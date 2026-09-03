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
    contributing-davekjohn/ carries no per-branch development document -- new-branch.ps1 creates one on a branch, the
    fold removes it at the merge. A written one whose declared branch is not the branch under HEAD is a
    leftover.

    TWO CALLERS, ONE ANSWER. The CI workflow .github/workflows/unfolded-entry.yml runs it on every push
    to main, so the leftover is caught regardless of who merged or how. The SessionStart hook
    unfolded-entry-sessioncheck.ps1 (workflow plugin) runs it in every repo that has the plugin, so the
    next specialists session is told at start rather than relying on a manual check.

    NO gh, NO NETWORK, NO PR. Whether the leftover's branch is merged, closed or still open does not
    change the answer: a written entry on the trunk is folded or it is a defect, and the fold is local.
    That is what lets the SessionStart hook run this in a consumer with no token.

    RUN IT FROM CI, and from the command line whenever you want the answer early:

        powershell -NoProfile -File scripts/lint/check-unfolded-entry.ps1
        powershell -NoProfile -File scripts/lint/check-unfolded-entry.ps1 -Branch main

    Exit 0 when the trunk is clean (or the only per-branch document present is the branch you are on);
    exit 1 with the file(s) and the branch each declares otherwise.

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

# Dual-context repo root: a consumer running the plugin mirror gets it from CLAUDE_PROJECT_DIR, the
# source root copy falls back to the git root. Same resolution as every other mirrored script.
$repoRoot = if ($RootOverride) { $RootOverride } elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# repo-config.ps1 first and optional, exactly as check-branch-entry loads it. Get-BranchFileDeclaredBranch
# reads the branch-line label from the wording rather than a hardcoded literal, and Get-BranchTrunkName
# reads an optional Get-TrunkBranchName -- a repo that translated the wording or renamed its trunk is
# read by its own names only while this is in the session.
$repoConfig = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $repoConfig -PathType Leaf) {
    try { . $repoConfig } catch { Write-Warning "scripts/repo-config.ps1 failed to load ($($_.Exception.Message)) -- the built-in wording is used." }
}

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

Write-Host "[ERROR] the trunk carries $($leftovers.Count) unfolded changelog entry(ies) -- a merge landed but its fold never ran:" -ForegroundColor Red
foreach ($l in $leftovers) {
    Write-Host "          $($l.Rel)  (declares branch '$($l.DeclaredBranch)')" -ForegroundColor Red
}
Write-Host '        The DEPLOY section is still trapped in each document, so CHANGELOG.md never received' -ForegroundColor Red
Write-Host '        it and a release cut would miss the change. Fold each one now:' -ForegroundColor Red
foreach ($l in $leftovers) {
    Write-Host "          fold-changelog-entry.ps1 -Branch $($l.DeclaredBranch) -Commit -Push" -ForegroundColor Red
}
Write-Host '        (In the source repo run scripts/release/fold-changelog-entry.ps1; a consumer runs the' -ForegroundColor Red
Write-Host '        fold-changelog skill.) If a ship is in progress the fold commit is seconds away and' -ForegroundColor Red
Write-Host '        this clears itself.' -ForegroundColor Red
exit 1
