#!/bin/sh

home-manager --flake ".#$(whoami)@$(hostname)" switch
