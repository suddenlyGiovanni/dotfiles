# rex-install: install Rex Beta when it is missing.
#
# Rex Beta has no Homebrew cask, but the app's own update feed (a Sparkle
# appcast) is public and lists every build as a disk image. This script takes
# the newest build from the feed, and installs the app from it only if Apple
# vouches for it: signed by Superlogical's team, and notarized. An app that is
# already installed is left alone; it updates itself.
#
# A switch runs it as root (default.nix), with one JSON file as its argument:
#
#   { feed: <appcast URL>, team: <Apple team ID>, app: <bundle name, e.g. "Rex Beta.app">,
#     target: <folder, e.g. /Applications>, owner: <account to own the app, or ""> }
#
# Nushell in brief, for what follows:
#   - a command's last expression is its return value;
#   - `$in` is the value piped into a command;
#   - `| complete` runs an external program without failing, and returns its
#     exit code, stdout and stderr as a record;
#   - `{|x| ... }` is a closure, and `do $closure $x` calls it.

# Install the app the spec describes, unless it is already there.
def main [
    spec_file: path # the JSON file described above
]: nothing -> nothing {
    let spec = open --raw $spec_file | from json
    let destination = $spec | destination-of
    if ($destination | path exists) { return }

    try {
        let build = newest-build $spec.feed
        print $"rex-install: installing ($spec.app) build ($build.version)"
        install-build $build $spec
        print $"rex-install: installed ($destination)"
    } catch {|error|
        print --stderr $"rex-install: not installed: ($error.msg)"
        exit 1
    }
}

# Where the app goes: the target folder, plus the bundle name.
def destination-of []: record -> string {
    let spec = $in
    $spec.target | path join $spec.app
}

# ── The feed ─────────────────────────────────────────────────────────────────

# The newest build the feed lists.
def newest-build [feed_url: string]: nothing -> record<version: int, url: string> {
    http get --raw $feed_url
    | from xml
    | children channel
    | first
    | children item
    | each {|item| $item | build-of-item }
    | sort-by version
    | last
}

# One feed item as a build: its build number, and the URL of its disk image.
# nu drops XML namespaces, so <sparkle:version> arrives as the tag `version`.
def build-of-item []: record -> record<version: int, url: string> {
    let item = $in
    {
        version: (
            $item
            | children version
            | first
            | text-of
            | into int
        )
        url: (
            $item
            | children enclosure
            | first
            | get attributes.url
        )
    }
}

# The child elements of an XML element that carry the tag.
def children [tag: string]: record -> list<record> {
    get content | where tag == $tag
}

# The text inside an XML element.
def text-of []: record -> string {
    get content | where tag == null | get content | str join
}

# ── Installing ───────────────────────────────────────────────────────────────

# Download the build, check the app inside it, and copy it to its destination.
# The scratch folder and the mounted image are removed whatever happens.
def install-build [build: record, spec: record]: nothing -> nothing {
    with-scratch-folder {|scratch|
        let image = download $build.url $scratch
        with-mounted-image $image {|volume|
            let app = $volume | path join $spec.app
            assert-signed-by $app $spec.team
            assert-notarized $app
            copy-app $app ($spec | destination-of) --owner $spec.owner
        }
    }
}

# Download a URL into a folder under its own file name; returns the file.
# curl writes the file itself, so the step has one effect, and --fail turns an
# HTTP error into a failed step instead of a saved error page.
def download [url: string, folder: path]: nothing -> string {
    let file = $folder | path join (
        $url
        | url parse
        | get path
        | path basename
    )
    let fetched = ^/usr/bin/curl --fail --silent --show-error --location --output $file $url | complete
    if $fetched.exit_code != 0 {
        error make {
            msg: $"cannot download ($url): ($fetched.stderr | str trim)"
            help: 'Check the network. The next switch tries again.'
        }
    }
    $file
}

# Fail unless the app is signed with a certificate of the Apple team.
def assert-signed-by [app: path, team: string]: nothing -> nothing {
    # codesign prints its details on stderr.
    let details = ^/usr/bin/codesign --display --verbose=2 $app | complete | get stderr | lines
    if $"TeamIdentifier=($team)" not-in $details {
        error make {
            msg: $"($app) is not signed by Apple team ($team)"
            help: 'The download may not come from Superlogical. Check the feed URL in modules/features/rex/default.nix.'
        }
    }
}

# Fail unless Gatekeeper accepts the app as notarized by Apple.
def assert-notarized [app: path]: nothing -> nothing {
    let assessment = ^/usr/sbin/spctl --assess --type execute --verbose=2 $app | complete
    if $assessment.exit_code != 0 or $assessment.stderr !~ 'source=Notarized Developer ID' {
        error make {
            msg: $"Gatekeeper does not accept ($app) as notarized: ($assessment.stderr | str trim)"
            help: 'Apple has not notarized this build. Wait for the next one, or install Rex Beta by hand.'
        }
    }
}

# Copy the app, and give it to the owner: Sparkle then updates it without
# asking for a password. An empty owner keeps the copier as the owner.
def copy-app [app: path, destination: path, --owner: string = '']: nothing -> nothing {
    ^/usr/bin/ditto $app $destination
    if ($owner | is-not-empty) { ^/usr/sbin/chown -R $owner $destination }
}

# ── Resources that must be released ──────────────────────────────────────────

# Run the body with a new empty folder, then delete the folder.
def with-scratch-folder [body: closure]: nothing -> nothing {
    let folder = ^/usr/bin/mktemp -d -t rex-install | str trim
    with-cleanup { do $body $folder } { rm --recursive --force $folder }
}

# Mount a disk image read-only, run the body with the mounted volume, then
# unmount it. hdiutil, not `diskutil image`: macOS 27 calls hdiutil deprecated,
# but its replacement does not exist on macOS 15, which Rex still supports.
def with-mounted-image [image: path, body: closure]: nothing -> nothing {
    let volume = $image | path dirname | path join volume
    let mounted = ^/usr/bin/hdiutil attach -nobrowse -readonly -noautoopen -mountpoint $volume $image | complete
    if $mounted.exit_code != 0 {
        error make {
            msg: $"cannot mount ($image): ($mounted.stderr | str trim)"
            help: 'The download may be incomplete. The next switch downloads it again.'
        }
    }
    with-cleanup { do $body $volume } {
        ^/usr/bin/hdiutil detach -quiet $volume | complete
    }
}

# Run the body, then the cleanup, even when the body fails; a failure of the
# body is raised again after the cleanup. nu has no try/finally.
def with-cleanup [body: closure, cleanup: closure]: nothing -> nothing {
    let failure = try {
        do $body
        null
    } catch {|error|
        $error.msg
    }
    do $cleanup
    if $failure != null { error make {msg: $failure, help: 'Raised again after the cleanup ran.'} }
}
