<#
.SYNOPSIS
    Which sibling libs a lib dot-sources, which libs a test suite copies into its fixture, and the
    gap between the two (issue #1693).

.DESCRIPTION
    WHY THIS EXISTS. Several suites build their fixture tree by HAND-LISTING the libs they copy into
    it, and nothing held those lists against what the copied libs actually dot-source. #1682 gave
    park-lib.ps1 its first lib dependency and every one of those lists went stale in the same commit.

    AND THE MISS IS SILENT, WHICH IS THE PART WORTH A GATE. The dot-source is guarded --
    `if (Test-Path $lib) { . $lib }` -- and correctly so: a consumer whose plugin mirror predates the
    new lib must not crash on load. In a fixture the file is absent for a completely different reason
    (nobody listed it), and the guard turns "this dependency is missing" into "the function is
    undefined". In Get-GitParkBacking's case that came out as an EMPTY BACKING NOTE rather than an
    error, so the failure surfaced only in whichever suite happened to assert the affected behaviour:
    park-cycle.tests.ps1 went 10 of 91 asserts red, while park-branch (31) and park-commit (28)
    exercised the same lib and stayed green because neither asserts that note.

    THE DEPENDENCY IS READ THROUGH THE VARIABLE, NOT OFF THE DOT-SOURCE LINE, and that is the whole
    reason this is a lib rather than three regexes in a suite. The shape this repo actually uses is:

        $parkPorcelainLib = Join-Path $PSScriptRoot 'git-porcelain-lib.ps1'
        if (Test-Path -LiteralPath $parkPorcelainLib -PathType Leaf) { . $parkPorcelainLib }

    so the dot-source command's own text is `. $parkPorcelainLib` and carries NO filename at all. A
    reader that matches on the dot-source's extent finds nothing -- measured against
    origin/fix/1682-porcelain-line-parse, the only real instance of the class, where it missed it
    outright. So a variable is resolved to its assignment in the same file and the literal is taken
    from there.

    A LITERAL IS NOT ENOUGH ON ITS OWN, EITHER, WHICH IS WHY THE DOT-SOURCE GATES THE READ. Naming a
    '.ps1' in a string is not the same as depending on it: shared-scripts-lib.ps1's registry names
    every mirrored script in the tree, and a reader that took every '.ps1' literal would report all of
    them. Only a literal that some dot-source actually reaches counts.

    COMMENTS CANNOT REACH ANY OF IT, and that is a property rather than an accident. park-lib.ps1's
    own header carries `. (Join-Path $PSScriptRoot '..\lib\park-lib.ps1')` as an .EXAMPLE; the AST
    does not see comments, so it cannot be mistaken for a self-dependency. This is the same reason
    check-plugin-integrity.ps1's fixture-git check reads the AST rather than the line text.

    Pure ASCII (repo convention for .ps1). No Set-StrictMode: dot-sourcing would change the strict
    mode of the calling script.
#>

# Separators are normalised through these rather than through a '\\' in a pattern. Written as code
# points because a backslash pair does not survive every layer this repo's scripts get written by --
# measured while building #1693, where '[\\/]' reached the file as '[\/]' and the class then matched
# only a forward slash, so the reader silently found nothing.
$script:FixtureDepBackslash = [char]92
$script:FixtureDepForwardSlash = [char]47

# A bare '<name>.ps1', or one at the end of a path. Anchored on the leaf so 'scripts/lib/x.ps1',
# '..\lib\x.ps1' and a bare 'x.ps1' all yield 'x.ps1'.
$script:FixtureDepLeafPattern = '(?:^|/)([A-Za-z0-9_.-]+\.ps1)$'

# THE REPO-OWNED SEAMS, WHICH A FIXTURE DOES NOT OWE (issue #1693). These are not "libs we decided to
# skip": they are the files whose CONTENT differs per repo, so the caller dot-sources the consumer's
# own copy from its repo root and a lib's sibling dot-source of the same name is a documented
# FALLBACK rather than the dependency. release-lib.ps1 says it in so many words -- "branch-info.ps1 is
# REPO-OWNED -- the prefix table differs per repo ... the caller (cut-release.ps1) has already
# dot-sourced the CONSUMER's branch-info from its repo root". A fixture that supplies the seam its own
# way is therefore complete, and demanding the sibling copy would report a correct fixture as broken.
#
# MEASURED: this is the second of the two false findings a naive version of this check produced on a
# clean tree -- internal-note.tests.ps1, which copies release-lib.ps1 and four of its five siblings and
# is right not to copy this one.
#
# ONE ENTRY, AND THE BAR FOR A SECOND IS THE RULE ABOVE, not convenience: the file must be one whose
# content the consuming repo owns. repo-config.ps1 is the other file in this tree that would qualify,
# and it is deliberately absent because no lib dot-sources it as a sibling -- adding it now would be a
# rule with nothing under it. THIS LIST IS NOT THE PLACE for a fixture that omits a dependency on
# purpose; see Get-FixtureCopiedLibName for why that needs an opt-out on the suite instead.
$script:FixtureDepRepoOwnedSeam = @('branch-info.ps1')

# Get-DotSourcedLibName's per-path memo. Declared here rather than on first use: see that function for
# why the lazy form cannot work under Set-StrictMode.
$script:FixtureDepDotSourceCache = @{}

function Get-FixtureDepRepoOwnedSeam {
    <# The repo-owned seam files a fixture does not owe a copy of. Exposed so a suite can assert the
       list rather than restate it -- a second definition of an exemption list is how one of them goes
       stale without anything saying so. #>
    return @($script:FixtureDepRepoOwnedSeam)
}

function Get-FixtureDepAst {
    <#
        The parsed AST of one .ps1, or a throw naming the file. Separate so both readers below fail
        the same way on an unparseable file rather than one of them returning an empty answer -- an
        empty answer here reads as "no dependencies", which is the exact silence this lib exists to
        remove.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    $errs = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errs)
    if ($errs -and @($errs).Count -gt 0) {
        throw "fixture-dep: '$Path' does not parse ($(@($errs)[0].Message))"
    }
    return $ast
}

