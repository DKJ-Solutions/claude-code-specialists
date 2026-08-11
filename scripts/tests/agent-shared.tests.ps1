<#
.SYNOPSIS
    Regression tests for the shared agent-def blocks: the lib (agent-shared-lib.ps1), the generator
    (build-agent-defs.ps1) and the drift gate in check-plugin-integrity.ps1.

.DESCRIPTION
    Dependency-free: no Pester, only PowerShell. The unit tests dot-source the lib and run
    Expand-AgentDefShared against in-memory fixtures; the smoke tests run the real scripts as a
    CHILD PROCESS (powershell -File) because they call 'exit' themselves.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/agent-shared.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot  = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Lib       = Join-Path $RepoRoot 'scripts\lib\agent-shared-lib.ps1'
$Build     = Join-Path $RepoRoot 'scripts\agents\build-agent-defs.ps1'
$Integrity = Join-Path $RepoRoot 'scripts\lint\check-plugin-integrity.ps1'
$Fixture   = Join-Path ([System.IO.Path]::GetTempPath()) "agent-shared-test-fixture-$PID"

. $Lib

$script:pass = 0
$script:fail = 0
function Assert-Equal { param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}
function Assert-True { param([bool]$Condition, [string]$Name)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red }
}
function Invoke-Script { param([string]$Path, [string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}
function New-Problems { New-Object System.Collections.Generic.List[string] }

try {
    # --- Fixture source: a shared block 'greeting' ---------------------------------------------------
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null
    $blockText = "- hello world`n- second line"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'greeting.md'), "$blockText`n", (New-Object System.Text.UTF8Encoding($false)))

    $begin = '<!-- BEGIN shared:greeting -- GENERATED, edit agent-shared/greeting.md -->'
    $end   = '<!-- END shared:greeting -->'
    $inSync = "before`n$begin`n$blockText`n$end`nafter"

    # --- 1. In-sync content stays the same; no problems ---------------------------------------------
    Write-Host "Expand-AgentDefShared -- in sync" -ForegroundColor Cyan
    $p1 = New-Problems
    $o1 = Expand-AgentDefShared -Content $inSync -SharedDir $Fixture -Problems $p1
    Assert-Equal $inSync $o1 'in-sync content stays byte-equal'
    Assert-Equal 0 $p1.Count 'no problems on in-sync content'

    # --- 2. Drift is detected and restored from the source ----------------------------------------
    Write-Host "Expand-AgentDefShared -- drift" -ForegroundColor Cyan
    $stale = "before`n$begin`n- MANUALLY CHANGED`n$end`nafter"
    $p2 = New-Problems
    $o2 = Expand-AgentDefShared -Content $stale -SharedDir $Fixture -Problems $p2
    Assert-True ($o2 -ne $stale) 'drift detected (expand deviates from the input)'
    Assert-Equal $inSync $o2 'expand restores the region from the canonical source'

    # --- 3. BEGIN without END is reported ------------------------------------------------------------
    Write-Host "Expand-AgentDefShared -- BEGIN without END" -ForegroundColor Cyan
    $noEnd = "before`n$begin`n- something"
    $p3 = New-Problems
    $null = Expand-AgentDefShared -Content $noEnd -SharedDir $Fixture -Problems $p3
    Assert-True ($p3.Count -ge 1) 'BEGIN without END is reported as a problem'

    # --- 4. Unknown block (missing source) is reported ----------------------------------------------
    Write-Host "Expand-AgentDefShared -- unknown block" -ForegroundColor Cyan
    $unknown = "before`n<!-- BEGIN shared:doesnotexist -->`n- x`n<!-- END shared:doesnotexist -->`nafter"
    $p4 = New-Problems
    $null = Expand-AgentDefShared -Content $unknown -SharedDir $Fixture -Problems $p4
    Assert-True ($p4.Count -ge 1) 'unknown block (missing source) is reported'

    # --- 5. Multiple blocks in ONE agent-def all get filled -------------------------------------
    Write-Host "Expand-AgentDefShared -- multiple blocks" -ForegroundColor Cyan
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'second.md'), "- block two`n", (New-Object System.Text.UTF8Encoding($false)))
    $b2 = '<!-- BEGIN shared:second -->'; $e2 = '<!-- END shared:second -->'
    $multiStale = "top`n$begin`n- old`n$end`nmiddle`n$b2`n- old2`n$e2`nbottom"
    $p5 = New-Problems
    $o5 = Expand-AgentDefShared -Content $multiStale -SharedDir $Fixture -Problems $p5
    Assert-True ($o5 -match 'hello world' -and $o5 -match 'block two') 'both blocks filled from their source'
    Assert-True (-not ($o5 -match 'old2')) 'stale content of the second block replaced'

    # --- 6. Smoke: the real repo is in sync ----------------------------------------------------------
    Write-Host "build-agent-defs.ps1 -Check + check-plugin-integrity.ps1 -- repo in sync" -ForegroundColor Cyan
    $rb = Invoke-Script -Path $Build -ScriptArgs @('-Check')
    Assert-Equal 0 $rb.Code 'build -Check: all shared blocks in sync on the repo'
    $ri = Invoke-Script -Path $Integrity -ScriptArgs @()
    Assert-Equal 0 $ri.Code 'lint gate green on the repo (incl. shared check)'

    # --- 7. THE GENERATOR AND THE GATE WALK THE PERSONAS TOO ----------------------------------------
    # The widening of August 8, 2026. Both halves are tested, because a generator that writes a file the
    # gate does not read is the exact shape in which a shared block goes quietly stale: the build keeps
    # reporting "in sync" and the gate keeps reporting green, while nothing has compared that file with
    # its source since the day it was placed.
    Write-Host "the personas are in scope, not just the agent defs" -ForegroundColor Cyan
    $realAgents = @(Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-agent.md' -File |
        Where-Object { $_.FullName -match '\\agents\\' })
    $realPersonas = @(Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-persona.md' -File |
        Where-Object { $_.FullName -match '\\personas\\' })
    Assert-True ($realPersonas.Count -gt 0) 'there are personas to cover in the first place'

    # The gate's own coverage line is the measurement: it states what it walked, so a gate that quietly
    # narrowed back to agents/ fails here instead of staying green on a smaller surface.
    $sharedCoverage = ($ri.Out -split "`n" | Where-Object { $_ -match '\[shared\]\s+checked\s+(\d+)' } | Select-Object -First 1)
    Assert-True ($sharedCoverage -match '\[shared\]\s+checked\s+(\d+)') 'the lint reports a [shared] coverage count'
    $sharedCount = if ($sharedCoverage -match '\[shared\]\s+checked\s+(\d+)') { [int]$Matches[1] } else { -1 }
    Assert-Equal ($realAgents.Count + $realPersonas.Count) $sharedCount 'the gate walks every agent def AND every persona'
    Assert-True ($sharedCount -gt $realAgents.Count) 'and that is strictly more than the agent defs alone -- the widening really happened'

    # The generator's scope. A source assertion rather than a drift run, deliberately: build-agent-defs
    # resolves its own repo root and cannot be pointed at a fixture, so drifting a real persona to prove
    # the point would mean editing a shipped file inside a test.
    $buildSrc = [System.IO.File]::ReadAllText($Build, [System.Text.Encoding]::UTF8)
    Assert-True ($buildSrc -match "'\*-persona\.md'") 'the generator collects *-persona.md'
    Assert-True ($buildSrc -match "personas") 'and filters on the personas directory'

    # --- 8. Every specialist actually carries the way-of-working block ------------------------------
    # A block whose whole purpose is "adapt to the repo you are installed in" is worth nothing in the
    # files it was never placed in, and placement is a one-off editorial act that no gate re-runs.
    Write-Host "repo-way-of-working reaches every specialist" -ForegroundColor Cyan
    $missing = @()
    foreach ($f in ($realAgents + $realPersonas)) {
        $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        if ($text -notmatch 'BEGIN shared:repo-way-of-working') { $missing += $f.Name }
    }
    Assert-Equal '' ($missing -join ', ') 'no agent def or persona is missing the block'
    $srcBlock = Join-Path $RepoRoot 'plugins\agent-shared\repo-way-of-working.md'
    Assert-True (Test-Path -LiteralPath $srcBlock) 'the canonical source file exists'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
