<#
.SYNOPSIS
    Regression tests for scripts/lib/source-repo-guard-lib.ps1 -- the guard that refuses a shared script
    running from a released copy inside the repo that maintains it.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/source-repo-guard.tests.ps1

    TWO LAYERS, DELIBERATELY. Get-OwnCopyPath is exercised directly against synthetic trees, because the
    decision it makes has more branches than a child process can cheaply cover -- and one integration case
    runs a REAL entry point from a copy outside a real repo, because the thing that has to hold is that the
    script actually stops, with a non-zero exit code, and says which path to run instead.

    THE ALLOW CASES CARRY THE RISK, NOT THE REFUSAL. A guard that refuses too much breaks every consumer,
    which is worse than the defect it repairs -- so a consumer with no marketplace, a consumer carrying a
    same-named script of their own, and the source repo's own in-repo mirror each get a case saying the
    guard stays out of it.

    Fixture paths carry $PID (repo convention): the test gate is a throttled parallel scheduler, so two
    runs overlapping is ordinary, and two runs sharing one fixed temp path tear down each other's tree
    mid-assert.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$GuardLib = Join-Path $RepoRoot 'scripts\lib\source-repo-guard-lib.ps1'

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message" -ForegroundColor Red }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -eq $Actual) { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message -- expected '$Expected', got '$Actual'" -ForegroundColor Red }
}

function New-Tree {
    <#
        A synthetic repo root. -Publishes writes .claude-plugin/marketplace.json, which is the condition
        that separates a repo that MAINTAINS shared scripts from a consumer that merely runs them.
        -Local writes the repo's own copy at scripts/<Relative>.
    #>
    param(
        [Parameter(Mandatory)][string]$Label,
        [switch]$Publishes,
        [switch]$Local,
        [string]$Relative = 'task\session-status.ps1'
    )
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("srguard-$PID-$Label-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    if ($Publishes) {
        New-Item -ItemType Directory -Path (Join-Path $dir '.claude-plugin') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $dir '.claude-plugin\marketplace.json') -Value '{}' -Encoding UTF8
    }
    if ($Local) {
        $p = Join-Path (Join-Path $dir 'scripts') $Relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $p) -Force | Out-Null
        Set-Content -LiteralPath $p -Value '# local copy' -Encoding UTF8
    }
    return $dir
}

