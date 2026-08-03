<#
.SYNOPSIS
    Builds the agent defs: fills every shared-block region (<!-- BEGIN/END shared:NAME -->) with
    the canonical source from plugins/agent-shared/<name>.md.
.DESCRIPTION
    Verbatim-shared bullets under **Boundaries** (e.g. the inbound rule, 19/19) are maintained in
    ONE place (agent-shared/) and filled in here across all agent defs. If you change a shared
    block, run this script: every agent def carrying that block gets updated. The content stays
    literally in the agent def (always-loaded, self-contained); this script keeps it in sync.

    Runs over all <plugin>/agents/*-agent.md in every plugin. Writes BOM-less, LF, only when
    something changes.

    -Check: writes nothing; reports drift (a block that deviates from its source) or a structural
    problem (BEGIN without END, unknown block) and ends with exit code 1. This is the mode
    check-plugin-integrity.ps1 and CI use as a gate.

    Pure ASCII (repo convention for .ps1).
.EXAMPLE
    ./scripts/agents/build-agent-defs.ps1
.EXAMPLE
    ./scripts/agents/build-agent-defs.ps1 -Check
#>
param([switch]$Check)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot '..\lib\agent-shared-lib.ps1')
$SharedDir = Get-AgentSharedDir -RepoRoot $RepoRoot
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path -LiteralPath $SharedDir -PathType Container)) {
    Write-Host "Source folder agent-shared/ is missing ($SharedDir) -- stopping." -ForegroundColor Red
    exit 1
}

Write-Host "== build-agent-defs$(if ($Check) {' -Check'}) -- $RepoRoot ==" -ForegroundColor Cyan

$agentFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-agent.md' -File |
    Where-Object { $_.FullName -match '\\agents\\' } | Sort-Object FullName

$changed = 0
$problemCount = 0
foreach ($f in $agentFiles) {
    $raw = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $rel = $f.FullName.Replace($RepoRoot, '.')
    $problems = New-Object System.Collections.Generic.List[string]
    $expanded = Expand-AgentDefShared -Content $raw -SharedDir $SharedDir -Problems $problems
    foreach ($p in $problems) {
        Write-Host "  [problem]    ${rel}: $p" -ForegroundColor Red
        $problemCount++
    }
    $current = ($raw -replace "`r`n", "`n")
    if ($expanded -ne $current) {
        $changed++
        if ($Check) {
            Write-Host "  [drift]      $rel -- shared block deviates from the source (run build-agent-defs.ps1)" -ForegroundColor Red
        } else {
            [System.IO.File]::WriteAllText($f.FullName, $expanded, $Utf8NoBom)
            Write-Host "  [updated]    $rel" -ForegroundColor Green
        }
    }
}

Write-Host ""
if ($Check) {
    if ($changed -gt 0 -or $problemCount -gt 0) {
        Write-Host "Summary: $changed drift, $problemCount problem -- NOT in sync." -ForegroundColor Red
        exit 1
    }
    Write-Host "Summary: all shared blocks in sync with the source." -ForegroundColor Green
    exit 0
}
if ($problemCount -gt 0) {
    Write-Host "Summary: $changed updated, $problemCount problem (fix that first)." -ForegroundColor Yellow
    exit 1
}
Write-Host "Summary: $changed agent def(s) updated, the rest already in sync." -ForegroundColor Cyan
exit 0
