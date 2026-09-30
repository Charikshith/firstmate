#!/usr/bin/env bash
# Live: a dead process left the old fork build's Windows directory-copy fallback behind
# (tokenless <lock> and <lock>.steal directories holding only a dead pid). Several real
# contenders then race for the lock at once: exactly one may hold it at a time and the
# leftovers must be reclaimed without manual deletion.
set -u
REPO=$1 T=$2
export STATE=$T/state; mkdir -p "$STATE"; LOCK=$STATE/legacy.lock
bash -c 'echo $BASHPID > "$1"' _ "$T/deadpid"; DEAD=$(cat "$T/deadpid")
mkdir -p "$LOCK" "$LOCK.steal"; echo "$DEAD" > "$LOCK/pid"; echo "$DEAD" > "$LOCK.steal/pid"
touch -d '10 seconds ago' "$LOCK" "$LOCK.steal" "$LOCK/pid" "$LOCK.steal/pid"
echo "before: legacy lock entries (dead pid $DEAD):"; ls -a "$LOCK" "$LOCK.steal"
: > "$T/holds"
for w in 1 2 3 4; do
  bash -c '. "$1/bin/fm-wake-lib.sh"; if fm_lock_acquire_wait_max "$2" 30; then echo "enter $BASHPID" >> "$3"; sleep 0.3; echo "exit $BASHPID" >> "$3"; fm_lock_release "$2"; else echo "timeout $BASHPID" >> "$3"; fi' _ "$REPO" "$LOCK" "$T/holds" &
done; wait
cat "$T/holds"
awk '{ if ($1=="enter") { if (cur!="") {print "OVERLAP"; bad=1} cur=$2 } else if ($1=="exit") cur=""; else bad=1 } END { print (bad ? "RESULT: FAIL" : "RESULT: 4 contenders held the lock one at a time") }' "$T/holds"
echo "after: lock or steal leftovers?"; ls -a "$STATE"
