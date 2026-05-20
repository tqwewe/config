# Handled by agenix
# https://github.com/ryantm/agenix
let
  macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsnUFtG1IYtexjTjCbvCknN/lr3OuittQzsWxAlajYP ariseyhun@live.com.au";
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZswi6XsdjP5E/O0c9zgmMNCA4cHQtzznhGuHT2eX8S";
  bigscreen = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpcJzDewbJTcPdibiEm2bd2rWGBq6h0LOzYXU5eSjQv dev@tqwewe.com";
in
{
  "deepseekApiKey.age".publicKeys = [
    macbook
    desktop
    bigscreen
  ];
  "openclawGatewayPassword.age".publicKeys = [
    macbook
    desktop
    bigscreen
  ];
  "openclawTelegramBotToken.age".publicKeys = [
    macbook
    desktop
    bigscreen
  ];
  "weatherApiKey.age".publicKeys = [ desktop ];
}
