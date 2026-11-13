# Sharing Nix tool derivations between the dotfiles flake and the project repos

Researched 2026-11-13 on this Mac (Determinate Nix 3.22.2, which is Nix 2.35.2). Nothing was changed: no lock file, no repo, no Nix setting. The only store-touching commands were read-only (`nix path-info`, `nix-store -q --roots`, `nix-store --gc --print-dead|--print-roots`).

## Recommendation

**The goal is partly achievable.** "Every repo resolves every tool to the same store path" is possible only if every repo locks the same nixpkgs revision, and that needs the team's agreement. It would also buy less than it looks like, because most of the duplication is not between dotfiles and the projects.

What the measurements say:

- The store is 49 GB (37,092 paths). Store optimisation is **off** (`auto-optimise-store = false`, `/nix/store/.links` is empty).
- The seven common tools alone exist in 48 copies. Everything except the largest copy of each costs roughly **2.1 GiB**.
- Almost every copy is held alive by a GC root in a project directory, not by dotfiles. There are 21 `.direnv` profiles in `headless` worktrees (43 directories under `.worktrees/`), `.pre-commit-config.yaml` links, forks, and `.devenv/gc`. `headless` worktrees alone lock six different nixpkgs revisions. Plain garbage collection cannot free what those roots hold (only 154 paths are dead right now).
- Same-version tools from different nixpkgs revisions have **different file contents** (checked: bun 1.4.2 ×3, nushell 0.116.1 ×3, just 1.58.0 ×3, treefmt 2.6.0 ×4, all different hashes). Hard-linking therefore will not merge them. It does merge identical files: a sample of files over 256 KiB found **5.7 GiB** of exact duplicates (JDK, rustc, deno, shellcheck, 19 copies of the `headless` source tree, and others).

Smallest change with the largest saving, in order:

1. **Alone, today: a scheduled `nix store optimise`** (weekly, root launchd job). Measured lower bound about 5.7 GiB, no lock file touched, no team input. See option A.
2. **Alone, today: prune stale worktrees and their `.direnv` / `.pre-commit-config.yaml` roots**, then let Determinate's GC collect. This is the largest lever on the duplicates of the tools above, and it is not in the original list of options. I did not measure the GiB it frees (see "Not verified").
3. **With the team: one shared nixpkgs pin** that all consuming repos `follow`, plus a shared update day. This is the only route to "one path per tool across repos", and it costs each repo its independent update schedule. Aligning the dotfiles flake to it is cheap once it exists.

Pinning the registry (option D) and aligning dotfiles to the team (option C) alone save very little: the global profile holds one copy per tool, so the best case is removing about one copy per tool.

## 1. Measurements

### 1.1 nixpkgs revision locked per repo

Dates are the `lastModified` of the locked nixpkgs commit. "Package set" is the input that tools are actually built from.

| Repo | Lock file | Package-set input | Revision | Date | Notes |
|---|---|---|---|---|---|
| dotfiles | `flake.lock` | `NixOS/nixpkgs` (`nixpkgs-unstable`) | `2074cc67` | 2026-11-12 | |
| dotfiles | `flake.lock` | `nixpkgs-master` (pinned by rev) | `86621d45` | 2026-10-23 | second set, on purpose |
| dotfiles | `flake.lock` | `nixpkgs_2` (via `onepassword-shell-plugins`, no `follows`) | `6dadaf43` | 2026-11-04 | third set, not followed |
| headless | `flake.lock` | `nixos/nixpkgs` (`nixos-unstable`) | `0bb2eedc` | 2026-11-01 | |
| connect | `flake.lock` | `nixos/nixpkgs` (`nixpkgs-unstable`) | `b86751bc` | 2026-04-16 | 7 months old |
| connect | `flake.lock` | `nixpkgs-secretspec` | `8edc0c72` | 2026-10-08 | second set, for secretspec only |
| developer | `flake.lock` | `NixOS/nixpkgs` (`nixpkgs-unstable`) | `7dd199b0` | 2026-10-07 | |
| weblate | `flake.lock` | `nixos/nixpkgs` (`nixos-unstable`) | `46db2e09` | 2026-03-24 | |
| react-native-ble-mesh | `devenv.lock` | `cachix/devenv-nixpkgs` (`rolling`) | `d97234e5` | 2026-10-26 | based on nixpkgs `674a2028` (2026-10-24) |
| expo-next-timezone-offset-change | `devenv.lock` | `cachix/devenv-nixpkgs` (`rolling`) | `d97234e5` | 2026-10-26 | same as ble-mesh |
| cm-process | `devenv.lock` | `cachix/devenv-nixpkgs` (`rolling`) | `8f24a228` | 2026-05-11 | based on nixpkgs `b3da6560` |
| cm-process | `devenv.lock` | `nixpkgs_2`, via the `pm` module (atlassian-cli) | `9f11f828` | 2026-06-13 | second set |
| device-database | `devenv.lock` | `cachix/devenv-nixpkgs` (`rolling`) | `fa7125ea` | 2026-03-23 | based on nixpkgs `9cf7092b` |
| atlassian-cli | `flake.lock` (no `devenv.lock`) | `NixOS/nixpkgs` (`nixpkgs-unstable`) | `9f11f828` | 2026-06-13 | same rev cm-process gets through `pm` |

