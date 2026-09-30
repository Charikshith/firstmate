#!/usr/bin/env bash
# Live: compare the session-lock ancestry walk from a plain shell under this Claude Code
# session against the same walk with a real node.exe running an unrelated
# C:/.../work/pi/tool.js inserted in between. The node must never be chosen as owner.
set -u
REPO=$1 T=$2
mkdir -p "$T/work/pi"
BASH_W=$(cygpath -m "$(command -v bash)")
WALK='
  export TMPDIR=$(mktemp -d)
  . "'"$REPO"'/bin/fm-session-lock-lib.sh"
  fm_win_table_load
  p=$(fm_win_self_pid); n=0
  while [ -n "$p" ] && [ "$n" -lt 12 ]; do
    fm_proc_read "$p" || break
    if fm_harness_process_matches "$FM_PROC_COMM" "$FM_PROC_ARGS"; then m="HARNESS"; else m="-"; fi
    echo "  $p ${FM_PROC_COMM##*/} [$m] ${FM_PROC_ARGS}"
    q=$(fm_proc_parent "$p") || { pp=${FM_WIN_PPID[p]}; echo "  (walk ends: parent $pp ${FM_WIN_COMM[pp]:-not in process table})"; break; }
    p=$q; n=$((n+1))
  done
  hp=$(fm_harness_ancestry_pid); FM_PROC_COMM=; [ -n "$hp" ] && fm_proc_read "$hp"
  echo "  => session-lock owner: ${hp:-none} ${FM_PROC_COMM##*/}"
  rm -rf "$TMPDIR"
'
cat > "$T/work/pi/tool.js" <<JS
const r = require('child_process').spawnSync('$BASH_W', ['-c', process.argv[2]], {stdio: 'inherit', env: process.env});
process.exit(r.status);
JS
echo "== A. plain shell"
bash -c "$WALK"
echo "== B. same shell under: node <T>/work/pi/tool.js"
node "$(cygpath -m "$T/work/pi/tool.js")" "$WALK"
