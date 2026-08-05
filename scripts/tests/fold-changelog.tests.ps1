<#
.SYNOPSIS
    Regression tests for scripts/release/fold-changelog-entry.ps1 -- specifically that fold-all mode
    only folds genuine changelog entry files and never touches repo-root meta docs.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Integration style -- runs the REAL fold
    script (copied into a throwaway temp repo root, so nothing touches the own working copy) and
    asserts on exit code + which files survive + CHANGELOG content.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/fold-changelog.tests.ps1

    Guards the bug where fold-all mode folded any root *.md that was not in a tiny denylist
    (CHANGELOG/CLAUDE/README) -- so CONTRIBUTING.md and SECURITY.md got folded and removed. The fix
    keys off the entry format itself: an entry opens with a '### <title> - <type> - <date>' H3
    heading; meta docs open with an H1. The tests below pin down: meta docs survive, a genuine entry
    (including one with a consumer-extended prefix) still folds, an H1 doc with a hyphenated name is
    NOT folded, and -Branch mode is unaffected.

    The fold script calls `gh pr list` per folded entry for PR-number enrichment; with no matching
    PR that simply returns nothing and the entry folds without a #NN -- so these tests do not depend
    on a PR existing. File selection (the thing under test) happens regardless of gh.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot         = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$FoldSrc          = Join-Path $RepoRoot 'scripts\release\fold-changelog-entry.ps1'
$RepoConfigSrc    = Join-Path $RepoRoot 'scripts\repo-config.ps1'
$NativeCaptureSrc = Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1'
# The entry format: the 'Tier: N' line the fold reads to pick a section and then removes, plus the section
# map itself. A $PSScriptRoot-relative sibling of the fold script, so the fixture has to carry it.
$EntryScaffoldSrc = Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1'

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

$script:fixtures = @()
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function New-FoldFixture {
    <#
        A throwaway repo root with the real fold script + its repo-owned/sibling dependencies
        (repo-config.ps1 for Get-RepoName, native-capture-lib.ps1 for the gh call) and a CHANGELOG
        with the ## Pull Requests / ## Releases skeleton. release-lib.ps1 is deliberately NOT copied,
        so the optional 'Plugins:' detection is simply skipped.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        # Keep-a-Changelog shape (issue #178): '## [Unreleased]' with released versions as ## sections
        # below it, and no '## Releases' anywhere. -Heading sets what repo-config reports; omit it to
        # strip Get-ChangelogHeading entirely and exercise the built-in fallback.
        [switch]$KeepAChangelog,
        [string]$Heading,
        [switch]$OmitHeadingFunction,
        # THE TIER SPLIT IS OPT-IN PER FIXTURE, and the default is deliberately OFF. Every test in this
        # file except the tier block at the end is about something orthogonal -- which files are folded,
        # and which heading the seam names -- and those must keep being asserted in the ONE-SECTION shape,
        # because that is what a consumer who has not adopted tiers runs. So the default fixture strips
        # the tier map and exercises the legacy single-heading path, and -TierSections builds the three
        # sections when the tier behaviour itself is the subject.
        [switch]$TierSections
    )
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("fold-test-$PID-$Label")
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\release') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib')     -Force | Out-Null
    Copy-Item -LiteralPath $FoldSrc          -Destination (Join-Path $dir 'scripts\release\fold-changelog-entry.ps1') -Force
    Copy-Item -LiteralPath $NativeCaptureSrc -Destination (Join-Path $dir 'scripts\lib\native-capture-lib.ps1')       -Force
    Copy-Item -LiteralPath $EntryScaffoldSrc -Destination (Join-Path $dir 'scripts\lib\entry-scaffold-lib.ps1')       -Force

    $repoConfig = [System.IO.File]::ReadAllText($RepoConfigSrc)
    if (-not $TierSections) {
        # Strip the tier map so Get-ChangelogTierSections falls back to the legacy single heading. Done by
        # removing the FUNCTION, not the backing variable: the probe is Get-Command-based, so a repo that
        # still has the variable but not the getter is exactly the consumer shape being modelled.
        $repoConfig = $repoConfig -replace '(?s)function Get-ChangelogTierHeadings \{.*?\r?\n\}', ''
        # The real repo-config no longer defines the legacy getter (the tier map supersedes it there), so
        # the fixture adds it back -- these tests are about a consumer that has only that one.
        if (-not $OmitHeadingFunction) {
            $headingValue = if ($PSBoundParameters.ContainsKey('Heading')) { $Heading } else { '## Pull Requests' }
            $repoConfig += "`n`$script:ChangelogHeading = '$headingValue'`nfunction Get-ChangelogHeading { return `$script:ChangelogHeading }`n"
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $dir 'scripts\repo-config.ps1'), $repoConfig, $Utf8NoBom)

    $changelog = if ($KeepAChangelog) {
        @(
            '# Changelog',
            '',
            'All notable changes to this project.',
            '',
            '## [Unreleased]',
            '',
            '## [v2.21.0] - 2026-07-24 - Minor',
            '',
            '- An older, already released change.',
            ''
        ) -join "`n"
    } elseif ($TierSections) {
        @(
            '# Changelog',
            '',
            '## Tier 2 - Pull Requests',
            '',
            'What a consumer notices.',
            '',
            '## Tier 1 - Pull Requests',
            '',
            'What the team gets out of it.',
            '',
            '## Tier 0 - Pull Requests',
            '',
            'Repo-internal only.',
            '',
            '## Releases',
            '',
            'Released versions.',
            ''
        ) -join "`n"
    } else {
        @(
            '# Changelog',
            '',
            '## Pull Requests',
            '',
            'Everything merged since the last release.',
            '',
            '## Releases',
            '',
            'Released versions.',
            ''
        ) -join "`n"
    }
    [System.IO.File]::WriteAllText((Join-Path $dir 'CHANGELOG.md'), $changelog, $Utf8NoBom)
    $script:fixtures += $dir
    return $dir
}

