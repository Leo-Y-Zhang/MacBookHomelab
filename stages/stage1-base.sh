#!/bin/sh
# Stage 1 - base server configuration for the MacBook Air homelab.
#
# What this does, in plain terms:
#   - refreshes the list of available updates and installs security updates
#   - installs a firewall (ufw) and turns it on: block everything coming in
#     except SSH, and DNS on the local network (for AdGuard later)
#   - installs and enables automatic security updates
#   - installs lm-sensors so we can read CPU temperature
#   - adds a 4 GB swap file so the 4 GB of RAM has a safety margin
#   - creates the /srv folders every later stage will use
#   - keeps the server RUNNING when the lid is closed
#
# What this does NOT do: it never touches your disk layout, your partitions, or
# your files. The only files it creates are the swap file and the /srv folders.
#
# It asks for your password (sudo) because installing software and changing
# system settings needs administrator rights. Run it with:  sh stage1-base.sh

set -eu

# Run as yourself, not with sudo: each step asks for sudo where it needs it,
# and the /srv folders below must end up owned by you rather than by root.
if [ "$(id -u)" -eq 0 ]; then
  echo "Run this stage as your own user, not with sudo or as root." >&2
  exit 1
fi

echo ">>> 1/7  Refreshing package lists and installing security updates"
sudo apt-get update
sudo apt-get -y upgrade

echo ">>> 2/7  Installing the tools this stage needs"
sudo apt-get -y install ufw unattended-upgrades lm-sensors curl ca-certificates

echo ">>> 3/7  Firewall: block inbound by default, allow SSH and local DNS"
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Port 22 opened by number: the OpenSSH ufw profile only exists once
# openssh-server is installed, and that happens in stage 2.
sudo ufw allow 22/tcp
# DNS for AdGuard, restricted to the local network only (adjust if your LAN differs):
sudo ufw allow from 192.168.0.0/16 to any port 53 proto udp
sudo ufw allow from 192.168.0.0/16 to any port 53 proto tcp
sudo ufw --force enable
sudo ufw status verbose

echo ">>> 4/7  Turning on automatic security updates"
echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true' | sudo debconf-set-selections
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

echo ">>> 5/7  Adding a 4 GB swap file (only if one is not already present)"
if ! sudo swapon --show | grep -q '/swapfile'; then
  sudo fallocate -l 4G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
else
  echo "    a swap file already exists - leaving it alone"
fi
# Prefer RAM, use swap only under pressure (kinder to the SSD):
sudo sysctl -w vm.swappiness=10 >/dev/null
grep -q 'vm.swappiness' /etc/sysctl.conf || echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf

echo ">>> 6/7  Creating the /srv folders for later stages"
sudo mkdir -p /srv/appdata /srv/share /srv/media /srv/photos /srv/backups
# The folders themselves, not what is in them: once later stages have run,
# containers own their data under /srv (a database directory must stay owned
# by the database's user), and running this stage again must not take it back.
owner=$(id -un)
group=$(id -gn)
sudo chown "$owner:$group" /srv/appdata /srv/share /srv/media /srv/photos /srv/backups

echo ">>> 7/7  Keeping the server running with the lid closed"
sudo sed -i 's/^#\?HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
grep -q '^HandleLidSwitch=ignore' /etc/systemd/logind.conf || echo 'HandleLidSwitch=ignore' | sudo tee -a /etc/systemd/logind.conf
grep -q '^HandleLidSwitchExternalPower=ignore' /etc/systemd/logind.conf || echo 'HandleLidSwitchExternalPower=ignore' | sudo tee -a /etc/systemd/logind.conf
sudo systemctl restart systemd-logind

echo
echo ">>> Stage 1 complete."
echo "    Temperature now:"; sensors 2>/dev/null | grep -i -m1 'Core 0' || echo "    (run 'sudo sensors-detect --auto' once, then 'sensors')"
echo "    Free memory + swap:"; free -h
echo "    Test the lid: close it. The machine should stay awake (its fan/power light stays on)."
echo "    To undo the lid change: set both HandleLidSwitch lines back to 'suspend' in"
echo "    /etc/systemd/logind.conf and run: sudo systemctl restart systemd-logind"
