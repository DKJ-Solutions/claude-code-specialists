<#
.SYNOPSIS
    Regression tests for scripts/lib/source-repo-guard-lib.ps1 -- the guard that refuses a shared script
    running from a released copy inside the repo that maintains it.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/source-repo-guard.tests.ps1

    TWO LAYERS, DELIBERATELY. Get-OwnCopyPath is exercised directly against synthetic trees, because the
    decision it makes has more branches than a child process can cheaply cover -- and one integration case
    runs a REAL entry point from a copy outside a real repo, because the thing that has to hold is that the
    script actually stops, with a non-zero exit code, and says which path to run instead.

    THE ALLOW CASES CARRY THE RISK, NOT THE REFUSAL. A guard that refuses too much breaks every consumer,
    which is worse than the defect it repairs -- so a consumer with no marketplace, a consumer carrying a
    same-named script of their own, and the source repo's own in-repo mirror each get a case saying the
    guard stays out of it.

    Fixture paths carry $PID (repo convention): the test gate is a throttled parallel scheduler, so two
    runs overlapping is ordinary, and two runs sharing one fixed temp path tear down each other's tree
    mid-assert.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$GuardLib = Join-Path $RepoRoot 'scripts\lib\source-repo-guard-lib.ps1'

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

function New-Tree {
    <#
        A synthetic repo root. -Publishes writes .claude-plugin/marketplace.json, which is the condition
        that separates a repo that MAINTAINS shared scripts from a consumer that merely runs them.
        -Local writes the repo's own copy at scripts/<Relative>.
    #>
    param(
        [Parameter(Mandatory)][string]$Label,
        [switch]$Publishes,
        [switch]$Local,
        [string]$Relative = 'task\park-branch.ps1'
    )
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("srguard-$PID-$Label-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    if ($Publishes) {
        New-Item -ItemType Directory -Path (Join-Path $dir '.claude-plugin') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $dir '.claude-plugin\marketplace.json') -Value '{}' -Encoding UTF8
    }
    if ($Local) {
        $p = Join-Path (Join-Path $dir 'scripts') $Relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $p) -Force | Out-Null
        Set-Content -LiteralPath $p -Value '# local copy' -Encoding UTF8
    }
    return $dir
}

