<#
.SYNOPSIS
    Tests for plugins/dkj-policy/hooks/cycle-autopark.ps1 -- the Stop hook that runs park-cycle.ps1
    after every turn, and what it does with the two streams that come back.

.DESCRIPTION
    WHY THIS SUITE EXISTS (issue #1600, September 8, 2026). The hook had no coverage at all, on the
    reasonable ground that it is deliberately thin -- every bound, refusal and measurement lives in
    park-cycle.ps1, which park-cycle.tests.ps1 exercises in full. What that left untested was the one
    thing the hook does own: WHICH STREAMS OF THE CHILD REACH THE SESSION. It captured stdout only,
    and the single most urgent line park-cycle can produce -- the sentence naming a second session on
    the same branch, written through Write-Error by Invoke-GitPark -- is on stderr. So the one turn
    where this hook had something urgent to say was the turn whose most useful line it dropped.

    Measured on feat/plugin-version-overview: two sessions ran the same pre-PR review in full from one
    handoff note, each finding real defects the other missed, and the collision was not learned until
    open-pr refused the push roughly half an hour later.

    THE FIXTURES DO NOT USE park-cycle AT ALL, deliberately. -ScriptOverride lets the hook run a stub
    that writes exactly what each case is about, so what is pinned here is the hook's own contract --
    both streams captured, a merged ErrorRecord stringified rather than printed as an object, exit 0
    whatever the child did -- with no git, no origin and no gh anywhere near it. park-cycle's own
    behaviour is park-cycle.tests.ps1's subject, and duplicating it here would be a second answer to a
    question that already has one.

    THE STUB MUST ACCEPT -Quiet AND -RepoRoot, because the hook passes them. A stub that did not would
    fail on parameter binding and every assert below would go green for the wrong reason -- so case (a)
    asserts a stdout line arrives, which is what proves the stub ran at all.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Continue'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Hook     = Join-Path $RepoRoot 'plugins\dkj-policy\hooks\cycle-autopark.ps1'
# $PID in the fixture path: the gate is a throttled PARALLEL scheduler, so two runs at one fixed temp
# path tear down each other's tree mid-assert. Same reasoning as the sibling hook suites.
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) "cycle-autopark-tests-$PID"

$Ascii = New-Object System.Text.ASCIIEncoding
$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else            { $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red }
}

function Assert-Says {
    param([string]$Text, [string]$Phrase, [string]$Name)
    # ALL whitespace stripped, not collapsed -- the same treatment park-cycle.tests.ps1 applies (#1512),
    # and the stronger form is needed here rather than merely tidier. The child is its own powershell
    # process: it renders and WRAPS at its buffer width before we ever see the text, and a wrap lands
    # mid-word ('...THIS BR' / 'ANCH'), which collapsing runs of whitespace to one space does not repair.
    $flat = ($Text -replace '\s', '')
    if ($flat.Contains(($Phrase -replace '\s', ''))) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         wanted: '$Phrase'`n         in:     '$flat'" -ForegroundColor Red
    }
}

function New-Stub {
    <#
        A stand-in for park-cycle.ps1 that writes what the case is about and exits with $ExitCode. It
        takes the two parameters the hook passes, so a binding failure cannot be mistaken for silence.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [string]$StdOut = '',
        [string]$StdErr = '',
        [int]$ExitCode = 0
    )
    $path = Join-Path $Fixture "stub-$Label.ps1"
    $body = @"
param([switch]`$Quiet, [string]`$RepoRoot = '')
`$ErrorActionPreference = 'Continue'
if ('$StdOut') { Write-Host '$StdOut' }
if ('$StdErr') { Write-Error '$StdErr' -ErrorAction Continue }
exit $ExitCode
"@
    [System.IO.File]::WriteAllText($path, $body, $Ascii)
    return $path
}

function Invoke-Hook {
    <# Runs the hook as a child, capturing stdout only -- which is what a Stop hook's own report is. #>
    param([string]$ScriptOverride = '')
    $callArgs = @()
    if ($ScriptOverride) { $callArgs += @('-ScriptOverride', $ScriptOverride) }
    $prevPlugin = $env:CLAUDE_PLUGIN_ROOT
    try {
        # Cleared so a case that passes NO override really meets "no script found" rather than this
        # machine's installed plugin cache.
        Remove-Item Env:\CLAUDE_PLUGIN_ROOT -ErrorAction SilentlyContinue
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Hook @callArgs
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = (($out | Out-String)) }
    } finally {
        if ($null -eq $prevPlugin) { Remove-Item Env:\CLAUDE_PLUGIN_ROOT -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PLUGIN_ROOT = $prevPlugin }
    }
}

