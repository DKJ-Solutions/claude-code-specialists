<#
.SYNOPSIS
    Regression tests for scripts/lib/sync-rules.ps1 -- the two queries team-shopify's pre-task sync is
    built on (inbound #787, extended with the merged-sync-branch case from inbound #801).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell and git.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/sync-rules.tests.ps1

    WHY THESE TWO FUNCTIONS HAVE A SUITE AND THE SYNC ITSELF DOES NOT. The policy is one sentence -- the
    trunk wins what the trunk touched -- and it is not where the risk is. The risk is in the two QUERIES
    that decide when it fires, and both fail SILENTLY and in the losing direction:

      * Get-SyncReferencePoint answering with a commit that is too RECENT protects fewer files, and
        answering $null while the caller carries on protects none at all.
      * Test-MainTouchedSince answering $false for a path the trunk has touched hands that file to live.

    THE DELETION CASE IS THE HEADLINE, and it is here because the first hand-written implementation of
    this rule got it wrong: a deletion is also a touch, so a file the trunk REMOVED must answer $true, or
    the sync puts back a file somebody deleted on purpose. It reads as an edge case and is the ordinary
    one -- removing a section from a theme is how a theme changes.

    THE UNION PATTERN IS TESTED FROM BOTH SIDES. The shipped default matches the two spellings actually
    in use ('sync:' and 'Sync '), and a repo that narrows it through the seam must still be able to
    exclude the other -- so there is a case for the default matching both and a case for a narrowed
    pattern matching only one.

    Fixture paths carry $PID (repo convention): the test gate is a throttled parallel scheduler, so two
    runs overlapping is ordinary, and two runs sharing one fixed temp path tear down each other's tree
    mid-assert.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $RepoRoot 'scripts\lib\sync-rules.ps1')

$script:pass = 0
$script:fail = 0
$script:trees = @()

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

function New-GitTree {
    <# A fresh repo with a local identity and autocrlf off -- identity so a machine with no global
       user.email does not fail here for a reason unrelated to the code under test, autocrlf so git's own
       CRLF warning never reaches stderr and trips the EAP guard. Same reasoning as every other git
       fixture in this directory. #>
    param([Parameter(Mandatory = $true)][string]$Label)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("syncrules-$PID-$Label-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $script:trees += $dir
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $dir init --quiet                       | Out-Null
        & git -C $dir config user.name  'sync-rules test' | Out-Null
        & git -C $dir config user.email 'sync@test.invalid' | Out-Null
        & git -C $dir config core.autocrlf false          | Out-Null
    } finally { $ErrorActionPreference = $prevEap }
    return $dir
}

function Add-Commit {
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][string]$Message,
        [hashtable]$Write = @{},
        [string[]]$Delete = @()
    )
    foreach ($rel in $Write.Keys) {
        $target = Join-Path $Dir $rel
        $parent = Split-Path -Parent $target
        if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Set-Content -LiteralPath $target -Value $Write[$rel] -Encoding ascii -NoNewline
    }
    foreach ($rel in $Delete) {
        $target = Join-Path $Dir $rel
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
    }
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $Dir add -A                     | Out-Null
        & git -C $Dir commit -q -m $Message       | Out-Null
    } finally { $ErrorActionPreference = $prevEap }
    return ([string](& git -C $Dir rev-parse HEAD)).Trim()
}

