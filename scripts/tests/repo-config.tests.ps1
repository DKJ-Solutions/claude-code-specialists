<#
.SYNOPSIS
    Regression tests for scripts/repo-config.ps1 (the local repo-data SSOT).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Guards that the repo name lives in one
    place and that its blob URL is derived from it (issue #81 -- the repo name used to be
    hardcoded in open-pr.ps1, fold-changelog-entry.ps1 and release-lib.ps1).

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/repo-config.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\repo-config.ps1')

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name (pattern '$Pattern' not found)" -ForegroundColor Red
    }
}

Write-Host "repo-config" -ForegroundColor Cyan
$name = Get-RepoName
Assert-Match $name '^[\w.-]+/[\w.-]+$' 'Get-RepoName has the form owner/name'

# The blob URL is derived from the repo name (single source) -- not separately hardcoded.
$blob = Get-RepoBlobUrl
Assert-Equal "https://github.com/$name/blob/main/" $blob 'Get-RepoBlobUrl is derived from Get-RepoName'

# The lint gate that open-pr.ps1 runs (repo-specific, injected instead of hardcoded in open-pr).
$lint = Get-LintScript
Assert-Match $lint '\.ps1$' 'Get-LintScript points to a .ps1'
Assert-Match $lint '^scripts[\\/]' 'Get-LintScript is repo-root-relative under scripts/'

# Roster config for check-roster-sync.ps1 (the roster file + the deliberately ignored agent ids).
$roster = Get-RosterPath
Assert-Match $roster '\.md$' 'Get-RosterPath points to a .md'
$ignored = @(Get-RosterIgnoredIds)
foreach ($id in $ignored) { Assert-Match $id '^\d{2}-\d{2}$' "Get-RosterIgnoredIds: '$id' is a valid <group>-<id>" }

# THE CHANGELOG'S TIER SECTIONS (the tier model, August 5, 2026) -- which section
# fold-changelog-entry.ps1 files a merged entry under, one per tier, in the order they appear in the
# document. Optional in the script contract, like the single Get-ChangelogHeading it replaces (issue
# #178).
#
# ASSERTED AGAINST CHANGELOG.md ITSELF, not just for shape. A heading declared here that the document
# does not have makes the fold stop dead on the next merged branch, and a heading the document has that
# is NOT declared here silently stops receiving entries -- so the seam and the file are held against each
# other in both directions.
$tierHeadings = Get-ChangelogTierHeadings
Assert-True ($null -ne $tierHeadings) 'Get-ChangelogTierHeadings returns a map'
$tierPairs = @()
foreach ($e in $tierHeadings.GetEnumerator()) { $tierPairs += [pscustomobject]@{ Tier = [int]$e.Key; Heading = [string]$e.Value } }
Assert-Equal 3 $tierPairs.Count 'three tier sections are declared in this workshop'
Assert-Equal '2,1,0' (($tierPairs | ForEach-Object { $_.Tier }) -join ',') 'declared highest tier first -- the map order IS the document order'
foreach ($p in $tierPairs) {
    Assert-Match $p.Heading '^##\s' "tier $($p.Tier): the heading is a literal ## line"
    Assert-Equal "## Tier $($p.Tier) - Pull Requests" $p.Heading "tier $($p.Tier): this workshop's heading"
}
$changelogPath = Join-Path $PSScriptRoot '..\..\CHANGELOG.md'
$changelogText = Get-Content -LiteralPath $changelogPath -Raw -Encoding UTF8
foreach ($p in $tierPairs) {
    $found = @([regex]::Matches($changelogText, '(?m)^' + [regex]::Escape($p.Heading) + '\s*$')).Count
    Assert-Equal 1 $found "tier $($p.Tier): its heading appears exactly once in CHANGELOG.md"
}
$declaredHeadings = @($tierPairs | ForEach-Object { $_.Heading })
$prLike = @([regex]::Matches($changelogText, '(?m)^##[^\r\n]*Pull Requests[^\r\n]*$') | ForEach-Object { $_.Value.Trim() })
foreach ($h in $prLike) {
    Assert-True ($declaredHeadings -contains $h) "CHANGELOG.md's '$h' is declared in the seam (an undeclared section stops receiving entries silently)"
}

