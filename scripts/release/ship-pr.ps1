<#
.SYNOPSIS
    Ship the current branch in one command: open the PR -> wait for the CI check -> merge -> fold.

.DESCRIPTION
    Orchestrates the whole PR chain that is otherwise run by hand
    (open-pr.ps1 -> watch CI -> gh pr merge -> checkout main -> fold-changelog-entry.ps1), so the
    five-step sequence becomes one call. Deliberately workshop-local tooling (like cut-release.ps1):
    NOT mirrored into the plugin, because merge policy and the CI check name are repo-specific --
    a consumer that wants the same convenience writes its own (smartwatchbanden already has a
    ship-pr.ps1). WHEN it may run is governance, not script logic (see CLAUDE.md): by default a
    finished branch ships without asking, but work with a visible result -- or work that is
    irreversible/outward-facing -- waits for Dave's explicit word first.

    Steps, stopping on the first failure (nothing is forced):
      1. open-pr.ps1 -Title <Title> [-SkipLint] [-SkipTests] -- runs the local lint + test gate,
         pushes, and opens the PR. If a gate fails, nothing is pushed and this stops here.
      2. Look up the PR number for the current branch (gh pr list --head <branch>).
      3. Wait for the required CI check to finish (gh pr checks <pr> --watch). Branch protection on
         main blocks the merge until it is green; if a check FAILS, this stops WITHOUT merging.
      4. Merge (gh pr merge <pr> --merge). No --admin: the CI gate is never bypassed.
      5. Check out main, fast-forward, fold the entry (fold-changelog-entry.ps1 -Branch <branch>),
         and commit + push the fold directly on main (the permitted fold exception).
      6. Verify the issues the PR declared it closes are actually CLOSED, and close any that are not
         (verify-resolved-issues.ps1 -- its own script, and tested there).

    Step 6 is the second half of the resolves gate (a lesson from PRs #341-#343, where eight repaired
    findings stayed open because the bodies carried plain mentions instead of closing keywords).
    open-pr.ps1 writes the `Closes #<n>` lines; GitHub honours them on merge into the default branch.
    Step 6 then checks the outcome. A belt on top of a brace: if it never fires, the keyword did its
    job. It cannot fail the ship -- the merge has already happened by then.

    -NoMerge stops after step 1 (open the PR only) -- the same as calling open-pr.ps1 directly, but
    handy when scripting. The native git/gh calls run through Invoke-NativeCapture (the #107 stderr
    guard). Pure ASCII (repo convention for .ps1).

    NOTE (test gap): like open-pr.ps1 this orchestrator drives live git/gh against a real remote and
    is not covered by an automated suite -- the sub-steps it calls (open-pr, fold,
    verify-resolved-issues, the helpers) are tested on their own. Step 6 was deliberately extracted
    into its own script for exactly that reason: it is the one step here that MUTATES state outside
    this repo (it posts comments and closes issues), so leaving it inline would have meant untestable
    write access. What remains untested here is only the orchestration order.

.PARAMETER Title
    PR title, e.g. "feat: new domain plugin".

.PARAMETER SkipLint
    Passed through to open-pr.ps1 (skip the lint gate -- escape valve).

.PARAMETER SkipTests
    Passed through to open-pr.ps1 (skip the test gate -- escape valve).

.PARAMETER NoMerge
    Open the PR and stop (do not wait for CI, merge, or fold).

.PARAMETER PollSeconds
    Poll interval (seconds) for the CI watch. Default 15.

.PARAMETER Resolves
    Passed through to open-pr.ps1: the issue numbers this PR resolves, as a string ('331,332').
    Step 6 verifies them. A string and not an [int[]] for the reason documented on open-pr.ps1's own
    parameter: across `powershell -File` a comma list is cast to one number via the thousands
    separator ('332,340' -> 332340), silently and without an error.

.PARAMETER NoResolves
    Passed through to open-pr.ps1: declare that this PR closes no issue.

.EXAMPLE
    ./scripts/release/ship-pr.ps1 -Title "feat: group release output by category"

