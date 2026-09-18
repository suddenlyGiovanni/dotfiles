# starship - A minimal, blazing-fast, and customizable prompt for any shell
# https://starship.rs/
# https://github.com/nix-community/home-manager/blob/master/modules/programs/starship.nix
#
# ══════════════════════════════════════════════════════════════════════════════
# LAYOUT
# ══════════════════════════════════════════════════════════════════════════════
#
#   <repo> headless <worktree> alchemy-local-dev-r2-4538d1/apps/docs <branch> worktree-… → origin/main ~2 +1 ?3 (+14 -3 lines)
#   ❯                                 <error> 1 ERROR <clock> 12s <bun> 1.4.2 <nix> nix
#
# (<name> stands for the glyph of that name in glyphTable below.)
#
# Left, line 1 — where you are: [ssh host] [repo + worktree glyph, linked
#   worktrees only] directory, branch → upstream, git status, line metrics.
# Left, line 2 — the input line: background jobs, `❯`.
# Right — what the last command did, then context that only shows up when it
#   applies: exit status, duration, direnv problems, herdr pane, AWS profile,
#   gcloud (only with a CLOUDSDK_* var set), docker context, toolchain, nix.
#
# Principle: everyday segments are an icon only; rare or alarming ones spell
# themselves out ("direnv not allowed", "3 conflicted"). `prompt-legend`
# (fish, nu) prints every glyph with its name, the git status key, and
# `starship explain` for the current directory.
#
# ══════════════════════════════════════════════════════════════════════════════
# WHY GLYPHS ARE CODEPOINTS, NOT LITERALS
# ══════════════════════════════════════════════════════════════════════════════
#
# Nerd Font icons live in Unicode Private Use Areas. Literal copies of them
# were silently stripped from this file by an editor/tool pass in commit
# f551551 (2026-01-05): 83 symbols became plain spaces and the prompt lost its
# icons without any error. Glyphs are therefore spelled as hex codepoints and
# named after their Nerd Font class (https://www.nerdfonts.com/cheat-sheet), and
# an assertion below fails evaluation if any `*symbol` setting is blank.
#
# ══════════════════════════════════════════════════════════════════════════════
# SHELL INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# Shell integrations are enabled from config.programs.<shell>.enable. Transient
# prompt (fish): on fish >= 4.1 starship uses fish's native transient prompt.
# HM's enableTransience is fish-only, so nu gets the equivalent through its own
# TRANSIENT_PROMPT_* variables (below).
_: {
  flake.modules.homeManager.starship = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) attrByPath mkDefault;

    # Safe lookup for shell enable flags with fallback to false
    # This prevents evaluation failures if a shell module isn't imported
    shellEnabled = path: attrByPath path false config;

    # A codepoint (hex) as a UTF-8 string. Nix has no \u escape, JSON does —
    # astral-plane codepoints (md-* icons, U+F0000+) need a UTF-16 surrogate pair.
    glyph = hex: let
      cp = (builtins.fromTOML "cp = 0x${hex}").cp;
      esc = n: "\\u" + lib.fixedWidthString 4 "0" (lib.toHexString n);
      off = cp - 65536;
      utf16 =
        if cp < 65536
        then esc cp
        else esc (55296 + off / 1024) + esc (56320 + lib.mod off 1024);
    in
      builtins.fromJSON ''"${utf16}"'';

    # name = [ codepoint  nerd-font-class ]
    glyphTable = {
      repo = ["f401" "oct-repo"];
      worktree = ["ec7e" "cod-worktree"];
      branch = ["f418" "oct-git_branch"];
      tag = ["f412" "oct-tag"];
      lock = ["f033e" "md-lock"];
      error = ["f467" "oct-x"];
      clock = ["f0150" "md-clock_outline"];
      ssh = ["eb01" "cod-globe"];
      direnv = ["f107f" "md-folder_cog"];
      herdr = ["f018d" "md-console"];
      aws = ["f0ef" "fa-aws"];
      gcloud = ["f11f6" "md-google_cloud"];
      docker = ["f308" "linux-docker"];
      nix = ["f313" "linux-nixos"];
      package = ["f03d7" "md-package_variant_closed"];
      bun = ["e76f" "dev-bun"];
      nodejs = ["e718" "dev-nodejs_small"];
      deno = ["e7c0" "dev-denojs"];
      python = ["e235" "fae-python"];
      rust = ["f1617" "md-language_rust"];
      golang = ["e627" "seti-go"];
      java = ["e738" "dev-java"];
      kotlin = ["e634" "custom-kotlin"];
      swift = ["e755" "dev-swift"];
      ruby = ["e791" "dev-ruby_rough"];
      lua = ["e620" "seti-lua"];
    };
    nf = lib.mapAttrs (_: entry: glyph (builtins.head entry)) glyphTable;

    # Git status key printed by `prompt-legend` (fish and nu)
    gitStatusKey = [
      "  ~N modified   +N staged   ?N untracked   »N renamed   ✘N deleted   N conflicted"
      "  ⇡N ahead of upstream   ⇣N behind upstream   → origin/x  upstream differs from branch name"
      "  (+A -D lines)  lines added/removed vs HEAD"
      "  (stashes are not shown: they are shared by every worktree of a repo)"
    ];

    starship = lib.getExe config.programs.starship.package;
    inherit (lib.hm.nushell) toNushell;

    # Toolchains shown on the right as `<icon> <version>` when detected.
    languages = ["bun" "nodejs" "deno" "python" "rust" "golang" "java" "kotlin" "swift" "ruby" "lua"];

    # Every `*symbol` setting that renders as nothing — see "WHY GLYPHS ARE
    # CODEPOINTS" above.
    blankSymbols = let
      walk = path: value:
        if lib.isAttrs value
        then lib.concatLists (lib.mapAttrsToList (name: walk (path ++ [name])) value)
        else
          lib.optional
          (lib.isString value && lib.hasSuffix "symbol" (lib.last path) && builtins.match "[[:space:]]*" value != null)
          (lib.concatStringsSep "." path);
    in
      walk [] config.programs.starship.settings;
  in {
    assertions = [
      {
        assertion = blankSymbols == [];
        message = "starship: blank symbol setting(s), likely stripped glyphs: ${lib.concatStringsSep ", " blankSymbols}";
      }
    ];

    # Legend for the prompt: glyph names, git status key, and what each
    # segment in the current directory means.
    programs.fish.functions.prompt-legend = lib.mkIf (shellEnabled ["programs" "fish" "enable"]) {
      description = "Explain the starship prompt: glyphs, git status key, current segments";
      body = ''
        set_color --bold; echo "Glyphs"; set_color normal
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: entry: "printf '  %s  %-9s U+%-6s nf-%s\\n' ${lib.escapeShellArg nf.${name}} ${name} ${lib.toUpper (builtins.head entry)} ${lib.last entry}") glyphTable)}
        echo
        set_color --bold; echo "Git status (files)"; set_color normal
        ${lib.concatMapStringsSep "\n" (line: "echo ${lib.escapeShellArg line}") gitStatusKey}
        echo
        set_color --bold; echo "This directory"; set_color normal
        starship explain
      '';
    };

    programs.nushell.extraConfig = lib.mkIf (shellEnabled ["programs" "nushell" "enable"]) (lib.mkAfter ''
      # Explain the starship prompt: glyphs, git status key, current segments
      def prompt-legend [] {
          print $"(ansi attr_bold)Glyphs(ansi reset)"
          ${toNushell {multiline = false;} (lib.mapAttrsToList (name: entry: {
          inherit name;
          code = builtins.head entry;
          class = lib.last entry;
        })
        glyphTable)} | each {|g|
              print $"  (char --unicode $g.code)  ($g.name | fill --width 9) U+($g.code | str uppercase | fill --width 6) nf-($g.class)"
          } | ignore
          print ""
          print $"(ansi attr_bold)Git status \(files\)(ansi reset)"
          ${lib.concatMapStringsSep "\n    " (line: "print ${toNushell {} line}") gitStatusKey}
          print ""
          print $"(ansi attr_bold)This directory(ansi reset)"
          ^${starship} explain
      }

      # Transient prompt, as enableTransience does for fish: once a command runs,
      # its prompt collapses to the prompt character.
      $env.TRANSIENT_PROMPT_COMMAND = {|| ^${starship} module character }
      $env.TRANSIENT_PROMPT_INDICATOR = ""
      $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = ""
      $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = ""
    '');

    programs.starship = {
      enable = true;
      package = mkDefault pkgs.starship;

      enableBashIntegration = mkDefault (shellEnabled ["programs" "bash" "enable"]);
      enableZshIntegration = mkDefault (shellEnabled ["programs" "zsh" "enable"]);
      enableFishIntegration = mkDefault (shellEnabled ["programs" "fish" "enable"]);
      enableNushellIntegration = mkDefault (shellEnabled ["programs" "nushell" "enable"]);
      enableTransience = mkDefault (shellEnabled ["programs" "fish" "enable"]);

      # Written to ~/.config/starship.toml — https://starship.rs/config/
      settings =
        {
          add_newline = false;
          scan_timeout = 30;
          command_timeout = 500;

          # Explicit module lists instead of "$all": $all grows with every
          # release (maven, mise, pixi, netns, … since 1.23) and puts
          # everything on one side.
          format = lib.concatStrings [
            "$username"
            "$hostname"
            "$container"
            "\${custom.worktree}"
            "$directory"
            "$git_branch"
            "$git_commit"
            "$git_state"
            "$git_status"
            "$git_metrics"
            "$line_break"
            "$jobs"
            "$character"
          ];
          right_format = lib.concatStrings ([
              "$status"
              "$cmd_duration"
              "$direnv"
              "\${env_var.HERDR_ENV}"
              "\${env_var.AWS_PROFILE}"
              "$gcloud"
              "$docker_context"
              "$package"
            ]
            ++ map (m: "$" + m) languages
            ++ ["$nix_shell" "$shell"]);

          # `starship statusline claude-code` (statusLine in Claude Code's
          # settings.json) renders this profile from the session JSON on stdin.
          profiles.claude-code = lib.concatStrings [
            "$claude_model"
            "\${custom.worktree}"
            "$directory"
            "$git_branch"
            "$git_status"
            "$claude_context"
            "$claude_cost"
          ];

          # ── Prompt character ──────────────────────────────────────────────────
          character = {
            success_symbol = "[❯](bold green)";
            error_symbol = "[❯](bold red)";
            vimcmd_symbol = "[❮](bold green)";
            vimcmd_replace_one_symbol = "[❮](bold purple)";
            vimcmd_replace_symbol = "[❮](bold purple)";
            vimcmd_visual_symbol = "[❮](bold yellow)";
          };

          # ── Where am I ────────────────────────────────────────────────────────

          # Starship has no worktree awareness: inside a linked worktree
          # `truncate_to_repo` treats the worktree root as the repo, so the real
          # repo name disappears (starship#6981, #6604). This prints it — only in
          # linked worktrees, where git-dir and git-common-dir differ. Runs under
          # sh so it doesn't pay a fish startup per prompt.
          custom.worktree = {
            description = "Repository a linked git worktree belongs to";
            require_repo = true;
            when = true;
            shell = ["sh"];
            command = ''
              set -f
              IFS='
              '
              set -- $(git rev-parse --path-format=absolute --git-common-dir --git-dir 2>/dev/null)
              [ "$#" -eq 2 ] && [ "$1" != "$2" ] || exit 0
              common=''${1%/.git}
              common=''${common##*/}
              printf '%s' "''${common%.git}"
            '';
            # Conditional group: custom modules render even when $output is empty.
            format = "([${nf.repo} $output ${nf.worktree}]($style) )";
            style = "bold blue";
          };

          # Path from the repo (or worktree) root; outside repos, the last three
          # directories. The worktree module above already names the repo, so the
          # path leading up to the root is dropped.
          directory = {
            truncation_length = 3;
            truncate_to_repo = true;
            truncation_symbol = "…/";
            read_only = " ${nf.lock}";
            style = "bold cyan";
            repo_root_style = "bold cyan";
            format = "[$path]($style)[$read_only]($read_only_style) ";
            repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
          };

          hostname = {
            ssh_only = true;
            ssh_symbol = "${nf.ssh} ";
            format = "[$ssh_symbol$hostname]($style) in ";
            style = "bold dimmed green";
          };

          username = {
            show_always = false;
            format = "[$user]($style) @ ";
            style_root = "bold red";
            style_user = "bold yellow";
          };

          container = {
            format = "[$symbol \\[$name\\]]($style) ";
            symbol = "⬢";
            style = "bold red dimmed";
          };

          # ── Git ───────────────────────────────────────────────────────────────

          # Full branch name (agent branches are `worktree-<name>`, up to ~55
          # chars). The upstream is shown only when its name differs from the
          # branch — for agent worktrees that is `origin/main`.
          git_branch = {
            symbol = "${nf.branch} ";
            format = "[$symbol$branch( → $remote_name/$remote_branch)]($style) ";
            style = "bold purple";
          };

          git_commit = {
            tag_symbol = " ${nf.tag} ";
            only_detached = true;
            tag_disabled = false;
          };

          git_state = {
            format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
            style = "bold yellow";
          };

          # One colour per kind; each entry carries its own trailing space.
          # Stashes are hidden: the stash stack is repo-wide, so every worktree
          # would show it forever.
          git_status = {
            format = "([$all_status$ahead_behind]($style))";
            style = "bold";
            conflicted = "[\${count} conflicted ](bold red)";
            ahead = "[⇡\${count} ](bold green)";
            behind = "[⇣\${count} ](bold yellow)";
            diverged = "[⇡\${ahead_count}⇣\${behind_count} ](bold red)";
            up_to_date = "";
            untracked = "[?\${count} ](bold blue)";
            stashed = "";
            modified = "[~\${count} ](bold yellow)";
            staged = "[+\${count} ](bold green)";
            renamed = "[»\${count} ](bold cyan)";
            deleted = "[✘\${count} ](bold red)";
            typechanged = "";
          };

          # Line counts, parenthesised and labelled so `+14` isn't read as
          # "14 staged files". Nested groups drop a zero side; the whole
          # segment disappears when both are zero.
          # Slowest module (~40 ms in headless); core.fsmonitor didn't help
          # (git_status + git_metrics ~42 ms with it, measured 2026-09-14).
          git_metrics = {
            disabled = false;
            only_nonzero_diffs = true;
            format = "(\\((([+$added]($added_style) )([-$deleted]($deleted_style) ))lines\\) )";
            added_style = "green";
            deleted_style = "red";
          };

          # ── Right side: last command ─────────────────────────────────────────

          status = {
            disabled = false;
            format = "[$symbol$status( $common_meaning)( $signal_name)]($style) ";
            symbol = "${nf.error} ";
            style = "bold red";
            recognize_signal_code = true;
            map_symbol = true;
            not_executable_symbol = "🚫 ";
            not_found_symbol = "🔍 ";
            sigint_symbol = "🧱 ";
            signal_symbol = "⚡ ";
          };

          cmd_duration = {
            min_time = 2000;
            format = "[${nf.clock} $duration]($style) ";
            style = "bold yellow";
            show_milliseconds = false;
          };

          # ── Right side: context, only when it applies ─────────────────────────

          # Silent while the .envrc is allowed and loaded; spells out the problem
          # otherwise. The glyph is literal format text rather than $symbol so the
          # conditional group stays empty when both messages are.
          direnv = {
            disabled = false;
            format = "([${nf.direnv} direnv$allowed$loaded]($style) )";
            style = "bold yellow";
            allowed_msg = "";
            not_allowed_msg = " not allowed";
            denied_msg = " denied";
            loaded_msg = "";
            unloaded_msg = " not loaded";
          };

          # herdr (terminal workspace manager for agents) exports HERDR_ENV=1.
          env_var.HERDR_ENV = {
            description = "Running inside a herdr pane";
            format = "[${nf.herdr} herdr]($style) ";
            style = "bold green";
          };

          # The aws module shows the default profile's region (and an expiry
          # marker) in every directory. Only an explicitly selected profile is
          # worth the space.
          aws.disabled = true;
          env_var.AWS_PROFILE = {
            description = "Selected AWS profile";
            format = "[${nf.aws} aws $env_value]($style) ";
            style = "bold yellow";
          };

          gcloud = {
            symbol = "${nf.gcloud} gcloud ";
            format = "[$symbol$account(@$domain)( \\($project\\))]($style) ";
            detect_env_vars = ["CLOUDSDK_CONFIG" "CLOUDSDK_ACTIVE_CONFIG_NAME" "CLOUDSDK_CORE_PROJECT"];
          };

          docker_context = {
            symbol = "${nf.docker} ";
            format = "[$symbol$context]($style) ";
          };

          package = {
            symbol = "${nf.package} ";
            format = "[$symbol$version]($style) ";
          };

          # `use flake` via direnv always reports "impure (nix-shell-env)", so
          # the state and name carry no information.
          nix_shell = {
            symbol = "${nf.nix} ";
            format = "[$symbol$state]($style) ";
            impure_msg = "nix";
            pure_msg = "nix pure";
            unknown_msg = "nix";
          };

          # Only shells other than nu, the login shell, are worth pointing out.
          shell = {
            disabled = false;
            format = "([$indicator]($style) )";
            style = "bold white";
            fish_indicator = "fish";
            zsh_indicator = "zsh";
            bash_indicator = "bash";
            nu_indicator = "";
            unknown_indicator = "";
          };
        }
        // lib.genAttrs languages (name: {
          symbol = "${nf.${name}} ";
          format = "[$symbol($version )]($style)";
          version_format = "\${raw}";
        });
    };
  };
}
