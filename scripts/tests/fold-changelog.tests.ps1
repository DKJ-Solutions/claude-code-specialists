<#
.SYNOPSIS
    Regression tests for scripts/release/fold-changelog-entry.ps1 -- which files it folds, where in
    CHANGELOG.md's flat list it puts them, and what it does and does not strip on the way.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Integration style -- runs the REAL fold
    script (copied into a throwaway temp repo root, so nothing touches the own working copy) and
    asserts on exit code + which files survive + CHANGELOG content.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/fold-changelog.tests.ps1

    THE FIXTURE CHANGELOG HAS NO SECTION HEADINGS, and that is the change this suite was rewritten for
    (August 5, 2026). CHANGELOG.md used to carry one '## Tier N - Pull Requests' section per tier, named by
    a repo-owned seam, and most of this file's fixture machinery existed to model which sections a consumer
    had declared. The document is a FLAT RANKED LIST now: intro, then one '## ' per change. So the seam, the
    Keep-a-Changelog variant, the "wrong heading stops cleanly" refusal and the three-section fixture are all
    gone -- not relaxed, but structurally unreachable, because there is no heading name left to get wrong.

    What replaces them is the assert those tests were standing in for: the entry lands BELOW the intro and
    at its RANKED position, and the intro is never written over.

    Two guards worth keeping in mind while reading:

      * the original bug this file was written for -- fold-all folding any root *.md that was not in a tiny
        denylist, so CONTRIBUTING.md and SECURITY.md got folded and removed. The fix keys off the entry
        format itself, and since this change that means an H2 heading (an H3 for an entry file written
        before it) against a meta doc's H1.
      * the pre-pass: a fold-all run writes one entry at a time, so a refusal has to happen before the
        first write or it leaves a half-state to unpick by hand on main.

    The fold script calls `gh pr list` per folded entry for PR-number enrichment; with no matching
    PR that simply returns nothing and the entry folds without a #NN -- so these tests do not depend
    on a PR existing. Everything under test here happens regardless of gh.

    Pure ASCII (repo convention for .ps1). The middot in a pre-format entry heading is built from its
    codepoint.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot         = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$FoldSrc          = Join-Path $RepoRoot 'scripts\release\fold-changelog-entry.ps1'
$RepoConfigSrc    = Join-Path $RepoRoot 'scripts\repo-config.ps1'
$NativeCaptureSrc = Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1'
# The entry format: the heading levels the fold recognises and normalises to, the impact table it reads the
# rank from, and the ranked insert offset. A $PSScriptRoot-relative sibling of the fold script, so the
# fixture has to carry it.
$EntryScaffoldSrc = Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1'
# Dot-sourced into the RUNNER as well, not only copied into each fixture: the branch/ cases build their
# fixture files with the real formatters and assert with the real predicates, so a change to the format
# breaks the script and its test together instead of leaving the test asserting a shape nothing writes.
. $EntryScaffoldSrc

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

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red
    }
}

$script:fixtures = @()
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

# The fixture changelog's intro, kept as one variable so the tests can assert it came through untouched
# rather than re-describing it. Deliberately contains NO '## ' line: in the flat model the intro is
# everything above the first entry heading, so an intro that carried one would move the boundary.
$script:FixtureIntro = @(
    '# Changelog',
    '',
    'Everything merged since the last release, furthest reach first. Every release ever cut is listed',
    'in releases/README.md.',
    ''
) -join "`n"

function New-FoldFixture {
    <#
        A throwaway repo root with the real fold script + its repo-owned/sibling dependencies
        (repo-config.ps1 for Get-RepoName, native-capture-lib.ps1 for the gh call, entry-scaffold-lib.ps1
        for the entry format) and a CHANGELOG holding only its intro. release-lib.ps1 is deliberately NOT
        copied, so the optional 'Plugins:' detection is simply skipped.

        repo-config.ps1 is copied VERBATIM now. It used to be rewritten per fixture -- stripping the tier
        map, adding back the legacy single-heading getter -- because which changelog sections a repo declared
        was the subject of half these tests. The fold reads no section seam at all any more, so there is
        nothing left to vary.
    #>
    param([Parameter(Mandatory = $true)][string]$Label)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("fold-test-$PID-$Label")
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\release') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib')     -Force | Out-Null
    Copy-Item -LiteralPath $FoldSrc          -Destination (Join-Path $dir 'scripts\release\fold-changelog-entry.ps1') -Force
    Copy-Item -LiteralPath $NativeCaptureSrc -Destination (Join-Path $dir 'scripts\lib\native-capture-lib.ps1')       -Force
    Copy-Item -LiteralPath $EntryScaffoldSrc -Destination (Join-Path $dir 'scripts\lib\entry-scaffold-lib.ps1')       -Force
    Copy-Item -LiteralPath $RepoConfigSrc    -Destination (Join-Path $dir 'scripts\repo-config.ps1')                  -Force

    [System.IO.File]::WriteAllText((Join-Path $dir 'CHANGELOG.md'), $script:FixtureIntro, $Utf8NoBom)
    $script:fixtures += $dir
    return $dir
}

function New-EntryFile {
    <#
        An entry file as new-changelog-entry.ps1 writes one since August 5, 2026: an H2 for the change, then
        the three named H3 sections. -Rows sets the impact table's data rows (the scaffold's own tier-0 row
        by default), so a test can declare a reach and a significance without hand-building the file.
    #>
    param(
        [string]$Dir, [string]$Name, [string]$Title,
        [string]$Rows = '| 0 | - | - |',
        [string]$Type = 'Feat',
        [string]$ExtraBody = ''
    )
    $lines = @("## $Title", '', '### What does this change do?', '', 'Demo entry body.')
    if ($ExtraBody) { $lines += @('', $ExtraBody) }
    $lines += @(
        '', '### Who is this for', '',
        '| Tier | Significance | Why |', '|---|---|---|', $Rows,
        '', '### Type of change', '', $Type
    )
    [System.IO.File]::WriteAllText((Join-Path $Dir $Name), (($lines -join "`n") + "`n"), $Utf8NoBom)
}

