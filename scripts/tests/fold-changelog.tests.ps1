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
        [switch]$OmitHeadingFunction
    )
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("fold-test-$PID-$Label")
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\release') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib')     -Force | Out-Null
    Copy-Item -LiteralPath $FoldSrc          -Destination (Join-Path $dir 'scripts\release\fold-changelog-entry.ps1') -Force
    Copy-Item -LiteralPath $NativeCaptureSrc -Destination (Join-Path $dir 'scripts\lib\native-capture-lib.ps1')       -Force

    $repoConfig = [System.IO.File]::ReadAllText($RepoConfigSrc)
    if ($OmitHeadingFunction) {
        # A consumer whose repo-config predates the contract: the whole function is gone.
        $repoConfig = $repoConfig -replace '(?s)function Get-ChangelogHeading \{.*?\r?\n\}', ''
    } elseif ($PSBoundParameters.ContainsKey('Heading')) {
        $repoConfig = $repoConfig -replace "(?m)^\`$script:ChangelogHeading = .*$", "`$script:ChangelogHeading = '$Heading'"
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

function Invoke-Fold {
    param([Parameter(Mandatory = $true)][string]$Dir, [string]$Branch)
    $scriptPath = Join-Path $Dir 'scripts\release\fold-changelog-entry.ps1'
    $callArgs = @('-RepoRoot', $Dir)
    if ($PSBoundParameters.ContainsKey('Branch')) { $callArgs += @('-Branch', $Branch) }
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
foreach ($f in $script:fixtures) { Remove-Item -Recurse -Force -LiteralPath $f -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "Result: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
