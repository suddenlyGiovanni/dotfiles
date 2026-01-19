# AWS CLI - Unified tool to manage AWS services
# This module installs the AWS CLI and configures XDG-compliant paths
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkDefault
    ;
in {
  # ── XDG Compliance ──────────────────────────────────────────────────────────
  # Move AWS config and credentials to XDG directories
  home.sessionVariables = {
    AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";
    AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";
  };

  # ── Packages ────────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    awscli2 # Unified tool to manage your AWS services
  ];
}