function New-LegacyEntryFile {
    <#
        An entry file in the shape written BEFORE this format: an H3 heading carrying the type (and a
        scaffolded date) as middot fields, with a 'Tier: N' line under it instead of an impact table.

        NOT A HISTORICAL CURIOSITY. An entry file lives only on a branch, so any branch created before this
        change still carries one -- this repo had exactly such a branch parked on the remote when the change
        was written. -NoTierLine leaves the line out, which is the undeclared (= tier 0) case.
    #>
    param([string]$Dir, [string]$Name, [string]$Title, [string]$Tier = '0', [switch]$NoTierLine, [string]$ExtraBody = '')
    $md = [char]0x00B7
    $tierLine = if ($NoTierLine) { '' } else { "Tier: $Tier`n`n" }
    $body = "### $Title $md Feat $md 2026-01-01`n`n$tierLine" + "Demo entry body.`n" + $ExtraBody
    [System.IO.File]::WriteAllText((Join-Path $Dir $Name), $body, $Utf8NoBom)
}

function New-DocFile {
    # An H1 markdown doc (a meta file), NOT an entry.
    param([string]$Dir, [string]$Name, [string]$Heading)
    [System.IO.File]::WriteAllText((Join-Path $Dir $Name), "# $Heading`n`nSome prose.`n", $Utf8NoBom)
}

function Get-Changelog {
    param([string]$Dir)
    return [System.IO.File]::ReadAllText((Join-Path $Dir 'CHANGELOG.md'))
}

function Get-EntryOrder {
    <#
        The entry headings in document order -- which is the ONE thing the fold decides now that there are no
        sections to file into. Asserted as an ordered list rather than as "the title appears somewhere",
        because the latter passes on every possible ordering, including the reverse.
    #>
    param([string]$Changelog)
    return @([regex]::Matches($Changelog, '(?m)^## (.+)$') | ForEach-Object { $_.Groups[1].Value.Trim() })
}

function Get-ChangelogIntro {
    <# Everything above the first entry heading. The fold must never write into this. #>
    param([string]$Changelog)
    $m = ([regex]'(?m)^## ').Match($Changelog)
    if (-not $m.Success) { return $Changelog }
    return $Changelog.Substring(0, $m.Index)
}

function Initialize-FoldGitRepo {
    <# Turn a fixture into a real git repo with the baseline committed, so -Commit has something to
       commit ONTO.

       Identity and autocrlf are set LOCALLY. Identity, because a machine without a global user.email
       would otherwise fail inside the script under test and read as a defect in it. autocrlf, because
       git's "LF will be replaced by CRLF" warning goes to stderr, and on Windows PowerShell that is
       enough to fail the suite for a reason that has nothing to do with folding.

       NO '2>&1' ON A NATIVE COMMAND -- the #107 pitfall this repo documents and that its own shared-
       scripts guard exists to catch. Under ErrorActionPreference=Stop a single stderr line from git
       becomes a terminating NativeCommandError before any exit code is read. EAP is dropped to Continue
       for the duration instead. #>
    param([Parameter(Mandatory = $true)][string]$Dir)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $Dir init --quiet                          | Out-Null
        & git -C $Dir config user.name  'fold test'         | Out-Null
        & git -C $Dir config user.email 'fold@test.invalid' | Out-Null
        & git -C $Dir config core.autocrlf false            | Out-Null
        & git -C $Dir add -A                                | Out-Null
        & git -C $Dir commit -m 'baseline' --quiet          | Out-Null
    } finally { $ErrorActionPreference = $prevEap }
}

function Invoke-Git {
    <# Read a fact back out of a fixture repo. Same EAP discipline as above, for the same reason. #>
    param([Parameter(Mandatory = $true)][string]$Dir, [Parameter(Mandatory = $true)][string[]]$GitArgs)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        return @(& git -C $Dir @GitArgs)
    } finally { $ErrorActionPreference = $prevEap }
}

function Invoke-Fold {
    param([Parameter(Mandatory = $true)][string]$Dir, [string]$Branch, [string[]]$ExtraArgs = @())
    $scriptPath = Join-Path $Dir 'scripts\release\fold-changelog-entry.ps1'
    $callArgs = @('-RepoRoot', $Dir)
    if ($PSBoundParameters.ContainsKey('Branch')) { $callArgs += @('-Branch', $Branch) }
    $callArgs += $ExtraArgs
    $prevPd  = $env:CLAUDE_PROJECT_DIR
    $prevEap = $ErrorActionPreference
    try {
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @callArgs 2>&1
        $code = $LASTEXITCODE
    } finally {
        if ($null -ne $prevPd) { $env:CLAUDE_PROJECT_DIR = $prevPd }
        $ErrorActionPreference = $prevEap
    }
    return [pscustomobject]@{ ExitCode = $code; Output = ($out -join "`n") }
}

# ---------------------------------------------------------------------------------------------------
Write-Host "fold-all -- meta docs survive, real entry folds" -ForegroundColor Cyan
$dir = New-FoldFixture -Label 'metasafe'
New-EntryFile -Dir $dir -Name 'feat-demo-thing.md' -Title 'Demo thing'
New-DocFile   -Dir $dir -Name 'CONTRIBUTING.md'     -Heading 'Contributing'
New-DocFile   -Dir $dir -Name 'SECURITY.md'         -Heading 'Security Policy'
New-DocFile   -Dir $dir -Name 'CLAUDE.md'           -Heading 'Project guide'
$r = Invoke-Fold -Dir $dir
$changelogText = Get-Changelog -Dir $dir

