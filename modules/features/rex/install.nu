# rex-install: put Rex Beta into a folder when it is not there yet.
#
# Rex Beta has no Homebrew cask, and its docs give no download link. The app's
# own update feed is public: a Sparkle appcast that lists every build as a DMG.
# This script reads that feed, takes the newest build, and copies the app out
# of it, but only when the app carries Superlogical's Developer ID signature
# and Apple's notarization. An app that is already there is left alone: Sparkle
# inside it keeps it current.
#
# The switch runs it as root (default.nix); the copy then belongs to the user,
# so that Sparkle can replace it without asking for a password.
#
# The arguments come as one JSON file, written by default.nix:
#
#   { feed: <appcast URL>, team: <Apple team ID the app must be signed with>,
#     app: <bundle name>, target: <folder>, owner: <account, or "" to keep it> }
def main [
    spec: path # the JSON file above
]: nothing -> nothing {
    let spec = open --raw $spec | from json
    let feed = $spec.feed
    let team = $spec.team
    let app = $spec.app
    let target = $spec.target
    let owner = $spec.owner
    let installed = $target | path join $app
    if ($installed | path exists) { return }

    let build = newest-build $feed
    print $"rex-install: installing ($app) build ($build.version) from ($build.url)"

    let work = ^/usr/bin/mktemp -d -t rex-install | str trim
    let mount = $work | path join mount
    let dmg = $work | path join (
        $build.url
        | url parse
        | get path
        | path basename
    )
    let failure = try {
        http get --raw $build.url | save --raw $dmg
        # hdiutil, not `diskutil image`: macOS 27 calls it deprecated, but the
        # replacement does not exist on the macOS 15 that Rex still supports.
        let attached = ^/usr/bin/hdiutil attach -nobrowse -readonly -noautoopen -mountpoint $mount $dmg | complete
        if $attached.exit_code != 0 { error make {msg: $"cannot open ($dmg): ($attached.stderr | str trim)"} }

        let source = $mount | path join $app
        verify $source $team
        ^/usr/bin/ditto $source $installed
        if ($owner | is-not-empty) { ^/usr/sbin/chown -R $owner $installed }
        print $"rex-install: installed ($installed)"
        null
    } catch {|error|
        $error.msg
    }

    if ($mount | path exists) {
        ^/usr/bin/hdiutil detach -quiet $mount | complete | ignore
    }
    rm --recursive --force $work

    if $failure != null {
        print --stderr $"rex-install: not installed: ($failure)"
        exit 1
    }
}

# The newest build in the feed: its build number and its DMG's URL.
def newest-build [feed: string]: nothing -> record<version: int, url: string> {
    http get --raw $feed
    | from xml
    | get content
    | where tag == channel
    | first
    | get content
    | where tag == item
    | each {|item|
        let fields = $item.content | where tag != null
        let enclosure = $fields | where tag == enclosure | first
        {
            # nu drops the namespace: <sparkle:version> arrives as `version`.
            version: ($fields | where tag == version | get --optional 0.content.0.content | into int)
            url: $enclosure.attributes.url
        }
    }
    | sort-by version
    | last
}

# Stop unless the app is signed by the team and Gatekeeper accepts it as notarized.
def verify [app: path, team: string]: nothing -> nothing {
    let signature = ^/usr/bin/codesign --display --verbose=2 $app | complete
    let team_line = $signature.stderr | lines | where $it starts-with 'TeamIdentifier='
    if $team_line != [$"TeamIdentifier=($team)"] {
        error make {msg: $"($app) is not signed by team ($team)"}
    }

    let assessment = ^/usr/sbin/spctl --assess --type execute --verbose=2 $app | complete
    if $assessment.exit_code != 0 or not ($assessment.stderr | str contains 'source=Notarized Developer ID') {
        error make {
            msg: $"Gatekeeper does not accept ($app) as notarized: ($assessment.stderr | str trim)"
        }
    }
}
