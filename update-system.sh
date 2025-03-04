#!/bin/sh

# Detect the operating system
OS="$(uname -s)"

case "$OS" in
  Darwin)
    # macOS
    darwin-rebuild switch --flake .
    ;;
  Linux)
    # Linux (assuming NixOS)
    sudo nixos-rebuild switch --flake .
    ;;
  *)
    echo "Unsupported operating system: $OS"
    exit 1
    ;;
esac