.EXAMPLE
    ./scripts/release/ship-pr.ps1 -Title "fix: the pre-flight reads commits" -Resolves 331,332
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Title,
    [switch]$SkipLint,
    [switch]$SkipTests,
    [switch]$NoMerge,
    [int]$PollSeconds = 15,
    [string]$Resolves = '',
    [switch]$NoResolves
)
$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

# Repo name from the local repo-config (single source), and the shared native-capture helper (#114).
. (Join-Path $repoRoot 'scripts\repo-config.ps1')
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')
$repo = Get-RepoName

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq 'main') { Write-Error "You are on main; ship-pr runs from a branch."; exit 1 }

# --- Step 1: open the PR (open-pr.ps1 runs the lint + test gate, pushes, opens) ------------------
$openArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'open-pr.ps1'), '-Title', $Title)
if ($SkipLint)  { $openArgs += '-SkipLint' }
if ($SkipTests) { $openArgs += '-SkipTests' }
# Handed over as the raw string. open-pr.ps1 parses it itself precisely BECAUSE this hop goes through
# `powershell -File`, where an [int[]] parameter would silently collapse '331,332' into 331332.
if ($Resolves) { $openArgs += @('-Resolves', $Resolves) }
if ($NoResolves) { $openArgs += '-NoResolves' }
Write-Host "ship-pr: opening the PR..." -ForegroundColor Cyan
& powershell @openArgs
if ($LASTEXITCODE -ne 0) { Write-Error "open-pr failed -- ship-pr stops (nothing merged)."; exit 1 }

if ($NoMerge) {
    Write-Host "ship-pr: -NoMerge set -- PR opened, stopping before the CI wait/merge/fold." -ForegroundColor Green
    exit 0
}

# --- Step 2: find the PR number for this branch --------------------------------------------------
$prList = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'list', '--head', $branch, '--state', 'open', '--json', 'number', '--limit', '1', '--repo', $repo) -DiscardStderr
if ($prList.ExitCode -ne 0) { Write-Error "Could not list the PR for '$branch' (is gh logged in?)."; exit 1 }
$prs = @($prList.Output | ConvertFrom-Json)
if ($prs.Count -lt 1) { Write-Error "No open PR found for '$branch' after open-pr -- stopping."; exit 1 }
$pr = $prs[0].number
Write-Host "ship-pr: PR #$pr opened for '$branch'." -ForegroundColor Green

# --- Step 3: wait for the required CI check ------------------------------------------------------
# The CI checks can lag a few seconds behind the push: `gh pr checks` prints "no checks reported"
# and exits 0 while none are registered yet -- indistinguishable by exit code from "all passed", so
# a bare --watch could return immediately and let the merge below run straight into a BLOCKED wall.
# First poll (on the TEXT, not the exit code) until at least one check is registered, then --watch it.
Write-Host "ship-pr: waiting for CI (lint-en-tests) on PR #$pr..." -ForegroundColor Cyan
$maxWaitSec = 180
$waited = 0
while ($true) {
    $probe = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'checks', "$pr", '--repo', $repo)
    if (($probe.Output | Out-String) -notmatch 'no checks reported') { break }
    if ($waited -ge $maxWaitSec) {
        Write-Error "No CI check registered for PR #$pr after ${maxWaitSec}s -- NOT merged. Check the workflow, or merge manually once it is green."
        exit 1
    }
    Write-Host "  (no check registered yet -- waited ${waited}s/${maxWaitSec}s)" -ForegroundColor DarkYellow
    Start-Sleep -Seconds $PollSeconds
    $waited += $PollSeconds
}
# --watch now blocks until the registered check finishes; exit 0 = all passed, non-zero = a failure.
# Branch protection blocks the merge until green, so a non-zero here means we must NOT merge.
$checks = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'checks', "$pr", '--watch', '--interval', "$PollSeconds", '--repo', $repo)
$checks.Output | ForEach-Object { Write-Host $_ }
if ($checks.ExitCode -ne 0) {
    Write-Error "CI did not pass for PR #$pr (exit $($checks.ExitCode)) -- NOT merged. Fix CI and re-run, or merge manually once green."
    exit 1
}
Write-Host "ship-pr: CI green." -ForegroundColor Green

