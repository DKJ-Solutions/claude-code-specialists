<#
.SYNOPSIS
    Tests for scripts/release/verify-resolved-issues.ps1 (the post-merge half of the resolves gate).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Exit code 0 if everything passes, 1 on a
    failure -- so usable as a CI gate.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/verify-resolved-issues.tests.ps1

    Why this suite exists: this is the one part of the ship chain that MUTATES state outside the repo
    -- it posts comments and CLOSES issues. Reviewing it was not enough; the failure mode (closing an
    issue that a PR never really declared) is invisible until it has already happened on a live
    tracker. So the script is driven end to end against a FAKE gh on PATH that records every call.

    The load-bearing scenario is the backtick one: a document explaining this gate necessarily writes
    `Closes #<n>` as prose, and the changelog entry for the gate does exactly that. GitHub does not
    link a reference inside a code span, so it closes nothing there -- and neither may this script,
    or it would force-close an unrelated issue while crediting the wrong PR.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (git rev-parse --show-toplevel).Trim()
$ScriptPath = Join-Path $RepoRoot 'scripts\release\verify-resolved-issues.ps1'

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

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
$fakeBin = Join-Path ([System.IO.Path]::GetTempPath()) ("verify-resolved-bin-$PID")
$callLog = Join-Path ([System.IO.Path]::GetTempPath()) ("verify-resolved-calls-$PID.log")
$prevPath = $env:PATH
$prevEap = $ErrorActionPreference