try {
    # --- The default pattern ------------------------------------------------------------------------
    Write-Host 'the default reference pattern'
    Assert-Equal '^[Ss]ync' (Get-SyncDefaultReferencePattern) 'default/pattern: the union of the two spellings in use'

    # --- The reference point ------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'Get-SyncReferencePoint'

    $lower = New-GitTree -Label 'lower'
    Add-Commit -Dir $lower -Message 'initial'          -Write @{ 'a.txt' = 'a1' } | Out-Null
    $lowerSync = Add-Commit -Dir $lower -Message 'sync: live theme drift 2026-08-01' -Write @{ 'b.txt' = 'b1' }
    Add-Commit -Dir $lower -Message 'feat: something else' -Write @{ 'c.txt' = 'c1' } | Out-Null

    Push-Location -LiteralPath $lower
    try {
        $ref = Get-SyncReferencePoint
        Assert-Equal $lowerSync $ref.Ref  "ref/lower: 'sync:' is found"
        Assert-Equal 'sync'     $ref.Kind 'ref/lower: and reported as a sync commit rather than a tag'
    } finally { Pop-Location }

    $upper = New-GitTree -Label 'upper'
    Add-Commit -Dir $upper -Message 'initial' -Write @{ 'a.txt' = 'a1' } | Out-Null
    $upperSync = Add-Commit -Dir $upper -Message 'Sync main with live theme (a-store)' -Write @{ 'b.txt' = 'b1' }
    Add-Commit -Dir $upper -Message 'fix: unrelated' -Write @{ 'c.txt' = 'c1' } | Out-Null

    Push-Location -LiteralPath $upper
    try {
        $ref = Get-SyncReferencePoint
        Assert-Equal $upperSync $ref.Ref "ref/upper: 'Sync ' with a capital is found by the SAME default"
        # The whole reason the default is not '^sync'. A pattern that misses this spelling finds nothing,
        # falls through to the tag lookup, finds nothing there in a repo with no tags, and aborts on the
        # first run -- before the rule has ever protected anything.
        $narrow = Get-SyncReferencePoint -Pattern '^sync:'
        Assert-True ($null -eq $narrow) 'ref/upper: a narrowed pattern excludes it, so the seam genuinely narrows'
    } finally { Pop-Location }

    # Two syncs: the floor is the most recent one. This is also why a LOOSER pattern is the dangerous
    # direction -- it can only move the floor forward, and a floor that is too recent protects less.
    $two = New-GitTree -Label 'two'
    Add-Commit -Dir $two -Message 'initial'        -Write @{ 'a.txt' = 'a1' } | Out-Null
    Add-Commit -Dir $two -Message 'sync: the first' -Write @{ 'b.txt' = 'b1' } | Out-Null
    $second = Add-Commit -Dir $two -Message 'sync: the second' -Write @{ 'c.txt' = 'c1' }
    Push-Location -LiteralPath $two
    try {
        Assert-Equal $second (Get-SyncReferencePoint).Ref 'ref/two: the MOST RECENT sync commit is the floor'
    } finally { Pop-Location }

    # A MERGED SYNC BRANCH, WHICH IS THE WORST CASE THIS SUITE HOLDS (inbound #801). '--grep' matches any
    # LINE of a message, and a merge commit carries the merged commit's subject in its body -- so the
    # merge matches the pattern, and right after a sync PR lands that merge is HEAD. A floor on HEAD makes
    # Test-MainTouchedSince answer $false for every path and the exclusion rule keeps NOTHING back, while
    # printing a reference point as though all were well. Both halves are asserted: that the shipped
    # lookup skips the merge, AND that a lookup without --no-merges genuinely picks it -- so the flag
    # cannot be tidied away later as a style choice.
    $merged = New-GitTree -Label 'merged'
    Add-Commit -Dir $merged -Message 'initial' -Write @{ 'a.txt' = 'a1' } | Out-Null
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $trunkName = ([string](& git -C $merged rev-parse --abbrev-ref HEAD)).Trim()
        & git -C $merged checkout -q -b 'sync/live-2026-08-20' | Out-Null
    } finally { $ErrorActionPreference = $prevEap }
    $syncOnBranch = Add-Commit -Dir $merged -Message 'sync: mirror in-flight third-party edits from live (2 file(s))' -Write @{ 'b.txt' = 'b1' }
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $merged checkout -q $trunkName | Out-Null
        # Two -m flags: the first is the subject, the second the body -- the shape gh writes for a merge.
        & git -C $merged merge --no-ff -q 'sync/live-2026-08-20' `
            -m 'merge: sync/live-2026-08-20 (#27)' `
            -m 'sync: mirror in-flight third-party edits from live (2 file(s))' | Out-Null
        $mergeSha = ([string](& git -C $merged rev-parse HEAD)).Trim()
    } finally { $ErrorActionPreference = $prevEap }

    Push-Location -LiteralPath $merged
    try {
        Assert-True ($mergeSha -ne $syncOnBranch) 'ref/merged: the merge commit really is HEAD (fixture sanity)'
        Assert-Equal $syncOnBranch (Get-SyncReferencePoint).Ref 'ref/merged: the floor is the SYNC commit, not the merge that brought it in'

        # The regression half. Without --no-merges this same lookup answers with the merge, i.e. HEAD --
        # which is the failure measured in the consumer, not a hypothetical.
        $unrepaired = Invoke-SyncGitQuiet log -1 --format=%H "--grep=$(Get-SyncDefaultReferencePattern)" 'HEAD' |
            Where-Object { $_ } | Select-Object -First 1
        Assert-Equal $mergeSha ([string]$unrepaired).Trim() 'ref/merged: WITHOUT --no-merges the lookup does pick the merge, so the flag is load-bearing'
    } finally { Pop-Location }

    # No sync commit, but a tag: a wider window, and worth reporting as such.
    $tagged = New-GitTree -Label 'tagged'
    Add-Commit -Dir $tagged -Message 'initial' -Write @{ 'a.txt' = 'a1' } | Out-Null
    $prevEap = $ErrorActionPreference
    try { $ErrorActionPreference = 'Continue'; & git -C $tagged tag 'v1.0.0' | Out-Null } finally { $ErrorActionPreference = $prevEap }
    Add-Commit -Dir $tagged -Message 'feat: after the tag' -Write @{ 'b.txt' = 'b1' } | Out-Null
    Push-Location -LiteralPath $tagged
    try {
        $ref = Get-SyncReferencePoint
        Assert-Equal 'v1.0.0' $ref.Ref  'ref/tagged: the newest tag is the fallback floor'
        Assert-Equal 'tag'    $ref.Kind 'ref/tagged: and it says so, because a tag window is wider'
    } finally { Pop-Location }

    # Neither: $null, so the caller refuses. THE ONE THAT MATTERS MOST -- without a floor every file
    # looks untouched by the trunk, so the exclusion rule would pass everything through and the failure
    # would arrive as a green run.
    $bare = New-GitTree -Label 'bare'
    Add-Commit -Dir $bare -Message 'initial' -Write @{ 'a.txt' = 'a1' } | Out-Null
    Push-Location -LiteralPath $bare
    try {
        Assert-True ($null -eq (Get-SyncReferencePoint)) 'ref/bare: no sync commit and no tag answers $null, not a guess'
    } finally { Pop-Location }

    # --- The exclusion query ------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'Test-MainTouchedSince'

    $rule = New-GitTree -Label 'rule'
    Add-Commit -Dir $rule -Message 'initial' -Write @{
        'changed.txt' = 'v1'; 'deleted.txt' = 'v1'; 'untouched.txt' = 'v1'; 'with space.txt' = 'v1'
    } | Out-Null
    $floor = Add-Commit -Dir $rule -Message 'sync: the floor' -Write @{ 'floor.txt' = 'v1' }
    Add-Commit -Dir $rule -Message 'trunk: change one file'  -Write  @{ 'changed.txt' = 'v2' } | Out-Null
    Add-Commit -Dir $rule -Message 'trunk: delete one file'  -Delete @('deleted.txt') | Out-Null
    Add-Commit -Dir $rule -Message 'trunk: add one file'     -Write  @{ 'added.txt' = 'v1' } | Out-Null
    Add-Commit -Dir $rule -Message 'trunk: touch a spaced path' -Write @{ 'with space.txt' = 'v2' } | Out-Null

    Push-Location -LiteralPath $rule
    try {
        Assert-True     (Test-MainTouchedSince -Since $floor -Path 'changed.txt')   'rule/changed: a modified file is touched'
        Assert-True     (Test-MainTouchedSince -Since $floor -Path 'added.txt')     'rule/added: a file the trunk added is touched, so live must not delete it'
        # THE CASE THE FIRST IMPLEMENTATION GOT WRONG.
        Assert-True     (Test-MainTouchedSince -Since $floor -Path 'deleted.txt')   'rule/deleted: A DELETION IS ALSO A TOUCH -- live must not resurrect it'
        Assert-True     (Test-MainTouchedSince -Since $floor -Path 'with space.txt') 'rule/spaced: a path with a space is measured, not mangled'
        Assert-True (-not (Test-MainTouchedSince -Since $floor -Path 'untouched.txt')) 'rule/untouched: an untouched file is live''s to overwrite'
        # A path that has never existed writes to stderr while being an ordinary "no". Under EAP=Stop that
        # is a terminating NativeCommandError unless the lib lowers it, which is what Invoke-SyncGitQuiet
        # is for -- so this case tests the wrapper as much as the answer.
        Assert-True (-not (Test-MainTouchedSince -Since $floor -Path 'never-existed.txt')) 'rule/absent: a path that never existed answers $false without throwing'
        # The floor itself is exclusive: the sync commit is not "since the sync commit".
        Assert-True (-not (Test-MainTouchedSince -Since $floor -Path 'floor.txt')) 'rule/floor: the reference commit''s own change is not counted as later work'
    } finally { Pop-Location }
}
finally {
    foreach ($d in $script:trees) {
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
