#!/usr/bin/env bash
set -euo pipefail
LAB=${1:-ospf}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YAML="$SCRIPT_DIR/frr3_${LAB}.clab.yml"
LOGDIR="$SCRIPT_DIR/results"
LOGFILE="$LOGDIR/results.log"
mkdir -p "$LOGDIR"

DOCKER_BIN="docker"
DOCKER_SUDO=0
if ! $DOCKER_BIN ps >/dev/null 2>&1; then
  DOCKER_SUDO=1
fi
export DOCKER_BIN DOCKER_SUDO

CLAB_BIN="containerlab"
CLAB_SUDO=0
if ! $CLAB_BIN version >/dev/null 2>&1; then
  CLAB_SUDO=1
fi

dockercmd() {
  if [ "$DOCKER_SUDO" -eq 1 ]; then sudo docker "$@"; else docker "$@"; fi
}
clabcmd() {
  if [ "$CLAB_SUDO" -eq 1 ]; then sudo -E containerlab "$@"; else containerlab "$@"; fi
}

"$SCRIPT_DIR/clean.sh"

ts="$(date '+%Y-%m-%d %H:%M:%S')"
echo "===== RUN ($LAB) @ $ts =====" | tee -a "$LOGFILE"

echo "[*] (Re)deploying lab: $LAB"
clabcmd deploy --reconfigure -t "$YAML"

echo "[*] Configuring hosts h1/h3..."
dockercmd exec clab-frr3-h1 ip addr add 10.0.1.10/24 dev eth1 || true
dockercmd exec clab-frr3-h1 ip link set eth1 up
dockercmd exec clab-frr3-h1 ip route replace default via 10.0.1.1
dockercmd exec clab-frr3-h3 ip addr add 10.0.3.10/24 dev eth1 || true
dockercmd exec clab-frr3-h3 ip link set eth1 up
dockercmd exec clab-frr3-h3 ip route replace default via 10.0.3.1

echo "[*] Measuring initial convergence..."
conv=$(
python3 - <<'PY'
import subprocess, time, sys, os
DOCKER_BIN=os.environ.get("DOCKER_BIN","docker")
DOCKER_SUDO=os.environ.get("DOCKER_SUDO","0")=="1"
def docker_exec(args):
    base = (["sudo","-E","docker"] if DOCKER_SUDO else ["docker"])
    return subprocess.run(base+["exec"]+args)
def ms(): return int(subprocess.check_output(["date","+%s%3N"]).decode().strip())
t0=ms()
for _ in range(600):
    r = docker_exec(["clab-frr3-h1","sh","-lc","ping -n -c1 -W1 10.0.3.10 >/dev/null 2>&1"])
    if r.returncode==0:
        print(ms()-t0); sys.exit(0)
    time.sleep(0.2)
print("timeout")
PY
)
echo "convergence_ms=${conv}" | tee -a "$LOGFILE"

echo "[*] Measuring failure recovery (down r1-eth1) ..."
dockercmd exec clab-frr3-r1 ip link set eth1 down
rec=$(
python3 - <<'PY'
import subprocess, time, sys, os
DOCKER_SUDO=os.environ.get("DOCKER_SUDO","0")=="1"
def docker_exec(args):
    base = (["sudo","-E","docker"] if DOCKER_SUDO else ["docker"])
    return subprocess.run(base+["exec"]+args)
def ms(): return int(subprocess.check_output(["date","+%s%3N"]).decode().strip())
t0=ms()
for _ in range(600):
    r = docker_exec(["clab-frr3-h1","sh","-lc","ping -n -c1 -W1 10.0.3.10 >/dev/null 2>&1"])
    if r.returncode==0:
        print(ms()-t0); sys.exit(0)
    time.sleep(0.2)
print("timeout")
PY
)
echo "recovery_ms=${rec}" | tee -a "$LOGFILE"
dockercmd exec clab-frr3-r1 ip link set eth1 up

echo "[*] Measuring control-plane overhead for 60s ..."
dockercmd exec clab-frr3-r1 sh -lc '
set -e
if ! command -v tcpdump >/dev/null 2>&1; then
  if command -v apk >/dev/null 2>&1; then
    apk add --no-cache tcpdump
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update && apt-get install -y tcpdump
  elif command -v microdnf >/dev/null 2>&1; then
    microdnf install -y tcpdump || dnf install -y tcpdump || true
  fi
fi
'
if [ "$LAB" = "rip" ]; then
  FILTER='udp port 520'
else
  FILTER="ip proto 89"
fi
dockercmd exec clab-frr3-r1 sh -lc "timeout 62s tcpdump -i eth1 -nn \"$FILTER\" -w /tmp/cap.pcap >/dev/null 2>&1 || true"
count=$(dockercmd exec clab-frr3-r1 sh -lc "tcpdump -r /tmp/cap.pcap 2>/dev/null | wc -l")
echo "overhead_pkts_60s=${count}" | tee -a "$LOGFILE"

echo "[*] Done."
echo "" >> "$LOGFILE"