Assert-True ($r.ExitCode -eq 0)                                              'fold-all exits 0'
Assert-True (-not (Test-Path (Join-Path $dir 'feat-demo-thing.md')))        'the genuine entry file is removed'
Assert-True ($changelogText -match 'Demo thing')                            'the entry is folded into CHANGELOG'
Assert-True (Test-Path (Join-Path $dir 'CONTRIBUTING.md'))                  'CONTRIBUTING.md survives (not folded)'
Assert-True (Test-Path (Join-Path $dir 'SECURITY.md'))                      'SECURITY.md survives (not folded)'
Assert-True (Test-Path (Join-Path $dir 'CLAUDE.md'))                        'CLAUDE.md survives (reserved)'
Assert-True ($changelogText -notmatch 'Security Policy')                    'meta content did NOT leak into CHANGELOG'
Assert-True ($changelogText -notmatch '(?m)^# Contributing')               'CONTRIBUTING body did NOT leak into CHANGELOG'
# THE ENTRY'S OWN SECTIONS CAME THROUGH AT THEIR OWN LEVEL. A replace-all rather than a count-1 would have
# flattened these three into H2s and turned one entry into four.
Assert-Equal 1 @(Get-EntryOrder -Changelog $changelogText).Count 'the folded entry is exactly ONE entry heading, not four'
foreach ($section in @('What does this change do?', 'Who is this for', 'Type of change')) {
    Assert-True ($changelogText -match ('(?m)^### ' + [regex]::Escape($section) + '\s*$')) "the '$section' section kept its own level"
}
# THE HEADING IS LEFT EXACTLY AS THE AUTHOR WROTE IT (Dave, August 5, 2026). The fold used to prepend
# '#NN <midDot> ' to the title; the number is on the closing line now, where the url makes it clickable.
# Asserted as the WHOLE heading line, anchored: a prefix match would pass with anything prepended.
Assert-Equal 'Demo thing' @(Get-EntryOrder -Changelog $changelogText)[0] 'the heading is exactly the title -- nothing is prepended to it'
Assert-True ($changelogText -notmatch ('(?m)^## #\d+ ' + [regex]::Escape([char]0x00B7))) 'no entry heading carries a PR number'
# And the number is not LOST, which is the whole reason it could leave the heading. This fixture has no PR
# (the fold's gh call finds nothing by design here), so the assert is on the mechanism rather than a number:
# the fold writes the number in exactly one place, and that place is the closing line.
$foldSrcText = [System.IO.File]::ReadAllText($FoldSrc, [System.Text.Encoding]::UTF8)
Assert-True ($foldSrcText -match 'Format-EntryFoldFooter') 'the closing line is still what carries the PR number and the merge date'
Assert-True ($foldSrcText -notmatch '\$entryHashes #\$num') 'and the heading prepend is gone from the source, not merely unused'

# ---------------------------------------------------------------------------------------------------
Write-Host "The intro is written below, never over" -ForegroundColor Cyan
#      There is no configured heading to insert after any more, so the boundary between the intro and the
#      list is derived structurally -- the first entry heading. Getting that wrong writes an entry into the
#      middle of the intro, which is why it is asserted rather than assumed.
Assert-True ((Get-ChangelogIntro -Changelog $changelogText).TrimEnd() -eq $script:FixtureIntro.TrimEnd()) `
    'the intro is byte-identical after the fold'
Assert-True ((Get-Changelog -Dir $dir).IndexOf('Demo thing') -gt $script:FixtureIntro.TrimEnd().Length) `
    'and the entry sits below all of it'

# ---------------------------------------------------------------------------------------------------
Write-Host "A changelog with nothing pending yet -- the first entry opens the list" -ForegroundColor Cyan
#      This replaces the retired "could not find the '## Pull Requests' heading -- stopping" refusal. That
#      path existed because the fold needed a configured heading to exist in the file; it now needs none, so
#      the case it refused over is the ordinary empty-list case and must simply work.
$dirE = New-FoldFixture -Label 'emptylist'
New-EntryFile -Dir $dirE -Name 'feat-first-ever.md' -Title 'The first one'
$rE = Invoke-Fold -Dir $dirE
$clE = Get-Changelog -Dir $dirE
Assert-True ($rE.ExitCode -eq 0)                     'empty list: exits 0 rather than refusing over a missing heading'
Assert-Equal 'The first one' (@(Get-EntryOrder -Changelog $clE))[0] 'empty list: the entry becomes the list'
# THE BLANK LINE IS ENSURED, NOT ASSUMED. An intro whose last line had no blank line after it would leave
# '...releases/README.md.## The first one' -- which markdown renders as one paragraph and no heading at all,
# so nothing would look broken until a parser went looking for the entry.
Assert-True ($clE -match "(?m)^\s*$[\r\n]+## The first one") 'empty list: with a blank line between the intro and the heading'

# ---------------------------------------------------------------------------------------------------
Write-Host "fold-all -- a consumer-extended prefix still folds" -ForegroundColor Cyan
$dir2 = New-FoldFixture -Label 'extprefix'
New-EntryFile -Dir $dir2 -Name 'style-tweak-colors.md' -Title 'Tweak colors'
$r2 = Invoke-Fold -Dir $dir2
Assert-True ($r2.ExitCode -eq 0)                                            'fold-all (ext prefix) exits 0'
Assert-True (-not (Test-Path (Join-Path $dir2 'style-tweak-colors.md')))    'extended-prefix entry is folded (not prefix-gated)'
Assert-True ((Get-Changelog -Dir $dir2) -match 'Tweak colors')             'extended-prefix entry lands in CHANGELOG'

# ---------------------------------------------------------------------------------------------------
Write-Host "fold-all -- an H1 doc with a hyphenated name is NOT folded" -ForegroundColor Cyan
$dir3 = New-FoldFixture -Label 'hyphendoc'
New-DocFile -Dir $dir3 -Name 'my-loose-notes.md' -Heading 'My loose notes'
$r3 = Invoke-Fold -Dir $dir3
Assert-True ($r3.ExitCode -eq 0)                                            'fold-all (hyphen doc) exits 0'
Assert-True (Test-Path (Join-Path $dir3 'my-loose-notes.md'))               'a hyphenated H1 doc is not treated as an entry'

# ---------------------------------------------------------------------------------------------------
Write-Host "-Branch mode -- folds exactly the named entry" -ForegroundColor Cyan
$dir4 = New-FoldFixture -Label 'branchmode'
New-EntryFile -Dir $dir4 -Name 'fix-explicit-target.md' -Title 'Explicit target'
New-DocFile   -Dir $dir4 -Name 'CONTRIBUTING.md'        -Heading 'Contributing'
$r4 = Invoke-Fold -Dir $dir4 -Branch 'fix/explicit-target'
Assert-True ($r4.ExitCode -eq 0)                                            '-Branch mode exits 0'
Assert-True (-not (Test-Path (Join-Path $dir4 'fix-explicit-target.md')))   '-Branch folds the named entry'
Assert-True ((Get-Changelog -Dir $dir4) -match 'Explicit target')          '-Branch entry lands in CHANGELOG'
Assert-True (Test-Path (Join-Path $dir4 'CONTRIBUTING.md'))                'CONTRIBUTING.md untouched in -Branch mode'

