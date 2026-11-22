# gcloud - Google Cloud CLI (also bq, gsutil)
# https://cloud.google.com/sdk/docs
#
# Installed from nixpkgs (`pkgs.google-cloud-sdk`, cached binary). The package
# ships bash/fish/zsh completions. `gcloud components install/update` can't
# write to the store; add components declaratively instead:
#   pkgs.google-cloud-sdk.withExtraComponents [pkgs.google-cloud-sdk.components.<name>]
#
# Mainly here so gws can create the Cloud project and OAuth client: gws itself
# lives in the family vault's devenv (~/Documents/family, `just google-setup`).
# Auth state lives in ~/.config/gcloud (already the default) and
# isn't declared here; log in with `gcloud auth login`.
_: {
  flake.modules.homeManager.gcloud = {pkgs, ...}: {
    home.packages = [pkgs.google-cloud-sdk];
  };
}
