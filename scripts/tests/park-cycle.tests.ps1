<#
.SYNOPSIS
    Regression tests for scripts/task/park-cycle.ps1 -- the automatic push of the branch's development
    cycle to origin, and every bound that stops it (#900).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Integration style -- runs the REAL script in a
    throwaway temp git repo with a bare 'origin', so the commit/push mutations never touch the own
    working copy or a real remote.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/park-cycle.tests.ps1

    THE gh SHIM IS THE POINT OF THIS SUITE, not a workaround. park-cycle's most important bound is that
    it becomes a no-op once a PR exists -- without that, it would break the DEPLOY lock (#884) on every
    branch in the repo. A bare repo is not a GitHub remote, so a real `gh pr list` against a fixture
    fails, and a suite that accepted that would only ever exercise the fail-safe path and would report
    "no PR" and "gh is broken" as the same green. So each fixture gets a `gh` of its own, first on PATH,
    answering the one shape this script parses. All three answers are then reachable: no PR, a PR, and
    gh failing.

    park-cycle.ps1 itself calls 'exit', so it is run here as a CHILD PROCESS (powershell -File). Its own
    git calls run under ErrorActionPreference=Continue via the shared Invoke-NativeCapture (the #107
    pitfall) -- this suite mirrors the same caution around its own fixture git calls.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path

# Every lib park-cycle.ps1 dot-sources $PSScriptRoot-relative. A fixture missing one has no script at
# all, so they are named here rather than globbed: a lib that is added to the script and forgotten here
# must fail loudly in this suite, not be silently supplied by a wildcard.
$ParkCycleSrc     = Join-Path $RepoRoot 'scripts\task\park-cycle.ps1'
$NativeCaptureSrc = Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1'
$EntryScaffoldSrc = Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1'
$ParkLibSrc       = Join-Path $RepoRoot 'scripts\lib\park-lib.ps1'
$PrIssuesSrc      = Join-Path $RepoRoot 'scripts\lib\pr-issues-lib.ps1'

# The cycle path and the scope phrases are read from the shared libs rather than retyped, so a rename
# stays a one-place change -- the same discipline new-branch.tests.ps1 and park-branch.tests.ps1 follow.
. $EntryScaffoldSrc
. $NativeCaptureSrc
. $ParkLibSrc

$script:pass = 0
$script:fail = 0
$script:fixtures = @()

function Get-FlatOutput {
    <# Captured child output with the line breaks removed, so a phrase assert cannot fail on a wrap
       point that park-cycle.ps1 does not decide. Same reasoning as park-branch.tests.ps1's copy. #>
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

function New-Fixture {
    <#
        A throwaway git repo with park-cycle.ps1 and its four libs copied in, an initial commit on
        'main', and (unless -NoOrigin) a bare repo wired up as 'origin'. Also writes a `gh` shim whose
        answer is chosen by -GhAnswer: 'none' (an empty list), 'pr' (one PR, number 42) or 'fail'
        (exit 1, which is how gh missing, logged out or offline all arrive).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [ValidateSet('none', 'pr', 'fail')][string]$GhAnswer = 'none',
        [switch]$NoOrigin,
        # Writes a scripts/repo-config.ps1 answering the OPTIONAL trunk seam with this name. Omitted:
        # no repo-config at all, which is the unadopted repo every other fixture here models.
        [string]$TrunkName = ''
    )
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("park-cycle-test-$PID-$Label")
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\task') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib')  -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir '_bin')         -Force | Out-Null
    Copy-Item -LiteralPath $ParkCycleSrc     -Destination (Join-Path $dir 'scripts\task\park-cycle.ps1')        -Force
    Copy-Item -LiteralPath $NativeCaptureSrc -Destination (Join-Path $dir 'scripts\lib\native-capture-lib.ps1') -Force
    Copy-Item -LiteralPath $EntryScaffoldSrc -Destination (Join-Path $dir 'scripts\lib\entry-scaffold-lib.ps1') -Force
    Copy-Item -LiteralPath $ParkLibSrc       -Destination (Join-Path $dir 'scripts\lib\park-lib.ps1')           -Force
    Copy-Item -LiteralPath $PrIssuesSrc      -Destination (Join-Path $dir 'scripts\lib\pr-issues-lib.ps1')      -Force

    # A .cmd rather than a .ps1: Invoke-NativeCapture resolves 'gh' as a native command, and only an
    # executable extension on PATHEXT is found that way.
    $ghBody = switch ($GhAnswer) {
        'none' { "@echo off`r`necho []`r`n" }
        'pr'   { "@echo off`r`necho [{`"number`":42}]`r`n" }
        'fail' { "@echo off`r`nexit /b 1`r`n" }
    }
    [System.IO.File]::WriteAllText((Join-Path $dir '_bin\gh.cmd'), $ghBody, (New-Object System.Text.ASCIIEncoding))

    if ($TrunkName) {
        $cfg = "function Get-TrunkBranchName { '$TrunkName' }`r`n"
        [System.IO.File]::WriteAllText((Join-Path $dir 'scripts\repo-config.ps1'), $cfg, (New-Object System.Text.ASCIIEncoding))
    }

    $bareRemote = "$dir.git"
    if (Test-Path -LiteralPath $bareRemote) { Remove-Item -Recurse -Force -LiteralPath $bareRemote }

    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $dir init -q 2>$null | Out-Null
        & git -C $dir config user.email 'tycho-tests@local.invalid' 2>$null | Out-Null
        & git -C $dir config user.name 'Tycho Tests' 2>$null | Out-Null
        # symbolic-ref rather than checkout -b: works on a still-unborn HEAD whatever git's own
        # init.defaultBranch says. Same reasoning as park-branch.tests.ps1.
        & git -C $dir symbolic-ref HEAD refs/heads/main 2>$null | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $dir 'README.md'), "# fixture`n", (New-Object System.Text.UTF8Encoding $false))
        & git -C $dir add -A 2>$null | Out-Null
        & git -C $dir commit -q -m 'init' 2>$null | Out-Null
        if (-not $NoOrigin) {
            & git init --bare -q $bareRemote 2>$null | Out-Null
            & git -C $dir remote add origin $bareRemote 2>$null | Out-Null
        }
    } finally { $ErrorActionPreference = $prevEap }

    $script:fixtures += $dir
    $script:fixtures += $bareRemote
    return $dir
}

function New-CycleDocument {
    <#
        Writes a development cycle at the path the shared resolver expects, declaring $Branch in its
        heading -- the shape Get-BranchFileDeclaredBranch reads. -Branch '' writes a reset document
        (no name at all), which is the state the trunk carries.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Branch,
        [string]$Body = 'work in progress'
    )
    $rel = (Get-BranchFilePaths).Cycle
    $full = Join-Path $Dir ($rel -replace '/', '\')
    New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force | Out-Null
    $heading = if ($Branch) { "## Development cycle: ``$Branch``" } else { '# Development cycle' }
    [System.IO.File]::WriteAllText($full, "$heading`n`n$Body`n", (New-Object System.Text.UTF8Encoding $false))
    return $rel
}

function Invoke-ParkCycle {
    <#
        Runs the fixture copy as a child process, with the fixture as cwd (so the dual-context fallback
        `git rev-parse --show-toplevel` lands there), without a CLAUDE_PROJECT_DIR left over from an
        earlier run, and with the fixture's own _bin first on PATH so its `gh` shim is the one found.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [switch]$Quiet
    )
    $scriptPath = Join-Path $Dir 'scripts\task\park-cycle.ps1'
    $callArgs = @()
    if ($Quiet) { $callArgs += '-Quiet' }

    $prevPd   = $env:CLAUDE_PROJECT_DIR
    $prevPath = $env:PATH
    $prevEap  = $ErrorActionPreference
    $prevLoc  = (Get-Location).Path
    try {
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        $env:PATH = (Join-Path $Dir '_bin') + ';' + $prevPath
        Set-Location -LiteralPath $Dir
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @callArgs 2>&1
        $code = $LASTEXITCODE
        return [pscustomobject]@{ Code = $code; Out = (Get-FlatOutput $out) }
    } finally {
        $ErrorActionPreference = $prevEap
        Set-Location -LiteralPath $prevLoc
        $env:PATH = $prevPath
        if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prevPd }
    }
}

