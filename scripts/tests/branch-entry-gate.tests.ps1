<#
.SYNOPSIS
    Regression tests for scripts/lint/check-branch-entry.ps1 -- the CI gate that holds every branch to
    carrying a written changelog entry (inbound #789).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell and git.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/branch-entry-gate.tests.ps1

    THE ENTRY STATES COME FROM THE REAL FORMATTERS, NEVER FROM A LITERAL IN THIS FILE. Format-EntryBlock
    with empty fields IS the scaffolded state and Format-BranchChangelogReset IS the reset state, so a
    change to either shape reaches these cases automatically. A fixture written by hand would be a third
    definition of the format, in the file whose whole job is to prove there are not two -- and it would go
    stale exactly when the gate did, hiding the failure instead of catching it.

    THE CASE THAT CARRIES THE MOST WEIGHT IS THE ONE THAT PASSES. An entry whose significance is not
    settled must exit 0: Dave placed that refusal at the release cut (open-pr.ps1, August 5, 2026), and
    both hand-written consumer gates refuse a merge over it -- which is the drift this shipped gate exists
    to end. A test that only checked the refusals would let that come straight back.

    Fixture paths carry $PID (repo convention): the test gate is a throttled parallel scheduler, so two
    runs overlapping is ordinary, and two runs sharing one fixed temp path tear down each other's tree
    mid-assert.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\lint\check-branch-entry.ps1'
. (Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1')

$script:pass = 0
$script:fail = 0
$script:trees = @()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message" -ForegroundColor Red }
}

function New-Consumer {
    <# A fixture repo with the branch dossier in place. No git history is needed: the gate reads files
       and a branch NAME, which the caller passes. #>
    param([Parameter(Mandatory = $true)][string]$Label, [string]$RepoConfig = '')
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("entrygate-$PID-$Label-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    New-Item -ItemType Directory -Path (Join-Path $dir 'workflow-davekjohn\branch') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib') -Force | Out-Null
    $script:trees += $dir
    if ($RepoConfig) {
        Set-Content -LiteralPath (Join-Path $dir 'scripts\repo-config.ps1') -Value $RepoConfig -Encoding ascii
    }
    return $dir
}

function Set-Entry {
    # [AllowEmptyString()] is load-bearing and the lib says so about its own callers: most of a formatted
    # entry is blank lines, and a [string[]] without it rejects the whole call.
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Lines
    )
    $target = Join-Path $Dir 'workflow-davekjohn\branch\branch-deployment.md'
    [System.IO.File]::WriteAllText($target, (($Lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-Gate {
    param([Parameter(Mandatory = $true)][string]$Dir, [Parameter(Mandatory = $true)][string]$Branch)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -RootOverride $Dir -Branch $Branch 2>&1
    } finally { $ErrorActionPreference = $prevEap }
    return @{ Out = ($out | Out-String); Code = $LASTEXITCODE }
}

try {
    # --- The two exits that are not about the entry at all -------------------------------------------
    Write-Host 'the exemptions'

    $c = New-Consumer -Label 'exempt'
    Set-Entry -Dir $c -Lines (Format-BranchChangelogReset -Branch 'main')

    $r = Invoke-Gate -Dir $c -Branch 'sync/live-2026-08-20'
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'exempt prefix') 'exempt/default: a sync branch owes no entry, even with the entry in its reset state'

    $r = Invoke-Gate -Dir $c -Branch 'main'
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'trunk') 'trunk: judged as the trunk, where the reset state is the DESIGNED state'

    # An unknown prefix is deliberately NOT exempt: a typo in a prefix would otherwise skip the gate.
    $r = Invoke-Gate -Dir $c -Branch 'syncc/typo'
    Assert-True ($r.Code -eq 1) 'exempt/typo: a prefix that merely LOOKS exempt is not -- the gate still runs'

    # The seam narrows and widens it, and the source declares no exemption of its own.
    $c2 = New-Consumer -Label 'seam' -RepoConfig "function Get-EntryGateExemptPrefixes { return @('mirror','vendor') }"
    Set-Entry -Dir $c2 -Lines (Format-BranchChangelogReset -Branch 'main')
    $r = Invoke-Gate -Dir $c2 -Branch 'mirror/upstream'
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'exempt prefix') 'exempt/seam: the seam answer replaces the default'
    $r = Invoke-Gate -Dir $c2 -Branch 'sync/live-2026-08-20'
    Assert-True ($r.Code -eq 1) 'exempt/seam: and REPLACES it -- a repo that names its own list does not silently keep sync'

    # --- The refusals -------------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'the refusals'

    $missing = New-Consumer -Label 'missing'
    $r = Invoke-Gate -Dir $missing -Branch 'feat/thing'
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'does not exist') 'missing: no entry file at all refuses, and names new-branch'

    $reset = New-Consumer -Label 'reset'
    Set-Entry -Dir $reset -Lines (Format-BranchChangelogReset -Branch 'main')
    $r = Invoke-Gate -Dir $reset -Branch 'feat/thing'
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'reset state') 'reset: the state the fold leaves behind is not an entry'

    # THE CASE A HEADING TEST PASSES AND THIS ONE MUST NOT. A freshly scaffolded entry already carries
    # the H2 and the section headings, which is exactly why the hand-written gates reached for the score.
    $scaffolded = New-Consumer -Label 'scaffolded'
    Set-Entry -Dir $scaffolded -Lines (Format-EntryBlock -Branch 'feat/thing' -Description '' -Type 'Feat' -Body '')
    $r = Invoke-Gate -Dir $scaffolded -Branch 'feat/thing'
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'has not been written yet') 'scaffolded: created and never filled in refuses -- the case a heading test lets through'
    Assert-True ($r.Out -match '- ') 'scaffolded: and it NAMES the fields still waiting, rather than only saying no'

    # --- The pass, and the one that must not become a refusal ---------------------------------------
    Write-Host ''
    Write-Host 'what passes'

    $written = New-Consumer -Label 'written'
    Set-Entry -Dir $written -Lines (Format-EntryBlock -Branch 'feat/thing' -Type 'Feat' `
        -Description 'The thing now does the thing.' -Body 'The thing now does the thing.' `
        -ImpactRows @([pscustomobject]@{ Tier = 0; Score = 2; Why = 'Maintainers notice it.' }))
    $r = Invoke-Gate -Dir $written -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'written: a filled-in entry passes'
    Assert-True ($r.Out -match 'carries a written entry') 'written: and says which file it read'

    # AN EMPTY SCORE IS NOT AN UNSETTLED ONE, which is worth pinning because it is counter-intuitive and
    # it is what the hand-written gates got wrong. A tier section whose Score line is blank carries no
    # number, so the entry's REACH is tier 0 -- a complete, legitimate answer that owes nothing
    # (entry-scaffold-lib: "TIER 0 OWES NOTHING"). The gate must pass it in silence.
    $blank = New-Consumer -Label 'blank'
    Set-Entry -Dir $blank -Lines (Format-EntryBlock -Branch 'feat/thing' -Type 'Feat' `
        -Description 'The thing now does the thing.' -Body 'The thing now does the thing.' `
        -ImpactRows @([pscustomobject]@{ Tier = 2; Score = 0; Why = 'Subscribers notice it.' }))
    $r = Invoke-Gate -Dir $blank -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'blank score: reads as tier 0, which owes nothing -- passes'
    Assert-True ($r.Out -notmatch 'RELEASE CUT') 'blank score: and is not even reported, because nothing is unsettled'

    # THE LOAD-BEARING CASE. Scores genuinely unsettled -> still exit 0, with the cut named as where the
    # refusal lives. Both hand-written consumer gates fail this one, which is why it is here.
    # Tier 1 carries its REASON but no number. A reason left blank is a different case and belongs to the
    # scaffold gate above -- it is an unwritten field, and that one does refuse. This is the narrow state
    # where everything is written and only the ranking is still open.
    $unscored = New-Consumer -Label 'unscored'
    Set-Entry -Dir $unscored -Lines (Format-EntryBlock -Branch 'feat/thing' -Type 'Feat' `
        -Description 'The thing now does the thing.' -Body 'The thing now does the thing.' `
        -ImpactRows @(
            [pscustomobject]@{ Tier = 2; Score = 4; Why = 'Subscribers notice it.' },
            [pscustomobject]@{ Tier = 1; Score = 0; Why = 'Colleagues get something out of it.' }
        ))
    $r = Invoke-Gate -Dir $unscored -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'unscored: an unsettled significance does NOT block the merge -- that refusal is the cut''s'
    Assert-True ($r.Out -match 'RELEASE CUT will refuse') 'unscored: and the gate says where the refusal does live'
}
finally {
    foreach ($d in $script:trees) {
        if ($d -and (Test-Path -LiteralPath $d)) {
            Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILED: $($script:fail) of $($script:pass + $script:fail) asserts." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