$fixtures = @()
try {
    . $GuardLib

    Write-Host 'A foreign copy IS refused when the repo maintains the same script' -ForegroundColor Cyan
    # The measured case: a released mirror run inside the repo it was mirrored from.
    $src = New-Tree -Label 'src' -Publishes -Local; $fixtures += $src
    $cache = New-Tree -Label 'cache'; $fixtures += $cache
    $foreign = Join-Path $cache 'scripts\task\park-branch.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $foreign) -Force | Out-Null
    Set-Content -LiteralPath $foreign -Value '# released copy' -Encoding UTF8
    $own = Get-OwnCopyPath -ScriptPath $foreign -RepoRoot $src
    Assert-Equal 'scripts\task\park-branch.ps1' $own 'the local path to run instead is returned, repo-relative'

    Write-Host "The repo's own copy is NOT refused" -ForegroundColor Cyan
    $inside = Join-Path $src 'scripts\task\park-branch.ps1'
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $inside -RepoRoot $src) 'running the source itself is fine'

    Write-Host 'The in-repo plugin mirror is NOT refused' -ForegroundColor Cyan
    # Lint check 8 holds this byte-identical to the source, so running it is not the staleness the guard is
    # about. Refusing it would also make the drift lint's own fixtures unrunnable.
    $mirror = Join-Path $src 'plugins\workflows\contributing-davekjohn\scripts\task\park-branch.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $mirror) -Force | Out-Null
    Set-Content -LiteralPath $mirror -Value '# in-repo mirror' -Encoding UTF8
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $mirror -RepoRoot $src) 'the mirror inside the repo is allowed'

    Write-Host 'A consumer is NEVER refused -- the two ways that must both hold' -ForegroundColor Cyan
    # 1. No marketplace: the ordinary consumer. This is the condition doing the real work.
    $plainConsumer = New-Tree -Label 'consumer' -Local; $fixtures += $plainConsumer
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $foreign -RepoRoot $plainConsumer) `
        'a repo that publishes no plugins is left alone even though it has a same-named script'
    # 2. Publishes, but has no copy of THIS script -- a repo publishing some other plugin entirely.
    $otherPublisher = New-Tree -Label 'other' -Publishes; $fixtures += $otherPublisher
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $foreign -RepoRoot $otherPublisher) `
        'a publishing repo without its own copy of this script is left alone'

    Write-Host 'A sibling directory whose name merely starts with the root name is still foreign' -ForegroundColor Cyan
    # '...\srguard-x-src-abc' vs '...\srguard-x-src-abc-two': a prefix compare without the separator reads
    # the second as being inside the first, and the guard would then wave through a genuinely foreign copy.
    $sibling = $src + '-two'
    $siblingScript = Join-Path $sibling 'scripts\task\park-branch.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $siblingScript) -Force | Out-Null
    Set-Content -LiteralPath $siblingScript -Value '# next door' -Encoding UTF8
    $fixtures += $sibling
    Assert-Equal 'scripts\task\park-branch.ps1' (Get-OwnCopyPath -ScriptPath $siblingScript -RepoRoot $src) `
        'a path that shares the root as a string PREFIX is not treated as being inside it'

    Write-Host 'The relative path comes from the INNERMOST scripts segment' -ForegroundColor Cyan
    # A mirror path carries two ('...\plugins\...\scripts\task\x.ps1'), and taking the first would compose
    # a nonsense local path like scripts\workflows\contributing-davekjohn\scripts\task\x.ps1.
    $deep = New-Tree -Label 'deep'; $fixtures += $deep
    $deepScript = Join-Path $deep 'scripts\plugins\workflows\wf\scripts\task\park-branch.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $deepScript) -Force | Out-Null
    Set-Content -LiteralPath $deepScript -Value '# doubly nested' -Encoding UTF8
    Assert-Equal 'scripts\task\park-branch.ps1' (Get-OwnCopyPath -ScriptPath $deepScript -RepoRoot $src) `
        'two scripts segments: the last one wins'

    Write-Host 'A script that lives under no scripts/ directory at all is not judged' -ForegroundColor Cyan
    $loose = Join-Path $cache 'somewhere\else.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $loose) -Force | Out-Null
    Set-Content -LiteralPath $loose -Value '# loose' -Encoding UTF8
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $loose -RepoRoot $src) 'no scripts segment, no verdict'

    Write-Host 'An unresolvable repo root switches the guard OFF rather than refusing' -ForegroundColor Cyan
    # A guard that cannot tell which repo it is in must not refuse anything: that would break a script run
    # outside any repo, which is a legitimate thing to do with fix-mojibake -Path.
    Assert-Equal $null (Get-OwnCopyPath -ScriptPath $foreign -RepoRoot (Join-Path $cache 'no-such-tree')) `
        'a root that does not exist yields no finding'

    Write-Host 'INTEGRATION: a real entry point stops, with exit 1, naming the local path' -ForegroundColor Cyan
    # The asserts above prove the decision; this proves the CONSEQUENCE. Without it, a lib returning the
    # right answer to nobody would pass the suite.
    #
    # THE ENTRY POINT USED TO BE session-status.ps1, removed with /lock and /handover by #957. What this
    # block needs is any guarded entry point that (a) loads the guard BEFORE any other lib and (b) writes
    # nothing, so a guard that failed to fire cannot damage the real tree it is pointed at. check-branch-entry
    # qualifies on both counts: the guard is its first dot-source, and it only reports.
    $realRepo = $RepoRoot
    $awayDir = Join-Path ([System.IO.Path]::GetTempPath()) ("srguard-$PID-away-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    $fixtures += $awayDir
    New-Item -ItemType Directory -Path (Join-Path $awayDir 'scripts\lint') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $awayDir 'scripts\lib') -Force | Out-Null
    Copy-Item (Join-Path $realRepo 'scripts\lint\check-branch-entry.ps1') (Join-Path $awayDir 'scripts\lint\check-branch-entry.ps1')
    Copy-Item $GuardLib (Join-Path $awayDir 'scripts\lib\source-repo-guard-lib.ps1')
    $prev = $env:CLAUDE_PROJECT_DIR
    try {
        $env:CLAUDE_PROJECT_DIR = $realRepo
        $out = (& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $awayDir 'scripts\lint\check-branch-entry.ps1') 2>&1) | Out-String
        $code = $LASTEXITCODE
    } finally {
        if ($null -eq $prev) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prev }
    }
    Assert-Equal 1 $code 'the run exits 1 rather than reporting'
    # -cmatch, CASE-SENSITIVELY, and the reason is worth keeping even though the script that produced it is
    # gone: session-status printed the lock file, whose prose was full of the word 'refuses', and a
    # case-insensitive match on 'REFUSED' passed against a run that never fired. Any entry point can print
    # the lowercase word in passing, so the marker is only evidence in the case the guard writes it.
    Assert-True ($out -cmatch 'REFUSED: this repo maintains') 'it says it refused, in its own words'
    Assert-True ($out -match 'run this: scripts.lint.check-branch-entry\.ps1') 'and names the copy to run instead'
    # IT STOPPED BEFORE DOING ANY OF ITS WORK, pinned on the very next thing it would have touched: the
    # away tree carries the guard lib and nothing else, so a guard that did not fire would fall over on the
    # dot-source below it and say so, naming the lib in the error.
    Assert-True (-not ($out -match 'entry-scaffold-lib')) 'and it stopped BEFORE doing any of its work'

    Write-Host 'A WORKTREE of the repo is NOT refused, and a CLONE still is (#851)' -ForegroundColor Cyan
    # REAL GIT HERE, not a directory fixture. The whole question is what `git rev-parse
    # --git-common-dir` answers, and a fabricated tree cannot answer it -- asserting against a stub
    # would test the stub. The pair matters more than either half: a worktree must be allowed AND a
    # separate clone must still be refused, because the second is the released mirror this guard exists
    # for, and a fix that let both through would remove the guard while looking like it narrowed it.
    #
    # EVERY git CALL GOES THROUGH Invoke-NativeCapture, and that is not tidiness. git writes progress to
    # stderr, which under this file's $ErrorActionPreference = 'Stop' becomes a TERMINATING error even
    # when git exits 0 -- the #96/#97/#107 pitfall the repo has paid for three times. Writing these
    # asserts the obvious way reproduced it immediately: `git worktree add` printed 'Preparing worktree'
    # and the suite died on a successful command.
    . (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')
    $git = {
        param([string[]]$Arguments)
        Invoke-NativeCapture -FilePath 'git' -Arguments $Arguments
    }

    $gitOk = (& $git @('--version')).ExitCode -eq 0
    if (-not $gitOk) {
        # Announced rather than silently skipped: a suite that needs git to prove a git rule must say when
        # it could not, or a green run means something different from what the reader thinks.
        Write-Host '  [SKIP] git is not available -- the worktree asserts did not run' -ForegroundColor Yellow
    } else {
        $gitSrc = New-Tree -Label 'gitsrc' -Publishes -Local; $fixtures += $gitSrc
        & $git @('-C', $gitSrc, 'init', '--quiet')                            | Out-Null
        & $git @('-C', $gitSrc, 'config', 'user.email', 'suite@example.invalid') | Out-Null
        & $git @('-C', $gitSrc, 'config', 'user.name', 'Suite')               | Out-Null
        & $git @('-C', $gitSrc, 'config', 'commit.gpgsign', 'false')          | Out-Null
        & $git @('-C', $gitSrc, 'add', '-A')                                  | Out-Null
        & $git @('-C', $gitSrc, 'commit', '--quiet', '-m', 'fixture')         | Out-Null

        # The lane lives OUTSIDE the repo root, exactly as worktree-lane.ps1 places it -- a worktree
        # inside the tree would be walked by the lint gate's link scan and by the suites.
        $lane = Join-Path ([System.IO.Path]::GetTempPath()) ("guard-lane-" + [System.Guid]::NewGuid().ToString('N').Substring(0, 8))
        $fixtures += $lane
        & $git @('-C', $gitSrc, 'worktree', 'add', '--detach', $lane) | Out-Null
        $laneScript = Join-Path $lane 'scripts\task\park-branch.ps1'

        Assert-True (Test-Path -LiteralPath $laneScript) 'the worktree carries the committed script'
        Assert-Equal $null (Get-OwnCopyPath -ScriptPath $laneScript -RepoRoot $gitSrc) `
            'a script in a WORKTREE of the repo is allowed -- it is the same repository, not a snapshot'

        # And the half that must not have changed: a separate clone of the same repo is a different
        # repository, answers with its own --git-common-dir, and is still refused.
        $clone = Join-Path ([System.IO.Path]::GetTempPath()) ("guard-clone-" + [System.Guid]::NewGuid().ToString('N').Substring(0, 8))
        $fixtures += $clone
        & $git @('clone', '--quiet', $gitSrc, $clone) | Out-Null
        $cloneScript = Join-Path $clone 'scripts\task\park-branch.ps1'
        Assert-True (Test-Path -LiteralPath $cloneScript) 'the clone carries the script too -- the two shapes are indistinguishable on disk'
        Assert-Equal 'scripts\task\park-branch.ps1' (Get-OwnCopyPath -ScriptPath $cloneScript -RepoRoot $gitSrc) `
            'a CLONE is still refused -- which is the released mirror this guard exists for'

        # The identity helper on its own terms, so a failure above can be told apart from a failure here.
        Assert-Equal (Get-GuardGitCommonDir -Path $gitSrc) (Get-GuardGitCommonDir -Path $lane) `
            'the repo and its worktree report the same shared .git'
        Assert-True ((Get-GuardGitCommonDir -Path $clone) -ne (Get-GuardGitCommonDir -Path $gitSrc)) `
            'and a clone reports a different one'
        Assert-Equal $null (Get-GuardGitCommonDir -Path $cache) `
            'a path in no git repository answers $null, which reads as "cannot tell" and keeps the guard refusing'

        # Leave no worktree registered behind: the fixture directory is deleted in the finally block, and a
        # stale registration would make later `git worktree` calls in the fixture repo complain.
        & $git @('-C', $gitSrc, 'worktree', 'remove', '--force', $lane) | Out-Null
    }
}
finally {
    foreach ($d in $fixtures) {
        if ($d -and (Test-Path -LiteralPath $d)) {
            Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# --- COVERAGE: the guard is WIRED IN, not merely correct ------------------------------------------------
# EVERYTHING ABOVE TESTS WHETHER THE GUARD DECIDES CORRECTLY. Nothing tested whether it is actually
# CALLED, and that is the half that went wrong. Measured August 26, 2026 while repairing the stale
# tallies of issue #897: scripts/README.md claimed "fourteen of the sixteen shared entry points now
# refuse outright" and named two exceptions with a sound reason -- both are SessionStart hooks, invoked
# from the plugin by design, so refusing there would fail every session start in this repo. The real
# figures were 20 of 23, and the third absentee was scripts/maintenance/measure-always-on.ps1, which is
# no such hook. Its own skill page prints '${CLAUDE_PLUGIN_ROOT}/scripts/maintenance/measure-always-on.ps1'
# and then says to run the local copy instead -- precisely the shape the guard exists for. A gap, not an
# exception, almost certainly missed when that script joined the registry the day before.
#
# WHY A TEST AND NOT A PROSE COUNT. The claim it replaces was a hand-typed ratio over a registry that can
# be asked, in a page nothing checks -- so it was wrong when written and would be wrong again after the
# next entry point. This assert derives the set from Get-SharedScriptPairs, so a new entry point is held
# to the rule on the day it is registered rather than on the day somebody re-counts.
#
# THE EXCEPTION LIST IS NAMED HERE AND NOWHERE ELSE, and it is deliberately short. Adding to it is a
# decision that has to be argued in this file, which is the property the README could never have: a page
# can go stale in silence, a failing assert cannot.
. (Join-Path $RepoRoot 'scripts\lib\shared-scripts-lib.ps1')

# Each is invoked from the plugin by a SessionStart hook, so a refusal would fail every session start in
# this repo. That reason is specific to being a hook -- it does not extend to a script somebody runs.
#
# check-git-identity.ps1 joined them on September 3, 2026 (issue #1315) on exactly that reason and no
# other: git-identity-sessioncheck.ps1 runs it from '${CLAUDE_PLUGIN_ROOT}/scripts/lint/', which is the
# released copy, so Assert-OwnCopy would refuse it -- and thereby the hook -- at every session start here.
# It has no second caller: there is no CI half, deliberately, because a runner acts and commits as a bot
# and would report a mismatch on every push.
$guardExempt = @(
    'scripts\sync\check-roster-sync.ps1',
    'scripts\sync\check-script-contract.ps1',
    'scripts\lint\check-git-identity.ps1'
)

$entryPoints = @(Get-SharedScriptPairs -RepoRoot $RepoRoot |
    Where-Object { -not $_.LibOnly } |
    Select-Object -ExpandProperty SourceRel -Unique)

Assert-True ($entryPoints.Count -gt 0) `
    'coverage: the registry yields entry points at all -- an empty set would pass every assert below while checking nothing'

$missingGuard = @()
foreach ($ep in $entryPoints) {
    if ($guardExempt -contains $ep) { continue }
    $epPath = Join-Path $RepoRoot $ep
    if (-not (Test-Path -LiteralPath $epPath -PathType Leaf)) {
        $missingGuard += "$ep (registered but absent from the tree)"
        continue
    }
    $epText = [System.IO.File]::ReadAllText($epPath, [System.Text.Encoding]::UTF8)
    if ($epText -notmatch 'source-repo-guard-lib') { $missingGuard += $ep }
}
Assert-True ($missingGuard.Count -eq 0) `
    "coverage: every shared entry point dot-sources the guard, except the named SessionStart-hook scripts$(if ($missingGuard.Count) { ' -- WITHOUT IT: ' + ($missingGuard -join ', ') })"

# AND THE EXEMPTIONS ARE HELD TO BEING REAL. An exemption for a script that no longer exists, or that has
# since gained the guard, is a licence nobody is using -- and the next reader would take it as evidence
# that the entry is still needed. Same reasoning as the checks in the lint gate that refuse to carry a
# stale exclusion.
foreach ($ex in $guardExempt) {
    $exPath = Join-Path $RepoRoot $ex
    Assert-True (Test-Path -LiteralPath $exPath -PathType Leaf) `
        "coverage: the exemption for $ex names a file that exists"
    Assert-True ($entryPoints -contains $ex) `
        "coverage: the exemption for $ex names a registered entry point, so it is exempting something real"
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILED: $($script:fail) of $($script:pass + $script:fail) asserts." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
