<#
.SYNOPSIS
    Tests for the shared lens-location helpers in scripts/lib/check-report-lib.ps1.

.DESCRIPTION
    These functions decide WHERE a consumer's repo lenses live, which makes them the single point every
    reader (the roster check, the drift lint, the teardown) and every writer (the bootstrap) agrees on.
    They had no direct test before the seam (issue #221) was added -- only indirect coverage through the
    suites that happen to call them, which is exactly the kind of shared decision that deserves its own
    assertions.

    The interesting one is Get-LensWriteDir. It encodes a promise that is easy to break by accident:
    the bootstrap never relocates a lens tree the repo owner already has, so a consumer who adopted
    before the seam keeps their layout, and a consumer who migrates by hand is followed automatically.

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $RepoRoot 'scripts\lib\check-report-lib.ps1')

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

$Fixture = Join-Path ([System.IO.Path]::GetTempPath()) "check-report-lib-test-$PID"

try {
    Write-Host "== check-report-lib.tests: lens locations and the seam ==" -ForegroundColor Cyan
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null

    # --- 1. Get-SeamPaths: the literals the bootstrap writes and the teardown matches ---------------
    #     One source for both sides. If these drift the bootstrap writes a line the teardown cannot
    #     find, and the consumer is left with a dangling import -- silent, because nothing errors.
    Write-Host "Get-SeamPaths -- the shared literals" -ForegroundColor Cyan
    $seam = Get-SeamPaths -RepoRoot $Fixture
    Assert-Equal (Join-Path $Fixture '.claude\specialists') $seam.Dir 'seam dir is .claude\specialists'
    Assert-Equal (Join-Path $Fixture '.claude\specialists\lenses') $seam.LensDir 'lenses live in the seam dir'
    Assert-Equal (Join-Path $Fixture '.claude\specialists\SPECIALISTS.md') $seam.Inclusion 'the inclusion is SPECIALISTS.md'
    Assert-Equal '@.claude/specialists/SPECIALISTS.md' $seam.ImportLine 'the import line is exactly the seam line'
    # An '@'-import path is not a filesystem path: it must read identically on every platform, so a
    # backslash must never leak into it from Join-Path.
    Assert-True (-not ($seam.ImportLine -match '\\')) 'the import line is forward-slashed, never backslashed'

    # --- 2. Get-LensDirCandidates: the seam is the most canonical, legacy still follows -------------
    Write-Host "Get-LensDirCandidates -- order and back-compat" -ForegroundColor Cyan
    $cands = @(Get-LensDirCandidates -RepoRoot $Fixture -PluginName 'team-alpha')
    Assert-Equal $seam.LensDir $cands[0] 'the seam is candidate 0 -- the most canonical'
    Assert-True ($cands -contains (Join-Path $Fixture '.claude\plugins\claude-specialists\team-alpha')) 'the pre-seam plugin path is still read'
    Assert-Equal (Join-Path $Fixture '.claude\extensions') $cands[-1] 'the legacy pre-plugin-path location is still read, and stays last'

    # --- 3. Get-LensWriteDir: THE PROMISE -- never relocate an existing tree ------------------------
    #     Fresh consumer -> the seam. A consumer that already has lenses somewhere -> that same place,
    #     because writing seam lenses beside a legacy tree would split the surface in two and leave the
    #     teardown reasoning about both at once.
    Write-Host "Get-LensWriteDir -- fresh gets the seam, an adopted consumer is left alone" -ForegroundColor Cyan
    Assert-Equal $seam.LensDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'team-alpha') 'fresh consumer: writes to the seam'

    $legacyDir = Join-Path $Fixture '.claude\plugins\claude-specialists\team-alpha'
    New-Item -ItemType Directory -Path $legacyDir -Force | Out-Null
    $legacyLens = Join-Path $legacyDir '06-16-extension.md'
    [System.IO.File]::WriteAllText($legacyLens, "# 06-16 repo lens`n")
    Assert-Equal $legacyDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'team-alpha') 'adopted consumer: keeps writing to its existing tree, not the seam'

    # An EMPTY legacy directory is not an adopted consumer -- only an actual lens counts, so a stray
    # leftover folder does not pin a fresh repo to the old layout.
    Remove-Item -LiteralPath $legacyLens -Force
    Assert-Equal $seam.LensDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'team-alpha') 'an empty legacy directory does not count as adopted'

    # And once the owner migrates by hand, the writer follows them without being told.
    New-Item -ItemType Directory -Path $seam.LensDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $seam.LensDir '06-16-extension.md'), "# 06-16 repo lens`n")
    Assert-Equal $seam.LensDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'team-alpha') 'after a hand migration the writer follows to the seam automatically'

    # --- 4. Write-Coverage: a verdict never travels without its coverage (issue #221) ----------------
    #     The line exists so an empty category cannot pass in silence, so the assertions are about
    #     exactly that: the zero must be PRESENT and must be distinguishable from a healthy count.
    Write-Host "Write-Coverage -- the non-counting [COVERAGE] line" -ForegroundColor Cyan
    # $script:errors/$script:infos are what the lib's Write-Info/Write-Failure bump. Coverage is
    # context, not a signal, so these must be untouched afterwards -- otherwise a legitimately empty
    # category would break its own gate, which is the opposite of the point.
    $script:errors = 0
    $script:infos = 0

    $out = (Write-Coverage -Category 'lenses' -Checked 0 -Of 4 -Note 'nothing to compare' 6>&1 | Out-String)
    Assert-True ($out -match '\[lenses\] checked 0 of 4 -- nothing to compare') 'empty category: category, count, denominator and reason all on one line'
    Assert-Equal 0 $script:errors 'empty category does NOT count as an error -- an empty category is a fact, not a failure'
    Assert-Equal 0 $script:infos  'empty category does NOT count as an info signal either -- [COVERAGE] is non-counting, like [OK]/[SKIP]/[SCOPE]'

    $out = (Write-Coverage -Category 'lenses' -Checked 4 -Of 4 6>&1 | Out-String)
    Assert-True ($out -match '\[lenses\] checked 4 of 4') 'healthy category: states the real count'
    Assert-True (-not ($out -match ' -- ')) 'healthy category: no reason appended when none was given'

    # -Of omitted: a category whose count IS the whole story (files scanned) reads as a plain number,
    # not as "of -1".
    $out = (Write-Coverage -Category 'parse' -Checked 51 6>&1 | Out-String)
    Assert-True ($out -match '\[parse\] checked 51') 'no denominator: plain count'
    Assert-True (-not ($out -match 'of -1')) 'no denominator: the sentinel never leaks into the output'

    # --- Format-SafeToken / Format-SuspectToken (inbound #309) ------------------------------------
    #     A plugin id is an 'enabledPlugins' KEY NAME -- an arbitrary JSON string -- and it is printed
    #     into lines the SessionStart hooks forward into the session context. An unsanitized newline
    #     there forges a line. The reasoning was already recorded on Set-CheckScope since #203; it had
    #     been applied to exactly one value, and #302 added markers that print ids.
    Write-Host "Format-SafeToken -- untrusted values that get PRINTED" -ForegroundColor Cyan
    # A legitimate id must survive completely untouched, or this guard would corrupt every normal report.
    Assert-Equal 'team-alpha@claude-code-specialists' (Format-SafeToken -Value 'team-alpha@claude-code-specialists') 'a real plugin id passes through unchanged'
    Assert-Equal 'team-lifehub@claude-code-specialists' (Format-SafeToken -Value 'team-lifehub@claude-code-specialists') 'hyphens and @ survive'
    Assert-Equal '06-16' (Format-SafeToken -Value '06-16') 'a specialist id survives'
    Assert-Equal 'a.b_c/d' (Format-SafeToken -Value 'a.b_c/d') 'dot, underscore and slash are in the charset'

    # THE FORGERY CASE. A newline must not survive in ANY of its shapes -- LF, CRLF or a lone CR. It is
    # STRIPPED rather than turned into a space, because the charset filter runs before the whitespace
    # collapse and a newline is not in the charset.
    foreach ($nl in @("a`nb", "a`r`nb", "a`rb")) {
        Assert-Equal 'ab' (Format-SafeToken -Value $nl) "a newline is stripped, never printed ($([int][char]$nl[1]))"
    }
    Assert-True (-not ((Format-SafeToken -Value "x`n  [ERROR] forged") -match "`n")) 'no newline survives, so no line can be forged'
    # And a second layer that falls out of the same charset, worth pinning deliberately rather than
    # leaving as a happy accident: '[' and ']' are not in it either, so a value cannot fabricate a MARKER
    # TOKEN even on the line it is legitimately printed on. The hooks filter on exactly those tokens
    # ([ERROR], [NOT-INSTALLED-HERE], ...), so this is what stops a crafted id from promoting itself into
    # a surfaced signal without needing a newline at all.
    Assert-Equal 'x ERROR forged' (Format-SafeToken -Value "x`n  [ERROR] forged") 'brackets are stripped too, so a marker token cannot be forged inline either'
    Assert-True (-not ((Format-SafeToken -Value '[NOT-INSTALLED-HERE]') -match '\[')) 'no square bracket survives from an untrusted value'
    # Control characters and the brackets/colons a report line is structured with.
    Assert-Equal 'ab' (Format-SafeToken -Value "a`tb") 'a tab is collapsed away'
    Assert-Equal 'ab' (Format-SafeToken -Value "a$([char]0)b") 'a NUL is stripped'
    Assert-Equal 'ab' (Format-SafeToken -Value "a$([char]27)b") 'an ESC is stripped -- no ANSI escape reaches a terminal'
    # Length cap, so a multi-kilobyte key cannot flood the session context.
    Assert-Equal 120 (Format-SafeToken -Value ('z' * 500)).Length 'over-long values are capped at 120'
    Assert-Equal 8 (Format-SafeToken -Value ('z' * 500) -MaxLength 8).Length 'the cap is overridable'
    Assert-Equal '' (Format-SafeToken -Value '') 'empty in, empty out -- no throw'

    Write-Host "Format-SafePathToken -- untrusted values that ARE paths (inbound #414)" -ForegroundColor Cyan
    # The reason this function exists rather than a wider charset on Format-SafeToken: the id-shaped
    # sanitizer strips exactly the characters that make a path findable, and a finding whose whole job is
    # to name a missing file must print one the reader can look up.
    Assert-Equal 'CUsersDaveKok.claudepluginsx.md' (Format-SafeToken -Value 'C:\Users\DaveKok\.claude\plugins\x.md') 'the id-shaped sanitizer mangles a Windows path into something unlookupable -- the defect this function avoids'
    Assert-Equal 'C:\Users\DaveKok\.claude\plugins\x.md' (Format-SafePathToken -Value 'C:\Users\DaveKok\.claude\plugins\x.md') 'a Windows path survives intact: drive letter, colon and separators'
    Assert-Equal '~/.claude/plugins/marketplaces/m/personas/01-01-persona.md' (Format-SafePathToken -Value '~/.claude/plugins/marketplaces/m/personas/01-01-persona.md') "a home-relative path keeps its '~' -- without it the reader cannot tell where the path starts"
    Assert-Equal 'lenses/01-01-extension.md' (Format-SafePathToken -Value 'lenses/01-01-extension.md') 'a plain relative path passes through unchanged'

    # The two things that still MUST NOT survive, for the same reasons as in Format-SafeToken: these
    # lines are forwarded into session context by the SessionStart hooks.
    Assert-True (-not ((Format-SafePathToken -Value "x`n  [ERROR] forged") -match "`n")) 'no newline survives, so no line can be forged'
    Assert-True (-not ((Format-SafePathToken -Value '[NOT-INSTALLED-HERE]') -match '\[')) 'no square bracket survives -- a marker in a path would be COUNTED by the hook, not just look odd'
    Assert-Equal 'ab' (Format-SafePathToken -Value "a$([char]27)b") 'an ESC is stripped -- no ANSI escape reaches a terminal'
    Assert-Equal 'ab' (Format-SafePathToken -Value "a$([char]0)b") 'a NUL is stripped'
    # Longer cap than the id form (a path is legitimately longer), and truncation SAYS it truncated --
    # a silently cut path reads as a real path that simply is not there.
    Assert-Equal 200 (Format-SafePathToken -Value ('z' * 500)).Length 'over-long paths are capped at 200'
    Assert-True ((Format-SafePathToken -Value ('z' * 500)) -match '\.\.\.$') 'and a capped path ends in an ellipsis rather than looking complete'
    Assert-Equal '' (Format-SafePathToken -Value '') 'empty in, empty out -- no throw'

    # Set-CheckScope must still behave exactly as before: it now delegates, and its label carries NO
    # explanatory suffix (that belongs only to the suspect form).
    Set-CheckScope "fixture/repo`n[ERROR] forged"
    $scoped = Format-CheckScoped 'msg'
    Assert-True (-not ($scoped -match "`n")) 'Set-CheckScope: still sanitized after delegating to the helper'
    Assert-True (-not ($scoped -match 'sanitized')) 'Set-CheckScope: the label gets no explanatory suffix'
    Set-CheckScope

    Write-Host "Format-SuspectToken -- when the value IS the complaint" -ForegroundColor Cyan
    # A clean value is reported plainly: no noise on the ordinary path.
    Assert-Equal 'Bad_Name@m' (Format-SuspectToken -Value 'Bad_Name@m') 'an invalid-but-printable id is shown as-is (it fails the SLUG guard, not this one)'
    # A value that had to be changed must SAY so -- otherwise an "invalid plugin id" error shows a
    # plausible id and hides the characters that made it invalid, defeating its own message.
    $susp = Format-SuspectToken -Value "evil`nid@m"
    Assert-True ($susp -match 'shown sanitized') 'a changed value is flagged as sanitized'
    Assert-True (-not ($susp -match "`n")) 'and it is still newline-free'
    # A value with nothing printable left cannot be shown at all -- say that, with the raw length, rather
    # than print empty quotes that read like "the id is blank".
    $none = Format-SuspectToken -Value "$([char]0)$([char]1)$([char]2)"
    Assert-True ($none -match '<unprintable>') 'a wholly unprintable value says so instead of showing empty quotes'
    Assert-True ($none -match '3 character') 'and it names the raw length, the only fact left about it'

    # --- Get-SettingsChainPaths / Get-EnabledPlugins (inbound #294) -------------------------------
    #     The shared answer to "which plugins are enabled here", after three call sites each read
    #     .claude/settings.json alone and produced a false green, a silent skip and a false alarm from
    #     the identical blind spot. Direct assertions, because the ORDER and the PRECEDENCE are the
    #     substance: get either wrong and the callers are wrong in ways their own tests cannot see.
    Write-Host "Get-EnabledPlugins -- the settings chain" -ForegroundColor Cyan
    $chainRoot = Join-Path $Fixture 'chain'
    $userHome  = Join-Path $Fixture 'userhome'
    New-Item -ItemType Directory -Path (Join-Path $chainRoot '.claude') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $userHome '.claude') -Force | Out-Null
    $projFile  = Join-Path $chainRoot '.claude\settings.json'
    $localFile = Join-Path $chainRoot '.claude\settings.local.json'
    $userFile  = Join-Path $userHome  '.claude\settings.json'

    # Lowest precedence FIRST, so a caller that walks the list and overwrites gets local > project > user
    # for free. This order IS the contract -- reversing it silently inverts every precedence below.
    $chain = @(Get-SettingsChainPaths -RepoRoot $chainRoot -UserHomeOverride $userHome)
    Assert-Equal 3 $chain.Count 'chain: three layers (user, project, local)'
    # RepoOwned is the predicate behind RepoEnabledIds, and it lives on the chain rather than at the call
    # site so that no caller has to match a LABEL -- a label is prose and may be reworded (issue #1138).
    Assert-True (-not $chain[0].RepoOwned) 'chain: the user layer is NOT repo-owned'
    Assert-True $chain[1].RepoOwned 'chain: .claude/settings.json is'
    Assert-True $chain[2].RepoOwned 'chain: and so is .claude/settings.local.json -- BOTH repo layers count'
    Assert-Equal $userFile  $chain[0].Path 'chain: the user layer comes first (lowest precedence)'
    Assert-Equal $projFile  $chain[1].Path 'chain: .claude/settings.json second'
    Assert-Equal $localFile $chain[2].Path 'chain: .claude/settings.local.json last (highest precedence)'

    # Nothing anywhere: no file, no key -- distinguishable from "a key that enables nothing", because the
    # two mean different things to a reader (never configured vs. deliberately empty).
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 0 $e.Ids.Count 'no files: nothing enabled'
    Assert-True (-not $e.AnyFileExists) 'no files: AnyFileExists is false'
    Assert-True (-not $e.AnyKeyFound) 'no files: AnyKeyFound is false'
    Assert-Equal 'no settings file' $e.Summary 'no files: Summary says so instead of naming paths that do not exist'

    # THE #294 CASE: the enable lives only in settings.local.json, the file the plugin's own settings
    # proposal points the reader at and all three call sites used to ignore.
    [System.IO.File]::WriteAllText($localFile, '{ "enabledPlugins": { "team-alpha@claude-code-specialists": true } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 'team-alpha@claude-code-specialists' ($e.Ids -join ',') 'local-only: the enable is seen'
    Assert-Equal '.claude/settings.local.json' $e.LayerById['team-alpha@claude-code-specialists'] 'local-only: the deciding layer is reported'
    Assert-True $e.AnyKeyFound 'local-only: AnyKeyFound is true'

    # Per-key precedence, the deliberate choice documented on the helper: a local 'false' switches off a
    # project 'true' rather than the layers replacing one another wholesale.
    [System.IO.File]::WriteAllText($projFile,  '{ "enabledPlugins": { "team-alpha@claude-code-specialists": true } }')
    [System.IO.File]::WriteAllText($localFile, '{ "enabledPlugins": { "team-alpha@claude-code-specialists": false } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 0 $e.Ids.Count 'precedence: a local false overrides a project true'
    Assert-True $e.AnyKeyFound 'precedence: the key WAS found -- "enables nothing", not "never configured"'
    Assert-Equal '.claude/settings.json and .claude/settings.local.json' $e.Summary 'precedence: Summary names both existing layers'

    # Per-key merge, the other half: a project enable and a local enable of a DIFFERENT plugin both count.
    # Wholesale replacement would drop the project one, which is the failure direction this helper must
    # never take -- losing an enable is how the false green happened.
    [System.IO.File]::WriteAllText($localFile, '{ "enabledPlugins": { "team-lifehub@claude-code-specialists": true } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 'team-alpha@claude-code-specialists,team-lifehub@claude-code-specialists' ($e.Ids -join ',') 'merge: layers combine per plugin id, they do not replace each other'

    # --- RepoEnabledIds: which enables are THIS REPO's (issue #1138) ------------------------------
    #     The gate behind check-roster-sync's [RECORD-SHAPE] count. It rests on a measurement against
    #     Claude Code 2.1.251: 'claude plugin install --scope project' writes the enable into the repo's
    #     own settings in all six shapes tried, and where it CANNOT write it the install fails and leaves
    #     no register record -- so the write is a precondition of the record, not a side effect of it.
    #     Asserted here rather than only through the check, because "which enables are the repo's" is a
    #     question about this helper and every consumer of it inherits the answer.
    #     Both repo layers still carry an enable at this point (project: team-alpha, local: team-lifehub).
    Assert-Equal 'team-alpha@claude-code-specialists,team-lifehub@claude-code-specialists' ($e.RepoEnabledIds -join ',') 'repo-enabled: both REPO layers count -- settings.local.json is the repo''s too, not the machine''s'

    # The case the gate exists for: the enable lives ONLY in the user layer. It is still enabled -- the
    # session really does load that plugin -- but it is not something this repo asked for or can fix from
    # inside itself, which is the whole distinction.
    [System.IO.File]::WriteAllText($userFile,  '{ "enabledPlugins": { "widgets@claude-code-specialists": true } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-True ($e.Ids -contains 'widgets@claude-code-specialists') 'machine-wide: it IS enabled -- the plugin loads'
    Assert-True (-not ($e.RepoEnabledIds -contains 'widgets@claude-code-specialists')) 'machine-wide: but it is not one of THIS repo''s enables'

    # Precedence carries through: a repo layer outranks the user layer, so an id enabled in both decides in
    # the repo's and counts. Getting this backwards would suppress a repo enable that also happens to exist
    # machine-wide -- a false silence rather than a false alarm, which is the direction that must not fail.
    [System.IO.File]::WriteAllText($userFile,  '{ "enabledPlugins": { "team-alpha@claude-code-specialists": true } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-True ($e.RepoEnabledIds -contains 'team-alpha@claude-code-specialists') 'enabled in both: the repo layer decides, so it counts as the repo''s'

    # And it is never larger than Ids: an id switched OFF in a repo layer is not enabled at all, so it must
    # appear in neither list. The predicate may narrow the set; it may not invent a member.
    [System.IO.File]::WriteAllText($projFile,  '{ "enabledPlugins": { "team-alpha@claude-code-specialists": false } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-True (-not ($e.Ids -contains 'team-alpha@claude-code-specialists')) 'repo false: not enabled'
    Assert-True (-not ($e.RepoEnabledIds -contains 'team-alpha@claude-code-specialists')) 'repo false: and therefore not repo-enabled either'
    Assert-Equal 0 (@($e.RepoEnabledIds | Where-Object { $e.Ids -notcontains $_ }).Count) 'repo-enabled is always a SUBSET of Ids'

    # Restore the state the cases below inherit.
    [System.IO.File]::WriteAllText($userFile,  '{ }')
    [System.IO.File]::WriteAllText($projFile,  '{ "enabledPlugins": { "team-alpha@claude-code-specialists": true } }')
    [System.IO.File]::WriteAllText($localFile, '{ "enabledPlugins": { "team-lifehub@claude-code-specialists": true } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome

    # THE ORDINAL SORT, ON A PAIR THAT ACTUALLY DISCRIMINATES. The helper sorts ordinally rather than by
    # culture, and the measurement behind that choice was taken on 'team-alpha@m' vs
    # 'specialists-lifehub@m' -- a prefix pair with punctuation between, where the two collations
    # disagree ('-' is 0x2D, '@' is 0x40, so ordinal puts the hyphen first while en-US does not).
    #
    # Renaming those plugins to team-alpha/team-lifehub took that discrimination away without touching a
    # line of the sort: for the new pair both collations agree, so the assert above would now pass with
    # the ordinal comparison removed. This one is written on a synthetic pair for that reason -- the
    # property must not depend on what the real plugins happen to be called this month.
    [System.IO.File]::WriteAllText($projFile,  '{ "enabledPlugins": { "zeta@m": true, "zeta-two@m": true } }')
    [System.IO.File]::WriteAllText($localFile, '{ }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 'zeta-two@m,zeta@m' ($e.Ids -join ',') 'ordinal sort: the hyphen sorts before the at-sign, whatever the machine culture says'
    # Put the chain back the way this block found it: the scenarios below build on the project layer
    # holding the core team's enable, and a synthetic pair left standing here would fail one of them
    # several screens away from the line that caused it.
    [System.IO.File]::WriteAllText($projFile,  '{ "enabledPlugins": { "team-alpha@claude-code-specialists": true } }')
    [System.IO.File]::WriteAllText($localFile, '{ "enabledPlugins": { "team-lifehub@claude-code-specialists": true } }')

    # The user layer counts, and is overridable per key by the repo -- a plugin enabled machine-wide IS
    # loaded in every session, so excluding this layer would rebuild the same false green one level up.
    Remove-Item -LiteralPath $localFile -Force
    [System.IO.File]::WriteAllText($userFile, '{ "enabledPlugins": { "team-shopify@claude-code-specialists": true } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-True ($e.Ids -contains 'team-shopify@claude-code-specialists') 'user layer: a machine-wide enable counts'
    Assert-Equal 'user ~/.claude/settings.json' $e.LayerById['team-shopify@claude-code-specialists'] 'user layer: named as the deciding layer'

    # A layer that does not parse is REPORTED, never thrown, and never silently turns the answer into
    # "nothing enabled" -- the rest of the chain still counts.
    [System.IO.File]::WriteAllText($localFile, '{ "enabledPlugins": { oops')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal '.claude/settings.local.json' ($e.Unreadable -join ',') 'unparseable layer: reported by label, not thrown'
    Assert-True ($e.Ids -contains 'team-alpha@claude-code-specialists') 'unparseable layer: the readable layers still counted'

    # --- Shapes that are VALID but easy to crash on -----------------------------------------------
    #     Found live, not by reasoning: a settings.json holding exactly '{ }' was reported as "does not
    #     parse". Under Set-StrictMode -Version Latest the usual
    #     '$obj.PSObject.Properties.Name -contains ...' idiom throws on an object with NO properties, and
    #     the catch then relabelled a perfectly good file as corrupt. These three shapes are all ordinary
    #     consumer states, so each must produce an ANSWER and never an Unreadable entry.
    Remove-Item -LiteralPath $userFile -Force
    foreach ($shape in @('{ }', '{ "enabledPlugins": { } }', '{ "enabledPlugins": null }', '{ "permissions": { "allow": [] } }')) {
        [System.IO.File]::WriteAllText($projFile, $shape)
        Remove-Item -LiteralPath $localFile -Force -ErrorAction SilentlyContinue
        $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
        Assert-Equal 0 @($e.Unreadable).Count "valid shape '$shape': not reported as unparseable"
        Assert-Equal 0 $e.Ids.Count "valid shape '$shape': nothing enabled"
        Assert-True $e.AnyFileExists "valid shape '$shape': the file is seen"
    }
    # ... and the key-present cases are still distinguishable from the no-key ones, because the two mean
    # different things to a reader ("deliberately empty" vs "never configured").
    [System.IO.File]::WriteAllText($projFile, '{ "enabledPlugins": { } }')
    Assert-True (Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome).AnyKeyFound 'empty enabledPlugins: AnyKeyFound is true'
    [System.IO.File]::WriteAllText($projFile, '{ }')
    Assert-True (-not (Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome).AnyKeyFound) 'no enabledPlugins key: AnyKeyFound is false'

    # --- KeyIn / KeySummary: WHERE the key lives, not what was looked at (inbound #304) ------------
    #     Summary answers "what did you inspect?" and was used for "where is the key?", so a repo
    #     carrying it in one of three layers had all three named -- and the two a reader opens first were
    #     the two that demonstrably did not have it. The fixture below is life-hub's EXACT measured
    #     shape, because that is the one that produced the wrong sentence: the key in the user layer only,
    #     as an empty object, with both repo-owned layers present and key-less.
    Write-Host "Get-EnabledPlugins -- KeyIn/KeySummary (inbound #304)" -ForegroundColor Cyan
    [System.IO.File]::WriteAllText($userFile,  '{ "enabledPlugins": { } }')
    [System.IO.File]::WriteAllText($projFile,  '{ "permissions": { "allow": [] } }')
    [System.IO.File]::WriteAllText($localFile, '{ "permissions": { "allow": [] } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 3 @($e.Consulted).Count 'life-hub shape: all three layers exist, so all three were consulted'
    Assert-Equal 'user ~/.claude/settings.json' ($e.KeyIn -join ',') 'life-hub shape: KeyIn names ONLY the layer carrying the key'
    Assert-Equal 'user ~/.claude/settings.json' $e.KeySummary 'life-hub shape: KeySummary is that one layer, not all three'
    Assert-True $e.AnyKeyFound 'life-hub shape: the key WAS found (empty object is an answer)'
    # The two must not be confused, and the regression is easiest to spot by asserting they DIFFER here.
    Assert-True ($e.Summary -ne $e.KeySummary) 'life-hub shape: Summary and KeySummary are different sentences'
    Assert-True ($e.Summary -match 'and') 'life-hub shape: Summary still names every consulted layer'

    # Several layers carrying the key -> the joined phrasing, so the fix is not "always print one label".
    [System.IO.File]::WriteAllText($projFile, '{ "enabledPlugins": { } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 'user ~/.claude/settings.json and .claude/settings.json' $e.KeySummary 'two layers with the key: both named, joined with "and"'
    # No layer carries it -> a sentence, never an empty string dangling in a message.
    [System.IO.File]::WriteAllText($userFile, '{ }')
    [System.IO.File]::WriteAllText($projFile, '{ }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 0 @($e.KeyIn).Count 'no layer with the key: KeyIn is empty'
    Assert-Equal 'no settings layer' $e.KeySummary 'no layer with the key: KeySummary is a sentence, not an empty string'

    # --- Format-LabelList: the one place a list of labels becomes prose ---------------------------
    Write-Host "Format-LabelList -- the shared joining" -ForegroundColor Cyan
    Assert-Equal 'nothing' (Format-LabelList -Labels @() -IfEmpty 'nothing') 'empty list: the caller word'
    Assert-Equal 'a' (Format-LabelList -Labels @('a')) 'one label: bare'
    Assert-Equal 'a and b' (Format-LabelList -Labels @('a', 'b')) 'two labels: "and", no comma'
    Assert-Equal 'a, b and c' (Format-LabelList -Labels @('a', 'b', 'c')) 'three labels: commas then "and"'

    # --- Get-JsonField: StrictMode-safe reads over consumer-owned JSON ----------------------------
    Write-Host "Get-JsonField -- absent fields are answers, not crashes" -ForegroundColor Cyan
    $obj = '{ "a": "x", "n": null }' | ConvertFrom-Json
    Assert-Equal 'x' (Get-JsonField $obj 'a') 'present field: read'
    Assert-Equal '' (Get-JsonField $obj 'missing') 'absent field: the default, no throw'
    Assert-Equal 'fb' (Get-JsonField $obj 'missing' 'fb') 'absent field: the caller default'
    Assert-Equal 'fb' (Get-JsonField $obj 'n' 'fb') 'explicit null: treated as absent'
    # The shape that produced the #294 mislabelling: an object with NO properties at all.
    Assert-Equal '' (Get-JsonField ('{ }' | ConvertFrom-Json) 'a') 'empty object: an answer, not a StrictMode crash'
    Assert-Equal '' (Get-JsonField $null 'a') 'null object: an answer'

    # --- Get-InstallRecord / Test-PluginInstalledHere (inbound #302) ------------------------------
    #     The other half of what Claude Code needs. An enable without a record for THIS projectPath loads
    #     nothing, and every check reported the full specialist surface anyway. Asserted directly, because
    #     the two rules that matter here -- EVERY matching record (#240) and "a pathless record does not
    #     exclude this path" -- are both invisible to the callers' own tests.
    Write-Host "Get-InstallRecord -- the install administration (inbound #302)" -ForegroundColor Cyan
    $adminHome = Join-Path $Fixture 'adminhome'
    $repoA = Join-Path $Fixture 'repoA'
    $repoB = Join-Path $Fixture 'repoB'
    New-Item -ItemType Directory -Path (Join-Path $adminHome '.claude\plugins') -Force | Out-Null
    New-Item -ItemType Directory -Path $repoA -Force | Out-Null
    New-Item -ItemType Directory -Path $repoB -Force | Out-Null
    $adminFile = Join-Path $adminHome '.claude\plugins\installed_plugins.json'

    # No administration at all: "could not look", NOT "not installed". The predicate must stay permissive
    # here -- absence of the authority is not evidence of absence, and a check that fires its loudest new
    # signal where it knows least is the cry-wolf failure #294 spent a release removing.
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    Assert-True (-not $r.Exists) 'no administration: Exists is false'
    Assert-True (-not $r.AnyRecord) 'no administration: AnyRecord is false'
    Assert-True (Test-PluginInstalledHere -InstallRecord $r -PluginId 'team-alpha@m') 'no administration: the predicate does NOT claim "not installed"'

    # A record for THIS path, and one for another path. Only the first counts as installed here -- this is
    # the whole measurement behind #302 and #301.
    $adminJson = @"
{
  "version": 2,
  "plugins": {
    "team-alpha@m": [
      { "scope": "project", "projectPath": "$($repoA -replace '\\', '\\')", "version": "3.0.6" }
    ],
    "other@m": [
      { "scope": "project", "projectPath": "$($repoB -replace '\\', '\\')", "version": "3.0.6" }
    ]
  }
}
"@
    [System.IO.File]::WriteAllText($adminFile, $adminJson)
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    Assert-True $r.Exists 'administration present: Exists is true'
    Assert-True $r.Readable 'administration present: Readable is true'
    Assert-Equal 'team-alpha@m' ($r.Ids -join ',') 'path match: only the plugin recorded for THIS path'
    Assert-Equal '3.0.6' $r.RecordsById['team-alpha@m'][0].Version 'path match: the record is projected onto a fixed shape'
    Assert-Equal 'project' $r.RecordsById['team-alpha@m'][0].Scope 'path match: Scope travels along'
    Assert-True (Test-PluginInstalledHere -InstallRecord $r -PluginId 'team-alpha@m') 'path match: installed here'
    Assert-True (-not (Test-PluginInstalledHere -InstallRecord $r -PluginId 'other@m')) 'THE #302 CASE: a record for another path is NOT installed here'
    Assert-True (-not (Test-PluginInstalledHere -InstallRecord $r -PluginId 'absent@m')) 'no record at all: not installed here'
    Assert-True $r.AnyRecord 'AnyRecord distinguishes "no installs administered" from "none for this repo"'

    # Case- and trailing-separator-insensitive: two spellings of one directory are not two answers (#240).
    $r = Get-InstallRecord -RepoRoot ($repoA.ToUpper() + '\') -UserHomeOverride $adminHome
    Assert-True (Test-PluginInstalledHere -InstallRecord $r -PluginId 'team-alpha@m') 'a different spelling of the same path still matches'

    # EVERY matching record, never just the first (#240): several disagreeing records is its own answer,
    # and the caller can only report that honestly if it receives all of them.
    $dupJson = @"
{ "plugins": { "team-alpha@m": [
    { "scope": "project", "projectPath": "$($repoA -replace '\\', '\\')", "version": "3.0.6" },
    { "scope": "project", "projectPath": "$($repoA -replace '\\', '\\')", "version": "2.11.0" }
] } }
"@
    [System.IO.File]::WriteAllText($adminFile, $dupJson)
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    Assert-Equal 2 @($r.RecordsById['team-alpha@m']).Count 'duplicate records: BOTH returned, not the first one'
    Assert-Equal '2.11.0,3.0.6' ((@($r.RecordsById['team-alpha@m']) | ForEach-Object { $_.Version } | Sort-Object) -join ',') 'duplicate records: the disagreement is visible to the caller'

    # A PATHLESS record covers every repo, so it must never produce a "not installed here" claim. Erring
    # this way can only suppress a warning, never invent one.
    [System.IO.File]::WriteAllText($adminFile, '{ "plugins": { "userwide@m": [ { "scope": "user", "version": "3.0.6" } ] } }')
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    Assert-Equal 0 $r.Ids.Count 'pathless record: not counted as a path match'
    Assert-Equal 'userwide@m' ($r.PathlessIds -join ',') 'pathless record: kept separately rather than dropped'
    Assert-True (Test-PluginInstalledHere -InstallRecord $r -PluginId 'userwide@m') 'pathless record: does NOT exclude this path'

    # A record naming a directory that no longer exists cannot be about this repo -- and must not crash on
    # a $null from Resolve-Path under StrictMode. This is the deleted-throwaway-folder case from #301.
    [System.IO.File]::WriteAllText($adminFile, "{ `"plugins`": { `"gone@m`": [ { `"scope`": `"project`", `"projectPath`": `"$($repoA -replace '\\', '\\')\\does-not-exist`", `"version`": `"3.0.6`" } ] } }")
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    Assert-True $r.Readable 'vanished projectPath: still readable, no crash'
    Assert-True (-not (Test-PluginInstalledHere -InstallRecord $r -PluginId 'gone@m')) 'vanished projectPath: not installed here'

    # An administration that does not parse is REPORTED, never thrown -- and the predicate stays permissive,
    # because an authority the check could not read is not evidence about the repo.
    [System.IO.File]::WriteAllText($adminFile, '{ "plugins": { oops')
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    Assert-True $r.Exists 'unparseable administration: Exists is true'
    Assert-True (-not $r.Readable) 'unparseable administration: Readable is false'
    Assert-True ($r.Error -ne '') 'unparseable administration: the reason is carried, not swallowed'
    Assert-True (Test-PluginInstalledHere -InstallRecord $r -PluginId 'team-alpha@m') 'unparseable administration: the predicate does not claim "not installed"'

    # Shapes that are valid but easy to crash on, same class as the settings-chain block above.
    foreach ($shape in @('{ }', '{ "plugins": { } }', '{ "plugins": null }', '{ "plugins": { "p@m": [] } }')) {
        [System.IO.File]::WriteAllText($adminFile, $shape)
        $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
        Assert-True $r.Readable "valid administration shape '$shape': parsed, not reported as corrupt"
        Assert-Equal 0 $r.Ids.Count "valid administration shape '$shape': nothing matched"
    }
    # A record missing 'version'/'scope' entirely is an ordinary state (a newer or older CLI): it must
    # still match on path and simply carry empty fields.
    [System.IO.File]::WriteAllText($adminFile, "{ `"plugins`": { `"bare@m`": [ { `"projectPath`": `"$($repoA -replace '\\', '\\')`" } ] } }")
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    Assert-True (Test-PluginInstalledHere -InstallRecord $r -PluginId 'bare@m') 'record without scope/version: still matches on path'
    Assert-Equal '' $r.RecordsById['bare@m'][0].Version 'record without version: an empty field, not a crash'

    # --- Get-RecordShape (inbound #314/#315) ------------------------------------------------------
    # The second predicate over the same records, and the reason it is separate is asserted here rather
    # than only argued in a comment: Test-PluginInstalledHere must stay PERMISSIVE (a false
    # [NOT-INSTALLED-HERE] is the cry-wolf failure #294 removed), while this one is STRICT about a shape
    # -- exactly one record, scoped 'project'. The pairs below therefore assert both predicates on the
    # same fixture: "installed here" stays true in every case where this one reports a finding.
    Write-Host "Get-RecordShape -- one record, scoped project (inbound #314/#315)" -ForegroundColor Cyan
    $pathJson = ($repoA -replace '\\', '\\')

    # The assumed shape: silent.
    [System.IO.File]::WriteAllText($adminFile, "{ `"plugins`": { `"p@m`": [ { `"scope`": `"project`", `"projectPath`": `"$pathJson`" } ] } }")
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    Assert-True ($null -eq (Get-RecordShape -InstallRecord $r -PluginId 'p@m')) 'one project record: no finding'

    # THE #314 CASE: what a session start leaves behind. Note the pairing -- the plugin IS installed here,
    # so only this predicate may speak. If both fired, a reader would be told to run the install that
    # produces the #315 duplicate.
    [System.IO.File]::WriteAllText($adminFile, "{ `"plugins`": { `"p@m`": [ { `"scope`": `"local`", `"projectPath`": `"$pathJson`" } ] } }")
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    $shape = Get-RecordShape -InstallRecord $r -PluginId 'p@m'
    Assert-True ($null -ne $shape) 'local-scoped record: a finding'
    Assert-True ($shape.Shapes -contains 'no-project-scope') 'local-scoped record: named as the no-project-scope shape'
    Assert-True (-not ($shape.Shapes -contains 'duplicate')) 'local-scoped record: and NOT as a duplicate -- there is only one'
    Assert-True (-not $shape.HasProject) 'local-scoped record: HasProject is false'
    Assert-Equal 1 $shape.Count 'local-scoped record: the count is stated'
    Assert-True (Test-PluginInstalledHere -InstallRecord $r -PluginId 'p@m') 'local-scoped record: STILL installed here -- the two predicates disagree on purpose'

    # THE #315 CASE: the repair install's duplicate. A project record is present, so only the duplicate
    # half may fire -- the two shapes have different remedies and must not be conflated.
    [System.IO.File]::WriteAllText($adminFile, "{ `"plugins`": { `"p@m`": [ { `"scope`": `"project`", `"projectPath`": `"$pathJson`" }, { `"scope`": `"local`", `"projectPath`": `"$pathJson`" } ] } }")
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    $shape = Get-RecordShape -InstallRecord $r -PluginId 'p@m'
    Assert-True ($shape.Shapes -contains 'duplicate') 'two records: named as a duplicate'
    Assert-True (-not ($shape.Shapes -contains 'no-project-scope')) 'two records incl. project: the no-project-scope half does NOT fire'
    Assert-True $shape.HasProject 'two records incl. project: HasProject is true'
    Assert-Equal 2 $shape.Count 'two records: the count is what a reader needs'

    # Both shapes at once: two records, neither scoped project.
    [System.IO.File]::WriteAllText($adminFile, "{ `"plugins`": { `"p@m`": [ { `"scope`": `"local`", `"projectPath`": `"$pathJson`" }, { `"scope`": `"local`", `"projectPath`": `"$pathJson`" } ] } }")
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    $shape = Get-RecordShape -InstallRecord $r -PluginId 'p@m'
    Assert-True ($shape.Shapes -contains 'duplicate') 'two local records: duplicate'
    Assert-True ($shape.Shapes -contains 'no-project-scope') 'two local records: AND no-project-scope -- both shapes can hold at once'
    Assert-Equal 1 $shape.Scopes.Count 'two local records: the scope list is deduplicated'

    # THE #323 CASE: a 'project' record demoted to a pathless one. THIS ASSERTION IS THE REVERSE OF WHAT IT
    # USED TO BE, deliberately. It used to read "pathless record: not this predicate -- it judges only
    # records scoped to THIS path", pinning the silence on the grounds that a pathless record is step 0b's
    # scopeless-install warning. Round v9 measured the case the old reasoning had no room for: a session
    # start REWRITES a correct 'project' record into a pathless 'user' one, with no command run, so the
    # owner cannot be an install warning. The repo is then absent from its own verification query while the
    # plugin loads, and neither marker said anything -- each correct by its own rule. It is this predicate's
    # subject now.
    [System.IO.File]::WriteAllText($adminFile, '{ "plugins": { "p@m": [ { "scope": "user" } ] } }')
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    $shape = Get-RecordShape -InstallRecord $r -PluginId 'p@m'
    Assert-True ($null -ne $shape) 'pathless record: a finding since #323 -- the demotion is reported'
    Assert-True ($shape.Shapes -contains 'pathless-only') 'pathless record: named as the pathless-only shape'
    Assert-True (-not ($shape.Shapes -contains 'no-project-scope')) 'pathless record: and NOT as no-project-scope -- the remedies differ, so the shapes must not be conflated'
    Assert-True (-not ($shape.Shapes -contains 'duplicate')) 'pathless record: nor as a duplicate'
    Assert-Equal 0 $shape.Count 'pathless record: Count is 0 -- no records for this path IS the finding'
    Assert-Equal 'user' ($shape.Scopes -join ',') 'pathless record: the pathless scope is reported, so the line can name what it found'
    Assert-True (-not $shape.HasProject) 'pathless record: HasProject is false'
    # The pairing that matters: the permissive predicate must NOT change with it. A pathless record really
    # does load here, so [NOT-INSTALLED-HERE] would be a false alarm -- which is why this shape needed a
    # second reporter rather than a stricter first one.
    Assert-True (Test-PluginInstalledHere -InstallRecord $r -PluginId 'p@m') 'pathless record: STILL installed here -- the two predicates disagree on purpose'
    # No record of ANY kind is [NOT-INSTALLED-HERE]'s state, and stays out of this predicate. This is the
    # boundary that keeps the two markers from describing one plugin twice.
    Assert-True ($null -eq (Get-RecordShape -InstallRecord $r -PluginId 'absent@m')) 'no record at all: not this predicate -- no evidence is the other marker''s subject'
    Assert-True (-not (Test-PluginInstalledHere -InstallRecord $r -PluginId 'absent@m')) 'no record at all: and NOT installed here -- so exactly one marker speaks'
    # And an unstated scope is a gap in the administration, not a wrong answer. Same direction of error as
    # Test-PluginInstalledHere: this may suppress a finding, never invent one.
    [System.IO.File]::WriteAllText($adminFile, "{ `"plugins`": { `"p@m`": [ { `"projectPath`": `"$pathJson`" } ] } }")
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    Assert-True ($null -eq (Get-RecordShape -InstallRecord $r -PluginId 'p@m')) 'record with no scope field: silent, not reported as a mismatch'
    # An unreadable authority: nothing may be concluded from it, in either predicate.
    [System.IO.File]::WriteAllText($adminFile, '{ "plugins": { oops')
    $r = Get-InstallRecord -RepoRoot $repoA -UserHomeOverride $adminHome
    Assert-True ($null -eq (Get-RecordShape -InstallRecord $r -PluginId 'p@m')) 'unparseable administration: no shape finding invented'

    # --- Resolve-PluginDir: the record decides which version, the cache scan is the fallback ----------
    #     A shared cache holds every version any consumer on the machine pulled, so "highest present" and
    #     "the one THIS repo loads" are different questions the moment there is a second consumer.
    #     Measured August 4, 2026: cache at 3.1.2/3.2.0/3.3.0, this repo's record pinned 3.2.0, and the
    #     roster check reported on 3.3.0's agent set.
    #
    #     $env:USERPROFILE is redirected rather than a -UserHomeOverride passed: Get-InstallRecord
    #     documents that flag as pinning the settings chain, and states its callers do not forward theirs.
    #     Resolve-PluginDir therefore offers no passthrough, and this is the sanctioned way to point it at
    #     a throwaway home -- the same route the connector version test uses.
    Write-Host "Resolve-PluginDir -- install record first, cache scan as fallback" -ForegroundColor Cyan
    $rpCache = Join-Path $Fixture 'rpcache'
    $rpRepo  = Join-Path $Fixture 'rprepo'
    $rpHome  = Join-Path $Fixture 'rphome'
    New-Item -ItemType Directory -Path $rpRepo -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $rpHome '.claude\plugins') -Force | Out-Null
    foreach ($v in @('1.9.0', '1.10.0')) {
        New-Item -ItemType Directory -Path (Join-Path $rpCache "m\team-alpha\$v\agents") -Force | Out-Null
    }
    # A version with NO agents/ dir, to prove the scan's existing filter still applies underneath.
    New-Item -ItemType Directory -Path (Join-Path $rpCache 'm\team-alpha\2.0.0') -Force | Out-Null
    $rpAdmin = Join-Path $rpHome '.claude\plugins\installed_plugins.json'
    $rpRepoJson = (Resolve-Path -LiteralPath $rpRepo).Path.Replace('\', '\\')
    $pinnedPath = (Join-Path $rpCache 'm\team-alpha\1.9.0')
    $pinnedJson = $pinnedPath.Replace('\', '\\')

    $savedProfile = $env:USERPROFILE
    try {
        $env:USERPROFILE = $rpHome

        # 1. No -RepoRoot: unchanged behaviour, and 2.0.0 is skipped for lacking agents/.
        $d = Resolve-PluginDir -Name 'team-alpha' -Marketplace 'm' -CacheRoot $rpCache
        Assert-Equal '1.10.0' (Split-Path $d -Leaf) 'no RepoRoot: the semantically highest version with agents/ (1.10.0 over 1.9.0, 2.0.0 skipped)'

        # 2. A record pinning the OLDER version wins over the higher one in the cache.
        [System.IO.File]::WriteAllText($rpAdmin, "{ `"plugins`": { `"team-alpha@m`": [ { `"scope`": `"project`", `"projectPath`": `"$rpRepoJson`", `"installPath`": `"$pinnedJson`", `"version`": `"1.9.0`" } ] } }")
        $d = Resolve-PluginDir -Name 'team-alpha' -Marketplace 'm' -CacheRoot $rpCache -RepoRoot $rpRepo
        Assert-Equal '1.9.0' (Split-Path $d -Leaf) 'record pins 1.9.0: the record wins over the higher version in the cache'

        # 3. A record for ANOTHER repo must not steer this one.
        $d = Resolve-PluginDir -Name 'team-alpha' -Marketplace 'm' -CacheRoot $rpCache -RepoRoot $repoB
        Assert-Equal '1.10.0' (Split-Path $d -Leaf) "another repo's record does not apply -- back to the cache scan"

        # 4. A record whose installPath is GONE falls through rather than blinding the check.
        $goneJson = (Join-Path $rpCache 'm\team-alpha\9.9.9').Replace('\', '\\')
        [System.IO.File]::WriteAllText($rpAdmin, "{ `"plugins`": { `"team-alpha@m`": [ { `"scope`": `"project`", `"projectPath`": `"$rpRepoJson`", `"installPath`": `"$goneJson`", `"version`": `"9.9.9`" } ] } }")
        $d = Resolve-PluginDir -Name 'team-alpha' -Marketplace 'm' -CacheRoot $rpCache -RepoRoot $rpRepo
        Assert-Equal '1.10.0' (Split-Path $d -Leaf) 'stale record (installPath gone): falls back to the cache scan instead of returning nothing'

        # 5. A recorded path that exists but has no agents/ dir is not a plugin dir either.
        $noAgentsJson = (Join-Path $rpCache 'm\team-alpha\2.0.0').Replace('\', '\\')
        [System.IO.File]::WriteAllText($rpAdmin, "{ `"plugins`": { `"team-alpha@m`": [ { `"scope`": `"project`", `"projectPath`": `"$rpRepoJson`", `"installPath`": `"$noAgentsJson`", `"version`": `"2.0.0`" } ] } }")
        $d = Resolve-PluginDir -Name 'team-alpha' -Marketplace 'm' -CacheRoot $rpCache -RepoRoot $rpRepo
        Assert-Equal '1.10.0' (Split-Path $d -Leaf) 'recorded path without agents/: falls through, same rule the cache scan applies'

        # 6. An unreadable administration must not break resolution -- Get-InstallRecord reports, and the
        #    scan still answers. This is what makes step 2 a refinement rather than a gate.
        [System.IO.File]::WriteAllText($rpAdmin, '{ "plugins": { oops')
        $d = Resolve-PluginDir -Name 'team-alpha' -Marketplace 'm' -CacheRoot $rpCache -RepoRoot $rpRepo
        Assert-Equal '1.10.0' (Split-Path $d -Leaf) 'unreadable administration: the cache scan still answers, no throw'
    }
    finally {
        $env:USERPROFILE = $savedProfile
    }
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
