<#
.SYNOPSIS
    Tests for scripts/lib/remote-ahead-lib.ps1 -- the shared composer behind new-branch.ps1's resume
    warning and open-pr.ps1's remote-ahead gate (issue #1450).

.DESCRIPTION
    Get-RemoteAheadNote is EXTRACTED, not new: new-branch.tests.ps1 already exercises its output
    end-to-end through new-branch.ps1's own resume path (cases under "remote ahead", "remote level",
    "adversarial tip"), and those assertions are the ones that would catch a behaviour change from the
    extraction. This suite is the unit-level complement -- the function in isolation, against real git
    fixtures, plus the structural asserts that both callers actually reach it rather than a private copy.

    A REAL GIT REPOSITORY PER CASE, same reasoning gate-lib.tests.ps1 states: the function's whole job
    is to be right about what git reports, so a stubbed git would only prove the parser agrees with
    the stub.

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibPath  = Join-Path $RepoRoot 'scripts\lib\remote-ahead-lib.ps1'

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ("$Expected" -eq "$Actual") { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}
function Assert-True {
    param([bool]$Condition, [string]$Label)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label" -ForegroundColor Red }
}

Assert-True (Test-Path -LiteralPath $LibPath) 'remote-ahead-lib.ps1 exists at its registered source path'
. (Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1')
. $LibPath

$FixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) "remote-ahead-lib-tests-$PID"
$Utf8NoBom   = New-Object System.Text.UTF8Encoding $false
$script:seq  = 0

function Invoke-FixtureGit {
    <# See gate-lib.tests.ps1's own copy of this helper for why EAP is lowered around the call --
       the autocrlf notice on 'git add' lands on stderr and would otherwise be a terminating error. #>
    param([string]$Dir, [Parameter(ValueFromRemainingArguments)][string[]]$GitArgs)
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $Dir @GitArgs 2>&1 | Out-Null
    } finally { $ErrorActionPreference = $prev }
}

function New-RemoteFixturePair {
    <#
        A bare "origin" plus a clone, so refs/remotes/origin/<branch> is a REAL remote-tracking ref
        rather than a second local branch standing in for one -- the distinction the function's own
        ref-spec arguments (LocalRef vs RemoteRef) exist to make. Returns the clone's path; the bare
        repo is a sibling directory the caller never has to touch directly.
    #>
    param([string]$Branch = 'work')
    $script:seq++
    $bare  = Join-Path $FixtureRoot "origin-$script:seq.git"
    $clone = Join-Path $FixtureRoot "clone-$script:seq"
    New-Item -ItemType Directory -Path $bare -Force | Out-Null
    Invoke-FixtureGit -Dir $bare 'init' '-q' '--bare'

    $seed = Join-Path $FixtureRoot "seed-$script:seq"
    New-Item -ItemType Directory -Path $seed -Force | Out-Null
    Invoke-FixtureGit -Dir $seed 'init' '-q'
    Invoke-FixtureGit -Dir $seed 'config' 'user.email' 'tycho@example.test'
    Invoke-FixtureGit -Dir $seed 'config' 'user.name'  'Tycho'
    Invoke-FixtureGit -Dir $seed 'config' 'commit.gpgsign' 'false'
    [System.IO.File]::WriteAllText((Join-Path $seed 'tracked.txt'), "one`n", $Utf8NoBom)
    Invoke-FixtureGit -Dir $seed 'add' '-A'
    Invoke-FixtureGit -Dir $seed 'commit' '-qm' 'init'
    Invoke-FixtureGit -Dir $seed 'branch' '-M' $Branch
    Invoke-FixtureGit -Dir $seed 'remote' 'add' 'origin' $bare
    Invoke-FixtureGit -Dir $seed 'push' '-q' 'origin' $Branch

    $prevClone = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git clone -q $bare $clone 2>&1 | Out-Null
    } finally { $ErrorActionPreference = $prevClone }
    Invoke-FixtureGit -Dir $clone 'checkout' '-q' $Branch
    Invoke-FixtureGit -Dir $clone 'config' 'user.email' 'tycho@example.test'
    Invoke-FixtureGit -Dir $clone 'config' 'user.name'  'Tycho'
    Invoke-FixtureGit -Dir $clone 'config' 'commit.gpgsign' 'false'
    return @{ Bare = $bare; Clone = $clone; Seed = $seed; Branch = $Branch }
}