# ---------------------------------------------------------------------------------------------------
Write-Host "Committing is opt-in, and the default is unchanged" -ForegroundColor Cyan
#      The fold has always left its result uncommitted. That stays the default: this commit lands on the
#      main branch under a named exception, so it has to be asked for.
$dir8 = New-FoldFixture -Label 'nocommit'
Initialize-FoldGitRepo -Dir $dir8
New-EntryFile -Dir $dir8 -Name 'fix-no-commit.md' -Title 'Not committed'
$r8 = Invoke-Fold -Dir $dir8
Assert-True ($r8.ExitCode -eq 0)                                            'default: exits 0'
$status8 = (Invoke-Git -Dir $dir8 -GitArgs @('status', '--porcelain')) -join "`n"
Assert-True ($status8 -match 'CHANGELOG\.md')                              'default: the fold is left in the working tree, uncommitted'
Assert-True (@(Invoke-Git -Dir $dir8 -GitArgs @('log', '--oneline')).Count -eq 1) 'default: no commit was made'

# ---------------------------------------------------------------------------------------------------
Write-Host "-Commit commits the fold, and names the branch and PR in the subject" -ForegroundColor Cyan
#      Entry file created BEFORE the repo is initialised, so it is tracked -- which mirrors the real
#      flow, where the entry was committed on the branch and arrived on main with the merge.
$dir9 = New-FoldFixture -Label 'commit'
New-EntryFile -Dir $dir9 -Name 'fix-commits-itself.md' -Title 'Commits itself'
Initialize-FoldGitRepo -Dir $dir9
$r9 = Invoke-Fold -Dir $dir9 -ExtraArgs @('-Commit')
Assert-True ($r9.ExitCode -eq 0)                                            '-Commit: exits 0'
$subject9 = ((Invoke-Git -Dir $dir9 -GitArgs @('log', '-1', '--pretty=%s')) -join '').Trim()
Assert-True ($subject9 -match '^chore: fold changelog entry fix/commits-itself') `
    '-Commit: the subject follows the established format and names the branch'
Assert-True ((((Invoke-Git -Dir $dir9 -GitArgs @('status', '--porcelain')) -join '').Trim()) -eq '') `
    '-Commit: the working tree is clean afterwards -- nothing half-done is left behind'

# THE SCOPE PROPERTY, which is the whole reason this may commit to main at all. An unrelated modified
# file -- and one already STAGED, which is the case a plain 'git commit' would sweep in -- must not end
# up in the fold commit.
$dir10 = New-FoldFixture -Label 'commitscope'
New-EntryFile -Dir $dir10 -Name 'fix-scope.md' -Title 'Scoped'
Initialize-FoldGitRepo -Dir $dir10
[System.IO.File]::WriteAllText((Join-Path $dir10 'UNRELATED.md'), "# Not part of the fold`n", $Utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path $dir10 'STAGED.md'),    "# Staged before the fold ran`n", $Utf8NoBom)
Invoke-Git -Dir $dir10 -GitArgs @('add', 'STAGED.md') | Out-Null
$r10 = Invoke-Fold -Dir $dir10 -ExtraArgs @('-Commit')
Assert-True ($r10.ExitCode -eq 0)                                           'scope: exits 0'
$touched10 = @((Invoke-Git -Dir $dir10 -GitArgs @('show', '--name-only', '--pretty=format:', 'HEAD')) | Where-Object { $_ })
Assert-True ($touched10.Count -eq 2)                                        'scope: the commit holds exactly two paths'
Assert-True (($touched10 -contains 'CHANGELOG.md') -and ($touched10 -contains 'fix-scope.md')) `
    'scope: and they are CHANGELOG.md plus the entry file'
Assert-True ($touched10 -notcontains 'STAGED.md')                          'scope: a file staged before the run is NOT swept into the fold commit'
Assert-True ($touched10 -notcontains 'UNRELATED.md')                       'scope: and neither is an unrelated modified file'

# ---------------------------------------------------------------------------------------------------
Write-Host "The entry file's deletion is part of the commit, not left dangling" -ForegroundColor Cyan
#      The fold removes the entry file from disk. If the commit recorded only CHANGELOG.md, the deletion
#      would sit unstaged afterwards -- an unfolded-looking entry file returning on the next checkout,
#      which is exactly the silent half-state this repo keeps rediscovering.
$statusKind10 = (Invoke-Git -Dir $dir10 -GitArgs @('show', '--name-status', '--pretty=format:', 'HEAD')) -join "`n"
Assert-True ($statusKind10 -match '(?m)^D\s+fix-scope\.md')                'the entry file is recorded as deleted in the commit'

