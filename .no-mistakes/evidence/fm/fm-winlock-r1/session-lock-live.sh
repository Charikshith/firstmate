#!/usr/bin/env bash
# Live: real node.exe processes are read from the real Win32 process table.
set -u
REPO=$1 T=$2
mkdir -p "$T/work/pi" "$T/npm/node_modules/@mariozechner/pi-coding-agent/dist" "$T/tmp"
echo 'setTimeout(()=>{},60000)' > "$T/work/pi/tool.js"
cp "$T/work/pi/tool.js" "$T/npm/node_modules/@mariozechner/pi-coding-agent/dist/cli.js"
W=$(cygpath -m "$T")
node "$W/work/pi/tool.js" --api-key=SECRET-CMDLINE-TOKEN-123 & A=$!
node "$W/npm/node_modules/@mariozechner/pi-coding-agent/dist/cli.js" & B=$!
sleep 2
export TMPDIR=$T/tmp
. "$REPO/bin/fm-session-lock-lib.sh"
fm_win_host && echo "fm_win_host: yes"
fm_win_table_load || { echo "table load failed"; exit 1; }
WA=$(cat /proc/$A/winpid) WB=$(cat /proc/$B/winpid)
for p in "unrelated C:/work/pi/tool.js:$WA" "pi-coding-agent cli.js:$WB"; do
  label=${p%:*} wp=${p##*:}
  fm_proc_read "$wp" || { echo "$label: unreadable"; continue; }
  if fm_harness_process_matches "$FM_PROC_COMM" "$FM_PROC_ARGS"; then r=HARNESS; else r="not a harness"; fi
  echo "$label (winpid $wp) comm=${FM_PROC_COMM##*/} -> $r"
done
cache=$(ls "$TMPDIR"/.fm-win-table.* 2>/dev/null | head -1)
echo "cache file: ${cache##*/}"
echo "cache rows: $(wc -l < "$cache")"
grep -c 'SECRET-CMDLINE-TOKEN' "$cache" | sed 's/^/cache lines containing the secret argv token: /'
echo "cache row for unrelated node process:"; awk -F'\t' -v p="$WA" '$1==p' "$cache"
echo "cache row for pi-coding-agent process:"; awk -F'\t' -v p="$WB" '$1==p' "$cache" | sed "s#$W#<T>#g"
echo "cache ACL (icacls):"; icacls "$(cygpath -w "$cache")" | sed "s#$(cygpath -w "$T" | sed 's/\/\\/g')#<T>#"
kill $A $B