`atlassian-cli` has no `devenv.lock` because it is the module repo itself: a `flake.nix` plus a `devenv.nix` that other repos import.

Twelve distinct package-set revisions across the ten repos. Only the two devenv repos that were updated together (`react-native-ble-mesh`, `expo-next-timezone-offset-change`) and `cm-process`/`atlassian-cli` (through `pm`) coincide.

Inside `headless` the picture is worse: the 29 worktrees that have a `flake.lock` (of 43 directories under `.worktrees/`) lock these revisions: `0bb2eedc` ×17, `55bfb4d7` ×4, `b1b87598` ×3, `151fa4e8` ×2, `56c02bc0` ×2, `a799d3e3` ×1.

### 1.2 Copies of common tools in `/nix/store`

Main outputs only (no `-doc`, `-man`, `-dev`, `-completions`, `-source`, `.drv`). "Own size" is the NAR size of the output itself, not its closure. "Duplicate cost" is the total of all copies minus the largest one.

| Tool | Copies | Versions present | Own size per copy | Duplicate cost |
|---|---:|---|---|---:|
| bun | 9 | 1.3.1, 1.3.10, 1.3.11, 1.4.2 ×3, 1.4.3, 1.4.4 ×2 | 58–85 MiB | ~505 MiB |
| nodejs | 16 | 22.18, 22.20, 22.23.2, 24.1 (×2 builds), 24.7, 24.11, 24.14, 24.20, 24.21 ×2, 24.22.2, 26.8.2, 26.11.1, 26.12.1, 26.13 | 65–100 MiB | ~1,120 MiB |
| nushell | 5 | 0.115.1 ×2, 0.116.1 ×3 | 70–74 MiB | ~285 MiB |
| git | 5 | 2.53.0, 2.55.0 ×2, 2.56.0 ×2 | 40–52 MiB | ~160 MiB |
| treefmt | 4 | 2.6.0 ×4 | 9 MiB | ~27 MiB |
| just | 7 | 1.46.0, 1.47.1, 1.49.0, 1.58.0 ×3, 1.59.0 | 4–5 MiB | ~26 MiB |
| direnv | 2 | 2.37.1, 2.38.2 | 8–9 MiB | ~8 MiB |
| **Total** | **48** | | | **~2.1 GiB** |

Notes on how to read this:

- Several "copies" are the same version built from different nixpkgs revisions. Their binaries differ byte for byte, so file-level deduplication cannot merge them.
- For `nodejs`, the real binary lives in `nodejs-slim-*` for newer nixpkgs and in `nodejs-*` for older ones. The table counts both.
- `git` closures are about 1.5 GiB each, but most of that is shared dependencies, so the own size is the honest figure.
- The sum counts only the tools' own outputs. Their dependency closures (ICU, openssl, libc++, …) duplicate across revisions as well, so the true cost is higher. I did not measure it.
- These are a small part of the store: all 48 copies together are about 2.4 GiB of 49 GB (about 5%).

### 1.3 Who keeps the copies alive

`nix-store -q --roots` on the bun, just, nushell, treefmt and nodejs paths shows, for example:

