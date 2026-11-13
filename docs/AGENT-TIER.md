# Agent tier: credentials on a new machine

What to do after the first `just switch` so that you and the agents can both work, and where each
credential lives. The design and its evidence are in
[research/afk-credentials.md](./research/afk-credentials.md); the code is
[modules/features/agent-tier/](../modules/features/agent-tier/default.nix).

## The rule

- **Your credentials need you.** They live in 1Password, and each use asks for Touch ID.
- **The agent's credentials need nobody.** They live on this machine only, each one is narrow, and
  each one can be thrown away and made again in a minute. None of them goes into 1Password.

## Where each credential lives

| Credential | Used by | Lives in | In 1Password? | On a new machine |
|---|---|---|---|---|
| Your SSH keys (GitHub, GitLab, commit signing) | You, in a terminal | 1Password | Yes. It is the only copy | Nothing: sign in to 1Password |
| `gh` token (github.com) | You and the agent | macOS keychain, written by `gh auth login` | No | Log in again |
| `glab` token (dev.thingos.io) | You and the agent | macOS keychain, written by `glab auth login` | No. Make a new token | Create a token, log in |
| Agent signing key | The agent's commits | `~/.ssh/agent-signing`, made by the switch | No. One per machine | Register the new key, delete the old one |
| Vault secrets (Vaultwarden) | You, through `with-secrets` | The company vault | No | `bw login` |

Why the agent's credentials stay out of 1Password: a copy in a vault would outlive the machine it
was made for. Losing one costs a minute; leaking one is bounded by what it can do, and the signing
key can do nothing but sign.

## Setup, in order

`agent-tier-check` tests every step below and prints the command for each one that is missing.
Run it first, run it after each step, and stop when every line says `ok`.

1. **1Password.** Open the app and sign in. In Settings, Developer: turn on "Use the SSH agent"
   and "Integrate with 1Password CLI". This gives a terminal your own keys.
2. **GitHub login.** A browser opens; approve it.

   ```bash
   gh auth login --hostname github.com --git-protocol https --web --scopes admin:ssh_signing_key
   ```

   Already logged in, and the check says the token lacks the scope:

   ```bash
   gh auth refresh --hostname github.com --scopes admin:ssh_signing_key
   ```

3. **GitLab login** (work host). Create a personal access token at
   `https://dev.thingos.io/-/user_settings/personal_access_tokens` with the scopes `api` and
   `write_repository` and an expiry date of at most one year. Then paste it when asked:

   ```bash
   glab auth login --hostname dev.thingos.io
   ```

   Answer "HTTPS" for the git protocol and "yes" to authenticating git with the token.
4. **Register the agent signing key.** The check prints both commands with this machine's name:

   ```bash
   agent-tier-check
   ```

   They have this shape. On GitLab the usage type must be `signing`, never `auth`: a signing-only
   key cannot log in.

   ```bash
   gh ssh-key add ~/.ssh/agent-signing.pub --type signing --title "Agent signing key - <machine>"
   ```

   ```bash
   glab ssh-key add ~/.ssh/agent-signing.pub --usage-type signing --title "Agent signing key - <machine>"
   ```

5. **Delete the old machine's key** on both forges, if this machine replaces one:
   `https://github.com/settings/keys` and `https://dev.thingos.io/-/user_settings/ssh_keys`.
6. **Check.** Every line must say `ok`:

   ```bash
   agent-tier-check
   ```

## When something expires or breaks

| Symptom | Cause | Fix |
|---|---|---|
| The check says the `glab` token expires soon, or agent pushes to GitLab fail with 401 | The personal access token has an expiry date | Step 3 again, with a new token |
| Agent commits show as "Unverified" | The key is not registered, or is registered on another account | Step 4 |
| An agent's `git push` fails at once with "Permission denied" | The remote's host has no HTTPS rewrite | Add the host to `forges` in `modules/features/agent-tier/default.nix` |
| The key may have leaked | | Delete it on both forges, `rm ~/.ssh/agent-signing ~/.ssh/agent-signing.pub`, `just switch`, step 4 |
