{ lib, ... }:
{
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    enableIPv6 = true;
    nameservers = [
      "8.8.8.8"
    ];
    defaultGateway = "170.64.128.1";
    defaultGateway6 = {
      address = "";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          {
            address = "170.64.147.60";
            prefixLength = 19;
          }
          {
            address = "10.49.0.5";
            prefixLength = 16;
          }
        ];
        #        ipv6.addresses = [
        #          { address="fe80::a49f:c2ff:fe7f:3292"; prefixLength=64; }
        #        ];
        ipv4.routes = [
          {
            address = "170.64.128.1";
            prefixLength = 32;
          }
        ];
        #        ipv6.routes = [ { address = ""; prefixLength = 128; } ];
      };
      eth1 = {
        ipv4.addresses = [
          {
            address = "10.126.0.2";
            prefixLength = 20;
          }
        ];
        #        ipv6.addresses = [
        #          { address="fe80::309a:fdff:fe14:eca8"; prefixLength=64; }
        #        ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="a6:9f:c2:7f:32:92", NAME="eth0"
    ATTR{address}=="32:9a:fd:14:ec:a8", NAME="eth1"
  '';
}
