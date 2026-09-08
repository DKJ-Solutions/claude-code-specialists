<#
.SYNOPSIS
    Judging a test fixture's own git commands -- one source for the rule, dot-sourced by the suites
    under scripts/tests/ (issue #1635).

.DESCRIPTION
    Dot-source this file from a suite:

        . (Join-Path $PSScriptRoot '..\lib\fixture-git-lib.ps1')

    WHY THIS EXISTS. A suite in this directory builds its fixture with git -- init, config,
    symbolic-ref, add, commit, remote add, push, clone -- and the standing idiom for those calls was

        & git -C $dir init -q 2>$null | Out-Null

    inside a try that lowers $ErrorActionPreference. Lowering the preference is correct and stays: git
    writes ordinary progress to stderr, which under EAP=Stop is a terminating NativeCommandError before
    any exit code is read (the #96/#97/#107 pitfall this repo documents). What was NOT correct is that
    the exit code went with it: a git command that FAILED was indistinguishable from one that worked.

    WHY THAT IS WORSE IN A FIXTURE THAN IN PRODUCTION CODE. A production script that ignores a failed
    git usually goes on to fail visibly. A fixture that ignores one produces a repo that is PLAUSIBLE --
    it exists, it has a HEAD, it just does not hold what the case assumed -- and every assert below it
    then measures the wrong thing. The failure is attributed to the script under test, which is the one
    place it certainly is not.

    AND THE PARALLEL GATE IS WHAT MAKES IT RECURRING RATHER THAN THEORETICAL. Thirty concurrent lanes
    over one temp tree make a transient index.lock sharing violation, a scanner holding a file or disk
    pressure ordinary rather than rare -- so the shape to expect is a suite that is red under the gate,
    green on its own, and silent about why. That is the sighting #1622 recorded, in sync-main.tests.ps1.

    THE COUNT DOES NOT THROW, DELIBERATELY. A suite that dies at the first fixture hiccup reports less
    than one that runs on and names what broke. So a failure is printed and counted, and
    Write-FixtureGitSummary at the foot of the suite turns the count into an exit code -- INCLUDING when
    every assert passed, because a clean sweep over a repo that was never built proves less than it
    appears to.

    THE STATE LIVES IN THE CALLING SUITE'S SCRIPT SCOPE, which is what dot-sourcing means: the
    assignment below and the functions' own $script: lookups both resolve to the scope of the file that
    dot-sourced this one. Each suite is its own process under the gate, so there is nothing to share and
    nothing to reset between suites.

    Workshop-only -- scripts/tests/ is not mirrored into any plugin, so this lib is not registered in
    shared-scripts-lib.ps1 and has no mirror to drift from.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

# EVERY FIXTURE git CALL THAT FAILED in the suite that dot-sourced this file. Initialized here rather
# than in each suite, so a suite cannot adopt the helper and forget the counter it reads.
$script:FixtureGitFailures = 0

function Assert-FixtureGitOk {
    <#
        Judge ONE fixture git call: on a non-zero exit code, print the command, print git's own output,
        and count it. Silent and free on the normal path.

        The caller keeps its own signature and its own EAP handling -- this function is only the verdict,
        because the suites in this directory pass their git arguments in four different shapes (a
        [string[]] parameter, ValueFromRemainingArguments, $args, a literal argument list) and rewriting
        every call site was never the point of #1635.

        -Output is git's combined output, captured by the caller with 2>&1. Passing it is optional: a
        caller that discarded the output still gets the exit code and the command named, which is the
        part that says a fixture is broken. Under Windows PowerShell 5.1 a native child's stderr captured
        with 2>&1 arrives wrapped in ErrorRecords -- harmless at EAP=Continue, which is where every
        caller here already is, and $LASTEXITCODE is unaffected by the wrapping. It is $? that the
        wrapping disturbs, and nothing here reads $?.
    #>
    param(
        [Parameter(Mandatory = $true)][AllowNull()][int]$Code,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$GitArgs,
        $Output = $null
    )
    if ($Code -eq 0) { return }
    $script:FixtureGitFailures++
    Write-Host "  [FIXTURE GIT FAILED] exit $Code -- git $($GitArgs -join ' ')" -ForegroundColor Magenta
    if ($null -ne $Output) {
        foreach ($line in (($Output | Out-String) -split "`r?`n")) {
            if ("$line".Trim()) { Write-Host "      $line" -ForegroundColor Magenta }
        }
    }
}

function Invoke-FixtureGitJudged {
    <#
        Run one git command with the EAP lowered, discard its output, and judge its exit code. The
        one-line replacement for the `& git ... 2>$null | Out-Null` idiom, for the suites whose fixture
        builders call git inline rather than through a helper of their own.

        -Arguments is the whole argument vector, '-C <dir>' included -- the same shape those inline call
        sites already had, so converting one is a substitution rather than a redesign.
    #>
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & git @Arguments 2>&1
        Assert-FixtureGitOk -Code $LASTEXITCODE -GitArgs $Arguments -Output $out
    } finally { $ErrorActionPreference = $prevEap }
}

function Invoke-FixtureGitIn {
    <#
        The same thing for the dominant idiom in this directory -- `& git -C $dir <rest>` -- so a call
        site converts by substitution rather than by being rewritten:

            & git -C $dir commit -q -m 'init' 2>$null | Out-Null
            Invoke-FixtureGitIn $dir commit -q -m 'init'

        FIRST ARGUMENT IS THE REPO DIRECTORY; everything after it is git's own argument vector.

        NO param() BLOCK, DELIBERATELY, and this is the whole reason the function is shaped like this.
        A param block makes it an advanced function, and PowerShell then tries to BIND every argument
        starting with a dash to a parameter name -- so `branch -D <name>` would resolve `-D` against a
        `-Dir`-style parameter and either take the branch name as the directory or fail on a duplicate.
        A simple function with no param block puts every argument in $args verbatim, dashes included,
        which is exactly what a pass-through to a native command needs. Measured shape, not a
        preference: git's own flags include -C, -c, -D, -R, -q, -m and -b, and a wrapper that binds any
        of them silently changes the command it was asked to run.
    #>
    $a = @($args | ForEach-Object { "$_" })
    if ($a.Count -lt 1) { throw 'Invoke-FixtureGitIn: the first argument is the repo directory.' }
    $rest = if ($a.Count -gt 1) { @($a[1..($a.Count - 1)]) } else { @() }
    Invoke-FixtureGitJudged (@('-C', $a[0]) + $rest)
}

function Get-FixtureGitFailureCount {
    <# How many fixture git commands failed so far. For a suite that wants to say so mid-run, and for
       this lib's own tests. #>
    return $script:FixtureGitFailures
}

function Write-FixtureGitSummary {
    <#
        Print the broken-fixture block if anything failed, and return $true when it did -- which the
        caller turns into an exit code.

        WHY IT IS PRINTED ABOVE THE VERDICT AND EVEN ON A GREEN RUN. Every assert below a git command
        that failed is measuring a repo that was never built, so reading them as a judgement on the
        script under test is the wrong conclusion -- and it is the conclusion a reader reaches by
        default, because a red suite normally means the script regressed. A fixture that half-built and
        still went green is a case the suite is not testing, and the reader should know which run they
        are looking at.

        -Subject names the script under test, so the line says what the asserts are NOT a verdict on.
    #>
    param([string]$Subject = 'the script under test')
    if ($script:FixtureGitFailures -le 0) { return $false }
    Write-Host "FIXTURE: $($script:FixtureGitFailures) git command(s) FAILED while building this run's repos -- see the [FIXTURE GIT FAILED] lines above." -ForegroundColor Magenta
    Write-Host "         Whatever the asserts say, they are not a verdict on $Subject`: some of them read a repo that was never built." -ForegroundColor Magenta
    Write-Host "         Under the parallel test gate this is the shape to expect from contention (issue #1622) -- re-run the suite on its own before reading anything into it." -ForegroundColor Magenta
    Write-Host ''
    return $true
}