function New-EntryFile {
    param([string]$Dir, [string]$Name, [string]$Title)
    $body = "### $Title " + [char]0x00B7 + " Feat " + [char]0x00B7 + " 2026-01-01`n`nDemo entry body.`n"
    [System.IO.File]::WriteAllText((Join-Path $Dir $Name), $body, $Utf8NoBom)
}

function New-DocFile {
    # An H1 markdown doc (a meta file), NOT an entry.
    param([string]$Dir, [string]$Name, [string]$Heading)
    [System.IO.File]::WriteAllText((Join-Path $Dir $Name), "# $Heading`n`nSome prose.`n", $Utf8NoBom)
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
$changelogText = Get-Content -LiteralPath (Join-Path $dir 'CHANGELOG.md') -Raw

Assert-True ($r.ExitCode -eq 0)                                              'fold-all exits 0'
Assert-True (-not (Test-Path (Join-Path $dir 'feat-demo-thing.md')))        'the genuine entry file is removed'
Assert-True ($changelogText -match 'Demo thing')                            'the entry is folded into CHANGELOG'
Assert-True (Test-Path (Join-Path $dir 'CONTRIBUTING.md'))                  'CONTRIBUTING.md survives (not folded)'
Assert-True (Test-Path (Join-Path $dir 'SECURITY.md'))                      'SECURITY.md survives (not folded)'
Assert-True (Test-Path (Join-Path $dir 'CLAUDE.md'))                        'CLAUDE.md survives (reserved)'
Assert-True ($changelogText -notmatch 'Security Policy')                    'meta content did NOT leak into CHANGELOG'
Assert-True ($changelogText -notmatch '(?m)^# Contributing')               'CONTRIBUTING body did NOT leak into CHANGELOG'

# ---------------------------------------------------------------------------------------------------
Write-Host "fold-all -- a consumer-extended prefix still folds" -ForegroundColor Cyan
$dir2 = New-FoldFixture -Label 'extprefix'
New-EntryFile -Dir $dir2 -Name 'style-tweak-colors.md' -Title 'Tweak colors'
$r2 = Invoke-Fold -Dir $dir2
$changelog2 = Get-Content -LiteralPath (Join-Path $dir2 'CHANGELOG.md') -Raw
Assert-True ($r2.ExitCode -eq 0)                                            'fold-all (ext prefix) exits 0'
Assert-True (-not (Test-Path (Join-Path $dir2 'style-tweak-colors.md')))    'extended-prefix entry is folded (not prefix-gated)'
Assert-True ($changelog2 -match 'Tweak colors')                            'extended-prefix entry lands in CHANGELOG'

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
$changelog4 = Get-Content -LiteralPath (Join-Path $dir4 'CHANGELOG.md') -Raw
Assert-True ($r4.ExitCode -eq 0)                                            '-Branch mode exits 0'
Assert-True (-not (Test-Path (Join-Path $dir4 'fix-explicit-target.md')))   '-Branch folds the named entry'
Assert-True ($changelog4 -match 'Explicit target')                         '-Branch entry lands in CHANGELOG'
Assert-True (Test-Path (Join-Path $dir4 'CONTRIBUTING.md'))                'CONTRIBUTING.md untouched in -Branch mode'

# ---------------------------------------------------------------------------------------------------
Write-Host "Keep-a-Changelog -- folds under the configured '## [Unreleased]' heading" -ForegroundColor Cyan
$dir5 = New-FoldFixture -Label 'keepachangelog' -KeepAChangelog -Heading '## [Unreleased]'
New-EntryFile -Dir $dir5 -Name 'fix-mix-titels.md' -Title 'Mix titles'
$r5 = Invoke-Fold -Dir $dir5
$changelog5 = Get-Content -LiteralPath (Join-Path $dir5 'CHANGELOG.md') -Raw
Assert-True ($r5.ExitCode -eq 0)                                            'keep-a-changelog: exits 0 (no hard stop on the heading)'
Assert-True (-not (Test-Path (Join-Path $dir5 'fix-mix-titels.md')))        'keep-a-changelog: the entry file is folded away'
Assert-True ($changelog5 -match 'Mix titles')                              'keep-a-changelog: the entry lands in CHANGELOG'
# Placement: inside [Unreleased], above the released version below it -- not appended at the end.
$posUnreleased = $changelog5.IndexOf('## [Unreleased]')
$posEntry      = $changelog5.IndexOf('Mix titles')
$posReleased   = $changelog5.IndexOf('## [v2.21.0]')
Assert-True ($posUnreleased -lt $posEntry)                                 'keep-a-changelog: the entry sits BELOW the [Unreleased] heading'
Assert-True ($posEntry -lt $posReleased)                                   'keep-a-changelog: the entry sits ABOVE the released version section'

# ---------------------------------------------------------------------------------------------------
Write-Host "Keep-a-Changelog -- a wrong/absent heading stops cleanly, naming the config" -ForegroundColor Cyan
$dir6 = New-FoldFixture -Label 'headingmiss' -KeepAChangelog -Heading '## Pull Requests'
New-EntryFile -Dir $dir6 -Name 'fix-no-heading.md' -Title 'No heading here'
$r6 = Invoke-Fold -Dir $dir6
Assert-True ($r6.ExitCode -eq 1)                                            'heading miss: exits 1'
Assert-True (Test-Path (Join-Path $dir6 'fix-no-heading.md'))               'heading miss: the entry file is left untouched'
Assert-True ($r6.Output -match [regex]::Escape('## Pull Requests'))         'heading miss: the message names the heading it looked for'
Assert-True ($r6.Output -match 'Get-ChangelogHeading')                      'heading miss: the message points at the repo-config function to set'

# ---------------------------------------------------------------------------------------------------
Write-Host "Backwards compatible -- a repo-config without Get-ChangelogHeading still folds" -ForegroundColor Cyan
$dir7 = New-FoldFixture -Label 'nofunction' -OmitHeadingFunction
New-EntryFile -Dir $dir7 -Name 'fix-legacy-config.md' -Title 'Legacy config'
$r7 = Invoke-Fold -Dir $dir7
$changelog7 = Get-Content -LiteralPath (Join-Path $dir7 'CHANGELOG.md') -Raw
Assert-True ($r7.ExitCode -eq 0)                                            'legacy config: exits 0 (falls back to the default heading)'
Assert-True ($changelog7 -match 'Legacy config')                           'legacy config: the entry lands under ## Pull Requests'
$posPr    = $changelog7.IndexOf('## Pull Requests')
$posEnt7  = $changelog7.IndexOf('Legacy config')
$posRel7  = $changelog7.IndexOf('## Releases')
Assert-True ($posPr -lt $posEnt7 -and $posEnt7 -lt $posRel7)               'legacy config: placement unchanged (between the two headings)'

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
# THE TIER SPLIT (August 5, 2026): the entry declares a tier, the fold files it and consumes the line
# ===================================================================================================
# These are the only fixtures built with -TierSections. Everything above deliberately runs the
# one-section shape, because that is what a consumer who has not adopted the model runs -- and both paths
# have to keep working.

function New-TieredEntryFile {
    # Like New-EntryFile, but with a 'Tier: N' line where new-changelog-entry.ps1 writes one: directly
    # under the heading. -NoTierLine leaves it out, which is the undeclared (= tier 0) case.
    param([string]$Dir, [string]$Name, [string]$Title, [string]$Tier, [switch]$NoTierLine, [string]$ExtraBody = '')
    $md = [char]0x00B7
    $tierLine = if ($NoTierLine) { '' } else { "Tier: $Tier`n`n" }
    $body = "### $Title $md Feat $md 2026-01-01`n`n$tierLine" + "Demo entry body.`n" + $ExtraBody
    [System.IO.File]::WriteAllText((Join-Path $Dir $Name), $body, $Utf8NoBom)
}

Write-Host "Each entry lands in the section its tier names" -ForegroundColor Cyan
$dirT1 = New-FoldFixture -Label 'tier-routing' -TierSections
New-TieredEntryFile -Dir $dirT1 -Name 'feat-consumer.md'  -Title 'Consumer facing'  -Tier '2'
New-TieredEntryFile -Dir $dirT1 -Name 'docs-colleague.md' -Title 'For colleagues'   -Tier '1'
New-TieredEntryFile -Dir $dirT1 -Name 'chore-internal.md' -Title 'Repo internal'    -Tier '0'
$rT1 = Invoke-Fold -Dir $dirT1
Assert-True ($rT1.ExitCode -eq 0) 'tier routing: exits 0'
$clT1 = [System.IO.File]::ReadAllText((Join-Path $dirT1 'CHANGELOG.md'))
# Asserted per section rather than on the whole file: "the title appears somewhere" would pass even with
# every entry filed in one section, which is the failure this is for.
function Get-SectionBody {
    param([string]$Changelog, [string]$Heading)
    $lines = $Changelog -split "`r?`n"
    $from = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -eq $Heading) { $from = $i + 1; break } }
    if ($from -lt 0) { return '' }
    $out = @()
    for ($i = $from; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s') { break }
        $out += $lines[$i]
    }
    return ($out -join "`n")
}
$sec2 = Get-SectionBody -Changelog $clT1 -Heading '## Tier 2 - Pull Requests'
$sec1 = Get-SectionBody -Changelog $clT1 -Heading '## Tier 1 - Pull Requests'
$sec0 = Get-SectionBody -Changelog $clT1 -Heading '## Tier 0 - Pull Requests'
Assert-True ($sec2 -match 'Consumer facing')   'tier routing: the tier-2 entry is under the tier-2 heading'
Assert-True ($sec2 -notmatch 'For colleagues') 'tier routing: and nothing else is'
Assert-True ($sec1 -match 'For colleagues')    'tier routing: the tier-1 entry is under the tier-1 heading'
Assert-True ($sec0 -match 'Repo internal')     'tier routing: the tier-0 entry is under the tier-0 heading'
Assert-True ($sec0 -notmatch 'Consumer facing') 'tier routing: and the tier-2 entry did not leak down into it'
# THE LINE IS CONSUMED. Once the section states the tier, an entry restating it would be the same fact in
# two places -- the drift shape this repo has paid for three times.
Assert-True ($clT1 -notmatch '(?m)^Tier:')     'the Tier: line is removed once the section states the tier'
Assert-True ($sec2 -match 'Demo entry body')   'and the body around it survives intact'
# Each section keeps its own intro: the fold inserts below it, not over it.
Assert-True ($sec2 -match 'What a consumer notices') 'the section intro is untouched'

