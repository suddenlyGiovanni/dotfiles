# difftastic (difft) - Structural diff that understands syntax
# https://difftastic.wilfred.me.uk/
# https://difftastic.wilfred.me.uk/git.html (canonical git integration guide)
# https://github.com/Wilfred/difftastic
# https://github.com/nix-community/home-manager/blob/master/modules/programs/difftastic.nix
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# difftastic is a structural diff tool. It parses both sides with Tree-sitter
# and diffs the resulting ASTs, so reformatting (line breaks, brace moves,
# whitespace) is invisible while genuine semantic changes are highlighted.
#
# Complement to delta — NOT a replacement:
#   - delta:    line-based pretty-printer wrapped around git's internal diff.
#               Output is pipe-friendly ANSI; works as the default git pager.
#               Stays enabled and continues to handle `git diff` / `git show`.
#   - difft:    AST-based diff algorithm. Output is for human eyeballs
#               (side-by-side, structural), not pipe-grep, so wiring it as
#               git's primary diff engine would break agent shell loops and
#               conflict with delta. Exposed via per-command aliases (below).
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE
# ══════════════════════════════════════════════════════════════════════════════
#
# Per upstream's recommended pattern (https://difftastic.wilfred.me.uk/git.html
# under "Regular Usage"), difft is wired via aliases that scope `diff.external`
# to specific subcommands. This keeps delta the default for plain `git diff`
# / `git log` / `git show` while giving you on-demand structural diffs:
#
#   git ddiff                          difft view of unstaged changes
#   git ds                             difft view of the most recent commit
#   git dl                             difft view of recent commit patches
#   git dlog                           difft view of full log history
#   git dshow <ref>                    difft view of a specific commit
#
#   difft a.ts b.ts                    Standalone — diff two arbitrary files
#
# ══════════════════════════════════════════════════════════════════════════════
# DESIGN NOTE — WHY NOT `programs.difftastic.git.enable = true` OR difftool
# ══════════════════════════════════════════════════════════════════════════════
#
# Two HM-blessed paths exist; neither matches our requirements:
#
#   - `programs.difftastic.git.enable = true` sets `diff.external` globally,
#     replacing git's diff engine everywhere. Conflicts with delta (asserted
#     by home-manager's git module: only one of delta / diff-highlight /
#     diff-so-fancy / difftastic / patdiff / riff can own diff). Breaks
#     line-by-line output agents grep through.
#
#   - `programs.difftastic.git.diffToolMode = true` wires difft as a difftool
#     (`git difftool`). Works, but upstream actively recommends against this:
#     "for best results, we recommend `-c diff.external=difft` as described
#     above. Git passes more information to the external diff, including
#     file permission changes and rename information, so difftastic can show
#     more information."
#
# So this module enables the difftastic package + options, leaves the HM git
# integration disabled, and adds the upstream-blessed alias set directly to
# `programs.git.settings.alias`. Delta keeps owning the default git diff flow;
# difft is one keystroke away when you want structural review.
#
{
  flake.modules.homeManager.difftastic = {pkgs, ...}: {
    programs.difftastic = {
      enable = true;
      options = {
        color = "auto";
        sort-paths = true;
        tab-width = 2;
      };
    };

    # Aliases that scope `diff.external=difft` to specific commands.
    # Per https://difftastic.wilfred.me.uk/git.html#regular-usage — upstream's
    # recommended pattern, preserves delta as the default git pager.
    programs.git.settings.alias = let
      withDifft = subcommand: "-c diff.external=${pkgs.difftastic}/bin/difft ${subcommand} --ext-diff";
    in {
      ddiff = withDifft "diff";
      dshow = withDifft "show";
      dlog = withDifft "log";
      dl = withDifft "log -p";
      ds = withDifft "show";
    };
  };
}
