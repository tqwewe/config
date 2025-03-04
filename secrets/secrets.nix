# Handled by agenix
# https://github.com/ryantm/agenix
let
  macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsnUFtG1IYtexjTjCbvCknN/lr3OuittQzsWxAlajYP ariseyhun@live.com.au";
in
{
  "copilotApiKey.age".publicKeys = [ macbook ];
  "deepseekApiKey.age".publicKeys = [ macbook ];
}
