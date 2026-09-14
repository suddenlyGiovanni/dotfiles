# herdr - Terminal workspace manager for AI coding agents
# https://github.com/herdrdev/herdr
# https://herdr.dev/docs/install/
#
# Installed from nixpkgs (cached binary) rather than the upstream flake, which
# builds from source via rust-overlay + zig. `herdr update` / `herdr channel`
# only manage direct installs; this version tracks our nixpkgs pin.
#
# The nixpkgs package ships no shell completions, so they're generated from
# `herdr completion <shell>` in a separate derivation — overriding the package's
# postInstall would miss the binary cache and rebuild herdr from source.
#
# The Claude Code skill comes from the package's own source, pinned to the same
# version as the binary. `herdr integration install` (agent hooks) is not
# declared here.
_: {
  flake.modules.homeManager.herdr = {
    lib,
    pkgs,
    ...
  }: let
    herdr = lib.getExe pkgs.herdr;
    herdrCompletions = pkgs.runCommand "herdr-completions" {nativeBuildInputs = [pkgs.installShellFiles];} ''
      export HOME=$TMPDIR
      installShellCompletion --cmd herdr \
        --bash <(${herdr} completion bash) \
        --fish <(${herdr} completion fish) \
        --zsh  <(${herdr} completion zsh)
    '';
  in {
    home.packages = [pkgs.herdr herdrCompletions];

    programs.claude-code.skills.herdr = "${pkgs.herdr.src}/skills/herdr";
  };
}
