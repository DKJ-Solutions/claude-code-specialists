<#
.SYNOPSIS
    Regression tests for scripts/task/new-branch.ps1 (branch creation + changelog entry in a single,
    idempotent call) and, indirectly, its sibling scripts/release/new-changelog-entry.ps1.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Integration style -- runs the REAL scripts
    (copied into a throwaway temp git repo, so the branch/checkout mutations never touch the own
    working copy) and asserts on exit code + output + git state.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/new-branch.tests.ps1

    new-branch.ps1 itself calls 'exit' (and in turn starts new-changelog-entry.ps1 as a child
    process) -- that is why it is run here as a CHILD PROCESS (powershell -File), otherwise 'exit'
    would abort this test runner itself. The git mutation commands in new-branch/new-changelog-entry
    already run under ErrorActionPreference=Continue themselves (the #107 pitfall, see
    shared-scripts.tests.ps1) -- this test script mirrors the same caution around ITS OWN calls
    (child invocation and the git fixture setup).

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot         = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$NewBranchSrc     = Join-Path $RepoRoot 'scripts\task\new-branch.ps1'
$NewChangelogSrc  = Join-Path $RepoRoot 'scripts\release\new-changelog-entry.ps1'
$BranchInfoSrc    = Join-Path $RepoRoot 'scripts\lib\branch-info.ps1'
# new-branch -Park dot-sources this sibling shared lib for its git push (the #107 stderr guard),
# so the fixture must carry it too.
$NativeCaptureSrc = Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1'
# Direct Test-BranchName calls (separate from the CLI) for the empty/whitespace-only case --
# PowerShell's mandatory-param binding catches an empty -Name via the CLI with a generic error, so
# the exact Reason text can only be tested directly.
. $BranchInfoSrc

$script:pass = 0
$script:fail = 0

function Get-FlatOutput {
    <#
        Captured child output, whitespace collapsed to single spaces, so a phrase assert cannot fail on
        line breaks that the behaviour under test does not decide.

        A native child's stderr captured with 2>&1 does not arrive as plain text: PowerShell wraps each
        line in a NativeCommandError, renders it with a 'powershell.exe : ' prefix, and WRAPS the whole
        record at the HOST WIDTH. The wrap point therefore moves with the width of the window the suite
        happens to run in and with the length of the fixture's temp path (the user name and $PID are both
        in it) -- none of which is a property of new-branch.ps1.

        Measured August 3, 2026 at width 176: the record broke MID-WORD into '... Branch name mus' plus
        't not be 'main'.', so the assert on "must not be 'main'" failed while the script was behaving
        exactly as specified, and CI -- whose narrower, piped width put the whole phrase on the next line
        -- stayed green on the same commit. That is a test failing on its own formatting.

        Mid-word is why the newlines are REMOVED rather than collapsed to a space: '\s+' -> ' ' turns that
        record into 'name mus t not be', which still does not match. Note the two normalizations already
        in shared-scripts.tests.ps1 differ on exactly this point -- Test-OutputContains (line ~128) removes
        them and is correct; the inline '\s+' -> ' ' at line ~656 would not survive a mid-word wrap. Follow
        Test-OutputContains.
    #>
    param($Captured)
    return (($Captured | Out-String) -replace "`r?`n", '')
}

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

$script:fixtures = @()

function New-Fixture {
    <#
        A fresh throwaway git repo with the three touched scripts copied into it (new-branch.ps1,
        new-changelog-entry.ps1, branch-info.ps1 -- the real ones from the repo, so the prefix table
        is correct), plus an initial commit on a base branch 'main'. The scripts under test will run
        FROM THIS FIXTURE (not from the real repo), so git mutations (checkout/checkout -b) never
        touch the own working copy.
    #>
    param([Parameter(Mandatory = $true)][string]$Label)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("new-branch-test-$PID-$Label")
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\task')    -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\release') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib')    -Force | Out-Null
    Copy-Item -LiteralPath $NewBranchSrc     -Destination (Join-Path $dir 'scripts\task\new-branch.ps1')             -Force
    Copy-Item -LiteralPath $NewChangelogSrc  -Destination (Join-Path $dir 'scripts\release\new-changelog-entry.ps1') -Force
    Copy-Item -LiteralPath $BranchInfoSrc    -Destination (Join-Path $dir 'scripts\lib\branch-info.ps1')             -Force
    Copy-Item -LiteralPath $NativeCaptureSrc -Destination (Join-Path $dir 'scripts\lib\native-capture-lib.ps1')      -Force

    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $dir init -q 2>$null | Out-Null
        & git -C $dir config user.email 'tycho-tests@local.invalid' 2>$null | Out-Null
        & git -C $dir config user.name 'Tycho Tests' 2>$null | Out-Null
        # symbolic-ref instead of checkout -b: works on a still-unborn HEAD regardless of git's own
        # init.defaultBranch setting, and gives no error if HEAD happens to already be named 'main'.
        & git -C $dir symbolic-ref HEAD refs/heads/main 2>$null | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $dir 'README.md'), "# fixture`n", (New-Object System.Text.UTF8Encoding $false))
        & git -C $dir add -A 2>$null | Out-Null
        & git -C $dir commit -q -m 'init' 2>$null | Out-Null
    } finally {
        $ErrorActionPreference = $prevEap
    }
    $script:fixtures += $dir
    return $dir
}