Write-Host "An entry with no Tier: line is tier 0, and says so" -ForegroundColor Cyan
$dirT2 = New-FoldFixture -Label 'tier-default' -TierSections
New-TieredEntryFile -Dir $dirT2 -Name 'chore-undeclared.md' -Title 'Nothing declared' -NoTierLine
$rT2 = Invoke-Fold -Dir $dirT2
Assert-True ($rT2.ExitCode -eq 0) 'undeclared tier: exits 0 -- the default is a valid answer, not an error'
$clT2 = [System.IO.File]::ReadAllText((Join-Path $dirT2 'CHANGELOG.md'))
Assert-True ((Get-SectionBody -Changelog $clT2 -Heading '## Tier 0 - Pull Requests') -match 'Nothing declared') `
    'undeclared tier: the entry is filed as tier 0 -- the harmless end of the scale'
# Said out loud rather than absorbed: an author who simply forgot has produced work that cannot carry a
# release on its own, and the moment to learn that is now rather than at the cut.
Assert-True ($rT2.Output -match 'no Tier: line') 'undeclared tier: the run reports that it defaulted'

Write-Host "A tier the model has no meaning for stops the fold, before anything is written" -ForegroundColor Cyan
$dirT3 = New-FoldFixture -Label 'tier-bad' -TierSections
New-TieredEntryFile -Dir $dirT3 -Name 'feat-good.md' -Title 'Perfectly fine' -Tier '2'
New-TieredEntryFile -Dir $dirT3 -Name 'feat-bad.md'  -Title 'Bad tier'       -Tier '5'
$before3 = [System.IO.File]::ReadAllText((Join-Path $dirT3 'CHANGELOG.md'))
$rT3 = Invoke-Fold -Dir $dirT3
Assert-True ($rT3.ExitCode -eq 1) 'bad tier: exits 1'
Assert-True ($rT3.Output -match 'tier 5 does not exist') 'bad tier: the reason names the value'
# THE PRE-PASS IS THE POINT. Folding writes one entry at a time, so a problem found on the second file
# would leave the first already folded and its source file deleted -- a half-state to unpick by hand on
# main. So NOTHING may have happened, including to the entry that was fine.
Assert-True ([System.IO.File]::ReadAllText((Join-Path $dirT3 'CHANGELOG.md')) -eq $before3) `
    'bad tier: the changelog is byte-identical -- the pre-pass ran before any write'
