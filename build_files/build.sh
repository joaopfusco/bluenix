#!/bin/bash
set -ouex pipefail

# Install Nix package manager
mkdir -p /nix && \
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    -o /nix/determinate-nix-installer.sh && \
    chmod a+rx /nix/determinate-nix-installer.sh

# Configure XDG_DATA_DIRS so GNOME can find .desktop files from Nix apps,
# allow unfree packages by default, and make these settings available to all users.
cat > /etc/profile.d/nix-xdg.sh << 'EOF'
if [ -d "$HOME/.nix-profile/share" ]; then
    export XDG_DATA_DIRS="$HOME/.nix-profile/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
fi
export NIXPKGS_ALLOW_UNFREE=1
EOF