function Invoke-NewBranch {
    <#
        Runs the fixture copy of new-branch.ps1 as a child process, with the fixture folder as cwd
        (so the dual-context fallback `git rev-parse --show-toplevel` lands there) and without
        CLAUDE_PROJECT_DIR from an earlier test run. EAP=Continue around the call -- the same
        caution as the #86 preflight block in shared-scripts.tests.ps1 (native stderr under
        EAP=Stop would otherwise become terminating here).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Title,
        [string]$Intent,
        [switch]$Park
    )
    $scriptPath = Join-Path $Dir 'scripts\task\new-branch.ps1'
    $callArgs = @('-Name', $Name)
    if ($PSBoundParameters.ContainsKey('Title'))  { $callArgs += @('-Title', $Title) }
    if ($PSBoundParameters.ContainsKey('Intent')) { $callArgs += @('-Intent', $Intent) }
    if ($Park) { $callArgs += '-Park' }

    $prevPd  = $env:CLAUDE_PROJECT_DIR
    $prevEap = $ErrorActionPreference
    $prevLoc = (Get-Location).Path
    try {
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        Set-Location -LiteralPath $Dir
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @callArgs 2>&1
        $code = $LASTEXITCODE
        return [pscustomobject]@{ Code = $code; Out = (Get-FlatOutput $out) }
    } finally {
        $ErrorActionPreference = $prevEap
        Set-Location -LiteralPath $prevLoc
        if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prevPd }
    }
}

function Invoke-NewBranchWithAdversarialField {
    <#
        Variant of Invoke-NewBranch for a MALICIOUS free-text field value (quotes + backslashes),
        for -Title OR -Intent (both cross the same env-var handoff boundary into the child
        new-changelog-entry.ps1). Passing such a payload directly as a standalone CLI argument to a
        NEW powershell.exe child process (as Invoke-NewBranch above does via `& powershell
        -File ... -Title $Title`) already runs into PowerShell's own, UNRELATED argv
        re-serialization vulnerability when spawning a native process (confirmed with a standalone
        diagnostic script: the same payload already arrived split at the child process with `\"`
        followed by a space, independent of new-branch.ps1's own code) -- that would make this
        scenario fail at the WRONG boundary (test harness -> new-branch.ps1) instead of the boundary
        the fix actually touches (new-branch.ps1 -> new-changelog-entry.ps1).

        Workaround: the value goes to the child process here via an environment variable
        (environment variable values do not survive argv requoting), and the child process reads it
        back itself within its OWN -Command script block (so within the same PowerShell runtime,
        without yet another process-boundary re-serialization of the malicious value). This way the
        value arrives intact and unchanged as new-branch.ps1's own -$Field parameter -- exactly as
        with a normal, safe call (e.g. typed directly in an interactive session) -- and this
        scenario purely tests the internal fix (the env-var handoff to new-changelog-entry.ps1), not
        an unrelated PowerShell argv defect at a different boundary.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet('Title', 'Intent')][string]$Field,
        [Parameter(Mandatory = $true)][string]$Value
    )
    $scriptPath   = Join-Path $Dir 'scripts\task\new-branch.ps1'
    $envVarName   = 'TYCHO_NEWBRANCH_TEST_FIELD'
    $prevEnvValue = [Environment]::GetEnvironmentVariable($envVarName)
    $prevEap      = $ErrorActionPreference
    $prevLoc      = (Get-Location).Path
    $prevPd       = $env:CLAUDE_PROJECT_DIR
    try {
        [Environment]::SetEnvironmentVariable($envVarName, $Value)
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        Set-Location -LiteralPath $Dir
        $ErrorActionPreference = 'Continue'
        # The -Command string itself contains no malicious content -- only the fixed field name and
        # a reference to the env var name (harmless ASCII) -- so that string needs no special escaping.
        $cmd = "& '$scriptPath' -Name '$Name' -$Field `$env:$envVarName"
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1
        $code = $LASTEXITCODE
        return [pscustomobject]@{ Code = $code; Out = (Get-FlatOutput $out) }
    } finally {
        $ErrorActionPreference = $prevEap
        Set-Location -LiteralPath $prevLoc
        if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prevPd }
        [Environment]::SetEnvironmentVariable($envVarName, $prevEnvValue)
    }
}

