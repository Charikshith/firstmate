#!/usr/bin/env bash
# Live: a holder is SIGKILLed while holding the lock; a live holder blocks; a non-owner release is a no-op.
set -u
REPO=$1 T=$2
export STATE=$T/state; mkdir -p "$STATE"; LOCK=$STATE/r.lock
. "$REPO/bin/fm-wake-lib.sh"
echo "== 1. live holder blocks a contender"
bash -c '. "$1/bin/fm-wake-lib.sh"; fm_lock_acquire_wait "$2"; echo "holder pid=$BASHPID"; ls -a "$2"; sleep 30' _ "$REPO" "$LOCK" & H=$!
for _ in $(seq 100); do [ -s "$LOCK/pid" ] && break; sleep 0.1; done
sleep 0.5
bash -c '. "$1/bin/fm-wake-lib.sh"; if fm_lock_try_acquire "$2"; then echo "contender ACQUIRED (FAIL)"; else echo "contender refused while holder alive (ok)"; fi' _ "$REPO" "$LOCK"
echo "== 2. non-owner release is a no-op"
bash -c '. "$1/bin/fm-wake-lib.sh"; fm_lock_release "$2"' _ "$REPO" "$LOCK"
[ -s "$LOCK/pid" ] && echo "lock still held by pid $(cat "$LOCK/pid") (ok)" || echo "lock removed by non-owner (FAIL)"
echo "== 3. SIGKILL the holder, then a new contender reclaims"
kill -9 $H; wait $H 2>/dev/null
echo "lock dir left behind by dead holder:"; ls -a "$LOCK"
sleep 2.5   # past FM_LOCK_STALE_AFTER
bash -c '. "$1/bin/fm-wake-lib.sh"; if fm_lock_acquire_wait_max "$2" 20; then echo "reclaimed by pid=$BASHPID recovered_from=${FM_LOCK_RECOVERED_PID:-?}"; cat "$2/pid"; fm_lock_release "$2"; else echo "reclaim FAILED"; fi' _ "$REPO" "$LOCK"
echo "lock exists after release? $( [ -e "$LOCK" ] && echo yes || echo no )"
echo "stray entries in state dir:"; ls -a "$STATE"
