<#
.SYNOPSIS
    The CI shard: Invoke-TestSuiteGate's partition, and the fail-closed summary job that makes four
    green shards mean something. Issue #1351.

.DESCRIPTION
    WHY THIS SUITE EXISTS. Sharding replaced one required check with five jobs, and every way it can go
    wrong is SILENT IN THE GREEN DIRECTION -- the family this repo has now measured three times (#1294's
    dropped runs, #1300's fold shortcut, #1325's exit-code inference). Specifically:

      * -ShardCount disagreeing with the matrix length runs a FRACTION of the pool and reports every
        shard green. A matrix of [1,2,3,4] against -ShardCount 5 runs 4/5 of the suites, for ever, with
        nothing in any log saying which fifth never ran.
      * The summary job losing `if: always()` turns a red shard into NO verdict: a job that needs a
        failed job is skipped, and a skipped check is not a reported failure.
      * The summary job losing its result comparison turns `always()` into a permanent GREEN.
      * The summary job being RENAMED un-gates `main` outright -- `main-ci-gate` requires the context
        `lint-en-tests`, so the ruleset would wait for a check nobody reports.

    None of those changes any observable behaviour of the repo TODAY, which is what makes them worth
    asserts rather than a comment: nothing else in the tree would notice.

    THE PARTITION IS TESTED AS A PROPERTY, NOT AS A SPELLING. The asserts below run the real
    Invoke-TestSuiteGate over a temporary directory of trivial suites and check what it actually RAN --
    a clean cover (every suite exactly once across the shards), balance, and the refusals -- rather than
    grepping the lib for a modulo. A stride written backwards, off by one, or over an unsorted list
    passes every text match and fails the cover.

    WHY IT RUNS REAL CHILD PROCESSES. The gate's whole shape is Start-Process children, and the property
    under test is which files it hands to them. Its own per-suite output is the only honest evidence of
    that, so each fixture suite prints a line naming itself and the assert reads the transcript. The
    fixture suites do nothing else, so the whole suite costs a few seconds.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

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

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$ciPath   = Join-Path $repoRoot '.github\workflows\ci.yml'
$libPath  = Join-Path $repoRoot 'scripts\lib\native-capture-lib.ps1'

$ci = Get-Content -LiteralPath $ciPath -Raw
. $libPath

# ------------------------------------------------------------------------------------------------
Write-Host "== the partition: a clean cover, over a real gate run ==" -ForegroundColor Cyan

# Twelve suites, named so that alphabetical order is unambiguous and a stride is distinguishable from a
# contiguous block. Each one prints its own name and exits 0.
$fixtureDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ci-shard-fixture-$PID")
if (Test-Path -LiteralPath $fixtureDir) { Remove-Item -Recurse -Force -LiteralPath $fixtureDir }
New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null

$fixtureNames = @()
foreach ($n in 1..12) {
    $name = ('s{0:d2}' -f $n)
    $fixtureNames += $name
    $body = "Write-Host 'RAN:$name'" + "`r`n" + 'exit 0'
    Set-Content -LiteralPath (Join-Path $fixtureDir "$name.tests.ps1") -Value $body -Encoding Ascii
}

function Get-ShardRun {
    <# Runs the real gate for one shard and returns the suite names it actually executed. #>
    param([int]$Shard, [int]$ShardCount)
    $out = Invoke-TestSuiteGate -TestsDir $fixtureDir -Context 'gate probe' -MaxParallel 4 `
        -Shard $Shard -ShardCount $ShardCount 6>&1 | Out-String -Width 4000
    $ran = @([regex]::Matches($out, 'RAN:(s\d\d)') | ForEach-Object { $_.Groups[1].Value })
    [pscustomobject]@{ Ran = $ran; Text = $out }
}

$shardRuns = @(1..4 | ForEach-Object { Get-ShardRun -Shard $_ -ShardCount 4 })
$allRan = @($shardRuns | ForEach-Object { $_.Ran })

Assert-True ($allRan.Count -eq 12) "four shards of four run 12 suites in total, not more and not fewer (ran $($allRan.Count))"
Assert-True (@($allRan | Sort-Object -Unique).Count -eq 12) 'every suite ran exactly once -- no suite is in two shards'
Assert-True ((Compare-Object $fixtureNames ($allRan | Sort-Object) | Measure-Object).Count -eq 0) `
    'and the union is the whole pool -- no suite is in no shard'

# BALANCE IS THE POINT OF THE STRIDE, so it is asserted rather than assumed. 12 over 4 is exact; the
# general claim is that no two shards differ by more than one, which is what a stride guarantees and a
# contiguous block over an uneven division does not.
$sizes = @($shardRuns | ForEach-Object { $_.Ran.Count })
Assert-True (($sizes | Measure-Object -Maximum).Maximum - ($sizes | Measure-Object -Minimum).Minimum -le 1) `
    "no two shards differ in size by more than one (sizes $($sizes -join ','))"

# A STRIDE, NOT A BLOCK -- the assert that actually distinguishes the two implementations. Shard 1 of a
# stride holds s01, s05, s09; shard 1 of a contiguous split holds s01, s02, s03.
Assert-True (($shardRuns[0].Ran | Sort-Object) -join ',' -eq 's01,s05,s09') `
    'shard 1 holds every fourth suite (s01,s05,s09) -- a stride, not the first contiguous block'
Assert-True (($shardRuns[1].Ran | Sort-Object) -join ',' -eq 's02,s06,s10') 'and shard 2 is offset by one'

# DETERMINISM: the same two integers select the same files, which is what makes a red shard re-runnable
# by hand. Asserted by running one shard twice rather than by reading the sort call.
$again = Get-ShardRun -Shard 3 -ShardCount 4
Assert-True ((($again.Ran | Sort-Object) -join ',') -eq (($shardRuns[2].Ran | Sort-Object) -join ',')) `
    'the same (Shard, ShardCount) selects the same suites on a second run'

# THE UNSHARDED CALL IS UNCHANGED -- every existing caller passes neither parameter.
$whole = Invoke-TestSuiteGate -TestsDir $fixtureDir -Context 'gate probe' -MaxParallel 4 6>&1 | Out-String -Width 4000
$wholeRan = @([regex]::Matches($whole, 'RAN:(s\d\d)') | ForEach-Object { $_.Groups[1].Value })
Assert-True ($wholeRan.Count -eq 12) 'a call with neither parameter still runs the whole pool'
Assert-True ($whole -match 'all 12 suites passed') 'and its summary line still says "all 12", unchanged'
Assert-True ($whole -notmatch 'shard') 'and mentions no shard at all'

Write-Host "== the summary line names its scope (#1318's rule, applied to shards) ==" -ForegroundColor Cyan
Assert-True ($shardRuns[0].Text -match 'shard 1/4') 'a sharded run names the shard on the line that gets quoted'
Assert-True ($shardRuns[0].Text -match '3 of 12 suites passed') 'and states the slice against the pool, so the seconds are readable later'
Assert-True ($shardRuns[0].Text -notmatch 'all 3 suites passed') 'and never claims "all" of a slice'

Write-Host "== the refusals: a nonsensical shard is not interpreted ==" -ForegroundColor Cyan

# EACH OF THESE HAS A PLAUSIBLE SILENT READING, which is why the gate throws instead of picking one.
$threw = $false
try { Invoke-TestSuiteGate -TestsDir $fixtureDir -Shard 3 6>&1 | Out-Null } catch { $threw = $true }
Assert-True $threw '-Shard without -ShardCount throws rather than quietly running the whole pool'

$threw = $false
try { Invoke-TestSuiteGate -TestsDir $fixtureDir -ShardCount 4 6>&1 | Out-Null } catch { $threw = $true }
Assert-True $threw '-ShardCount without -Shard throws rather than quietly running the whole pool'

$threw = $false
try { Invoke-TestSuiteGate -TestsDir $fixtureDir -Shard 5 -ShardCount 4 6>&1 | Out-Null } catch { $threw = $true }
Assert-True $threw 'a shard past the count throws rather than selecting nothing and reporting green'

$threw = $false
try { Invoke-TestSuiteGate -TestsDir $fixtureDir -Shard 0 -ShardCount 4 6>&1 | Out-Null } catch { $threw = $true }
Assert-True $threw 'and so does shard 0 -- the parameter is 1-based, and off-by-one is the likeliest typo'

# MORE SHARDS THAN SUITES is the one empty slice that is legitimate, and it must not read as "this repo
# has no tests" -- the directory plainly does.
$thin = Invoke-TestSuiteGate -TestsDir $fixtureDir -Shard 20 -ShardCount 20 -MaxParallel 2 3>&1 6>&1 | Out-String -Width 4000
Assert-True ($thin -match 'more shards than suites') 'an empty slice says more shards than suites'
Assert-True ($thin -notmatch 'no \*\.tests\.ps1 suites found') 'and does not claim the directory is empty when it holds twelve'

if (Test-Path -LiteralPath $fixtureDir) { Remove-Item -Recurse -Force -LiteralPath $fixtureDir }

# ------------------------------------------------------------------------------------------------
Write-Host "== ci.yml: the matrix and -ShardCount agree ==" -ForegroundColor Cyan

# THE ONE MISMATCH NOTHING ELSE WOULD CATCH. Both numbers are read out of the workflow and compared, so
# changing the matrix without changing the flag fails here instead of running a fraction of the pool for
# ever. Derived, not hard-coded to 4: raising both together is a legitimate change and must stay green.
$matrixMatch = [regex]::Match($ci, '(?m)^\s*shard:\s*\[([0-9,\s]+)\]\s*$')
Assert-True ($matrixMatch.Success) 'ci.yml declares a shard matrix as a literal list'
$matrixEntries = @()
if ($matrixMatch.Success) {
    $matrixEntries = @($matrixMatch.Groups[1].Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
# ANCHORED ON THE CALL, NOT ON THE FILE. The first version of this assert searched the whole workflow
# for '-ShardCount\s+(\d+)' and read the 5 out of the COMMENT that explains what a mismatch would do --
# so it reported a mismatch against a file that had none. Same trap the merge-queue suite's header names
# for `merge_group`: on a page where every rule is also explained in prose, a substring match reads the
# prose. The number that matters is the one on the line that invokes the gate.
$countMatch = [regex]::Match($ci, 'Invoke-TestSuiteGate[^\r\n]*-ShardCount\s+(\d+)')
Assert-True ($countMatch.Success) 'and passes -ShardCount on the line that calls the gate'
Assert-True ($matrixMatch.Success -and $countMatch.Success -and [int]$countMatch.Groups[1].Value -eq $matrixEntries.Count) `
    "-ShardCount ($(if ($countMatch.Success) { $countMatch.Groups[1].Value } else { '?' })) equals the matrix length ($($matrixEntries.Count))"
Assert-True (($matrixEntries | Sort-Object { [int]$_ }) -join ',' -eq (1..$matrixEntries.Count -join ',')) `
    'and the matrix is 1..N with no gaps -- the gate refuses anything else, but it would refuse it in CI'
Assert-True ($ci -match '-Shard \$\{\{ matrix\.shard \}\}') 'each entry passes its own shard number through'

Write-Host "== ci.yml: the required check is the summary job, and it fails closed ==" -ForegroundColor Cyan

# THE NAME. `main-ci-gate` requires the context 'lint-en-tests'; GitHub names a check after its job.
Assert-True ($ci -match '(?m)^  lint-en-tests:\s*$') 'a job named lint-en-tests still exists -- the required context is reported'
Assert-True ($ci -match '(?m)^  suites:\s*$') 'the suites job carries the pool'
Assert-True ($ci -match '(?m)^  lint:\s*$') 'and the lint keeps a job of its own, run once rather than once per shard'

# Extract the summary job by its own key, so the asserts below cannot be satisfied by text elsewhere in
# the file -- the mistake the merge-queue suite's own header warns about.
$summaryJob = [regex]::Match($ci, '(?ms)^  lint-en-tests:\s*$(?<body>.*)\z')
Assert-True ($summaryJob.Success) 'the summary job block is readable'
$summary = if ($summaryJob.Success) { $summaryJob.Groups['body'].Value } else { '' }

Assert-True ($summary -match '(?m)^\s*needs:\s*\[\s*lint\s*,\s*suites\s*\]') 'it needs both legs'
Assert-True ($summary -match '(?m)^\s*if:\s*always\(\)') `
    'and runs with if: always() -- without it a red shard reports NO verdict rather than a red one'
Assert-True ($summary -match 'needs\.lint\.result') 'it reads the lint result'
Assert-True ($summary -match 'needs\.suites\.result') 'and the suites result'
Assert-True ($summary -match 'exit 1') 'and exits non-zero on a leg that did not succeed'

# STRICT SUCCESS, both legs. A comparison against 'failure' would pass a skipped or cancelled leg, which
# is the same silence in a different coat.
Assert-True ($summary -match '"\$\{\{ needs\.lint\.result \}\}"\s*!=\s*"success"') 'the lint leg is required to be success, not merely not-failure'
Assert-True ($summary -match '"\$\{\{ needs\.suites\.result \}\}"\s*!=\s*"success"') 'and so is the suites leg'
Assert-True ($summary -notmatch '!=\s*["'']failure') 'no leg is judged by "not failure", which would accept skipped and cancelled'

# It must not become a job that does work -- if it ever needs a checkout or a script, the reasoning for
# putting it on ubuntu (and for it being cheap) has changed and should be re-read rather than patched.
Assert-True ($summary -notmatch 'actions/checkout') 'the summary job checks nothing out -- it compares two strings'
Assert-True ($summary -match 'runs-on: ubuntu-latest') 'and runs on ubuntu, which the file header explains'

Write-Host "== ci.yml: what sharding must NOT have changed ==" -ForegroundColor Cyan

# #1300's fold shortcut stays on the STEP. On the job it would make needs.suites.result legitimately
# 'skipped' on a fold commit, and the summary would then have to accept a non-success from that leg.
$suitesJob = [regex]::Match($ci, '(?ms)^  suites:\s*$(?<body>.*?)(?=^  lint-en-tests:\s*$)')
Assert-True ($suitesJob.Success) 'the suites job block is readable'
$suitesBody = if ($suitesJob.Success) { $suitesJob.Groups['body'].Value } else { '' }
Assert-True ($suitesBody -notmatch "(?m)^    if:") `
    'the fold-commit skip is NOT a job-level if: -- that would make a skipped leg legitimate'
Assert-True ($suitesBody -match "(?m)^        if:[^\r\n]*startsWith\(github\.event\.head_commit\.message,\s*'fold:'\)") `
    'it is still the step-level skip #1300 measured'
Assert-True ($suitesBody -match 'fail-fast: false') `
    'fail-fast is false -- a red shard must not cancel the other three, which is where the re-run evidence lives'

# The gate is still the shared one (#512), and CI still does not walk scripts/tests itself.
Assert-True ($ci -match 'Invoke-TestSuiteGate') 'CI still calls the shared gate rather than a copy of its loop'
Assert-True ($ci -notmatch 'Get-ChildItem[^\r\n]*tests') 'and still does not glob the suites itself'
Assert-True ($ci -match '(?m)^\s{2}merge_group:') 'the merge_group trigger survived the restructure (#1325 prerequisite 1)'
Assert-True ($ci -like '*#1351*') 'and the file cites the issue whose measurement explains the shape'

# ------------------------------------------------------------------------------------------------
Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILED: $($script:fail) of $($script:pass + $script:fail) asserts." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