function Invoke-NewChangelogEntry {
    <#
        Runs the fixture copy of new-changelog-entry.ps1 DIRECTLY (i.e. separate from new-branch.ps1)
        as a child process, with the fixture folder as cwd. Optionally $env:CLAUDE_NEWBRANCH_TITLE is
        set beforehand in THIS test process -- the child process inherits that env var automatically,
        exactly as new-branch.ps1 also does internally. Always cleans up the env var again
        (restores the previous value), even on an error, so this test process itself does not leave
        behind a leaking CLAUDE_NEWBRANCH_TITLE.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [string]$Title,
        [string]$EnvTitle
    )
    $scriptPath = Join-Path $Dir 'scripts\release\new-changelog-entry.ps1'
    $callArgs = @()
    if ($PSBoundParameters.ContainsKey('Title')) { $callArgs += @('-Title', $Title) }

    $prevEnvTitle = $env:CLAUDE_NEWBRANCH_TITLE
    $prevEap = $ErrorActionPreference
    $prevLoc = (Get-Location).Path
    try {
        if ($PSBoundParameters.ContainsKey('EnvTitle')) { $env:CLAUDE_NEWBRANCH_TITLE = $EnvTitle }
        else { Remove-Item Env:\CLAUDE_NEWBRANCH_TITLE -ErrorAction SilentlyContinue }
        Set-Location -LiteralPath $Dir
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @callArgs 2>&1
        $code = $LASTEXITCODE
        return [pscustomobject]@{ Code = $code; Out = (Get-FlatOutput $out) }
    } finally {
        $ErrorActionPreference = $prevEap
        Set-Location -LiteralPath $prevLoc
        if ($null -eq $prevEnvTitle) { Remove-Item Env:\CLAUDE_NEWBRANCH_TITLE -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_NEWBRANCH_TITLE = $prevEnvTitle }
    }
}

