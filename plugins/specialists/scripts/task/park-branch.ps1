<#
.SYNOPSIS
    Park the current branch: commit any outstanding work and push it to origin -- NO PR, no live
    action.

.DESCRIPTION
    "Parking" a branch means: back it up to the remote so the exact same state is immediately
    continuable on any other device. Parking is the sibling of open-pr in the shared branch-workflow
    layer (issue #81), but deliberately stops well short of a PR:

      1. Guardrail: refuses on main -- parking is a feature-branch action (everything on main goes
         via a PR).
      2. Commits ALL outstanding work on the current branch (git add -A + commit), so nothing is
         left behind locally. The changelog entry file and any other WIP travel along, which is what
         makes "continue on another device" actually work.
      3. Pushes the branch to origin with `git push -u` (sets upstream tracking).

    What parking is NOT:
      - It opens NO pull request (push != PR -- the PR rule stays intact and separate, exactly like
        new-branch -Park).
      - It performs NO live/deploy action of any kind: it only touches git (add/commit/push). A
        consumer whose repo drives a live target (e.g. a Shopify theme) is never published by a park.

    Relation to `new-branch -Park`: that flag parks a branch AT CREATION and commits ONLY the
    changelog entry (leaving other staged work untouched). This script parks an EXISTING branch at
    any point mid-work and commits EVERYTHING outstanding. Use new-branch -Park to start-and-park in
    one move; use park-branch to back up a branch you are already working on.

    Self-contained: depends only on git and the shared native-capture helper that travels with it --
    no repo-owned config (no branch-info, no repo-config), so it needs no consumer-side scaffold.

    Every git call goes through the shared Invoke-NativeCapture (EAP=Continue -> run -> record
    $LASTEXITCODE), because git writes progress ('remote:' lines, etc.) to stderr, which under
    EAP=Stop would become a terminating NativeCommandError before the exit code could be judged (the
    #96/#97/#107 pitfall). The commit message goes via `git commit -F <file>`, never `-m "...$branch..."`:
    a branch name may legally carry a `"` which embedded in an -m argument would break native argv
    reconstruction (the quoting lesson) -- a message file sidesteps argv entirely.

    Pure ASCII (repo convention for .ps1).

.PARAMETER Intent
    (Optional) a short note on where you left off / what is next. When outstanding work is committed,
    it is appended to the park commit message, so the "where I left off" state lives in git history
    rather than only in cross-session memory. Ignored when there is nothing new to commit (the branch
    was already committed locally and is merely being pushed).

.EXAMPLE
    ./scripts/task/park-branch.ps1

.EXAMPLE
    ./scripts/task/park-branch.ps1 -Intent "Skeleton + routing done; next: wire the API client."
#>
[CmdletBinding()]
param(
    [string]$Intent = ''
)

$ErrorActionPreference = 'Stop'

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# Shared native-capture helper (#114 item 1). $PSScriptRoot-relative, not $repoRoot: this lib is not
# repo-owned -- it travels with the SAME plugin/mirror payload as this script (registered in
# scripts\lib\shared-scripts-lib.ps1), so it resolves from the workshop root, a consumer's plugin
# cache, or the plugin mirror tree alike.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# Current branch from HEAD. Via Invoke-NativeCapture so a detached/edge git state cannot turn a
# stderr line into a terminating error before the exit code is judged.
$branchRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'rev-parse', '--abbrev-ref', 'HEAD')
if ($branchRes.ExitCode -ne 0) {
    Write-Error "park cannot run -- not a git repository (or no HEAD): $repoRoot"
    exit 1
}
$branch = ($branchRes.Output | Out-String).Trim()

# Guardrail: parking is a feature-branch action. On main everything goes via a PR, so there is
# nothing to park.
if ($branch -eq 'main') {
    Write-Error "You are on main; park works on a feature branch (everything on main goes via a PR)."
    exit 1
}

# Stage everything outstanding: the whole point of a park is that nothing is left behind locally.
$addRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'add', '-A')
$addRes.Output | ForEach-Object { Write-Host $_ }
if ($addRes.ExitCode -ne 0) { Write-Error "park: staging outstanding work failed."; exit 1 }

# Commit only if something is actually staged. `git diff --cached --quiet` exits 0 when there is
# nothing staged (clean or already-committed) and 1 when there are staged changes -- so a branch
# that was already committed locally but never pushed skips the commit and is simply pushed as-is
# (the real-world scenario this script exists for, issue #175).
$diffRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'diff', '--cached', '--quiet')
if ($diffRes.ExitCode -ne 0) {
    # Message via `git commit -F <file>`, not `-m "...$branch..."`: a branch name may legally carry a
    # `"` (git check-ref-format allows it), which embedded in an -m argument would break native argv
    # reconstruction (the quoting lesson). A message file sidesteps argv entirely. An optional -Intent
    # is appended as a second paragraph, so "where I left off" lands in the commit itself. Cleaned up
    # in finally, whether or not git succeeds.
    $msg = "park: $branch (work parked for later)"
    if ($Intent.Trim()) { $msg = "$msg`n`n$($Intent.Trim())" }
    $msgFile = Join-Path ([System.IO.Path]::GetTempPath()) "park-branch-msg-$PID.txt"
    [System.IO.File]::WriteAllText($msgFile, $msg, (New-Object System.Text.UTF8Encoding $false))
    try {
        $commitRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'commit', '-F', $msgFile)
        $commitRes.Output | ForEach-Object { Write-Host $_ }
        if ($commitRes.ExitCode -ne 0) { Write-Error "park: committing outstanding work failed."; exit 1 }
    } finally {
        Remove-Item -Path $msgFile -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "park: nothing new to commit -- pushing the existing commits as-is." -ForegroundColor Yellow
}

# Push + set upstream tracking, so the branch is reachable (and continuable) from another device.
# No PR: push != PR (the PR rule stays intact and separate).
$pushRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'push', '-u', 'origin', $branch)
$pushRes.Output | ForEach-Object { Write-Host $_ }
if ($pushRes.ExitCode -ne 0) { Write-Error "park: git push failed (is 'origin' configured and reachable?)."; exit 1 }

Write-Host "Branch '$branch' parked on origin (pushed, no PR)." -ForegroundColor Green
exit 0
