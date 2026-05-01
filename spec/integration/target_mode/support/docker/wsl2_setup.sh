#!/bin/bash
# Helper script executed inside WSL2 to set up an SSH server for Chef
# target-mode integration tests on the Windows CI job.
#
# Docker-in-WSL2 is unreliable on GitHub-hosted runners: the embedded
# containerd in docker.io (Ubuntu 24.04) fails to load its bolt-database
# plugins ("operation not permitted") on the runner kernel, making
# "docker run" impossible.  Instead we skip Docker entirely and run sshd
# directly inside the WSL2 instance.  WSL2 automatically proxies WSL2
# ports to Windows localhost, so Train SSH (running on the Windows Ruby
# instance) reaches the server at 127.0.0.1:2222 just as it would with
# a Docker container.
#
# This also validates the primary real-world use-case: a Windows admin
# using Chef target-mode to manage a Linux host via SSH.
#
# Usage: bash wsl2_setup.sh <wsl2-checkout-path> <wsl2-key-output-dir>
#
#   <wsl2-checkout-path>  – the Git workspace expressed as a WSL2 path,
#                           e.g. /mnt/d/a/chef/chef  (unused; kept for
#                           call-site compatibility)
#   <wsl2-key-output-dir> – directory (WSL2 path) where the generated SSH
#                           key pair is written so PowerShell can read it
#                           via the normal Windows filesystem.
set -euo pipefail

KEY_OUT_DIR="$2"

# ── Install OpenSSH server ───────────────────────────────────────────────────
echo "Installing openssh-server..."
sudo apt-get update -qq 2>&1 | tail -3
sudo apt-get install -y --no-install-recommends openssh-server 2>&1 | tail -5

# ── Generate SSH key pair ────────────────────────────────────────────────────
ssh-keygen -t ed25519 -f /tmp/id_test -N "" -q

# ── Authorise the key for root ───────────────────────────────────────────────
sudo mkdir -p /root/.ssh
sudo cp /tmp/id_test.pub /root/.ssh/authorized_keys
sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/authorized_keys

# ── Configure sshd ──────────────────────────────────────────────────────────
# Port 2222 matches the container port mapping used in the Linux host job.
sudo mkdir -p /etc/ssh/sshd_config.d
sudo tee /etc/ssh/sshd_config.d/99-ci-test.conf >/dev/null <<'SSHD_CONF'
Port 2222
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication no
SSHD_CONF

# Ensure host keys exist (needed in a fresh WSL2 instance).
sudo ssh-keygen -A 2>/dev/null || true

# ── Start sshd ───────────────────────────────────────────────────────────────
sudo mkdir -p /run/sshd
sudo /usr/sbin/sshd -D &

# ── Wait for sshd to accept connections ─────────────────────────────────────
echo "Waiting for SSH on port 2222..."
for i in $(seq 1 20); do
  if ssh -o StrictHostKeyChecking=no \
         -o ConnectTimeout=2 \
         -o BatchMode=yes \
         -i /tmp/id_test \
         -p 2222 root@127.0.0.1 true 2>/dev/null; then
    echo "SSH server is ready."
    break
  fi
  [ "$i" -eq 20 ] && { echo "ERROR: Timed out waiting for SSH on port 2222"; exit 1; }
  sleep 2
done

# ── Export key pair to Windows-accessible location ───────────────────────────
mkdir -p "$KEY_OUT_DIR"
cp /tmp/id_test     "$KEY_OUT_DIR/id_test"
cp /tmp/id_test.pub "$KEY_OUT_DIR/id_test.pub"
echo "SSH keys copied to $KEY_OUT_DIR"
