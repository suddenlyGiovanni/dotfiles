# agent-tier-check: say what the agent tier still needs on this machine, and the
# command that fixes each gap. Run it after the first `just switch` on a new
# machine, and whenever an agent session cannot commit or push.
#
# It reads and tests; it changes nothing and prints no secret. default.nix builds
# the wrapper and passes the paths and the forges as JSON:
#
#   { envFile, gitConfig, signingKey, forges: [{ host, cli: "gh" | "glab" }] }
#
# Exit code 1 when a check fails.
const EXPIRY_WARNING = 14day

def main [
    data: path # JSON with the tier's paths and forges, written by default.nix
]: nothing -> nothing {
    let tier = open --raw $data | from json
    let checks = [
        (file-check 'Tier exports' $tier.envFile)
        (file-check 'Agent git configuration' $tier.gitConfig)
        (key-check $tier.signingKey)
        ...($tier.forges | each {|forge| forge-checks $forge $tier } | flatten)
    ]

    print (
        $checks
        | each {|check| render $check }
        | flatten
        | str join "\n"
    )
    if ($checks | any {|check| not $check.ok }) { exit 1 }
}

# A check that holds: what was checked, and what was found.
def passed [name: string, detail: string]: nothing -> record {
    {
        name: $name
        ok: true
        detail: $detail
        fix: ''
    }
}

# A check that does not hold, with the command that fixes it.
def failed [name: string, detail: string, --fix: string = 'just switch']: nothing -> record {
    {
        name: $name
        ok: false
        detail: $detail
        fix: $fix
    }
}

def render [check: record]: nothing -> list<string> {
    let mark = if $check.ok { 'ok     ' } else { 'MISSING' }
    let line = $"($mark)  ($check.name): ($check.detail)"
    if $check.ok { [$line] } else { [$line $"           fix: ($check.fix)"] }
}

# A file that the switch generates.
def file-check [name: string, file: path]: nothing -> record {
    if ($file | path exists) {
        passed $name $file
    } else {
        failed $name $"($file) does not exist" --fix 'just switch'
    }
}

# The signing key exists and signs with no prompt.
def key-check [key: path]: nothing -> record {
    let name = 'Signing key'
    if not ($key | path exists) { return (failed $name $"($key) does not exist" --fix 'just switch') }

    let signed = 'agent-tier-check' | ^ssh-keygen -Y sign -n git -f $key | complete
    if $signed.exit_code == 0 {
        passed $name $"($key) signs with no prompt"
    } else {
        failed $name $"($key) cannot sign: ($signed.stderr | str trim)" --fix $"rm ($key) ($key).pub; just switch"
    }
}

# Login, credential helper and key registration for one forge.
def forge-checks [forge: record, tier: record]: nothing -> list<record> {
    let login = match $forge.cli {
        'gh' => (github-login $forge.host)
        _ => (gitlab-login $forge.host)
    }
    if not $login.ok { return [$login] }

    let registration = match $forge.cli {
        'gh' => (github-registration $forge.host $tier.signingKey)
        _ => (gitlab-registration $forge.host $tier.signingKey)
    }
    [
        $login
        (helper-check $forge $tier.gitConfig)
        $registration
    ]
}

def github-login [host: string]: nothing -> record {
    let name = $"($host) login"
    let token = ^gh auth token --hostname $host | complete
    if $token.exit_code == 0 {
        passed $name 'gh has a token in the keychain'
    } else {
        failed $name 'gh is not logged in' --fix $"^gh auth login --hostname ($host) --git-protocol https --web"
    }
}

# glab's token is a personal access token with an expiry date: warn before it ends.
def gitlab-login [host: string]: nothing -> record {
    let name = $"($host) login"
    let fix = $"^glab auth login --hostname ($host)"
    let token = ^glab api personal_access_tokens/self --hostname $host | complete
    if $token.exit_code != 0 { return (failed $name 'glab is not logged in, or its token has expired' --fix $fix) }

    let expires = $token.stdout | from json | get --optional expires_at
    if $expires == null { return (passed $name 'glab has a token with no expiry date') }

    let left = ($expires | into datetime) - (date now)
    if $left < $EXPIRY_WARNING {
        failed $name $"glab's token expires on ($expires)" --fix $"create a new token on ($host), then: ($fix)"
    } else {
        passed $name $"glab's token expires on ($expires)"
    }
}

# git gets a password from the forge's CLI under the agent's git configuration.
def helper-check [forge: record, git_config: path]: nothing -> record {
    let name = $"($forge.host) credential helper"
    let request = ['protocol=https' $"host=($forge.host)" '' ''] | str join "\n"
    let filled = with-env {GIT_CONFIG_GLOBAL: $git_config GIT_TERMINAL_PROMPT: '0'} {
        $request | ^git credential fill | complete
    }
    let has_password = $filled.stdout | lines | any {|line| $line starts-with 'password=' }
    if $filled.exit_code == 0 and $has_password {
        passed $name $"git gets the token from ($forge.cli)"
    } else {
        failed $name $"git gets no token from ($forge.cli)" --fix 'just switch'
    }
}

def github-registration [host: string, key: path]: nothing -> record {
    let name = $"($host) signing key"
    let keys = ^gh api user/ssh_signing_keys --hostname $host | complete
    if $keys.exit_code != 0 {
        let fix = $"^gh auth refresh --hostname ($host) --scopes admin:ssh_signing_key"
        return (
            failed $name 'gh may not read the signing keys: its token lacks the scope' --fix $fix
        )
    }

    let registered = $keys.stdout | from json | any {|entry| ($entry.key | key-body) == (public-key $key | key-body) }
    if $registered {
        passed $name 'registered as a signing key'
    } else {
        failed $name 'not registered' --fix $"^gh ssh-key add ($key).pub --type signing --title \"(key-title)\""
    }
}

# On GitLab the key must be signing-only: a key that may also authenticate could log in.
def gitlab-registration [host: string, key: path]: nothing -> record {
    let name = $"($host) signing key"
    # glab takes its host from the repository it runs in, and gitlab.com outside one.
    let add = $"GITLAB_HOST=($host) ^glab ssh-key add ($key).pub --usage-type signing --title \"(key-title)\""
    let keys = ^glab api user/keys --hostname $host | complete
    if $keys.exit_code != 0 {
        return (
        failed $name 'glab cannot read the keys' --fix $"^glab auth login --hostname ($host)"
    )
    }

    let body = public-key $key | key-body
    let matches = $keys.stdout | from json | where ($it.key | key-body) == $body
    if ($matches | is-empty) { return (failed $name 'not registered' --fix $add) }

    let usage = $matches | first | get usage_type
    if $usage == 'signing' {
        passed $name 'registered, signing only'
    } else {
        failed $name $"registered with usage ($usage): it could log in" --fix $"delete it on ($host), then: ($add)"
    }
}

def public-key [key: path]: nothing -> string {
    open --raw $"($key).pub" | str trim
}

# The key material of a public key line, without its type and comment.
def key-body []: string -> string {
    parse --regex '^\S+ (?<body>\S+)' | get body | first
}

# The machine's name as macOS shows it on the network; `hostname` can be a DHCP name.
def key-title []: nothing -> string {
    let host = ^/usr/sbin/scutil --get LocalHostName | str trim
    $"Agent signing key - ($host)"
}