# The legacy single-section seam is deliberately NOT defined here: the tier map supersedes it, and a value
# nothing reads is a value that goes stale unnoticed. The fold still recognises it for a consumer that has
# not migrated, which is why it stays in the script contract as an [INFO] rather than being removed there.
Assert-Equal $null (Get-Command Get-ChangelogHeading -ErrorAction SilentlyContinue) 'Get-ChangelogHeading is not defined here -- the tier map answers instead'

# How many minors a major must recap. Ten in this workshop, and the number is held against the literal
# because the shared script hardcodes the same fallback -- the same two-copy risk as the entry stubs
# below.
Assert-Equal 10 (Get-ReleaseMajorMinMinors) 'Get-ReleaseMajorMinMinors is 10 in this workshop'

# The two retired highlights knobs. Asserted on ABSENCE: both configured the remove-before-publishing
# marker that the tier model replaced, and a repo-config still answering them would be handing values to
# a mechanism that no longer reads them.
foreach ($gone in 'Get-ReleaseHighlightsStakeholderTypes', 'Get-ReleaseHighlightsWording') {
    Assert-Equal $null (Get-Command $gone -ErrorAction SilentlyContinue) "$gone is retired, not left returning a value nothing reads"
}

# The optional "go live" stage description for the cut-release skill's Block 2 (issue #177, Optional
# in the script contract). Empty by default in this workshop and life-hub -- no separate live stage,
# so Block 2 of the checklist never applies here; only a repo that has one fills this in.
$liveStage = Get-LiveStage
Assert-Equal '' $liveStage "Get-LiveStage defaults to '' in this workshop (no separate live stage)"

# The stub wording new-changelog-entry.ps1 writes (issue #410, all four Optional in the script
# contract). Asserted against the LITERAL values rather than merely "is non-empty", because these four
# are the fallbacks the shared script hardcodes as well: if the two ever disagree, a consumer that
# defines nothing and a consumer that copies this file get different entries, which is exactly the
# split #410 exists to close. check-script-contract.ps1's Default fields are the third copy and are
# pinned by script-contract.tests.ps1.
Assert-Equal 'TODO: title' (Get-EntryTitlePlaceholder) 'Get-EntryTitlePlaceholder matches the shared default'
Assert-Equal '**To do / where I left off:**' (Get-EntryBodyHeading) 'Get-EntryBodyHeading matches the shared default'
Assert-Equal 'TODO: what still needs to happen on this branch, and where you left off.' (Get-EntryBodyPlaceholder) 'Get-EntryBodyPlaceholder matches the shared default'
Assert-Equal 'Chore' (Get-EntryFallbackType) 'Get-EntryFallbackType matches the shared default'

# The fallback type must be a type this repo's own branch table actually produces -- the release cut
# groups entries by that string, so a typo here silently drops every unknown-prefix entry into a
# catch-all category at the next release.
. (Join-Path $PSScriptRoot '..\lib\branch-info.ps1')
$knownTypes = @(Get-BranchTypes)
Assert-True ($knownTypes -contains (Get-EntryFallbackType)) "Get-EntryFallbackType ('$(Get-EntryFallbackType)') is one of the types this repo's branch table produces"

# How ship-pr.ps1 merges (issue #411, Optional in the contract). Constrained to the three values
# `gh pr merge` accepts: ship-pr validates it and refuses anything else rather than handing an unknown
# flag to gh at the moment it is about to write to main -- so this assert is the same guard, one layer
# earlier, where it costs nothing to hit.
$mergeMethod = Get-PrMergeMethod
Assert-True (@('merge', 'squash', 'rebase') -contains $mergeMethod) "Get-PrMergeMethod ('$mergeMethod') is one of merge/squash/rebase"
Assert-Equal 'merge' $mergeMethod 'Get-PrMergeMethod is merge in this workshop (every PR keeps its own commits on main)'

