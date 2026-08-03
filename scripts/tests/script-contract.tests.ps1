<#
.SYNOPSIS
    Regression tests for the script-contract check (scripts/sync/check-script-contract.ps1, issue
    #147) and its SessionStart hook
    (plugins/specialists/hooks/script-contract-sessioncheck.ps1).

.DESCRIPTION
    Dependency-free: no Pester, plain PowerShell. Integration-style -- runs the REAL check script (and
    the real hook) in a CHILD PROCESS against throwaway fixture repo roots in the temp dir, and
    asserts on exit-code + output, mirroring roster-sync.tests.ps1 (the closest analogue: same
    -ConsumerPathOverride pattern, same Assert-* helpers, same fixture-setup/teardown style).

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/script-contract.tests.ps1

    Fixture strategy: the POSITIVE fixtures copy the REAL scripts/lib/branch-info.ps1 and
    scripts/repo-config.ps1 verbatim (same idea as new-branch.tests.ps1 copying branch-info.ps1 for
    its real prefix table) -- so a passing suite here is grounded in this repo's actual contract, not
    a hand-rolled stand-in that could silently diverge from it. NEGATIVE fixtures start from that
    same real content and surgically remove one function's definition (Remove-PsFunction, a
    brace-counting cut -- a plain regex could not reliably find the matching closing brace) so the
    rest of the file (helper variables, other functions) stays exactly as-is and the only difference
    from the positive fixture is the one missing function.

    Pure ASCII (repo convention for .ps1).

    Test-gaps (honest):
      - The dual-context repo-root fallback of check-script-contract.ps1 (CLAUDE_PROJECT_DIR / git
        rev-parse when -ConsumerPathOverride is absent) is not exercised here -- every scenario pins
        the root explicitly, the same choice roster-sync.tests.ps1 documents for its own check.
      - Only branch-info.ps1 / repo-config.ps1 syntax-error-via-throw is exercised for the "lib throws
        on load" scenario (a deliberate `throw` statement) -- a genuine PowerShell PARSE error (e.g. an
        unbalanced brace) would also be caught by the same try/catch in the product script, but is not
        separately exercised here; the caught-exception code path is identical either way.
      - The hook's own $env:CLAUDE_PLUGIN_ROOT resolution branch (picking up
        ${CLAUDE_PLUGIN_ROOT}/scripts/sync/check-script-contract.ps1 when -CheckScriptOverride is
        omitted) is not exercised -- every hook scenario here pins -CheckScriptOverride explicitly, so
        the hook is tested end-to-end against the REAL check script rather than a stub, but always via
        the override path, not the plugin-root default.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot      = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script        = Join-Path $RepoRoot 'scripts\sync\check-script-contract.ps1'
$Hook          = Join-Path $RepoRoot 'plugins\specialists\hooks\script-contract-sessioncheck.ps1'
$BranchInfoSrc = Join-Path $RepoRoot 'scripts\lib\branch-info.ps1'
$RepoConfigSrc = Join-Path $RepoRoot 'scripts\repo-config.ps1'
$Fixture       = Join-Path ([System.IO.Path]::GetTempPath()) 'script-contract-test-fixture'

$script:pass = 0
$script:fail = 0

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

function Assert-Match {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern not found: '$Pattern'" -ForegroundColor Red
    }
}

function Assert-NotMatch {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -notmatch $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern present but should not be: '$Pattern'" -ForegroundColor Red
    }
}

