#!/usr/bin/env bash
set -euo pipefail

DOCKER_BIN="docker"; DOCKER_SUDO=0
if ! $DOCKER_BIN ps >/dev/null 2>&1; then DOCKER_SUDO=1; fi

CLAB_BIN="containerlab"; CLAB_SUDO=0
if ! $CLAB_BIN version >/dev/null 2>&1; then CLAB_SUDO=1; fi

dockercmd() { if [ "$DOCKER_SUDO" -eq 1 ]; then sudo docker "$@"; else docker "$@"; fi; }
clabcmd()   { if [ "$CLAB_SUDO" -eq 1 ]; then sudo -E containerlab "$@"; else containerlab "$@"; fi; }

echo "[*] Cleaning any previous frr3 lab remnants..."
clabcmd destroy --name frr3 --cleanup || true
dockercmd rm -f $(dockercmd ps -aq -f name=clab-frr3-) 2>/dev/null || true
dockercmd network rm clab 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf "$SCRIPT_DIR/clab-frr3" 2>/dev/null || true
sudo rm -f /etc/ssh/ssh_config.d/clab-frr3.conf 2>/dev/null || true

echo "[*] Clean done."
