#!/usr/bin/env bash
# pre-guard-test.sh — regression matrix for pre-guard.sh (hardening pass H1, 2026-07-02).
# Feeds hook-protocol JSON to pre-guard.sh and asserts BLOCK (exit 2) vs ALLOW.
# Text-deterministic guards only — cwd/gh/docker-dependent gates are exercised live, not here.
# Run: bash claude/hooks/tests/pre-guard-test.sh
set -u
GUARD="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/pre-guard.sh"
PASS=0; FAIL=0

t() { # t EXPECT DESC CMD
  local expect="$1" desc="$2" cmd="$3" json rc got
  json=$(jq -cn --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}')
  printf '%s' "$json" | bash "$GUARD" >/dev/null 2>&1; rc=$?
  got="ALLOW"; [ "$rc" -eq 2 ] && got="BLOCK"
  if [ "$got" = "$expect" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "✗ want $expect got $got — $desc :: $cmd"; fi
}
tsql() { # tsql EXPECT DESC SQL
  local expect="$1" desc="$2" sql="$3" json rc got
  json=$(jq -cn --arg s "$sql" '{tool_name:"mcp__erp-sql__query",tool_input:{sql:$s}}')
  printf '%s' "$json" | bash "$GUARD" >/dev/null 2>&1; rc=$?
  got="ALLOW"; [ "$rc" -eq 2 ] && got="BLOCK"
  if [ "$got" = "$expect" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "✗ want $expect got $got — $desc :: $sql"; fi
}

# ── git guards: -C/-c prefix must not bypass (H1 C1) ──
t BLOCK "push --force baseline"            'git push --force'
t BLOCK "push -f short"                    'git push -f origin main'
t BLOCK "-C prefix push --force"           'git -C /tmp/x push --force'
t BLOCK "-c prefix reset --hard"           'git -c user.name=x reset --hard HEAD~1'
t BLOCK "-C prefix reset --hard"           'git -C /tmp/x reset --hard'
t BLOCK "commit --amend baseline"          'git commit --amend'
t BLOCK "-C prefix amend"                  'git -C /tmp/x commit --amend --no-edit'
t BLOCK "checkout -- discards"             'git checkout -- src/app.ts'
t BLOCK "restore ."                        'git restore .'
t BLOCK "clean -fd"                        'git clean -fd'
t BLOCK "stash drop"                       'git stash drop'
t BLOCK "commit --no-verify"               'git commit --no-verify -m ""'
t BLOCK "push --no-verify"                 'git push --no-verify'
t BLOCK "-C prefix no-verify"              'git -C /x commit -m "" --no-verify'

# ── commit -n short form (H1 C4) ──
t BLOCK "commit -n"                        'git commit -n -m "msg"'
t BLOCK "commit -anm cluster"              'git commit -anm "msg"'
t ALLOW "commit -am is fine"               'git commit -am "normal message"'
t ALLOW "commit --signoff is fine"         'git commit --signoff -m "x"'
t ALLOW "push -n is dry-run"               'git push -n origin feature'

# ── push +refspec force (H1 C5) ──
t BLOCK "push +main refspec"               'git push origin +main'
t BLOCK "push +branch refspec"             'git push origin +agents/1-x'
t ALLOW "colon refspec no plus"            'git push origin HEAD:refs/heads/feature'

# ── git add bulk staging (H1 C3) ──
t BLOCK "add -A"                           'git add -A'
t BLOCK "add ."                            'git add .'
t BLOCK "add --all"                        'git add --all'
t BLOCK "-C prefix add -A"                 'git -C /x add -A'
t BLOCK "add . in chain"                   'cd /y && git add .'
t ALLOW "add explicit path"                'git add src/app.ts'
t ALLOW "add ./relative path"              'git add ./src/app.ts'
t ALLOW "add psi dir"                      'git add ψ/memory'
t ALLOW "add dotfile"                      'git add .gitignore'
t ALLOW "add -p patch mode"                'git add -p src/x.ts'

# ── quote-strip: flags inside message text must NOT false-positive ──
t ALLOW "amend inside commit msg"          'git commit -m "fix --amend bug in docs"'
t ALLOW "-n inside commit msg"             'git commit -m "supports -n flag now"'
t ALLOW "force inside maw hey"             'maw hey l1 "git push --force is banned here"'
t ALLOW "reset --hard inside grep arg"     'git log --grep "reset --hard"'

# ── rm -rf hardening (H1 C2): every segment, wrappers, abs path, quotes ──
t BLOCK "rm -rf home baseline"             'rm -rf ~/'
t BLOCK "rm -rf second segment"            'echo cleanup && rm -rf ~'
t BLOCK "rm -rf after semicolon"           'true; rm -rf /etc'
t BLOCK "env wrapper"                      'env rm -rf /'
t BLOCK "abs path /bin/rm"                 '/bin/rm -rf ~'
t BLOCK "xargs rm with text target"       'find x | xargs rm -rf /Users/j.smith'
t BLOCK "quoted root"                      'rm -rf "/"'
t BLOCK "-fr flag order + \$HOME"          'rm -fr $HOME'
t BLOCK "bare star"                        'rm -rf *'
t ALLOW "specific subpath"                 'rm -rf ./node_modules'
t ALLOW "tmp subpath"                      'rm -rf /tmp/build-cache'
t ALLOW "deep home subpath"                'rm -rf /Users/j.smith/ghq/github.com/x/y/agents/slug'
t ALLOW "glob with suffix"                 'rm -rf *.log'
t ALLOW "plain rm file"                    'rm file.txt'

# ── tmux blacklist additions (H1 C6) + pkill/killall (C8) ──
t BLOCK "tmux kill-server"                 'tmux kill-server'
t BLOCK "tmux run-shell"                   'tmux run-shell "echo x"'
t BLOCK "tmux send abbrev"                 'tmux send my-oracle hello'
t BLOCK "tmux respawn-pane"                'tmux respawn-pane -t x'
t ALLOW "tmux word inside quotes"          'echo "tmux kill-server is dangerous"'
t BLOCK "pkill node"                       'pkill node'
t BLOCK "killall -9 tmux"                  'killall -9 tmux'
t BLOCK "pkill -f codex"                   'pkill -f codex'
t ALLOW "pkill unrelated daemon"           'pkill -f my-random-daemon'
t ALLOW "bare kill pid (text-binding)"     'kill 12345'
t ALLOW "ps is read-only"                  'ps aux'

# ── branch -D warns but allows ──
t ALLOW "branch -D warns only"             'git branch -D old-branch'

# ── adversarial-review regression probes (2026-07-02) ──
t ALLOW "multi-line -m with -n word"       $'git commit -m "cli: add -n flag to trends export\n\n- details"'
t ALLOW "multi-line -m with -name"         $'git commit -m "cleanup: find -name pattern fix\n\nbody"'
t ALLOW "multi-line -m mentions --amend"   $'git commit -m "docs: --amend is banned\n\nsee doctrine"'
t ALLOW "rm -rf prose in commit msg"       'git commit -m "docs: warn against rm -rf ~ in cleanup"'
t ALLOW "rm -rf prose in echo"             'echo "never run rm -rf / anywhere"'
t ALLOW "rm -rf prose in issue body"       'gh issue create --title "x" --body "repro: rm -rf /etc fails"'
t ALLOW "rm -rf HOME prose in maw hey"     'maw hey l1 "reminder: rm -rf $HOME is blocked"'
t BLOCK "pkill -f quoted codex"            'pkill -f "codex"'
t BLOCK "quoted --force"                   'git push "--force"'
t BLOCK "git add bare glob"                'git add *'
t ALLOW "git add glob with suffix"         'git add *.ts'
t BLOCK "tmux -L socket kill-server"       'tmux -L sock kill-server'
t BLOCK "sudo rm -rf root"                 'sudo rm -rf /'
t BLOCK "timeout wrapper rm"               'timeout 5 rm -rf ~'

# ── interpreter-wrapper re-scan (audit 2026-07-02 C1/C2): bash -c/sh -c/eval
#    payloads recurse through the same guard — wrapping must not bypass ──
t BLOCK "bash -c force push"               'bash -c "git push --force"'
t BLOCK "sh -c rm -rf root"                'sh -c "rm -rf /"'
t BLOCK "eval reset --hard"                'eval "git reset --hard HEAD~1"'
t BLOCK "bash -c no-verify commit"         'bash -c "git commit --no-verify -m x"'
t BLOCK "bash -c no-verify push"           'bash -c "git push --no-verify origin main"'
t BLOCK "bash -c git add -A"               'bash -c "git add -A"'
t BLOCK "bash -c tmux kill-server"         'bash -c "tmux kill-server"'
t BLOCK "bash -c pkill codex"              'bash -c "pkill -f codex"'
t BLOCK "nested wrapper mixed quotes"      "bash -c 'sh -c \"git push --force\"'"
t ALLOW "bash -c benign pipeline"          'bash -c "ls -la | wc -l"'
t ALLOW "bash -c force-with-lease"         'bash -c "git push --force-with-lease origin main"'
t ALLOW "commit msg mentions bash -c"      'git commit -m "explain bash -c usage in docs"'
t BLOCK "timeout wraps bash -c evil"       'timeout 5 bash -c "rm -rf ~"'
# mention of an interpreter command INSIDE another command's quoted arg must not
# false-positive (detect on CMD_NQ, extract from CMD — audit 2026-07-02 follow-up)
t ALLOW "gh comment names bash -c force"    'gh issue comment 10 --body "now blocks bash -c '"'"'git push --force'"'"' too"'
t ALLOW "echo documents sh -c rm"           'echo "example: sh -c rm -rf / is blocked"'
t BLOCK "push literal upstream-org URL"    'git push https://github.com/upstream-org/maw-js.git HEAD:main'
t BLOCK "push literal upstream-org ssh"    'git push git@github.com:upstream-org/maw-js.git main'
t ALLOW "push own-org literal URL"         'git push https://github.com/your-org/maw-js.git HEAD:feature-x'

# ── production-DB MCP SQL guard (H1 C7): CTE + multi-statement ──
tsql BLOCK "plain INSERT"                  'INSERT INTO PRODDB.dbo.x VALUES(1)'
tsql BLOCK "CTE INSERT"                    'WITH cte AS (SELECT 1 AS a) INSERT INTO PRODDB.dbo.x SELECT a FROM cte'
tsql BLOCK "multi-statement UPDATE"        'SELECT 1; UPDATE PRODDB.dbo.x SET a=1'
tsql ALLOW "plain SELECT"                  'SELECT * FROM PRODDB.dbo.x'
tsql ALLOW "created_at column"             'SELECT created_at FROM PRODDB.dbo.orders'

echo "──────────────────────────────"
echo "pre-guard-test: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
