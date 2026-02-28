#!/bin/bash
set -ouex pipefail

mkdir -p /nix && \
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    -o /nix/determinate-nix-installer.sh && \
    chmod a+rx /nix/determinate-nix-installer.sh