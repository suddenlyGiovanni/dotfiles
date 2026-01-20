# Security Configuration
# This module manages security settings (firewall, Touch ID, etc.)
_: {
  # Enable sudo authentication with Touch ID
  security.pam.services.sudo_local.touchIdAuth = true;

  # Application firewall settings
  networking.applicationFirewall = {
    enable = true; # Enable the internal firewall
    allowSigned = true; # Allow any signed application to accept incoming requests
    allowSignedApp = true; # Allow any downloaded signed application to accept incoming requests
    enableStealthMode = true; # Drop incoming ICMP requests like ping
  };
}