function Get-FixtureDepPs1Leaf {
    <#
        The '<name>.ps1' a string literal names, or '' when it names none. One place, so the three
        spellings a path can arrive in are normalised identically wherever they are read.
    #>
    param([string]$Value)

    if (-not $Value) { return '' }
    $normalised = $Value.Replace($script:FixtureDepBackslash, $script:FixtureDepForwardSlash)
    $m = [regex]::Match($normalised, $script:FixtureDepLeafPattern)
    if ($m.Success) { return $m.Groups[1].Value }
    return ''
}

function Get-DotSourcedLibName {
    <#
        Every sibling lib ONE .ps1 dot-sources, as bare '<name>.ps1' leaves.

        Two shapes are read, and the second is the one that matters here:
          - a literal              `. (Join-Path $PSScriptRoot 'x-lib.ps1')`
          - a variable             `. $someLib`, resolved to its assignment in the SAME file

        Resolution is deliberately file-local and takes the LAST assignment before the dot-source. A
        real data-flow analysis would be a different kind of thing entirely, and the pattern in this
        tree is one assignment immediately above one guarded dot-source -- so anything cleverer would
        be answering a question nobody here asks. A variable this file never assigns yields nothing
        rather than a guess.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    # MEMOISED PER PATH, AND IT IS NOT A MICRO-OPTIMISATION. Get-FixtureDepFinding asks this per
    # (suite, lib) pair, so a lib every fixture copies -- native-capture-lib.ps1 is in seven of the
    # twelve -- was parsed and walked once per suite. Measured on the tree, three runs each: 11.0-13.2s
    # for the suite that drives this, against 8.2-8.7s with the cache and the two targeted walks below,
    # on a gate whose whole budget is ~230s across 30 lanes. What is left is PowerShell's own start-up
    # plus parsing each of the 84 suites once, which no cache can remove.
    #
    # The table is declared at the top of this file rather than initialised here on first use: under
    # Set-StrictMode the `if ($null -eq $script:...)` test IS a read of an unset variable and throws,
    # so the lazy form fails on the very first call it exists to serve.
    #
    # THE KEY IS THE FILE'S IDENTITY, NOT ITS PATH, and that was measured rather than anticipated. A
    # path-only key is correct for the gate -- one report over a tree nothing is writing to -- and
    # wrong for this lib's own suite, which rewrites the same fixture names between sections to make a
    # lib mean something different. Two asserts went red on a stale answer, and the shape of the fix
    # matters: a cache that is only correct while every caller remembers not to rewrite a file is the
    # enforced-by-memory shape, so the timestamp and the length do the remembering.
    $item = Get-Item -LiteralPath $Path
    $key = "$Path|$($item.LastWriteTimeUtc.Ticks)|$($item.Length)"
    if ($script:FixtureDepDotSourceCache.ContainsKey($key)) {
        return @($script:FixtureDepDotSourceCache[$key])
    }

    $ast = Get-FixtureDepAst -Path $Path

    # TWO TARGETED WALKS RATHER THAN ONE FindAll({ $true }). The predicate-true form materialises every
    # node in the file into an array -- for a 2,000-line lib that is the bulk of the cost, and both
    # loops below then filter it down again by type.
    $assignments = @($ast.FindAll({
        $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true))
    $commands = @($ast.FindAll({
        $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true))

    # Assignments first: $name -> the .ps1 leaf its right-hand side names, keyed by the offset it sits
    # at, so a later reassignment can win over an earlier one.
    $assigned = @{}
    foreach ($node in $assignments) {
        $left = $node.Left
        if (-not ($left -is [System.Management.Automation.Language.VariableExpressionAst])) { continue }
        $name = $left.VariablePath.UserPath
        $leaf = ''
        foreach ($lit in @($node.Right.FindAll({
                    $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true))) {
            $candidate = Get-FixtureDepPs1Leaf -Value $lit.Value
            if ($candidate) { $leaf = $candidate }
        }
        if (-not $leaf) { continue }
        if (-not $assigned.ContainsKey($name)) { $assigned[$name] = @() }
        $assigned[$name] += [pscustomobject]@{ Offset = $node.Extent.StartOffset; Leaf = $leaf }
    }

    $found = @()
    foreach ($node in $commands) {
        if ($node.InvocationOperator -ne [System.Management.Automation.Language.TokenKind]::Dot) { continue }

        # Shape one: the path is written out inside the dot-source itself.
        $literalLeaf = ''
        foreach ($lit in @($node.FindAll({
                    $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true))) {
            $candidate = Get-FixtureDepPs1Leaf -Value $lit.Value
            if ($candidate) { $literalLeaf = $candidate }
        }
        if ($literalLeaf) { $found += $literalLeaf; continue }

        # Shape two: the path is in a variable assigned earlier in this same file.
        foreach ($v in @($node.FindAll({
                    $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true))) {
            $name = $v.VariablePath.UserPath
            if (-not $assigned.ContainsKey($name)) { continue }
            $before = @($assigned[$name] | Where-Object { $_.Offset -lt $node.Extent.StartOffset } |
                        Sort-Object Offset)
            if ($before.Count -gt 0) { $found += $before[-1].Leaf }
        }
    }

    $result = @($found | Sort-Object -Unique)
    $script:FixtureDepDotSourceCache[$key] = $result
    return $result
}

# Copy-Item's SWITCH parameters -- the ones that consume no following element. Everything else that
# arrives as a parameter without an attached argument does consume the next element, so the positional
# walk below can tell 'Copy-Item -LiteralPath $a $b' (one positional) from 'Copy-Item $a $b -Force'
# (two). The set is closed and small because the command is fixed; a name missing from it costs one
# skipped positional, which under-reports rather than accuses.
$script:FixtureDepCopyItemSwitch = @(
    'Recurse', 'Force', 'PassThru', 'Container', 'Confirm', 'WhatIf', 'UseTransaction', 'Verbose',
    'Debug', 'ErrorAction', 'WarningAction', 'InformationAction'
)

function Get-CopyItemDestinationAst {
    <#
        The AST(s) that give ONE Copy-Item its destination -- named or positional.

        BOTH SHAPES ARE IN THIS TREE, which is the only reason this is a function rather than a line.
        Most suites write `-Destination (Join-Path $dir '...')`; source-repo-guard.tests.ps1 writes
        `Copy-Item $GuardLib (Join-Path $awayDir 'scripts\lib\source-repo-guard-lib.ps1')` positionally.
        A reader that handles only the named form silently stops treating that suite as a subject at
        all -- which is the same class of silent miss this whole lib exists to remove, so getting it
        wrong here would have been the joke writing itself.

        Positional destination is index 1 (0-based) among the positional arguments: Copy-Item's first
        positional is -Path and its second is -Destination.
    #>
    param([Parameter(Mandatory = $true)]
          [System.Management.Automation.Language.CommandAst]$Command)

    $elements = @($Command.CommandElements)
    $named = @()
    $positional = @()

    # Element 0 is the command name itself.
    for ($i = 1; $i -lt $elements.Count; $i++) {
        $el = $elements[$i]
        if ($el -is [System.Management.Automation.Language.CommandParameterAst]) {
            $name = $el.ParameterName
            if ($null -ne $el.Argument) {
                # -Destination:<value> -- the value is attached to the parameter itself.
                if ($name -eq 'Destination') { $named += $el.Argument }
                continue
            }
            if ($script:FixtureDepCopyItemSwitch -contains $name) { continue }
            if ($i + 1 -lt $elements.Count) {
                if ($name -eq 'Destination') { $named += $elements[$i + 1] }
                $i++   # the next element is this parameter's value, not a positional
            }
            continue
        }
        $positional += $el
    }

    if ($named.Count -gt 0) { return @($named) }
    if ($positional.Count -ge 2) { return @($positional[1]) }
    return @()
}

function Get-FixtureCopiedLibName {
    <#
        Every 'scripts/lib/<name>.ps1' a test suite copies into its fixture tree, as bare leaves.

        THE SUBJECT IS THE -Destination AND ONLY THE -Destination, which is not a detail. Every one of
        these copies reads FROM 'scripts\lib\<x>.ps1' in the real repo, so a reader that takes any
        literal in the command takes the source too -- and then every Copy-Item in the tree looks like
        a fixture lib copy. Measured while building this: that mistake produced two findings on a clean
        tree and both were false, which is the false-positive rate this repo declines a check over.

        THE FIRST OF THOSE TWO IS THE ONE WORTH KNOWING ABOUT, because binding to the destination fixes
        it for the right reason rather than by luck. consumer-check-lib.tests.ps1 copies its lib into a
        FLAT directory that deliberately has no measure-context-lib sibling: that fixture exists to
        prove the guarded load degrades correctly on a mirror built before that lib travelled. Its
        destination is therefore not a scripts/lib tree at all, and it is correctly not a subject here.

        BUT THE SHAPE IT REPRESENTS IS A REAL FUTURE FALSE POSITIVE, and there is deliberately no
        mechanism for it yet: a fixture that omits a dependency ON PURPOSE, inside a scripts/lib tree,
        would be reported and would be right to complain. None exists today. If one appears, the answer
        is a declared opt-out on that suite -- NOT another entry in the exemption list below, which is
        about a different thing entirely.

        Read off the command rather than the line, so a backtick continuation between -LiteralPath and
        -Destination cannot change the answer -- internal-note.tests.ps1 writes every one of its copies
        that way. A suite that copies nothing into a fixture scripts/lib returns nothing and is not a
        subject at all.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    $ast = Get-FixtureDepAst -Path $Path
    $found = @()
    foreach ($node in @($ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true))) {
        if ($node.GetCommandName() -ne 'Copy-Item') { continue }

        foreach ($valueAst in (Get-CopyItemDestinationAst -Command $node)) {
            foreach ($lit in @($valueAst.FindAll({
                        $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true))) {
                $value = [string]$lit.Value
                $normalised = $value.Replace($script:FixtureDepBackslash, $script:FixtureDepForwardSlash)
                if ($normalised -notmatch 'scripts/lib/') { continue }
                $leaf = Get-FixtureDepPs1Leaf -Value $value
                if ($leaf) { $found += $leaf }
            }
        }
    }

    return @($found | Sort-Object -Unique)
}

function Get-FixtureDepFinding {
    <#
        The gap for ONE suite: every lib that some lib it copies dot-sources, and that it does not
        copy itself. Returns a (possibly empty) list of pscustomobjects { Suite, Lib, Missing }.

        THE CLOSURE IS WALKED, NOT ONE LEVEL. If a copied lib pulls in B and B pulls in C, the fixture
        needs all three -- so reporting only B would make the author fix it, re-run, and be told about
        C on the second round. A visited set keeps a cycle from spinning.

        A DEPENDENCY THAT DOES NOT EXIST IN -LibDirectory IS NOT A FINDING. The guarded dot-source is
        there precisely because a lib may legitimately not be present yet, and this lib is not the
        place to have an opinion about a name the tree does not carry.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$SuitePath,
        [Parameter(Mandatory = $true)][string]$LibDirectory
    )

    $copied = @(Get-FixtureCopiedLibName -Path $SuitePath)
    if ($copied.Count -eq 0) { return @() }

    $suiteName = Split-Path -Path $SuitePath -Leaf
    $findings = @()
    $seen = @{}
    $queue = New-Object System.Collections.Queue
    foreach ($c in $copied) { $queue.Enqueue($c) }

    while ($queue.Count -gt 0) {
        $lib = [string]$queue.Dequeue()
        if ($seen.ContainsKey($lib)) { continue }
        $seen[$lib] = $true

        $libPath = Join-Path $LibDirectory $lib
        if (-not (Test-Path -LiteralPath $libPath -PathType Leaf)) { continue }

        foreach ($dep in (Get-DotSourcedLibName -Path $libPath)) {
            if ($dep -eq $lib) { continue }

            # A REPO-OWNED SEAM IS NEITHER REPORTED NOR WALKED. Not reported because the fixture does
            # not owe it (see the list's own note); not walked because it is not part of the fixture,
            # so its own dot-sources are the consumer's business rather than this fixture's debt.
            if ($script:FixtureDepRepoOwnedSeam -contains $dep) { continue }

            if (-not (Test-Path -LiteralPath (Join-Path $LibDirectory $dep) -PathType Leaf)) { continue }
            if ($copied -notcontains $dep) {
                $findings += [pscustomobject]@{ Suite = $suiteName; Lib = $lib; Missing = $dep }
            }
            $queue.Enqueue($dep)
        }
    }

    return @($findings | Sort-Object Lib, Missing -Unique)
}

function Get-FixtureDepReport {
    <#
        Every suite in -TestsDirectory that copies a lib, with its findings -- the whole answer in one
        call, so a gate and a suite cannot disagree about what was examined.

        Returns { Suites, Subjects, Findings }: how many suites were read, how many of them copy a lib
        at all, and the flat finding list. SUBJECTS IS RETURNED BECAUSE A SILENT PASS NEEDS IT: zero
        findings over zero subjects is a reader that found nothing to read, and zero findings over
        thirteen is the tree being clean. The two must never print the same line -- the same reason
        check-plugin-integrity.ps1's span checks print both figures.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$TestsDirectory,
        [Parameter(Mandatory = $true)][string]$LibDirectory
    )

    $suites = @(Get-ChildItem -Path $TestsDirectory -Filter '*.tests.ps1' -File | Sort-Object Name)
    $subjects = 0
    $findings = @()
    foreach ($s in $suites) {
        $copied = @(Get-FixtureCopiedLibName -Path $s.FullName)
        if ($copied.Count -eq 0) { continue }
        $subjects++
        $findings += @(Get-FixtureDepFinding -SuitePath $s.FullName -LibDirectory $LibDirectory)
    }

    return [pscustomobject]@{
        Suites   = $suites.Count
        Subjects = $subjects
        Findings = @($findings)
    }
}