$fixtures = @()
try {
    . $GuardLib

    Write-Host 'A foreign copy IS refused when the repo maintains the same script' -ForegroundColor Cyan
    # The measured case: a released mirror run inside the repo it was mirrored from.
    $src = New-Tree -Label 'src' -Publishes -Local; $fixtures += $src
    $cache = New-Tree -Label 'cache'; $fixtures += $cache
    $foreign = Join-Path $cache 'scripts\task\session-status.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $foreign) -Force | Out-Null
    Set-Content -LiteralPath $foreign -Value '# released copy' -Encoding UTF8
    $own = Get-OwnCopyPath -ScriptPath $foreign -RepoRoot $src
    Assert-Equal 'scripts\task\session-status.ps1' $own 'the local path to run instead is returned, repo-relative'

    Write-Host "The repo's own copy is NOT refused" -ForegroundColor Cyan
    $inside = Join-Path $src 'scripts\task\session-status.ps1'
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $inside -RepoRoot $src) 'running the source itself is fine'

    Write-Host 'The in-repo plugin mirror is NOT refused' -ForegroundColor Cyan
    # Lint check 8 holds this byte-identical to the source, so running it is not the staleness the guard is
    # about. Refusing it would also make the drift lint's own fixtures unrunnable.
    $mirror = Join-Path $src 'plugins\workflows\workflow-davekjohn\scripts\task\session-status.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $mirror) -Force | Out-Null
    Set-Content -LiteralPath $mirror -Value '# in-repo mirror' -Encoding UTF8
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $mirror -RepoRoot $src) 'the mirror inside the repo is allowed'

    Write-Host 'A consumer is NEVER refused -- the two ways that must both hold' -ForegroundColor Cyan
    # 1. No marketplace: the ordinary consumer. This is the condition doing the real work.
    $plainConsumer = New-Tree -Label 'consumer' -Local; $fixtures += $plainConsumer
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $foreign -RepoRoot $plainConsumer) `
        'a repo that publishes no plugins is left alone even though it has a same-named script'
    # 2. Publishes, but has no copy of THIS script -- a repo publishing some other plugin entirely.
    $otherPublisher = New-Tree -Label 'other' -Publishes; $fixtures += $otherPublisher
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $foreign -RepoRoot $otherPublisher) `
        'a publishing repo without its own copy of this script is left alone'

    Write-Host 'A sibling directory whose name merely starts with the root name is still foreign' -ForegroundColor Cyan
    # '...\srguard-x-src-abc' vs '...\srguard-x-src-abc-two': a prefix compare without the separator reads
    # the second as being inside the first, and the guard would then wave through a genuinely foreign copy.
    $sibling = $src + '-two'
    $siblingScript = Join-Path $sibling 'scripts\task\session-status.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $siblingScript) -Force | Out-Null
    Set-Content -LiteralPath $siblingScript -Value '# next door' -Encoding UTF8
    $fixtures += $sibling
    Assert-Equal 'scripts\task\session-status.ps1' (Get-OwnCopyPath -ScriptPath $siblingScript -RepoRoot $src) `
        'a path that shares the root as a string PREFIX is not treated as being inside it'

    Write-Host 'The relative path comes from the INNERMOST scripts segment' -ForegroundColor Cyan
    # A mirror path carries two ('...\plugins\...\scripts\task\x.ps1'), and taking the first would compose
    # a nonsense local path like scripts\workflows\workflow-davekjohn\scripts\task\x.ps1.
    $deep = New-Tree -Label 'deep'; $fixtures += $deep
    $deepScript = Join-Path $deep 'scripts\plugins\workflows\wf\scripts\task\session-status.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $deepScript) -Force | Out-Null
    Set-Content -LiteralPath $deepScript -Value '# doubly nested' -Encoding UTF8
    Assert-Equal 'scripts\task\session-status.ps1' (Get-OwnCopyPath -ScriptPath $deepScript -RepoRoot $src) `
        'two scripts segments: the last one wins'

    Write-Host 'A script that lives under no scripts/ directory at all is not judged' -ForegroundColor Cyan
    $loose = Join-Path $cache 'somewhere\else.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $loose) -Force | Out-Null
    Set-Content -LiteralPath $loose -Value '# loose' -Encoding UTF8
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $loose -RepoRoot $src) 'no scripts segment, no verdict'

    Write-Host 'An unresolvable repo root switches the guard OFF rather than refusing' -ForegroundColor Cyan
    # A guard that cannot tell which repo it is in must not refuse anything: that would break a script run
    # outside any repo, which is a legitimate thing to do with fix-mojibake -Path.
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $foreign -RepoRoot (Join-Path $cache 'no-such-tree')) `
        'a root that does not exist yields no finding'

    Write-Host 'INTEGRATION: a real entry point stops, with exit 1, naming the local path' -ForegroundColor Cyan
    # The asserts above prove the decision; this proves the CONSEQUENCE. Without it, a lib returning the
    # right answer to nobody would pass the suite.
    $realRepo = $RepoRoot
    $awayDir = Join-Path ([System.IO.Path]::GetTempPath()) ("srguard-$PID-away-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    $fixtures += $awayDir
    New-Item -ItemType Directory -Path (Join-Path $awayDir 'scripts\task') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $awayDir 'scripts\lib') -Force | Out-Null
    Copy-Item (Join-Path $realRepo 'scripts\task\session-status.ps1') (Join-Path $awayDir 'scripts\task\session-status.ps1')
    Copy-Item $GuardLib (Join-Path $awayDir 'scripts\lib\source-repo-guard-lib.ps1')
    $prev = $env:CLAUDE_PROJECT_DIR
    try {
        $env:CLAUDE_PROJECT_DIR = $realRepo
        $out = (& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $awayDir 'scripts\task\session-status.ps1') 2>&1) | Out-String
        $code = $LASTEXITCODE
    } finally {
        if ($null -eq $prev) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prev }
    }
    Assert-Equal 1 $code 'the run exits 1 rather than reporting'
    # -cmatch, case-sensitively: this script PRINTS the lock file, whose prose is full of the word
    # 'refuses', and a case-insensitive match on 'REFUSED' passed against a run that never fired.
    Assert-True ($out -cmatch 'REFUSED: this repo maintains') 'it says it refused, in its own words'
    Assert-True ($out -match 'run this: scripts.task.session-status\.ps1') 'and names the copy to run instead'
    Assert-True (-not ($out -match 'What the last release left open')) 'and it stopped BEFORE doing any of its work'
}
finally {
    foreach ($d in $fixtures) {
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
