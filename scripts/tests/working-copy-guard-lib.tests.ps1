<#
.SYNOPSIS
    Tests for scripts/lib/working-copy-guard-lib.ps1 -- the judgement behind the working-copy guard:
    which git commands mutate the dispatching session's tree, index or refs.

.DESCRIPTION
    IN-PROCESS, AND THAT IS THE POINT OF THE SPLIT. The judgement is a pure function, so a case costs
    a function call rather than a process and a payload. The hook's own suite
    (guard-working-copy.tests.ps1) covers the parts that need a real invocation: the agent_id gate,
    the exit codes and the refusal wording.

    SIX GROUPS.
      1. The class, as ONE class. #1665 measured `git stash` plus `git checkout HEAD -- <path>`, so a
         guard shaped like that pair reads as sufficient; #1669's comment records a later occurrence a
         pair-shaped guard would have passed. Every member of the class is asserted here, including
         the ones no incident has produced yet.
      2. The read-only siblings stay open BY NAME. `git stash list`, a `git branch` listing, a `git
         tag` listing, `git clean -n` and reading the reflog share a verb with a destructive form.
         Blocking a whole verb would have been shorter and would refuse a reviewer reading whether a
         stash exists.
      3. Describing the rule is not performing it -- the subcommand position, which is this guard's
         own answer to the lesson guard-live-theme.ps1 paid for. `git commit -m "never run git
         checkout HEAD -- <path>"` is the case no heredoc or text-tool exemption would have saved,
         because the segment IS led by git.
      4. Group 3 must not become a hole: wrappers, second segments, and text piped into a shell.
      5. THE MEASURED FALSE POSITIVE, and every shape that must not turn its exemption into a bypass.
         Run over the 995 real dispatched-subagent calls in this repo's transcripts, the judgement
         refused 12; eleven were real crossings and the twelfth was a test engineer working in its own
         fixture repo under /tmp. The exemption is scope rather than tolerance -- and a command that
         steps out and back IN is still judged, in all three ways it can step back.
      6. An agent with worktree isolation owns its own tree. The harness puts that worktree INSIDE the
         repo (.claude/worktrees/agent-<id>), so a plain "under the root" test would refuse such an
         agent every command in the one tree it is entitled to move. No incident produced this group:
         it is the feature whose whole purpose is to make this hazard impossible, and refusing it
         would be the guard breaking its own remedy.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $RepoRoot 'scripts\lib\working-copy-guard-lib.ps1')

# A stable, invented project root: the assertions are about path REASONING, and must not depend on
# where this checkout happens to live or on anything existing on disk.
$Proj = 'C:\work\myrepo'
$script:pass = 0
$script:fail = 0

function Assert-Violation {
    param([string]$Command, [string]$Name, [string]$Cwd = $Proj, [string]$ExpectSub = '')
    $v = Get-WorkingCopyViolation -Command $Command -ProjectRoot $Proj -Cwd $Cwd
    if ($null -eq $v) {
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected a violation, got none" -ForegroundColor Red
        return
    }
    if ($ExpectSub -and $v.Sub -ne $ExpectSub) {
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected sub '$ExpectSub', got '$($v.Sub)'" -ForegroundColor Red
        return
    }
    $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
}

