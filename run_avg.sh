#!/usr/bin/env bash
set -euo pipefail
LAB=${1:-ospf}
RUNS=${2:-3}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$SCRIPT_DIR/results/results.log"
mkdir -p "$SCRIPT_DIR/results"

RUNNER="$SCRIPT_DIR/run2.sh"

conv_sum=0; rec_sum=0; ovh_sum=0
okc=0; okr=0; oko=0

for i in $(seq 1 $RUNS); do
  echo "===== BATCH RUN $i/$RUNS ($LAB) ====="
  out=$(${RUNNER} "$LAB")
  echo "$out"

  c=$(echo "$out" | awk -F= '/convergence_ms=/{print $2}' | tail -n1)
  r=$(echo "$out" | awk -F= '/recovery_ms=/{print $2}' | tail -n1)
  o=$(echo "$out" | awk -F= '/overhead_pkts_60s=/{print $2}' | tail -n1)
  [[ "$c" =~ ^[0-9]+$ ]] && conv_sum=$((conv_sum + c)) && okc=$((okc+1)) || true
  [[ "$r" =~ ^[0-9]+$ ]] && rec_sum=$((rec_sum + r)) && okr=$((okr+1)) || true
  [[ "$o" =~ ^[0-9]+$ ]] && ovh_sum=$((ovh_sum + o)) && oko=$((oko+1)) || true
done

ts="$(date '+%Y-%m-%d %H:%M:%S')"
echo "===== AVERAGES ($LAB over $RUNS runs) @ $ts =====" | tee -a "$LOGFILE"
[ $okc -gt 0 ] && { echo "convergence_ms_avg=$((conv_sum/okc))" | tee -a "$LOGFILE" ; } || echo "convergence_ms_avg=NA" | tee -a "$LOGFILE"
[ $okr -gt 0 ] && { echo "recovery_ms_avg=$((rec_sum/okr))"   | tee -a "$LOGFILE" ; } || echo "recovery_ms_avg=NA"   | tee -a "$LOGFILE"
[ $oko -gt 0 ] && { echo "overhead_pkts_60s_avg=$((ovh_sum/oko))" | tee -a "$LOGFILE" ; } || echo "overhead_pkts_60s_avg=NA" | tee -a "$LOGFILE"
echo "" >> "$LOGFILE"
