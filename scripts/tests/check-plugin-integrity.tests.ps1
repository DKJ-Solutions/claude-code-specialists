<#
.SYNOPSIS
    Regression tests for scripts/lint/check-plugin-integrity.ps1:
      - check 4 (dead-link/anchor scan): guards that root CONTRIBUTING.md and
        connectors/README.md stay part of the scanned file set.
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
    canonical skillset for check 10: plugins/specialists/skills/
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

    Check 11 (printed lifecycle commands carry their flags), scenarios 17-27, same CONTRIBUTING.md
    fixture. The class these guard is the one three adoption rounds in a row kept producing: a doc
    place printing a command that no longer holds, failing silently when copied.
     17. A complete block (refresh, then install with --scope project) reports nothing -- and the
         coverage count proves the command WAS examined, so the pass is not an empty scan.
     18. A targeted install without --scope project fails, naming file and line, and the refresh rule
         does NOT also fire (it is satisfied two lines below) -- the two rules are independent.
     19. A targeted install with the flag but no refresh named nearby fails, and the scope rule does
         not fire. The mirror image of 18.
     20. (THE DISCRIMINATOR) bare mentions -- prose discussing the command with no @-target -- are not
         flagged, are counted as skipped, and the skip is stated. This is the case that decides whether
         a generic scan is viable at all; the same question made check 10 opt-in instead.
     21. A command WRAPPED across a newline inside one inline-code span keeps its flag. Regression
         guard: the first build was line-based and called the teardown SKILL's own uninstall line a
         violation because its flag sits on the next line.
     22. A fenced code block EARLIER in the file does not shift inline-span pairing. The second real
         bug: without fence masking a ```-delimiter opens a phantom span and every real span
         downstream pairs one position out, so scenario 21's command silently looked flagless -- a
         misread, not an error, which is why it gets its own case.
     23. uninstall needs the scope flag but is exempt from the refresh: a stale cache cannot affect a
         removal.
     24. History (CHANGELOG.md, and by the same rule releases/**, RELEASE.md, root entry files) is
         excluded and not even counted. The real repo proves the need -- specialists/CHANGELOG.md
         prints a targeted install with no scope flag, correctly, because that is what the release it
         describes actually said.
     25. Two commands with the SAME verb in one span are judged on their own arguments, and only the
         incomplete one is reported. Victor's review finding on this check's own code: the tail used to
         be taken from IndexOf($verb), so the second command borrowed the first one's flag.
     26. `uninstall --scope local` PASSES. Round v8 (inbound #314/#315) measured that a session start
         can leave a record at `scope=local` and that `--scope project` refuses to remove one, so this
         is the only command that does the job; a gate demanding `project` would reject the correct
         instruction and enforce the assumption that round disproved.
     27. The guard that must ship with 26: `install --scope local` still FAILS. The exception is
         verb-specific -- nothing measured says a local-scoped install is ever what a reader wants --
         and without this case the widening quietly becomes global.

    Check 12 (printed install-record queries name the disambiguating fields), scenarios 28-32, same
    fixture. This is the gate for the CLASS behind round v8's three findings rather than any one of them:
    the query every document points a reader at printed a green that under-determined the state.
     28. The complete four-field query passes, and the coverage count proves it was examined.
     29. Dropping `gitCommitSha` fails (the #313 field), anchored on the first line INSIDE the fence, and
         the "does not name" clause lists only what is missing while the message still names the full
         required set as context.
     30. Dropping `projectPath` fails: without it the query reports records beyond this repo, the
         `claude plugin list` mistake these same docs warn against -- so it is a required field, not part
         of the discriminator. The message names the mistake it reproduces.
     31. (THE DISCRIMINATOR) a fenced JSON snippet ILLUSTRATING the file is not a subject, even though it
         names the same fields and lacks `gitCommitSha`. Without this case the check would forbid
         documenting the file's own shape. It is counted as skipped and the skip is stated -- which is the
         assertion that made the check report its skip count on the empty-scan branch too, since "saw
         nothing" and "saw one block and did not judge it" are different states.
     32. Prose naming the file outside any fence is never an instruction.

    Check 17 (the per-plugin CHANGELOG intro still matches its generator), scenarios 33-37. These need a
    marketplace.json in the fixture, since the expected text is DERIVED from its 'name' -- which also
    switches checks 1/2/9 from "found nothing" to "found something incomplete". That noise is expected and
    asserted on nowhere, exactly as check 8's missing-mirror noise already is.
     33. A generated intro passes, and the coverage count proves the file was examined -- so the pass is
         evidence rather than an empty scan.
     34. (THE MEASURED DEFECT) an intro naming a marketplace the manifest does not is reported, naming the
         file, and the finding states the expected text so the repair needs no second lookup.
     35. The same sentences rewrapped at a different column PASS. A gate failing on layout would teach
         "rewrap to satisfy the linter" about a file no human should be rewrapping by hand. The fixture is
         DERIVED from the generator rather than retyped -- retyping the em-dash title as a plain hyphen was
         this scenario's first failure, a content difference masquerading as a layout one.
     36. A CHANGELOG with no '## vX.Y.Z' heading is REPORTED, not silently skipped: the intro's end cannot
         be located, so nothing can be asserted -- and a check that quietly asserts nothing is the exact
         failure mode this gate exists to prevent.
     37. (THE DESIGN, NOT A BUG GUARD) renaming the marketplace in the fixture manifest -- and nothing else
         -- flips the SAME file from failing to passing. Without this case the check could carry its own
         hardcoded copy of the name and every scenario above would still pass, which is precisely the shape
         of the defect it exists to catch.

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
# Fourth and fifth dot-sourced dependencies since check 17: release-lib.ps1 supplies
# Build-PluginChangelogIntro + Get-MarketplaceName, and release-lib itself dot-sources branch-info.ps1
# from its own folder. Both are copied for the same reason as the three above -- the fixture runs the
# REAL script, so a missing dependency is a broken suite rather than one skipped check.
$ReleaseLibSrc = Join-Path $RepoRoot 'scripts\lib\release-lib.ps1'
$BranchInfoSrc = Join-Path $RepoRoot 'scripts\lib\branch-info.ps1'
# Sixth, since the tier model (August 5, 2026): release-lib dot-sources entry-scaffold-lib.ps1 for the
# changelog's tier sections. Copied for the same reason as the five above -- this fixture runs the REAL
# script, so a missing sibling is a broken suite rather than one skipped check.
$EntryScaffoldSrc = Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1'
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
    New-Item -ItemType Directory -Path (Join-Path $Fixture 'connectors') -Force | Out-Null
    # check 10 fixture: two canonical skills (skill-alpha, skill-beta) plus a DEPTH DECOY -- a
    # SKILL.md one level deeper (skills/<name>/references/SKILL.md) that must NOT be picked up as a
    # third canonical skill, exercising the exact-depth binding of check 10's canonical-skillset scan.
    New-Item -ItemType Directory -Path (Join-Path $Fixture 'plugins\specialists\skills\skill-alpha\references') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Fixture 'plugins\specialists\skills\skill-beta') -Force | Out-Null

    Copy-Item -Path $IntegritySrc -Destination (Join-Path $Fixture 'scripts\lint\check-plugin-integrity.ps1') -Force
    Copy-Item -Path $AgentSharedLibSrc -Destination (Join-Path $Fixture 'scripts\lib\agent-shared-lib.ps1') -Force
    Copy-Item -Path $SharedScriptsLibSrc -Destination (Join-Path $Fixture 'scripts\lib\shared-scripts-lib.ps1') -Force
    Copy-Item -Path $CheckReportLibSrc -Destination (Join-Path $Fixture 'scripts\lib\check-report-lib.ps1') -Force
    Copy-Item -Path $ReleaseLibSrc -Destination (Join-Path $Fixture 'scripts\lib\release-lib.ps1') -Force
    Copy-Item -Path $BranchInfoSrc -Destination (Join-Path $Fixture 'scripts\lib\branch-info.ps1') -Force
    Copy-Item -Path $EntryScaffoldSrc -Destination (Join-Path $Fixture 'scripts\lib\entry-scaffold-lib.ps1') -Force

    $skillAlphaMd = "---`nname: skill-alpha`ndescription: Fixture skill alpha.`n---`n`n# Skill Alpha`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'plugins\specialists\skills\skill-alpha\SKILL.md'), $skillAlphaMd, $Utf8NoBom)
    $skillBetaMd = "---`nname: skill-beta`ndescription: Fixture skill beta.`n---`n`n# Skill Beta`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'plugins\specialists\skills\skill-beta\SKILL.md'), $skillBetaMd, $Utf8NoBom)
    # The depth decoy claims its own name (skill-deep-decoy) in frontmatter -- if check 10 ever
    # regressed to a looser depth match, that name would silently become a 3rd canonical skill.
    $skillDeepDecoyMd = "---`nname: skill-deep-decoy`ndescription: Depth decoy -- must not count as a canonical skill.`n---`n`n# Skill Deep Decoy`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'plugins\specialists\skills\skill-alpha\references\SKILL.md'), $skillDeepDecoyMd, $Utf8NoBom)

    # --- Scenario A: dead links in the two target files + a decoy outside the scan set --------------
    Write-Host "check 4 coverage -- CONTRIBUTING.md + connectors README are IN the scan set" -ForegroundColor Cyan
    $contributingBroken = "# Contributing`n`nSee [nope]($deadLink) for details.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), $contributingBroken, $Utf8NoBom)
    $connectorsBroken = "# Connectors`n`nSee [nope]($deadLink) for details.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'connectors\README.md'), $connectorsBroken, $Utf8NoBom)
    # Decoy: same dead link, but in a file that check 4 does NOT scan -- proves the two hits below
    # are due to CONTRIBUTING.md / the connectors README specifically being in the file list, not
    # some accidental blanket scan of every .md file in the fixture.
    #
    # IT MOVED OUT OF THE ROOT IN #405, AND THAT IS THE POINT IT NOW PROVES. This decoy used to sit at
    # 'NOTES.md' in the fixture root, back when the root docs were a NAMED list and the *.md glob covered
    # the separate family directory that held QUICKSTART.md, UNINSTALL.md and the family README. Flattening
    # moved those three documents INTO the root, so the root became the directory where consumer-facing
    # pages live and inherited the glob (see scenario 33, which requires exactly that). A root decoy would
    # now be testing that the glob does not work.
    #
    # So the decoy moved one directory down instead of being deleted: the property under test -- the scan
    # is scope-limited rather than a blanket walk of every .md in the tree -- is unchanged and still worth
    # asserting. Only the boundary moved, from "which root files are named" to "the root, and not below it".
    $decoyBroken = "# Decoy`n`nSee [nope]($deadLink) for details.`n"
    New-Item -ItemType Directory -Path (Join-Path $Fixture 'notes') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'notes\NOTES.md'), $decoyBroken, $Utf8NoBom)

    $a = Invoke-Integrity -FixtureRoot $Fixture
    Assert-Equal 1 $a.Code 'scenario A: exit 1 (findings present)'
    Assert-True ($a.Out -match [regex]::Escape('.\CONTRIBUTING.md') -and $a.Out -match '\[link\]') 'CONTRIBUTING.md dead link is reported'
    Assert-True ($a.Out -match [regex]::Escape('.\connectors\README.md')) 'connectors README dead link is reported'
    Assert-True (-not ($a.Out -match [regex]::Escape('NOTES.md'))) 'decoy notes\NOTES.md (outside the scan set) is NOT reported -- proves the scan is scope-limited, not a blanket walk'

    # --- Scenario B: fix both dead links -- the two specific findings disappear ----------------------
    Write-Host "check 4 coverage -- fixing the dead links removes exactly those findings" -ForegroundColor Cyan
    $contributingFixed = "# Contributing`n`nNothing to link to here.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), $contributingFixed, $Utf8NoBom)
    $connectorsFixed = "# Connectors`n`nNothing to link to here.`n"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'connectors\README.md'), $connectorsFixed, $Utf8NoBom)

    $b = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($b.Out -match [regex]::Escape('.\CONTRIBUTING.md') + '.*dead link')) 'CONTRIBUTING.md dead-link finding is gone once fixed'
    Assert-True (-not ($b.Out -match [regex]::Escape('.\connectors\README.md') + '.*dead link')) 'connectors README dead-link finding is gone once fixed'

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
    # The entry-format rule still has to hold, and since #405 it is CHECK 13 that carries it rather than
    # the dead-link scan. Every root *.md is link-scanned now, so "is this an entry file?" no longer
    # decides whether a root document is READ -- it decides whether it is judged as a changelog entry
    # (heading levels) and whether checks 11 and 12 skip it as history in the making. A permanent root
    # doc must never be counted as one: the fixture root holds CONTRIBUTING.md and CHANGELOG.md beside
    # the single entry file, so the count is the discriminator, and it would catch the entry rule
    # degrading into "any root .md" just as the old NOTES.md assertion did.
    Assert-True ($r16.Out -match '\[entry-heading\].*1 unfolded entry file\(s\)') 'scenario 16: exactly ONE root file is read as an entry -- a permanent root doc is scanned but never judged as one'

    # And once the fold has taken it away, it simply drops out of the set again -- no stale reference,
    # no error about a file that no longer exists.
    Remove-Item -LiteralPath $entryPath -Force
    $r17 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r17.Out -match [regex]::Escape('fix-my-branch.md'))) 'scenario 16: after the fold removes it, the entry file is gone from the set without complaint'

    # --- check 11: printed lifecycle commands carry their flags --------------------------------------
    # The class three adoption rounds in a row kept producing: a doc place printing a command that no
    # longer holds. The cases below are ordered by what they protect -- first the two rules, then the
    # DISCRIMINATOR (a bare mention must never be flagged; that over-detection is what forced check 10
    # to be opt-in), then the two real bugs this check hit while being built, then the exclusions.
    #
    # Matched on the error phrase, not the bare '[lifecycle]' tag: that tag also prefixes the coverage
    # line, which is present on every run. Same trap the check 10 pattern above documents.
    $LifecycleFindingPattern = "\[lifecycle\].*printed 'claude plugin"

    # --- Scenario 17: a correctly printed install passes ---------------------------------------------
    Write-Host "check 11 -- refresh + install + scope flag reports nothing" -ForegroundColor Cyan
    $s17Lines = @(
        '# Contributing'
        ''
        'From the root of your repo:'
        ''
        '```powershell'
        'claude plugin marketplace update claude-code-specialists'
        'claude plugin install specialists@claude-code-specialists --scope project'
        '```'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s17Lines -join "`n") + "`n"), $Utf8NoBom)
    $rL17 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($rL17.Out -match $LifecycleFindingPattern)) 'scenario 17: a complete install block reports no [lifecycle] finding'
    Assert-True ($rL17.Out -match '\[lifecycle\] checked [1-9]') 'scenario 17: and the command WAS examined -- the pass is not an empty scan'

    # --- Scenario 18: a targeted install without --scope project fails -------------------------------
    #     Fails silently in reality: the scopeless install writes a machine-wide record with no
    #     projectPath and still reports success (inbound #274/#279).
    Write-Host "check 11 -- a targeted install without --scope project fails" -ForegroundColor Cyan
    $s18Lines = @(
        '# Contributing'
        ''
        'Run `claude plugin install specialists@claude-code-specialists` from the repo root.'
        ''
        'Refresh first with `claude plugin marketplace update claude-code-specialists`.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s18Lines -join "`n") + "`n"), $Utf8NoBom)
    $rL18 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-Equal 1 $rL18.Code 'scenario 18: exit 1 -- a missing scope flag is an error'
    Assert-True ($rL18.Out -match [regex]::Escape('CONTRIBUTING.md:3') + ".*no '--scope project'") 'scenario 18: the finding names the file and the line'
    Assert-True (-not ($rL18.Out -match 'nor a link')) 'scenario 18: and NOT the refresh rule -- that one is satisfied two lines below'

    # --- Scenario 19: a targeted install with no refresh named nearby fails --------------------------
    Write-Host "check 11 -- a targeted install with no refresh nearby fails" -ForegroundColor Cyan
    $s19Lines = @(
        '# Contributing'
        ''
        'Run `claude plugin install specialists@claude-code-specialists --scope project` from the root.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s19Lines -join "`n") + "`n"), $Utf8NoBom)
    $rL19 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-Equal 1 $rL19.Code 'scenario 19: exit 1 -- a missing refresh is an error'
    Assert-True ($rL19.Out -match [regex]::Escape('CONTRIBUTING.md:3') + '.*nor a link') 'scenario 19: the refresh rule fires, naming file and line'
    Assert-True (-not ($rL19.Out -match "no '--scope project'")) 'scenario 19: and NOT the scope rule -- the flag is present'

    # --- Scenario 20 (THE DISCRIMINATOR): a bare mention is never flagged ----------------------------
    #     Prose discussing the command carries no @-target, and demanding flags there would be
    #     nonsense. This is the case that decides whether the check can be a generic scan at all: the
    #     147-hit over-detection measured on check 10 is what made THAT one opt-in.
    Write-Host "check 11 -- a bare mention in prose is NOT flagged (the over-detection guard)" -ForegroundColor Cyan
    $s20Lines = @(
        '# Contributing'
        ''
        'Note that `claude plugin update` defaults to user scope, and so does `claude plugin install`.'
        'Because `claude plugin update` pins the cache to a version, the card is always exact.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s20Lines -join "`n") + "`n"), $Utf8NoBom)
    $rL20 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($rL20.Out -match $LifecycleFindingPattern)) 'scenario 20: three bare mentions, zero findings -- discussion is not instruction'
    Assert-True ($rL20.Out -match '\[lifecycle\] checked 0') 'scenario 20: they are counted as skipped, not as enforced'
    Assert-True ($rL20.Out -match 'bare mention|nothing to enforce') 'scenario 20: and the skip is stated rather than silent'

    # --- Scenario 21: a command WRAPPED across a newline inside one inline-code span -----------------
    #     Regression guard. The first build of this check was line-based and called the teardown
    #     SKILL's own `claude plugin uninstall ...` / `--scope project` pair a violation, because the
    #     flag sits on the next line of the same span.
    Write-Host "check 11 -- a command wrapped across lines in one inline span keeps its flag" -ForegroundColor Cyan
    $s21Lines = @(
        '# Contributing'
        ''
        'Removing it is a separate step: `claude plugin uninstall specialists@claude-code-specialists'
        '--scope project`, run from the repo root.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s21Lines -join "`n") + "`n"), $Utf8NoBom)
    $rL21 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($rL21.Out -match $LifecycleFindingPattern)) 'scenario 21: the wrapped span is read as one command, flag included'

    # --- Scenario 22: a fenced block earlier in the file must not shift span pairing -----------------
    #     The second real bug: without fence masking, a ```-delimiter starts a phantom inline span and
    #     every real span downstream pairs one position out -- so scenario 21's command silently looked
    #     flagless. A silent misread, not an error, which is why it gets its own case.
    Write-Host 'check 11 -- a fenced code block earlier in the file does not break span pairing' -ForegroundColor Cyan
    $s22Lines = @(
        '# Contributing'
        ''
        '```powershell'
        'Write-Host "an unrelated example"'
        '```'
        ''
        'Removing it: `claude plugin uninstall specialists@claude-code-specialists'
        '--scope project`, from the root.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s22Lines -join "`n") + "`n"), $Utf8NoBom)
    $rL22 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($rL22.Out -match $LifecycleFindingPattern)) 'scenario 22: the fence is masked, so the wrapped span downstream is still read correctly'

    # --- Scenario 23: uninstall needs the scope flag, and is exempt from the refresh -----------------
    #     Asymmetric on purpose: a stale cache cannot affect a removal.
    Write-Host "check 11 -- uninstall needs the scope flag but not the refresh" -ForegroundColor Cyan
    $s23Lines = @(
        '# Contributing'
        ''
        'Afterwards run `claude plugin uninstall specialists@claude-code-specialists` to detach.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s23Lines -join "`n") + "`n"), $Utf8NoBom)
    $rL23 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($rL23.Out -match [regex]::Escape('CONTRIBUTING.md:3') + ".*no '--scope project'") 'scenario 23: a scopeless uninstall is still an error'
    Assert-True (-not ($rL23.Out -match 'nor a link')) 'scenario 23: but the refresh is never demanded of an uninstall'

    # --- Scenario 24: history is excluded, permanently and on purpose -------------------------------
    #     CHANGELOG.md and the release notes record what was true at the time and are never rewritten.
    #     The real repo proves the need: specialists/CHANGELOG.md prints a targeted install with no
    #     scope flag, correctly, because that is what the release it describes actually said.
    Write-Host "check 11 -- a lifecycle command in CHANGELOG.md history is not flagged" -ForegroundColor Cyan
    $s24Contributing = @('# Contributing', '', 'Nothing to run here.')
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s24Contributing -join "`n") + "`n"), $Utf8NoBom)
    $s24Changelog = @(
        '# Changelog'
        ''
        'The install back then was `claude plugin install specialists@claude-code-specialists`, with no'
        'scope flag and no refresh -- which is exactly what that release documented.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CHANGELOG.md'), (($s24Changelog -join "`n") + "`n"), $Utf8NoBom)
    $rL24 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($rL24.Out -match $LifecycleFindingPattern)) 'scenario 24: history is not held to the current rules'
    Assert-True ($rL24.Out -match '\[lifecycle\] checked 0') 'scenario 24: the history command was not even counted as enforced'

    # --- Scenario 25: two commands with the SAME verb in one span are judged separately --------------
    #     Victor's review finding on the check itself: the tail was originally taken from
    #     IndexOf($verb) in the span, so a second `install` in the same span was judged on the FIRST
    #     one's arguments -- a scopeless command reading as flagged correctly. The offset now comes from
    #     the match position. The first command here is complete, the second is not, and only the second
    #     may be reported.
    Write-Host 'check 11 -- two same-verb commands in one span are judged on their own arguments' -ForegroundColor Cyan
    $s25Lines = @(
        '# Contributing'
        ''
        'Refresh with `claude plugin marketplace update claude-code-specialists` first.'
        ''
        'Then `claude plugin install specialists@claude-code-specialists --scope project ; claude plugin install specialists-ecomm@claude-code-specialists` for both.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s25Lines -join "`n") + "`n"), $Utf8NoBom)
    $rL25 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($rL25.Out -match [regex]::Escape('CONTRIBUTING.md:5') + ".*no '--scope project'") 'scenario 25: the second, scopeless install IS reported'
    Assert-Equal 1 (@([regex]::Matches($rL25.Out, "no '--scope project'")).Count) 'scenario 25: and exactly once -- the first command is complete and must not be flagged too'

    # --- Scenario 26: `uninstall --scope local` passes -- the verb-specific exception ----------------
    #     Round v8 (inbound #314/#315) measured that a SESSION START can leave a record at
    #     `scope=local`, and that `claude plugin uninstall ... --scope project` refuses to remove one
    #     ("installed in local scope, not project"). So `--scope local` is the only command that does the
    #     job, and a gate demanding `project` here would reject the correct instruction -- enforcing the
    #     very assumption that round disproved. This is the case that keeps that fix documentable.
    Write-Host 'check 11 -- uninstall at --scope local passes (the state a session start leaves)' -ForegroundColor Cyan
    $s26Lines = @(
        '# Contributing'
        ''
        'Remove a record a session start left behind with'
        '`claude plugin uninstall specialists@claude-code-specialists --scope local`, then re-install.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s26Lines -join "`n") + "`n"), $Utf8NoBom)
    $rL26 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($rL26.Out -match $LifecycleFindingPattern)) 'scenario 26: a local-scoped uninstall is accepted'
    Assert-True ($rL26.Out -match '\[lifecycle\] checked [1-9]') 'scenario 26: and it WAS examined -- the pass is not an empty scan'

    # --- Scenario 27: the exception is verb-specific -- `install --scope local` still fails ----------
    #     The guard case that must ship with scenario 26, or the widening quietly becomes global. Nothing
    #     measured says a `local` INSTALL is ever what a reader wants; only the removal needs it.
    Write-Host 'check 11 -- install at --scope local is still an error (the exception is uninstall-only)' -ForegroundColor Cyan
    $s27Lines = @(
        '# Contributing'
        ''
        'Refresh with `claude plugin marketplace update claude-code-specialists` first.'
        ''
        'Then run `claude plugin install specialists@claude-code-specialists --scope local` from the root.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s27Lines -join "`n") + "`n"), $Utf8NoBom)
    $rL27 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-Equal 1 $rL27.Code 'scenario 27: exit 1 -- local scope does not satisfy the rule for install'
    Assert-True ($rL27.Out -match [regex]::Escape('CONTRIBUTING.md:5') + ".*no '--scope project'") 'scenario 27: the finding names the file and the line'
    Assert-True (-not ($rL27.Out -match 'nor a link')) 'scenario 27: and NOT the refresh rule -- that one is satisfied above'

    # --- check 12: a printed install-record query names the disambiguating fields ------------------
    # The class behind all three findings of round v8 rather than any one of them. Ordered like check 11's
    # block: the rule first, then the DISCRIMINATOR (an illustration must never be flagged), then the
    # exclusion that keeps prose out.
    $RecordQueryFindingPattern = "\[record-query\].*does not name"
    # The complete query, as both real docs now print it. Reused across the cases below with one field
    # removed at a time, so each case differs from the passing one in exactly one way.
    $rqFull = @(
        '```powershell'
        '$root = (Get-Location).Path'
        '(Get-Content "$env:USERPROFILE\.claude\plugins\installed_plugins.json" -Raw | ConvertFrom-Json).plugins.PSObject.Properties |'
        '  ForEach-Object { $n = $_.Name; $_.Value | Where-Object { $_.projectPath -eq $root } |'
        '    ForEach-Object { "$n -> $($_.scope) $($_.version) $($_.gitCommitSha)" } }'
        '```'
    )

    # --- Scenario 28: the complete query passes, and WAS examined ------------------------------------
    Write-Host 'check 12 -- a query naming all four fields reports nothing' -ForegroundColor Cyan
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), ((@('# Contributing', '') + $rqFull) -join "`n") + "`n", $Utf8NoBom)
    $rQ28 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($rQ28.Out -match $RecordQueryFindingPattern)) 'scenario 28: the complete query is accepted'
    Assert-True ($rQ28.Out -match '\[record-query\] checked [1-9]') 'scenario 28: and it WAS examined -- the pass is not an empty scan'

    # --- Scenario 29: a query without gitCommitSha fails (THE #313 CASE) ----------------------------
    #     The field whose absence let a consumer run main while every documented way of asking said 3.0.8.
    Write-Host 'check 12 -- a query without gitCommitSha fails (inbound #313)' -ForegroundColor Cyan
    $rq29 = @($rqFull) -replace ' \$\(\$_\.gitCommitSha\)', ''
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), ((@('# Contributing', '') + $rq29) -join "`n") + "`n", $Utf8NoBom)
    $rQ29 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-Equal 1 $rQ29.Code 'scenario 29: exit 1 -- a missing field is an error'
    # Line 4, not 3: the fence delimiter sits on line 3, and the anchor is the first line INSIDE it --
    # where the reader's eye has to go to fix the query.
    Assert-True ($rQ29.Out -match [regex]::Escape('CONTRIBUTING.md:4') + ".*does not name 'gitCommitSha'") 'scenario 29: the finding names the file, the first line INSIDE the fence, and the missing field'
    # The "does not name" clause lists ONLY what is missing. The message then goes on to name all four
    # required fields as context, deliberately, so the assertion pins the clause rather than the whole line.
    Assert-True ($rQ29.Out -match "does not name 'gitCommitSha'\.") 'scenario 29: the clause ends after the one missing field'
    Assert-True (-not ($rQ29.Out -match "does not name 'scope'")) 'scenario 29: the fields that ARE present are not reported as missing'

    # --- Scenario 30: a query without projectPath fails (the claude-plugin-list mistake) -----------
    #     Required rather than assumed: without it the query reports records beyond this repo, which is
    #     precisely the defect both documents spend a paragraph warning against. A doc printing that would
    #     be reproducing the mistake it warns about.
    Write-Host 'check 12 -- a query without projectPath fails (it would report other repos)' -ForegroundColor Cyan
    $rq30 = @(
        '```powershell'
        '(Get-Content "$env:USERPROFILE\.claude\plugins\installed_plugins.json" -Raw | ConvertFrom-Json).plugins.PSObject.Properties |'
        '  ForEach-Object { $n = $_.Name; $_.Value | ForEach-Object { "$n -> $($_.scope) $($_.version) $($_.gitCommitSha)" } }'
        '```'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), ((@('# Contributing', '') + $rq30) -join "`n") + "`n", $Utf8NoBom)
    $rQ30 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-Equal 1 $rQ30.Code 'scenario 30: exit 1'
    Assert-True ($rQ30.Out -match "does not name 'projectPath'") 'scenario 30: the missing filter is the finding'
    Assert-True ($rQ30.Out -match 'claude plugin list') 'scenario 30: and the message says WHY, by naming the mistake it reproduces'

    # --- Scenario 31 (THE DISCRIMINATOR): a JSON illustration is not a subject ----------------------
    #     It names the same fields and is not a command anyone reads a verdict off. Same mention-versus-use
    #     question check 11 answers with its @-target, and the third time this repo has had to answer it.
    #     Without this case the check would forbid documenting the file's own shape.
    Write-Host 'check 12 -- a fenced JSON snippet illustrating the file is NOT flagged' -ForegroundColor Cyan
    $rq31 = @(
        '# Contributing'
        ''
        'A record in `installed_plugins.json` looks like this:'
        ''
        '```json'
        '{ "plugins": { "specialists@claude-code-specialists": ['
        '  { "scope": "project", "version": "3.0.8", "projectPath": "C:\\repo" } ] } }'
        '```'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($rq31 -join "`n") + "`n"), $Utf8NoBom)
    $rQ31 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($rQ31.Out -match $RecordQueryFindingPattern)) 'scenario 31: an illustration is not held to the query rule, even though it lacks gitCommitSha'
    Assert-True ($rQ31.Out -match '\[record-query\] checked 0') 'scenario 31: and it is counted as skipped, not as enforced'
    Assert-True ($rQ31.Out -match 'skipped as illustration') 'scenario 31: the skip is STATED -- an empty scan must not read as "the docs are right"'

    # --- Scenario 32: a prose mention outside any fence is not a subject either ---------------------
    Write-Host 'check 12 -- prose naming the file is not a subject' -ForegroundColor Cyan
    $rq32 = @(
        '# Contributing'
        ''
        'Your version is written down in `installed_plugins.json` and nowhere else; the install'
        'success line names no version at all.'
    )
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($rq32 -join "`n") + "`n"), $Utf8NoBom)
    $rQ32 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($rQ32.Out -match $RecordQueryFindingPattern)) 'scenario 32: prose discussing the file is never an instruction'
    Assert-True ($rQ32.Out -match '\[record-query\] checked 0') 'scenario 32: nothing enforced'

    # --- Scenario 33: a NEW consumer-facing doc is in the scan set without being named ---------------
    #     The scan set for checks 11 and 12 (and the dead-link scan) used to be a hardcoded list of two
    #     family docs, 'README.md' and 'QUICKSTART.md'. UNINSTALL.md was then written beside them and no
    #     gate saw it -- a brand-new consumer-facing page printing exactly the class of command these two
    #     checks exist to police, invisible on the run that introduced it. #103 had closed the same gap by
    #     ADDING the two names, which is why a third name would have repeated the fix instead of closing
    #     the class: such a list is only ever correct until the next document is written, and nothing
    #     announces the omission.
    #
    #     So the assertion is deliberately about a file this suite has never heard of either. Its name is
    #     arbitrary on purpose -- if this scenario ever has to be updated because a real doc got that
    #     name, the enumeration has stopped being an enumeration.
    #
    #     THE SUBJECT SITS IN THE ROOT SINCE #405, because that is where the class lives now. Flattening
    #     moved QUICKSTART.md, UNINSTALL.md and the family README into the repo root, so the next
    #     consumer-facing page will be written there rather than in a family directory -- and a scenario
    #     testing the old directory would have gone on passing while the real gap reopened one level up.
    #     The named list this scenario exists to prevent is gone with it: the root carries the *.md glob.
    Write-Host 'scan set -- a root doc nobody named is still scanned (checks 11 + 12)' -ForegroundColor Cyan
    $s33Path = Join-Path $Fixture 'ZZ-NEWLY-WRITTEN-PAGE.md'
    $s33 = @(
        '# A page written after the scan set was last touched'
        ''
        'Remove it again:'
        ''
        '```powershell'
        'claude plugin uninstall specialists@claude-code-specialists'
        '```'
    )
    [System.IO.File]::WriteAllText($s33Path, (($s33 -join "`n") + "`n"), $Utf8NoBom)
    $r33 = Invoke-Integrity -FixtureRoot $Fixture
    # NOT asserted on the exit code, and that is a measurement rather than an oversight. Run against the
    # pre-fix scan set this scenario's exit code was 1 either way, so `Assert-Equal 1 $r33.Code` passed in
    # both worlds -- a green that proves nothing, which is the exact failure mode this suite keeps
    # catching in the checks it tests. The discriminating assertions are the ones naming the file.
    Assert-True ($r33.Out -match [regex]::Escape('ZZ-NEWLY-WRITTEN-PAGE.md')) 'scenario 33: the finding names the file that no line of the scan set mentions'
    Assert-True ($r33.Out -match 'scope') 'scenario 33: and it is the scope rule that catches it'
    # The same file is a subject for check 12 as well, which is the half that would fail if the widening
    # had been applied to only one of the two checks that share $linkFiles.
    [System.IO.File]::WriteAllText($s33Path, ((@('# Still unnamed', '') + (@($rqFull) -replace ' \$\(\$_\.gitCommitSha\)', '')) -join "`n") + "`n", $Utf8NoBom)
    $r33b = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r33b.Out -match [regex]::Escape('ZZ-NEWLY-WRITTEN-PAGE.md') + ".*does not name 'gitCommitSha'") 'scenario 33: check 12 reaches the same unnamed file'
    Remove-Item -LiteralPath $s33Path -Force
    # And the removal is itself asserted, so a later scenario cannot inherit a stray subject from this one.
    $r33c = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r33c.Out -match [regex]::Escape('ZZ-NEWLY-WRITTEN-PAGE.md'))) 'scenario 33: the fixture is left as it was found'

    # --- Scenario 34: check 13, entry heading levels (this repo's own defect, four times in one day) ---
    #     An entry body used a sub-heading at the entry's own level, so the two became siblings: after the
    #     fold CHANGELOG.md carried headings with no PR number, and the release renderer split an entry on
    #     every one of them, shipping "entries" with no number, no type and no Plugins line. Rendall's lens
    #     warned about it and the warning did not stop it, which is the whole argument for a gate: the rule
    #     is exactly checkable.
    #
    #     REWRITTEN FOR THE FLAT CHANGELOG (August 5, 2026). An entry is an H2 with three named H3 sections,
    #     so the forbidden levels moved up by one AND a second, new rule joined them: a heading AT the
    #     section level that is not one of the declared sections. Both halves are asserted here, and so is
    #     the case that must stay silent -- the three real section headings, which the pre-flat version of
    #     this check would have reported as three defects each.
    $s34Md = [char]0x00B7
    $s34Sections = @(
        '### What does this change do?'
        ''
        'A body with a correctly demoted sub-heading.'
        ''
        '#### Tested'
        ''
        'All green.'
        ''
        '### Who is this for'
        ''
        '| Tier | Significance | Why |'
        '|---|---|---|'
        '| 0 | - | - |'
        ''
        '### Type of change'
        ''
        'Fix'
    )
    Write-Host 'check 13 -- an entry is an H2 with three named H3 sections, and a body heading may be neither' -ForegroundColor Cyan
    $s34Entry = Join-Path $Fixture 'fix-a-branch-name.md'
    $s34Good = @('## A fixture entry') + @('') + $s34Sections
    [System.IO.File]::WriteAllText($s34Entry, (($s34Good -join "`n") + "`n"), $Utf8NoBom)
    $r34a = Invoke-Integrity -FixtureRoot $Fixture
    # THE ASSERT THAT MATTERS MOST HERE, because the whole entry format would trip a level-only rule: the
    # three declared section headings sit at the section level BY DESIGN and must be silent, while the
    # '####' sub-heading inside one of them is the ordinary accepted case.
    Assert-True (-not ($r34a.Out -match 'entry-heading.*fix-a-branch-name')) 'scenario 34: the three declared H3 sections plus a "####" sub-heading are accepted'
    Assert-True ($r34a.Out -match '\[entry-heading\] checked') 'scenario 34: and the entry file WAS examined -- the pass is not an empty scan'
    Assert-True ($r34a.Out -match '\[entry-heading\].*1 unfolded entry file\(s\)') 'scenario 34: an H2 entry file is RECOGNISED as one -- the detector was H3-only until August 5, 2026, so this check silently judged nothing'

    # Defect one: a heading at the entry's own level inside the body. This is the old '### Tested' defect,
    # one level up, and now the worse one -- it becomes a separate entry rather than a stray sub-heading.
    $s34Bad = @($s34Good) -replace '^#### Tested$', '## Tested'
    [System.IO.File]::WriteAllText($s34Entry, (($s34Bad -join "`n") + "`n"), $Utf8NoBom)
    $r34b = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r34b.Out -match 'entry-heading.*fix-a-branch-name\.md:7') 'scenario 34: an H2 in an entry body is reported, with its line number'
    Assert-True ($r34b.Out -match 'SEPARATE entry') 'scenario 34: and the message says WHY, by naming the consequence at fold time'
    Assert-True ($r34b.Out -match 'undeclared tier 0') 'scenario 34: including what the phantom entry declares -- nothing'

    # Defect two, new with the format: a heading at the SECTION level that is not a declared section. The
    # dangerous version of this is a MISSPELLED section heading, which costs the entry its declaration
    # silently -- so the fixture uses exactly that rather than an obviously unrelated word.
    $s34Typo = @($s34Good) -replace '^### Who is this for$', '### Who is this For'
    [System.IO.File]::WriteAllText($s34Entry, (($s34Typo -join "`n") + "`n"), $Utf8NoBom)
    $r34c = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r34c.Out -match 'entry-heading.*fix-a-branch-name\.md:11') 'scenario 34: a misspelled section heading is reported, with its line'
    Assert-True ($r34c.Out -match 'not one of them') 'scenario 34: and the message lists the sections that ARE declared'
    Assert-True ($r34c.Out -match 'loses that declaration') 'scenario 34: naming the silent cost rather than only the rule'

    # Fence-aware: an entry that QUOTES a heading is discussing structure, not creating it -- the
    # mention-versus-use question this file answers in four other checks, and one this repo's own entry
    # files do (the entry for this very change quotes the format).
    $s34Fenced = @(
        '## A fixture entry'
        ''
        '### What does this change do?'
        ''
        'The wrong form looks like this:'
        ''
        '```markdown'
        '## Tested'
        '### Who is this For'
        '```'
        ''
        '### Who is this for'
        ''
        '| Tier | Significance | Why |'
        '|---|---|---|'
        '| 0 | - | - |'
        ''
        '### Type of change'
        ''
        'Fix'
    )
    [System.IO.File]::WriteAllText($s34Entry, (($s34Fenced -join "`n") + "`n"), $Utf8NoBom)
    $r34d = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r34d.Out -match 'entry-heading.*fix-a-branch-name')) 'scenario 34: both fenced examples are mentions, not uses -- neither level is reported'

    # A PRE-FORMAT entry file, which is not history: an entry file lives only on a branch, so a branch
    # created before the format changed still carries an H3 heading, and this repo had one parked on the
    # remote the day the format landed. It must still be RECOGNISED (line 1 is skipped whatever its level,
    # because the fold promotes it) while its body is judged by the same rules.
    $s34Legacy = @(
        '### An older entry ' + $s34Md + ' Fix ' + $s34Md + ' 2026-08-01'
        ''
        'Body prose.'
        ''
        '## Not allowed here either'
    )
    [System.IO.File]::WriteAllText($s34Entry, (($s34Legacy -join "`n") + "`n"), $Utf8NoBom)
    $r34e = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r34e.Out -match '\[entry-heading\].*1 unfolded entry file\(s\)') 'scenario 34: a pre-format H3 entry file is still recognised as an entry file'
    Assert-True ($r34e.Out -match 'entry-heading.*fix-a-branch-name\.md:5') 'scenario 34: and its body is judged by the same rules'
    Assert-True (-not ($r34e.Out -match 'fix-a-branch-name\.md:1')) 'scenario 34: while its own H3 heading on line 1 is NOT reported -- that is the entry, and the fold promotes it'
    Remove-Item -LiteralPath $s34Entry -Force

    # The CHANGELOG half, which is what cut-release actually parses -- and the half that catches damage
    # arriving through the fold, the one write that happens directly on main past every PR gate.
    $s34Cl = Join-Path $Fixture 'CHANGELOG.md'
    $s34ClGood = @(
        '# Changelog'
        ''
        'Everything merged since the last release, furthest reach first.'
        ''
        '## #123 ' + $s34Md + ' A real entry'
        ''
    ) + $s34Sections + @('')
    [System.IO.File]::WriteAllText($s34Cl, (($s34ClGood -join "`n") + "`n"), $Utf8NoBom)
    $r34f = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r34f.Out -match 'entry-heading. CHANGELOG')) 'scenario 34: a well-formed flat changelog is silent'

    # A body sub-heading written at the entry's own level, in the middle of a formatted entry. It SPLITS the
    # entry: the three sections land across two blocks, so the phantom's first section is whichever one
    # followed it -- never the first. That is the rule, and it is structural rather than a guess about intent.
    $s34ClStray = @($s34ClGood) -replace '^#### Tested$', '## Tested'
    [System.IO.File]::WriteAllText($s34Cl, (($s34ClStray -join "`n") + "`n"), $Utf8NoBom)
    $r34g = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r34g.Out -match 'entry-heading. CHANGELOG\.md:11') 'scenario 34: a body heading at the entry level is reported, with its line'
    Assert-True ($r34g.Out -match 'has been SPLIT') 'scenario 34: and the message names what happened to the entry rather than only the rule'
    Assert-True ($r34g.Out -match "first named section is 'Who is this for'") 'scenario 34: quoting the section it starts at, which is the evidence'

    # THE FALSE POSITIVE THIS AVOIDS, and it is the reason the rule is not simply "an H2 needs a #NN": the
    # fold cannot reach gh on a manual merge, and then it writes a legitimate entry with no number and no PR
    # footer, saying so on the console. Keying on the number would report the fold's own documented output as
    # a defect.
    $s34ClNoPr = @($s34ClGood) -replace ('^## #123 ' + [regex]::Escape($s34Md) + ' A real entry$'), '## A real entry with no PR number'
    [System.IO.File]::WriteAllText($s34Cl, (($s34ClNoPr -join "`n") + "`n"), $Utf8NoBom)
    $r34h = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r34h.Out -match 'entry-heading. CHANGELOG')) 'scenario 34: an entry with no PR number but with its sections is accepted -- the manual-merge fold'

    # A PRE-FORMAT entry, which is the second legitimate shape: no sections at all, the type carried as a
    # heading field. Every entry this repo folded before August 5, 2026 looks like this, and so does anything
    # folded from a branch that predates the format -- so reporting it would fire on real history.
    $s34ClLegacy = @(
        '# Changelog'
        ''
        'Intro.'
        ''
        '## #99 ' + $s34Md + ' An entry from before the format ' + $s34Md + ' Fix ' + $s34Md + ' 2026-08-01'
        ''
        'Body prose, no named sections.'
        ''
        '#### A properly demoted sub-heading'
        ''
        'More prose.'
        ''
    )
    [System.IO.File]::WriteAllText($s34Cl, (($s34ClLegacy -join "`n") + "`n"), $Utf8NoBom)
    $r34k = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r34k.Out -match 'entry-heading. CHANGELOG')) 'scenario 34: a pre-format entry declaring its type in the heading is accepted -- no sections required of it'

    # THE PLACEMENT NEITHER RULE CATCHES ALONE, and the reason the check has two: a stray heading directly
    # BELOW the entry heading keeps all three sections in its own block, so the first rule sees a well-formed
    # entry. What gives it away is the entry ABOVE it, now sectionless -- and a current-format heading carries
    # no type field, so the type rule reports that one. The error lands on the real entry rather than on the
    # stray, which is why the message names both possibilities instead of asserting which it found.
    $s34ClAbsorbed = @(
        '# Changelog'
        ''
        'Intro.'
        ''
        '## #123 ' + $s34Md + ' A real entry'
        ''
        '## A sub-heading that swallowed the entry'
        ''
    ) + $s34Sections + @('')
    [System.IO.File]::WriteAllText($s34Cl, (($s34ClAbsorbed -join "`n") + "`n"), $Utf8NoBom)
    $r34l = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r34l.Out -match 'entry-heading. CHANGELOG\.md:5') 'scenario 34: a stray heading directly below an entry heading is caught via the entry it emptied'
    Assert-True ($r34l.Out -match 'declares neither its named sections nor a change type') 'scenario 34: and the message states exactly what is missing'
    Assert-True ($r34l.Out -match 'absorbed by such a heading directly below it') 'scenario 34: naming the second possibility, since the error lands on the victim rather than the cause'

    # An H1 below the intro, and a stray section-level heading, in one document -- so the assert on the
    # second one also proves the scan did not stop at the first. The pre-flat check keyed its boundary on a
    # heading NAME and had to reason carefully about not ending the scan at the very defect it looked for;
    # the boundary is structural now, so the scan simply runs to the end of the file.
    $s34ClMixed = @(
        '# Changelog'
        ''
        'Intro.'
        ''
        '## #123 ' + $s34Md + ' A real entry'
        ''
        '### What does this change do?'
        ''
        '# A body heading that climbs above every entry'
        ''
        '### Tested'
        ''
        '### Type of change'
        ''
        'Fix'
        ''
    )
    [System.IO.File]::WriteAllText($s34Cl, (($s34ClMixed -join "`n") + "`n"), $Utf8NoBom)
    $r34i = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($r34i.Out -match 'entry-heading. CHANGELOG\.md:9') 'scenario 34: an H1 below the intro is reported'
    Assert-True ($r34i.Out -match 'climbs above every entry') 'scenario 34: and the message names the consequence in the document'
    Assert-True ($r34i.Out -match 'entry-heading. CHANGELOG\.md:11') 'scenario 34: and the stray section heading AFTER it is still reported -- the scan did not stop'

    # A changelog with no entry at all is the normal state between a release and the next merge: not judged
    # and not an error. Stated as an assert because "reports nothing" and "found nothing to report" look
    # identical from the outside, and the coverage line is what distinguishes them.
    [System.IO.File]::WriteAllText($s34Cl, "# Changelog`n`nNothing merged since the last release.`n", $Utf8NoBom)
    $r34j = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r34j.Out -match 'entry-heading. CHANGELOG')) 'scenario 34: an entry-less changelog is not an error -- that is the state right after a release'
    Remove-Item -LiteralPath $s34Cl -Force

    # Leaves the fixture with a history-only mention again, which the coverage block below relies on.
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'CONTRIBUTING.md'), (($s24Contributing -join "`n") + "`n"), $Utf8NoBom)

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
    # Scenario 24 left the fixture with only a history mention, so this category is legitimately empty
    # here -- and an empty lifecycle scan is exactly the state a reader must not mistake for "the docs
    # are right", so it states its own reason like the lens category does.
    Assert-True ($rc.Out -match '\[lifecycle\] checked 0 -- no printed lifecycle command') `
        'coverage: an empty lifecycle scan says WHY it is empty, so "nothing to enforce" cannot read as "nothing wrong"'
    # Coverage is context, never a finding: it must not move the exit code or manufacture an error.
    # Scenario 16 left the fixture with a real finding, so this run legitimately exits 1 -- what is
    # asserted here is that no coverage line was itself counted as one.
    Assert-True (-not ($rc.Out -match '(?m)^\s*\[COVERAGE\]')) `
        'coverage: the token is the category name, not a literal [COVERAGE] tag -- one line per category, no extra noise'

    # --- check 15: a captured output sample must say what it is bound to ----------------------------
    # The class behind four of test round v11's nine findings. Each case below is one of the two ways
    # this check can fail badly: missing a real unbound sample, or firing on something that is not one.
    # The false-positive half is not optional politeness -- a gate that cries wolf gets an opt-out
    # pasted over every finding and then reports green while asserting nothing.
    # IN plugins/, NOT THE ROOT, because that is where the three consumer-facing documents now live and
    # $consumerDocs is read as a path rather than a bare name. The check Test-Path-skips an entry it
    # cannot find, in silence -- so a fixture writing to the old location would leave every assertion
    # below passing over a document the check never opened.
    $qsDir = Join-Path $Fixture 'plugins'
    if (-not (Test-Path -LiteralPath $qsDir)) { New-Item -ItemType Directory -Path $qsDir -Force | Out-Null }
    $qs = Join-Path $qsDir 'INSTALL.md'
    # Fence and box drawing from codepoints, never as literals. The first version wrote the fence
    # literally and silently produced an opening fence with the language on the NEXT line, so the
    # "a command block is not examined" case was testing a language-less block and failing for a
    # reason that had nothing to do with the check. Same discipline as fix-mojibake's ASCII-only
    # source, and for the same class of reason.
    #
    # AND EVERY '$fence + <lang>' BELOW IS PARENTHESISED, which is not style. In PowerShell the comma
    # binds TIGHTER than '+', so @('a', $fence + 'powershell', 'b') parses as ('a', $fence) +
    # ('powershell', 'b') -- four elements, and the language lands on its own line. That is what
    # actually broke the command-block case, twice, while the check under test was correct throughout.
    $bt    = [string][char]0x60
    $fence = $bt + $bt + $bt
    $tree  = 'repo/' + "`n" + [char]0x251C + [char]0x2500 + ' CLAUDE.md'

    # 1. THE FINDING: output quoted with nothing saying what it came from.
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'The closing line reads:', '', $fence,
        'Done: 4 created, 0 already present.', $fence, '', 'Compare it against yours.'
    ) -join "`n", $Utf8NoBom)
    $s1 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($s1.Out -match '\[expected-output\].*INSTALL\.md') `
        'expected-output: an output sample with no stated binding is reported'
    Assert-True ($s1.Out -match 'expected-output. checked [1-9]') `
        'expected-output: and the coverage line counts samples examined, not check runs'

    # 2. BOUND, three ways -- a version, a date, and a hedge. Each must clear it on its own.
    foreach ($binding in @('Measured on CLI 2.1.220.', 'Measured on 1 August 2026.', 'This varies by repo.')) {
        [System.IO.File]::WriteAllText($qs, @(
            '# Quickstart', '', 'The closing line reads:', '', $fence,
            'Done: 4 created, 0 already present.', $fence, '', $binding
        ) -join "`n", $Utf8NoBom)
        $s2 = Invoke-Integrity -FixtureRoot $Fixture
        Assert-True (-not ($s2.Out -match '\[expected-output\].*INSTALL\.md')) `
            "expected-output: a sample bound by '$binding' passes"
    }

    # 3. A COMMAND IS NOT A SAMPLE. Tagged blocks are things to run; they cannot go stale under a reader
    #    the way a captured transcript can.
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'Run this:', '', ($fence + 'powershell'),
        'claude plugin install specialists@claude-code-specialists --scope project', $fence
    ) -join "`n", $Utf8NoBom)
    $s3 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($s3.Out -match '\[expected-output\].*INSTALL\.md')) `
        'expected-output: a powershell block is a command to run, not examined'

    # 4. A DIAGRAM IS DRAWN, NOT CAPTURED. The check's first real false positive, on the seam diagram in
    #    the root README.
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'The shape is:', '', ($fence + 'text'), $tree, $fence
    ) -join "`n", $Utf8NoBom)
    $s4 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($s4.Out -match '\[expected-output\].*INSTALL\.md')) `
        'expected-output: a box-drawing diagram is not a captured sample'

    # 5. THE OPT-OUT HAS TO NAME A REASON. A bare marker must not silence the check, or the escape hatch
    #    becomes the way the gate is defeated rather than the way an exception is recorded.
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'Reads:', '', $fence, 'Done: 4 created.', $fence, '', '<!-- unbound-sample: -->'
    ) -join "`n", $Utf8NoBom)
    $s5 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($s5.Out -match '\[expected-output\].*INSTALL\.md') `
        'expected-output: an opt-out marker with no reason does not silence the check'
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'Reads:', '', $fence, 'Done: 4 created.', $fence, '',
        '<!-- unbound-sample: invented for the test fixture, bound to nothing real -->'
    ) -join "`n", $Utf8NoBom)
    $s6 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($s6.Out -match '\[expected-output\].*INSTALL\.md')) `
        'expected-output: an opt-out that names a reason does silence it'

    # --- check 16: a measured figure in prose names what it was measured on -------------------------
    # Check 15's class, one step outside its reach: the same staleness, in running prose where there is
    # no fence to mark it. Test round v12's #374 and its unfiled twin one section down. The cases below
    # are again the two ways this fails badly -- missing a real unbound figure, and firing on something
    # that is not one -- plus the three design decisions that could otherwise erode silently: the window
    # is bounded, a fence belongs to check 15, and 'measured' is not a binding.

    # 1. THE FINDING: a byte count with nothing saying whose machine it came from.
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'After the teardown the file is 288 bytes and holds nothing of ours.'
    ) -join "`n", $Utf8NoBom)
    $f1 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($f1.Out -match '\[measured-figure\].*INSTALL\.md') `
        'measured-figure: a byte count in prose with no stated binding is reported'
    Assert-True ($f1.Out -match 'measured-figure. checked [1-9]') `
        'measured-figure: and the coverage line counts figures examined, not check runs'

    # 2. BOUND, five ways -- a date, a test round, a version, a named profile state, and a hedge. Each
    #    must clear it on its own, because a writer will reach for whichever one fits the sentence.
    foreach ($binding in @(
        'Measured on 1 August 2026.', 'Measured in round v12.', 'Measured on CLI 2.1.220.',
        'Measured on a virgin profile.', 'The figure varies by platform.'
    )) {
        [System.IO.File]::WriteAllText($qs, @(
            '# Quickstart', '', "After the teardown the file is 288 bytes. $binding"
        ) -join "`n", $Utf8NoBom)
        $f2 = Invoke-Integrity -FixtureRoot $Fixture
        Assert-True (-not ($f2.Out -match '\[measured-figure\].*INSTALL\.md')) `
            "measured-figure: a figure bound by '$binding' passes"
    }

    # 3. THE WINDOW REACHES THE NEIGHBOURING BLOCKS, IN BOTH DIRECTIONS. A table row is bound by the
    #    paragraph introducing the table (the #339 table) or by the note underneath it saying which
    #    column came from where (the bracket table). Neither binding sits on the row itself, and a
    #    line-count window would have to guess how many rows the table has.
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'Measured on a virgin profile, 1 August 2026:', '',
        '| file | size |', '|---|---|', '| settings.json | 288 bytes |'
    ) -join "`n", $Utf8NoBom)
    $f3 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($f3.Out -match '\[measured-figure\].*INSTALL\.md')) `
        'measured-figure: a binding in the paragraph ABOVE a table binds its rows'
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'The sizes:', '',
        '| file | size |', '|---|---|', '| settings.json | 288 bytes |', '',
        'The right-hand column is round v12.'
    ) -join "`n", $Utf8NoBom)
    $f4 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($f4.Out -match '\[measured-figure\].*INSTALL\.md')) `
        'measured-figure: a binding in the paragraph BELOW a table binds its rows too'

    # 4. AND IT STOPS THERE. A binding two blocks away does NOT count -- otherwise the gate is satisfied
    #    by a date in an unrelated subsection, which is how a window quietly becomes section-wide.
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'Measured on a virgin profile, 1 August 2026.', '',
        'An unrelated paragraph sits in between.', '', 'The file is 288 bytes.'
    ) -join "`n", $Utf8NoBom)
    $f5 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($f5.Out -match '\[measured-figure\].*INSTALL\.md') `
        'measured-figure: a binding two blocks away is out of reach -- the window is bounded'

    # 5. A FENCED FIGURE BELONGS TO CHECK 15. Counting it here would report one sample as two findings,
    #    and would flag verbatim command output that is deliberately reproduced.
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'Measured in round v12, the output reads:', '', ($fence + 'text'),
        'known_marketplaces.json  288 bytes', $fence
    ) -join "`n", $Utf8NoBom)
    $f6 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($f6.Out -match '\[measured-figure\] checked 0') `
        'measured-figure: a figure inside a fence is check 15''s, and is not counted twice'

    # 6. 'measured' ON ITS OWN IS NOT A BINDING. It says the author saw the number, which was true of
    #    every finding this check exists for. Same rejection as check 15 makes, and for the same reason.
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'The clone is deleted (measured: 288 bytes, gone).'
    ) -join "`n", $Utf8NoBom)
    $f7 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($f7.Out -match '\[measured-figure\].*INSTALL\.md') `
        'measured-figure: the word ''measured'' alone does not bind a figure'

    # 7. NOT EVERY 'byte' IS A FIGURE. 'byte-identical' is a word, and a check that flagged it would be
    #    training writers to paste opt-outs over prose. The leading digit is what makes it a measurement.
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'The install leaves the file byte-identical, so the diff is empty.'
    ) -join "`n", $Utf8NoBom)
    $f8 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($f8.Out -match '\[measured-figure\] checked 0') `
        'measured-figure: ''byte-identical'' carries no number and is not a figure'

    # 8. THE OPT-OUT HAS TO NAME A REASON, exactly as check 15's does.
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'The file is 288 bytes.', '', '<!-- unbound-figure: -->'
    ) -join "`n", $Utf8NoBom)
    $f9 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($f9.Out -match '\[measured-figure\].*INSTALL\.md') `
        'measured-figure: an opt-out marker with no reason does not silence the check'
    [System.IO.File]::WriteAllText($qs, @(
        '# Quickstart', '', 'The file is 288 bytes.', '',
        '<!-- unbound-figure: invented for the test fixture, bound to nothing real -->'
    ) -join "`n", $Utf8NoBom)
    $f10 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($f10.Out -match '\[measured-figure\].*INSTALL\.md')) `
        'measured-figure: an opt-out that names a reason does silence it'

    # --- check 17: the per-plugin CHANGELOG intro still matches its generator ------------------------
    # THE DEFECT THIS SHIPPED WITH, MEASURED August 3, 2026: cut-release.ps1 writes the intro only for a
    # CHANGELOG that does not exist yet, so all four real files still opened by naming the marketplace the
    # rename had retired -- in the most consumer-facing file each plugin has, past every existing gate.
    # The fixture needs a marketplace.json for these (the expected text is derived from its 'name'), which
    # also switches checks 1/2/9 from "found nothing" to "found something incomplete". That extra noise is
    # never asserted on below, exactly as the suite's other checks treat check 8's missing-mirror noise.
    Write-Host "check 17: per-plugin CHANGELOG intro vs. Build-PluginChangelogIntro" -ForegroundColor Cyan
    [System.IO.File]::WriteAllText($qs, "# Quickstart`n", $Utf8NoBom)
    New-Item -ItemType Directory -Path (Join-Path $Fixture '.claude-plugin') -Force | Out-Null
    $mpPath = Join-Path $Fixture '.claude-plugin\marketplace.json'
    $plChangelog = Join-Path $Fixture 'plugins\specialists\CHANGELOG.md'
    function Set-FixtureMarketplaceName([string]$Name) {
        [System.IO.File]::WriteAllText($mpPath,
            ('{{ "name": "{0}", "plugins": [ {{ "name": "specialists", "source": "./plugins/specialists" }} ] }}' -f $Name),
            $Utf8NoBom)
    }
    # The generator is the authority on the expected text here too -- writing the sentences out by hand
    # would make this suite a second copy of the very string whose copies are the defect.
    . (Join-Path $Fixture 'scripts\lib\release-lib.ps1')
    function Write-FixturePluginChangelog([string]$MarketplaceName, [string]$Tail = "## v1.0.0 - 2026-01-01`n`nAn entry.`n") {
        [System.IO.File]::WriteAllText($plChangelog,
            ((Build-PluginChangelogIntro -PluginName 'specialists' -MarketplaceName $MarketplaceName) + $Tail),
            $Utf8NoBom)
    }

    # 33. The generated intro passes -- and the coverage count proves the file WAS examined, so the pass
    #     is not an empty scan (the failure mode #221 made every category report its count for).
    Set-FixtureMarketplaceName 'fixture-marketplace'
    Write-FixturePluginChangelog 'fixture-marketplace'
    $g1 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($g1.Out -match '\[changelog-intro\] checked 1') `
        'changelog-intro: the intro is examined, so a pass is evidence rather than an empty scan'
    Assert-True (-not ($g1.Out -match '\[changelog-intro\] \.')) `
        'changelog-intro: an intro matching its generator reports nothing'

    # 34. (THE MEASURED DEFECT) an intro naming a marketplace that marketplace.json does not is reported.
    Write-FixturePluginChangelog 'the-retired-name'
    $g2 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($g2.Out -match '\[changelog-intro\] \./plugins/specialists/CHANGELOG\.md') `
        'changelog-intro: an intro naming a retired marketplace fails, naming the file'
    Assert-True ($g2.Out -match 'fixture-marketplace') `
        'changelog-intro: the finding states the expected text, so the repair needs no second lookup'

    # 35. (THE GUARD THAT KEEPS THIS FROM BECOMING A WRAPPING POLICE) the same sentences, rewrapped at a
    #     different column, pass. A gate failing on layout would teach "rewrap to satisfy the linter"
    #     about a file no human should be rewrapping by hand.
    #     Derived from the generated text rather than retyped: the title carries an em dash built via
    #     [char]0x2014, and this suite is pure ASCII (repo convention for .ps1). Retyping it with a plain
    #     hyphen was this scenario's first failure -- a content difference masquerading as a layout one,
    #     which would have "proved" the opposite of what the case is for.
    $genLines = @(((Build-PluginChangelogIntro -PluginName 'specialists' -MarketplaceName 'fixture-marketplace').TrimEnd() -split "`n"))
    $titleLine = $genLines[0]
    $paragraph = (@($genLines[1..($genLines.Count - 1)]) -join ' ').Trim()   # the whole paragraph on ONE line
    [System.IO.File]::WriteAllText($plChangelog,
        ($titleLine + "`n`n" + $paragraph + "`n`n## v1.0.0 - 2026-01-01`n`nAn entry.`n"),
        $Utf8NoBom)
    $g3 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($g3.Out -match '\[changelog-intro\] \./plugins/specialists/CHANGELOG\.md')) `
        'changelog-intro: rewrapping the same sentences is not a finding -- content is compared, layout is not'

    # 36. A file with no version heading is REPORTED, not silently skipped: the intro's end cannot be
    #     located, so the check cannot assert anything -- and a check that quietly asserts nothing is the
    #     failure mode this whole gate exists to avoid.
    [System.IO.File]::WriteAllText($plChangelog, "# Changelog - specialists`n`nSomething hand-written.`n", $Utf8NoBom)
    $g4 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($g4.Out -match "\[changelog-intro\] \./plugins/specialists/CHANGELOG\.md: no '## vX\.Y\.Z' heading") `
        'changelog-intro: a file whose intro has no end boundary is reported rather than skipped in silence'

    # 37. (THE DESIGN, NOT A BUG GUARD) the expected name comes from marketplace.json's 'name', never from
    #     a literal in the gate. Renaming the marketplace in the fixture manifest -- and nothing else --
    #     must flip the SAME file from failing to passing. Without this case the check could carry its own
    #     hardcoded copy of the name and every scenario above would still pass, which is precisely the
    #     shape of the defect it is here to catch.
    Write-FixturePluginChangelog 'renamed-marketplace'
    $g5 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($g5.Out -match '\[changelog-intro\] \./plugins/specialists/CHANGELOG\.md') `
        'changelog-intro: an intro ahead of the manifest fails while the manifest still says the old name'
    Set-FixtureMarketplaceName 'renamed-marketplace'
    $g6 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($g6.Out -match '\[changelog-intro\] \./plugins/specialists/CHANGELOG\.md')) `
        'changelog-intro: renaming the marketplace in the manifest alone makes that same file pass -- the expected text is derived, not hardcoded'

    # --- check 18: a shared script's parameters must appear in the skill that documents it ------------
    # THE MEASURED DEFECT, August 4, 2026: the fold-changelog skill told consumers to commit the fold BY
    # HAND for two days after the script gained -Commit/-Push, because that improvement went into this
    # repo's lens. Looking for siblings found four more, including cut-release's -Bump and -NoPush.
    #
    # park-branch is the fixture's subject: one parameter (-Intent), one skill (park), so the scenario
    # exercises the mapping rather than a script's complexity. Both directions are asserted, because a
    # positive-only test would pass against a check that examines nothing at all.
    Write-Host "check 18: shared-script parameters vs. their skill" -ForegroundColor Cyan
    $parkSrc   = Join-Path $Fixture 'scripts\task\park-branch.ps1'
    $parkSkill = Join-Path $Fixture 'plugins\specialists\skills\park\SKILL.md'
    New-Item -ItemType Directory -Path (Split-Path -Parent $parkSrc) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent $parkSkill) -Force | Out-Null
    # A real param block, so the AST reader is what is being exercised -- not a string the test planted.
    [System.IO.File]::WriteAllText($parkSrc, "param([string]`$Intent)`nWrite-Host 'fixture'`n", $Utf8NoBom)

    # 38. A skill that never names the parameter is reported, naming the script and the parameter.
    [System.IO.File]::WriteAllText($parkSkill, "# park`n`nParks the current branch. No options described.`n", $Utf8NoBom)
    $s1 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($s1.Out -match '\[skill-param\].*park-branch\.ps1.*-Intent') `
        'skill-param: an undocumented parameter is reported, naming both the script and the parameter'
    Assert-True ($s1.Out -match '\[skill-param\] checked [1-9]') `
        'skill-param: the coverage count proves a parameter was actually examined, not an empty scan'

    # 39. Documenting it in the skill -- and changing nothing else -- makes the same file pass.
    [System.IO.File]::WriteAllText($parkSkill, "# park`n`nParks the current branch. Use ``-Intent`` to record where you left off.`n", $Utf8NoBom)
    $s2 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($s2.Out -match '\[skill-param\].*park-branch\.ps1')) `
        'skill-param: naming the parameter in the skill alone clears the finding'

    # 40. (THE FIXTURE-QUIET GUARD) a registered script that does not exist in this tree is skipped
    #     rather than reported as a missing skill. Check 8 already reports the missing source, and
    #     duplicating that here would have made this check fire on every scenario above it -- which is
    #     exactly what the first version of it did.
    Assert-True (-not ($s2.Out -match '\[skill-param\].*cut-release\.ps1')) `
        'skill-param: a registered script absent from the tree is skipped, not reported (check 8 owns that finding)'

    # 41. The coverage line names what it could NOT cover, rather than reading as complete -- the
    #     no-silent-caps rule. A registered script declaring Skill = '' must be listed by name.
    #     check-script-contract is the subject because its '' is a deliberate "no procedure to write
    #     down" (it runs from a hook), so the fixture only needs it to EXIST to reach the gaps list.
    #     Note this had to be a script present in the tree: scenario 40's skip fires first otherwise,
    #     which is why asserting on ship-pr here failed -- the fixture has no ship-pr.ps1.
    $contractStub = Join-Path $Fixture 'scripts\sync\check-script-contract.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $contractStub) -Force | Out-Null
    [System.IO.File]::WriteAllText($contractStub, "Write-Host 'fixture'`n", $Utf8NoBom)
    $s3 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($s3.Out -match '\[skill-param\].*NOT covered.*check-script-contract') `
        'skill-param: the coverage line names an entry point that declares no skill'
    Assert-True (-not ($s3.Out -match '\[skill-param\] scripts\\sync\\check-script-contract')) `
        'skill-param: and declaring no skill is coverage, not an error -- writing a missing skill is separate work'

    # --- check 19: a named consumer-facing document that is not there ------------------------------
    # 42. THE SILENT-COVERAGE CASE. Checks 15 and 16 open each $consumerDocs entry with a Test-Path
    #     'continue', so a stale entry costs coverage and says nothing. Measured August 6, 2026, moving
    #     those documents into plugins/: expected-output went 5 -> 1 and measured-figure 11 -> 0 in one
    #     commit, no error anywhere, and it surfaced only because somebody read the coverage line.
    #     The fixture never creates plugins/UNINSTALL.md, so the entry is genuinely absent here.
    $s4 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($s4.Out -match '\[consumer-doc\].*UNINSTALL\.md') `
        'consumer-doc: a named document that does not exist is reported instead of skipped in silence'
    Assert-True ($s4.Out -match '\[consumer-doc\].*(update the list|drop the entry)') `
        'consumer-doc: and the finding names both repairs, since the list and the tree can each be the wrong one'

    # 43. AND THE REASON THIS ASSERT EXISTS AT ALL, which is not check 19's subject. Adding a finding
    #     used to depend on WHERE in the file you added it: sixteen bare '$errors += ...' lines rebuilt
    #     the List[string] as a fixed-size array, so the first Add-Error below the last of them threw
    #     "the collection is of a fixed size" and killed the run mid-scan. Check 19 sits below all of
    #     them and is therefore the canary: if the '+=' style ever comes back, this scenario stops
    #     reporting a finding and starts reporting an exception.
    Assert-True (-not ($s4.Out -match 'fixed size|vaste grootte')) `
        'consumer-doc: the run completes -- a finding raised after the last check does not hit a fixed-size collection'
    Assert-True ($s4.Out -match 'Summary: \d+ error') `
        'consumer-doc: and the summary is still reached, so the scan ended normally rather than dying mid-file'
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
