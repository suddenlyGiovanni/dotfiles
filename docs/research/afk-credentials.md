# Credentials for unattended agent work (AFK): inventory and proposal

Date: 2026-11-13. Status: inventory done, nothing built. Scope: this machine (work host), the team
repo `infrastructure/developer`, and the `headless` monorepo as the main source of evidence.

## 1. Summary

- Every credential on this machine is set up so that **presence is the authorization**: a
  signature, an SSH connection or a secret read asks for Touch ID. The team setup states the same
  as its intent (developer ADR 0005: "Every secret read, SSH connection and signature asks for
  Touch ID"). Unattended work contradicts that rule by definition, so no setting fixes it.
- Three mechanisms cause all recorded stalls: the 1Password secrets FIFO read by direnv, commit
  signing, and SSH transport. `gh`, `glab`, `aws` and `bw` have no recorded failure.
- The proposal is a second, separate trust tier for agents: its own narrow credentials, no
  presence, delivered through the environment of the agent session. The human tier stays as it is.

## 2. Evidence

Counted over 2,791 Claude Code transcripts on this machine (`~/.config/claude/projects`), checked
with `rg -l` on the exact error text.

| Mechanism | Error an agent sees | Transcripts | Cost |
|---|---|---|---|
| direnv reads `.secrets.env`, a 1Password Environments FIFO, while 1Password is locked (headless) | `.secrets.env (FIFO) yielded no variables after retry` | 179 | Up to 150 s per `direnv exec` (measured 2026-09-22). Format and lint hooks pass their timeout and report nothing. |
| Commit signing through `op-ssh-sign` | `error: 1Password: agent returned an error`, `fatal: failed to write commit object` | 43 | Every commit, amend, rebase and cherry-pick fails, after the pre-commit hooks already ran. |
| SSH push, fetch and submodule clone through the 1Password agent | `sign_and_send_pubkey: signing failed … communication with agent failed`, `Permission denied (publickey)` | 38 | No push, no fetch. `glab mr create --fill` fails too, because glab pushes over SSH. |

Other sources:

- **headless retro log** (`docs/retro/`): few entries. One accepted theme ("The signing agent
  cannot approve while the operator is away", 2 sightings) and three unreviewed inbox notes from
  2026-10-23/24, all on the locked FIFO: a push that hung past 300 s, Bash calls that waited two to
  four minutes, edit hooks that went silent.
- **headless issues**: #255 (signing blocks agent sessions, open, needs triage) and #344 (bound the
  FIFO read, closed). The read in `.envrc` on `origin/main` is still unbounded (lines 63 and 65),
  so #344 is closed without its fix on `main`.
- **Misleading signal**: `ssh-add -l` lists the keys while signing is refused.

## 3. What is wrapped, and by what

Checked from an agent's Bash on this machine on 2026-11-13, without triggering a prompt.

| Operation | Mechanism | Needs presence | In an agent session |
|---|---|---|---|
| `git commit` | `gpg.format=ssh`, signer `op-ssh-sign`, key "Git Commit Signing Key" (1Password, vault Private) | Yes | Fails |
| `git push` / `fetch` over SSH | `IdentityAgent` is the 1Password socket for every host | Yes | Fails |
| `gh` | Token in the macOS keychain. The `op plugin run` wrapper exists only as a nu and fish function | Only in an interactive shell | Works |
| `glab` (dev.thingos.io) | Token in the macOS keychain. Same wrapper remark | Only in an interactive shell | Works. Its git operations use SSH and fail |
| `with-secrets` (Vaultwarden) | `bwbio unlock --raw`: Touch ID through the Bitwarden desktop app, once per command | Yes | Would fail. `bw` is `locked` now. No recorded failure, because headless does not use it yet |
| headless `.secrets.env` | 1Password Environments FIFO, read by `.envrc` | 1Password must be unlocked | Stalls, then loads no secrets |
| `aws` | IAM Identity Center, legacy profile format, no refresh token. Last token expired 2026-11-05 | Browser login | Fails once the 8-hour token expires. No recorded failure |
| `op read`, `op item` | 1Password CLI through the desktop app | Yes, per terminal session | Works only while unlocked and approved |

The team setup (`infrastructure/developer`) has the same shape with other parts: the Bitwarden
desktop SSH agent with "Ask for authorization: Always", commit signing through that agent,
`with-secrets` for tokens. It has no rule for unattended runs.

Not readable from here: the 1Password app's SSH agent settings (the file is protected by macOS).
The proposal does not depend on them.

## 4. What an unattended agent needs

Needed: commit, push and fetch, open a merge request, install packages (`GITLAB_TOKEN`,
`NPM_READ_TOKEN`), run the gates.

Not needed, and kept behind presence: deploy and production credentials, the Cloudflare minter
token, AWS roles, `sudo` (`just switch`), anything that writes to a vault.

## 5. Proposal: an agent tier

Principle: do not widen the human's keys (no "approve for all applications for 24 hours", no vault
left unlocked). Give agent sessions their own credentials, each one narrow enough to live without
a prompt.