function Invoke-Ps {
    param([string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

function Invoke-Hook {
    param([string[]]$HookArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Hook @HookArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

# Removes one PowerShell function definition ('function <Name> { ... }') from $Content, by counting
# braces from the first '{' after the 'function <Name>' token until the matching close -- a plain
# regex cannot reliably find the RIGHT closing brace once the body itself contains nested braces
# (both branch-info.ps1's and repo-config.ps1's functions do, e.g. an inline hashtable literal), so
# this walks the text char-by-char instead. Throws (a fixture-builder bug, not a product bug) if the
# function name is not found, so a typo in a test scenario fails loudly instead of silently keeping
# the "positive" content.
function Remove-PsFunction {
    param([Parameter(Mandatory = $true)][string]$Content, [Parameter(Mandatory = $true)][string]$FunctionName)
    $m = [regex]::Match($Content, "function\s+$([regex]::Escape($FunctionName))\b")
    if (-not $m.Success) {
        throw "Remove-PsFunction: '$FunctionName' not found in the given content -- fixture-builder bug."
    }
    $braceIdx = $Content.IndexOf('{', $m.Index)
    if ($braceIdx -lt 0) {
        throw "Remove-PsFunction: no opening brace found after 'function $FunctionName'."
    }
    $depth = 0
    $i = $braceIdx
    for (; $i -lt $Content.Length; $i++) {
        if ($Content[$i] -eq '{') { $depth++ }
        elseif ($Content[$i] -eq '}') { $depth--; if ($depth -eq 0) { break } }
    }
    if ($i -ge $Content.Length) {
        throw "Remove-PsFunction: no matching closing brace found for '$FunctionName'."
    }
    return $Content.Substring(0, $m.Index) + $Content.Substring($i + 1)
}

$script:RealBranchInfo = [System.IO.File]::ReadAllText($BranchInfoSrc)
$script:RealRepoConfig = [System.IO.File]::ReadAllText($RepoConfigSrc)

# Builds a fixture consumer repo-root with scripts/lib/branch-info.ps1 and/or scripts/repo-config.ps1.
# By default both are the REAL, unmodified content (the positive case). -StripFromBranchInfo /
# -StripFromRepoConfig surgically remove named functions (the negative cases). -OmitBranchInfo /
# -OmitRepoConfig skip writing the file entirely (the "missing lib" cases). -BranchInfoContentOverride
# replaces the whole branch-info.ps1 content outright (the "lib throws on load" case).
function New-FixtureConsumer {
    param(
        [switch]$OmitBranchInfo,
        [switch]$OmitRepoConfig,
        [string[]]$StripFromBranchInfo = @(),
        [string[]]$StripFromRepoConfig = @(),
        [string]$BranchInfoContentOverride,
        [string]$RepoConfigContentOverride
    )
    $root = Join-Path $Fixture 'consumer'
    if (Test-Path -LiteralPath $root) { Remove-Item -Recurse -Force -LiteralPath $root }
    New-Item -ItemType Directory -Path (Join-Path $root 'scripts\lib') -Force | Out-Null

    if (-not $OmitBranchInfo) {
        $content = if ($PSBoundParameters.ContainsKey('BranchInfoContentOverride')) { $BranchInfoContentOverride } else { $script:RealBranchInfo }
        foreach ($fn in $StripFromBranchInfo) { $content = Remove-PsFunction -Content $content -FunctionName $fn }
        [System.IO.File]::WriteAllText((Join-Path $root 'scripts\lib\branch-info.ps1'), $content)
    }
    if (-not $OmitRepoConfig) {
        $content = if ($PSBoundParameters.ContainsKey('RepoConfigContentOverride')) { $RepoConfigContentOverride } else { $script:RealRepoConfig }
        foreach ($fn in $StripFromRepoConfig) { $content = Remove-PsFunction -Content $content -FunctionName $fn }
        [System.IO.File]::WriteAllText((Join-Path $root 'scripts\repo-config.ps1'), $content)
    }
    return $root
}

try {
    Write-Host "== script-contract.tests: check-script-contract.ps1 ==" -ForegroundColor Cyan

    # --- 1. Positive: complete, valid branch-info.ps1 + repo-config.ps1 -> all [OK], exit 0 --------
    $c = New-FixtureConsumer
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 0 $r.Code 'happy path: exit-code 0'
    Assert-NotMatch '\[ERROR\]' $r.Out 'happy path: no errors'
    foreach ($fn in @('Get-BranchInfo', 'Test-BranchName', 'Get-RepoName', 'Get-LintScript', 'Get-RosterPath', 'Get-RosterIgnoredIds', 'Get-ChangelogHeading', 'Get-LiveStage', 'Get-EntryTitlePlaceholder', 'Get-EntryBodyHeading', 'Get-EntryBodyPlaceholder', 'Get-EntryFallbackType', 'Get-PrMergeMethod', 'Get-MojibakePaths', 'Get-ReservedRootMd', 'Get-ReleaseNotesGrouping', 'Get-ReleaseLiveMarker', 'Get-ReleasePluginTier', 'Get-ReleaseCategoryTitles', 'Get-ReleaseHighlightsBumps', 'Get-ReleaseHighlightsStakeholderTypes', 'Get-ReleaseHighlightsWording')) {
        Assert-Match "\[OK\]\s+'$fn' present in" $r.Out "happy path: '$fn' reported OK"
    }
    $okCount = @([regex]::Matches($r.Out, '\[OK\]')).Count
    Assert-Equal 22 $okCount 'happy path: exactly twenty-two [OK] lines (the six mandatory functions + the sixteen optional ones: Get-ChangelogHeading, Get-LiveStage, the four Get-Entry* stub-wording knobs, Get-PrMergeMethod, Get-MojibakePaths and the eight cut-release knobs from #417, nothing else)'
    # inbound #203: the run names the root it inspected and how it resolved it. Asserted on the clean
    # run too, not only on a drifted one -- the [SCOPE] line is context that must always be emitted, so
    # that the hook has something to surface the moment a finding does appear.
    Assert-Match '\[SCOPE\].*check-script-contract inspected' $r.Out 'happy path: a [SCOPE] line names the inspected root'
    Assert-Match ([regex]::Escape($c)) $r.Out 'happy path: the [SCOPE] line names the ACTUAL fixture root, not the session/git root'
    Assert-Match '\[SCOPE\].*-ConsumerPathOverride' $r.Out 'happy path: the [SCOPE] line names HOW the root was resolved (override)'
    # Non-counting, like [OK]/[SKIP]: context must never move the error/info tallies or the exit code.
    Assert-Match 'Summary: 0 error\(s\), 0 info signal\(s\)' $r.Out 'happy path: [SCOPE] is non-counting (0 errors, 0 infos)'

    # --- 2. Missing function in branch-info.ps1 (the exact #147 incident): Test-BranchName ---------
    #     new-branch crashed at runtime with "The term 'Test-BranchName' is not recognized" because
    #     the consumer's branch-info.ps1 predated that helper. Get-BranchInfo stays intact, so this
    #     must be the ONLY error, naming both the function and the shared script it breaks.
    $c = New-FixtureConsumer -StripFromBranchInfo @('Test-BranchName')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 1 $r.Code 'missing Test-BranchName: exit-code 1'
    # The finding must be actionable on its own (Dave, July 28, 2026: a consumer is served by the
    # plugin, not put to work for it). It used to end with "update it from the workshop's own
    # scripts\lib\branch-info.ps1" -- useless to the reader most likely to hit it: someone who installed
    # the plugin, has no copy of that source repo, and no reason to know it exists.
    Assert-Match 'It must return' $r.Out 'missing function: the finding states what the function must return'
    Assert-NotMatch "workshop's own" $r.Out 'missing function: the finding no longer points at a repo the reader may not have'
    Assert-NotMatch 'workshop' $r.Out 'missing function: no internal "workshop" jargon in a consumer-facing finding'
    Assert-Match "\[ERROR\].*'Test-BranchName' missing from scripts\\lib\\branch-info\.ps1.*required by: new-branch" $r.Out 'missing Test-BranchName: ERROR names the function, the lib, and new-branch'
    $errCount1 = @([regex]::Matches($r.Out, '\[ERROR\]')).Count
    Assert-Equal 1 $errCount1 'missing Test-BranchName: exactly one error (Get-BranchInfo unaffected)'
    Assert-Match "\[OK\]\s+'Get-BranchInfo' present in" $r.Out 'missing Test-BranchName: Get-BranchInfo still OK'

    # --- 3. Missing function in repo-config.ps1: Get-RosterPath ------------------------------------
    $c = New-FixtureConsumer -StripFromRepoConfig @('Get-RosterPath')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 1 $r.Code 'missing Get-RosterPath: exit-code 1'
    Assert-Match "\[ERROR\].*'Get-RosterPath' missing from scripts\\repo-config\.ps1.*required by: check-roster-sync" $r.Out 'missing Get-RosterPath: ERROR names the function, the lib, and check-roster-sync'
    $errCount2 = @([regex]::Matches($r.Out, '\[ERROR\]')).Count
    Assert-Equal 1 $errCount2 'missing Get-RosterPath: exactly one error'

    # --- 4. Missing lib file entirely: no scripts/repo-config.ps1 at all ---------------------------
    #     All four repo-config functions are unreachable -> one [ERROR] per function, and the check
    #     itself must not crash (branch-info.ps1 stays valid, so its two functions still report OK).
    $c = New-FixtureConsumer -OmitRepoConfig
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 1 $r.Code 'missing repo-config.ps1: exit-code 1'
    Assert-Match "\[ERROR\].*'scripts\\repo-config\.ps1' not found" $r.Out 'missing repo-config.ps1: ERROR names the missing file'
    foreach ($fn in @('Get-RepoName', 'Get-LintScript', 'Get-RosterPath', 'Get-RosterIgnoredIds')) {
        Assert-Match "\[ERROR\].*'$fn'.*cannot be checked" $r.Out "missing repo-config.ps1: '$fn' reported as unreachable"
    }
    $errCount3 = @([regex]::Matches($r.Out, '\[ERROR\]')).Count
    Assert-Equal 4 $errCount3 'missing repo-config.ps1: exactly four errors (one per MANDATORY repo-config function)'
    Assert-Match "\[INFO\].*'Get-ChangelogHeading'.*falls back to '## Pull Requests'" $r.Out 'missing repo-config.ps1: the optional Get-ChangelogHeading is INFO, not ERROR (#178)'
    Assert-Match "\[OK\]\s+'Get-BranchInfo' present in" $r.Out 'missing repo-config.ps1: branch-info.ps1 unaffected, still OK'

    # --- 4b. ALL libs absent -> one non-counting [BOOTSTRAP] marker, no per-function errors ---------
    #     Issue #225. When no contract lib exists at all, the repo has not been through
    #     specialists-init -- these files are exactly what its bootstrap puts down. Reporting each
    #     required function then produces errors about files that were never meant to exist yet (6 on a
    #     real fresh consumer), phrased as "this lib predates the contract", which is the wrong story
    #     for a repo that has no lib at all. A missing lib is only drift once the repo is set up.
    $c = New-FixtureConsumer -OmitBranchInfo -OmitRepoConfig
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 0 $r.Code 'all libs absent: exit-code 0 -- an unbootstrapped repo is not a failure'
    Assert-Match '\[BOOTSTRAP\]' $r.Out 'all libs absent: the non-counting marker is emitted'
    Assert-Match 'specialists-init' $r.Out 'all libs absent: the marker names the skill that resolves it'
    Assert-Match 'Nothing is broken' $r.Out 'all libs absent: states plainly that the install is fine'
    Assert-NotMatch '\[ERROR\]' $r.Out 'all libs absent: NOT one error per required function'
    # Both lib names belong in the message -- a reader should not have to guess which files are meant.
    Assert-Match 'branch-info\.ps1' $r.Out 'all libs absent: the marker names branch-info.ps1'
    Assert-Match 'repo-config\.ps1' $r.Out 'all libs absent: the marker names repo-config.ps1'

    # --- 4c. The predicate is strict: ONE lib present means real drift, not an unbootstrapped repo ---
    #     Guard against 4b swallowing case 4. Covered there for repo-config; asserted here from the
    #     other side so neither direction can regress into the bootstrap branch.
    $c = New-FixtureConsumer -OmitBranchInfo
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 1 $r.Code 'one lib present: exit-code 1 -- real drift'
    Assert-Match "\[ERROR\].*'scripts\\lib\\branch-info\.ps1' not found" $r.Out 'one lib present: the missing lib is still an ERROR'
    Assert-NotMatch '\[BOOTSTRAP\]' $r.Out 'one lib present: NOT reported as an unbootstrapped repo'

    # --- 5. Lib throws on load: branch-info.ps1 content that raises on dot-source ------------------
    #     Caught, not a crash -- one [ERROR] per function that lib was supposed to provide, naming the
    #     lib and surfacing the underlying exception message.
    $c = New-FixtureConsumer -BranchInfoContentOverride "throw 'fixture: deliberate load failure'"
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 1 $r.Code 'lib throws: exit-code 1'
    Assert-Match "\[ERROR\].*scripts\\lib\\branch-info\.ps1' failed to load.*deliberate load failure" $r.Out 'lib throws: ERROR names the lib and surfaces the exception message'
    $errCount4 = @([regex]::Matches($r.Out, '\[ERROR\]')).Count
    Assert-Equal 2 $errCount4 'lib throws: exactly two errors (Get-BranchInfo + Test-BranchName, both unreachable)'
    Assert-Match "\[OK\]\s+'Get-RepoName' present in" $r.Out 'lib throws: repo-config.ps1 unaffected, still OK'

    # --- 6. Optional Get-Pr* functions are never flagged -------------------------------------------
    #     The real repo-config.ps1 already has none of the four optional Get-Pr* functions (verified:
    #     the check is against this repo's OWN file) -- proving they are correctly excluded from the
    #     contract, not merely absent from a hand-written fixture that forgot them.
    $c = New-FixtureConsumer
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 0 $r.Code 'optional Get-Pr*: exit-code 0'
    foreach ($optFn in @('Get-PrDescriptionPlaceholder', 'Get-PrApprovalPattern', 'Get-PrAssignee', 'Get-PrMilestone')) {
        Assert-NotMatch $optFn $r.Out "optional Get-Pr*: '$optFn' never mentioned (not in the contract)"
    }
    $okCount6 = @([regex]::Matches($r.Out, '\[OK\]')).Count
    Assert-Equal 22 $okCount6 'optional Get-Pr*: still exactly twenty-two [OK] (the mandatory six + the sixteen declared optionals; the four UNdeclared Get-Pr* excluded)'

    # --- 6c. An optional contract function that is ABSENT -> [INFO] naming the fallback, exit 0 -----
    #     Get-ChangelogHeading (issue #178) is declared Optional: fold-changelog-entry.ps1 falls back
    #     to '## Pull Requests', so a consumer whose repo-config predates it is NOT drifted. It must
    #     still be mentioned -- silence would leave a Keep-a-Changelog consumer to discover at fold
    #     time that its section is never found.
    $c = New-FixtureConsumer -StripFromRepoConfig @('Get-ChangelogHeading')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 0 $r.Code 'optional absent: exit-code 0 (a fallback exists, so not a breach)'
    Assert-NotMatch '\[ERROR\]' $r.Out 'optional absent: no error'
    Assert-Match "\[INFO\].*'Get-ChangelogHeading' missing from scripts\\repo-config\.ps1.*used by: fold-changelog-entry.*optional.*falls back to '## Pull Requests'" $r.Out 'optional absent: INFO names the function, the caller and the fallback'

    # --- 6d. Get-LiveStage: absent -> [INFO] naming the empty-string fallback, exit 0 (issue #177) ----
    #     Mirrors test 6c above (Get-ChangelogHeading, issue #178): Get-LiveStage is Optional in the
    #     contract, so a consumer's repo-config.ps1 without it is not drifted -- the cut-release skill's
    #     Block 2 simply never applies (empty default = no separate live stage). Still surfaced, not
    #     silent: a repo that DOES have a live stage needs to learn the getter is missing, or the skill
    #     would silently never print Block 2. Its Default ('') is falsy, so Write-ContractGap's INFO
    #     message uses the "built-in fallback" phrasing rather than naming a quoted default value --
    #     asserted explicitly below (distinct from Get-ChangelogHeading's "falls back to '...'" phrasing
    #     in 6c, which has a non-empty Default).
    $c = New-FixtureConsumer -StripFromRepoConfig @('Get-LiveStage')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 0 $r.Code 'Get-LiveStage absent: exit-code 0 (empty-string fallback, not a breach)'
    Assert-NotMatch '\[ERROR\]' $r.Out 'Get-LiveStage absent: no error'
    Assert-Match "\[INFO\].*'Get-LiveStage' missing from scripts\\repo-config\.ps1.*used by: cut-release skill.*optional; the shared script has a built-in fallback\." $r.Out 'Get-LiveStage absent: INFO names the function, the caller, and the built-in (empty) fallback'
    # Still present -> [OK], not INFO or ERROR (already covered generically by the happy path in test 1;
    # made explicit here too, for direct traceability with the absent-case scenario just above).
    $c2 = New-FixtureConsumer
    $r2 = Invoke-Ps @('-ConsumerPathOverride', $c2)
    Assert-Equal 0 $r2.Code 'Get-LiveStage present: exit-code 0'
    Assert-Match "\[OK\]\s+'Get-LiveStage' present in" $r2.Out 'Get-LiveStage present: reported OK, not INFO or ERROR'

    # --- 6e. The four stub-wording knobs: absent -> four [INFO]s naming their defaults, exit 0 (#410) --
    #     Third instance of the 6c/6d pattern, and the one where "not broken" is most misleading: a
    #     consumer without these gets a perfectly working entry file in the wrong language, every
    #     branch, indefinitely. Nothing crashes, so the [INFO] is the ONLY signal that exists -- which
    #     is precisely the argument for declaring them optional rather than leaving them undeclared.
    #     All four stripped at once, because the failure they guard against is the set being unknown,
    #     not any single one of them.
    $c = New-FixtureConsumer -StripFromRepoConfig @('Get-EntryTitlePlaceholder', 'Get-EntryBodyHeading', 'Get-EntryBodyPlaceholder', 'Get-EntryFallbackType')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 0 $r.Code 'stub wording absent: exit-code 0 (every string has a fallback, not a breach)'
    Assert-NotMatch '\[ERROR\]' $r.Out 'stub wording absent: no error'
    Assert-Match "\[INFO\].*'Get-EntryTitlePlaceholder' missing from scripts\\repo-config\.ps1.*used by: new-changelog-entry.*optional.*falls back to 'TODO: title'" $r.Out 'stub wording absent: INFO for Get-EntryTitlePlaceholder names caller and default'
    Assert-Match ("\[INFO\].*'Get-EntryBodyHeading' missing.*falls back to '" + [regex]::Escape('**To do / where I left off:**') + "'") $r.Out 'stub wording absent: INFO for Get-EntryBodyHeading quotes the literal default heading'
    Assert-Match "\[INFO\].*'Get-EntryFallbackType' missing.*falls back to 'Chore'" $r.Out 'stub wording absent: INFO for Get-EntryFallbackType names the Chore default'
    $infoCount6e = @([regex]::Matches($r.Out, '\[INFO\]')).Count
    Assert-Equal 4 $infoCount6e 'stub wording absent: exactly four [INFO] lines -- one per stripped knob, and nothing else downgraded along with them'

    # --- 6b. Regression guard: legacy pre-strict-mode top-level code must not false-positive --------
    #     Victor's finding (fixed by Sylvester): the check used to dot-source consumer libs under this
    #     script's own `Set-StrictMode -Version Latest`. A repo-config.ps1 that defines every required
    #     function but ALSO carries harmless loose top-level code referencing an unset variable (the
    #     kind of pre-strict-mode code branch-info.ps1/repo-config.ps1 are documented as written on,
    #     and that the real non-strict runtime callers load without error) used to THROW during that
    #     strict-mode dot-source, producing a false [ERROR] for every function in the lib -- even
    #     though nothing is actually missing. The fix dot-sources/probes each consumer lib in a child
    #     scope with `Set-StrictMode -Off`, matching the real runtime. Do NOT delete this scenario when
    #     touching the strict-mode handling again -- it is the guard against that exact regression.
    $legacyRepoConfig = @'
# Fixture repo-config.ps1: a legacy consumer lib that defines all four required functions but also
# has a harmless loose top-level statement referencing an unset variable -- pre-strict-mode code an
# older consumer repo legitimately carries.
if ($LegacyDebugFlag) { Write-Host 'legacy debug mode' }

function Get-RepoName { return 'fixture-repo' }
function Get-LintScript { return 'scripts/lint/check-plugin-integrity.ps1' }
function Get-RosterPath { return 'ROSTER.md' }
function Get-RosterIgnoredIds { return @() }
'@
    $c = New-FixtureConsumer -RepoConfigContentOverride $legacyRepoConfig
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 0 $r.Code 'strict-mode regression: exit-code 0 (loose legacy code must not trip a false failure)'
    Assert-NotMatch '\[ERROR\]' $r.Out 'strict-mode regression: zero [ERROR] lines'
    foreach ($fn in @('Get-BranchInfo', 'Test-BranchName', 'Get-RepoName', 'Get-LintScript', 'Get-RosterPath', 'Get-RosterIgnoredIds')) {
        Assert-Match "\[OK\]\s+'$fn' present in" $r.Out "strict-mode regression: '$fn' still reported OK"
    }
    $okCount6b = @([regex]::Matches($r.Out, '\[OK\]')).Count
    Assert-Equal 6 $okCount6b 'strict-mode regression: exactly six [OK] lines (all functions detected despite the loose top-level code)'

    Write-Host "`n== script-contract.tests: contract-completeness drift guard ==" -ForegroundColor Cyan
    # Two-layered defense against the declared $script:Contract array in check-script-contract.ps1
    # silently going stale, chosen over the weaker "just re-type the pairs here" option because
    # that would only catch an accidental REMOVAL and would drift itself the moment a maintainer edits
    # the contract without updating this test:
    #   (a) parse the (Lib, Function, Scripts) records straight out of the check script's OWN
    #       source text (not re-typed here) and assert the exact set/attribution still matches what
    #       issue #147 (and #178, #177) declared -- catches a silent removal or a changed Scripts
    #       attribution.
    #   (b) for every (Function, Scripts) pair found, verify the function is really referenced where
    #       the contract claims it is used -- catches a contract entry going STALE (e.g. a refactor
    #       that stops calling the function while the contract still lists it), which a simple
    #       re-typed-list assertion could never catch.
    #
    # Design decision for Tycho (issue #177): the eighth record, Get-LiveStage, is checked by a
    # SEPARATE, dedicated block right after this loop rather than being folded into $expectedContract.
    # Reason: its Scripts attribution names the cut-release SKILL ('cut-release skill'), not a
    # mirrored shared script -- Get-SharedScriptPairs (the shared-script registry) genuinely does not
    # know it and should not, so the loop's per-script "is this a registered shared script" assertion
    # does not apply to it. Get-LiveStage instead gets its own literal/regex assertion for the record's
    # declaration AND its own staleness check against the real source of the cut-release SKILL.md it is
    # attributed to (the skill-file analogue of the loop's shared-script check) -- see the dedicated
    # block right after the loop. Both records are covered end to end, just by two different, fitting
    # mechanisms. The guard against a FUTURE ninth record silently falling outside coverage is
    # $totalRecordCount below (parsed from the check script's own source): a new record bumps that
    # count and this test goes red until a maintainer adds either a new $expectedContract entry (a real
    # shared script) or a new dedicated block (a skill or other non-mirrored attribution).
    . (Join-Path $RepoRoot 'scripts\lib\shared-scripts-lib.ps1')
    $pairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot)
    $pairsByName = @{}
    foreach ($p in $pairs) { $pairsByName[$p.Name] = $p }

    $expectedContract = @(
        @{ Function = 'Get-BranchInfo';      Lib = 'scripts\lib\branch-info.ps1'; Scripts = @('new-changelog-entry', 'open-pr') },
        @{ Function = 'Test-BranchName';      Lib = 'scripts\lib\branch-info.ps1'; Scripts = @('new-branch') },
        @{ Function = 'Get-RepoName';         Lib = 'scripts\repo-config.ps1';     Scripts = @('open-pr', 'fold-changelog-entry', 'ship-pr', 'verify-resolved-issues') },
        @{ Function = 'Get-LintScript';       Lib = 'scripts\repo-config.ps1';     Scripts = @('open-pr') },
        @{ Function = 'Get-RosterPath';       Lib = 'scripts\repo-config.ps1';     Scripts = @('check-roster-sync') },
        @{ Function = 'Get-RosterIgnoredIds'; Lib = 'scripts\repo-config.ps1';     Scripts = @('check-roster-sync') },
        @{ Function = 'Get-ChangelogHeading'; Lib = 'scripts\repo-config.ps1';     Scripts = @('fold-changelog-entry') },
        # The four stub-wording knobs (issue #410). These DO belong in this loop, unlike Get-LiveStage:
        # they are attributed to 'new-changelog-entry', a genuinely registered shared script, so the
        # per-script assertions below apply to them unchanged.
        # Three of the four gained a SECOND reader: open-pr.ps1's scaffold gate refuses a PR whose entry
        # still carries this wording, through the same shared lib the writer uses. The per-script assertion
        # below therefore now checks BOTH scripts really reference each one -- which is what would catch the
        # gate being removed while the contract still promised it.
        @{ Function = 'Get-EntryTitlePlaceholder'; Lib = 'scripts\repo-config.ps1'; Scripts = @('new-changelog-entry', 'open-pr'); ViaLib = 'entry-scaffold-lib' },
        @{ Function = 'Get-EntryBodyHeading';      Lib = 'scripts\repo-config.ps1'; Scripts = @('new-changelog-entry', 'open-pr'); ViaLib = 'entry-scaffold-lib' },
        @{ Function = 'Get-EntryBodyPlaceholder';  Lib = 'scripts\repo-config.ps1'; Scripts = @('new-changelog-entry', 'open-pr'); ViaLib = 'entry-scaffold-lib' },
        # The fourth stays single-reader on purpose: a changelog TYPE is not scaffold prose, so 'Chore' is a
        # legitimate final value and can never be evidence of an unedited entry.
        @{ Function = 'Get-EntryFallbackType';     Lib = 'scripts\repo-config.ps1'; Scripts = @('new-changelog-entry') },
        # The two knobs the newly mirrored scripts brought with them (issues #411 and #413). Both belong
        # in this loop for the same reason the Get-Entry* four do: they are attributed to real registered
        # shared scripts, so the per-script assertions below apply unchanged -- and those assertions are
        # exactly what would have caught the mirror being forgotten.
        @{ Function = 'Get-PrMergeMethod';         Lib = 'scripts\repo-config.ps1'; Scripts = @('ship-pr') },
        @{ Function = 'Get-MojibakePaths';         Lib = 'scripts\repo-config.ps1'; Scripts = @('fix-mojibake') },
        # The eight cut-release knobs (issue #417): five from phase 1, then the three the highlights
        # tier brought in phase 2. Same reasoning again: all attributed to 'cut-release', a registered
        # shared script, so the per-script assertions below cover them -- and those assertions are what
        # would catch the mirror or the seam being forgotten. The last of them is load-bearing for the
        # highlights three in particular: cut-release must really reference all three, which is what
        # separates a ported feature from three knobs nothing reads.
        @{ Function = 'Get-ReservedRootMd';        Lib = 'scripts\repo-config.ps1'; Scripts = @('cut-release') },
        @{ Function = 'Get-ReleaseNotesGrouping';  Lib = 'scripts\repo-config.ps1'; Scripts = @('cut-release') },
        @{ Function = 'Get-ReleaseLiveMarker';     Lib = 'scripts\repo-config.ps1'; Scripts = @('cut-release') },
        @{ Function = 'Get-ReleasePluginTier';     Lib = 'scripts\repo-config.ps1'; Scripts = @('cut-release') },
        @{ Function = 'Get-ReleaseCategoryTitles'; Lib = 'scripts\repo-config.ps1'; Scripts = @('cut-release') },
        @{ Function = 'Get-ReleaseHighlightsBumps';            Lib = 'scripts\repo-config.ps1'; Scripts = @('cut-release') },
        @{ Function = 'Get-ReleaseHighlightsStakeholderTypes'; Lib = 'scripts\repo-config.ps1'; Scripts = @('cut-release') },
        @{ Function = 'Get-ReleaseHighlightsWording';          Lib = 'scripts\repo-config.ps1'; Scripts = @('cut-release') }
    )

    $contractSrc = [System.IO.File]::ReadAllText($Script)
    $totalRecordCount = @([regex]::Matches($contractSrc, "Lib\s*=\s*'[^']+';\s*Function\s*=\s*'[^']+';\s*Scripts\s*=\s*@\(")).Count
    Assert-Equal 22 $totalRecordCount 'contract: exactly twenty-two (lib, function) records declared in check-script-contract.ps1 (the twenty-one below plus the dedicated Get-LiveStage block after this loop)'

    # Every record must carry a 'Returns' line, so a finding is actionable without any reference to this
    # source repo (Dave, July 28, 2026). Counted against $totalRecordCount rather than listed per record:
    # a ninth record added without a Returns then turns this red, which is exactly the drift to catch --
    # Get-RecordReturns degrades silently to the shorter message, so nothing else would notice.
    $returnsCount = @([regex]::Matches($contractSrc, "(?m)^\s*Returns\s*=\s*")).Count
    Assert-Equal $totalRecordCount $returnsCount 'contract: every declared record carries a Returns line (a finding must be actionable without the source repo)'

    foreach ($e in $expectedContract) {
        # Pitfall for whoever adds a record 9 here: this capture -- @\(([^)]*)\) -- stops at the FIRST
        # ')' it meets, so a Scripts value carrying its own parenthesis (e.g. 'foo (bar)') gets truncated
        # before the record's real closing paren. Keep every Scripts entry parenthesis-free; a record
        # attributed to something that needs a parenthetical name is a sign it does not belong in this
        # loop at all (see the design-decision comment above for Get-LiveStage, whose own dedicated
        # block below sidesteps this capture entirely).
        $pattern = "Lib\s*=\s*'([^']+)';\s*Function\s*=\s*'" + [regex]::Escape($e.Function) + "';\s*Scripts\s*=\s*@\(([^)]*)\)"
        $m = [regex]::Match($contractSrc, $pattern)
        Assert-True $m.Success "contract: record for '$($e.Function)' still declared"
        if ($m.Success) {
            Assert-Equal $e.Lib $m.Groups[1].Value "contract: '$($e.Function)' still attributed to $($e.Lib)"
            $actualScripts = @($m.Groups[2].Value -split ',' | ForEach-Object { $_.Trim().Trim("'") } | Where-Object { $_ })
            $expectedSorted = ($e.Scripts | Sort-Object) -join ','
            $actualSorted   = ($actualScripts | Sort-Object) -join ','
            Assert-Equal $expectedSorted $actualSorted "contract: '$($e.Function)' still required by exactly {$($e.Scripts -join ', ')}"

            # A record may reach its function INDIRECTLY, through a shared library both callers dot-source
            # (ViaLib). Then the proof is two-part and stricter than the direct match: the script must
            # really dot-source that lib, and the lib must really name the function. The direct form was
            # satisfiable by a mention in a docstring; this one is not, because a dot-source line is code.
            $viaLib = if ($e.ContainsKey('ViaLib')) { $e.ViaLib } else { $null }
            if ($viaLib) {
                Assert-True $pairsByName.ContainsKey($viaLib) "contract: '$viaLib' is a registered shared lib (Get-SharedScriptPairs)"
            }
            foreach ($scriptName in $actualScripts) {
                Assert-True $pairsByName.ContainsKey($scriptName) "contract: '$scriptName' is a registered shared script (Get-SharedScriptPairs)"
                if ($pairsByName.ContainsKey($scriptName)) {
                    $srcText = [System.IO.File]::ReadAllText($pairsByName[$scriptName].SourcePath)
                    if ($viaLib -and $pairsByName.ContainsKey($viaLib)) {
                        $libLeaf = Split-Path $pairsByName[$viaLib].SourcePath -Leaf
                        Assert-True ($srcText -match [regex]::Escape($libLeaf)) "contract: shared script '$scriptName' really dot-sources '$libLeaf' (the route to '$($e.Function)')"
                        $libText = [System.IO.File]::ReadAllText($pairsByName[$viaLib].SourcePath)
                        Assert-True ($libText -match [regex]::Escape($e.Function)) "contract: shared lib '$libLeaf' really references '$($e.Function)' (not a stale entry)"
                    } else {
                        Assert-True ($srcText -match [regex]::Escape($e.Function)) "contract: shared script '$scriptName' really references '$($e.Function)' in its own real source (not a stale entry)"
                    }
                }
            }
        }
    }

    # --- Get-LiveStage (record 8, issue #177): its own dedicated check -- see the design-decision -----
    #     comment above this loop for why it is not folded into $expectedContract. Verified by hand
    #     (scratch script, not checked in) before writing this pattern: it correctly matches the real
    #     record and correctly fails to match if the Lib/Scripts/Optional/Default attribution changes.
    $liveStagePattern = 'Lib\s*=\s*''scripts\\repo-config\.ps1'';\s*Function\s*=\s*''Get-LiveStage'';\s*Scripts\s*=\s*@\(''cut-release skill''\);\s*Optional\s*=\s*\$true;\s*Default\s*=\s*'''''
    Assert-True ([regex]::IsMatch($contractSrc, $liveStagePattern)) "contract: record for 'Get-LiveStage' still declared, attributed to scripts\repo-config.ps1 / 'cut-release skill', Optional with an empty-string Default"

    $cutReleaseSkillPath = Join-Path $RepoRoot 'plugins\specialists\skills\cut-release\SKILL.md'
    Assert-True (Test-Path -LiteralPath $cutReleaseSkillPath) 'contract: cut-release SKILL.md exists at the path the Get-LiveStage record is attributed to'
    if (Test-Path -LiteralPath $cutReleaseSkillPath) {
        $skillText = [System.IO.File]::ReadAllText($cutReleaseSkillPath)
        Assert-True ($skillText -match 'Get-LiveStage') "contract: cut-release SKILL.md really references 'Get-LiveStage' in its own real source (not a stale entry)"
    }

    Write-Host "`n== script-contract.tests: script-contract-sessioncheck.ps1 (hook) ==" -ForegroundColor Cyan

    # --- 7. Clean repo -> "in sync" line, exit 0, no [ERROR] surfaced ------------------------------
    $c = New-FixtureConsumer
    $r = Invoke-Hook @('-CheckScriptOverride', $Script, '-ConsumerPathOverride', $c)
    Assert-Equal 0 $r.Code 'hook clean: exit 0'
    Assert-Match 'script contract in sync' $r.Out 'hook clean: in-sync message'
    Assert-NotMatch '\[ERROR\]' $r.Out 'hook clean: no [ERROR] surfaced'
    Assert-NotMatch 'drift found' $r.Out 'hook clean: no drift summary'

    # --- 8. Drifted repo (missing Test-BranchName) -> [ERROR] surfaced, exit 0 (hook always exits 0) --
    $c = New-FixtureConsumer -StripFromBranchInfo @('Test-BranchName')
    $r = Invoke-Hook @('-CheckScriptOverride', $Script, '-ConsumerPathOverride', $c)
    Assert-Equal 0 $r.Code 'hook drifted: exit 0 (never blocks the session)'
    Assert-Match 'script-contract drift found' $r.Out 'hook drifted: drift summary shown'
    Assert-Match "\[ERROR\].*Test-BranchName" $r.Out 'hook drifted: the [ERROR] line is surfaced verbatim'
    # The end-to-end version of inbound #203, against the REAL check rather than a stub: a finding that
    # reaches the session must arrive with the repo it is about. The 2026-07-27 incident was exactly
    # this line going missing -- a true Test-BranchName finding, read as being about the wrong repo.
    Assert-Match '\[SCOPE\].*check-script-contract inspected' $r.Out 'hook drifted: the [SCOPE] line survives the [ERROR] filter'
    Assert-Match ([regex]::Escape($c)) $r.Out 'hook drifted: the surfaced scope is the fixture root the check really inspected'
    Assert-NotMatch 'may be partial' $r.Out 'hook drifted: a complete real check run is not flagged as partial'
    # [OK] lines must still stay out: widening the filter for [SCOPE] must not have widened it further.
    Assert-NotMatch '\[OK\]' $r.Out 'hook drifted: [OK] lines still stay out of the session context'

    # --- 9. Check script not found (-CheckScriptOverride to a nonexistent path) --------------------
    $missing = Join-Path $Fixture 'does-not-exist.ps1'
    $r = Invoke-Hook @('-CheckScriptOverride', $missing)
    Assert-Equal 0 $r.Code 'hook missing check script: exit 0'
    Assert-Match 'not found -- check skipped' $r.Out 'hook missing check script: notice'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host "`nResult: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
