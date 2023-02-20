# NixOS Configuration

To install, clone the repo and run the `update-system.sh` script

```bash
$ git clone git@github.com:tqwewe/config.git && cd ./config
$ ./update-system.sh
```

Next, initialiaze home manager

```bash
$ nix build --no-link .#homeConfigurations.ari@ari.activationPackage
$ "$(nix path-info .#homeConfigurations.ari@ari.activationPackage)"/activate
$ ./update-home.sh
```

The `./update-system.sh` and `./update-home.sh` scripts can be run when the config is updated.

This project was inspired by the minimal starter config at https://github.com/Misterio77/nix-starter-configs.
