<#
.SYNOPSIS
    Which sibling libs a lib dot-sources, which libs a file under scripts/tests copies into its
    fixture, and the gap between the two (issues #1693, #1865).

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

    THE DEPENDENCY IS READ THROUGH THE VARIABLE, NOT OFF THE DOT-SOURCE LINE. The shape this repo
    actually uses is:

        $parkPorcelainLib = Join-Path $PSScriptRoot 'git-porcelain-lib.ps1'
        if (Test-Path -LiteralPath $parkPorcelainLib -PathType Leaf) { . $parkPorcelainLib }

    so the dot-source command's own text is `. $parkPorcelainLib` and carries NO filename at all. A
    reader that matches on the dot-source's extent finds nothing -- measured against
    origin/fix/1682-porcelain-line-parse, the only real instance of the class, where the first version
    of this lib missed it outright.

    AND THAT READING IS NOT DONE HERE. script-contract-lib.ps1 already resolves it --
    Get-ScriptDotSourceTargets, with Get-AstPathHints doing the variable half -- so this lib delegates
    and converts the answer to bare leaves. The first version did not, and a second AST walker is
    exactly the "second literal" defect its own sibling issue (#1682) is about; the code review on this
    branch is what caught it. Get-DotSourcedLibName carries the whole argument.

    WHAT IS GENUINELY THIS LIB'S OWN is the other half of the question: which libs a SUITE copies into
    its fixture, which nothing else in the tree reads. That is Get-FixtureCopiedLibName, and it is
    where the two false findings a naive version produced were repaired.

    Pure ASCII (repo convention for .ps1). No Set-StrictMode: dot-sourcing would change the strict
    mode of the calling script.
#>

# THE SHARED DOT-SOURCE WALKER, AND THIS LOAD IS DELIBERATELY UNGUARDED. Every sibling dot-source in
# this tree is wrapped in `if (Test-Path ...)` because those libs travel to consumers, where a mirror
# may predate the file. This one does not travel: it is repo-local, read by one repo-local suite, and a
# missing sibling here is a broken checkout rather than an older consumer -- so it must fail loudly on
# load instead of leaving Get-DotSourcedLibName undefined, which is precisely the silence this whole
# lib exists to remove. Dot-sourcing it twice is harmless if a caller has already loaded it.
. (Join-Path $PSScriptRoot 'script-contract-lib.ps1')

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

        THIS DELEGATES, AND THAT IS THE POINT OF IT. The first version of this function was a second
        AST walker: it found dot-source commands, resolved a variable to its last assignment, and read
        the '.ps1' literal out of the right-hand side. All of that already existed in
        script-contract-lib.ps1 -- Get-ScriptDotSourceTargets, with Get-AstPathHints doing the variable
        resolution -- and that lib's own docstring says why: '$VarMap carries the same shape per
        variable name so ". $configPath" resolves through its assignment, which is how three of the
        four dot-source shapes in this tree are written'.

        SO THE SECOND ENGINE WAS THE DEFECT THIS BRANCH'S SIBLING ISSUE IS ABOUT. #1682 is "the git
        porcelain line parse is a second literal", and writing a rival dot-source resolver in the same
        week would have been the same mistake with a citation attached. Found by the code review on
        this branch rather than by me, which is worth recording: the duplication was invisible from
        inside the file, because both halves read correctly on their own.

        WHAT DELEGATING GAINED, beyond one engine instead of two. Get-ScriptDotSourceTargets already
        handles two shapes the hand-rolled reader did not: a path built from the REPO ROOT rather than
        $PSScriptRoot, and the `& { . $args[0] }` idiom. It also drops a target that resolves to no
        existing file, which is the same judgement Get-FixtureDepFinding was making one layer later.

        WHAT IS LEFT HERE IS THE SHAPE CONVERSION, and it is the whole reason this wrapper exists at
        all rather than the callers calling through: that function answers in absolute paths, and every
        question this lib asks is about a bare leaf, because a fixture's copy list is a list of leaves.
        Split-Path -Leaf is the entire difference.

        -RepoRoot is passed through because that function needs it to try the repo-root base. A caller
        with no repo (this lib's own suite, working in a sandbox) passes the sandbox root, which is the
        honest answer for that tree.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$RepoRoot
    )

    # THE PARSE FAILURE IS STILL THIS LIB'S OPINION, NOT THE SHARED WALKER'S. Get-ScriptDotSourceTargets
    # returns @() for a file it cannot parse, which is right for its own caller -- a contract check
    # asking "is this lib reachable" must not fall over on a syntax error elsewhere. Here an empty
    # answer means "this lib needs nothing copied", which is the exact silence the gate exists to
    # remove, so a file that does not parse is thrown on before the walk is asked.
    $null = Get-FixtureDepAst -Path $Path

    return @(Get-ScriptDotSourceTargets -Path $Path -RepoRoot $RepoRoot |
                ForEach-Object { Split-Path -Path $_ -Leaf } |
                Sort-Object -Unique)
}

# Copy-Item's SWITCH parameters -- the ones that consume no following element. Everything else that
# arrives as a parameter without an attached argument does consume the next element, so the positional
# walk below can tell 'Copy-Item -LiteralPath $a $b' (one positional) from 'Copy-Item $a $b -Force'
# (two). The set is closed and small because the command is fixed; a name missing from it costs one
# skipped positional, which under-reports rather than accuses.
# -ErrorAction, -WarningAction and -InformationAction are NOT in this list and must not be added: they
# are common parameters that take a VALUE (-ErrorAction Stop), unlike -Verbose and -Debug, which are
# switches. They were here, and the code review caught it: `Copy-Item -ErrorAction Stop $src (Join-Path
# $dir 'scripts\lib\a-lib.ps1')` lost its destination entirely -- measured, the reader returned nothing
# at all -- because 'Stop' was counted as the first positional and the real destination became the
# second. No suite in the tree writes that today, which is exactly why it needed a review to find and
# an assert to keep.
$script:FixtureDepCopyItemSwitch = @(
    'Recurse', 'Force', 'PassThru', 'Container', 'Confirm', 'WhatIf', 'UseTransaction', 'Verbose',
    'Debug'
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

    # THE PREFILTER IS FREE AND IT IS NOT A MICRO-OPTIMISATION EITHER. This runs over EVERY suite in the
    # directory to decide which ones are subjects, and only 18 of 84 files contain the string
    # 'Copy-Item' at all -- so 66 of them were being parsed to prove they have no Copy-Item in them.
    # Measured by the cost review: 725 ms for parse-plus-walk over all 84, against 275-281 ms with this
    # line, a 2.6x cut for one substring test. It cannot change the answer: a file with no occurrence of
    # the string cannot hold a Copy-Item CommandAst, and a file that only mentions it in a comment costs
    # one harmless parse.
    if (([System.IO.File]::ReadAllText($Path)).IndexOf('Copy-Item', [System.StringComparison]::Ordinal) -lt 0) {
        return @()
    }


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
        The gap for ONE fixture builder: every lib that some lib it copies dot-sources, and that it
        does not copy itself. Returns a (possibly empty) list of pscustomobjects { File, Lib, Missing }.

        THE SUBJECT IS A FILE THAT COPIES A LIB, WHICH IS USUALLY BUT NOT ALWAYS A SUITE. The parameter
        was -SuitePath and the field was Suite until #1865 widened the scan set; both now name what
        they actually hold, since check-plugin-integrity-fixture.ps1 is a builder four suites share and
        no suite itself.

        THE CLOSURE IS WALKED, NOT ONE LEVEL. If a copied lib pulls in B and B pulls in C, the fixture
        needs all three -- so reporting only B would make the author fix it, re-run, and be told about
        C on the second round. A visited set keeps a cycle from spinning.

        A DEPENDENCY THAT DOES NOT EXIST IN -LibDirectory IS NOT A FINDING. The guarded dot-source is
        there precisely because a lib may legitimately not be present yet, and this lib is not the
        place to have an opinion about a name the tree does not carry.

        -CopiedLib LETS A CALLER THAT ALREADY ASKED HAND THE ANSWER IN. Get-FixtureDepReport computes
        the copy list to decide whether a file is a subject at all, and then called this, which read
        the same file again -- measured by the cost review at 447 ms against 257 ms over the twelve real
        subjects, so ~190 ms of every run went on parsing each subject twice. Omitted, it reads the
        list itself, which keeps this function usable on its own.

        -RepoRoot is the base Get-ScriptDotSourceTargets needs for a dot-source built from the repo root
        rather than from $PSScriptRoot; it is not used for anything else here.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$LibDirectory,
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [string[]]$CopiedLib
    )

    # @() AROUND THE WHOLE if, not inside its branches: an if-expression assigned to a variable is
    # unwrapped, so a single-element result arrives as a bare string and .Count below then throws under
    # Set-StrictMode. The inner @() are not enough and it looked like they were.
    $copied = @(if ($PSBoundParameters.ContainsKey('CopiedLib')) { $CopiedLib }
                else { Get-FixtureCopiedLibName -Path $Path })
    if ($copied.Count -eq 0) { return @() }

    $fileName = Split-Path -Path $Path -Leaf
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

        foreach ($dep in (Get-DotSourcedLibName -Path $libPath -RepoRoot $RepoRoot)) {
            if ($dep -eq $lib) { continue }

            # A REPO-OWNED SEAM IS NEITHER REPORTED NOR WALKED. Not reported because the fixture does
            # not owe it (see the list's own note); not walked because it is not part of the fixture,
            # so its own dot-sources are the consumer's business rather than this fixture's debt.
            if ($script:FixtureDepRepoOwnedSeam -contains $dep) { continue }

            if (-not (Test-Path -LiteralPath (Join-Path $LibDirectory $dep) -PathType Leaf)) { continue }
            if ($copied -notcontains $dep) {
                $findings += [pscustomobject]@{ File = $fileName; Lib = $lib; Missing = $dep }
            }
            $queue.Enqueue($dep)
        }
    }

    return @($findings | Sort-Object Lib, Missing -Unique)
}

