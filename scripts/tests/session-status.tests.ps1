<#
.SYNOPSIS
    Regression tests for scripts/task/session-status.ps1 -- the reporter behind /lock and /continue.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Integration style -- runs the REAL script as a
    child process against a throwaway temp git repo, and asserts on its OUTPUT plus the fixture's git
    state afterwards.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/session-status.tests.ps1

    THE ASSERTS ARE ON THE PRINTED OUTPUT, NOT ON THE SOURCE. A text assert keyed on an expression is
    what made a correct change fail a test during #598's repair, so what is pinned here is what a reader
    actually sees.

    CLAUDE_PROJECT_DIR IS SET EXPLICITLY FOR EVERY CHILD RUN, and that is load-bearing rather than
    tidiness: this suite runs inside a session that very likely has it set to the real repo, a child
    inherits it, and the script prefers it over the git root. Without pinning it, every case here would
    silently report on the workshop repo instead of the fixture -- passing or failing on facts the test
    does not control.

    Pure ASCII (repo convention for .ps1), which is why the em dash in the encoding case is built from
    its code point instead of typed.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot  = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$ScriptSrc = Join-Path $RepoRoot 'scripts\task\session-status.ps1'

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message" -ForegroundColor Red }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -eq $Actual) { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message -- expected '$Expected', got '$Actual'" -ForegroundColor Red }
}

function Get-FlatOutput {
    <#
        Captured child output with newlines removed, so a phrase assert cannot fail on a line break this
        script does not decide. A native child's output WRAPS at the host width, and a mid-word break
        leaves 'no topic is loc' + 'ked' -- which a space would not repair either, hence removal rather
        than collapsing. Precedent: park-branch.tests.ps1 and shared-scripts.tests.ps1.
    #>
    param($Captured)
    return (($Captured | Out-String) -replace "`r?`n", '')
}

function New-Fixture {
    <#
        A throwaway git repo with the optional sources this script probes: a CHANGELOG with one pending
        entry, a release note carrying a 'still open' section, and a tag. Deliberately NO remote, so the
        gh and ls-remote paths exercise their degrade branches rather than reaching the network.
    #>
    # -NoteRoot repoints where the release note lives AND writes the repo-config that declares it, so the
    # pair is always consistent -- a fixture that moved the file without stating the seam would prove only
    # that the script cannot find it.
    param([switch]$Bare, [string]$NoteRoot = 'releases\notes')
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("sstat-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $dir | Out-Null
    Push-Location $dir
    $eap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    git init --quiet 2>&1 | Out-Null
    git config user.email 'test@example.com' 2>&1 | Out-Null
    git config user.name  'Test' 2>&1 | Out-Null
    git config commit.gpgsign false 2>&1 | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\task') -Force | Out-Null
    Copy-Item $ScriptSrc (Join-Path $dir 'scripts\task\session-status.ps1')
    if (-not $Bare) {
        Set-Utf8 (Join-Path $dir 'CHANGELOG.md') @(
            '# Changelog', '', 'Intro paragraph.', '',
            '## `feat/a-branch` changelog', '', '### Significance', '',
            '#### Tier 0', '', 'because.', '', '**Score:** 4', ''
        )
        if ($NoteRoot -ne 'releases\notes') {
            New-Item -ItemType Directory -Path (Join-Path $dir 'scripts') -Force | Out-Null
            Set-Utf8 (Join-Path $dir 'scripts\repo-config.ps1') @(
                'function Get-ReleaseNoteRoot {',
                ("    return '" + ($NoteRoot -replace '\\', '/') + "'"),
                '}'
            )
        }
        New-Item -ItemType Directory -Path (Join-Path $dir "$NoteRoot\1.x") -Force | Out-Null
        # The em dash is what the encoding case turns on -- built from its code point so this .ps1 stays
        # pure ASCII while the FIXTURE on disk carries a real multi-byte character.
        $dash = [string][char]0x2014
        Set-Utf8 (Join-Path $dir "$NoteRoot\1.x\1.0.0.md") @(
            '# Release notes v1.0.0', '',
            '## For consumers', '', 'Nothing to do.', '',
            '## What was still open at this release', '',
            "- the widget refactor $dash still with the technical writer",
            '- the second open thing', '',
            '## A later section', '', 'must not be printed.', ''
        )
    }
    git add -A 2>&1 | Out-Null
    git commit --quiet -m 'fixture' 2>&1 | Out-Null
    if (-not $Bare) { git tag -a 'v1.0.0' -m 'v1.0.0' 2>&1 | Out-Null }
    $ErrorActionPreference = $eap
    Pop-Location
    return $dir
}

function Set-Utf8 {
    # BOM-less UTF-8, which is what this repo's markdown is and therefore what the script must cope with.
    param([string]$Path, [string[]]$Lines)
    [System.IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding $false))
}

