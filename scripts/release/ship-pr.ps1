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

    -NoMerge stops after step 1 (open the PR only) -- the same as calling open-pr.ps1 directly, but
    handy when scripting. The native git/gh calls run through Invoke-NativeCapture (the #107 stderr
    guard). Pure ASCII (repo convention for .ps1).

    NOTE (test gap): like open-pr.ps1 this orchestrator drives live git/gh against a real remote and
    is not covered by an automated suite -- the sub-steps it calls (open-pr, fold, the helpers) are
    tested on their own.

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

.EXAMPLE
    ./scripts/release/ship-pr.ps1 -Title "feat: group release output by category"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Title,
    [switch]$SkipLint,
    [switch]$SkipTests,
    [switch]$NoMerge,
    [int]$PollSeconds = 15
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

$pull = Invoke-NativeCapture -FilePath 'git' -Arguments @('pull', '--ff-only')
$pull.Output | ForEach-Object { Write-Host $_ }
if ($pull.ExitCode -ne 0) { Write-Error "git pull --ff-only of main failed."; exit 1 }

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

Write-Host "Done: PR #$pr shipped -- opened, CI green, merged, folded on main." -ForegroundColor Green