# --- Step 4: merge (no --admin: never bypass the CI gate) ----------------------------------------
$merge = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'merge', "$pr", '--merge', '--repo', $repo)
$merge.Output | ForEach-Object { Write-Host $_ }
if ($merge.ExitCode -ne 0) { Write-Error "Merge of PR #$pr failed."; exit 1 }
Write-Host "ship-pr: PR #$pr merged." -ForegroundColor Green

# --- Step 5: main + fold + commit + push ---------------------------------------------------------
$co = Invoke-NativeCapture -FilePath 'git' -Arguments @('checkout', 'main')
$co.Output | ForEach-Object { Write-Host $_ }
if ($co.ExitCode -ne 0) { Write-Error "git checkout main failed."; exit 1 }

# Fetch + an EXPLICIT ff-only merge of origin/main, not a bare `git pull --ff-only` (lesson of
# July 29, 2026, PR #257). The bare pull aborted with "Cannot fast-forward to multiple branches" on a
# clean main immediately after a merge + prune -- and it aborts HERE, in the one gap between the merge
# and the fold, which is the state nothing reports: the PR is merged, the entry file is still in the
# root, and every gate stays green until a release trips over it. Git raises that error when handed more
# than one ref to merge; naming origin/main explicitly hands it exactly one, so this step cannot reach
# that failure mode, whereas a bare pull depends on whatever FETCH_HEAD happens to hold. Why the pull
# got more than one ref was deliberately not guessed at -- see Derek's lens for that reasoning.
$fetch = Invoke-NativeCapture -FilePath 'git' -Arguments @('fetch', '--prune', 'origin')
$fetch.Output | ForEach-Object { Write-Host $_ }
if ($fetch.ExitCode -ne 0) { Write-Error "git fetch of origin failed."; exit 1 }

$ff = Invoke-NativeCapture -FilePath 'git' -Arguments @('merge', '--ff-only', 'origin/main')
$ff.Output | ForEach-Object { Write-Host $_ }
if ($ff.ExitCode -ne 0) { Write-Error "git merge --ff-only of origin/main failed."; exit 1 }

Write-Host "ship-pr: folding the changelog entry..." -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'fold-changelog-entry.ps1') -Branch $branch
if ($LASTEXITCODE -ne 0) { Write-Error "fold-changelog-entry failed -- fold not committed."; exit 1 }

$add = Invoke-NativeCapture -FilePath 'git' -Arguments @('add', '-A')
if ($add.ExitCode -ne 0) { Write-Error "git add failed."; exit 1 }
$commit = Invoke-NativeCapture -FilePath 'git' -Arguments @('commit', '-m', "chore: fold changelog entry $branch (#$pr)")
$commit.Output | ForEach-Object { Write-Host $_ }
if ($commit.ExitCode -ne 0) { Write-Error "git commit of the fold failed."; exit 1 }

$push = Invoke-NativeCapture -FilePath 'git' -Arguments @('push', 'origin', 'main')
$push.Output | ForEach-Object { Write-Host $_ }
if ($push.ExitCode -ne 0) { Write-Error "git push of the fold failed."; exit 1 }

# --- Step 6: the issues the PR declared it closes are actually closed -----------------------------
# Its own script, so this state-MUTATING logic (it comments and closes) is testable against a fake gh
# instead of only reachable through a full live ship -- and so the same check is usable on its own to
# repair bookkeeping after the fact. It never fails the ship: the merge already succeeded.
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'verify-resolved-issues.ps1') -Pr $pr -Repo $repo
if ($LASTEXITCODE -ne 0) { Write-Warning "the issue-closing check reported a problem -- verify by hand with: gh issue list --repo $repo --state open" }

Write-Host "Done: PR #$pr shipped -- opened, CI green, merged, folded on main." -ForegroundColor Green
