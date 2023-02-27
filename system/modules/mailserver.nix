# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, ... }: {
  imports = [
    inputs.mailserver.nixosModule
  ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "ariseyhun@live.com.au";
  
  mailserver = {
    enable = true;

    fqdn = "mail.theari.dev";
    domains = [ "theari.dev" ];

    loginAccounts = {
      "info@theari.dev" = {
        hashedPassword = "$2b$05$SZOUIO97tCErijTOe60tWOU8ZmjJq7kQy9eWj70qKC7PH2s.Gs9qG";
      };
    };

    certificateScheme = 3;
  };
}
