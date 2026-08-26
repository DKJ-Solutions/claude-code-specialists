<#
.SYNOPSIS
    Regression tests for scripts/lib/seam-lib.ps1's Assert-WorkflowIsolatedSeamPath -- the provenance
    preflight (issue #885, group D) that backstops the isolate-by-default seams.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Assert-WorkflowIsolatedSeamPath is a pure
    function, dot-sourceable, so every PASSING case (it returns normally: no Write-Error, no exit) is
    exercised IN-PROCESS by dot-sourcing seam-lib.ps1 directly and calling the function. The one
    REFUSING case is different: that path calls 'exit 1', which would abort this runner if hit
    in-process, so it is exercised via a CHILD PROCESS instead -- same pattern as
    internal-note.tests.ps1's Invoke-Script, applied to a small generated wrapper script rather than to
    a real release script.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/seam-lib.tests.ps1

    What is asserted:
      1. a consumer whose seam resolves OUTSIDE contributing-davekjohn/ is refused (exit 1), and the
         refusal names the seam and the offending path;
      2. a consumer whose seam resolves INSIDE the folder passes, including the exact-match
         'workflow-davekjohn' case and the backslash-separated case (proving the '\' -> '/'
         normalization);
      3. a SOURCE repo (marketplace.json present) is exempt outright, even for the identical
         outside-the-folder path that got refused for the consumer in case 1 -- proving
         Test-IsWorkflowSourceRepo really short-circuits the whole check rather than the folder
         happening to match;
      4. which of the Get-Default* computed defaults still branch on Test-IsWorkflowSourceRepo and which
         stopped (issue #914) -- see section 3's own note for why the branch's ABSENCE needs an assert.
         The rest of what those functions do is exercised elsewhere too (cut-release-guardrail,
         internal-note, and the other group-D suites all read through them for real).

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot    = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$SeamLibPath = Join-Path $RepoRoot 'scripts\lib\seam-lib.ps1'

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function New-Fixture {
    <#
        A throwaway repo root: a plain directory (a consumer -- no marketplace.json) or one carrying an
        empty .claude-plugin/marketplace.json (a source, per Test-IsWorkflowSourceRepo's own test). Not
        a git repo on purpose -- RepoRoot is passed explicitly, the same fixture shape every other suite
        in this folder uses.
    #>
    param([Parameter(Mandatory)][string]$Label, [switch]$Source)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) "seam-lib-test-$PID-$Label"
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    if ($Source) {
        New-Item -ItemType Directory -Path (Join-Path $dir '.claude-plugin') -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $dir '.claude-plugin\marketplace.json'), '{}', $Utf8NoBom)
    }
    return $dir
}

$consumerDir = New-Fixture -Label 'consumer'
$sourceDir   = New-Fixture -Label 'source' -Source

# --- 1. The passing cases -- in-process, since the function returns normally without exiting --------
Write-Host "seam-lib.ps1 -- Assert-WorkflowIsolatedSeamPath: passing paths return normally (in-process)" -ForegroundColor Cyan

. $SeamLibPath

function Test-ReturnsNormally {
    param([string]$RepoRootArg, [string]$RelativePathArg, [string]$SeamNameArg)
    try {
        Assert-WorkflowIsolatedSeamPath -RepoRoot $RepoRootArg -RelativePath $RelativePathArg -SeamName $SeamNameArg
        return $true
    } catch {
        return $false
    }
}

# BOTH FOLDER NAMES PASS, AND BOTH ARE ASSERTED (#886, August 26, 2026). The folder renamed
# 'workflow-davekjohn/' -> 'contributing-davekjohn/'. The three asserts below it cover the OLD name and are
# kept deliberately: they are what proves an unmigrated consumer's seams still resolve, and this guard
# refuses with exit 1 rather than warning, so losing that tolerance would be a hard stop rather than a
# nuisance.
Assert-True (Test-ReturnsNormally $consumerDir 'contributing-davekjohn/CHANGELOG.md' 'Get-ChangelogPath') `
    'consumer, in-folder path under the CURRENT folder name: passes'
Assert-True (Test-ReturnsNormally $consumerDir 'contributing-davekjohn' 'Get-ChangelogPath') `
    'consumer, exact match "contributing-davekjohn" with no trailing path: passes'
Assert-True (Test-ReturnsNormally $consumerDir 'workflow-davekjohn/CHANGELOG.md' 'Get-ChangelogPath') `
    'consumer, in-folder path under the PRE-RENAME folder name: still passes'
Assert-True (Test-ReturnsNormally $consumerDir 'workflow-davekjohn' 'Get-ChangelogPath') `
    'consumer, exact match "workflow-davekjohn" (PRE-RENAME) with no trailing path: still passes'
Assert-True (Test-ReturnsNormally $consumerDir 'workflow-davekjohn\CHANGELOG.md' 'Get-ChangelogPath') `
    'consumer, backslash-separated in-folder path: passes (the \ -> / normalization works)'
# THE CASE THAT PROVES THE SHORT-CIRCUIT, NOT JUST THE FOLDER MATCH: the exact same relative path that
# gets refused for the consumer below passes here, unchanged, because Test-IsWorkflowSourceRepo exempts
# a source repo outright before the folder check ever runs.
Assert-True (Test-ReturnsNormally $sourceDir 'CHANGELOG.md' 'Get-ChangelogPath') `
    'source repo, path outside the folder: still passes -- exempt regardless of where it resolves'

# --- 2. The refusing case -- child process, since it calls exit 1 and would abort this runner --------
Write-Host "seam-lib.ps1 -- Assert-WorkflowIsolatedSeamPath: the refusal path (child process)" -ForegroundColor Cyan