| Path (short hash) | Held by |
|---|---|
| bun 1.3.1 `q77q60` | `headless/vendor/effect-v3/.direnv` only |
| bun 1.3.10 `547qzc` | `weblate/.direnv` and a weblate worktree under `.claude/worktrees` |
| bun 1.4.2 `9nmsid`, `r3r978` | `.pre-commit-config.yaml` links in three `headless` worktrees; a `result` link in a dotfiles worktree |
| bun 1.4.3 `v642xn` | five `headless` worktrees (`.pre-commit-config.yaml`, one `.direnv`) |
| nodejs 22.18 `9yqq8s`, 24.21 `7cr3l1`, 26.13 `m75c3h` | `~/Developer/forks/*/.direnv` |
| nodejs 24.22.2, bun 1.4.4 `6l3zg6`, just 1.59 | the current system generations and home-manager (the dotfiles copy, 4 generations `system-161…164`) |
| treefmt `yds67z` | `dotfiles/.direnv` and `.pre-commit-config.yaml` |

Totals: `nix-store --gc --print-roots` lists 2,578 roots (2,265 of them redacted as `{censored}`); 276 of the listed ones are `.direnv` / `.devenv` links, against 4 system generations and the home-manager root. 21 `headless` worktrees carry a `.direnv` profile; `nix-store --gc --print-dead` lists only **154 dead paths**, so the last garbage collection already took what it could. The duplicates are not garbage. They are live roots in old worktrees, forks and side projects.

### 1.4 Store size and optimisation state