# The file set fix-mojibake.ps1 examines by default (issue #413, Optional in the contract). Asserted
# against the real repo root rather than a fixture: the point of moving this list out of the tool was
# that a list can silently stop matching the repo it describes, and only the real tree can show that.
$repoRootForPaths = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$mjPaths = @(Get-MojibakePaths -RepoRoot $repoRootForPaths)
Assert-True ($mjPaths.Count -gt 0) 'Get-MojibakePaths returns a non-empty set'
Assert-True (($mjPaths | Where-Object { $_ -notmatch '\.md$' }).Count -eq 0) 'Get-MojibakePaths returns only .md files'
Assert-True (($mjPaths | Where-Object { -not (Test-Path -LiteralPath $_) }).Count -eq 0) 'Get-MojibakePaths returns only paths that exist'
foreach ($mustHave in @('CHANGELOG.md', 'README.md', 'CLAUDE.md')) {
    $want = Join-Path $repoRootForPaths $mustHave
    Assert-True ($mjPaths -contains $want) "Get-MojibakePaths includes the root $mustHave"
}
# The two directories that made the old hardcoded list workshop-shaped, and the reason it had to move
# behind the seam: a consumer has neither, and the tool silently examined almost nothing there.
Assert-True (($mjPaths | Where-Object { $_ -match '\\plugins\\' }).Count -gt 0) 'Get-MojibakePaths reaches the per-plugin CHANGELOG.md/RELEASE.md files'
Assert-True (($mjPaths | Where-Object { $_ -match '\\releases\\' }).Count -gt 0) 'Get-MojibakePaths reaches the archived release notes'

# The highlights tier (#417, Optional in the contract). ON for minor/major since August 3, 2026 -- these
# asserts were written the other way round one commit earlier, when the tier was off, and were flipped
# with Dave's decision. Kept as asserts on the VALUE rather than deleted: the tier writes files into
# releases/ and its output is judged by eye, so a silent change to either knob is worth a red test.
# Whether the tier WORKS is release-lib.tests.ps1's job; this is only about what this repo answers.
$hlBumps = @(Get-ReleaseHighlightsBumps)
Assert-Equal 2 $hlBumps.Count 'Get-ReleaseHighlightsBumps names two bump types'
Assert-True ($hlBumps -contains 'minor') 'Get-ReleaseHighlightsBumps includes minor'
Assert-True ($hlBumps -contains 'major') 'Get-ReleaseHighlightsBumps includes major'
# Patch is excluded BY DESIGN, not by omission: a minor here is cut when a consumer notices something,
# so a patch has no highlights reader by definition. Asserted so adding 'patch' becomes a decision.
Assert-True ($hlBumps -notcontains 'patch') 'Get-ReleaseHighlightsBumps excludes patch -- a patch has nothing a consumer would read'
# A bump type that is not one of the three the script understands would silently never match, so the
# tier would appear configured and generate nothing. Guarded here rather than at release time.
$badBumps = @($hlBumps | Where-Object { @('major', 'minor', 'patch') -notcontains $_ })
Assert-Equal 0 $badBumps.Count "Get-ReleaseHighlightsBumps names only major/minor/patch (stray: $($badBumps -join ', '))"

# WHAT USED TO BE ASSERTED HERE, and why it is not. Two more knobs configured the highlights draft: which
# branch types to promote above a "remove before publishing" marker, and in whose words to label that
# marker. The asserts held them against this repo's own branch table, because a type named there that
# branch-info never produces would put an empty category above the marker and drop the real ones below it.
#
# Both knobs, the marker and that whole failure mode are gone (August 5, 2026): the highlights document is
# now the release's TIER-2 entries, declared per entry by their author rather than inferred from a branch
# prefix -- which this repo had measured does not predict impact. Their absence is asserted at the top of
# this file, where the tier map is checked, rather than here where the values used to be read.

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
