<#
.SYNOPSIS
    Tests for scripts/lib/fixture-git-lib.ps1 -- the judging every suite's own fixture git calls now
    goes through (issue #1635).

.DESCRIPTION
    WHAT THIS EXISTS FOR. The lib is the one place that decides whether a broken fixture is visible, and
    it is invisible when it works: on the normal path it prints nothing and returns nothing, so a
    regression that stopped counting would leave every suite green and every suite meaningless. That is
    the same failure #1622 recorded one layer down -- a run that proves less than it appears to -- and it
    is why the counting is asserted rather than assumed.

    THE CASES RUN REAL git COMMANDS, both a succeeding one and a failing one, because the whole subject
    is what $LASTEXITCODE says after a native call. A stub returning a canned code would prove only that
    the arithmetic works.

    THE FAILING COMMAND IS `git -C <a directory that is not a repo> rev-parse`, which is a genuine
    non-zero exit with real stderr and needs no network, no fixture repo and nothing to clean up.

    WHY Invoke-FixtureGitIn HAS ITS OWN CASE. It takes no param() block on purpose -- an advanced
    function would BIND a leading-dash argument to a parameter name, so `branch -D <name>` would resolve
    -D against a -Dir-style parameter and silently change the command. That property is invisible until
    a suite passes a flag that collides, so it is pinned here with the flags git actually uses.

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibPath  = Join-Path $RepoRoot 'scripts\lib\fixture-git-lib.ps1'

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ("$Expected" -eq "$Actual") { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}
function Assert-True {
    param([bool]$Condition, [string]$Label)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label" -ForegroundColor Red }
}

function Assert-Says {
    <#
        Does the captured text contain this phrase, whatever the console did to it?

        STRIPS ALL WHITESPACE FROM BOTH SIDES -- issue #1512's rule, and this suite paid for ignoring it
        on its first CI run. Case 5 below captures Write-Host through the information stream, which goes
        through PowerShell's formatter, and the formatter HARD-WRAPS at the buffer width of whatever host
        is running. Both text asserts there passed locally and failed on the CI runner while the lib was
        behaving correctly -- the count asserts beside them stayed green, which is what pinned it to the
        text rather than to the behaviour. The reported command carries a temp path, so the line is long
        enough for a wrap point to land inside it, and which asserts straddle a break is decided by the
        width: a green run is not evidence. Normalizing runs of whitespace to one space does not fix it
        either, because the formatter breaks at whatever character sits at the column, word or not.

        Literal (IndexOf) rather than -match, so a phrase carrying a path separator, a dot or a bracket
        needs no escaping.
    #>
    param([string]$Text, [string]$Phrase, [string]$Label)
    $haystack = ($Text -replace '\s', '')
    $needle   = ($Phrase -replace '\s', '')
    if ($haystack.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Label`n         wanted to find: '$Phrase'`n         in:             '$Text'" -ForegroundColor Red
    }
}

Assert-True (Test-Path -LiteralPath $LibPath) 'fixture-git-lib.ps1 exists at its registered source path'
. $LibPath

# A directory that exists and is NOT a git repo -- the failing command's target. Under the temp root and
# keyed on $PID plus a fresh GUID, the per-process rule every fixture in this directory follows.
$NotARepo = Join-Path ([System.IO.Path]::GetTempPath()) ("fixture-git-lib-$PID-" + [guid]::NewGuid().ToString('N').Substring(0, 6))

try {
    New-Item -ItemType Directory -Path $NotARepo -Force | Out-Null

    # --- 1. the counter starts at zero and a working command leaves it there ------------------------
    Write-Host "`n== 1. a working fixture command is silent and free ==" -ForegroundColor Cyan
    Assert-Equal 0 (Get-FixtureGitFailureCount) 'the counter starts at zero'
    Invoke-FixtureGitJudged @('--version')
    Assert-Equal 0 (Get-FixtureGitFailureCount) 'a git command that exits 0 is not counted'
    Assert-True (-not (Write-FixtureGitSummary)) 'and the summary reports nothing to report'

    # --- 2. THE CASE THE LIB EXISTS FOR: a failing command is counted -------------------------------
    #
    # This is what the old `& git ... | Out-Null` idiom could not do. The count is the only thing that
    # knows, so it is the thing under test -- not the console text, which a later rewording may change.
    Write-Host "`n== 2. a failing fixture command is counted, not swallowed ==" -ForegroundColor Cyan
    Invoke-FixtureGitJudged @('-C', $NotARepo, 'rev-parse', 'HEAD')
    Assert-Equal 1 (Get-FixtureGitFailureCount) 'a git command that exits non-zero is counted once'
    Invoke-FixtureGitJudged @('-C', $NotARepo, 'rev-parse', 'HEAD')
    Assert-Equal 2 (Get-FixtureGitFailureCount) 'and the count accumulates rather than latching'

    # --- 3. the summary is what turns the count into an exit code -----------------------------------
    #
    # A CLEAN SWEEP OVER A BROKEN FIXTURE IS NOT A PASS, which is the whole point of returning $true
    # here: the caller's own assert tally is zero-fail in exactly the run this has to fail.
    Write-Host "`n== 3. the summary answers TRUE once anything failed ==" -ForegroundColor Cyan
    Assert-True (Write-FixtureGitSummary -Subject 'the script under test') 'the summary reports a broken fixture'
    Assert-Equal 2 (Get-FixtureGitFailureCount) 'and reading it does not reset the count'

    # --- 4. Assert-FixtureGitOk judges one call, with or without output -----------------------------
    Write-Host "`n== 4. the one-call verdict ==" -ForegroundColor Cyan
    Assert-FixtureGitOk -Code 0 -GitArgs @('init')
    Assert-Equal 2 (Get-FixtureGitFailureCount) 'code 0 adds nothing'
    Assert-FixtureGitOk -Code 128 -GitArgs @('commit', '-m', 'x')
    Assert-Equal 3 (Get-FixtureGitFailureCount) 'a non-zero code counts even with no output to print'

    # --- 5. Invoke-FixtureGitIn passes dashed flags THROUGH rather than binding them ----------------
    #
    # The property that would break silently. If this function ever grows a param() block, `-D` and `-q`
    # below stop being git's arguments and become PowerShell's -- and the command that runs is not the
    # command that was written. Asserted on the ARGUMENT VECTOR the failure line reports, because that
    # is the only place the resolved arguments are observable from outside.
    Write-Host "`n== 5. a dashed git flag is git's, not PowerShell's ==" -ForegroundColor Cyan
    $before = Get-FixtureGitFailureCount
    $out = Invoke-FixtureGitIn $NotARepo branch -D 'no-such-branch' 4>&1 6>&1 | Out-String
    Assert-Equal ($before + 1) (Get-FixtureGitFailureCount) 'the call ran and its failure was counted'
    # The dir arrives as '-C <dir>' and the flags arrive in order behind the subcommand. Through
    # Assert-Says rather than -match, for the wrap reason written at that function.
    Assert-Says $out "git -C $NotARepo branch -D no-such-branch" `
        'the reported command is the one that was written -- -D reached git verbatim'

    $before = Get-FixtureGitFailureCount
    $out = Invoke-FixtureGitIn $NotARepo commit -q -m 'a message with spaces' 4>&1 6>&1 | Out-String
    Assert-Equal ($before + 1) (Get-FixtureGitFailureCount) '-q -m also reached git rather than being bound'
    Assert-Says $out 'commit -q -m a message with spaces' `
        'and a quoted argument stays one argument'

    # Called with nothing at all it throws rather than running `git -C` against an empty path, which git
    # answers in a way that looks like a fixture failure instead of a call-site mistake.
    Write-Host "`n== 6. a call with no directory is a call-site error, said as one ==" -ForegroundColor Cyan
    $threw = $false
    try { Invoke-FixtureGitIn } catch { $threw = $true }
    Assert-True $threw 'Invoke-FixtureGitIn with no arguments throws'
}
finally {
    if (Test-Path -LiteralPath $NotARepo) { Remove-Item -Recurse -Force -LiteralPath $NotARepo -ErrorAction SilentlyContinue }
}

# NO Write-FixtureGitSummary GATE AT THIS FOOT, and that is deliberate rather than an omission: this
# suite FAILS fixture git commands on purpose, so its own count is expected to be non-zero and using it
# as a verdict here would make a correct run red. Every other suite reads it; this one asserts it.
Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