| Item | Value | Source |
|---|---|---|
| `/nix/store` size | 49 GB (`du -sh`), 37,092 entries | measured |
| `/nix/store/.links` | exists, **0 entries** | measured |
| `auto-optimise-store` | `false` (not set in `/etc/nix/nix.conf` or `/etc/nix/nix.custom.conf`; `nix config show` reports `false`) | measured |
| `/etc/nix/nix.custom.conf` | header comment only, no settings | measured |
| `nix --version` | `nix (Determinate Nix 3.22.2) 2.35.2` | measured |
| Default on macOS under Determinate Nix | off. Determinate's installer does not enable it on macOS, and its PR to change that ([nix-installer#1793](https://github.com/DeterminateSystems/nix-installer/pull/1793), "Enable auto-optimise-store on macOS") is still **open** | GitHub API |
| Determinate GC | `determinate-nixd` schedules GC itself and recommends not adding another GC job on top ([best practices](https://docs.determinate.systems/determinate-nix/best-practices/), [managed GC](https://learn.determinate.systems/determinate-nixd/managed-garbage-collection)). It says nothing about optimisation | docs |
| Hard-linking saved by the last `nix-collect-garbage` | 0.0 KiB, consistent with the above | given in the task |

Is `auto-optimise-store` still unsafe on macOS?

- It was. Nix [#7273](https://github.com/NixOS/nix/issues/7273) ("cannot link '/nix/store/.tmp-link' to '/nix/store/.links/...': File exists") collected years of reports on `aarch64-darwin` and `x86_64-darwin`. People disabled the setting and deleted `/nix/store/.links`. Lix [#477](https://git.lix.systems/lix-project/lix/issues/477) asked to disallow the setting on Darwin; Lix's installer turned it off on Mac.
- The fix landed: Nix PR [#14676](https://github.com/NixOS/nix/pull/14676) ("libstore: Use makeTempPath in optimizePath_, assorted fs fixes") was merged on 2025-12-01. nix-darwin's assertion now allows `auto-optimise-store` only on Nix ≥ 2.31.3 (< 2.32), ≥ 2.32.5 or ≥ 2.33 (or recent Lix), and otherwise says it "is known to corrupt the Nix Store, please use `nix.optimise.automatic` instead" ([modules/nix/default.nix](https://github.com/nix-darwin/nix-darwin/blob/master/modules/nix/default.nix)). **This Mac runs Nix 2.35.2, so it is on the fixed side of that check.** I did not confirm that #14676 is the same fix as the commit that assertion cites (`d888846b`); the version gate is nix-darwin's own statement.
- The documented alternative is the manual or scheduled command: `nix store optimise` (older: `nix-store --optimise`) ([manual](https://nix.dev/manual/nix/2.19/command-ref/new-cli/nix3-store-optimise)), which nix-darwin's option text recommends running periodically.
- Conservative reading: the automatic setting is probably safe on this version now, but Determinate has not blessed it on macOS yet, and one run of the explicit command carries none of the per-build risk. The scheduled command is the choice that needs no trust in the fix.

### 1.5 Exact duplicates at file level (sample)

To estimate what hard-linking would save, I hashed (`md5`) every file over 256 KiB whose size matched another file's size: 8,152 candidates out of 12,059 files over 256 KiB (32.8 GiB of the 49 GB).

| Result | Value |
|---|---|
| Redundant files with identical content | 4,920 |
| Reclaimable by hard-linking | **5.67 GiB** (a lower bound: files under 256 KiB were not hashed) |

Largest groups: `mesh-spec` HTML and database files inside 19 copies of the `headless` source tree (about 320 MiB), the Zulu JDK 17 `modules` file (124 MiB, 2 copies), two `librustc_driver` dylibs (93 + 92 MiB), `deno` (81 MiB), shellcheck (59 MiB, several), `hackage-packages.nix` (5 copies). None are the tool binaries compared in 1.2.

## 2. Options

For each, "Pins stay declared and tracked?" asks whether each repo's tool versions stay declared in its own committed lock file.

| # | Option | How it works | What it saves | Cost in independence | Pins stay declared and tracked? | Who can do it |
|---|---|---|---|---|---|---|
| A | **Do nothing structural**: GC plus file-level dedup (`nix store optimise`, scheduled) | Hard-links byte-identical files across all store paths. Nothing about evaluation or locks changes. | ≥ 5.7 GiB measured (files over 256 KiB, whole store). Does **not** merge same-version tools built from different revisions (their binaries differ). | None. | **Yes**, every lock file untouched. | You, alone |
| A2 | Prune stale roots | Remove old worktrees and their `.direnv`, `.pre-commit-config.yaml`, `.devenv/gc` links, forks you no longer use; then Determinate's GC can collect. | Not measured; likely the largest single saving on the tool duplicates in 1.2, since nearly all are rooted by old worktrees. | None. | **Yes**. | You, alone |
| B | **One shared pin inside the team**: a shared flake or devenv module that projects take as an input, with their `nixpkgs` set to `follows` the module's | Each project lock records the same nixpkgs revision. Same revision + same tool version → same store path, so copies collapse. | Up to the ~2.1 GiB of tool duplicates (1.2) plus their dependency closures, across the repos that adopt it. | Every adopting repo moves to the pin's cadence. A project cannot take a newer tool without leaving the pin, or the pin moves for everyone. | **Yes**, but the pin is now also decided centrally: the revision is in each repo's own lock, set by `follows`. Updating means updating the pin and every consumer lock. | Team agreement |
| C | **Align dotfiles to the team pin** (dotfiles `nixpkgs.follows` the team flake's nixpkgs) | Dotfiles' global tools resolve to the same paths the team repos use. | About one copy per tool (the global profile's own), roughly 0.3 GiB for these tools. Small: duplicates are mostly between projects. | Your personal setup follows the team's cadence (stale by weeks); your own `nixpkgs-unstable` freshness is gone. | Yes, dotfiles lock records the team's revision. | You, once a team pin exists |
| C' | **Reverse: team repos follow dotfiles** | Each repo's `nixpkgs` follows a flake that tracks one person's dotfiles. | Same as B. | **Wrong for shared repos.** A colleague cloning the repo needs your private dotfiles, and every update of your machine changes their locks. | A lock records the dotfiles' revision, but its source of truth is not in the repo's own history. | Not recommended |
| D | **Pin the flake registry** (`nix.registry.nixpkgs`) | `nix shell nixpkgs#x`, `nix run nixpkgs#x` and **new** locks (a fresh `nix flake lock`) start from the dotfiles' revision. | Little. **Existing locks do not move.** Helps ad-hoc commands only. | None for the team. | Yes (nothing in repos changes). | You, alone; see the caveat below |
| E | **Coordinated update cadence** (all locks updated the same day, same revision) | A process: pick a nixpkgs revision, run each repo's update against it (or let them lock `nixpkgs-unstable` on the same day). | Same as B while it lasts; repos drift apart again as soon as one updates alone. | Every repo updates on the team's schedule. | Yes, by convention only; nothing enforces it. | Team agreement |

### 2.1 How the existing team module is consumed

- `react-native-ble-mesh` and `expo-next-timezone-offset-change` have identical `devenv.yaml`:
  - `nixpkgs: github:cachix/devenv-nixpkgs/rolling`
  - `lib-config: git+ssh://git@dev.thingos.io/tes/npm-packages.git` with `flake: false`
  - `imports: [lib-config/devenv]`
- **The team module does not pin nixpkgs for its consumers.** `flake: false` means the module is imported as plain files; devenv documents that "imports from inputs only load Nix configuration" ([yaml options](https://devenv.sh/reference/yaml-options)), so any `inputs` declared inside that repo are ignored. The nixpkgs each consumer builds with is its own `nixpkgs` input, locked in its own `devenv.lock`. The two consumers lock `d97234e5` (2026-10-26) only because they were updated together. What the module's `devenv/default.nix` does with `pkgs` (bun, node, just, secretspec per its comment) I could not read: the repo is behind SSH and not in the local store (see "Not verified").
- `devenv.nix` in `expo-…` is two lines (`libConfig.name`, `dotenv.enable`); in `react-native-ble-mesh` it adds JDK, watchman, ruby and so on on top, from the same `pkgs`.
- `cm-process` imports `pm` (`git+ssh://git@dev.thingos.io/org/atlassian-cli.git`) **without** `flake: false` and without `follows`. The result: `pm` brings its own locked nixpkgs (`nixpkgs_2`, `9f11f828`, 2026-06-13) into `cm-process`'s lock. That is the concrete example of what a shared flake module costs when the consumer forgets `follows`: a second nixpkgs in the lock. devenv's docs show the fix: `inputs.<name>.follows`, or a nested override such as `pm/nixpkgs` ([inputs](https://devenv.sh/inputs/)).
- `device-database` has no `devenv.yaml`, so it uses devenv's default (`nixpkgs: github:cachix/devenv-nixpkgs/rolling`, [inputs](https://devenv.sh/inputs/)) and locks its own revision (2026-03-23).
- The `developer` repo (`~/Developer/work/developer`) is the **machine layer**, not a module that projects import. Its `flake.nix` has `nixpkgs-unstable` locked at `7dd199b0` (2026-10-07) and its own `nix-darwin`, `home-manager`, `nix-homebrew` inputs with `follows`. [ADR 0002](/Users/suddenlygiovanni/Developer/work/developer/docs/adr/0002-machine-layer-and-project-layer.md) states the rule explicitly: "Each project's toolchain stays exactly what its flake pins, whatever this repo installs", and "This repo never installs bun, Ruby or CocoaPods globally." The README adds: "You never install bun, Ruby or CocoaPods globally." So by design the team wants projects independent of the machine layer. Its `flakeModules.default` is exported for personal flakes (see its `docs/personal-flake.md`), not for project repos.
- The three project flakes (`headless`, `connect`, `weblate`) each declare `nixpkgs` themselves, with different branches (`nixos-unstable` vs `nixpkgs-unstable`). The two branches can point at different commits on the same day. `headless` and `weblate` use `import-tree` + flake-parts; `connect` has a second nixpkgs input for secretspec.

### 2.2 What each option needs on this Mac

- **A (scheduled optimise)**: nix-darwin's `nix.optimise.automatic` is not available here, because the dotfiles set `nix.enable = false` (Determinate owns Nix; `darwin-core.nix:71`), and nix-darwin's `nixpkgs.flake.setFlakeRegistry` carries the same `nix.enable` requirement. A plain nix-darwin `launchd.daemons.<name>` running `nix store optimise` as root does not depend on `nix.enable`; I have not tried it. `sudo` needs a password here, so I could not test running `nix store optimise` or measure its real saving.
- **D (registry)**: `nix registry resolve nixpkgs` now returns `https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1`. That is Determinate's default registry (`flake-registry = https://install.determinate.systems/flake-registry/stable/flake-registry.json`) and `nix-path = nixpkgs=flake:https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/*.tar.gz`, a **third** moving source, different from the dotfiles lock and from every project lock. `nix registry list` also shows a second `nixpkgs` entry (`github:NixOS/nixpkgs/nixpkgs-unstable`); resolution returns the weekly one (I did not look up why). To pin it to the dotfiles' revision you need a user-level registry entry (home-manager `nix.registry`, which writes `~/.config/nix/registry.json`) or a custom `flake-registry` in `nix.custom.conf`. I did not test either on this setup.
- **B / C / E**: no tooling on this machine; they are decisions and lock edits.

## 3. Recommendation, split by who decides

**You can do alone, now, with no lock change:**

1. Schedule `nix store optimise` (weekly, root). Expected ≥ 5.7 GiB back, repeatable as the store grows. Reason it beats the setting: `auto-optimise-store` is probably safe on 2.35.2 but not endorsed by Determinate on macOS yet ([installer PR still open](https://github.com/DeterminateSystems/nix-installer/pull/1793)); the explicit command is the path nix-darwin and the Nix manual document.
2. Prune stale roots: old `headless` worktrees (21 with `.direnv` profiles, six nixpkgs revisions), forks, side projects, dotfiles `result` links, then let Determinate's GC run. Most of the 48 tool copies disappear this way, with zero effect on anyone else's pins.
3. Optional and small: point the user-level registry at the dotfiles' nixpkgs, so ad-hoc `nix shell nixpkgs#x` stops using a weekly third revision. Existing locks do not move.
4. Fix inside dotfiles: `onepassword-shell-plugins` locks its own nixpkgs (`nixpkgs_2`, `6dadaf43`) because there is no `follows`. One line in `flake.nix` (`inputs.onepassword-shell-plugins.inputs.nixpkgs.follows = "nixpkgs"`), the same way the other inputs are already wired. This changes `flake.lock`, so it is a decision for you, not something I did.

**Needs the team:**

5. A shared nixpkgs pin that all consuming repos follow, plus a shared update day (options B, E). This is the only route to one path per tool across repos, and it has costs the team must accept: `connect` is seven months behind, `weblate` and `device-database` about eight (I cannot tell whether on purpose), the devenv repos build from `cachix/devenv-nixpkgs` and the flake repos from `NixOS/nixpkgs`, and pulling those together changes what each repo's tools are. At minimum, `cm-process`'s `pm` input should `follow` its nixpkgs, which removes one copy set with a single `devenv.yaml` line.
6. Only then, align dotfiles to the pin (option C). Not the reverse (C').

**Not worth it:** aligning dotfiles with the projects alone. The global profile holds one copy per tool; the 48 copies are almost all project and worktree roots.

## 4. Not verified

- **Real savings of `nix store optimise`**: needs root and a run; I only estimated 5.7 GiB from hashing files over 256 KiB. Files under 256 KiB were not hashed, so the real number is higher, but APFS accounting (clones, sparse files, `du` vs. bytes on disk) was not checked.
- **GiB freed by pruning stale roots**: not measured. A measurement needs a dry run of "what becomes dead if these roots go", which I did not build.
- **Dependency closures** of the duplicated tools (ICU, openssl, …) are not in the 2.1 GiB figure.
- **Whether `cachix/devenv-nixpkgs` paths equal `NixOS/nixpkgs` paths** for untouched packages at the same upstream commit. devenv-nixpkgs is a patched nixpkgs; sharing between a devenv repo and a flake repo may need identical derivations, which I did not test (it would need evaluating two nixpkgs trees).
- **The `tes/npm-packages` (`lib-config`) source and `lib-config/devenv/default.nix`**: private SSH repo, not in the local store. Statement that it "does not pin nixpkgs" rests on `flake: false` plus devenv's documented import behaviour and on the consumers' lock files, not on reading the module.
- **Whether Nix #14676 is the fix nix-darwin's assertion refers to.** Version gate taken from nix-darwin's source as is.
- **Determinate's macOS default** is read from `nix config show`, `/etc/nix/nix.conf` and the open installer PR. I found no Determinate document stating it.
- **A launchd job for `nix store optimise` and a user-level registry** in this nix-darwin + Determinate setup: designed from the module options, not tried.
- **Roots shown as `{censored}`**: `nix-store --gc --print-roots` redacted 2,265 entries (roots belonging to other users' or processes' paths); the per-path root lists above exclude them.

## 5. Follow-up, 2026-11-13: APFS, and what was acted on

### 5.1 Can APFS deduplicate the store?

Question: APFS has copy-on-write. Can the store share data between duplicate files through it, or through symlinks? Checked on this Mac:

| Check | Result |
|---|---|
| The `/nix` volume | its own APFS volume, "Nix Store"; 53.0 GB used on disk against 49 GB counted by `du` over `/nix/store`. Nothing is shared today: the disk holds every byte `du` counts |
| A hard link on APFS (`ln`) | same inode as the original, link count 2, no extra space |
| A clone on APFS (`cp -c`, copy-on-write) | its own inode, link count 1, no extra space; `du` counts it in full (128 MiB reported for 64 MiB on disk) |
| What Nix uses | hard links, under `/nix/store/.links`, through `nix store optimise` or `auto-optimise-store` |
| Does Nix use clones | no direct reference to `clonefile` in the `nix` binary, `libnixutil` or `libnixstore` of Determinate Nix 3.22.2 (`nm -u`) |
| Symlinks | Nix uses them to build profiles and generations out of store paths, not to deduplicate files inside the store |

So:

- **Yes, APFS can deduplicate the store, and the supported way is hard links.** `nix store optimise` does exactly that, and it suits a store whose files never change.
- **APFS clones would save the same space, but Nix does not create them.** A third-party tool that replaces duplicates with clones would be working behind Nix's back on a store Nix assumes it owns; with hard links available there is no reason to.
- **Neither mechanism merges two different builds of the same tool version.** Their files differ (section 1.2), so only a shared nixpkgs pin removes those copies.
- This closes the "APFS accounting" item in section 4 as far as clones go: none are in use, so `du` is an honest measure here.

### 5.2 What was acted on

| Recommendation | Status |
|---|---|
| 1. Scheduled `nix store optimise` | Done: `modules/features/nix-store-optimise.nix`, a root launchd daemon, Sunday 04:15. First run on 2026-11-13: the Nix volume went from 50,529 MiB to 42,354 MiB on disk, **8.0 GiB freed**, 379,133 links, in about 11 minutes. Afterwards `nix store verify --recursive` re-hashed the 759 paths of the running system without a finding. Open: the process ended on a broken-pipe signal and wrote no summary, so it is not proven that the pass covered the whole store; a second run that frees next to nothing would prove it |
| 2. Prune stale roots | Partly done on 2026-11-13: 14 of the 31 `headless` worktrees removed, the 6 that were clean and in `main` and the 8 that were in `main` with uncommitted files. Those files are in `headless`'s stash, one entry per worktree, labelled "removed worktree <name>". Branches were kept. 196 store paths (1.6 GiB by NAR size) became collectable. Left: 6 clean, pushed worktrees, 11 with work that exists only there, and the dotfiles worktree `.claude/worktrees/open-code-nix-setup-3176a9`, which holds a `result` link |
| 3. User-level registry pinned to the dotfiles' nixpkgs | Not done, untested on Determinate Nix |
| 4. `onepassword-shell-plugins` follows the dotfiles' nixpkgs | Done: the lock drops its second nixpkgs (`nixpkgs_2`); the host builds |
| 5–6. A shared team pin | Out of scope: it needs the team |

## Sources

- Nix issue [#7273](https://github.com/NixOS/nix/issues/7273): `.tmp-link` errors with `auto-optimise-store` on macOS (closed).
- Nix PR [#14676](https://github.com/NixOS/nix/pull/14676): `makeTempPath` in `optimizePath_`, merged 2025-12-01.
- Lix issue [#477](https://git.lix.systems/lix-project/lix/issues/477): disallow `auto-optimise-store` on Darwin; Lix installer [commit](https://git.lix.systems/lix-project/lix-installer/commit/35864576243828e0383aaee86805865ea7271ca0) "Turn off auto optimise store on mac".
- DeterminateSystems/nix-installer PR [#1793](https://github.com/DeterminateSystems/nix-installer/pull/1793): "Enable auto-optimise-store on macOS" (open at the time of writing).
- nix-darwin [`modules/nix/default.nix`](https://github.com/nix-darwin/nix-darwin/blob/master/modules/nix/default.nix) (assertion text, option text) and [`modules/nix/nixpkgs-flake.nix`](https://github.com/nix-darwin/nix-darwin/blob/master/modules/nix/nixpkgs-flake.nix) (`setFlakeRegistry`).
- Nix manual, [`nix store optimise`](https://nix.dev/manual/nix/2.19/command-ref/new-cli/nix3-store-optimise).
- Determinate Nix: [documentation](https://docs.determinate.systems/determinate-nix/), [best practices](https://docs.determinate.systems/determinate-nix/best-practices/), [managed garbage collection](https://learn.determinate.systems/determinate-nixd/managed-garbage-collection), [determinate-nixd](https://docs.determinate.systems/determinate-nix/determinate-nixd/).
- devenv: [inputs](https://devenv.sh/inputs/), [yaml options](https://devenv.sh/reference/yaml-options), [pinning](https://devenv.sh/pinning/).
- Local files read: `dotfiles/flake.lock`, `dotfiles/flake.nix`, `dotfiles/modules/features/devenv.nix`, the lock and `devenv.yaml`/`devenv.nix` files named in section 1.1 under `~/Developer/work/`, `developer/README.md`, `developer/flake.nix`, `developer/docs/adr/0002-…`, `/etc/nix/nix.conf`, `/etc/nix/nix.custom.conf`, `nix config show`.
