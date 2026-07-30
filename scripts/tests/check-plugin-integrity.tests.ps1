<#
.SYNOPSIS
    Regression tests for scripts/lint/check-plugin-integrity.ps1:
      - check 4 (dead-link/anchor scan): guards that root CONTRIBUTING.md and
        claude-code-plugins/claude-specialists/connectors/README.md stay part of the scanned file set.
      - check 10 (marked "all skills" enumerations vs. the canonical skillset): the opt-in
        <!-- skills:all --> ... <!-- /skills:all --> span mechanics, its scope-limiting (no generic
        prose scan), the exact-depth binding of the canonical skillset, fence-masking of literal
        marker examples, and the symmetric orphan-END sweep (a lone or duplicate END is a hard error
        too, not just a lone BEGIN).

.DESCRIPTION
    Check 4 context: both files used to be silently SKIPPED by check 4's file list -- a coverage gap
    nobody noticed until it was found by inspection and fixed (CONTRIBUTING.md alongside the
    original set; the connectors README as a follow-up spotted by Edith, #159 follow-up). The risk
    this test guards against is not "does the link scanner work" (that engine is exercised implicitly
    by every other suite's lint-gate smoke check, e.g. agent-shared.tests.ps1 /
    bootstrap-drift.tests.ps1) but the narrower, easy-to-silently-regress thing: if someone later
    refactors the $linkFiles list in check-plugin-integrity.ps1 and drops one of these two files
    again, that must fail loudly here instead of the gap reappearing unnoticed.

    Mechanism (grounded in the REAL script, not a re-implementation of its logic -- same idea as
    script-contract.tests.ps1's "copy the real dependency" pattern): a throwaway fixture repo root
    gets a copy of the real check-plugin-integrity.ps1 plus its two dot-sourced dependencies
    (agent-shared-lib.ps1, shared-scripts-lib.ps1) at the same relative paths, so the script runs
    for real as a child process against the fixture. The fixture is deliberately otherwise empty
    (no marketplace.json, no plugins, no agent defs) -- checks 1/2/3/3b/3c/6/7 simply find nothing to
    check, and check 8 always reports its 8 shared-script pairs as "missing" against this minimal
    fixture (expected noise, asserted on nowhere below). The fixture additionally carries a small
    canonical skillset for check 10: claude-code-plugins/claude-specialists/specialists/skills/
    skill-alpha/SKILL.md and .../skill-beta/SKILL.md (2 real skills), plus a DEPTH DECOY
    skills/skill-alpha/references/SKILL.md (a SKILL.md one level too deep, which must NOT be picked
    up as a 3rd canonical skill). Only check 4's and check 10's per-file findings are asserted on, so
    the other checks' expected noise does not affect the outcome.

    Check 4, Scenario A: a deliberately dead relative link is placed inside BOTH CONTRIBUTING.md and
    the connectors README, plus a THIRD markdown file at the fixture root that is NOT in check 4's
    file list (a decoy, proving the scan is scope-limited by design, not "catches everything by
    accident"). Asserts: both target files' dead links are reported, the decoy's is not.
    Check 4, Scenario B: the dead links in CONTRIBUTING.md / the connectors README are fixed
    (removed) -- asserts the two specific findings disappear, proving the failure in scenario A was
    genuinely driven by that file's content (not a false positive / accidental match).

    Check 10, scenarios 1-8 (all reuse CONTRIBUTING.md as the varying doc; the connectors README is
    left marker-free throughout, per check 4 Scenario B, so every finding below is attributable to
    CONTRIBUTING.md alone):
      1. A complete marked span passes; the printed canonical-skill count (2) doubles as proof the
         depth decoy was not counted as a 3rd skill.
      2. A span missing a canonical name fails, naming the missing skill.
      3. A span naming something that is not a skill fails, naming the unknown entry.
      4. An unpaired BEGIN marker (no matching END) is a hard error.
      5. TWO unpaired BEGIN markers in the SAME file are BOTH reported -- the regression guard on a
         deliberate design choice: an earlier version used 'break' on the first unpaired marker and
         silently abandoned the rest of the file; the fix keeps scanning instead.
      6. An UNMARKED, deliberately incomplete enumeration is NOT flagged -- the core reason check 10
         is opt-in rather than a generic prose scan (a real doc such as QUICKSTART.md legitimately
         lists only some skills as illustration).
      7. An INLINE span in running prose is unaffected by backtick terms OUTSIDE the span that are
         not skill names (mirrors the real family-README sentence with the *-sessioncheck hook
         names one line above the skill enumeration).
      8. The depth-decoy SKILL.md, if named inside a span, is reported as an unknown skill -- the
         flip side of scenario 1's canonical-count check, proving it was never in the canonical set.
      9. A complete marker EXAMPLE inside a fenced ```-code block reports nothing AND does not count
         in the span total -- proof it is genuinely invisible (Get-FenceMaskedText), not "seen and
         happened to pass".
     10. A fence containing ONLY the BEGIN marker, with no END anywhere else in the file either, does
         NOT raise "has no matching END" -- the exact case that was a hard error before the
         fence-masking fix (the reason for the change).
     11. A REAL span OUTSIDE a fence, in the same file as a fenced example, is still checked normally
         AND its reported line number matches the actual line -- the crux of masking with same-length
         whitespace instead of cutting the fence out (offsets stay valid).
     12. (Deliberate-boundary lock, not a bug guard) a marker written as INLINE code (single
         backticks, not a fence) is NOT masked and IS still scanned as live -- locks in the documented
         trade-off that a real span's own claimed names are themselves single-backtick delimited, so
         masking inline code would erase genuine findings too.
     13. A LONE orphan END, with no BEGIN anywhere in the file, is a hard error with the correct line
         number -- the symmetric counterpart of scenario 4's BEGIN-without-END (Victor's review
         finding: the original check-10 only guarded one direction of the pair).
     14. (The important one) a SECOND END pasted inside an already-open, otherwise real span -- the
         copy-paste mistake that used to go silently GREEN: the span closed early at the first END,
         the rest of the enumeration became unchecked prose, and the surplus END vanished. Asserts
         BOTH halves at once: the truncated span reports its now-missing name (proof it closed
         early), and the surplus END is reported separately, on its own line.
     15. An END inside a code fence is invisible too, exactly like a fenced BEGIN (scenarios 9/10) --
         proves the masking is symmetric for both sentinels.

    Deliberately NOT added: a dedicated "two separate, fully valid spans in one file -> neither's own
    END is misreported as an orphan" scenario. Judgment call, not an oversight: scenario 1 (and 7, 11)
    already assert "no [skill-list] finding" for a normal, single complete span -- since the
    no-finding pattern below also covers "has no matching", a regression that made the sweep
    mis-flag a span's own legitimate END would already fail those asserts. Scenario 14 additionally
    proves the sweep can tell a consumed END apart from an unconsumed one *within the same file*, on
    a `HashSet[int]` of offsets (structurally multi-entry-safe, not a single scalar it could
    overwrite). Combined, that already exercises both directions the symmetry sweep needs to get
    right; a scenario with two independent valid pairs would exercise the same logic again without
    adding a new failure mode.

    Test gap (honest): this does not re-exercise the anchor-slug logic (GitHub heading-slug rules)
    or the full scan engine end-to-end -- that is already covered elsewhere (Get-HeadingSlugs is
    exercised implicitly by the repo-wide lint-gate smoke checks in agent-shared.tests.ps1 and
    bootstrap-drift.tests.ps1). This suite narrowly guards file-set COVERAGE for check 4's two files
    and the specific check 10 behaviors listed above.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/check-plugin-integrity.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$IntegritySrc      = Join-Path $RepoRoot 'scripts\lint\check-plugin-integrity.ps1'
$AgentSharedLibSrc = Join-Path $RepoRoot 'scripts\lib\agent-shared-lib.ps1'
$SharedScriptsLibSrc = Join-Path $RepoRoot 'scripts\lib\shared-scripts-lib.ps1'
# Third dot-sourced dependency since #221: check-report-lib.ps1, for the non-counting Write-Coverage
# line every category closes with. Copied like the other two, so the fixture runs the REAL script.
$CheckReportLibSrc = Join-Path $RepoRoot 'scripts\lib\check-report-lib.ps1'
$Fixture = Join-Path ([System.IO.Path]::GetTempPath()) ("check-plugin-integrity-test-$PID")

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

function Invoke-Integrity {
    param([string]$FixtureRoot)
    $scriptPath = Join-Path $FixtureRoot 'scripts\lint\check-plugin-integrity.ps1'
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath 2>&1
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
$deadLink = './this-file-does-not-exist-xyz.md'

try {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path (Join-Path $Fixture 'scripts\lint') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Fixture 'scripts\lib') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Fixture 'claude-code-plugins\claude-specialists\connectors') -Force | Out-Null
    # check 10 fixture: two canonical skills (skill-alpha, skill-beta) plus a DEPTH DECOY -- a
    # SKILL.md one level deeper (skills/<name>/references/SKILL.md) that must NOT be picked up as a
    # third canonical skill, exercising the exact-depth binding of check 10's canonical-skillset scan.
    New-Item -ItemType Directory -Path (Join-Path $Fixture 'claude-code-plugins\claude-specialists\specialists\skills\skill-alpha\references') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Fixture 'claude-code-plugins\claude-specialists\specialists\skills\skill-beta') -Force | Out-Null

    Copy-Item -Path $IntegritySrc -Destination (Join-Path $Fixture 'scripts\lint\check-plugin-integrity.ps1') -Force
    Copy-Item -Path $AgentSharedLibSrc -Destination (Join-Path $Fixture 'scripts\lib\agent-shared-lib.ps1') -Force
    Copy-Item -Path $SharedScriptsLibSrc -Destination (Join-Path $Fixture 'scripts\lib\shared-scripts-lib.ps1') -Force
    Copy-Item -Path $CheckReportLibSrc -Destination (Join-Path $Fixture 'scripts\lib\check-report-lib.ps1') -Force

    $skillAlphaMd = "---`nname: skill-alpha`ndescription: Fixture skill alpha.`n---`n`n# Skill Alpha`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'claude-code-plugins\claude-specialists\specialists\skills\skill-alpha\SKILL.md'), $skillAlphaMd, $Utf8NoBom)
    $skillBetaMd = "---`nname: skill-beta`ndescription: Fixture skill beta.`n---`n`n# Skill Beta`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'claude-code-plugins\claude-specialists\specialists\skills\skill-beta\SKILL.md'), $skillBetaMd, $Utf8NoBom)
    # The depth decoy claims its own name (skill-deep-decoy) in frontmatter -- if check 10 ever
    # regressed to a looser depth match, that name would silently become a 3rd canonical skill.
    $skillDeepDecoyMd = "---`nname: skill-deep-decoy`ndescription: Depth decoy -- must not count as a canonical skill.`n---`n`n# Skill Deep Decoy`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'claude-code-plugins\claude-specialists\specialists\skills\skill-alpha\references\SKILL.md'), $skillDeepDecoyMd, $Utf8NoBom)

    # --- Scenario A: dead links in the two target files + a decoy outside the scan set --------------
    Write-Host "check 4 coverage -- CONTRIBUTING.md + connectors README are IN the scan set" -ForegroundColor Cyan
    $contributingBroken = "# Contributing`n`nSee [nope]($deadLink) for details.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), $contributingBroken, $Utf8NoBom)
    $connectorsBroken = "# Connectors`n`nSee [nope]($deadLink) for details.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'claude-code-plugins\claude-specialists\connectors\README.md'), $connectorsBroken, $Utf8NoBom)
    # Decoy: same dead link, but in a file that check 4 does NOT scan -- proves the two hits below
    # are due to CONTRIBUTING.md / the connectors README specifically being in the file list, not
    # some accidental blanket scan of every .md file in the fixture.
    $decoyBroken = "# Decoy`n`nSee [nope]($deadLink) for details.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'NOTES.md'), $decoyBroken, $Utf8NoBom)

    $a = Invoke-Integrity -FixtureRoot $Fixture
    Assert-Equal 1 $a.Code 'scenario A: exit 1 (findings present)'
    Assert-True ($a.Out -match [regex]::Escape('.\CONTRIBUTING.md') -and $a.Out -match '\[link\]') 'CONTRIBUTING.md dead link is reported'
    Assert-True ($a.Out -match [regex]::Escape('.\claude-code-plugins\claude-specialists\connectors\README.md')) 'connectors README dead link is reported'
    Assert-True (-not ($a.Out -match [regex]::Escape('NOTES.md'))) 'decoy NOTES.md (outside the scan set) is NOT reported -- proves the scan is scope-limited, not accidental'

    # --- Scenario B: fix both dead links -- the two specific findings disappear ----------------------
    Write-Host "check 4 coverage -- fixing the dead links removes exactly those findings" -ForegroundColor Cyan
    $contributingFixed = "# Contributing`n`nNothing to link to here.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), $contributingFixed, $Utf8NoBom)
    $connectorsFixed = "# Connectors`n`nNothing to link to here.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'claude-code-plugins\claude-specialists\connectors\README.md'), $connectorsFixed, $Utf8NoBom)

    $b = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($b.Out -match [regex]::Escape('.\CONTRIBUTING.md') + '.*dead link')) 'CONTRIBUTING.md dead-link finding is gone once fixed'
    Assert-True (-not ($b.Out -match [regex]::Escape('.\claude-code-plugins\claude-specialists\connectors\README.md') + '.*dead link')) 'connectors README dead-link finding is gone once fixed'

    # === check 10: marked "all skills" enumerations vs. the canonical skillset ==========================
    # From here on, only CONTRIBUTING.md's content is varied per scenario. The connectors README is
    # left exactly as fixed by Scenario B above (marker-free), so it never contributes a
    # <!-- skills:all --> span of its own -- keeping every assertion below attributable to
    # CONTRIBUTING.md alone.
    #
    # NOTE: the "[skill-list]" tag prefixes BOTH the error lines and the informational
    # "checked N span(s) against M canonical skill(s)" pass-line -- so "no finding" assertions must
    # match on an actual error phrase, not on the bare "[skill-list]" tag (which is always present
    # once at least one span exists).
    $SkillListFindingPattern = '\[skill-list\].*(is missing:|not a known skill:|has no matching)'

    # --- Scenario 1: a complete marked span passes. The canonical-skill count printed in the info
    # line doubles as proof that the depth-decoy SKILL.md is NOT counted as a 3rd canonical skill --
    Write-Host "check 10 -- a complete <!-- skills:all --> span passes" -ForegroundColor Cyan
    $s1Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '- `skill-beta`'
        '<!-- /skills:all -->'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s1Lines -join "`n") + "`n"), $Utf8NoBom)

    $r1 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r1.Out -match $SkillListFindingPattern)) 'scenario 1: a complete span reports no [skill-list] finding'
    Assert-True ($r1.Out -match [regex]::Escape('checked 1 <!-- skills:all --> span(s) against 2 canonical skill(s)')) 'scenario 1: canonical set is exactly 2 -- the depth-decoy SKILL.md was not counted as a 3rd'

    # --- Scenario 2: a span missing a canonical skill name fails, naming it --------------------------
    Write-Host "check 10 -- a span missing a canonical skill name fails" -ForegroundColor Cyan
    $s2Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '<!-- /skills:all -->'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s2Lines -join "`n") + "`n"), $Utf8NoBom)

    $r2 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r2.Out -match '\[skill-list\].*is missing: skill-beta') 'scenario 2: the missing skill-beta is named in the finding'

    # --- Scenario 3: a span naming something that is not a skill fails -------------------------------
    Write-Host "check 10 -- a span naming a non-skill fails" -ForegroundColor Cyan
    $s3Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '- `skill-beta`'
        '- `not-a-real-skill`'
        '<!-- /skills:all -->'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s3Lines -join "`n") + "`n"), $Utf8NoBom)

    $r3 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r3.Out -match '\[skill-list\].*not a known skill: not-a-real-skill') 'scenario 3: the unknown name not-a-real-skill is named in the finding'

    # --- Scenario 4: an unpaired BEGIN marker (no matching END) is a hard error ----------------------
    Write-Host "check 10 -- an unpaired BEGIN marker fails" -ForegroundColor Cyan
    $s4Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '- `skill-beta`'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s4Lines -join "`n") + "`n"), $Utf8NoBom)

    $r4 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r4.Out -match [regex]::Escape("has no matching '<!-- /skills:all -->'")) 'scenario 4: the unpaired BEGIN marker is reported'

    # --- Scenario 5: TWO unpaired BEGIN markers in the SAME file -- BOTH must be reported. Regression
    # guard: an earlier version used 'break' on the first unpaired marker and silently abandoned the
    # rest of the file, so a second, later problem in the same doc went unnoticed. The fix continues
    # scanning past a malformed marker instead of bailing out of the whole file.
    Write-Host "check 10 -- two unpaired BEGIN markers in one file are BOTH reported" -ForegroundColor Cyan
    $s5Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        ''
        'Some unrelated paragraph in between.'
        ''
        '<!-- skills:all -->'
        '- `skill-beta`'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s5Lines -join "`n") + "`n"), $Utf8NoBom)

    $r5 = Invoke-Integrity -FixtureRoot $Fixture
    $unpairedHits = [regex]::Matches($r5.Out, [regex]::Escape("has no matching '<!-- /skills:all -->'"))
    Assert-Equal 2 $unpairedHits.Count 'scenario 5: both unpaired BEGIN markers are reported, not just the first (no break-and-abandon regression)'

    # --- Scenario 6: an UNMARKED, deliberately incomplete enumeration must NOT fail. This is the
    # whole reason check 10 is opt-in rather than a generic prose scan: a real doc (e.g.
    # QUICKSTART.md) legitimately lists only SOME skills as illustration, without ever claiming to be
    # exhaustive, and must not be flagged just because it happens to under-enumerate.
    Write-Host "check 10 -- an unmarked, deliberately incomplete list is NOT flagged" -ForegroundColor Cyan
    $s6Lines = @(
        '# Contributing'
        ''
        'Here is one skill, for illustration only (this list is not exhaustive):'
        '- `skill-alpha`'
        ''
        "That's not all of them."
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s6Lines -join "`n") + "`n"), $Utf8NoBom)

    $r6 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r6.Out -match $SkillListFindingPattern)) 'scenario 6: an unmarked, incomplete list reports no [skill-list] finding'
    Assert-True ($r6.Out -match [regex]::Escape('0 <!-- skills:all --> span(s) found')) 'scenario 6: zero spans found across the fixture -- opt-in, so this is a pass'

    # --- Scenario 7: an INLINE span in running prose -- backtick terms OUTSIDE the span that are not
    # skill names must not be flagged. Mirrors the real family-README sentence (the three
    # *-sessioncheck hook names sit one line above the skill enumeration, outside its span).
    Write-Host "check 10 -- an inline span in prose ignores backtick terms outside it" -ForegroundColor Cyan
    $s7Lines = @(
        '# Contributing'
        ''
        'Session hooks `connector-sessioncheck`, `roster-sessioncheck`, and `script-contract-sessioncheck` run at session start.'
        'Only the skills (<!-- skills:all -->`skill-alpha`, `skill-beta`<!-- /skills:all -->) remain available there.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s7Lines -join "`n") + "`n"), $Utf8NoBom)

    $r7 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r7.Out -match $SkillListFindingPattern)) 'scenario 7: hook names outside the inline span are not treated as claimed skill names'

    # --- Scenario 8: the depth-decoy SKILL.md (skills/<name>/references/SKILL.md) is not part of the
    # canonical skillset -- naming it inside a span is reported as an unknown name, proving it was
    # never picked up as a real skill in the first place (the flip side of scenario 1's count check).
    Write-Host "check 10 -- a SKILL.md nested one level too deep is not a canonical skill" -ForegroundColor Cyan
    $s8Lines = @(
        '# Contributing'
        ''
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '- `skill-beta`'
        '- `skill-deep-decoy`'
        '<!-- /skills:all -->'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s8Lines -join "`n") + "`n"), $Utf8NoBom)

    $r8 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r8.Out -match '\[skill-list\].*not a known skill: skill-deep-decoy') 'scenario 8: the depth decoy skill-deep-decoy is reported as unknown -- it was never in the canonical set'

    # --- Scenario 9: a complete marker EXAMPLE inside a fenced ```-code block -- reports nothing, AND
    # does not count in the span total. Asserting the count (not just "no error") is the point: it is
    # the proof the example is genuinely invisible to the scan, not "seen, checked, and happened to
    # pass" -- see Get-FenceMaskedText in the real script (added because a literal marker example in
    # a doc, e.g. Tessa's convention writeup, would otherwise itself be read as a live span).
    Write-Host "check 10 -- a fenced marker EXAMPLE is invisible to the scan (not counted)" -ForegroundColor Cyan
    $s9Lines = @(
        '# Contributing'
        ''
        'Here is how you show the marker literally:'
        ''
        '```'
        '<!-- skills:all -->'
        '- `skill-alpha`'
        '- `skill-beta`'
        '<!-- /skills:all -->'
        '```'
        ''
        'End of example.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s9Lines -join "`n") + "`n"), $Utf8NoBom)

    $r9 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r9.Out -match $SkillListFindingPattern)) 'scenario 9: a fenced marker example reports no [skill-list] finding'
    Assert-True ($r9.Out -match [regex]::Escape('0 <!-- skills:all --> span(s) found')) 'scenario 9: the fenced example is not counted as a span at all -- proves it is invisible, not merely passing'

    # --- Scenario 10: a fence containing ONLY the BEGIN marker, with no '<!-- /skills:all -->'
    # ANYWHERE ELSE in the file either -- must NOT raise "has no matching END". This is exactly the
    # case that gave a hard error before the fence-masking fix (the reason for the change): a fenced
    # BEGIN-only example used to be indistinguishable from a genuinely malformed live marker.
    Write-Host "check 10 -- a fenced BEGIN-only example (no END anywhere) is NOT an unpaired-marker error" -ForegroundColor Cyan
    $s10Lines = @(
        '# Contributing'
        ''
        'Example of just the opening marker:'
        ''
        '```'
        '<!-- skills:all -->'
        '```'
        ''
        '(no matching end anywhere in this file)'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s10Lines -join "`n") + "`n"), $Utf8NoBom)

    $r10 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r10.Out -match $SkillListFindingPattern)) 'scenario 10: a fenced BEGIN-only example reports no "has no matching END" error'
    Assert-True ($r10.Out -match [regex]::Escape('0 <!-- skills:all --> span(s) found')) 'scenario 10: the masked BEGIN inside the fence never becomes a span (not even an unpaired one)'

    # --- Scenario 11: a REAL span OUTSIDE a fence, in the SAME file as a fenced example -- still
    # checked normally, and its reported LINE NUMBER matches the actual line. The line number is the
    # crux of the masking approach (same length + same newline positions as the original) -- if
    # someone ever swaps the mask for a cut/splice, this assert is designed to break.
    Write-Host "check 10 -- a real span outside a fence is still checked, with the correct line number" -ForegroundColor Cyan
    $s11Lines = @(
        '# Contributing'                             # line 1
        ''                                             # line 2
        'Example of the marker (not a live span):'    # line 3
        ''                                             # line 4
        '```'                                          # line 5
        '<!-- skills:all -->'                          # line 6
        '- `something`'                                # line 7
        '<!-- /skills:all -->'                          # line 8
        '```'                                          # line 9
        ''                                             # line 10
        'Real usage below:'                            # line 11
        ''                                             # line 12
        '<!-- skills:all -->'                          # line 13
        '- `skill-alpha`'                              # line 14
        '<!-- /skills:all -->'                          # line 15
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s11Lines -join "`n") + "`n"), $Utf8NoBom)

    $r11 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r11.Out -match [regex]::Escape('span at line 13 is missing: skill-beta')) 'scenario 11: the real span outside the fence is checked, and reports the correct line (13)'
    Assert-True (-not ($r11.Out -match 'not a known skill: something')) 'scenario 11: the fenced examples "something" never surfaces as an unknown-skill finding -- it is masked, not scanned'
    Assert-True ($r11.Out -match [regex]::Escape('checked 1 <!-- skills:all --> span(s) against 2 canonical skill(s)')) 'scenario 11: only the real span is counted -- the fenced example contributes 0'

    # --- Scenario 12 (deliberate-boundary lock, not a bug guard): a marker written as INLINE code
    # (single backticks, not a fence) is NOT masked and IS still scanned as a live span. Sylvester's
    # documented trade-off: a real span's own claimed skill names are themselves single-backtick
    # delimited, so there is no character-level way to tell "this pair of backticks is an inline-code
    # escape" from "this pair of backticks is a claimed skill name" -- masking inline code would erase
    # genuine findings along with any escaped example. Fixing this assert to expect silence later
    # would mean someone changed that boundary without discussing it first.
    Write-Host "check 10 -- a marker in INLINE code (not a fence) is still scanned as live (deliberate boundary)" -ForegroundColor Cyan
    $s12Lines = @(
        '# Contributing'                                                # line 1
        ''                                                                # line 2
        'Inline example (not fenced): `<!-- skills:all -->`'             # line 3
        '- `skill-alpha`'                                                  # line 4
        '`<!-- /skills:all -->`'                                           # line 5
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s12Lines -join "`n") + "`n"), $Utf8NoBom)

    $r12 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r12.Out -match [regex]::Escape('span at line 3 is missing: skill-beta')) 'scenario 12: a marker inside single-backtick inline code is still read as a live span (deliberately not masked)'

    # --- Scenario 13: a LONE orphan END, with no BEGIN anywhere in the file -- a hard error, with the
    # correct line number. Victor's finding: the original check-10 only guarded BEGIN-without-END; an
    # orphan or duplicate END vanished silently. This is the symmetric counterpart of scenario 4.
    Write-Host "check 10 -- a lone orphan END (no BEGIN anywhere) fails" -ForegroundColor Cyan
    $s13Lines = @(
        '# Contributing'                              # line 1
        ''                                              # line 2
        '<!-- /skills:all -->'                          # line 3
        ''                                              # line 4
        'No begin marker anywhere in this file.'        # line 5
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s13Lines -join "`n") + "`n"), $Utf8NoBom)

    $r13 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r13.Out -match [regex]::Escape("'<!-- /skills:all -->' at line 3 has no matching '<!-- skills:all -->'")) 'scenario 13: the lone orphan END is reported, with the correct line number'

    # --- Scenario 14 (the important one): a SECOND END pasted inside an already-open, otherwise real
    # span -- exactly the copy-paste mistake that used to go silently, dangerously GREEN: the span
    # closed early at the first END, the rest of the enumeration became unchecked prose, the surplus
    # END vanished, and the check reported "checked 1 span" after only checking half of it. Two
    # things must both be true now: the truncated span reports its now-missing name (proof it closed
    # early), AND the surplus END is reported separately, on its own line.
    Write-Host "check 10 -- a second END pasted inside a real span is caught, not silently swallowed" -ForegroundColor Cyan
    $s14Lines = @(
        '# Contributing'                              # line 1
        ''                                              # line 2
        '<!-- skills:all -->'                          # line 3
        '- `skill-alpha`'                                # line 4
        '<!-- /skills:all -->'                          # line 5
        '<!-- /skills:all -->'                          # line 6 -- copy-paste duplicate
        '- `skill-beta`'                                 # line 7 -- now just prose, outside the span
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s14Lines -join "`n") + "`n"), $Utf8NoBom)

    $r14 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r14.Out -match [regex]::Escape('span at line 3 is missing: skill-beta')) 'scenario 14: the span closed early at the first END -- skill-beta (now outside it) is reported missing'
    Assert-True ($r14.Out -match [regex]::Escape("'<!-- /skills:all -->' at line 6 has no matching '<!-- skills:all -->'")) 'scenario 14: the surplus second END is reported separately, on its own line'

    # --- Scenario 15: an END inside a code fence -- no error. Proves the masking is symmetric: a
    # fenced END is exactly as invisible to the sweep as a fenced BEGIN was in scenario 9/10.
    Write-Host "check 10 -- an END inside a code fence is invisible too (symmetric masking)" -ForegroundColor Cyan
    $s15Lines = @(
        '# Contributing'
        ''
        '```'
        '<!-- /skills:all -->'
        '```'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s15Lines -join "`n") + "`n"), $Utf8NoBom)

    $r15 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r15.Out -match $SkillListFindingPattern)) 'scenario 15: a fenced END reports no [skill-list] finding'
    Assert-True ($r15.Out -match [regex]::Escape('0 <!-- skills:all --> span(s) found')) 'scenario 15: the masked END never becomes an orphan finding -- it is invisible, same as a masked BEGIN'

    # --- Scenario 16: root changelog ENTRY files are IN the scan set (#234) --------------------------
    # The window this closes: an entry file's text sits outside every scanned path while the PR is
    # open, and only lands in a scanned file at FOLD time -- which happens directly on main, past every
    # PR gate. v2.13.0 was blocked by exactly that: a marker quoted in changelog prose became an
    # unpaired BEGIN in CHANGELOG.md, discovered only when cut-release ran the full gate on main.
    # Both halves are asserted here: the dead link (check 4) AND the quoted marker (check 10, the
    # original case), because they share this file set and the window covered both.
    Write-Host "check 4 + 10 -- a root changelog entry file is scanned BEFORE the fold" -ForegroundColor Cyan
    $midDot = [char]0x00B7
    $entryPath = Join-Path $Fixture 'fix-my-branch.md'
    $s16Lines = @(
        "### My change $midDot Fix $midDot 2026-07-29"
        ''
        "See [nope]($deadLink) for details."
        'The gate caught the skill missing from a `<!-- skills:all -->` span.'
    )
    [System.IO.File]::WriteAllText($entryPath, (($s16Lines -join "`n") + "`n"), $Utf8NoBom)

    $r16 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-Equal 1 $r16.Code 'scenario 16: exit 1 -- an entry file is scanned, so its findings surface while the PR is open'
    Assert-True ($r16.Out -match [regex]::Escape('.\fix-my-branch.md') -and $r16.Out -match '\[link\]') 'scenario 16: a dead link in an entry body is reported BEFORE the fold, not after'
    Assert-True ($r16.Out -match [regex]::Escape("'<!-- skills:all -->' at line 4 has no matching")) 'scenario 16: the original #234 case -- a marker quoted in entry prose is caught on the PR instead of on main'
    # The decoy from scenario A is still sitting in the fixture root with the same dead link, and it
    # opens with an H1. It must STILL be ignored: the new rule keys on the entry format, not on "any
    # root .md", so a permanent root doc (README, CONTRIBUTING, SECURITY, ...) never joins the set.
    Assert-True (-not ($r16.Out -match [regex]::Escape('NOTES.md'))) 'scenario 16: an H1 root doc is still NOT read as an entry file -- the scan stayed scope-limited'

    # And once the fold has taken it away, it simply drops out of the set again -- no stale reference,
    # no error about a file that no longer exists.
    Remove-Item -LiteralPath $entryPath -Force
    $r17 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r17.Out -match [regex]::Escape('fix-my-branch.md'))) 'scenario 16: after the fold removes it, the entry file is gone from the set without complaint'

    # --- [COVERAGE]: every category states what it examined, and an empty one says so (issue #221) ---
    # This fixture is the ideal witness and always has been: it carries no agent def, no manual, no
    # persona, no plugin manifest and no lens tree, so those categories are GENUINELY empty. Before
    # #221 the run was therefore green while silently checking nothing in half its categories -- the
    # docstring above even records that as "expected noise, asserted on nowhere below". It is asserted
    # on now: a category that finds nothing must say the number out loud.
    #
    # Deliberately asserts the ZERO cases (the ones that used to be invisible) AND two non-zero cases,
    # because a coverage line that always printed "0" would satisfy the first half while being useless.
    Write-Host "[COVERAGE] every category reports its count, and an empty category is visible" -ForegroundColor Cyan
    $rc = Invoke-Integrity -FixtureRoot $Fixture
    foreach ($cat in @('agent-def', 'manual', 'persona', 'specialist', 'shared', 'release-card')) {
        Assert-True ($rc.Out -match "\[$([regex]::Escape($cat))\] checked 0\b") `
            "coverage: the genuinely empty category '$cat' reports 'checked 0' instead of staying silent"
    }
    Assert-True ($rc.Out -match '\[link-scan/lenses\] checked 0\b') `
        'coverage: the lens category -- the one a teardown removes -- reports 0 on a repo with no lens tree'
    Assert-True ($rc.Out -match '\[link-scan/lenses\] checked 0 -- no repo-lens file') `
        'coverage: the empty lens category also states WHY it is empty, so a reader can tell a teardown from a loss'
    Assert-True ($rc.Out -match '\[link-scan\] checked [1-9]') `
        'coverage: a non-empty category reports its real count -- the line is not hardcoded to 0'
    Assert-True ($rc.Out -match '\[parse\] checked [1-9]') `
        'coverage: parse counts the .ps1 files it actually parsed (the copied script + its libs)'
    # Coverage is context, never a finding: it must not move the exit code or manufacture an error.
    # Scenario 16 left the fixture with a real finding, so this run legitimately exits 1 -- what is
    # asserted here is that no coverage line was itself counted as one.
    Assert-True (-not ($rc.Out -match '(?m)^\s*\[COVERAGE\]')) `
        'coverage: the token is the category name, not a literal [COVERAGE] tag -- one line per category, no extra noise'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
