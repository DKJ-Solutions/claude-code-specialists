<#
.SYNOPSIS
    Unfolded-entry check: detects a branch's development document left committed on the trunk, which
    is a fold that never ran after a merge (issue #1270). Read-only, no network.

.DESCRIPTION
    The fold (fold-changelog-entry.ps1) folds a branch's `### DEPLOY:` entry into CHANGELOG.md and
    REMOVES that branch's development document -- so on the trunk there is no copy at all
    (contributing-davekjohn/development.md is created by new-branch and removed by the fold; per-branch
    since #1255). Therefore ANY development document committed on the trunk ref is a skipped fold: the
    entry never reached CHANGELOG.md's `## [Unreleased]` list, and a release cut in that window would
    miss the change.

    THE MERGE PATH THAT PRODUCES THIS. The fold is invoked only from ship-pr.ps1, locally. A PR brought
    up to date and merged from the GitHub UI never touches ship-pr, so nothing folds -- measured on
    PRs #1253 and #1261 (issue #1266), both merged from the UI by accounts that were not running a
    specialists session. cut-release.ps1 already refuses to cut while such a leftover exists; nothing
    surfaced it before the cut. This check is that early signal, run from a SessionStart hook
    (unfolded-entry-sessioncheck.ps1) alongside the roster / connector / script-contract checks.

    WHY IT IS PURELY LOCAL. "Was this branch merged?" would need gh, auth and a network round trip at
    every session start in every consumer. It is also the wrong question: a leftover on the trunk is a
    skipped fold whether the branch is merged, closed or still open, so the file's mere presence on the
    trunk ref is the whole signal. No gh, no ancestry walk.

    WHICH TRUNK REF. origin/<trunk> when the remote-tracking ref exists (the shared trunk #1270 is
    about), else the local <trunk> branch. No fetch is done -- the remote-tracking ref is read from
    disk, so a leftover pushed since the last fetch surfaces on the next session after a pull rather
    than immediately. That is a signal, not a gate; strictly better than the silence it replaces. The
    working tree and the current branch are never inspected, so a feature branch's own in-progress
    development-<slug>.md is not a finding.

    Per finding it names the file, the ref, the branch the document declares, whether the `### DEPLOY:`
    entry is still filled (an unfolded entry) or the file is in its reset state (a fold that removed
    the entry but not the file), and the fold command to run.

    Soft / read-only, mirroring check-script-contract.ps1: this script changes nothing, in any repo.
    [OK]/[INFO]/[ERROR] convention shared via check-report-lib.ps1 (issue #114). Exit code: 0 = no
    errors, 1 = at least one.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Use this path as the repo root instead of the dual-context default.

.PARAMETER TrunkRefOverride
    (Optional, for tests) Inspect this git ref instead of resolving origin/<trunk> or the local
    <trunk> branch. A fixture points it at a scratch ref it built.

.EXAMPLE
    .\scripts\sync\check-unfolded-entry.ps1
#>
param(
    [string]$ConsumerPathOverride = '',
    [string]$TrunkRefOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:errors = 0
$script:infos  = 0

# Write-Ok/Write-Info/Write-Failure/Write-CheckSummary/Resolve-CheckRoot/Write-CheckScope: shared with
# the other sync checks (single source, issue #114). $PSScriptRoot-relative (NOT $repoRoot -- this lib
# is not repo-owned), so it resolves from the source root or the plugin mirror alike.
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')

# The branch-document helpers -- Get-BranchTrunkName, Get-BranchFilePaths, Get-BranchFileLegacyNames,
# Get-BranchFileDeclaredBranch, Test-BranchChangelogIsFilled. entry-scaffold-lib.ps1 is shared machinery
# that travels with this script (same plugin payload), so $PSScriptRoot-relative like the lib above.
# repo-config.ps1 is OPTIONAL and backs the Get-TrunkBranchName seam Get-BranchTrunkName reads; every
# value it supplies has a working default, so Test-Path then a try/catch that degrades to a warning.
$scope = Resolve-CheckRoot -Override $ConsumerPathOverride
if (-not $scope.Path) {
    Write-Host '== check-unfolded-entry ==' -ForegroundColor Cyan
    Write-Failure "no repo root could be resolved ($($scope.Note)) -- nothing was checked."
    Write-CheckSummary
}
$repoRoot = $scope.Path

$repoConfigPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $repoConfigPath -PathType Leaf) {
    try { . $repoConfigPath } catch {
        Write-Warning "scripts\repo-config.ps1 could not be loaded ($($_.Exception.Message)); falling back to the default trunk name."
    }
}
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')

Write-Host '== check-unfolded-entry ==' -ForegroundColor Cyan
Write-CheckScope -Scope $scope -CheckName 'check-unfolded-entry'

# git query commands only (ls-tree, show). Each sets $ErrorActionPreference = 'Continue' before the
# redirect: under this script's top-level 'Stop', PowerShell 5.1 wraps every native stderr line as a
# terminating error, so '2>$null' alone is not enough -- the repo's no-unprotected-redirect rule. Every
# ref reaches these only AFTER Test-GitRef has confirmed it resolves, so the error path is never taken.
function Invoke-GitQuery {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $ErrorActionPreference = 'Continue'
    $out = & git -C $repoRoot @Arguments 2>$null
    return [pscustomobject]@{ Ok = ($LASTEXITCODE -eq 0); Lines = @($out) }
}

# rev-parse --verify --quiet is SILENT on a ref that does not resolve (exit 1, nothing on either
# stream), so this is the one probe that can ask "does this ref exist" without leaking a `fatal:` line
# into a session-forwarded report. '^{commit}' also rejects a ref that exists but is not a commit.
function Test-GitRef {
    param([string]$Ref)
    $ErrorActionPreference = 'Continue'
    & git -C $repoRoot rev-parse --verify --quiet "$Ref^{commit}" > $null 2>&1
    return ($LASTEXITCODE -eq 0)
}

$trunk = Get-BranchTrunkName

# WHICH REF: an override wins (a fixture's scratch ref), then origin/<trunk> if that remote-tracking ref
# resolves, then the local <trunk> branch. Nothing is fetched -- a remote-tracking ref is read from disk.
$refToInspect = ''
$refLabel = ''
if ($TrunkRefOverride) {
    if (Test-GitRef $TrunkRefOverride) { $refToInspect = $TrunkRefOverride; $refLabel = $TrunkRefOverride }
} else {
    foreach ($cand in @(
        [pscustomobject]@{ Ref = "refs/remotes/origin/$trunk"; Label = "origin/$trunk" },
        [pscustomobject]@{ Ref = "refs/heads/$trunk";          Label = $trunk }
    )) {
        if (Test-GitRef $cand.Ref) { $refToInspect = $cand.Ref; $refLabel = $cand.Label; break }
    }
}

if (-not $refToInspect) {
    # Not a failure: a fresh clone whose trunk is named differently, a detached checkout, a repo with no
    # origin, or a fixture override that does not resolve. An authority that cannot be read is not
    # evidence of a problem.
    $what = if ($TrunkRefOverride) { "'$TrunkRefOverride'" } else { "'origin/$trunk' or local '$trunk'" }
    Write-Ok "no $what ref to inspect -- the trunk could not be read here."
    Write-CheckSummary
}

# The names a branch document can carry: the per-branch pattern, the pre-#1255 shared name, and every
# legacy name (including the pre-#886 workflow-davekjohn/ set) -- all from the one resolver the fold and
# every gate share, so this cannot drift from what actually gets written. Both legacy KINDS: before the
# August 2026 merge the entry and the step list were two files, and the fold removed both, so a leftover
# of either is a skipped fold.
$paths       = Get-BranchFilePaths
$dirGlob     = "$($paths.Directory)/$($paths.Pattern)"        # contributing-davekjohn/development-*.md
$sharedName  = [string]$paths.SharedFile                      # contributing-davekjohn/development.md
$legacyNames = @(Get-BranchFileLegacyNames -Kind Deployment) + @(Get-BranchFileLegacyNames -Kind Cycle) |
    Sort-Object -Unique

$tree = Invoke-GitQuery -Arguments @('ls-tree', '-r', '--name-only', $refToInspect, '--', $paths.Directory, 'workflow-davekjohn')
if (-not $tree.Ok) {
    Write-Ok "could not list '$refLabel' -- the trunk could not be read here."
    Write-CheckSummary
}

# CASE-SENSITIVE matching (-clike / -ceq / -ccontains): git paths are case-sensitive and the resolver's
# canonical names are all lowercase, so a case-insensitive '-like development-*.md' would also swallow
# contributing-davekjohn/DEVELOPMENT-portable.md -- the portable doc a consumer's folder carries -- and
# raise a false [ERROR] at every session start in every consumer.
$leftovers = @($tree.Lines | Where-Object {
    $p = ([string]$_).Trim()
    $p -and (($p -clike $dirGlob) -or ($p -ceq $sharedName) -or ($legacyNames -ccontains $p))
})

if ($leftovers.Count -eq 0) {
    Write-Ok "'$refLabel' carries no branch development document -- every merged branch was folded."
    Write-CheckSummary
}

foreach ($path in ($leftovers | Sort-Object -Unique)) {
    $show = Invoke-GitQuery -Arguments @('show', "${refToInspect}:${path}")
    $text = if ($show.Ok) { ($show.Lines -join "`n") } else { '' }
    $declared = ''
    $filled = $false
    if ($text) {
        $declared = [string](Get-BranchFileDeclaredBranch -Text $text -OpeningHeadingOnly)
        $filled = [bool](Test-BranchChangelogIsFilled -Text $text)
    }

    if ($declared -and $declared -ne $trunk) {
        $state = if ($filled) {
            "Its '### DEPLOY:' entry is still trapped here and never reached CHANGELOG.md's '## [Unreleased]' list"
        } else {
            'The file is in its reset state -- the entry folded, the file did not'
        }
        Write-Failure ("$path is committed on '$refLabel', but the fold removes a branch's development " +
            "document at the merge -- it never ran for '$declared'. $state. Fold it: " +
            "fold-changelog-entry.ps1 -Branch $declared, then commit the result on '$trunk' (the fold exception).")
    } elseif ($declared -eq $trunk) {
        Write-Failure ("$path is committed on '$refLabel' and declares the trunk ('$declared') -- a reset-state " +
            "development document the fold should have removed. Delete it on '$trunk'; nothing needs folding.")
    } else {
        Write-Failure ("$path is committed on '$refLabel' with no readable branch heading -- a development " +
            "document the fold should have removed. Read it, fold the branch it belongs to " +
            "(fold-changelog-entry.ps1 -Branch <branch>), then remove it on '$trunk'.")
    }
}

Write-CheckSummary
