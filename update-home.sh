#!/bin/sh

home-manager --flake ".#$(whoami)@$(hostname -s)" switch