function Assert-Clean {
    param([string]$Command, [string]$Name, [string]$Cwd = $Proj)
    $v = Get-WorkingCopyViolation -Command $Command -ProjectRoot $Proj -Cwd $Cwd
    if ($null -eq $v) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Name`n         expected none, got a '$($v.Sub)' violation on: $($v.Segment)" -ForegroundColor Red }
}

Write-Host "== working-copy-guard-lib ==" -ForegroundColor Cyan

Write-Host ""
Write-Host "-- group 1: the class, and it is ONE class" -ForegroundColor Cyan

# The two commands #1665 actually measured.
Assert-Violation 'git stash' 'the bare stash #1665 measured -- a bare stash IS a push' -ExpectSub 'stash'
Assert-Violation 'git checkout HEAD -- scripts/lib/gate-lib.ps1' 'the checkout HEAD -- <path> #1665 measured' -ExpectSub 'checkout'
# The command #1669's comment measured, which a pair-shaped guard would have passed.
Assert-Violation 'git checkout fix/1682-porcelain-line-parse' 'the bare branch checkout #1669 measured' -ExpectSub 'checkout'

foreach ($sub in @('checkout main', 'switch -c feat/x', 'restore --staged .', 'reset --hard HEAD',
                   'rebase origin/main', 'merge origin/main', 'pull --ff-only',
                   'cherry-pick abc1234', 'revert HEAD', 'am /tmp/p.patch',
                   'update-ref refs/heads/x HEAD')) {
    Assert-Violation "git $sub" "git $sub"
}
Assert-Violation 'git stash pop'   'stash pop moves the tree too'          -ExpectSub 'stash'
Assert-Violation 'git stash -u'    'stash -u takes untracked files as well' -ExpectSub 'stash'
Assert-Violation 'git clean -fd'   'clean -fd deletes untracked files'      -ExpectSub 'clean'
Assert-Violation 'git branch -D old/thing' 'branch -D destroys a pointer'   -ExpectSub 'branch'
Assert-Violation 'git branch -f main HEAD' 'branch -f moves one'            -ExpectSub 'branch'
Assert-Violation 'git tag -d v4.0.0'       'tag -d removes a ref'           -ExpectSub 'tag'
Assert-Violation 'git tag -f v4.0.0 HEAD'  'tag -f moves one'               -ExpectSub 'tag'
Assert-Violation 'git reflog expire --expire=now --all' 'reflog expire destroys the last recovery path' -ExpectSub 'reflog'
# git's own global options sit before the subcommand and must not hide it.
Assert-Violation 'git -C . checkout main'                    'a -C global option does not hide the subcommand'
Assert-Violation 'git -c core.quotePath=true reset --hard'   'nor does a -c config override'
Assert-Violation 'git --no-pager checkout main'              'nor a valueless global flag'
Assert-Violation 'git.exe checkout main'                     'git.exe is git'
# BOTH -n AND --force IS A DRY RUN, AND THAT WAS VERIFIED AGAINST GIT RATHER THAN REASONED. This
# assertion was first written the other way round -- judged on the --force, on the assumption that the
# more dangerous flag wins -- and the suite caught it. Measured in a throwaway repo: `git clean -nd
# --force` prints "Would remove untracked.txt", exits 0, and the file is still there afterwards. So
# exempting it is not leniency, it is what the command does.
Assert-Clean 'git clean -nd --force' 'clean with BOTH -n and --force is a dry run, so nothing is discarded'

Write-Host ""
Write-Host "-- group 2: the read-only siblings stay open" -ForegroundColor Cyan

foreach ($c in @('git stash list', 'git stash show -p', 'git branch', 'git branch -av',
                 'git branch --show-current', 'git tag', 'git tag -l "v4*"', 'git clean -n',
                 'git clean --dry-run', 'git clean -nd', 'git reflog', 'git reflog -n 5',
                 'git status --short', 'git diff origin/main...HEAD', 'git diff main -- a.ps1',
                 'git show HEAD:a.ps1', 'git log --oneline -5', 'git ls-files', 'git rev-parse HEAD',
                 'git fetch origin -q', 'git worktree add /tmp/probe origin/main',
                 'git worktree list', 'git worktree remove /tmp/probe')) {
    Assert-Clean $c $c
}
Assert-Clean 'git commit -m "a change"' 'commit belongs to another block and does not discard'
Assert-Clean 'git add -A'               'and so does add'
Assert-Clean 'npm test'                 'an unrelated command is not git'
Assert-Clean ''                         'an empty command is not a violation'

Write-Host ""
Write-Host "-- group 3: describing the rule is not performing it" -ForegroundColor Cyan

Assert-Clean 'git commit -m "the reviewer must never run git checkout HEAD -- <path>"' `
    'THE CASE THE SUBCOMMAND POSITION EXISTS FOR: a commit message naming the rule'
Assert-Clean 'git commit -m "fix: git stash and git reset are now refused"' `
    'and one naming two members of the class'
Assert-Clean 'echo "never run git stash in a dispatched agent"' 'echoing the rule'
Assert-Clean 'grep -rn "git checkout HEAD --" plugins/'         'searching for the rule'
Assert-Clean "cat > doc.md <<'EOF'`nnever run git stash here`ngit checkout HEAD -- x is forbidden`nEOF" `
    'a heredoc writing the rule into a file'
Assert-Clean "`$doc = @'`ngit reset --hard is never yours to run`n'@`n`$doc | Out-File notes.md" `
    'a here-string writing the rule into a file'
Assert-Clean 'git log --oneline --grep="git stash"' 'searching history for the words'

Write-Host ""
Write-Host "-- group 4: the counter-cases that make group 3 safe" -ForegroundColor Cyan

Assert-Violation 'bash -c "git reset --hard origin/main"'    'a bash -c wrapper is re-scanned'
Assert-Violation 'powershell -Command "git checkout main"'   'a powershell -Command wrapper too'
Assert-Violation 'echo hi && git checkout main'              'a real command after a harmless one'
Assert-Violation "echo hi`ngit stash"                        'a real command on the next line'
Assert-Violation 'echo "git stash" | bash'                   'text piped into a shell really runs'
Assert-Violation 'eval "git reset --hard"'                   'and so does eval'

Write-Host ""
Write-Host "-- group 5: the measured false positive, and its bypasses" -ForegroundColor Cyan

# The twelfth refusal in the corpus measurement, verbatim in shape: a fixture repo under /tmp.
Assert-Clean 'cd /tmp/grtest2 && git log --oneline && git checkout $(git rev-parse HEAD)' `
    'THE MEASURED FALSE POSITIVE: a fixture repo outside the project is out of scope'
Assert-Clean 'cd C:\work\other && git reset --hard'      'so is another checkout entirely'
Assert-Clean 'git -C C:\work\other reset --hard'         'and a -C into one'
Assert-Clean 'cd C:\work\myrepo-lanes\fix--x && git checkout main' `
    'a lane worktree is a SIBLING of the repo, so the ordinary rule already covers it'

Assert-Violation 'cd /tmp/grtest2 && cd C:\work\myrepo && git reset --hard' `
    'stepping out and back IN is judged -- the exemption is not a bypass'
Assert-Violation 'cd /tmp/grtest2 && git -C C:\work\myrepo checkout main' `
    'a -C back in outranks the cd out'
Assert-Violation 'cd /tmp/grtest2 && git --work-tree=C:\work\myrepo checkout main' `
    'and so does a --work-tree back in'
Assert-Violation 'cd /tmp/grtest2 && git --git-dir=C:\work\myrepo\.git checkout main' `
    'and a --git-dir back in'
Assert-Violation 'cd scripts && git checkout HEAD -- lib/gate-lib.ps1' `
    'a RELATIVE cd stays inside the project'
Assert-Violation 'cd "C:\work\myrepo" && git stash' `
    'a quoted cd to the project itself is inside'
Assert-Violation 'cd $SOMEWHERE && git reset --hard' `
    'a cd this file cannot resolve is treated as inside -- never exempt what cannot be read'

# With no project root there is no question to answer, so everything is judged.
$v = Get-WorkingCopyViolation -Command 'cd /tmp/grtest2 && git reset --hard'
if ($null -ne $v) { $script:pass++; Write-Host "  [PASS] with NO project root the directory rule is skipped and everything is judged" -ForegroundColor Green }
else { $script:fail++; Write-Host "  [FAIL] with NO project root the directory rule is skipped and everything is judged" -ForegroundColor Red }

Write-Host ""
Write-Host "-- group 6: an isolated agent owns its own worktree" -ForegroundColor Cyan

$wt = 'C:\work\myrepo\.claude\worktrees\agent-a1'
Assert-Clean 'git checkout main' 'an agent standing in its OWN worktree may move it' -Cwd $wt
Assert-Clean 'git reset --hard'  'and reset it'                                      -Cwd $wt
Assert-Clean 'cd C:\work\myrepo\.claude\worktrees\agent-a1 && git stash' 'reached by an explicit cd, too'
Assert-Violation 'cd C:\work\myrepo && git reset --hard' `
    'but a cd back to the dispatching checkout is judged' -Cwd $wt
Assert-Violation 'git -C C:\work\myrepo reset --hard' `
    'and so is a -C back to it' -Cwd $wt

Write-Host ""
Write-Host "-- the pieces, directly" -ForegroundColor Cyan

$inv = Get-GitInvocation 'git -C . checkout HEAD -- a.ps1'
Assert-Violation 'git checkout main' 'sanity: the judgement is reachable'
if ($inv.Sub -eq 'checkout') { $script:pass++; Write-Host "  [PASS] Get-GitInvocation reads past global options to the subcommand" -ForegroundColor Green }
else { $script:fail++; Write-Host "  [FAIL] Get-GitInvocation reads past global options to the subcommand (got '$($inv.Sub)')" -ForegroundColor Red }

$inv = Get-GitInvocation 'git stash'
if ($inv.Args.Count -eq 0) { $script:pass++; Write-Host "  [PASS] a subcommand with no arguments yields an EMPTY argument list, not a reversed one" -ForegroundColor Green }
else { $script:fail++; Write-Host "  [FAIL] a subcommand with no arguments yields an empty argument list (got $($inv.Args.Count): $($inv.Args -join ','))" -ForegroundColor Red }

if ($null -eq (Get-GitInvocation 'npm run build')) { $script:pass++; Write-Host "  [PASS] a non-git segment is not an invocation" -ForegroundColor Green }
else { $script:fail++; Write-Host "  [FAIL] a non-git segment is not an invocation" -ForegroundColor Red }

# Case sensitivity is a real property here: -d and -D are different flags, as are -m/-M and -c/-C.
if (Test-HasFlag -Arguments @('-D') -Flags @('-D')) { $script:pass++; Write-Host "  [PASS] Test-HasFlag matches -D" -ForegroundColor Green }
else { $script:fail++; Write-Host "  [FAIL] Test-HasFlag matches -D" -ForegroundColor Red }
if (-not (Test-HasFlag -Arguments @('-a') -Flags @('-D'))) { $script:pass++; Write-Host "  [PASS] and does not match an unrelated short flag" -ForegroundColor Green }
else { $script:fail++; Write-Host "  [FAIL] and does not match an unrelated short flag" -ForegroundColor Red }
if (Test-HasFlag -Arguments @('-nd') -Flags @('-n')) { $script:pass++; Write-Host "  [PASS] and finds a flag inside a BUNDLE (-nd carries -n)" -ForegroundColor Green }
else { $script:fail++; Write-Host "  [FAIL] and finds a flag inside a bundle (-nd carries -n)" -ForegroundColor Red }
if (-not (Test-HasFlag -Arguments @('--contains') -Flags @('-c'))) { $script:pass++; Write-Host "  [PASS] and does not read a long flag as a bundle of short ones" -ForegroundColor Green }
else { $script:fail++; Write-Host "  [FAIL] and does not read a long flag as a bundle of short ones" -ForegroundColor Red }

Write-Host ""
Write-Host "Summary: $script:pass passed, $script:fail failed" -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