| Need | Agent tier | Why this and not the alternative |
|---|---|---|
| Git transport | HTTPS, with `glab auth git-credential` as the credential helper | Works today. The token is already in the keychain on every colleague's Mac that ran `glab auth login`. |
| Commit signing | A per-machine Ed25519 key on disk, registered on GitLab with usage type "Signing" only | Commits stay verified, and an agent's commits are distinguishable from the human's. The key cannot log in anywhere. dev.thingos.io supports the signing-only type (the current key uses it). Alternative: unsigned commits, which `main` already accepts. |
| Tokens for installs | A short allowlist in the macOS keychain, read through secretspec's `keyring` provider, placed before `bw://` in the provider chain, and injected into the install command only (section 10) | Narrow: only read tokens. The team module already has the option for it (`developer.secretspec.settings`). Alternative: one Touch ID before leaving that keeps the whole vault session for N hours; simpler, but it exposes the whole vault. |
| `with-secrets` | A path that never prompts: read the chain, and fail in under a second with the name of the missing secret | Today it calls `bwbio unlock` first, always. |
| headless FIFO | In agent sessions, skip the FIFO and take the allowlist from the keychain. Separately, land the bound that #344 describes | Removes the largest stall. The durable fix is a `secretspec.toml` in headless, which puts both repos on one mechanism. |
| Token identity | A separate personal access token named for agent use, least scopes, short expiry | A project access token (bot user, any GitLab licence, at most 365 days) attributes agent work to a bot, but each project's maintainers must create it. Team decision, later. |

Delivery: the session-start hook writes the git settings into the agent's environment
(`GIT_CONFIG_COUNT`, `GIT_CONFIG_KEY_n`, `GIT_CONFIG_VALUE_n`), next to the direnv line that
`modules/features/claude-code/hooks/direnv-env.nu` writes today. No git config file changes, and a
terminal the human opens is unaffected. The tier is on in every agent session, not only when the
user says "AFK": the agent then never has to judge whether someone is present, and the per-command
overrides in the global agent instructions go away.

Path to the team: build and measure here, then move it to `infrastructure/developer` as one
home-manager module (key generated at activation, outside the Nix store; secretspec chain; the
`with-secrets` path; the hook) with an amendment to ADR 0005: presence for people, the agent tier
for unattended runs.

## 6. Order of work

1. Git transport and the signing key (43 and 38 transcripts, some in both; this repo only).
2. headless: skip the FIFO in agent sessions, and bound the read (179 transcripts).
3. `with-secrets` without a prompt, and the keychain allowlist.
4. AWS: `sso-session` format with a refresh token. No recorded failure; last.

## 7. Open decisions

1. Agent signing key, or unsigned commits.
2. Keychain allowlist, or a time-boxed vault session.
3. Separate personal token now; project access tokens with the team later, or never.

## 8. Follow-up, 2026-11-13: the setup is also too open

Presence gating is all or nothing. While the vault is locked, an agent can do nothing. While it is
unlocked, an agent holds everything the user holds.

- **headless puts seven secrets into every agent command.** With 1Password unlocked, a direnv load
  exports `GITLAB_TOKEN`, `NPM_READ_TOKEN`, `JIRA_API_TOKEN`, `CONFLUENCE_API_TOKEN`,
  `WEBLATE_API_TOKEN`, `DEPLOY_READ_PASSWORD` and `CLOUDFLARE_API_TOKEN_MINTER` (names read from
  `direnv exec . env`, values not printed). The last one mints Cloudflare tokens.
- **Token-shaped strings are already in the transcripts**: GitLab tokens in 11 files (3 distinct
  values), Atlassian tokens in 8, npm tokens in 4, AWS access key ids in 4. Some may be examples.
  The transcripts are plain files under `~/.config/claude/projects`. Rotate the three GitLab values.
- **Every AWS profile is an administrator role** (`internal-tools-admin` is the default, then
  `SystemAdministrator` and `AdministratorAccess`). For eight hours after `aws sso login`, any
  agent command can use them.

