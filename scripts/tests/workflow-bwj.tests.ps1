<#
.SYNOPSIS
    Regression tests for the workflow-bwj plugin: its structure, its marketplace registration, and
    the pure helpers of the asana-mirror CI script it ships as a template.

.DESCRIPTION
    Dependency-free: no Pester, only PowerShell. Exit 0 if everything passes, 1 on a failure.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/workflow-bwj.tests.ps1

    The asana-mirror helpers are exercised by dot-sourcing the template: it runs its main flow only
    when invoked directly, so a dot-source loads the functions and does nothing else.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'
$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$PluginRoot = Join-Path $RepoRoot 'plugins\workflows\workflow-bwj'

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

function Assert-Throws {
    param([scriptblock]$Block, [string]$Name)
    try { & $Block; $script:fail++; Write-Host "  [FAIL] $Name (no exception)" -ForegroundColor Red }
    catch { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
}

# --- 1. Plugin structure -------------------------------------------------------------------------
Write-Host "`n-- structure --" -ForegroundColor Cyan

$manifestPath = Join-Path $PluginRoot '.claude-plugin\plugin.json'
Assert-True (Test-Path -LiteralPath $manifestPath) 'plugin.json is present'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
Assert-Equal 'workflow-bwj' $manifest.name 'plugin.json name is workflow-bwj'

foreach ($rel in @('README.md', 'WORKFLOW-portable.md',
                   'skills\report-issue\SKILL.md', 'skills\adopt-bwj-asana\SKILL.md',
                   'templates\asana-mirror.yml', 'templates\asana-mirror.ps1')) {
    Assert-True (Test-Path -LiteralPath (Join-Path $PluginRoot $rel)) "ships $rel"
}

Assert-True (-not (Test-Path -LiteralPath (Join-Path $PluginRoot 'agents'))) 'carries no agents/ (workflow rule)'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $PluginRoot 'manuals'))) 'carries no manuals/ (workflow rule)'

# skill folder name matches its frontmatter name:
foreach ($skill in @('report-issue', 'adopt-bwj-asana')) {
    $txt = Get-Content -LiteralPath (Join-Path $PluginRoot "skills\$skill\SKILL.md") -Raw
    $nm  = [regex]::Match($txt, '(?m)^name:\s*(\S+)\s*$')
    Assert-Equal $skill $nm.Groups[1].Value "skill '$skill' frontmatter name matches its folder"
}

# --- 2. Marketplace registration + lockstep version --------------------------------------------
Write-Host "`n-- marketplace --" -ForegroundColor Cyan

$marketplace = Get-Content -LiteralPath (Join-Path $RepoRoot '.claude-plugin\marketplace.json') -Raw | ConvertFrom-Json
$entry = $marketplace.plugins | Where-Object { $_.name -eq 'workflow-bwj' }
Assert-True ($null -ne $entry) 'workflow-bwj is listed in marketplace.json'
Assert-Equal './plugins/workflows/workflow-bwj' $entry.source 'marketplace source points at the plugin folder'

$alphaManifest = Get-Content -LiteralPath (Join-Path $RepoRoot 'plugins\teams\team-alpha\.claude-plugin\plugin.json') -Raw | ConvertFrom-Json
Assert-Equal $alphaManifest.version $manifest.version 'version is in lockstep with team-alpha'

# --- 3. asana-mirror pure helpers ------------------------------------------------------------------
Write-Host "`n-- asana-mirror helpers --" -ForegroundColor Cyan

. (Join-Path $PluginRoot 'templates\asana-mirror.ps1')

# GID extraction
Assert-Equal '1201234567890123' (Get-AsanaTaskGid -IssueBody "text`n<!-- asana-task: 1201234567890123 -->`nmore") 'Get-AsanaTaskGid reads the marker'
Assert-Equal '1201234567890123' (Get-AsanaTaskGid -IssueBody '<!--asana-task:1201234567890123-->') 'Get-AsanaTaskGid tolerates no inner spaces'
Assert-True  ($null -eq (Get-AsanaTaskGid -IssueBody 'no marker here')) 'Get-AsanaTaskGid returns null when absent'
Assert-True  ($null -eq (Get-AsanaTaskGid -IssueBody '<!-- asana-task: not-a-number -->')) 'Get-AsanaTaskGid rejects a non-numeric marker'
Assert-True  ($null -eq (Get-AsanaTaskGid -IssueBody '')) 'Get-AsanaTaskGid handles an empty body'

# request building -- closed vs reopened
$put = New-AsanaCompleteRequest -Gid '123' -Completed $true
Assert-Equal 'PUT' $put.Method 'complete request is a PUT'
Assert-Equal 'https://app.asana.com/api/1.0/tasks/123' $put.Uri 'complete request URI carries the GID'
Assert-True  ($put.Body -match '"completed":true') 'closed -> completed:true'
$reopen = New-AsanaCompleteRequest -Gid '123' -Completed $false
Assert-True  ($reopen.Body -match '"completed":false') 'reopened -> completed:false'

# a non-numeric GID never reaches a request
Assert-Throws { New-AsanaCompleteRequest -Gid '123; rm -rf /' -Completed $true } 'New-AsanaCompleteRequest throws on a non-numeric GID'
Assert-Throws { New-AsanaCommentRequest  -Gid 'abc' -Text 'x' }                 'New-AsanaCommentRequest throws on a non-numeric GID'

# comment request
$c = New-AsanaCommentRequest -Gid '123' -Text 'Resolved via GitHub owner/repo#7'
Assert-Equal 'POST' $c.Method 'comment request is a POST'
Assert-True  ($c.Uri.EndsWith('/tasks/123/stories')) 'comment request posts to the stories endpoint'

# issue-ref parsing for the reconciliation sweep
Assert-Equal 'BWJ-ecommerce/smartwatchbanden#42' (Get-IssueRefFromNotes -Notes 'see https://github.com/BWJ-ecommerce/smartwatchbanden/issues/42 for detail') 'Get-IssueRefFromNotes pulls owner/repo#n from a GitHub URL'
Assert-True  ($null -eq (Get-IssueRefFromNotes -Notes 'no link at all')) 'Get-IssueRefFromNotes returns null without a GitHub issue URL'

# --- done ---------------------------------------------------------------------------------------
Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
