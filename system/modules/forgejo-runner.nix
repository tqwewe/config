# Mirrored from ~/dev/tqwewe/zion/desktop/forgejo-runner.nix, which is where the
# forge this registers against is configured. Two copies because a flake cannot
# import a path outside its own source, and pulling zion in as an input would
# drag colmena, disko, sops-nix and hermes-agent into this lock file for one
# module. Change both, or consolidate onto one.

# Forgejo Actions runner for git.tqwewe.com, for Ari's workstation.
#
# Import this from the desktop's own configuration.nix -- it is NOT part of the
# server config. zion has Actions enabled but deliberately runs no runner: a
# cargo build peaks past what 4 GB leaves once Forgejo, Vaultwarden and restic
# have taken their share, and the OOM killer picks the largest RSS, which is one
# of those. See "Things that will bite you" in the README.
#
# The runner polls the forge outbound over HTTPS. Nothing listens here, neither
# firewall needs a hole, and a dynamic home IP is irrelevant. The desktop being
# off just means jobs queue until it is back.
#
# Registration, once. The runner does not register itself: it needs the UUID and permanent
# token of a runner that already exists.
#
#   1. Forgejo -> Site Administration -> Actions -> Runners -> Create new runner,
#      which shows a UUID and a token.
#   2. Set services.forgejoRunner.uuid to the UUID, and put the token alone in the
#      token file (root-owned, 0400):
#        printf '%s' '<token>' | sudo install -m 0400 -o root /dev/stdin /etc/forgejo-runner.token
#   3. Rebuild.
#
# A runner registered by the old gitea-actions-runner module already has both, in
# /var/lib/gitea-runner/zion/.runner as "uuid" and "token".
#
# Jobs run natively on this host rather than in a container. That is the entire
# point: the cargo registry, the sccache and the actions cache stay warm between
# runs, which is what makes this faster than GitHub's free runners rather than
# merely equivalent. The cost is that jobs see NixOS, not Ubuntu:
#
#   - `runs-on:` must be `native`, not `ubuntu-latest`.
#   - Actions that fetch prebuilt binaries will not run. There is no
#     /lib64/ld-linux-x86-64.so.2 on this host, so dtolnay/rust-toolchain,
#     actions/setup-node and friends produce "No such file or directory" on a
#     file that plainly exists. Use the toolchain in `hostPackages` below instead.
#   - `uses:` resolves against code.forgejo.org, not github.com.
#   - No `apt-get`. A workflow needing a package gets it via extraPackages.
#
# What a job gets without asking for it: stable Rust with std for x86_64 and aarch64, gnu and
# musl, so one host can build all four release targets; the C cross compilers those targets
# need; cargo-deny and release-plz, which upstream ships as actions this runner cannot run;
# and $RUST_MSRV_BIN, a pinned older toolchain kept off PATH. hekla's .forgejo/workflows are
# the worked example of all of it.
#
# The Rust toolchains come from rust-overlay, which this module applies as an overlay itself,
# so the flake importing it needs that input.
#
# If a repository genuinely needs the Ubuntu userland, enable docker or podman
# on this host and add a container label alongside the host one, e.g.
#   labels = [ "native:host" "ubuntu-latest:docker://node:24-bookworm" ];
# Container jobs are hermetic but start cold every time, so keep the Rust work
# on `native`.

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.forgejoRunner;

  # Fixed rather than derived from cfg.name: this is the systemd StateDirectory,
  # and renaming the runner should not orphan its caches.
  instance = "zion";
  stateDir = "/var/lib/gitea-runner/${instance}";

  # One toolchain for every job, carrying std for the cross targets as well as the host's.
  # nixpkgs' rustc ships std for x86_64-linux alone, so a release build that targets musl or
  # aarch64 cannot come from there. This is also what puts clippy and rustfmt on PATH.
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    targets = [
      "x86_64-unknown-linux-musl"
      "aarch64-unknown-linux-gnu"
      "aarch64-unknown-linux-musl"
    ];
  };

  # The version-pinned toolchains, as directories rather than PATH entries. A second cargo,
  # node or go on PATH would shadow the default one for the whole job, so a workflow reaches
  # into these for the one step that wants an old version:
  #
  #   PATH="$RUST_MSRV_DIR/1.88.0/bin:$PATH" cargo check -p heklang
  #
  # Versions are what the repositories on this forge declare. nixpkgs drops a language
  # version when upstream ends support for it, so a floor below what it carries cannot be
  # tested here at all -- that is why the Go and Node lists start above their go.mod and
  # engines floors.
  toolchainDir =
    dirName: versions:
    pkgs.linkFarm dirName (
      lib.mapAttrsToList (version: drv: {
        name = version;
        path = drv;
      }) versions
    );

  msrvToolchains = toolchainDir "rust-msrv" (
    lib.genAttrs cfg.msrvVersions (version: pkgs.rust-bin.stable.${version}.minimal)
  );

  nodeToolchains = toolchainDir "node-versions" (
    lib.genAttrs cfg.nodeVersions (major: pkgs."nodejs_${major}")
  );

  goToolchains = toolchainDir "go-versions" (
    lib.genAttrs cfg.goVersions (version: pkgs."go_${lib.replaceStrings [ "." ] [ "_" ] version}")
  );
