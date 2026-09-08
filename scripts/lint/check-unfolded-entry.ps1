<#
.SYNOPSIS
    Gate: does the trunk carry an unfolded changelog entry -- a per-branch development document that a merge left
    behind because its fold never ran? (issue #1270)

.DESCRIPTION
    THE HOLE THIS CLOSES. The fold (fold-changelog-entry.ps1) runs from exactly one place: ship-pr.ps1,
    locally. A PR merged from the GitHub UI -- or any path that skips ship-pr -- merges the branch's
    development document into the trunk and never folds it: the '### DEPLOY:' entry stays trapped in the
    document, CHANGELOG.md never receives it, and a release cut in that window misses the change in the
    notes. Nothing downstream reported it. Measured on #1266: PRs #1253 and #1261 sat unfolded on main
    for ~10 hours. #1270 is the standing question that split off from it -- make the skipped fold loud.

    IT ADDS NO RULE OF ITS OWN. It calls Get-UnfoldedTrunkEntry in entry-scaffold-lib.ps1, which is the
    one definition of "a written entry stranded on the trunk". The invariant: on the trunk,
    dkj-policy/ carries no per-branch development document -- new-branch.ps1 creates one on a branch, the
    fold removes it at the merge. A written one whose declared branch is not the branch under HEAD is a
    leftover.

    TWO CALLERS, ONE ANSWER. The CI workflow .github/workflows/unfolded-entry.yml runs it on every push
    to main, so the leftover is caught regardless of who merged or how. The SessionStart hook
    unfolded-entry-sessioncheck.ps1 (workflow plugin) runs it in every repo that has the plugin, so the
    next specialists session is told at start rather than relying on a manual check.

    NO gh, NO NETWORK, NO PR. Whether the leftover's branch is merged, closed or still open does not
    change the answer: a written entry on the trunk is folded or it is a defect, and the fold is local.
    That is what lets the SessionStart hook run this in a consumer with no token.

    AND ONE THING THE WORKING COPY ALONE CANNOT ANSWER (issue #1585): whether the fold has ALREADY RUN
    on origin. A checkout that is merely BEHIND origin/<trunk> still carries the document on disk and
    still has a CHANGELOG.md without the entry, so the detector above -- which reads the working copy
    and nothing else -- reported a landed fold as a skipped one, and sent the reader at a fold when the
    repair was one 'git pull --ff-only'. Measured September 8, 2026: fold-on-merge.yml had folded
    fix/1575-prune-merged-dirty-guard and pushed it at 08:50:21Z, and a session starting 7 commits
    behind was told the fold never ran. Nothing was BROKEN -- fold-changelog-entry.ps1 has its own
    trunk guard and refuses on a stale checkout, so following the printed remedy was safe -- but the
    [ERROR] was indistinguishable from the real skipped-fold state this check exists to catch.

    SO EACH LEFTOVER IS ASKED ONE MORE QUESTION, AND IT COSTS NO NETWORK: is it still present on the
    remote-tracking ref refs/remotes/origin/<trunk> that is already on disk? Absent there means the
    fold has landed and this checkout has not caught up. THE QUESTION IS ONLY ASKED WHEN THE CHECKOUT
    IS BEHIND -- Get-TrunkGap -NoFetch, the same measurement the fold refuses on and new-branch.ps1
    warns on -- because absent-on-origin with a gap of ZERO means something else entirely: a document
    that was never committed, which no pull will fix. That gate is also what keeps this arm unreachable
    from CI, where the pushed commit IS origin/<trunk> and the gap is 0.

    AND THE GATE IS A GAP, NOT A DIRECTION, WHICH LEAVES ONE STATE MISREAD: a checkout that is BOTH
    ahead and behind. There, a document committed locally and never pushed is also absent on origin, and
    is reported as already folded. The precise test would be the other half of the same fold commit --
    is the entry in CHANGELOG.md ON THAT REF -- and it is deliberately not built here: it would put a
    second definition of "what a folded entry looks like in the changelog" in this script, and the
    state needs local unpushed commits on the trunk, which this workflow only produces between a fold
    and its push. Named rather than guarded, and tracked as issue #1601.

    RUN IT FROM CI, and from the command line whenever you want the answer early:

        powershell -NoProfile -File scripts/lint/check-unfolded-entry.ps1
        powershell -NoProfile -File scripts/lint/check-unfolded-entry.ps1 -Branch main

    Exit 0 when the trunk is clean (or the only per-branch document present is the branch you are on),
    and exit 0 with a [WARN] when every document found has already been folded on origin -- the trunk
    that matters carries no unfolded entry, and only this checkout is behind. Exit 1 with the file(s)
    and the branch each declares whenever a fold is genuinely still owed.

    Pure ASCII, per this repo's script-layer convention.

.PARAMETER Branch
    The branch to treat as "current" -- its own development document is expected and not a leftover.
    Defaults to the current one. The CI workflow passes 'main' explicitly: a push to main IS main, but
    naming it keeps the workflow readable and independent of the checkout's detached state.

.PARAMETER RootOverride
    Repo root to operate on, for the test suite and the SessionStart hook. A consumer never types this:
    the root is resolved dual-context like every other shared script.

.EXAMPLE
    powershell -NoProfile -File scripts/lint/check-unfolded-entry.ps1 -Branch main
#>
[CmdletBinding()]
param(
    [string]$Branch = '',
    [string]$RootOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# NO SOURCE-REPO GUARD, deliberately, and for exactly the reason source-repo-guard-lib.ps1's own header
# gives for check-roster-sync.ps1 and check-script-contract.ps1: a SessionStart hook invokes this from
# '${CLAUDE_PLUGIN_ROOT}/scripts/lint/' against the current repo, so Assert-OwnCopy would refuse it --
# and thereby the hook -- at every session start in the source repo. The CI half runs the in-repo copy
# (via actions/checkout), which the guard would not have fired on anyway.

# THE ROOT COMES FROM ONE DEFINITION (#1422). Dot-sourced guarded, so a mirror built before this lib
# existed degrades to the old inline form rather than throwing.
$checkLib = Join-Path $PSScriptRoot '..\lib\consumer-check-lib.ps1'
if (Test-Path -LiteralPath $checkLib -PathType Leaf) { . $checkLib }

$repoRoot = if (Get-Command Resolve-CheckRepoRoot -ErrorAction SilentlyContinue) {
    Resolve-CheckRepoRoot -RootOverride $RootOverride
} elseif ($RootOverride) { $RootOverride } elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# '' MEANS "COULD NOT TELL". This runs from a SessionStart hook as well as from CI, and the hook's case
# is a tree that is not a checkout -- where there is no trunk to carry a leftover, so there is nothing to
# judge rather than a failure. The CI half always has a checkout (actions/checkout), so it never lands here.
if (-not $repoRoot) {
    Write-Host '[OK] no git checkout here -- no trunk to carry an unfolded entry.'
    exit 0
}

# repo-config.ps1 first and optional, exactly as check-branch-entry loads it. Get-BranchFileDeclaredBranch
# reads the branch-line label from the wording rather than a hardcoded literal, and Get-BranchTrunkName
# reads an optional Get-TrunkBranchName -- a repo that translated the wording or renamed its trunk is
# read by its own names only while this is in the session.
$repoConfig = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $repoConfig -PathType Leaf) {
    try { . $repoConfig } catch { Write-Warning "scripts/repo-config.ps1 failed to load ($($_.Exception.Message)) -- the built-in wording is used." }
}

# GUARDED, LIKE consumer-check-lib ABOVE, AND FOR THE SAME REASON. Get-TrunkGap needs
# Invoke-NativeCapture, and this check is mirrored into a plugin whose cached copy in a consumer may
# predate #1585. Where the lib is absent the two Get-Command probes below both miss, the upstream
# question is never asked, and the report degrades to exactly the pre-#1585 wording -- a check that
# still answers its original question rather than one that throws at a session start.
$nativeLib = Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1'
if (Test-Path -LiteralPath $nativeLib -PathType Leaf) { . $nativeLib }

. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')

# $Branch is passed through as-is, empty included. Get-UnfoldedTrunkEntry resolves HEAD itself, with
# its own try/catch -- so this script needs no git call and does not fall over on a fixture tree that
# is not a checkout (the SessionStart hook's case). An empty current branch excludes nothing, and
# every written per-branch document is then reported: the right answer for a CI checkout of the trunk, and
# the CI workflow passes -Branch main explicitly anyway.
if ($Branch -eq 'HEAD') { $Branch = '' }

$leftovers = @(Get-UnfoldedTrunkEntry -RepoRoot $repoRoot -CurrentBranch $Branch)

if ($leftovers.Count -eq 0) {
    Write-Host '[OK] no unfolded changelog entry on the trunk.'
    exit 0
}

# --- IS THE FOLD OWED, OR ALREADY LANDED ON ORIGIN? (issue #1585) --------------------------------
# The gap is measured with -NoFetch: the remote-tracking ref is read exactly as the last fetch left it,
# so a SessionStart hook stays offline and a fixture repo with no origin simply reports Measured=$false.
# A caller must never read "could not measure" as "behind" (Get-TrunkGap's own header says so), which is
# why $behind stays 0 unless the measurement actually succeeded.
$behind   = 0
$trunkRef = ''
if ((Get-Command Get-TrunkGap -ErrorAction SilentlyContinue) -and (Get-Command Invoke-NativeCapture -ErrorAction SilentlyContinue)) {
    try {
        $gap = Get-TrunkGap -RepoRoot $repoRoot -NoFetch
        if ($gap.Measured) { $behind = [int]$gap.Behind; $trunkRef = [string]$gap.Ref }
    } catch { }
}

$folded   = New-Object System.Collections.Generic.List[object]
$stranded = New-Object System.Collections.Generic.List[object]
foreach ($l in $leftovers) {
    $landed = $false
    if ($behind -gt 0 -and $trunkRef) {
        # 'git cat-file -e <ref>:<path>' is the whole test: a non-zero exit means the document is not in
        # origin's tree at all, which is the fold's own signature -- it REMOVES the document and adds the
        # entry to CHANGELOG.md in one commit. Reading CHANGELOG.md on that ref instead would answer the
        # same question and cost a blob read plus a heading match; the absent path is the cheaper half of
        # the same commit.
        $probe = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'cat-file', '-e', "${trunkRef}:$($l.Rel)") -DiscardStderr
        if ($probe.ExitCode -ne 0) { $landed = $true }
    }
    if ($landed) { $folded.Add($l) | Out-Null } else { $stranded.Add($l) | Out-Null }
}

if ($stranded.Count -eq 0) {
    # NOT [ERROR], AND NOT SILENCE EITHER. The trunk that matters -- origin's -- carries no unfolded
    # entry, so exit 1 would report a defect that does not exist; but a checkout this far behind is worth
    # one line, and the SessionStart hook surfaces this token with its own accurate headline.
    Write-Host "[WARN] $($folded.Count) development document(s) here have ALREADY been folded on $trunkRef -- this checkout is $behind commit(s) behind:" -ForegroundColor Yellow
    foreach ($l in $folded) {
        Write-Host "         $($l.Rel)  (declares branch '$($l.DeclaredBranch)')" -ForegroundColor Yellow
    }
    Write-Host '       So this is not a skipped fold and there is nothing to fold -- the entry is already in' -ForegroundColor Yellow
    Write-Host '       CHANGELOG.md on origin. Catch up instead:' -ForegroundColor Yellow
    Write-Host '         git pull --ff-only' -ForegroundColor Yellow
    exit 0
}

Write-Host "[ERROR] the trunk carries $($stranded.Count) unfolded changelog entry(ies) -- a merge landed but its fold never ran:" -ForegroundColor Red
foreach ($l in $stranded) {
    Write-Host "          $($l.Rel)  (declares branch '$($l.DeclaredBranch)')" -ForegroundColor Red
}
Write-Host '        The DEPLOY section is still trapped in each document, so CHANGELOG.md never received' -ForegroundColor Red
Write-Host '        it and a release cut would miss the change. Fold each one now:' -ForegroundColor Red
foreach ($l in $stranded) {
    Write-Host "          fold-changelog-entry.ps1 -Branch $($l.DeclaredBranch) -Commit -Push" -ForegroundColor Red
}
Write-Host '        (In the source repo run scripts/release/fold-changelog-entry.ps1; a consumer runs the' -ForegroundColor Red
Write-Host '        fold-changelog skill.) If a ship is in progress the fold commit is seconds away and' -ForegroundColor Red
Write-Host '        this clears itself.' -ForegroundColor Red
if ($behind -gt 0) {
    # PULL FIRST, OR THE REMEDY ABOVE REFUSES. fold-changelog-entry.ps1's own trunk guard (#1405) stops
    # on a stale checkout, so naming the fold without naming the gap sends the reader at a command that
    # cannot run yet.
    Write-Host "        This checkout is also $behind commit(s) behind $trunkRef -- 'git pull --ff-only' first," -ForegroundColor Red
    Write-Host '        or the fold refuses on the stale trunk.' -ForegroundColor Red
}
foreach ($l in $folded) {
    Write-Host "        (Already folded on origin, nothing owed: $($l.Rel) -- the pull clears it.)" -ForegroundColor Yellow
}
exit 1
