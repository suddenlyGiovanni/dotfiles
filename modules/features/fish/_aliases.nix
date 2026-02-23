# Fish shell aliases
# https://fishshell.com/docs/current/cmds/alias.html
#
# Aliases are not expanded inline (unlike abbreviations). Used here for
# command replacements (eza, bat, fzf) where expansion would be confusing.
# Consumed by fish/default.nix via import.
#
# Related: bat.nix (bat config), fzf.nix (fzf config), eza.nix (eza config)
{
  # Use eza as ls replacement (eza integration provides basic aliases, these are extras)
  ll = "eza --all --long --icons --header --classify --group --group-directories-first --sort=type --time-style=default --hyperlink --git --git-repos";
  tree = "eza --all --long --tree --level=2 --header --classify --group --git --icons --group-directories-first --sort=type --color-scale";

  # bat integrations (bat is configured in bat.nix, these add convenience)
  cat = "bat --paging=never";
  bathelp = "bat --plain --language=help";

  # fd/fzf powered searches
  preview = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'";
}