in
{
  options.services.forgejoRunner = {
    enable = lib.mkEnableOption "Forgejo Actions runner registered against zion";

    url = lib.mkOption {
      type = lib.types.str;
      default = "https://git.tqwewe.com";
      description = "Base URL of the Forgejo instance to poll.";
    };

    uuid = lib.mkOption {
      type = lib.types.str;
      description = "UUID of the runner as registered on the forge. Not a secret on its own; the token is.";
    };

    tokenFile = lib.mkOption {
      type = lib.types.path;
      default = "/etc/forgejo-runner.token";
      description = ''
        Path to a root-owned 0400 file containing only the runner's token. Keep
        it out of the Nix store: everything in the store is world-readable.
      '';
    };

    capacity = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = ''
        Jobs to run concurrently. One is the right default even on 20 threads:
        cargo already saturates the machine on its own, and a second job mostly
        buys contention. Raise it if jobs spend their time waiting on network or
        on single-threaded link steps.
      '';
    };

    sccache = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Wrap rustc in sccache, with a cache that outlives any single job's
        working directory and is shared across repositories and branches.
        Turn it off if a crate misbehaves under it; the fallback on a cache miss
        is a normal compile, so failures here are rare but not impossible.
      '';
    };

    msrvVersions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "1.85.0" # tephra-types, tephra-proto, tephra-client
        "1.88.0" # heklang
        "1.90.0" # tree-sitter-hek, hek
        "1.95.0" # hekla, tephra, seglog, tephra-server
      ];
      description = ''
        Rust versions exposed to jobs under `$RUST_MSRV_DIR/<version>/bin`, for the workflow
        step that checks a crate still builds on the `rust-version` it declares. Kept off
        PATH so they cannot shadow the stable toolchain; a job opts in per command with
        `PATH="$RUST_MSRV_DIR/1.88.0/bin:$PATH"`.
      '';
    };

    nodeVersions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "22"
        "24"
      ];
      description = ''
        Node majors exposed under `$NODE_VERSIONS_DIR/<major>/bin`, for a test matrix across
        supported versions. The default one, on PATH, is whatever `nodejs` is in nixpkgs.
        A major nixpkgs has dropped for end-of-life cannot be listed here.
      '';
    };

    goVersions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "1.26"
        "1.27"
      ];
      description = ''
        Go versions exposed under `$GO_VERSIONS_DIR/<version>/bin`, for a test matrix across
        supported versions. `go` on PATH is the nixpkgs default.
      '';
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "with pkgs; [ sqlite protobuf ]";
      description = "Extra packages on PATH for jobs. This is the NixOS replacement for an apt-get step.";
    };

    extraEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ LIBCLANG_PATH = "''${pkgs.libclang.lib}/lib"; }'';
      description = ''
        Extra environment variables for every job. Where -sys crates need to be
        pointed at a library, this is the place; PKG_CONFIG_PATH below is the
        worked example.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Where `pkgs.rust-bin` above comes from. The overlay only adds attributes, so nothing
    # else on the system changes shape because of it.
    nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];

    services.forgejo-runner = {
      instances.${instance} = {
        enable = true;

        secrets.server.connections.default.token_url = cfg.tokenFile;

        # In host mode PATH is exactly this list plus coreutils. Anything a
        # workflow calls and does not find here does not exist.
        hostPackages =
          with pkgs;
          [
            # The module's own defaults, restated because setting this replaces
            # them. nodejs is not optional: every JavaScript action needs it,
            # including actions/checkout.
            bash
            coreutils
            curl
            gawk
            gitMinimal
            gnused
            nodejs
            wget

            # Rust. This has to come from Nix, because a workflow cannot download a
            # toolchain that would run on this host. One derivation rather than four:
            # cargo, rustc, clippy and rustfmt, plus std for the cross targets.
            rustToolchain

            # Enough to build the common -sys crates: cc for linking, pkg-config to find
            # system libraries, and cmake, make and perl for the ones that vendor a C
            # project and build it themselves. make is not optional padding: jemalloc-sys
            # runs ./configure and make from its build.rs, and tephra links jemalloc.
            gcc
            pkg-config
            openssl
            cmake
            gnumake
            perl

            # The C half of a cross build, and the linker for it: rusqlite is bundled
            # wherever it is used, so every target compiles SQLite from C. zig rather than
            # a pkgsCross gcc because these binaries get published: nix's cc wrapper bakes
            # an ELF interpreter and a RUNPATH inside /nix/store into anything it links,
            # which runs on this host and nowhere else. `cargo zigbuild --target
            # <triple>.2.17` links against the standard loader and an explicit glibc floor.
            cargo-zigbuild
            zig

            # CI tools that ship as Docker actions or GitHub-only actions upstream, which
            # host mode cannot run: these are called directly instead.
            cargo-deny
            cargo-hack
            release-plz

            # release-plz shells out to this to decide whether a change is breaking, and
            # only warns if it is absent -- so without it a breaking API change that the
            # commit message did not mark as one goes to crates.io as a patch bump. The
            # release-plz GitHub action installed it for us; the nixpkgs CLI does not.
            cargo-semver-checks

            # protoc for the crates whose build.rs compiles .proto. The version tracks the
            # protobuf crates tephra version-locks against, 35.1 at the time of writing;
            # prost and tonic find it on PATH without being told where.
            protobuf

            # tree-sitter, for heklang's grammar gate. `tree-sitter-hek/src/` is generated and
            # committed, because nix's `buildGrammar` compiles `parser.c` and never runs
            # `generate`; CI regenerates it and diffs, to catch a `grammar.js` edit that was
            # never regenerated. The version is load-bearing: `src/` carries generator-version
            # artefacts, so a runner on a different CLI fails the diff on a grammar that is
            # perfectly in sync. nixpkgs-unstable is at 0.26.9, which is what heklang
            # committed with. nodejs above is the other half; `generate` evaluates
            # `grammar.js` with it.
            tree-sitter

            # Go, for the client library. The version here is the default one; the matrix
            # reads $GO_VERSIONS_DIR.
            go

            # Publishing a static site to zion, and the container images to the forge's own
            # registry. buildx is a CLI plugin, hence the extra dirs variable below.
            rsync
            openssh
            docker-client
            docker-buildx

            # Reached for often enough by actions and by hand-written steps.
            findutils
            gnugrep
            gnutar
            gzip
            xz
            zstd
            jq
          ]
          ++ lib.optional cfg.sccache sccache
          ++ cfg.extraPackages;

        settings = {
          server.connections.default = {
            inherit (cfg) url uuid;
          };

          runner = {
            inherit (cfg) capacity;

            # ":host" is what selects native execution.
            labels = [ "native:host" ];

            envs = {
              # Out of the per-job working directory, so crates are fetched once
              # ever rather than once per run. This is the single biggest win
              # over a hosted runner, which starts from an empty disk each time.
              CARGO_HOME = "${stateDir}/cargo";

              # NixOS writes the bundle here but only exports SSL_CERT_FILE to
              # login shells, not to systemd units, so jobs need it spelled out.
              SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
              GIT_SSL_CAINFO = "/etc/ssl/certs/ca-certificates.crt";

              # openssl-sys finds nothing from PATH alone, and left to itself it
              # falls back to building a vendored copy from source on every
              # cache miss. Point it at the Nix one and forbid the fallback.
              PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
              OPENSSL_NO_VENDOR = "1";

              # The version-pinned toolchains, kept off PATH so they cannot shadow the
              # defaults. See the options above for why a workflow asks by version.
              RUST_MSRV_DIR = "${msrvToolchains}";
              NODE_VERSIONS_DIR = "${nodeToolchains}";
              GO_VERSIONS_DIR = "${goToolchains}";

              # buildx is a docker CLI plugin, and the CLI looks for plugins in a fixed set
              # of directories that do not exist on NixOS. An interactive shell gets this
              # from the system profile; a systemd unit inherits none of it.
              DOCKER_CLI_PLUGIN_EXTRA_DIRS = "${pkgs.docker-buildx}/libexec/docker/cli-plugins";
            }
            // lib.optionalAttrs cfg.sccache {
              RUSTC_WRAPPER = "sccache";
              SCCACHE_DIR = "${stateDir}/sccache";
              SCCACHE_CACHE_SIZE = "20G";
              # sccache refuses to start if this is left on.
              CARGO_INCREMENTAL = "0";
            }
            // lib.optionalAttrs config.programs.nix-ld.enable {
              # nix-ld puts a loader at /lib64/ld-linux-x86-64.so.2, which is what
              # lets a downloaded binary run here at all -- but it drives it from
              # these two variables, and NixOS exports them only to login shells.
              # Passing them through is what makes actions/setup-* and
              # dtolnay/rust-toolchain work instead of dying on a missing loader.
              # It is a fallback, not the plan: a toolchain fetched per job is a
              # toolchain that is not cached.
              NIX_LD = toString config.environment.variables.NIX_LD;
              NIX_LD_LIBRARY_PATH = toString config.environment.variables.NIX_LD_LIBRARY_PATH;
            }
            // cfg.extraEnv;
          };

          # Left at its default of $HOME/.cache/actcache, which is inside the
          # StateDirectory and so survives restarts. This is what backs
          # actions/cache, and being local disk it restores at NVMe speed rather
          # than paying GitHub's upload and download.
          cache.enabled = true;
        };
      };
    };

    # systemd mounts a DynamicUser service's StateDirectory nosuid,nodev,NOEXEC, and the
    # job's working directory lives under it ($HOME/.cache/act/...). cargo has to execute
    # what it just wrote there -- build scripts, and proc-macro dylibs it dlopens -- so
    # every Rust build dies on "Permission denied (os error 13)" against a build script
    # that is plainly there and plainly +x. A static user gets the same directory mounted
    # rw,nosuid, which is what every other service on this host already gets.
    users.users.gitea-runner = {
      isSystemUser = true;
      group = "gitea-runner";
      description = "Forgejo Actions runner";

      # Without this the account's home is /var/empty, and ssh cannot write known_hosts:
      # `StrictHostKeyChecking=accept-new` then re-accepts the host key on every single
      # deploy instead of pinning it once, which is trust-on-first-use with no memory.
      # The unit already sets HOME here; this makes the passwd entry agree with it.
      home = stateDir;

      # For `docker buildx bake` in tephra's image workflow. Worth being clear-eyed about:
      # the docker socket is a root-equivalent interface, so a workflow on this runner can
      # become root on this host. Acceptable only because every repository it builds is
      # Ari's own. Drop this group, and the image workflow with it, the day that stops
      # being true.
      extraGroups = [ "docker" ];
    };
    users.groups.gitea-runner = { };

    # This is a workstation before it is a build server. CI gets the whole
    # machine while it is idle and yields as soon as Ari is doing something.
    systemd.services."forgejo-runner-${instance}" = {
      # The module's own state directory is /var/lib/forgejo-runner. This one predates the
      # switch from gitea-actions-runner and holds the warm cargo, sccache and action caches.
      environment.HOME = lib.mkForce stateDir;

      serviceConfig = {
        # See the users.users block above. The module defaults to a DynamicUser; this names
        # the account and keeps systemd from inventing the user and the directory.
        DynamicUser = lib.mkForce false;
        User = "gitea-runner";
        Group = "gitea-runner";
        StateDirectory = lib.mkForce "gitea-runner/${instance}";
        WorkingDirectory = lib.mkForce stateDir;
        # Only needed to undo noexec on a DynamicUser's directory, which this no longer is.
        ExecPaths = lib.mkForce [ ];

        # DynamicUser implied this, and turning it off took it away with it: jobs then share
        # the host's /tmp, where a file left by another user is a permission error rather
        # than a clean slate. heklang's CLI tests write to a fixed /tmp/hek-cli-<case> path
        # and fail outright on someone else's leftovers. A private /tmp is both the isolation
        # the service had before and the thing that makes a test like that safe here.
        PrivateTmp = true;

        # nixpkgs sets RestartSec=2, which is right for a forge restarting under it.
        # It is wrong for a rejected registration token: that loops forever, and at
        # two seconds it is re-POSTing to the forge before you can read the log.
        # Slow enough to be ignorable, still fast enough to ride out a reboot.
        # mkForce because the upstream module sets it at the same priority.
        RestartSec = lib.mkForce 30;

        # systemd hands a service 1024 open files by default, which is a desktop-daemon
        # number, not a CI one: tephra's integration tests flood a connection pool and hit
        # EMFILE well before they finish. A hosted GitHub runner gives a job 65536, so this
        # is matching what the tests were written against rather than inventing headroom.
        # Soft:hard -- the hard limit is systemd's own default and is left alone.
        LimitNOFILE = "65536:524288";

        Nice = 10;
        CPUWeight = 50;
        IOWeight = 50;
      };
    };
  };
}
