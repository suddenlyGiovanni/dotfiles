# Security - macOS security and firewall configuration
# https://daiderd.com/nix-darwin/manual/index.html#opt-security.pam
# https://daiderd.com/nix-darwin/manual/index.html#opt-networking.applicationFirewall
#
# Enables Touch ID for sudo authentication via PAM and configures the
# application firewall (incoming connections, signed app exceptions,
# stealth mode for dropping ICMP probes).
_: {
  flake.modules.darwin.security = _: {
    # Enable sudo authentication with Touch ID
    security.pam.services.sudo_local.touchIdAuth = true;

    # Application firewall settings
    networking.applicationFirewall = {
      enable = true; # Enable the internal firewall
      allowSigned = true; # Allow any signed application to accept incoming requests
      allowSignedApp = true; # Allow any downloaded signed application to accept incoming requests
      enableStealthMode = true; # Drop incoming ICMP requests like ping
    };
  };
}
