<#
.SYNOPSIS
    Tests for scripts/task/adopt-workflow-folder.ps1 -- the scaffold that places the workflow's own
    root folder (contributing-davekjohn/) in a consuming repo.

.DESCRIPTION
    What is covered, and why these four:
      1. the DRY RUN default writes nothing -- the same contract adopt-config is trusted on;
      2. -Apply places every file the folder promises, with the branch files in the reset shape the
         shared formatters write -- and the releases page carrying NO history table, since the list
         belongs at the repo root (inbound #786);
      3. a re-run is additive: a file somebody edited is never overwritten, whatever it says;
      4. a repo that publishes plugins is refused -- the source keeps its docs at its root (Dave,
         August 14, 2026), so the scaffold must not build the layout its owner declined.

    The repo root is pinned per child run via CLAUDE_PROJECT_DIR, the same dual-context branch every
    mirrored script resolves first, so the fixtures need no git of their own.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\task\adopt-workflow-folder.ps1'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) "adopt-workflow-folder-test-fixture-$PID"

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
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern not found: '$Pattern'" -ForegroundColor Red
    }
}

function New-FixtureConsumer {
    param([string]$Label, [switch]$AsPluginSource)
    $root = Join-Path $Fixture "consumer-$Label"
    if (Test-Path -LiteralPath $root) { Remove-Item -Recurse -Force -LiteralPath $root }
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    if ($AsPluginSource) {
        New-Item -ItemType Directory -Path (Join-Path $root '.claude-plugin') -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $root '.claude-plugin\marketplace.json'), '{}')
    }
    return $root
}

function Invoke-Adopt {
    param([string]$Dir, [string[]]$ScriptArgs = @())
    $prevPd = $env:CLAUDE_PROJECT_DIR
    try {
        $env:CLAUDE_PROJECT_DIR = $Dir
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script @ScriptArgs
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
    } finally {
        if ($null -eq $prevPd) { Remove-Item Env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prevPd }
    }
}

# Every file -Apply must place. Read from the same claim the script makes rather than restated per
# assert, so a target added there fails ONE list here instead of passing unexamined.
$ExpectedFiles = @(
    'contributing-davekjohn\README.md',
    'contributing-davekjohn\CONTRIBUTING.md',
    'contributing-davekjohn\releases\README.md',
    'contributing-davekjohn\releases\audience\.gitkeep'
)

try {
    Write-Host "== adopt-workflow-folder.tests: scripts/task/adopt-workflow-folder.ps1 ==" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null

    # --- 1. Dry run (the default): the plan is printed, nothing is written -------------------------
    Write-Host "adopt-workflow-folder -- dry run writes nothing" -ForegroundColor Cyan
    $c1 = New-FixtureConsumer -Label 'dryrun'
    $r1 = Invoke-Adopt -Dir $c1
    Assert-Equal 0 $r1.Code 'dry run: exit 0'
    Assert-Match 'DRY RUN' $r1.Out 'dry run: says so out loud'
    Assert-Match '\[create\]\s+contributing-davekjohn/README\.md' $r1.Out 'dry run: lists the folder README as to-create'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $c1 'contributing-davekjohn'))) 'dry run: the folder was not created'

    # --- 2. -Apply places the whole folder ----------------------------------------------------------
    Write-Host "adopt-workflow-folder -- -Apply places every file" -ForegroundColor Cyan
    $c2 = New-FixtureConsumer -Label 'apply'
    $r2 = Invoke-Adopt -Dir $c2 -ScriptArgs @('-Apply')
    Assert-Equal 0 $r2.Code '-Apply: exit 0'
    foreach ($rel in $ExpectedFiles) {
        Assert-True (Test-Path -LiteralPath (Join-Path $c2 $rel) -PathType Leaf) "-Apply: $rel exists"
    }
    # THE BRANCH DOCUMENT IS NOT PLACED, and that is this adopter's half of the lifetime rule (Dave,
    # August 23, 2026). It used to be written here in its reset state, so a consumer's first look at the
    # folder was also their reference. The document exists only while a branch is open now, so placing one
    # would hand them a file their own first fold deletes -- the only entry in this list that is not
    # permanently theirs.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $c2 'contributing-davekjohn\development-cycle.md'))) '-Apply: the branch document is NOT placed -- it lives only while a branch is open'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $c2 'contributing-davekjohn\branch'))) '-Apply: and no branch/ directory is placed any more'
    # THE FOLDER PAGE MUST NOT CARRY A HISTORY TABLE, and this assert is the regression guard on inbound
    # #786. It did until August 20, 2026: the page was scaffolded with a '## Release history' heading, a
    # table, and a VUL-IN promising that the cut would insert its rows there -- while this same command's
    # closing advice told the reader to leave Get-ReleaseHistoryPath at the repo root. Two statements in
    # one run that cannot both be true, and the consumer who followed the advice got a table that stays
    # empty forever. The page now points at the seam's answer instead.
    $relText = [System.IO.File]::ReadAllText((Join-Path $c2 'contributing-davekjohn\releases\README.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($relText -notmatch '\| Version \| Date \| Type \| Title \|') '-Apply: the folder page carries NO history table (the list is not here)'
    Assert-Match 'releases/README\.md' $relText '-Apply: it names where the list actually lives instead'
    # And the closing block names the two seams only this repo can answer.
    Assert-Match 'Get-ReleaseNoteRoot' $r2.Out '-Apply: the next-steps block names Get-ReleaseNoteRoot'
    Assert-Match 'Get-ReleaseHistoryPath' $r2.Out '-Apply: and Get-ReleaseHistoryPath'

    # --- 3. Additive: a re-run never overwrites what somebody wrote --------------------------------
    Write-Host "adopt-workflow-folder -- re-run keeps every existing file" -ForegroundColor Cyan
    $marker = '# HAND-EDITED -- the scaffold must never win over this line'
    [System.IO.File]::WriteAllText((Join-Path $c2 'contributing-davekjohn\CONTRIBUTING.md'), $marker)
    $r3 = Invoke-Adopt -Dir $c2 -ScriptArgs @('-Apply')
    Assert-Equal 0 $r3.Code 're-run: exit 0'
    Assert-Match '\[exists\]\s+contributing-davekjohn/CONTRIBUTING\.md' $r3.Out 're-run: the edited file is reported as left alone'
    $kept = [System.IO.File]::ReadAllText((Join-Path $c2 'contributing-davekjohn\CONTRIBUTING.md'), [System.Text.Encoding]::UTF8)
    Assert-Equal $marker $kept 're-run: the hand-edited content survives byte for byte'

    # --- 4. A plugin-publishing repo is refused ------------------------------------------------------
    Write-Host "adopt-workflow-folder -- refused in a repo that publishes plugins" -ForegroundColor Cyan
    $c4 = New-FixtureConsumer -Label 'source' -AsPluginSource
    $r4 = Invoke-Adopt -Dir $c4 -ScriptArgs @('-Apply')
    Assert-Equal 1 $r4.Code 'plugin source: exit 1'
    Assert-Match 'REFUSED' $r4.Out 'plugin source: says it is refusing, and why'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $c4 'contributing-davekjohn'))) 'plugin source: nothing was written'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
