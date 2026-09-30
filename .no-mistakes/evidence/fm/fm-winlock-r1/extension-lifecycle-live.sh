#!/usr/bin/env bash
# Live: unmodified bin/fm-procevent.sh extension-bind / extension-retirement (bash takes the lifecycle lock, execs
# bin/fm-extension.mjs which must accept the handoff) on a Windows host, where the lock is natively the mkdir form.
set -u
REPO=$1 T=$2 EV=$3
. "$EV/make_package.fixture.sh"
. "$REPO/bin/fm-wake-lib.sh"; fm_lock_mkdir_host && echo "native mkdir lock scheme on this host: yes"
H=$T/home; mkdir -p "$H"; P=$T/pkg
make_package "$P" org.example.live-mkdir ext-live-mkdir
LOCK=$H/state/procevent/.extension-binding-lifecycle.lock
echo "== bind"
out=$(FM_HOME="$H" "$REPO/bin/fm-procevent.sh" extension-bind bind "$P" --adapter ext-live-mkdir --trust-same-user-code 2>&1); rc=$?
printf '%s\n' "$out" | sed "s#$T#<T>#g"; echo "bind exit=$rc"
d=$(printf '%s\n' "$out" | sed -n 's/^binding-digest: //p')
echo "lifecycle lock after bind exists? $( [ -e "$LOCK" ] && echo yes || echo no )"
echo "== retire-binding"
out=$(FM_HOME="$H" "$REPO/bin/fm-procevent.sh" extension-retirement binding retire-binding org.example.live-mkdir --if-binding-digest "$d" 2>&1); rc=$?
printf '%s\n' "$out" | sed "s#$T#<T>#g"; echo "retire exit=$rc"
echo "lifecycle lock after retire exists? $( [ -e "$LOCK" ] && echo yes || echo no )"
echo "procevent dir entries:"; ls -a "$H/state/procevent" 2>/dev/null