Assert-True (Test-Path -LiteralPath (Join-Path $dirT3 'feat-good.md')) `
    'bad tier: and the VALID entry file still exists, rather than being folded first'
Assert-True (Test-Path -LiteralPath (Join-Path $dirT3 'feat-bad.md')) 'bad tier: as does the invalid one'

Write-Host "A tier with no section declared is refused by name, not silently neighboured" -ForegroundColor Cyan
$dirT4 = New-FoldFixture -Label 'tier-nosection' -TierSections
# Drop tier 2 from the fixture's own map, so an entry declaring it has nowhere to go.
$cfgT4 = Join-Path $dirT4 'scripts\repo-config.ps1'
$cfgText = [System.IO.File]::ReadAllText($cfgT4) -replace "(?m)^\s*2 = '## Tier 2 - Pull Requests'\r?\n", ''
[System.IO.File]::WriteAllText($cfgT4, $cfgText, $Utf8NoBom)
New-TieredEntryFile -Dir $dirT4 -Name 'feat-orphan.md' -Title 'Nowhere to go' -Tier '2'
$rT4 = Invoke-Fold -Dir $dirT4
Assert-True ($rT4.ExitCode -eq 1) 'orphan tier: exits 1'
Assert-True ($rT4.Output -match 'no changelog section for it') 'orphan tier: the reason says what is missing'
Assert-True ($rT4.Output -match 'declares tiers: 1, 0') 'orphan tier: and lists the tiers the repo does declare'
Assert-True (Test-Path -LiteralPath (Join-Path $dirT4 'feat-orphan.md')) 'orphan tier: the entry file is untouched'

Write-Host "A Tier: line QUOTED inside a fence is not the declaration" -ForegroundColor Cyan
#      An entry documenting the tier model writes the line it is explaining -- this repo's own entry for
#      this change does. A blind regex would read the quoted value as the declaration AND delete that line
#      out of the fence while folding, damaging the one entry that explains the mechanism.
$dirT5 = New-FoldFixture -Label 'tier-fenced' -TierSections
$fence = "``````text`n" + "Tier: 2`n" + "``````" + "`n"
New-TieredEntryFile -Dir $dirT5 -Name 'docs-explains.md' -Title 'Explains the format' -Tier '1' -ExtraBody "`nAn example:`n`n$fence"
$rT5 = Invoke-Fold -Dir $dirT5
Assert-True ($rT5.ExitCode -eq 0) 'fenced tier: exits 0'
$clT5 = [System.IO.File]::ReadAllText((Join-Path $dirT5 'CHANGELOG.md'))
Assert-True ((Get-SectionBody -Changelog $clT5 -Heading '## Tier 1 - Pull Requests') -match 'Explains the format') `
    'fenced tier: the REAL declaration decided the section, not the quoted one'
Assert-True ($clT5 -match '(?m)^Tier: 2$') 'fenced tier: and the quoted line survives inside the fence'

# ---------------------------------------------------------------------------------------------------
foreach ($f in $script:fixtures) { Remove-Item -Recurse -Force -LiteralPath $f -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "Result: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