function Get-CommitMessage {
    <#
        The last commit's full message with every run of whitespace collapsed to one space.

        THE COLLAPSE IS NOT COSMETIC. The backing note is WRAPPED for commit-body width, so where the
        line break falls is park-lib's decision about rendering rather than a fact about the note -- and
        a phrase assert pinned across it goes red the moment a clause is reworded by a word. Same
        reasoning as Get-FlatOutput above, one layer along.
    #>
    param([Parameter(Mandatory = $true)][string]$Dir)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        return ((((& git -C $Dir log -1 --pretty=%B) | Out-String) -replace '\s+', ' ').Trim())
    } finally { $ErrorActionPreference = $prevEap }
}

function Get-CommitCount {
    param([Parameter(Mandatory = $true)][string]$Dir)
    $prevEap = $ErrorActionPreference
    try { $ErrorActionPreference = 'Continue'; return @(& git -C $Dir log --oneline).Count }
    finally { $ErrorActionPreference = $prevEap }
}

function Get-HeadFiles {
    param([Parameter(Mandatory = $true)][string]$Dir)
    $prevEap = $ErrorActionPreference
    try { $ErrorActionPreference = 'Continue'; return @(& git -C $Dir diff-tree --no-commit-id --name-only -r HEAD 2>$null) }
    finally { $ErrorActionPreference = $prevEap }
}

