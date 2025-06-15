# Handled by agenix
# https://github.com/ryantm/agenix
let
  macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsnUFtG1IYtexjTjCbvCknN/lr3OuittQzsWxAlajYP ariseyhun@live.com.au";
  pc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZswi6XsdjP5E/O0c9zgmMNCA4cHQtzznhGuHT2eX8S";
in
{
  "copilotApiKey.age".publicKeys = [ macbook ];
  "deepseekApiKey.age".publicKeys = [ macbook ];
  "weatherApiKey.age".publicKeys = [ pc ];
}