function Push-FixtureCommit {
    <# Advances ORIGIN's copy of $Branch by one commit, from the seed working copy -- simulating a
       second session's push that the clone under test has not fetched. #>
    param($Pair, [string]$Message, [string]$AuthorName = 'Someone Else')
    Invoke-FixtureGit -Dir $Pair.Seed 'config' 'user.name' $AuthorName
    [System.IO.File]::WriteAllText((Join-Path $Pair.Seed 'tracked.txt'), "$Message`n", $Utf8NoBom)
    Invoke-FixtureGit -Dir $Pair.Seed 'add' '-A'
    Invoke-FixtureGit -Dir $Pair.Seed 'commit' '-qm' $Message
    Invoke-FixtureGit -Dir $Pair.Seed 'push' '-q' 'origin' $Pair.Branch
}

try {
    New-Item -ItemType Directory -Path $FixtureRoot -Force | Out-Null

    # --- 1. level: nothing to report ------------------------------------------------------------
    Write-Host "`n== 1. a checkout level with its own remote reports nothing ==" -ForegroundColor Cyan
    $p1 = New-RemoteFixturePair
    $note1 = Get-RemoteAheadNote -RepoRoot $p1.Clone -LocalRef 'HEAD' -RemoteRef "refs/remotes/origin/$($p1.Branch)" `
                                  -BranchLabel $p1.Branch -FreshLabel "origin/$($p1.Branch)" -StaleLabel 'stale' -Fresh $true
    Assert-Equal '' $note1 'HEAD level with the remote-tracking ref yields the empty string'

    # --- 2. THE CASE THIS LIB EXISTS FOR: a real divergence ------------------------------------
    Write-Host "`n== 2. a diverged remote is named, counted and quoted ==" -ForegroundColor Cyan
    $p2 = New-RemoteFixturePair
    Push-FixtureCommit -Pair $p2 -Message 'park: work (all outstanding work)' -AuthorName 'Other Session'
    Invoke-FixtureGit -Dir $p2.Clone 'fetch' '-q' 'origin'
    $note2 = Get-RemoteAheadNote -RepoRoot $p2.Clone -LocalRef 'HEAD' -RemoteRef "refs/remotes/origin/$($p2.Branch)" `
                                  -BranchLabel $p2.Branch -FreshLabel "origin/$($p2.Branch)" -StaleLabel 'stale' -Fresh $true
    Assert-True ($note2 -match [regex]::Escape("'$($p2.Branch)' is 1 commit(s) behind origin/$($p2.Branch)")) "names the branch and the count (got: $note2)"
    Assert-True ($note2 -match 'Other Session') 'quotes the author of the tip commit'
    Assert-True ($note2 -match [regex]::Escape('park: work (all outstanding work)')) 'quotes the subject of the tip commit'
    Assert-True ($note2.EndsWith('.')) 'the sentence is terminated'

    # --- 3. a bigger gap counts correctly, not just presence/absence ---------------------------
    Write-Host "`n== 3. the count reflects more than one commit ==" -ForegroundColor Cyan
    $p3 = New-RemoteFixturePair
    Push-FixtureCommit -Pair $p3 -Message 'first'
    Push-FixtureCommit -Pair $p3 -Message 'second'
    Push-FixtureCommit -Pair $p3 -Message 'third'
    Invoke-FixtureGit -Dir $p3.Clone 'fetch' '-q' 'origin'
    $note3 = Get-RemoteAheadNote -RepoRoot $p3.Clone -LocalRef 'HEAD' -RemoteRef "refs/remotes/origin/$($p3.Branch)" `
                                  -BranchLabel $p3.Branch -FreshLabel "origin/$($p3.Branch)" -StaleLabel 'stale' -Fresh $true
    Assert-True ($note3 -match 'is 3 commit\(s\) behind') "reports three, not one (got: $note3)"
    Assert-True ($note3 -match [regex]::Escape('third')) 'the tip line is the LATEST of the three, not the first'

    # --- 4. Fresh vs stale label selection -------------------------------------------------------
    Write-Host "`n== 4. the caller's Fresh flag picks which label is used ==" -ForegroundColor Cyan
    $p4 = New-RemoteFixturePair
    Push-FixtureCommit -Pair $p4 -Message 'moved'
    Invoke-FixtureGit -Dir $p4.Clone 'fetch' '-q' 'origin'
    $noteFresh = Get-RemoteAheadNote -RepoRoot $p4.Clone -LocalRef 'HEAD' -RemoteRef "refs/remotes/origin/$($p4.Branch)" `
                                      -BranchLabel $p4.Branch -FreshLabel 'FRESH-LABEL' -StaleLabel 'STALE-LABEL' -Fresh $true
    $noteStale = Get-RemoteAheadNote -RepoRoot $p4.Clone -LocalRef 'HEAD' -RemoteRef "refs/remotes/origin/$($p4.Branch)" `
                                      -BranchLabel $p4.Branch -FreshLabel 'FRESH-LABEL' -StaleLabel 'STALE-LABEL' -Fresh $false
    Assert-True ($noteFresh -match 'FRESH-LABEL') 'Fresh $true selects the fresh label'
    Assert-True ($noteStale -match 'STALE-LABEL') 'Fresh $false selects the stale label'

    # --- 5. adversarial tip: control/format characters are stripped, the words survive ---------
    # Same case new-branch.tests.ps1's "adversarial tip" exercises end-to-end; here in isolation, and
    # with a fixture-supplied U+202E (RTL override) rather than depending on new-branch's own scaffold.
    Write-Host "`n== 5. an adversarial commit subject is sanitised, not hidden ==" -ForegroundColor Cyan
    $p5 = New-RemoteFixturePair
    $rtl = [string]([char]0x202E)
    Push-FixtureCommit -Pair $p5 -Message "safe-looking ${rtl}txt.exe" -AuthorName 'Evil Author'
    Invoke-FixtureGit -Dir $p5.Clone 'fetch' '-q' 'origin'
    $note5 = Get-RemoteAheadNote -RepoRoot $p5.Clone -LocalRef 'HEAD' -RemoteRef "refs/remotes/origin/$($p5.Branch)" `
                                  -BranchLabel $p5.Branch -FreshLabel "origin/$($p5.Branch)" -StaleLabel 'stale' -Fresh $true
    Assert-True ($note5 -match 'is 1 commit\(s\) behind') 'the warning still fires -- the strip is not a refusal to report'
    Assert-True ($note5 -notmatch [char]0x202E) 'the RTL override itself is gone'
    Assert-True ($note5 -match 'safe-looking') 'the ordinary words around it survive'

    # --- 6. length cap ---------------------------------------------------------------------------
    Write-Host "`n== 6. a long subject is capped rather than pushing the sentence off-screen ==" -ForegroundColor Cyan
    $p6 = New-RemoteFixturePair
    Push-FixtureCommit -Pair $p6 -Message ('x' * 200)
    Invoke-FixtureGit -Dir $p6.Clone 'fetch' '-q' 'origin'
    $note6 = Get-RemoteAheadNote -RepoRoot $p6.Clone -LocalRef 'HEAD' -RemoteRef "refs/remotes/origin/$($p6.Branch)" `
                                  -BranchLabel $p6.Branch -FreshLabel "origin/$($p6.Branch)" -StaleLabel 'stale' -Fresh $true
    Assert-True ($note6 -match [regex]::Escape('...')) 'a subject past the cap is truncated with an ellipsis'
    Assert-True ($note6 -notmatch ('x' * 130)) 'and does not carry the whole 200-character subject verbatim'

    # --- 7. a rev-list that cannot answer reports nothing, never throws ------------------------
    Write-Host "`n== 7. an unanswerable comparison is silence, not a throw ==" -ForegroundColor Cyan
    $p7 = New-RemoteFixturePair
    $threw = $false
    $note7 = $null
    try {
        $note7 = Get-RemoteAheadNote -RepoRoot $p7.Clone -LocalRef 'HEAD' -RemoteRef 'refs/remotes/origin/does-not-exist' `
                                      -BranchLabel 'ghost' -FreshLabel 'origin/ghost' -StaleLabel 'stale' -Fresh $true
    } catch { $threw = $true }
    Assert-True (-not $threw) 'a nonexistent remote ref does not throw'
    Assert-Equal '' $note7 'and is reported as no divergence, never a guess'

    # --- 8. both callers reach the shared function, not a private copy -------------------------
    Write-Host "`n== 8. new-branch and open-pr both call the shared function ==" -ForegroundColor Cyan
    $newBranchText = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'scripts\task\new-branch.ps1'))
    $openPrText    = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'scripts\release\open-pr.ps1'))
    Assert-True ($newBranchText -match 'lib\\remote-ahead-lib\.ps1') 'new-branch.ps1 dot-sources remote-ahead-lib'
    Assert-True ($openPrText -match 'lib\\remote-ahead-lib\.ps1') 'open-pr.ps1 dot-sources remote-ahead-lib'
    Assert-True ($newBranchText -match 'Get-RemoteAheadNote -RepoRoot') 'new-branch.ps1 calls Get-RemoteAheadNote'
    Assert-True ($openPrText -match 'Get-RemoteAheadNote -RepoRoot') 'open-pr.ps1 calls Get-RemoteAheadNote'
    # THE REGRESSION THIS GUARDS: a second, hand-typed copy of the sanitiser regex would satisfy every
    # case above while leaving the file with two definitions that can disagree from tomorrow onward.
    Assert-Equal 0 ([regex]::Matches($newBranchText, [regex]::Escape('\p{Cc}\p{Cf}')).Count) 'new-branch.ps1 no longer carries its own copy of the strip pattern'
    Assert-Equal 0 ([regex]::Matches($openPrText, [regex]::Escape('\p{Cc}\p{Cf}')).Count) 'open-pr.ps1 never carried one either'

    # --- 9. open-pr's gate sits BEFORE the lint+test gate, and blocks -------------------------
    Write-Host "`n== 9. open-pr asks before spending the gate, and refuses rather than warns ==" -ForegroundColor Cyan
    # THE REAL CAUSE, FOUND VIA A DIAGNOSTIC BUILD (issue #1450): not a CI/culture/escaping quirk at
    # all. GitHub tests the PULL-REQUEST MERGE REF, not this branch's own tip -- so every earlier run
    # here was silently comparing against WHATEVER open-pr.ps1 LOOKED LIKE ONCE MERGED WITH main AT
    # THAT MOMENT, while every local check (and every fetch of "this branch's own copy" via git show or
    # the GitHub Contents API with ?ref=<branch>) read the unmerged branch tip -- which is exactly why
    # three independent rewrites of the SAME landmark (backtick-escaped IndexOf, single-quoted IndexOf,
    # a regex match) all failed identically on CI and all passed identically off it. Between this
    # branch's creation and each of those pushes, main gained a -MaxParallel parameter on
    # Invoke-WorkflowGates (issue #1443) that this branch had not yet merged, so the FULL call-signature
    # literal this case used to assert against was already stale the moment CI built the merge.
    #
    # THE REPAIR IS TWO PARTS: the branch is merged with main (so the PR and this local checkout agree
    # with what CI actually tests), and the landmark itself now names only what THIS branch's own gate
    # owns -- '-Context ''the PR''' distinguishes the PR-path call from -GatesOnly's '-Context ''the
    # gate run''' -- rather than the other call's FULL parameter list, which is main's to extend and not
    # this test's to pin.
    $fetchLiteral = '''fetch'', ''origin'''
    $gateCallAnchor = '-Context ''the PR'''
    $orderPattern = [regex]::Escape($fetchLiteral) + '(?s).*?' + [regex]::Escape($gateCallAnchor)
    Assert-True ([regex]::IsMatch($openPrText, $orderPattern)) 'both landmarks are found, and the single-branch fetch runs before the PR-path gate call'
    $remoteAheadGateBlock = [regex]::Match($openPrText, "(?s)# --- Remote-ahead gate.*?\n\n# THE GATES BELOW").Value
    Assert-True ([bool]$remoteAheadGateBlock) 'the remote-ahead gate block is found as a single section'
    Assert-True ($remoteAheadGateBlock -match 'exit 1') 'a real divergence exits rather than only warning'
    Assert-True ($remoteAheadGateBlock -match 'could not fetch') 'a failed fetch is reported rather than silently ignored'
    Assert-True ($remoteAheadGateBlock -notmatch "Write-Warning[^\r\n]*Another session") 'a real divergence is refused (Write-Error), not merely warned about, unlike new-branch''s own use of the same note'

    # --- 10. the pair is registered and mirrored ------------------------------------------------
    Write-Host "`n== 10. the lib travels to the consumer ==" -ForegroundColor Cyan
    . (Join-Path $RepoRoot 'scripts\lib\shared-scripts-lib.ps1')
    $pairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot)
    $rPair = @($pairs | Where-Object { $_.Name -eq 'remote-ahead-lib' })
    Assert-Equal 1 $rPair.Count 'remote-ahead-lib is registered exactly once'
    if ($rPair.Count -eq 1) {
        Assert-True ([bool]$rPair[0].LibOnly) 'registered as a dot-sourced library'
        Assert-True (Test-Path -LiteralPath $rPair[0].MirrorPath) 'and its mirror exists in the plugin tree'
        $srcText = [System.IO.File]::ReadAllText($rPair[0].SourcePath)
        $mirText = [System.IO.File]::ReadAllText($rPair[0].MirrorPath)
        Assert-Equal $srcText.Length $mirText.Length 'source and mirror are byte-identical in length'
    }
    $mirrorNewBranchPath = Join-Path $RepoRoot 'plugins\dkj-policy\scripts\task\new-branch.ps1'
    $mirrorOpenPrPath    = Join-Path $RepoRoot 'plugins\dkj-policy\scripts\release\open-pr.ps1'
    Assert-True (Test-Path -LiteralPath $mirrorNewBranchPath) 'the mirrored new-branch.ps1 exists'
    Assert-True (Test-Path -LiteralPath $mirrorOpenPrPath) 'the mirrored open-pr.ps1 exists'
    if ((Test-Path -LiteralPath $mirrorNewBranchPath) -and (Test-Path -LiteralPath $mirrorOpenPrPath)) {
        Assert-True (([System.IO.File]::ReadAllText($mirrorNewBranchPath)) -match 'Get-RemoteAheadNote -RepoRoot') 'the mirrored new-branch.ps1 calls the shared function'
        Assert-True (([System.IO.File]::ReadAllText($mirrorOpenPrPath)) -match 'Get-RemoteAheadNote -RepoRoot') 'the mirrored open-pr.ps1 calls the shared function'
    }

} finally {
    if (Test-Path -LiteralPath $FixtureRoot) {
        Remove-Item -Recurse -Force -LiteralPath $FixtureRoot -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