function Invoke-Status {
    param([string]$Fixture, [string[]]$ExtraArgs = @())
    $prev = $env:CLAUDE_PROJECT_DIR
    $env:CLAUDE_PROJECT_DIR = $Fixture
    try {
        $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Fixture 'scripts\task\session-status.ps1')) + $ExtraArgs
        $out  = & powershell @args 2>&1
        return [pscustomobject]@{ Out = $out; Flat = (Get-FlatOutput $out); Code = $LASTEXITCODE }
    } finally {
        if ($null -eq $prev) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prev }
    }
}

# The parent decodes the child's stdout with this encoding. Set to UTF-8 so the encoding case measures
# the SCRIPT's file read rather than a second, unrelated decoding step introduced by the harness.
$prevOut = [Console]::OutputEncoding
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
} catch { }

$fixtures = @()
try {
    Write-Host 'No topic locked' -ForegroundColor Cyan
    $fx = New-Fixture; $fixtures += $fx
    $r = Invoke-Status -Fixture $fx
    Assert-Equal 0 $r.Code 'exits 0 -- it is a reporter, and a non-zero code would make a skill look failed'
    Assert-True ($r.Flat -match 'no topic is locked') 'says so plainly rather than printing an empty block'
    Assert-True ($r.Flat -match '\.claude') 'and still prints the path, so /lock knows where to write'

    Write-Host 'The lock is printed first, verbatim, with the repo-wins warning' -ForegroundColor Cyan
    $lock = Join-Path $fx 'my-lock.md'
    Set-Utf8 $lock @('# Locked topic', '', '## The subject', '', 'Rebuild the widget parser.')
    $r = Invoke-Status -Fixture $fx -ExtraArgs @('-StoreOverride', $lock)
    Assert-True ($r.Flat -match 'Rebuild the widget parser\.') 'the locked subject is printed verbatim'
    Assert-True ($r.Flat -match 'the repo') 'and the warning that the repo wins travels with it'
    # ORDER MATTERS AND IS ASSERTED: the agreed subject is why somebody ran the command, and burying it
    # under six blocks of repo facts is how it gets skimmed past.
    $iLock = $r.Flat.IndexOf('Rebuild the widget parser')
    $iTree = $r.Flat.IndexOf('Branch and tree')
    Assert-True ($iLock -ge 0 -and $iTree -gt $iLock) 'the lock is printed BEFORE the repo blocks, not after them'

    Write-Host 'BOM-less UTF-8 is read as UTF-8, not as the ANSI codepage' -ForegroundColor Cyan
    # THE MEASURED BUG THIS PINS: PowerShell 5.1's Get-Content reads a BOM-less file in the system ANSI
    # codepage, so an em dash came back as three mojibake characters -- caught on this script's first run
    # against a real release note. Asserted on the note's section because that is the text a reader acts on.
    $dash = [string][char]0x2014
    $r = Invoke-Status -Fixture $fx
    Assert-True ($r.Flat -match 'the widget refactor') 'the still-open section is printed'
    Assert-True ($r.Flat.Contains($dash)) "and its em dash survives the read -- the mojibake regression"
    # The mangled form's FIRST character (U+00E2), built from its code point for the same reason the em
    # dash is: typing the mojibake literally into a pure-ASCII .ps1 is how the first draft of this file
    # broke its own parser. The fixture contains no legitimate U+00E2, so its presence can only be a
    # misdecoded lead byte.
    Assert-True (-not $r.Flat.Contains([string][char]0x00E2)) 'and the misdecoded lead byte does not appear'

    Write-Host 'Only the still-open section is printed, and it stops at the next heading' -ForegroundColor Cyan
    Assert-True ($r.Flat -match 'the second open thing') 'every line of the section is printed, not just the first'
    Assert-True (-not ($r.Flat -match 'must not be printed')) 'the FOLLOWING section is not swallowed'
    Assert-True (-not ($r.Flat -match 'Nothing to do')) 'and neither is the section BEFORE it'

    Write-Host 'The repo blocks report what the fixture actually contains' -ForegroundColor Cyan
    Assert-True ($r.Flat -match 'feat/a-branch') 'the pending entry is named'
    Assert-True ($r.Flat -match 'tier 0 -> 4') 'with the tier and score a release decision turns on'
    Assert-True ($r.Flat -match 'v1\.0\.0') 'the last tag is read'
    # A REMOTE-LESS REPO TAKES THE DEGRADE PATH, verified rather than assumed: git ls-remote fails, and
    # under ErrorActionPreference=Stop that surfaces as a terminating error the block catches. This is a
    # real consumer state (a fresh local repo), and what is pinned is that it SAYS so instead of printing
    # an empty block that reads as "nothing is parked".
    Assert-True ($r.Flat -match 'origin is unreachable') 'a remote-less fixture says the remote could not be read, rather than implying nothing is parked'

    Write-Host 'It writes nothing -- the contract both skills rely on' -ForegroundColor Cyan
    Push-Location $fx
    $eap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $dirty = @(git status --porcelain 2>&1 | Where-Object { $_ -notmatch 'my-lock\.md' })
    $ErrorActionPreference = $eap
    Pop-Location
    Assert-Equal 0 $dirty.Count 'the fixture tree is untouched after a run (the lock fixture aside)'

    Write-Host 'A parked branch on a real remote is listed, and the trunk is not' -ForegroundColor Cyan
    # THE POSITIVE PATH OF THE BLOCK THAT EXISTS BECAUSE OF A MEASURED MISS: a parked branch has no pull
    # request by design, so it is invisible to a local git status, to the pending entries and to the issue
    # list. Worth a bare remote in the fixture rather than only asserting the degrade line.
    $origin = Join-Path ([System.IO.Path]::GetTempPath()) ("sstat-origin-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $fixtures += $origin
    $eap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    git init --bare --quiet $origin 2>&1 | Out-Null
    Push-Location $fx
    git remote add origin $origin 2>&1 | Out-Null
    git push --quiet -u origin HEAD 2>&1 | Out-Null
    $trunkName = (git rev-parse --abbrev-ref HEAD).Trim()
    git checkout --quiet -b 'feat/parked-elsewhere' 2>&1 | Out-Null
    git push --quiet -u origin 'feat/parked-elsewhere' 2>&1 | Out-Null
    git checkout --quiet $trunkName 2>&1 | Out-Null
    Pop-Location
    $ErrorActionPreference = $eap
    $r = Invoke-Status -Fixture $fx
    Assert-True ($r.Flat -match 'feat/parked-elsewhere') 'the parked branch is named'
    Assert-True (-not ($r.Flat -match "Parked branches on origin.*$trunkName\b.*Open issues")) 'and the trunk is not listed as parked'

    Write-Host 'Every optional source degrades to a stated line, not an error' -ForegroundColor Cyan
    # A repo that has adopted none of this workflow: no CHANGELOG, no releases/, no tag, no remote. A
    # status command that fails because an optional source is absent is worse than no status command.
    $bare = New-Fixture -Bare; $fixtures += $bare
    $r = Invoke-Status -Fixture $bare
    Assert-Equal 0 $r.Code 'still exits 0 with every optional source missing'
    Assert-True ($r.Flat -match 'no CHANGELOG\.md') 'the absent changelog is named'
    Assert-True ($r.Flat -match 'no tags') 'the absent tag is named'
    Assert-True ($r.Flat -match 'no release note was found') 'the absent release note is named'
    Assert-True ($r.Flat -match 'Branch and tree') 'and the blocks that CAN be read still are'

    Write-Host 'The release note is found where Get-ReleaseNoteRoot says it is (#616)' -ForegroundColor Cyan
    # THIS IS THE READER HALF OF THE SEAM, and it is the half that fails in silence. cut-release writes the
    # note under the configured root; if this reporter kept looking under the default, the note would be
    # written to one place and looked for in another, and the miss prints as "no release note was found"
    # -- which reads like a repo that has not cut one yet rather than a repo whose seam is not honoured.
    $moved = New-Fixture -NoteRoot 'releases\stakeholders'; $fixtures += $moved
    $r = Invoke-Status -Fixture $moved
    Assert-Equal 0 $r.Code 'repointed note root: still exits 0'
    Assert-True ($r.Flat -match 'releases/stakeholders') 'the note is found under the configured root, and the source path says so'
    Assert-True (-not ($r.Flat -match 'no release note was found')) 'and it is NOT reported as absent'
    Assert-True ($r.Flat -match 'the widget refactor') 'the still-open section is read out of it, so the file was really parsed'
    # And the absent-line has to name the configured root too: it is the one message whose whole job is to
    # tell the reader where to look, so printing the default there sends them to a directory this repo does
    # not use.
    $movedBare = New-Fixture -NoteRoot 'releases\stakeholders'; $fixtures += $movedBare
    Remove-Item -LiteralPath (Join-Path $movedBare 'releases\stakeholders') -Recurse -Force
    $r = Invoke-Status -Fixture $movedBare
    Assert-True ($r.Flat -match 'no release note was found under releases/stakeholders/') `
        'when there is none, the absent line names the CONFIGURED root rather than the default'
}
finally {
    try { [Console]::OutputEncoding = $prevOut } catch { }
    foreach ($d in $fixtures) {
        if ($d -and (Test-Path -LiteralPath $d)) {
            Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILED: $($script:fail) of $($script:pass + $script:fail) asserts." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
