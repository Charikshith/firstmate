# Live Windows validation — fm/herdr-windows-socket (bf77c00 vs base c6bdbe3)
Host: MINGW64_NT-10.0-26200 (Git Bash), herdr 0.9.1-preview Windows, Claude Code CLI, lavish-axi.
Herdr lab session: fm-lab-wintest-2368-11019 (bin/fm-herdr-lab.sh provision/run/teardown). Lab home: mktemp under %TEMP% via bin/fm-lab-home.sh.

## 1. Herdr drive-path socket -> presentation lock
herdr session list socket_path: C:\Users\Chakri\AppData\Roaming\herdr\sessions\fm-lab-wintest-2368-11019\herdr.sock
new : socket -> /c/Users/Chakri/AppData/Roaming/herdr/sessions/fm-lab-wintest-2368-11019/herdr.sock rc=0
new : lock   -> /tmp/firstmate-herdr-presentation/order-1c6ef93d20bfdcb0c08c6afa47fd5dc2.lock rc=0 (755 noacl namespace accepted by ownership)
base: socket rc=1, lock rc=1

## 2. Live pane cwd (herdr reports foreground_cwd:null, cwd frozen at the worktree)
after `cd /tmp/fmwt-sub && bash`          : new -> /tmp/fmwt-sub
after native launcher (cmd.exe -> bash) + cd /tmp/fmwt-native : new -> /tmp/fmwt-native ; base -> '' (empty)
ADVERSARIAL nested MSYS subshell (bash -> bash) then `cd /tmp/fmwt-deeper`: new -> /tmp/fmwt-sub (STALE; expected /tmp/fmwt-deeper)
  /proc: 3976 win=9680 ppid=1 cwd=/tmp/fmwt-sub ; 7295 win=28744 ppid=3976 cwd=/tmp/fmwt-deeper
  Win32 table: 28744's ParentProcessId 32852 is absent (exited MSYS fork stub), so the Win32 walk never reaches it.

## 3. Pane-state classification with a real claude.exe
claude foreground            : process-info fg=[claude.exe] -> sample=agent
Win32 walk, claude under native-launched bash : fm_backend_herdr_win_descendant_agent <shell_pid> rc=0 (agent)
after /exit                  : walk rc=1 (shell); absent pid rc=2 (unreadable)
claude under plain MSYS subshell: walk rc=1 (missed; same fork-stub gap as §2)
idle Git Bash pane           : fg=[bash.exe] -> classify=other -> sample=other (walk not reached)
pid-reuse guard (synthetic table): orphan older than shell rc=1, genuine child rc=0, zero ctime rc=1

## 4. Fleet sync clone root (lab home under C:/Users/.../AppData/Local/Temp)
git toplevel: C:/Users/Chakri/AppData/Local/Temp/fm-lab.NCfyjS/projects/demo ; pwd -P: /c/Users/.../projects/demo
new : demo: synced 23aa30e..eb595f1
new : inner: skipped: not a clone root (git would act on .../projects/outer)   <- nested-dir guard kept
base: demo: skipped: not a clone root (git would act on .../projects/demo)

## 5. Lavish board liveness (real lavish-axi listing "D:\Code\...\rustypi-tui.html",open,...)
new : /d/Code/AI/Agents/rustypi/prototype/rustypi-tui.html listed_open rc=0 ; not-open.html rc=1
base: rustypi-tui.html rc=1

## 6. Stop hook launch shape under a REAL Claude Stop hook (claude -p --settings probe, in the lab pane)
old-env-shebang (exec script): harness ancestor NOT found
new-exec-bash   (exec bash script): harness ancestor found winpid 8488

## 7. procevent private dir on noacl (mode reads 755 after chmod 700)
new : exact-mode check rc=0 ; base rc=1
