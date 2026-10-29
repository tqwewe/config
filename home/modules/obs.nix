{ pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      input-overlay
      # gcc 15+ compiles as C23 by default, and glibc 2.42 made strrchr const-generic
      # there: handed a `const char *` it now yields one back. obs-utils.c assigns that
      # to a plain `char *`, and the plugin's bundled ObsPluginHelpers.cmake builds with
      # -Werror, so -Wdiscarded-qualifiers is fatal. Build it as the pre-C23 C it was
      # written against rather than patching the one call site.
      (obs-advanced-masks.overrideAttrs (old: {
        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE = "${old.env.NIX_CFLAGS_COMPILE or ""} -std=gnu17";
        };
      }))
      obs-backgroundremoval
      obs-shaderfilter
      obs-tuna
    ];
  };
}
