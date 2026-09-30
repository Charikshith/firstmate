# Live Windows validation: fm/herdr-windows-socket (301f1ed vs base c6bdbe3)

Host: MINGW64_NT-10.0-26200 (Git Bash), herdr 0.9.1-preview (Windows), Claude Code on PATH.
Lab: `bin/fm-herdr-lab.sh provision fm-lab-wintest-49230-30262` (pane default shell = Git Bash login),
backend calls routed through a PATH `herdr` shim -> `fm-herdr-lab.sh run <lab>`; torn down with
`fm-herdr-lab.sh teardown` (rc=0, default session untouched). Base-commit (`c6bdbe3`) scripts were run from a `git archive` copy for comparison.

## 1. Herdr drive-path socket resolves (fm_backend_herdr_presentation_session_socket_path)
herdr session list reports: `C:\Users\Chakri\AppData\Roaming\herdr\sessions\fm-lab-wintest-...\herdr.sock`
- BASE: rc=1 (refused)
- NEW:  `/c/Users/Chakri/AppData/Roaming/herdr/sessions/fm-lab-wintest-49230-30262/herdr.sock` rc=0

## 2. Live pane cwd visible (fm_backend_herdr_current_path)
herdr `pane get`: cwd frozen at the launch dir, foreground_cwd absent.
- BASE: `[]` (empty -> fm-spawn path poll never sees the pane move)
- NEW:  `[/c/Users/Chakri/.no-mistakes/worktrees/.../01M3RDVGWMA5EYAMZ2ZVZ6EBRX]`
- After sending `cd /tmp/fmwt.FTUB && bash` (nested subshell like `treehouse get`): NEW -> `[/tmp/fmwt.FTUB]`

## 3. Pane-state classification with a real Claude in the lab pane
- claude.exe running: sample=`agent`, win_descendant_agent(shell 21824) rc=0, pane_agent_state=`live`
- bogus shell pid: win_descendant_agent rc=2 (unreadable)
- after Esc exits Claude (foreground `bash.exe`): win_descendant_agent rc=1, pane_agent_state=`no-agent`
  (sample=`other`, same as base, because the shared classifier does not map `bash.exe` to shell)

## 4. PID-reuse guard (injected row into real Win32 table, shell created=134352214240113960)
- orphan claude.exe claiming ppid=shell, created OLDER than shell -> rc=1 (ignored)
- created NEWER -> rc=0 (accepted as descendant)
- created 0 -> rc=1 (ignored)

## 5. Private-directory checks on Git Bash noacl (/tmp dir after chmod 700 -> stat reports 755)
- presentation lock namespace: BASE rc=1, NEW rc=0; symlink still rejected (rc=1)
- procevent private dir exact=1: BASE rc=1, NEW rc=0; nonexistent dir rejected (rc=1)
- note: noacl also reports /c/Windows as owned by the current uid, so ownership-only accepts it (lockns rc=0)

## 6. Lavish board liveness vs real lavish-axi listing
listing rows: `"D:\\Code\\AI\\Agents\\rustypi\\prototype\\rustypi-tui.html",open,...`
- /d/.../rustypi-tui.html: BASE rc=1, NEW rc=0
- /d/.../transcript-styles.html: BASE rc=1, NEW rc=0
- prefix /d/.../rustypi-tui.htm: NEW rc=1; unlisted not-a-board.html: NEW rc=1

## 7. Fleet sync on a lab home clone (origin one step ahead)
git prints toplevel as `C:/.../projects/demo`
- home outside %TEMP% (inside the worktree, removed after): BASE `skipped: not a clone root`; NEW `demo: synced e600c0b..cae4104`
- home at `/tmp/fm-lab.X`: BASE skipped; NEW synced
- home at `/c/Users/Chakri/AppData/Local/Temp/fm-lab.X` (Git Bash's default $TMPDIR spelling): NEW still
  `skipped: not a clone root (git would act on /tmp/fm-lab.X/projects/demo)` because pwd -P of the drive path
  resolves through the MSYS /tmp mount
- adversarial: plain dir nested in the firstmate checkout -> still `skipped: not a clone root`

## 8. Stop auto-arm hook command
Ran the hook command string from .claude/settings.json through bash from this Claude Code session with a probe
script in place of fm-claude-stop-autoarm.sh that calls fm_harness_ancestry_pid:
- NEW (`exec bash .../fm-claude-stop-autoarm.sh`): harness ancestor found: winpid=31684
- BASE (`exec .../fm-claude-stop-autoarm.sh`): also found in this invocation shape (base failure not reproduced)