function Test-RefOnRemote {
    param([Parameter(Mandatory = $true)][string]$Bare, [Parameter(Mandatory = $true)][string]$Ref)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $Bare rev-parse --verify --quiet $Ref 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } finally { $ErrorActionPreference = $prevEap }
}

function Switch-ToBranch {
    param([Parameter(Mandatory = $true)][string]$Dir, [Parameter(Mandatory = $true)][string]$Name)
    $prevEap = $ErrorActionPreference
    try { $ErrorActionPreference = 'Continue'; & git -C $Dir checkout -q -b $Name 2>$null | Out-Null }
    finally { $ErrorActionPreference = $prevEap }
}

try {
    # --- (a) THE HAPPY PATH: a dirty document, no PR -> committed and pushed, one file only ---------
    Write-Host "park-cycle.ps1 -- pushes the development cycle when no PR exists" -ForegroundColor Cyan
    $fixA = New-Fixture -Label 'a' -GhAnswer 'none'
    Switch-ToBranch -Dir $fixA -Name 'feat/visible-v1'
    $relA = New-CycleDocument -Dir $fixA -Branch 'feat/visible-v1'
    # An unrelated dirty file, the bound that matters most: an AUTOMATIC park that swept this in would
    # publish work in progress nobody asked to publish. park-branch does sweep it, deliberately; this
    # must not.
    [System.IO.File]::WriteAllText((Join-Path $fixA 'stray.txt'), "stray`n", (New-Object System.Text.UTF8Encoding $false))

    $rA = Invoke-ParkCycle -Dir $fixA
    Assert-Equal 0 $rA.Code 'happy path: exit 0'
    Assert-True ($rA.Out -match 'parked on origin') 'happy path: reports the document reached origin'
    Assert-Equal 2 (Get-CommitCount -Dir $fixA) 'happy path: exactly one park commit on top of the fixture commit'
    $filesA = Get-HeadFiles -Dir $fixA
    Assert-True ($filesA -contains $relA) 'happy path: the commit carries the development cycle'
    Assert-Equal 1 $filesA.Count 'happy path: and NOTHING else -- the unrelated dirty file stayed out'
    Assert-True (Test-RefOnRemote -Bare "$fixA.git" -Ref 'refs/heads/feat/visible-v1') 'happy path: the branch ref is on origin'
    $msgA = Get-CommitMessage -Dir $fixA
    Assert-True ($msgA -match [regex]::Escape((Get-GitParkScopes)['BranchFiles'])) 'happy path: the commit names the branch-files scope it committed'
    # THE BACKING NOTE (#960), on the ordinary park: it is always stamped, so its ABSENCE cannot be read
    # as "this park was fine". fixA's document carries no steps and one unrelated dirty file.
    Assert-True ($msgA -match [regex]::Escape((Get-GitParkBackingMarker))) 'happy path: the commit body carries the backing note'
    Assert-True ($msgA -match 'no steps written yet') 'happy path: and says the plan has no steps yet rather than reporting zero of zero done'
    Assert-True ($msgA -match '1 file\(s\) uncommitted') 'happy path: it counts the unrelated dirty file as unpublished work'
    Assert-True (-not ($msgA -match 'stray')) 'happy path: COUNTS, NEVER FILENAMES -- the unrelated path is not named in a public commit'
    Assert-True (-not ($msgA -match 'reads as FINISHED')) 'happy path: and no alarm on a plan that never claimed to be finished'
    # The note is BODY, not subject: a `git log --oneline` of a branch stays readable.
    $subjA = ((& git -C $fixA log -1 --pretty=%s) | Out-String).Trim()
    Assert-True (-not ($subjA -match [regex]::Escape((Get-GitParkBackingMarker)))) 'happy path: the note stays out of the subject line'

    # --- (b) IDEMPOTENT: a second run has nothing to do, and says so ------------------------------
    Write-Host "park-cycle.ps1 -- a second run does nothing" -ForegroundColor Cyan
    $rB = Invoke-ParkCycle -Dir $fixA
    Assert-Equal 0 $rB.Code 'second run: exit 0'
    Assert-True ($rB.Out -match 'already on origin') 'second run: says the document is already on origin'
    Assert-Equal 2 (Get-CommitCount -Dir $fixA) 'second run: no second commit'

    # --- (c) -Quiet: the hook path prints NOTHING when there is nothing to do ---------------------
    # The assert that keeps the hook usable. Without it this would add a line to every turn of every
    # session, which is the difference between a hook nobody notices and one everybody turns off.
    Write-Host "park-cycle.ps1 -- -Quiet is silent when there is nothing to do" -ForegroundColor Cyan
    $rC = Invoke-ParkCycle -Dir $fixA -Quiet
    Assert-Equal 0 $rC.Code '-Quiet: exit 0'
    Assert-Equal '' $rC.Out.Trim() '-Quiet: no output at all'

    # --- (d) THE DEPLOY LOCK (#884): a PR exists -> no commit, no push ----------------------------
    # THE MOST IMPORTANT BOUND IN THE SCRIPT. ship-pr refuses the merge once this document has diverged
    # from what the PR published, so a pusher that kept running after open-pr would block every merge in
    # the repo -- and the failure would read as the lock misbehaving rather than as this.
    Write-Host "park-cycle.ps1 -- a PR exists: the document is the PR's from there on" -ForegroundColor Cyan
    $fixD = New-Fixture -Label 'd' -GhAnswer 'pr'
    Switch-ToBranch -Dir $fixD -Name 'feat/has-a-pr-v1'
    $null = New-CycleDocument -Dir $fixD -Branch 'feat/has-a-pr-v1'

    $rD = Invoke-ParkCycle -Dir $fixD
    Assert-Equal 0 $rD.Code 'PR open: exit 0 -- this is a normal outcome, not an error'
    Assert-True ($rD.Out -match 'PR #42 is open') 'PR open: names the PR it found'
    Assert-Equal 1 (Get-CommitCount -Dir $fixD) 'PR open: nothing committed'
    Assert-True (-not (Test-RefOnRemote -Bare "$fixD.git" -Ref 'refs/heads/feat/has-a-pr-v1')) 'PR open: nothing pushed'

    # --- (e) gh CANNOT ANSWER -> fail-safe: do not push -------------------------------------------
    # gh missing, logged out, offline, or an unparseable payload all arrive here. Being one turn stale is
    # a nuisance; an unmergeable branch is a defect, so unknown does not push.
    Write-Host "park-cycle.ps1 -- gh cannot answer: fail-safe, no push" -ForegroundColor Cyan
    $fixE = New-Fixture -Label 'e' -GhAnswer 'fail'
    Switch-ToBranch -Dir $fixE -Name 'feat/gh-broken-v1'
    $null = New-CycleDocument -Dir $fixE -Branch 'feat/gh-broken-v1'

    $rE = Invoke-ParkCycle -Dir $fixE
    Assert-Equal 0 $rE.Code 'gh failing: exit 0'
    Assert-True ($rE.Out -match 'not pushing') 'gh failing: says it is not pushing'
    Assert-True ($rE.Out -match 'DEPLOY lock') 'gh failing: and names the reason, so the direction is not read as a bug'
    Assert-Equal 1 (Get-CommitCount -Dir $fixE) 'gh failing: nothing committed'
    Assert-True (-not (Test-RefOnRemote -Bare "$fixE.git" -Ref 'refs/heads/feat/gh-broken-v1')) 'gh failing: nothing pushed'

    # --- (f) ON THE TRUNK: nothing to do, and it says why ----------------------------------------
    Write-Host "park-cycle.ps1 -- on the trunk, where the fold removes this document" -ForegroundColor Cyan
    $fixF = New-Fixture -Label 'f' -GhAnswer 'none'
    $null = New-CycleDocument -Dir $fixF -Branch 'feat/not-checked-out-v1'

    $rF = Invoke-ParkCycle -Dir $fixF
    Assert-Equal 0 $rF.Code 'trunk: exit 0'
    Assert-True ($rF.Out -match 'on the trunk') 'trunk: names the trunk rule'
    Assert-Equal 1 (Get-CommitCount -Dir $fixF) 'trunk: nothing committed'

    # --- (g) A RESET DOCUMENT declares no branch -> left alone -----------------------------------
    # Resolve-BranchFilePath falls back to a path that merely EXISTS when nothing claims the branch, so
    # without this check a branch created outside new-branch would push the trunk's own empty document
    # under a `park:` subject.
    Write-Host "park-cycle.ps1 -- a reset document belongs to no branch" -ForegroundColor Cyan
    $fixG = New-Fixture -Label 'g' -GhAnswer 'none'
    Switch-ToBranch -Dir $fixG -Name 'feat/reset-doc-v1'
    $null = New-CycleDocument -Dir $fixG -Branch ''

    $rG = Invoke-ParkCycle -Dir $fixG
    Assert-Equal 0 $rG.Code 'reset document: exit 0'
    Assert-True ($rG.Out -match 'reset state') 'reset document: says the document belongs to no branch'
    Assert-Equal 1 (Get-CommitCount -Dir $fixG) 'reset document: nothing committed'

    # --- (h) SOMEBODY ELSE'S DOCUMENT -> left alone, owner named ---------------------------------
    Write-Host "park-cycle.ps1 -- a document belonging to another branch is left alone" -ForegroundColor Cyan
    $fixH = New-Fixture -Label 'h' -GhAnswer 'none'
    Switch-ToBranch -Dir $fixH -Name 'feat/current-branch-v1'
    $null = New-CycleDocument -Dir $fixH -Branch 'docs/somebody-else-v1'

    $rH = Invoke-ParkCycle -Dir $fixH
    Assert-Equal 0 $rH.Code "other branch's document: exit 0"
    Assert-True ($rH.Out -match 'docs/somebody-else-v1') "other branch's document: names the owner"
    Assert-True ($rH.Out -match 'left alone') "other branch's document: says it kept its hands off"
    Assert-Equal 1 (Get-CommitCount -Dir $fixH) "other branch's document: nothing committed"

    # --- (i) NO ORIGIN: nowhere to park to, and that is not a failure ----------------------------
    Write-Host "park-cycle.ps1 -- no 'origin' remote" -ForegroundColor Cyan
    $fixI = New-Fixture -Label 'i' -GhAnswer 'none' -NoOrigin
    Switch-ToBranch -Dir $fixI -Name 'feat/no-remote-v1'
    $null = New-CycleDocument -Dir $fixI -Branch 'feat/no-remote-v1'

    $rI = Invoke-ParkCycle -Dir $fixI
    Assert-Equal 0 $rI.Code 'no origin: exit 0'
    Assert-True ($rI.Out -match "no 'origin' remote") 'no origin: says why nothing happened'
    Assert-Equal 1 (Get-CommitCount -Dir $fixI) 'no origin: nothing committed'

    # --- (j) NO DOCUMENT AT ALL: nothing to park ------------------------------------------------
    Write-Host "park-cycle.ps1 -- no development cycle on disk" -ForegroundColor Cyan
    $fixJ = New-Fixture -Label 'j' -GhAnswer 'none'
    Switch-ToBranch -Dir $fixJ -Name 'feat/no-document-v1'

    $rJ = Invoke-ParkCycle -Dir $fixJ
    Assert-Equal 0 $rJ.Code 'no document: exit 0'
    Assert-True ($rJ.Out -match 'does not exist yet') 'no document: says there is nothing to park'
    Assert-Equal 1 (Get-CommitCount -Dir $fixJ) 'no document: nothing committed'

    # --- (k) AN UNPUSHED LOCAL COMMIT is invisibility too --------------------------------------
    # A committed-but-unpushed document is the real-world case park was written for (#175): the gate is
    # "is it on origin", not "is the file dirty".
    Write-Host "park-cycle.ps1 -- a committed but unpushed document is still pushed" -ForegroundColor Cyan
    $fixK = New-Fixture -Label 'k' -GhAnswer 'none'
    Switch-ToBranch -Dir $fixK -Name 'feat/committed-not-pushed-v1'
    $relK = New-CycleDocument -Dir $fixK -Branch 'feat/committed-not-pushed-v1'
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $fixK add -- $relK 2>$null | Out-Null
        & git -C $fixK commit -q -m 'cycle by hand' 2>$null | Out-Null
    } finally { $ErrorActionPreference = $prevEap }

    $rK = Invoke-ParkCycle -Dir $fixK
    Assert-Equal 0 $rK.Code 'unpushed commit: exit 0'
    Assert-True ($rK.Out -match 'parked on origin') 'unpushed commit: pushed anyway'
    Assert-Equal 2 (Get-CommitCount -Dir $fixK) 'unpushed commit: no empty extra commit was made'
    Assert-True (Test-RefOnRemote -Bare "$fixK.git" -Ref 'refs/heads/feat/committed-not-pushed-v1') 'unpushed commit: the branch ref is on origin'

    # --- (l) THE TRUNK SEAM: a consumer whose trunk is not 'main' -------------------------------
    # THE ASSERT IS INVERTED ON PURPOSE, which is what makes it prove anything. This repo's trunk is
    # 'master' here, and the branch checked out is called 'main' -- so a script that assumed 'main' is
    # the trunk would refuse with "on the trunk" and look perfectly well-behaved doing it. Only a script
    # that actually reads Get-TrunkBranchName parks this branch.
    #
    # It also pins the layer this script deliberately does NOT have: it asks Get-BranchTrunkName, which
    # probes that seam itself, rather than probing the seam a second time on its own.
    Write-Host "park-cycle.ps1 -- reads the consumer's trunk name, so 'main' can be an ordinary branch" -ForegroundColor Cyan
    $fixL = New-Fixture -Label 'l' -GhAnswer 'none' -TrunkName 'master'
    # The fixture's initial commit already sits on 'main'; here that is a FEATURE branch, not the trunk.
    $relL = New-CycleDocument -Dir $fixL -Branch 'main'

    $rL = Invoke-ParkCycle -Dir $fixL
    Assert-Equal 0 $rL.Code 'trunk seam: exit 0'
    Assert-True (-not ($rL.Out -match 'on the trunk')) "trunk seam: 'main' is NOT treated as the trunk -- the seam was read"
    Assert-True ($rL.Out -match 'parked on origin') 'trunk seam: and the branch was parked'
    Assert-True ((Get-HeadFiles -Dir $fixL) -contains $relL) 'trunk seam: the commit carries the development cycle'

    # --- (m) THE SHAPE #960 WAS MEASURED ON: a plan that reads as FINISHED with nothing behind it -----
    # THE ASSERT THIS WHOLE MECHANISM EXISTS FOR. The measured branch had eight resolved CREATE steps, a
    # diff against the trunk consisting of the cycle document alone, and the work uncommitted in another
    # device's working copy. From origin that is indistinguishable from a finished branch, and the more
    # complete the ticks the more convincing the wrong reading -- a session picking it up either rebuilds
    # work that already exists or opens a PR that merges the document alone.
    Write-Host "park-cycle.ps1 -- a plan that reads as finished with nothing behind it says so" -ForegroundColor Cyan
    $fixM = New-Fixture -Label 'm' -GhAnswer 'none'
    Switch-ToBranch -Dir $fixM -Name 'feat/ticked-but-empty-v1'
    $null = New-CycleDocument -Dir $fixM -Branch 'feat/ticked-but-empty-v1' `
        -Body "### CREATE`n`n- [x] wrote the reader`n- [x] wrote the writer`n"
    # The work, uncommitted -- which is what the other device's checkout looked like.
    [System.IO.File]::WriteAllText((Join-Path $fixM 'reader.ps1'), "# work`n", (New-Object System.Text.UTF8Encoding $false))
    [System.IO.File]::WriteAllText((Join-Path $fixM 'writer.ps1'), "# work`n", (New-Object System.Text.UTF8Encoding $false))

    $rM = Invoke-ParkCycle -Dir $fixM
    Assert-Equal 0 $rM.Code 'finished plan: exit 0 -- the note is a note, never a gate'
    Assert-True ($rM.Out -match 'parked on origin') 'finished plan: and the park still happened, which is the point of it not being a gate'
    $msgM = Get-CommitMessage -Dir $fixM
    Assert-True ($msgM -match '2 of 2 step\(s\) resolved') 'finished plan: the note counts the resolved steps'
    Assert-True ($msgM -match 'nothing else committed on this branch') 'finished plan: and says nothing else is committed'
    Assert-True ($msgM -match 'reads as FINISHED') 'finished plan: the alarm fires -- this is the state that misleads a reader'
    Assert-True ($msgM -match 'not missing') 'finished plan: and it says the work is uncommitted elsewhere rather than gone'
    Assert-True ($msgM -match 'Do NOT rebuild it') 'finished plan: naming the wrong move a good-faith pickup would make'
    Assert-True (-not ($msgM -match 'reader\.ps1')) 'finished plan: still counts only -- the uncommitted paths are not published'
    Assert-Equal 1 (Get-HeadFiles -Dir $fixM).Count 'finished plan: and bound 1 holds -- the commit is the document alone'

    # --- (n) A HALF-DONE PLAN GETS THE NUMBERS AND NO ALARM ------------------------------------------
    # THE ASSERT THAT KEEPS THE ALARM WORTH READING. 'Any resolved step with nothing committed' would fire
    # on nearly every early park -- a planning step ticked before a line of code exists is the ordinary
    # case -- and an alarm that fires on almost every park is one nobody reads by the time it matters.
    Write-Host "park-cycle.ps1 -- a half-done plan gets the numbers, not the alarm" -ForegroundColor Cyan
    $fixN = New-Fixture -Label 'n' -GhAnswer 'none'
    Switch-ToBranch -Dir $fixN -Name 'feat/half-done-v1'
    $null = New-CycleDocument -Dir $fixN -Branch 'feat/half-done-v1' `
        -Body "### CREATE`n`n- [x] read the code`n- [ ] change it`n"

    $rN = Invoke-ParkCycle -Dir $fixN
    Assert-Equal 0 $rN.Code 'half-done plan: exit 0'
    $msgN = Get-CommitMessage -Dir $fixN
    Assert-True ($msgN -match '1 of 2 step\(s\) resolved') 'half-done plan: the numbers are still there'
    Assert-True (-not ($msgN -match 'reads as FINISHED')) 'half-done plan: and the alarm stays silent, because one step is still open'
    Assert-True ($msgN -match 'nothing uncommitted') 'half-done plan: a clean working copy is stated rather than left blank'
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
