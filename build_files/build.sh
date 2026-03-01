#!/bin/bash
set -ouex pipefail

# Install Nix package manager
mkdir -p /nix && \
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    -o /nix/determinate-nix-installer.sh && \
    chmod a+rx /nix/determinate-nix-installer.sh

# Configure XDG_DATA_DIRS so GNOME can find .desktop files from Nix apps,
# allow unfree packages, and ensure /usr/local/bin takes priority in PATH
cat > /etc/profile.d/nix-xdg.sh << 'EOF'
if [ -d "$HOME/.nix-profile/share" ]; then
    export XDG_DATA_DIRS="$HOME/.nix-profile/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
fi
export NIXPKGS_ALLOW_UNFREE=1
export PATH="/usr/local/bin:$PATH"
EOF

# Wrapper for nix profile add to update desktop database after installing new applications
rm -f /usr/local/bin 2>/dev/null || true
mkdir -p /usr/local/bin
cat > /usr/local/bin/nix << 'EOF'
#!/bin/bash
if [[ "$1" == "profile" && ( "$2" == "add" || "$2" == "install" ) ]]; then
    NIXPKGS_ALLOW_UNFREE=1 /nix/var/nix/profiles/default/bin/nix profile add --impure "${@:3}"
    ln -sf ~/.nix-profile/share/applications/*.desktop ~/.local/share/applications/ 2>/dev/null || true
    update-desktop-database ~/.local/share/applications 2>/dev/null || true
else
    /nix/var/nix/profiles/default/bin/nix "$@"
fi
EOF
chmod +x /usr/local/bin/nix

# Install nixGL after Nix is ready
cat > /etc/systemd/system/nixgl-install.service << 'EOF'
[Unit]
Description=Install nixGL after Nix is ready
After=nix-daemon.service
Wants=nix-daemon.service
ConditionPathExists=!/root/.nix-profile/bin/nixGL

[Service]
Type=oneshot
ExecStart=/bin/bash -c "NIXPKGS_ALLOW_UNFREE=1 nix profile add --impure github:nix-community/nixGL"
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl enable nixgl-install.service