try {
    $ErrorActionPreference = 'Continue'  # native calls below -- the #107 stderr pitfall guard

    # --- Fake gh -----------------------------------------------------------------------------------
    # Records every invocation (one line per call) so ordering can be asserted, and answers:
    #   pr view    -> GH_PR_BODY (or fails when GH_FAIL_PR_VIEW is set)
    #   issue view -> 'CLOSED' when the number is listed in GH_CLOSED_ISSUES, else 'OPEN'
    #   issue comment / issue close -> recorded, exit 0
    New-Item -ItemType Directory -Path $fakeBin -Force | Out-Null
    $ghImpl = @'
if ($env:GH_CALL_LOG) { Add-Content -Path $env:GH_CALL_LOG -Value ($args -join ' ') }
if ($args -contains 'pr' -and $args -contains 'view') {
    if ($env:GH_FAIL_PR_VIEW) { [Console]::Error.WriteLine('fake gh: pr view failed'); exit 1 }
    Write-Output $env:GH_PR_BODY
    exit 0
}
if ($args -contains 'issue' -and $args -contains 'view') {
    $num = $args[[array]::IndexOf($args, 'view') + 1]
    $closed = @()
    if ($env:GH_CLOSED_ISSUES) { $closed = $env:GH_CLOSED_ISSUES -split ',' }
    if ($closed -contains $num) { Write-Output 'CLOSED' } else { Write-Output 'OPEN' }
    exit 0
}
if ($args -contains 'issue' -and $args -contains 'comment') { exit 0 }
if ($args -contains 'issue' -and $args -contains 'close') { exit 0 }
exit 1
'@
    [System.IO.File]::WriteAllText((Join-Path $fakeBin 'gh-impl.ps1'), $ghImpl, $Utf8NoBom)
    $ghCmd = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0gh-impl.ps1`" %*`r`nexit /b %ERRORLEVEL%`r`n"
    [System.IO.File]::WriteAllText((Join-Path $fakeBin 'gh.cmd'), $ghCmd, $Utf8NoBom)
    $env:PATH = "$fakeBin;$env:PATH"
    $env:GH_CALL_LOG = $callLog

    function Invoke-Verify {
        <# Runs the script under test with a clean call log and returns its output + the log. #>
        param([string]$Body, [string]$ClosedIssues = '', [switch]$ReportOnly, [switch]$FailPrView)
        Remove-Item -Path $callLog -Force -ErrorAction SilentlyContinue
        $env:GH_PR_BODY = $Body
        $env:GH_CLOSED_ISSUES = $ClosedIssues
        if ($FailPrView) { $env:GH_FAIL_PR_VIEW = '1' } else { Remove-Item Env:\GH_FAIL_PR_VIEW -ErrorAction SilentlyContinue }
        $shipArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath, '-Pr', '999', '-Repo', 'fake/repo')
        if ($ReportOnly) { $shipArgs += '-ReportOnly' }
        $out = (& powershell @shipArgs 2>&1 | Out-String)
        $code = $LASTEXITCODE
        $log = if (Test-Path $callLog) { Get-Content -Path $callLog } else { @() }
        # Output is whitespace-NORMALIZED here, once, for every scenario. The child renders
        # Write-Host/Write-Warning at ITS OWN console buffer width, so any phrase an assert matches can
        # be split by a line wrap -- and the wrap point depends on the width and on the repo's path
        # length, which differ between a dev machine and CI. This suite learned that the expensive way:
        # a 'gh issue list' assert passed locally and failed on CI, in the same class of bug a
        # copy-edit pass had just reported for the sibling suite. Fixing it per-assert there and not
        # here is precisely the instance-instead-of-class mistake, so it is centralized: no assert in
        # this file CAN be width-fragile.
        return [pscustomobject]@{ Output = ($out -replace '\s+', ' '); ExitCode = $code; Log = @($log) }
    }

    Write-Host "A declared issue that GitHub left open is closed, comment first" -ForegroundColor Cyan
    # #331 already closed by the merge, #332 still open -> only #332 is acted on.
    $r = Invoke-Verify -Body "Fixes the thing.`n`nCloses #331`nCloses #332" -ClosedIssues '331'
    Assert-Equal 0 $r.ExitCode 'exits 0'
    Assert-True (($r.Log | Where-Object { $_ -match 'issue view 331' }).Count -eq 1) 'checked the state of #331'
    Assert-True (($r.Log | Where-Object { $_ -match 'issue view 332' }).Count -eq 1) 'checked the state of #332'
    Assert-True (($r.Log | Where-Object { $_ -match 'issue close 331' }).Count -eq 0) 'did NOT re-close the already-closed #331'
    Assert-True (($r.Log | Where-Object { $_ -match 'issue close 332' }).Count -eq 1) 'closed the still-open #332'
    Assert-True (($r.Log | Where-Object { $_ -match 'issue comment 332' }).Count -eq 1) 'commented on #332'
    Assert-True (($r.Log | Where-Object { $_ -match 'issue comment 332' -and $_ -match '--body-file' }).Count -eq 1) 'the comment went via --body-file (never a multiline inline body)'
    # Ordering matters: `gh issue close --comment` drops a multiline comment, so the comment must
    # land BEFORE the close, not after.
    $cmtIdx = [array]::IndexOf(@($r.Log | ForEach-Object { $_ }), (@($r.Log | Where-Object { $_ -match 'issue comment 332' }))[0])
    $clsIdx = [array]::IndexOf(@($r.Log | ForEach-Object { $_ }), (@($r.Log | Where-Object { $_ -match 'issue close 332' }))[0])
    Assert-True ($cmtIdx -lt $clsIdx) 'commented BEFORE closing'

    Write-Host "Everything already closed by the merge -> nothing is touched" -ForegroundColor Cyan
    $r2 = Invoke-Verify -Body "Closes #331`nCloses #332" -ClosedIssues '331,332'
    Assert-Equal 0 $r2.ExitCode 'exits 0'
    Assert-True (($r2.Log | Where-Object { $_ -match 'issue close' }).Count -eq 0) 'closed nothing'
    Assert-True (($r2.Log | Where-Object { $_ -match 'issue comment' }).Count -eq 0) 'commented nothing'
    Assert-True ($r2.Output -match 'already closed by the merge') 'says so'

    Write-Host "A body that declares nothing" -ForegroundColor Cyan
    $r3 = Invoke-Verify -Body 'This PR mentions #332 but closes nothing.'
    Assert-Equal 0 $r3.ExitCode 'exits 0'
    Assert-True (($r3.Log | Where-Object { $_ -match 'issue view' }).Count -eq 0) 'no issue was even inspected'
    Assert-True (($r3.Log | Where-Object { $_ -match 'issue close' }).Count -eq 0) 'a PLAIN MENTION closes nothing'
    Assert-True ($r3.Output -match 'declared no issue') 'reports that nothing was declared'

    Write-Host "A closing keyword inside BACKTICKS is not a declaration" -ForegroundColor Cyan
    # The critical case: prose explaining the gate. This body is the shape of the gate's own changelog
    # entry. GitHub does not link a reference in a code span, so nothing may be closed here -- without
    # this, the script force-closed #331 with a comment crediting an unrelated PR.
    $r4 = Invoke-Verify -Body 'GitHub does not distribute a keyword: `Closes #331, #332` closes only the first.'
    Assert-Equal 0 $r4.ExitCode 'exits 0'
    Assert-True (($r4.Log | Where-Object { $_ -match 'issue close' }).Count -eq 0) 'closed NOTHING from a backticked example'
    Assert-True (($r4.Log | Where-Object { $_ -match 'issue view' }).Count -eq 0) 'did not even inspect it'
    # And the same body with the keyword OUTSIDE the backticks must still work, so the stripping is
    # not just silently swallowing everything.
    $r5 = Invoke-Verify -Body 'Closes #331 -- and see `#332` for context.'
    Assert-True (($r5.Log | Where-Object { $_ -match 'issue view 331' }).Count -eq 1) 'a real keyword outside backticks still counts'
    Assert-True (($r5.Log | Where-Object { $_ -match 'issue view 332' }).Count -eq 0) 'the backticked #332 does not'

    Write-Host "A fenced code block is stripped too" -ForegroundColor Cyan
    $fenced = "See the example:`n`n" + '```' + "`npowershell -Resolves 331`nCloses #331`n" + '```' + "`n`nNothing is declared here."
    $r6 = Invoke-Verify -Body $fenced
    Assert-True (($r6.Log | Where-Object { $_ -match 'issue close' }).Count -eq 0) 'closed nothing from inside a fence'

    Write-Host "-ReportOnly does not mutate anything" -ForegroundColor Cyan
    $r7 = Invoke-Verify -Body 'Closes #332' -ReportOnly
    Assert-Equal 0 $r7.ExitCode 'exits 0'
    Assert-True (($r7.Log | Where-Object { $_ -match 'issue view 332' }).Count -eq 1) 'still inspects the issue'
    Assert-True (($r7.Log | Where-Object { $_ -match 'issue close' }).Count -eq 0) 'closes nothing'
    Assert-True (($r7.Log | Where-Object { $_ -match 'issue comment' }).Count -eq 0) 'comments nothing'
    Assert-True ($r7.Output -match 'report-only') 'says it is report-only'

    Write-Host "An unreadable PR body warns and exits 0 (a merged ship must not read as failed)" -ForegroundColor Cyan
    $r8 = Invoke-Verify -Body 'Closes #332' -FailPrView
    Assert-Equal 0 $r8.ExitCode 'exits 0 even though gh failed'
    Assert-True ($r8.Output -match 'could not read the body') 'warns about it'
    Assert-True ($r8.Output -match 'gh issue list') 'points at the manual check'
    Assert-True (($r8.Log | Where-Object { $_ -match 'issue close' }).Count -eq 0) 'closed nothing while blind'
} finally {
    $ErrorActionPreference = $prevEap
    $env:PATH = $prevPath
    'GH_CALL_LOG', 'GH_PR_BODY', 'GH_CLOSED_ISSUES', 'GH_FAIL_PR_VIEW' | ForEach-Object {
        Remove-Item "Env:\$_" -ErrorAction SilentlyContinue
    }
    Remove-Item -Path $fakeBin -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $callLog -Force -ErrorAction SilentlyContinue
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
