{
  allowUnfree = true;
  # librewolf is flagged insecure in nixpkgs only because it lacks an active
  # committer (no timely updates), not for a specific known vulnerability.
  permittedInsecurePackages = [
    "librewolf-151.0.2-1"
    "librewolf-unwrapped-151.0.2-1"
  ];
}