Write-Host "== cycle-autopark.ps1 ==" -ForegroundColor Cyan
Assert-True (Test-Path -LiteralPath $Hook -PathType Leaf) 'the hook exists at its registered path'
if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
New-Item -ItemType Directory -Force -Path $Fixture | Out-Null

try {
    # --- (a) STDOUT IS RELAYED -- the pre-existing contract, and the proof the stub ran -------------
    Write-Host "cycle-autopark.ps1 -- a child's stdout reaches the session" -ForegroundColor Cyan
    $rA = Invoke-Hook -ScriptOverride (New-Stub -Label 'a' -StdOut 'park-cycle: pushed one document')
    Assert-True ($rA.Code -eq 0) 'stdout: exit 0'
    Assert-Says $rA.Out 'park-cycle: pushed one document' 'stdout: the line is relayed'

    # --- (b) STDERR IS RELAYED TOO -- the #1600 repair ---------------------------------------------
    # THE DEFECT: `$out = @(& powershell ...)` captures stdout alone, so Invoke-GitPark's push-failure
    # sentence -- the one naming another session on the branch -- never reached the hook's report.
    Write-Host "cycle-autopark.ps1 -- a child's stderr reaches it as well (#1600)" -ForegroundColor Cyan
    $rB = Invoke-Hook -ScriptOverride (New-Stub -Label 'b' -StdErr 'origin already has commits this branch does not')
    Assert-True ($rB.Code -eq 0) 'stderr: exit 0 -- the hook never fails a turn'
    Assert-Says $rB.Out 'origin already has commits this branch does not' 'stderr: the sentence is relayed, not dropped'

    # --- (c) THE WORDS SURVIVE THE TRIP, banner and console wrap included -------------------------
    # 2>&1 in Windows PowerShell 5.1 hands the merged stderr over as ErrorRecords rather than strings,
    # so the ToString() in the hook is load-bearing -- a bare Write-Host of a record prints its own
    # formatting instead of the text. What arrives is still the CHILD's rendering of its own error: a
    # 'stub-c.ps1 :' prefix, the message, and two trailing CategoryInfo/FullyQualifiedErrorId lines,
    # wrapped at that process's buffer width. That is acceptable for a safety net -- park-cycle passes
    # -NoFailureMessage now, so the sentence that matters arrives on stdout in its own voice -- and what
    # is pinned here is only that a line written to stderr is not LOST. The assert strips whitespace
    # entirely for the wrap; see Assert-Says.
    Write-Host "cycle-autopark.ps1 -- a line written to stderr is not lost" -ForegroundColor Cyan
    $rC = Invoke-Hook -ScriptOverride (New-Stub -Label 'c' -StdErr 'ANOTHER SESSION OR DEVICE IS WORKING THIS BRANCH')
    Assert-Says $rC.Out 'ANOTHER SESSION OR DEVICE IS WORKING THIS BRANCH' "stderr: the words survive the child's own rendering and wrap"

    # --- (d) BOTH STREAMS AT ONCE, and a non-zero child ------------------------------------------
    # The real shape of a refused push: git's plumbing on stdout, the interpretation on stderr. Neither
    # may cost the other, and the child's exit code may not reach the session -- a Stop hook that fails
    # interrupts the work it was added to protect.
    Write-Host "cycle-autopark.ps1 -- both streams survive, and a failing child still exits 0" -ForegroundColor Cyan
    $rD = Invoke-Hook -ScriptOverride (New-Stub -Label 'd' -StdOut '! [rejected] feat/x -> feat/x (fetch first)' -StdErr 'park: git push was rejected' -ExitCode 1)
    Assert-True ($rD.Code -eq 0) 'both streams: the hook exits 0 even though the child exited 1'
    Assert-Says $rD.Out '! [rejected] feat/x -> feat/x (fetch first)' 'both streams: git plumbing is there'
    Assert-Says $rD.Out 'park: git push was rejected' 'both streams: and the interpretation beside it'

    # --- (e) NO SCRIPT TO RUN -> silent, and still exit 0 ----------------------------------------
    # The existing bound, pinned so the stderr merge cannot turn a half-installed plugin into a line per
    # turn. Unlike the session checks, this one says nothing: it runs on EVERY turn.
    Write-Host "cycle-autopark.ps1 -- no park-cycle to run: silent, exit 0" -ForegroundColor Cyan
    $rE = Invoke-Hook
    Assert-True ($rE.Code -eq 0) 'no script: exit 0'
    Assert-True ([string]::IsNullOrWhiteSpace($rE.Out)) 'no script: and not one line printed'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