# ---------------------------------------------------------------------------------------------------
Write-Host "An entry git never tracked does not break the commit" -ForegroundColor Cyan
#      Found by this suite before it reached anyone: naming an untracked path makes 'git commit' fail on
#      the pathspec -- and by then the fold has already deleted the file, so the run ends with the
#      changelog updated, the entry gone and nothing committed. The normal flow never hits it (the entry
#      arrives on main with the merge), which is precisely why it would have waited for the one time
#      somebody folded an entry they had not committed.
$dir11 = New-FoldFixture -Label 'untracked'
Initialize-FoldGitRepo -Dir $dir11
New-EntryFile -Dir $dir11 -Name 'fix-never-committed.md' -Title 'Never committed'
$r11 = Invoke-Fold -Dir $dir11 -ExtraArgs @('-Commit')
Assert-True ($r11.ExitCode -eq 0)                                          'untracked entry: exits 0 rather than failing on the pathspec'
Assert-True ($r11.Output -match 'git never tracked them')                  'untracked entry: and says which file was left out of the commit'
$touched11 = @((Invoke-Git -Dir $dir11 -GitArgs @('show', '--name-only', '--pretty=format:', 'HEAD')) | Where-Object { $_ })
Assert-True ($touched11 -contains 'CHANGELOG.md')                          'untracked entry: the changelog is still committed'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $dir11 'fix-never-committed.md'))) `
    'untracked entry: and the entry file is still folded away'

# ===================================================================================================
# THE ORDER OF THE FLAT LIST: tier first, significance second (Dave, August 5, 2026; issue #467)
# ===================================================================================================
# This is what the three '## Tier N - Pull Requests' headings used to communicate visually, kept as an
# ordering rather than as structure. The unit tests in entry-scaffold.tests.ps1 prove the offset function;
# these prove the FOLD uses it, through the real script, against a real file.

Write-Host "Significance orders entries within a tier" -ForegroundColor Cyan
$dirS = New-FoldFixture -Label 'impact-order'
# Folded LOW first, then middling, then HIGH -- so a fold that merely prepends (the pre-ranking behaviour)
# would leave them in exactly the reverse of the wanted order. Only real ordering can pass this.
New-EntryFile -Dir $dirS -Name 'feat-low.md'  -Title 'Least consequential' -Rows '| 1 | 1 | cosmetic |'
$rLow = Invoke-Fold -Dir $dirS -Branch 'feat/low'
New-EntryFile -Dir $dirS -Name 'feat-mid.md'  -Title 'Middling'            -Rows '| 1 | 3 | a clear improvement |'
$rMid = Invoke-Fold -Dir $dirS -Branch 'feat/mid'
New-EntryFile -Dir $dirS -Name 'feat-high.md' -Title 'Most consequential'  -Rows '| 1 | 5 | the reader must act |'
$rHigh = Invoke-Fold -Dir $dirS -Branch 'feat/high'
Assert-True (($rLow.ExitCode -eq 0) -and ($rMid.ExitCode -eq 0) -and ($rHigh.ExitCode -eq 0)) 'impact order: all three folds exit 0'
$orderS = @(Get-EntryOrder -Changelog (Get-Changelog -Dir $dirS))
Assert-Equal 'Most consequential' $orderS[0] 'impact order: significance 5 leads'
Assert-Equal 'Middling'           $orderS[1] 'impact order: then 3'
Assert-Equal 'Least consequential' $orderS[2] 'impact order: then 1 -- so the fold ordered, not prepended'

Write-Host "The tier is the FIRST key -- reach beats weight" -ForegroundColor Cyan
#      The failure this guards is the one measured on the offset function's first run: a repo-internal change
#      leading the document. A tier-0 entry with the top score must still sink below a tier-1 entry with the
#      bottom one, or the flat list has lost the distinction the three headings used to make.
$dirT = New-FoldFixture -Label 'tier-order'
New-EntryFile -Dir $dirT -Name 'chore-internal.md' -Title 'Repo internal only' -Rows '| 0 | - | - |'
Invoke-Fold -Dir $dirT -Branch 'chore/internal' | Out-Null
New-EntryFile -Dir $dirT -Name 'docs-colleague.md' -Title 'For colleagues' -Rows '| 1 | 1 | barely anything |'
Invoke-Fold -Dir $dirT -Branch 'docs/colleague' | Out-Null
New-EntryFile -Dir $dirT -Name 'feat-consumer.md' -Title 'Consumer facing' -Rows "| 2 | 2 | small |`n| 1 | 2 | small |"
$rT = Invoke-Fold -Dir $dirT -Branch 'feat/consumer'
Assert-True ($rT.ExitCode -eq 0) 'tier order: exits 0'
$orderT = @(Get-EntryOrder -Changelog (Get-Changelog -Dir $dirT))
Assert-Equal 'Consumer facing'    $orderT[0] 'tier order: the tier-2 entry leads on a score of 2'
Assert-Equal 'For colleagues'     $orderT[1] 'tier order: the tier-1 entry follows on a score of 1'
Assert-Equal 'Repo internal only' $orderT[2] 'tier order: and the tier-0 entry sinks, whatever it scores'

# ===================================================================================================
# WHAT THE FOLD CARRIES, AND WHAT IT NO LONGER CONSUMES
# ===================================================================================================
# A REVERSAL, not a relaxation, and the asserts below are inverted from what they were the day before.
# While the changelog had one section per tier, the heading above an entry stated its reach -- so the
# entry's own 'Tier: N' line was the same fact twice, and an unscored table was a question nobody had put.
# With the sections gone the entry is the only carrier of both.

Write-Host "A scored impact table is carried into the record" -ForegroundColor Cyan
#      Unchanged behaviour, and the reason is the two-moment property: the cut empties the pending list, so a
#      score consumed here would not exist when the release documents are built days later, and the ordering
#      could not be reproduced without re-estimating it.
$clS = Get-Changelog -Dir $dirS
Assert-True ($clS -match '(?m)^\|\s*1\s*\|\s*5\s*\|') 'scored table: the row survives the fold'
Assert-True ($clS -match 'the reader must act')        'scored table: including its Why, which is the lasting half'

Write-Host "An UNSCORED table is carried too, because its section names a question" -ForegroundColor Cyan
#      This is the inversion. The scaffold row used to be stripped as "a question nobody was asked", which was
#      right while a heading stated the tier. Now '### Who is this for' is a named section of the entry, and a
#      heading with its answer cut out is worse than a placeholder: the reader cannot tell "nobody was asked"
#      from "somebody deleted it". Worse, stripping it would leave the entry declaring no reach at all.
$dirU = New-FoldFixture -Label 'impact-unscored'
New-EntryFile -Dir $dirU -Name 'chore-internal.md' -Title 'Repo internal' -Rows '| 0 | - | - |'
$rU = Invoke-Fold -Dir $dirU
Assert-True ($rU.ExitCode -eq 0) 'unscored table: exits 0'
$clU = Get-Changelog -Dir $dirU
Assert-True ($clU -match 'Repo internal')                        'unscored table: the entry is folded'
Assert-True ($clU -match '(?m)^\|\s*Tier\s*\|\s*Significance\s*\|') 'unscored table: and its table is still there'
Assert-True ($clU -match '(?m)^\|\s*0\s*\|\s*-\s*\|\s*-\s*\|')   'unscored table: scaffold row and all, so the reach is still declared'

