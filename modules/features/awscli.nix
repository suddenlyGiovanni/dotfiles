# AWS CLI - XDG configuration and profiles
# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
#
# Work host: AWS IAM Identity Center (SSO) — run `aws sso login` to authenticate.
# Personal host: 1Password shell plugin (see 1password/default.nix).
#
# On work host, awscli2 is installed directly here.
# On personal host, it's installed via 1Password shell plugins.
_: {
  flake.modules.homeManager.awscli = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles) isWorkHost;
  in {
    # Install awscli2 directly on work host (personal gets it via 1password shell plugins)
    home.packages = lib.optionals isWorkHost [pkgs.awscli2];

    # ── XDG Compliance ──────────────────────────────────────────────────────────
    # Move AWS config and credentials to XDG directories
    # Default locations would be ~/.aws/config and ~/.aws/credentials
    home.sessionVariables = {
      AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";
      AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";
    };

    # ── AWS SSO Profile (work only) ───────────────────────────────────────────
    # Declaratively manage ~/.config/aws/config
    # Authenticate with: aws sso login
    xdg.configFile."aws/config" = lib.mkIf isWorkHost {
      text = ''
        [default]
        sso_start_url = https://d-9967527825.awsapps.com/start
        sso_region = eu-central-1
        sso_account_id = 832394005187
        sso_role_name = internal-tools-admin
        region = eu-central-1
        output = json

        [profile admin]
        sso_start_url = https://d-9967527825.awsapps.com/start
        sso_region = eu-central-1
        sso_account_id = 832394005187
        sso_role_name = SystemAdministrator
        region = eu-central-1
        output = json

        [profile deploy]
        sso_start_url = https://d-9967527825.awsapps.com/start
        sso_region = eu-central-1
        sso_account_id = 832394005187
        sso_role_name = AdministratorAccess
        region = eu-central-1
        output = json
      '';
    };
  };
}