So the agent tier is not only for unattended runs. It also takes these secrets out of the agent's
reach when the user is present.

## 9. Tasks by tier

Counted over 95,282 Bash calls that agents made on this machine.

| Tier | Tasks | Calls | Unattended | Credentials |
|---|---|---|---|---|
| A. Local work | Edit, build, test, lint, format, commit | `git commit` 1,099 | Yes | A signing key, or none |
| B. Development with the team | Fetch and push branches, merge requests, issues, pipeline status, package installs, read and comment in Jira and Confluence | `glab mr`, `issue`, `api` 1,534; `gh` 259; fetch, pull, clone 133; `git push` 64; installs 47 | Yes | The agent's own narrow ones, delivered by a channel from section 10 |
| C. Operations | AWS, Cloudflare tokens and deploys, `alchemy`, `terraform`, `pulumi`, the deploy server, store releases, merges into protected branches, `sudo` | `alchemy` 16; `wrangler` 6; `terraform` or `pulumi` 6; `aws` 5; `sudo` 1 | No | The user's, with presence. Never in an agent's environment |
| D. Credential administration | Create, rotate or read a secret; write to a vault | `op` 10; `secretspec` 29; `with-secrets` 24 | No | The user only |

An agent still authors tier C changes (infrastructure code, pipelines). The apply runs with the
user present, or in CI behind a protected environment. If agents later need to read cloud state, a
separate read-only role is the way, not the user's profiles.

## 10. Delivery channels

The agent needs a capability, not the value. Ranked; use the first that fits.

| Channel | How the secret travels | Agent's environment | Fits |
|---|---|---|---|
| 1. The tool's own helper | Store to tool, through a pipe, when the tool asks | Nothing | git over HTTPS (credential helper), `glab` and `gh` (keychain), AWS (`credential_process`) |
| 2. A connector the harness holds | The harness keeps the OAuth token; the agent gets tool calls | Nothing | Jira, Confluence, GitLab merge requests through MCP tools |
| 3. Injection into one command | A broker starts one fixed command with the secret in that process only | Nothing; the child holds it while it runs | Package installs (`with-secrets -S install bun install`) |
| 4. Injection at the network edge | The process holds a placeholder; a local proxy swaps in the real value for allowed hosts | A placeholder | What 1 to 3 cannot cover. Needs a prototype |
| Not a channel | A secret exported into the shell (direnv, `.env`, a FIFO read by `.envrc`) | The value, in every command | Nothing |

Channel 3 holds only if the agent cannot choose the command: `with-secrets env` would print
everything. The map from command to secrets must be fixed in configuration the agent cannot edit
(`~/.config/secretspec/commands/`, generated by Nix), and a hook must deny any other command under
the broker.

The limit: an agent runs as the same macOS user. Channels 1 to 3 keep values out of the
conversation, the history and the logs, which closes accidental leaks. They do not stop a process
that runs as the user from using a credential that needs no presence. Against that, the bounds are
scope, expiry, and a sandbox that denies reads of the stores and limits the network. A separate
macOS user or a container for agents is the stronger form.

## 11. Status

| Step | State |
|---|---|
| Tiers A to D | Agreed, 2026-11-13 |
| Git transport, signing key, no AWS in agent sessions | Built in `modules/features/agent-tier.nix` and the Claude Code env hook. Tested with a throwaway key: a signed commit in 71 ms with no prompt, `ls-remote` over HTTPS on both forges, an SSH remote with no rewrite fails in 0.5 s. Not active until `just switch`; the key is not registered |
| headless: no secrets exported into agent sessions | Not started (another repository) |
| `with-secrets` without a prompt, fixed command map | Not started |
| Rotate the tokens found in transcripts | The user's step |
| Other harnesses source `~/.config/agent-tier/env.sh` | Not started |

## 12. Not verified

- secretspec's documentation says a Nix-built binary asks for the login keychain password on the
  first read after each upgrade ("Always Allow" then holds until the next upgrade). Not tested
  here. If true, a `just update` before leaving would re-create a prompt.
- Whether GitLab shows a commit as verified when it is signed with a signing-only key whose title
  names an agent, under the human's account. Expected yes; not tested.
- Other harnesses (OpenCode, Zed, Delta) have no session-start hook wired yet; each needs its own
  way to receive the same environment.
- The transcript counts are files that contain the error text. They include a few research
  sessions that quote it (about 4).
