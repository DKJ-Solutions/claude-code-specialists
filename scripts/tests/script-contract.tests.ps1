<#
.SYNOPSIS
    Regression tests for the script-contract check (scripts/sync/check-script-contract.ps1, issue
    #147) and its SessionStart hook
    (claude-code-plugins/claude-specialists/specialists/hooks/script-contract-sessioncheck.ps1).

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
$Hook          = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\hooks\script-contract-sessioncheck.ps1'
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
    foreach ($fn in @('Get-BranchInfo', 'Test-BranchName', 'Get-RepoName', 'Get-LintScript', 'Get-RosterPath', 'Get-RosterIgnoredIds', 'Get-ChangelogHeading')) {
        Assert-Match "\[OK\]\s+'$fn' present in" $r.Out "happy path: '$fn' reported OK"
    }
    $okCount = @([regex]::Matches($r.Out, '\[OK\]')).Count
    Assert-Equal 7 $okCount 'happy path: exactly seven [OK] lines (the six mandatory functions + the optional Get-ChangelogHeading, nothing else)'

    # --- 2. Missing function in branch-info.ps1 (the exact #147 incident): Test-BranchName ---------
    #     new-branch crashed at runtime with "The term 'Test-BranchName' is not recognized" because
    #     the consumer's branch-info.ps1 predated that helper. Get-BranchInfo stays intact, so this
    #     must be the ONLY error, naming both the function and the shared script it breaks.
    $c = New-FixtureConsumer -StripFromBranchInfo @('Test-BranchName')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c)
    Assert-Equal 1 $r.Code 'missing Test-BranchName: exit-code 1'
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
    Assert-Equal 7 $okCount6 'optional Get-Pr*: still exactly seven [OK] (the mandatory six + Get-ChangelogHeading; the Get-Pr* four excluded)'

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
    # silently going stale, chosen over the weaker "just re-type the six pairs here" option because
    # that would only catch an accidental REMOVAL and would drift itself the moment a maintainer edits
    # the contract without updating this test:
    #   (a) parse the six (Lib, Function, Scripts) records straight out of the check script's OWN
    #       source text (not re-typed here) and assert the exact set/attribution still matches what
    #       issue #147 declared -- catches a silent removal or a changed Scripts attribution.
    #   (b) for every (Function, Scripts) pair found, read the REAL source of each named shared script
    #       (via Get-SharedScriptPairs, the same SSOT shared-scripts.tests.ps1 uses) and assert the
    #       function name actually appears there -- catches a contract entry going STALE (e.g. a
    #       shared script refactored to stop calling the function while the contract still lists it),
    #       which a simple re-typed-list assertion could never catch.
    . (Join-Path $RepoRoot 'scripts\lib\shared-scripts-lib.ps1')
    $pairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot)
    $pairsByName = @{}
    foreach ($p in $pairs) { $pairsByName[$p.Name] = $p }

    $expectedContract = @(
        @{ Function = 'Get-BranchInfo';      Lib = 'scripts\lib\branch-info.ps1'; Scripts = @('new-changelog-entry', 'open-pr') },
        @{ Function = 'Test-BranchName';      Lib = 'scripts\lib\branch-info.ps1'; Scripts = @('new-branch') },
        @{ Function = 'Get-RepoName';         Lib = 'scripts\repo-config.ps1';     Scripts = @('open-pr', 'fold-changelog-entry') },
        @{ Function = 'Get-LintScript';       Lib = 'scripts\repo-config.ps1';     Scripts = @('open-pr') },
        @{ Function = 'Get-RosterPath';       Lib = 'scripts\repo-config.ps1';     Scripts = @('check-roster-sync') },
        @{ Function = 'Get-RosterIgnoredIds'; Lib = 'scripts\repo-config.ps1';     Scripts = @('check-roster-sync') },
        @{ Function = 'Get-ChangelogHeading'; Lib = 'scripts\repo-config.ps1';     Scripts = @('fold-changelog-entry') }
    )

    $contractSrc = [System.IO.File]::ReadAllText($Script)
    $totalRecordCount = @([regex]::Matches($contractSrc, "Lib\s*=\s*'[^']+';\s*Function\s*=\s*'[^']+';\s*Scripts\s*=\s*@\(")).Count
    Assert-Equal 7 $totalRecordCount 'contract: exactly seven (lib, function) records declared in check-script-contract.ps1'

    foreach ($e in $expectedContract) {
        $pattern = "Lib\s*=\s*'([^']+)';\s*Function\s*=\s*'" + [regex]::Escape($e.Function) + "';\s*Scripts\s*=\s*@\(([^)]*)\)"
        $m = [regex]::Match($contractSrc, $pattern)
        Assert-True $m.Success "contract: record for '$($e.Function)' still declared"
        if ($m.Success) {
            Assert-Equal $e.Lib $m.Groups[1].Value "contract: '$($e.Function)' still attributed to $($e.Lib)"
            $actualScripts = @($m.Groups[2].Value -split ',' | ForEach-Object { $_.Trim().Trim("'") } | Where-Object { $_ })
            $expectedSorted = ($e.Scripts | Sort-Object) -join ','
            $actualSorted   = ($actualScripts | Sort-Object) -join ','
            Assert-Equal $expectedSorted $actualSorted "contract: '$($e.Function)' still required by exactly {$($e.Scripts -join ', ')}"

            foreach ($scriptName in $actualScripts) {
                Assert-True $pairsByName.ContainsKey($scriptName) "contract: '$scriptName' is a registered shared script (Get-SharedScriptPairs)"
                if ($pairsByName.ContainsKey($scriptName)) {
                    $srcText = [System.IO.File]::ReadAllText($pairsByName[$scriptName].SourcePath)
                    Assert-True ($srcText -match [regex]::Escape($e.Function)) "contract: shared script '$scriptName' really references '$($e.Function)' in its own real source (not a stale entry)"
                }
            }
        }
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