Write-Host "A pre-format entry keeps its Tier: line and is promoted to an H2" -ForegroundColor Cyan
#      Both halves matter, and both are inversions of the old behaviour. The line SURVIVES because nothing
#      above the entry states the tier any more -- consuming it would make the entry read back as tier 0 and
#      drop silently out of the release documents. And the H3 heading is PROMOTED, because an H3 is not an
#      entry boundary in a flat list of H2s: it would be absorbed into the block above and inherit its PR link.
$dirL = New-FoldFixture -Label 'impact-legacy'
New-EntryFile       -Dir $dirL -Name 'feat-current.md' -Title 'Written in the new format' -Rows '| 1 | 3 | fine |'
Invoke-Fold -Dir $dirL -Branch 'feat/current' | Out-Null
New-LegacyEntryFile -Dir $dirL -Name 'feat-old.md' -Title 'Written before the table' -Tier '2'
$rL = Invoke-Fold -Dir $dirL -Branch 'feat/old'
Assert-True ($rL.ExitCode -eq 0) 'legacy entry: exits 0'
$clL = Get-Changelog -Dir $dirL
Assert-True ($clL -match '(?m)^Tier: 2$') 'legacy entry: its Tier: line is CARRIED, so its reach survives the fold'
$orderL = @(Get-EntryOrder -Changelog $clL)
Assert-Equal 2 $orderL.Count 'legacy entry: it is an entry boundary in its own right'
Assert-True ($orderL[0] -match 'Written before the table') 'legacy entry: and its tier-2 line still ranks it above the tier-1 entry'
Assert-True ($clL -notmatch '(?m)^### Written before the table') 'legacy entry: nothing is left at the old level'
Assert-True ($rL.Output -match 'pre-flat entry format') 'legacy entry: and the promotion is reported rather than done silently'

Write-Host "An entry with no declaration at all is tier 0, and says so" -ForegroundColor Cyan
$dirD = New-FoldFixture -Label 'undeclared'
New-LegacyEntryFile -Dir $dirD -Name 'chore-undeclared.md' -Title 'Nothing declared' -NoTierLine
$rD = Invoke-Fold -Dir $dirD
Assert-True ($rD.ExitCode -eq 0) 'undeclared: exits 0 -- the default is a valid answer, not an error'
Assert-True ((Get-Changelog -Dir $dirD) -match 'Nothing declared') 'undeclared: the entry is folded as tier 0, the harmless end'
# Said out loud rather than absorbed: an author who simply forgot has produced work that cannot carry a
# release on its own, and the moment to learn that is now rather than at the cut.
Assert-True ($rD.Output -match 'declares no tier') 'undeclared: the run reports that it defaulted'

Write-Host "A missing significance is reported, and folded anyway" -ForegroundColor Cyan
#      Deliberately not a refusal. Refusing the fold of an ALREADY-MERGED branch produces the silent
#      half-state this repo has measured -- an unfolded entry file in the repo root the morning after its
#      merge, with main looking finished. cut-release.ps1 is the refusal point Dave chose instead.
$dirM = New-FoldFixture -Label 'impact-noscore'
New-EntryFile -Dir $dirM -Name 'feat-unscored.md' -Title 'Reaches but unweighed' -Rows '| 1 | - | - |'
$rM = Invoke-Fold -Dir $dirM
Assert-True ($rM.ExitCode -eq 0) 'missing score: exits 0 -- the fold is not the refusal point'
Assert-True ($rM.Output -match 'declares no significance for tier 1') 'missing score: but it is said out loud'
Assert-True ($rM.Output -match 'release cut will refuse') 'missing score: and names where it WILL be refused'
Assert-True ((Get-Changelog -Dir $dirM) -match 'Reaches but unweighed') 'missing score: the entry landed'

Write-Host "A malformed table stops the run before anything is written" -ForegroundColor Cyan
$dirB = New-FoldFixture -Label 'impact-malformed'
$clBefore = Get-Changelog -Dir $dirB
New-EntryFile -Dir $dirB -Name 'feat-bad.md' -Title 'Off the scale' -Rows '| 1 | 9 | too high |'
$rB = Invoke-Fold -Dir $dirB
Assert-True ($rB.ExitCode -ne 0) 'malformed table: refuses'
Assert-True ($rB.Output -match 'off the scale') 'malformed table: and says which cell'
Assert-True ((Get-Changelog -Dir $dirB) -eq $clBefore) 'malformed table: CHANGELOG.md is untouched -- this script commits straight to main'
Assert-True (Test-Path (Join-Path $dirB 'feat-bad.md')) 'malformed table: and the entry file still exists, so nothing has to be unpicked'

Write-Host "THE PRE-PASS: one bad entry folds none of the good ones" -ForegroundColor Cyan
#      Folding writes one entry at a time, so a problem found on the second file would leave the first already
#      folded and its source file deleted -- a half-state to unpick by hand on main. So NOTHING may have
#      happened, including to the entry that was fine.
$dirP = New-FoldFixture -Label 'prepass'
$clP0 = Get-Changelog -Dir $dirP
New-EntryFile -Dir $dirP -Name 'feat-good.md' -Title 'Perfectly fine' -Rows '| 1 | 3 | fine |'
New-EntryFile -Dir $dirP -Name 'feat-worse.md' -Title 'Bad tier'      -Rows '| 5 | 3 | nonexistent tier |'
$rP = Invoke-Fold -Dir $dirP
Assert-True ($rP.ExitCode -eq 1) 'pre-pass: exits 1'
Assert-True ($rP.Output -match 'tier 5') 'pre-pass: the reason names the value'
Assert-True ((Get-Changelog -Dir $dirP) -eq $clP0) 'pre-pass: the changelog is byte-identical -- it ran before any write'
Assert-True (Test-Path -LiteralPath (Join-Path $dirP 'feat-good.md')) 'pre-pass: the VALID entry file still exists, rather than being folded first'
Assert-True (Test-Path -LiteralPath (Join-Path $dirP 'feat-worse.md')) 'pre-pass: as does the invalid one'