$wrapperPath = Join-Path ([System.IO.Path]::GetTempPath()) "seam-lib-test-$PID-wrapper.ps1"
$wrapperContent = @"
param(
    [Parameter(Mandatory)][string]`$RepoRoot,
    [Parameter(Mandatory)][string]`$RelativePath,
    [Parameter(Mandatory)][string]`$SeamName
)
. '$SeamLibPath'
Assert-WorkflowIsolatedSeamPath -RepoRoot `$RepoRoot -RelativePath `$RelativePath -SeamName `$SeamName
"@
[System.IO.File]::WriteAllText($wrapperPath, $wrapperContent, $Utf8NoBom)

function Invoke-AssertChild {
    param([string]$RepoRootArg, [string]$RelativePathArg, [string]$SeamNameArg)
    # $psArgs, NOT $args: inside a function $args is an automatic variable holding the caller's own
    # arguments, so assigning to it and splatting the result silently passes something else entirely --
    # the same trap internal-note.tests.ps1's Invoke-Script is written around.
    $psArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $wrapperPath,
        '-RepoRoot', $RepoRootArg, '-RelativePath', $RelativePathArg, '-SeamName', $SeamNameArg)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = (& powershell @psArgs 2>&1 | Out-String)
        return [pscustomobject]@{ Out = $out; Code = $LASTEXITCODE }
    } finally { $ErrorActionPreference = $prevEap }
}

$r = Invoke-AssertChild $consumerDir 'CHANGELOG.md' 'Get-ChangelogPath'
Assert-True ($r.Code -eq 1) 'consumer, path outside the folder: exits 1'
Assert-True ($r.Out -match 'Get-ChangelogPath') 'and the refusal names the seam'
Assert-True ($r.Out -match 'CHANGELOG\.md') 'and the offending path'
Assert-True ($r.Out -match 'contributing-davekjohn') 'and the folder it should have resolved inside'


# --- 3. The computed defaults: which of them stopped branching on the source (issue #914) -----------
# THIS SECTION IS WHY THE FILE SYNOPSIS'S "out of scope" NOTE NO LONGER HOLDS FOR ALL OF THEM. #885 gave
# five seams a computed default and every one branched on Test-IsWorkflowSourceRepo; #914 removed that
# branch from exactly two -- the tier-0 changelog notes and the GitHub Release body -- because a tree
# nothing writes but a cut exists only BECAUSE the workflow does. The branch's absence is the whole
# change, and nothing asserted it: the two functions return one string, so a reinstated branch would go
# on returning a valid path and be discovered at somebody's next cut. The three that KEEP the branch are
# asserted here too, so "collapse them all for symmetry" fails a test rather than reading as tidying.
Write-Host "seam-lib.ps1 -- the computed defaults: source vs consumer" -ForegroundColor Cyan

# Both fixtures need the folder to exist, because Get-WorkflowFolderName prefers what is there.
New-Item -ItemType Directory -Path (Join-Path $consumerDir 'contributing-davekjohn') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $sourceDir   'contributing-davekjohn') -Force | Out-Null

$dfltChangelogSrc = Get-DefaultReleaseChangelogNotesRoot -RepoRoot $sourceDir
$dfltChangelogCon = Get-DefaultReleaseChangelogNotesRoot -RepoRoot $consumerDir
Assert-True ($dfltChangelogSrc -eq 'contributing-davekjohn/releases/changelog') `
    "the changelog notes root is inside the folder in a SOURCE repo: '$dfltChangelogSrc'"
Assert-True ($dfltChangelogSrc -eq $dfltChangelogCon) `
    'and it is the SAME answer for a consumer -- #914 removed the source branch, it did not move it'

$dfltGithubSrc = Get-DefaultReleaseGithubNotesRoot -RepoRoot $sourceDir
Assert-True ($dfltGithubSrc -eq 'contributing-davekjohn/releases/github') `
    "the GitHub-body root is inside the folder in a SOURCE repo too: '$dfltGithubSrc'"
Assert-True ($dfltGithubSrc -eq (Get-DefaultReleaseGithubNotesRoot -RepoRoot $consumerDir)) `
    'and the same for a consumer, for the same reason'

# THE THREE THAT STILL BRANCH, and the reason is not symmetry: a repo's changelog and its release list
# exist whichever tooling cut them, so a source keeps them at its root. #914 did not include the internal
# note either, so its branch stands until somebody asks for it.
Assert-True ((Get-DefaultChangelogPath -RepoRoot $sourceDir) -eq 'CHANGELOG.md') `
    'the changelog path still keeps a source at its own root file'
Assert-True ((Get-DefaultChangelogPath -RepoRoot $consumerDir) -eq 'contributing-davekjohn/CHANGELOG.md') `
    'and still isolates a consumer'
Assert-True ((Get-DefaultReleaseHistoryPath -RepoRoot $sourceDir) -eq 'releases/README.md') `
    'the release history still keeps a source at releases/README.md -- it stayed behind at #914'
Assert-True ((Get-DefaultReleaseInternalNotesRoot -RepoRoot $sourceDir) -eq 'releases/internal') `
    'the internal-note root still branches: #914 did not include it'
Assert-True ((Get-DefaultReleaseInternalNotesRoot -RepoRoot $consumerDir) -eq 'contributing-davekjohn/releases/internal') `
    'and a consumer still gets the isolated answer for it'
Remove-Item -Recurse -Force -LiteralPath $consumerDir -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force -LiteralPath $sourceDir -ErrorAction SilentlyContinue
Remove-Item -Force -LiteralPath $wrapperPath -ErrorAction SilentlyContinue

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
