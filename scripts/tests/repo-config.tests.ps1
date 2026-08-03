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

# The CHANGELOG.md section heading fold-changelog-entry.ps1 folds a merged entry into (issue #178,
# Optional in the script contract -- see check-script-contract.ps1). Must be the literal '##' heading
# line as it appears in the file; this workshop's own value is '## Pull Requests'.
$heading = Get-ChangelogHeading
Assert-Match $heading '^##\s' 'Get-ChangelogHeading returns a literal ## heading line'
Assert-Equal '## Pull Requests' $heading "Get-ChangelogHeading is '## Pull Requests' in this workshop"

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

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
