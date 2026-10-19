# glab - the GitLab CLI
# https://gitlab.com/gitlab-org/cli
#
# Installed on the work host by the 1Password shell plugins
# (1password/default.nix); this module only pins its version.
_: {
  # ── Overlay: glab 1.123.0 ───────────────────────────────────────────────────
  # nixpkgs-unstable is on 1.114.0 (as of 2026-10-19); the work flakes pin up to
  # 1.121.0. nixpkgs builds glab from Go source, so instead of re-vendoring its
  # modules this installs the upstream release binary, as the headless repo's
  # overlay does. Drop this once nixpkgs ships >= 1.123.0.
  #
  # The hash is upstream's checksums.txt entry for the asset, in SRI form:
  #   curl -sL "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/<version>/checksums.txt"
  flake.modules.darwin.glab = {
    nixpkgs.overlays = [
      (_final: prev: {
        glab = prev.stdenvNoCC.mkDerivation (finalAttrs: {
          pname = "glab";
          version = "1.123.0";

          src = prev.fetchurl {
            url = "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${finalAttrs.version}/glab_${finalAttrs.version}_darwin_arm64.tar.gz";
            hash = "sha256-v3dupH07MEECZ62rnIcJkL4nToX23MzO5CifXs8Tht8=";
          };

          sourceRoot = ".";

          nativeBuildInputs = [prev.installShellFiles];

          # The same completions nixpkgs' source build generates. glab creates
          # its config dir on start, and the sandbox has no writable $HOME.
          installPhase = ''
            runHook preInstall
            install -Dm755 bin/glab $out/bin/glab
            export HOME=$TMPDIR
            installShellCompletion --cmd glab \
              --bash <($out/bin/glab completion -s bash) \
              --fish <($out/bin/glab completion -s fish) \
              --zsh <($out/bin/glab completion -s zsh)
            runHook postInstall
          '';

          meta =
            prev.glab.meta
            // {
              changelog = "https://gitlab.com/gitlab-org/cli/-/releases/v${finalAttrs.version}";
              platforms = ["aarch64-darwin"];
            };
        });
      })
    ];
  };
}