function Get-FixtureDepReport {
    <#
        Every file in -TestsDirectory that copies a lib, with its findings -- the whole answer in one
        call, so a gate and a suite cannot disagree about what was examined.

        Returns { Files, Subjects, Findings }: how many files were read, how many of them copy a lib
        at all, and the flat finding list. SUBJECTS IS RETURNED BECAUSE A SILENT PASS NEEDS IT: zero
        findings over zero subjects is a reader that found nothing to read, and zero findings over
        thirteen is the tree being clean. The two must never print the same line -- the same reason
        check-plugin-integrity.ps1's span checks print both figures.

        EVERY '.ps1', NOT ONLY '*.tests.ps1' (issue #1865). The filter was the suite-name pattern until
        September 11, 2026, on the reasonable-sounding ground that the class this gate measures is "a
        SUITE copies a lib into a fixture". What that misses is the case where the copying has been
        FACTORED OUT of the suites, and the tree already holds one: check-plugin-integrity-fixture.ps1
        is not a suite by name, copies fourteen libs, and is shared by the four
        check-plugin-integrity-{links,commands,docs,entries} suites -- so the one builder here that four
        suites depend on was the one the gate could not see.

        MEASURED ON #1860's BRANCH, which gave entry-scaffold-lib.ps1 a new unconditional sibling: this
        gate reported 7 findings, named all seven suites, and was right about every one of them -- and
        the four lint suites then failed anyway, 4 of 93 asserts red, because check-plugin-integrity.ps1
        died on lib load before printing a finding. That is the identical failure mode #1650 records one
        lib earlier and the identical one #1693 built this gate to prevent. The gate found the seven it
        could see and was structurally blind to the eighth.

        AND WIDENING IS BORN GREEN, which is why it is this repair rather than the more thorough one.
        The three other non-suite files here (fresh-consumer, round-baseline and round-tally .measure.ps1)
        contain no Copy-Item at all, so they are not subjects and cost one substring test each; the
        builder itself reports 0 findings today. The alternative weighed in #1865 -- follow each suite's
        own dot-sources, so a builder is reached because a suite LOADS it rather than because of where it
        sits -- is strictly more correct and strictly more code, and buys nothing this tree can measure
        today. It is the repair to reach for on the day a builder moves out of scripts/tests.

        -RepoRoot is passed through to the dot-source walker; -LibDirectory is where a dependency is
        looked for. They are separate parameters because this lib's own suite points them at a sandbox
        whose layout is not a repo's.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$TestsDirectory,
        [Parameter(Mandatory = $true)][string]$LibDirectory,
        [Parameter(Mandatory = $true)][string]$RepoRoot
    )

    $files = @(Get-ChildItem -Path $TestsDirectory -Filter '*.ps1' -File | Sort-Object Name)
    $subjects = 0
    $findings = @()
    foreach ($f in $files) {
        # Read ONCE and handed on -- see Get-FixtureDepFinding's -CopiedLib for the measurement.
        $copied = @(Get-FixtureCopiedLibName -Path $f.FullName)
        if ($copied.Count -eq 0) { continue }
        $subjects++
        $findings += @(Get-FixtureDepFinding -Path $f.FullName -LibDirectory $LibDirectory `
                                             -RepoRoot $RepoRoot -CopiedLib $copied)
    }

    return [pscustomobject]@{
        Files    = $files.Count
        Subjects = $subjects
        Findings = @($findings)
    }
}