Write-Host "A declaration QUOTED inside a fence is not the declaration" -ForegroundColor Cyan
#      An entry documenting this format writes the thing it is explaining -- this repo's own entries for the
#      tier model and for this change both do. A blind regex would read the quoted value as the declaration.
$dirF = New-FoldFixture -Label 'fenced'
$fence = "``````text`n" + "| Tier | Significance | Why |`n|---|---|---|`n| 2 | 5 | quoted, not declared |`n" + '```' + "`n"
New-EntryFile -Dir $dirF -Name 'docs-explains.md' -Title 'Explains the format' -Rows '| 1 | 2 | the real one |' -ExtraBody "An example:`n`n$fence"
$rF = Invoke-Fold -Dir $dirF
Assert-True ($rF.ExitCode -eq 0) 'fenced: exits 0'
$clF = Get-Changelog -Dir $dirF
Assert-True ($clF -match 'the real one')            'fenced: the REAL declaration is the one folded in'
Assert-True ($clF -match 'quoted, not declared')    'fenced: and the quoted table survives inside its fence'
Assert-True ($rF.Output -notmatch 'no significance') 'fenced: the real row was read, so nothing is reported missing'

Write-Host "The branch/ pair: folded from the new path, RESET rather than deleted" -ForegroundColor Cyan
#      The split (Dave, August 6, 2026). Two things have to hold that did not exist before: the entry is
#      found at a fixed path instead of one named after the branch, and clearing it means rewriting it to
#      its empty state -- deleting it would leave the trunk missing a file the next branch expects.
$dirBF = New-FoldFixture -Label 'branchfiles'
$bfPaths = Get-BranchFilePaths
New-Item -ItemType Directory -Path (Join-Path $dirBF $bfPaths.Directory) -Force | Out-Null
New-EntryFile -Dir $dirBF -Name $bfPaths.Changelog -Title 'Written in the branch folder' -Rows '| 1 | 4 | the split |'
[System.IO.File]::WriteAllText((Join-Path $dirBF $bfPaths.Progress),
    ((Format-BranchProgressScaffold -Branch 'feat/branch-folder') -join "`n") + "`n", $Utf8NoBom)

$rBF = Invoke-Fold -Dir $dirBF
Assert-True ($rBF.ExitCode -eq 0) 'branch files: exits 0'
Assert-True ((Get-Changelog -Dir $dirBF) -match 'Written in the branch folder') 'branch files: the entry landed in CHANGELOG.md'

$bfChangelogPath = Join-Path $dirBF $bfPaths.Changelog
$bfProgressPath  = Join-Path $dirBF $bfPaths.Progress
Assert-True (Test-Path -LiteralPath $bfChangelogPath) 'branch files: the entry file still EXISTS -- it is a fixed path the next branch will use'
$bfChangelogAfter = [System.IO.File]::ReadAllText($bfChangelogPath)
Assert-True (-not (Test-BranchChangelogIsFilled -Text $bfChangelogAfter)) 'branch files: and it is back in its empty state'
Assert-True (-not ($bfChangelogAfter -match 'Written in the branch folder')) 'branch files: with the folded entry gone from it, not merely appended to'

$bfProgressAfter = [System.IO.File]::ReadAllText($bfProgressPath)
Assert-True (-not ($bfProgressAfter -match '(?m)^- \[ \] ')) 'branch files: the step list is reset too -- a merged branch does not hand its ticked boxes to the next one'
Assert-Equal 'main' (Get-BranchFileDeclaredBranch -Text $bfProgressAfter) 'branch files: and the reset names the trunk again'
Assert-True ($rBF.Output -match 'reset') 'branch files: the run says it reset rather than removed, so the reader does not go looking for a deleted file'

Write-Host "A RESET branch-changelog.md is not an entry, and is not folded" -ForegroundColor Cyan
#      The reset state opens with an H1, exactly as CONTRIBUTING.md does. This is what makes a double fold
#      impossible and what stops the trunk's own empty file being pasted into CHANGELOG.md as a change.
$dirBR = New-FoldFixture -Label 'branchreset'
New-Item -ItemType Directory -Path (Join-Path $dirBR $bfPaths.Directory) -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $dirBR $bfPaths.Changelog),
    ((Format-BranchChangelogReset) -join "`n") + "`n", $Utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path $dirBR $bfPaths.Progress),
    ((Format-BranchProgressReset) -join "`n") + "`n", $Utf8NoBom)
$clBR0 = Get-Changelog -Dir $dirBR
$rBR = Invoke-Fold -Dir $dirBR
Assert-True ($rBR.ExitCode -eq 0) 'reset pair: exits 0 -- nothing to fold is not an error'
Assert-True ($rBR.Output -match 'No entry files found') 'reset pair: and it says there was nothing to fold'
Assert-True ((Get-Changelog -Dir $dirBR) -eq $clBR0) 'reset pair: CHANGELOG.md is byte-identical'

Write-Host "The fold commit names both branch files" -ForegroundColor Cyan
#      The entry is modified rather than deleted now, and the step list rides along because this run
#      rewrote it. Leaving either out produces a commit that resets half the pair.
$dirBC = New-FoldFixture -Label 'branchcommit'
New-Item -ItemType Directory -Path (Join-Path $dirBC $bfPaths.Directory) -Force | Out-Null
New-EntryFile -Dir $dirBC -Name $bfPaths.Changelog -Title 'Committed from the branch folder' -Rows '| 1 | 2 | commit scope |'
[System.IO.File]::WriteAllText((Join-Path $dirBC $bfPaths.Progress),
    ((Format-BranchProgressScaffold -Branch 'feat/commit-scope') -join "`n") + "`n", $Utf8NoBom)
Initialize-FoldGitRepo -Dir $dirBC
# An unrelated staged file, to prove the enforced scope did not widen along with the path change.
[System.IO.File]::WriteAllText((Join-Path $dirBC 'stray.txt'), "unrelated`n", $Utf8NoBom)
Invoke-Git -Dir $dirBC -GitArgs @('add', 'stray.txt') | Out-Null