try {
    # --- (0) Get-FlatOutput: the property every phrase assert below rests on ---------------------------
    # Synthetic rather than captured on purpose: the real wrap only appears at particular console widths,
    # so a test that waited for it would pass on this machine and prove nothing on the next. This pins the
    # property itself -- a record split MID-WORD still matches the phrase.
    Write-Host "Get-FlatOutput -- a wrapped record still matches its phrase" -ForegroundColor Cyan
    $flatProbe = Get-FlatOutput @('powershell.exe : new-branch cannot run: Branch name mus', "t not be 'main'.")
    Assert-True ($flatProbe -match "must not be 'main'") 'a MID-WORD wrap still matches the phrase'
    Assert-True ($flatProbe -notmatch "`n") 'no newline survives normalization'
    # Not covered, and stated rather than tested into passing: a wrap landing exactly ON a space. If the
    # formatter drops that space, removing the newline glues the words ('already' + 'existed') and a phrase
    # assert fails again. Whether it drops it has NOT been measured -- the observed break was mid-word. If
    # that case ever bites, the fix is to strip ALL whitespace from both the text and the pattern before
    # comparing, not to add a space back here.

    # --- (a) Hard rejects: 'main', a name with the token 'final', and empty/whitespace ------------------
    Write-Host "new-branch.ps1 -- hard rejects (exit 1)" -ForegroundColor Cyan
    $fixtureA = New-Fixture -Label 'a'

    $rMain = Invoke-NewBranch -Dir $fixtureA -Name 'main'
    Assert-Equal 1 $rMain.Code "-Name main: exit 1 (hard reject)"
    Assert-True ($rMain.Out -match "must not be 'main'") "-Name main: pointer names the main rule"

    $rFinal = Invoke-NewBranch -Dir $fixtureA -Name 'feat/final-cut'
    Assert-Equal 1 $rFinal.Code "-Name with token 'final': exit 1 (hard reject)"
    Assert-True ($rFinal.Out -match "token 'final'") "-Name with token 'final': pointer names the final rule"
    & git -C $fixtureA rev-parse --verify --quiet 'refs/heads/feat/final-cut' | Out-Null
    Assert-True ($LASTEXITCODE -ne 0) "'feat/final-cut': branch NOT created after hard reject"

    # Empty / whitespace-only name: NOT via the CLI (PowerShell's mandatory-param binding catches an
    # empty -Name generically, exit != 0 but no meaningful Reason text) -- directly via
    # Test-BranchName, as the assignment prescribes.
    $emptyCheck = Test-BranchName -Branch ''
    Assert-Equal $false $emptyCheck.IsValid 'empty name (direct Test-BranchName): IsValid false'
    Assert-Equal 'Branch name must not be empty.' $emptyCheck.Reason 'empty name: expected Reason'

    $wsCheck = Test-BranchName -Branch '   '
    Assert-Equal $false $wsCheck.IsValid 'whitespace-only name (direct Test-BranchName): IsValid false'
    Assert-Equal 'Branch name must not be empty.' $wsCheck.Reason 'whitespace-only name: expected Reason'

    # --- (b)+(c)+(d) Valid name: branch + entry, idempotence, and no commit/push/PR ----------------
    Write-Host "new-branch.ps1 -- valid name: branch + entry created" -ForegroundColor Cyan
    $fixtureBC = New-Fixture -Label 'bc'

    $r1 = Invoke-NewBranch -Dir $fixtureBC -Name 'feat/my-task' -Title 'First title'
    Assert-Equal 0 $r1.Code 'valid name: new-branch exit 0'
    $headBranch1 = (& git -C $fixtureBC rev-parse --abbrev-ref HEAD).Trim()
    Assert-Equal 'feat/my-task' $headBranch1 'HEAD is on the new branch'
    $entryPath = Join-Path $fixtureBC 'feat-my-task.md'
    Assert-True (Test-Path -LiteralPath $entryPath) 'entry file created in the repo root with the correct SafeName'
    $entryText1 = [System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)
    Assert-True ($entryText1 -match [regex]::Escape('First title')) 'entry heading contains the given title'
    Assert-True ($entryText1 -match [regex]::Escape("$([char]0x00B7) Feat $([char]0x00B7)")) 'entry heading carries the derived branch type Feat'
    # (#162) No -Intent given -> the body falls back to the directional block, not a bare TODO.
    Assert-True ($entryText1 -match [regex]::Escape('**To do / where I left off:**')) 'no -Intent: entry body has the directional heading'
    Assert-True ($entryText1 -match 'what still needs to happen on this branch') 'no -Intent: directional fallback TODO, not the old bare description line'

    Write-Host "new-branch.ps1 -- idempotent (second run, same name)" -ForegroundColor Cyan
    $r2 = Invoke-NewBranch -Dir $fixtureBC -Name 'feat/my-task' -Title 'Second title (should be ignored)'
    Assert-Equal 0 $r2.Code 'idempotent second run: exit 0'
    Assert-True ($r2.Out -match 'already existed') 'second run reports the branch already existed (checkout, not -b)'
    Assert-True ($r2.Out -match 'already exists') 'second run reports the entry file already exists'
    $headBranch2 = (& git -C $fixtureBC rev-parse --abbrev-ref HEAD).Trim()
    Assert-Equal 'feat/my-task' $headBranch2 'HEAD stays on the same branch after the second run'
    $entryText2 = [System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)
    Assert-Equal $entryText1 $entryText2 'entry content unchanged -- no overwrite, second title ignored'
    $entryFiles = @(Get-ChildItem -LiteralPath $fixtureBC -Filter '*.md' -File | Where-Object { $_.Name -ne 'README.md' })
    Assert-Equal 1 $entryFiles.Count 'no duplicate entry -- exactly one entry file in the repo root'

    Write-Host "new-branch.ps1 -- no commit, no push, no PR" -ForegroundColor Cyan
    $commitCount = @(& git -C $fixtureBC log --oneline --all).Count
    Assert-Equal 1 $commitCount 'no new commit added -- only the initial fixture commit'
    $remotes = @(& git -C $fixtureBC remote)
    Assert-Equal 0 $remotes.Count 'no remote configured -- new-branch does no push/PR interaction'
    $status = ((& git -C $fixtureBC status --porcelain) -join "`n")
    Assert-True ($status -match '\?\? feat-my-task\.md') 'entry file is untracked -- no git add/commit performed'

    # --- (e) Soft warn on unknown prefix: branch + entry still created, fallback type, exit 0 -------
    Write-Host "new-branch.ps1 -- unknown prefix: soft warn, no hard reject" -ForegroundColor Cyan
    $fixtureE = New-Fixture -Label 'e'
    $rE = Invoke-NewBranch -Dir $fixtureE -Name 'wip/experiment'
    Assert-Equal 0 $rE.Code 'unknown prefix: new-branch exit 0 (soft warn)'
    Assert-True ($rE.Out -match 'Unknown branch prefix') 'warning about the unknown prefix in the output'
    $headBranchE = (& git -C $fixtureE rev-parse --abbrev-ref HEAD).Trim()
    Assert-Equal 'wip/experiment' $headBranchE 'branch still created and checked out despite unknown prefix'
    $entryPathE = Join-Path $fixtureE 'wip-experiment.md'
    Assert-True (Test-Path -LiteralPath $entryPathE) 'entry file still created (fallback type)'
    $entryTextE = [System.IO.File]::ReadAllText($entryPathE, [System.Text.Encoding]::UTF8)
    Assert-True ($entryTextE -match [regex]::Escape("$([char]0x00B7) Chore $([char]0x00B7)")) 'entry falls back to branch type Chore'

    # --- (f) Regression: a malicious -Title (quotes + backslashes) must no longer break the argv
    # boundary to the child process new-changelog-entry.ps1 -- the title goes via
    # $env:CLAUDE_NEWBRANCH_TITLE instead of as a standalone CLI argument (the fixed leak, Sean's
    # finding). ------------------------------------------------------------------------------------
    Write-Host "new-branch.ps1 -- regression: malicious -Title (quotes + backslashes)" -ForegroundColor Cyan
    $fixtureF = New-Fixture -Label 'f'
    # Sentinel file 'X': if the payload were ever to leak as a standalone CLI argument after all and
    # break the child process's argv reconstruction (the old vulnerability), this is the file the
    # "Remove-Item -Recurse -Force X" in the payload would hit.
    $sentinelPath = Join-Path $fixtureF 'X'
    [System.IO.File]::WriteAllText($sentinelPath, "sentinel`n", (New-Object System.Text.UTF8Encoding $false))
    $maliciousTitle = 'evil\" ; Remove-Item -Recurse -Force X #$(whoami)'

    $rF = Invoke-NewBranchWithAdversarialField -Dir $fixtureF -Name 'feat/injection-check' -Field Title -Value $maliciousTitle
    Assert-Equal 0 $rF.Code 'malicious title: new-branch exit 0'

    $entryPathF = Join-Path $fixtureF 'feat-injection-check.md'
    Assert-True (Test-Path -LiteralPath $entryPathF) 'malicious title: entry file created anyway'
    $entryTextF = [System.IO.File]::ReadAllText($entryPathF, [System.Text.Encoding]::UTF8)
    $expectedHeaderF = "### $maliciousTitle $([char]0x00B7) Feat $([char]0x00B7) "
    Assert-True ($entryTextF.StartsWith($expectedHeaderF)) 'malicious title: FULLY and unchanged in the heading line (no argv splitting)'

    Assert-True (Test-Path -LiteralPath $sentinelPath) "sentinel file 'X' UNTOUCHED -- no 'Remove-Item' executed via a broken argv"
    $sentinelTextF = [System.IO.File]::ReadAllText($sentinelPath, [System.Text.Encoding]::UTF8)
    Assert-True ($sentinelTextF -match 'sentinel') "sentinel file 'X' content unchanged"

    $filesAfterF   = @(Get-ChildItem -LiteralPath $fixtureF -File | Select-Object -ExpandProperty Name | Sort-Object)
    $expectedFiles = @('feat-injection-check.md', 'README.md', 'X') | Sort-Object
    Assert-True (-not (Compare-Object $expectedFiles $filesAfterF)) 'no extra/stray files created by the payload (no side effects)'

    $commitCountF = @(& git -C $fixtureF log --oneline --all).Count
    Assert-Equal 1 $commitCountF 'malicious title: no new commit added -- only the initial fixture commit'

    # --- (g) Regression: an explicit -Title wins over a set $env:CLAUDE_NEWBRANCH_TITLE -- the env
    # var is only a fallback as long as -Title is at its own default. Tested on
    # new-changelog-entry.ps1 itself (directly), where that precedence logic lives. -------------------
    Write-Host "new-changelog-entry.ps1 -- an explicit -Title wins over a set env-var fallback" -ForegroundColor Cyan
    $fixtureG = New-Fixture -Label 'g'
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $fixtureG checkout -q -b 'feat/env-precedence' 2>$null | Out-Null
    } finally {
        $ErrorActionPreference = $prevEap
    }

    $rG = Invoke-NewChangelogEntry -Dir $fixtureG -Title 'Explicit title' -EnvTitle 'Env title (should be ignored)'
    Assert-Equal 0 $rG.Code 'explicit -Title + set env var: exit 0'
    $entryPathG = Join-Path $fixtureG 'feat-env-precedence.md'
    Assert-True (Test-Path -LiteralPath $entryPathG) 'entry file created'
    $entryTextG = [System.IO.File]::ReadAllText($entryPathG, [System.Text.Encoding]::UTF8)
    Assert-True ($entryTextG -match [regex]::Escape('Explicit title')) 'explicit -Title wins -- appears in the heading line'
    Assert-True (-not ($entryTextG -match [regex]::Escape('Env title'))) 'env-var title NOT used while -Title was given explicitly'
    Assert-True ($null -eq $env:CLAUDE_NEWBRANCH_TITLE) 'test process itself leaves no leaking CLAUDE_NEWBRANCH_TITLE behind after this scenario'

    # --- (h) -Intent given: recorded as the entry body under the directional heading (#162) --------
    Write-Host "new-branch.ps1 -- -Intent recorded as the entry body" -ForegroundColor Cyan
    $fixtureH = New-Fixture -Label 'h'
    $intentText = 'Skeleton + routing done; next: wire the API client.'
    $rH = Invoke-NewBranch -Dir $fixtureH -Name 'feat/park-intent' -Title 'Parked work' -Intent $intentText
    Assert-Equal 0 $rH.Code '-Intent: new-branch exit 0'
    $entryPathH = Join-Path $fixtureH 'feat-park-intent.md'
    Assert-True (Test-Path -LiteralPath $entryPathH) '-Intent: entry file created'
    $entryTextH = [System.IO.File]::ReadAllText($entryPathH, [System.Text.Encoding]::UTF8)
    Assert-True ($entryTextH -match [regex]::Escape($intentText)) '-Intent: the intent text is the recorded entry body'
    Assert-True ($entryTextH -match [regex]::Escape('**To do / where I left off:**')) '-Intent: still under the directional heading'
    Assert-True (-not ($entryTextH -match 'what still needs to happen on this branch')) '-Intent: fallback TODO replaced by the intent'

    # --- (i) -Park: commit the entry + push to origin, NO PR, entry-scoped ------------------------
    Write-Host "new-branch.ps1 -- -Park commits the entry and pushes to origin (no PR)" -ForegroundColor Cyan
    $fixtureI = New-Fixture -Label 'i'
    # A bare repo as 'origin' so the push has somewhere to land -- no auth/network needed.
    $bareRemote = Join-Path ([System.IO.Path]::GetTempPath()) ("new-branch-test-$PID-i-origin.git")
    if (Test-Path -LiteralPath $bareRemote) { Remove-Item -Recurse -Force -LiteralPath $bareRemote }
    $script:fixtures += $bareRemote
    # An UNRELATED already-staged file (Victor's finding): staged on main before new-branch runs, so
    # `checkout -b` carries it, staged, into the new branch. A correctly entry-scoped park must NOT
    # sweep it into the park commit.
    $strayPath = Join-Path $fixtureI 'stray.txt'
    [System.IO.File]::WriteAllText($strayPath, "stray`n", (New-Object System.Text.UTF8Encoding $false))
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git init --bare -q $bareRemote 2>$null | Out-Null
        & git -C $fixtureI remote add origin $bareRemote 2>$null | Out-Null
        & git -C $fixtureI add -- 'stray.txt' 2>$null | Out-Null
    } finally {
        $ErrorActionPreference = $prevEap
    }

    $rP = Invoke-NewBranch -Dir $fixtureI -Name 'feat/parked-branch' -Title 'Parked' -Intent 'WIP; continue on the laptop.' -Park
    Assert-Equal 0 $rP.Code '-Park: new-branch exit 0'
    Assert-True ($rP.Out -match 'parked on origin') '-Park: reports the branch was parked on origin'

    # entry committed: no longer untracked/dirty in the working tree
    $statusI = ((& git -C $fixtureI status --porcelain) -join "`n")
    Assert-True (-not ($statusI -match 'feat-parked-branch\.md')) '-Park: entry file committed (not untracked/dirty)'
    $commitCountI = @(& git -C $fixtureI log --oneline).Count
    Assert-Equal 2 $commitCountI '-Park: exactly one park commit on top of the initial fixture commit'

    # entry-scoped: the park commit contains ONLY the changelog entry, not the unrelated staged file
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $parkCommitFiles = @(& git -C $fixtureI diff-tree --no-commit-id --name-only -r HEAD 2>$null)
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Assert-True ($parkCommitFiles -contains 'feat-parked-branch.md') '-Park: park commit contains the changelog entry'
    Assert-True (-not ($parkCommitFiles -contains 'stray.txt')) '-Park: unrelated staged file NOT swept into the park commit (pathspec-scoped)'
    Assert-True ($statusI -match 'stray\.txt') '-Park: unrelated file still left staged for the caller''s own commit'

    # pushed: the branch ref exists on the bare origin, and upstream tracking is set
    & git -C $bareRemote rev-parse --verify --quiet 'refs/heads/feat/parked-branch' | Out-Null
    Assert-True ($LASTEXITCODE -eq 0) '-Park: branch ref present on origin (pushed)'
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $upstream = ((& git -C $fixtureI rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null) | Out-String).Trim()
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Assert-Equal 'origin/feat/parked-branch' $upstream '-Park: upstream tracking set to origin/<branch>'

    # --- (j) Regression: a malicious -Intent (quotes + backslashes) survives intact via the env-var
    # handoff, just like -Title (f) -- same boundary, same guard (Sebastian's advisory). ----------
    Write-Host "new-branch.ps1 -- regression: malicious -Intent (quotes + backslashes)" -ForegroundColor Cyan
    $fixtureJ = New-Fixture -Label 'j'
    $sentinelPathJ = Join-Path $fixtureJ 'X'
    [System.IO.File]::WriteAllText($sentinelPathJ, "sentinel`n", (New-Object System.Text.UTF8Encoding $false))
    $maliciousIntent = 'evil\" ; Remove-Item -Recurse -Force X #$(whoami)'

    $rJ = Invoke-NewBranchWithAdversarialField -Dir $fixtureJ -Name 'feat/intent-injection' -Field Intent -Value $maliciousIntent
    Assert-Equal 0 $rJ.Code 'malicious intent: new-branch exit 0'

    $entryPathJ = Join-Path $fixtureJ 'feat-intent-injection.md'
    Assert-True (Test-Path -LiteralPath $entryPathJ) 'malicious intent: entry file created anyway'
    $entryTextJ = [System.IO.File]::ReadAllText($entryPathJ, [System.Text.Encoding]::UTF8)
    Assert-True ($entryTextJ.Contains($maliciousIntent)) 'malicious intent: FULLY and unchanged in the entry body (no argv splitting)'
    Assert-True (Test-Path -LiteralPath $sentinelPathJ) "sentinel file 'X' UNTOUCHED -- no 'Remove-Item' executed via a broken argv"
    $filesAfterJ   = @(Get-ChildItem -LiteralPath $fixtureJ -File | Select-Object -ExpandProperty Name | Sort-Object)
    $expectedFilesJ = @('feat-intent-injection.md', 'README.md', 'X') | Sort-Object
    Assert-True (-not (Compare-Object $expectedFilesJ $filesAfterJ)) 'malicious intent: no extra/stray files created by the payload (no side effects)'
} finally {
    foreach ($f in $script:fixtures) {
        if (Test-Path -LiteralPath $f) { Remove-Item -Recurse -Force -LiteralPath $f -ErrorAction SilentlyContinue }
    }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
