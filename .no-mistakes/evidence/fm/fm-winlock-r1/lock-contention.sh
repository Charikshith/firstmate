#!/usr/bin/env bash
# Live: N real Git Bash processes contend for one lock on native NTFS (no symlink emulation).
set -u
REPO=$1 T=$2 N=${3:-6} ITER=${4:-15}
export STATE=$T/state; mkdir -p "$STATE"
LOCK=$STATE/test.lock COUNTER=$T/counter HOLD=$T/holders
echo 0 > "$COUNTER"; : > "$HOLD"
worker() {
  . "$REPO/bin/fm-wake-lib.sh"
  for i in $(seq "$ITER"); do
    fm_lock_acquire_wait "$LOCK"
    echo "enter $BASHPID" >> "$HOLD"
    [ -d "$LOCK" ] && [ ! -L "$LOCK" ] || echo "NOT-A-PLAIN-DIR" >> "$HOLD"
    c=$(cat "$COUNTER"); sleep 0.02; echo $((c+1)) > "$COUNTER"
    echo "exit $BASHPID" >> "$HOLD"
    fm_lock_release "$LOCK"
  done
}
. "$REPO/bin/fm-wake-lib.sh"
fm_lock_mkdir_host && echo "host uses mkdir scheme: yes" || echo "host uses mkdir scheme: NO"
for w in $(seq "$N"); do worker & done; wait
echo "expected counter: $((N*ITER))  actual: $(cat "$COUNTER")"
# overlap check: every enter must be followed by exit of the same pid
awk '{ if ($1=="enter") { if (cur!="") { print "OVERLAP " cur " " $2; bad=1 } cur=$2 } else if ($1=="exit") { if (cur!=$2) {print "BAD exit " $2; bad=1} cur="" } else {print; bad=1} } END { print (bad ? "RESULT: FAIL" : "RESULT: no overlapping holders") }' "$HOLD"
echo "lock path after all releases exists? $( [ -e "$LOCK" ] && echo yes || echo no )"
ls -a "$STATE"