$rBC = Invoke-Fold -Dir $dirBC -ExtraArgs @('-Commit')
Assert-True ($rBC.ExitCode -eq 0) 'fold commit: exits 0'
$bcFiles = @(Invoke-Git -Dir $dirBC -GitArgs @('diff-tree', '--no-commit-id', '--name-only', '-r', 'HEAD'))
Assert-True ($bcFiles -contains 'CHANGELOG.md')        'fold commit: CHANGELOG.md is in it'
Assert-True ($bcFiles -contains $bfPaths.Changelog)    'fold commit: the reset entry file is in it'
Assert-True ($bcFiles -contains $bfPaths.Progress)     'fold commit: and the reset step list, so the pair lands together'
Assert-True (-not ($bcFiles -contains 'stray.txt'))    'fold commit: the unrelated staged file is NOT swept in -- the pathspec scope is unchanged'

# ---------------------------------------------------------------------------------------------------
Write-Host "A changelog with no trailing newline does not swallow the entry appended to its end" -ForegroundColor Cyan
#      Get-ImpactInsertOffset returns the slice's LENGTH for the lowest-ranked entry -- the common case, since
#      tier 0 sinks to the bottom -- so the insert lands at the very end of the content. Ending on '---' with
#      nothing after it, that produces '---## <title>' on ONE line: '^## ' stops matching, so the cut never
#      sees the entry, and the entry FILE is deleted by then. Nothing errors and the markdown stays
#      well-formed, which is exactly why only a test catches it.
#
#      THE CONDITION IS NOT HYPOTHETICAL AND THE LOSS IS NOT RECORDED, which is why this test exists in this
#      shape. The branch behind PR #486 was handed over with the final newline stripped by an editor and
#      repaired before its commit, so no commit, PR or fold ever carried it -- the condition is ordinary
#      editing, and everything below is what proves the loss follows from it.
#
#      The seeded entry is tier 1 ON PURPOSE. An equal rank puts the new entry ABOVE its equals, so two tier-0
#      entries would exercise the insert-before-a-heading path and never reach the end of the list at all.
$dirN = New-FoldFixture -Label 'tail-noeol'
New-EntryFile -Dir $dirN -Name 'feat-ranked-above.md' -Title 'Ranks above the newcomer' -Rows '| 1 | 3 | a clear improvement |'
Invoke-Fold -Dir $dirN -Branch 'feat/ranked-above' | Out-Null
# The editor's damage, reproduced exactly: every trailing line break gone, so the file ends on '---'.
$clNpath = Join-Path $dirN 'CHANGELOG.md'
[System.IO.File]::WriteAllText($clNpath, ([System.IO.File]::ReadAllText($clNpath)).TrimEnd(), $Utf8NoBom)
Assert-True (-not ([System.IO.File]::ReadAllText($clNpath)).EndsWith("`n")) 'tail no-eol: the fixture really has no trailing newline'
New-EntryFile -Dir $dirN -Name 'chore-sinks-to-bottom.md' -Title 'Sinks to the bottom' -Rows '| 0 | - | - |'
$rN = Invoke-Fold -Dir $dirN -Branch 'chore/sinks-to-bottom'
$clN = Get-Changelog -Dir $dirN
# WHICH ASSERTS PIN THE GUARD AND WHICH DO NOT, written down because the defect is SILENT and the difference
# is therefore invisible. Verified by removing the guard: the three marked below fail, and these two pass
# either way -- the fold succeeds whichever side of the bug it is on, so an exit code cannot see it.
Assert-True ($rN.ExitCode -eq 0) 'tail no-eol: exits 0 (an invariant -- the defect never threw)'
# THE THREE THAT PIN IT.
$orderN = @(Get-EntryOrder -Changelog $clN)
Assert-Equal 2 $orderN.Count 'tail no-eol: the appended entry is still an entry heading, not glued onto the separator'
Assert-Equal 'Sinks to the bottom' $orderN[1] 'tail no-eol: and it sits at the bottom, below the higher-ranked one'
# The defect shape itself, asserted directly: a heading welded to the separator above it.
Assert-True ($clN -notmatch '---##') 'tail no-eol: no separator carries a heading on its own line'
# THE SECOND INVARIANT: the appended entry block ends in a separator plus a blank line by construction, so
# this passes with the guard removed too. It is here to pin the NEXT fold's precondition rather than this one.
Assert-True ($clN.EndsWith("`n")) 'tail no-eol: and the document is left ending on a line break (an invariant)'

Write-Host "The tail is normalised rather than merely repaired -- accumulated blanks are capped" -ForegroundColor Cyan
#      Same one line does both jobs. Split-Changelog already strips this accumulation from the HEAD, for the
#      reason that applies here too: it renders identically, so nothing looks wrong until somebody opens the
#      raw file years in.
$dirNB = New-FoldFixture -Label 'tail-blanks'
New-EntryFile -Dir $dirNB -Name 'feat-first.md' -Title 'The seeded one' -Rows '| 1 | 3 | a clear improvement |'
Invoke-Fold -Dir $dirNB -Branch 'feat/first' | Out-Null
$clNBpath = Join-Path $dirNB 'CHANGELOG.md'
[System.IO.File]::WriteAllText($clNBpath, (([System.IO.File]::ReadAllText($clNBpath)).TrimEnd() + "`n`n`n`n`n"), $Utf8NoBom)
New-EntryFile -Dir $dirNB -Name 'chore-second.md' -Title 'The appended one' -Rows '| 0 | - | - |'
$rNB = Invoke-Fold -Dir $dirNB -Branch 'chore/second'
# Both invariants, as in the block above: neither can see this behaviour, and they are labelled so that the
# one assert that CAN is not read as three.
Assert-True ($rNB.ExitCode -eq 0) 'tail blanks: exits 0 (an invariant)'
$clNB = (Get-Changelog -Dir $dirNB) -replace "`r`n", "`n"
Assert-Equal 2 @(Get-EntryOrder -Changelog $clNB).Count 'tail blanks: both entries are headings (an invariant)'
# Asserted as "nowhere in the document", not as "not at the end". The appended entry block ends in
# '---' + blank line by construction, so an end-of-file assertion passes whether the guard ran or not --
# the four blanks end up in the MIDDLE, above the entry that was appended after them.
Assert-True ($clNB -notmatch "`n`n`n") 'tail blanks: the run of blank lines is capped, not merely pushed up the document'

# ---------------------------------------------------------------------------------------------------
foreach ($f in $script:fixtures) { Remove-Item -Recurse -Force -LiteralPath $f -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "Result: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
