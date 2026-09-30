#!/usr/bin/env bash
# usage: r3-drive.sh <fn> [args]  -- sources the gate worktree's herdr backend with the lab shim on PATH
export PATH="/c/Users/Chakri/.no-mistakes/evidence/01M3RDVGWMA5EYAMZ2ZVZ6EBRX/r3shim:$PATH"
cd "${ROOT:-/c/Users/Chakri/.no-mistakes/worktrees/199e09f5c085/01M3RDVGWMA5EYAMZ2ZVZ6EBRX}"
source bin/fm-backend.sh
fm_backend_source herdr || exit 9
S=$(cat /tmp/fmlab.name)
"$@"
