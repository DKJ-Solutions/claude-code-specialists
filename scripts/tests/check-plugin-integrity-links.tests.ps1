<#
.SYNOPSIS
    check-plugin-integrity.ps1, part 1 of 4: check 4 (the dead-link scan set), check 10 (the
    marked <!-- skills:all --> spans) and check 28 (the '@'-import targets), plus scenario 16 -- a root
    entry file is scanned before the fold.

.DESCRIPTION
    The fixture, the assert helpers and Invoke-Integrity live in check-plugin-integrity-fixture.ps1,
    which also records why this suite is four files. The scenario documentation that used to open the
    single file is kept where each scenario is, rather than as one index four files would have to
    share.

    Check 4 guards file-set COVERAGE rather than the scan engine: if the $linkFiles list is refactored
    and drops CONTRIBUTING.md, the connectors README or one of the four payload layers, that must fail
    loudly here. Check 10's fifteen scenarios cover the span mechanics, the fence masking in both
    directions, and the symmetric orphan-END sweep.

    Check 28 is check 4's sibling -- the same scan set, a different syntax -- and its scenarios pin the
    resolution rule (file-relative, NOT repo-root-relative) separately from both discriminators (a fenced
    '@(...)' and a prose line), because each can fail invisibly in the others' direction. One assert
    compares its coverage count against check 4's, so the two sets cannot silently drift apart.

    Test gap (honest, inherited from the single file): the anchor-slug logic and the full scan engine
    are not re-exercised here -- they are covered by the repo-wide lint smoke checks in
    agent-shared.tests.ps1 and bootstrap-drift.tests.ps1.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'check-plugin-integrity-fixture.ps1')

$Fixture = Join-Path ([System.IO.Path]::GetTempPath()) ("check-plugin-integrity-links-$PID")

try {
    New-IntegrityFixture -Fixture $Fixture

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

    # --- Scenario B2: the four payload layers added in #481 are IN the scan set ---------------------
    # Agent defs, agent-shared, .github and .claude/rules matched no category until August 6, 2026 --
    # 40 files, the largest of them the agent defs, which are the biggest body of prose this repo ships.
    # A real dead link had been sitting in one of them, seen by nothing. Each layer gets its own broken
    # link here rather than one shared assertion, because they are four separate rules and a single
    # combined check would pass while three of them were absent.
    Write-Host "check 4 coverage -- the payload layers (#481) are IN the scan set" -ForegroundColor Cyan
    $payloadTargets = @(
        @{ Rel = 'plugins\teams\team-alpha\agents\09-99-agent.md';   Label = 'an agent def' },
        @{ Rel = 'plugins\teams\agent-shared\fixture-block.md';  Label = 'a shared agent-def block' },
        @{ Rel = '.github\pull_request_template.md';             Label = 'a .github template' },
        @{ Rel = '.claude\rules\fixture-rule.md';                Label = 'a path-scoped rule' }
    )
    foreach ($pt in $payloadTargets) {
        $ptFull = Join-Path $Fixture $pt.Rel
        New-Item -ItemType Directory -Path (Split-Path -Parent $ptFull) -Force | Out-Null
        [System.IO.File]::WriteAllText($ptFull, "# Fixture`n`nSee [nope]($deadLink) for details.`n", $Utf8NoBom)
    }
    $b2 = Invoke-Integrity -FixtureRoot $Fixture
    foreach ($pt in $payloadTargets) {
        Assert-True ($b2.Out -match [regex]::Escape('.\' + $pt.Rel)) `
            ("payload scan: a dead link in $($pt.Label) is reported -- " + $pt.Rel)
    }
    Assert-True (-not ($b2.Out -match [regex]::Escape('NOTES.md'))) `
        'payload scan: the out-of-scope decoy is STILL not reported -- the four new rules are scoped, not a blanket walk'

    # And removing them again clears exactly those findings, so the assertions above are bound to the
    # files rather than to some other error the fixture happens to produce.
    foreach ($pt in $payloadTargets) { Remove-Item -LiteralPath (Join-Path $Fixture $pt.Rel) -Force }
    $b3 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($b3.Out -match [regex]::Escape('09-99-agent.md'))) `
        'payload scan: removing the agent def clears its finding -- the report tracked the file, not the fixture'

    # --- Scenario B4: the entry's links resolve from the REPO ROOT, not from branch/ ----------------
    # The entry file's text is pasted verbatim into CHANGELOG.md at the root, so its links have to work
    # there. Until the branch/ split it sat in the root and that held by construction; moving it one level
    # down turned every root-relative link in an entry into a dead one, measured on the first entry written
    # after the move. Both halves are asserted, because a fix that simply stopped scanning branch/ would
    # satisfy the first and lose the check entirely.
    Write-Host "check 4 coverage -- an entry's links are judged where the text LANDS" -ForegroundColor Cyan
    $entryDirFx = Join-Path $Fixture 'contributing-davekjohn\branch'
    New-Item -ItemType Directory -Path $entryDirFx -Force | Out-Null
    $entryFx    = Join-Path $entryDirFx 'branch-deployment.md'
    $progressFx = Join-Path $entryDirFx 'branch-cycle.md'
    # 'connectors/README.md' exists in this fixture and is root-relative -- exactly the shape an entry
    # writes, and exactly what resolving from contributing-davekjohn/branch/ would call dead.
    [System.IO.File]::WriteAllText($entryFx,
        "## Fixture entry`n`nSee [the connectors README](connectors/README.md) and [nope]($deadLink).`n", $Utf8NoBom)
    # The step list never travels, so it keeps the ordinary nested convention: '../../' to reach the root.
    [System.IO.File]::WriteAllText($progressFx,
        "# Branch progress`n`n**Branch:** ``feat/fixture```n`n## Steps`n`n- [ ] see [the connectors README](../../connectors/README.md)`n", $Utf8NoBom)

    $b4 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($b4.Out -match 'dead link ''connectors/README\.md''')) `
        'entry links: a root-relative link in the entry is NOT dead -- it is judged from the repo root, where the fold puts the text'
    Assert-True ($b4.Out -match [regex]::Escape('.\contributing-davekjohn\branch\branch-deployment.md') -and $b4.Out -match [regex]::Escape($deadLink)) `
        'entry links: a genuinely dead link in the entry IS still reported -- the rebase is not a way out of the check'
    Assert-True (-not ($b4.Out -match [regex]::Escape('.\contributing-davekjohn\branch\branch-cycle.md'))) `
        'entry links: the step list keeps the ordinary nested convention -- it never travels, so ../../ is correct there'

    Remove-Item -LiteralPath $entryFx, $progressFx -Force

    # --- Scenario B5: plugins/ is read WHOLE, and a file gathered twice is reported once -------------
    # Inbound #566. Every rule in the scan set names either a SHAPE of file (SKILL.md, *-manual.md,
    # */agents/*.md) or a PLACE it takes entirely (the root, branch/, releases/). A markdown file sitting at
    # plugin level matched neither, which is exactly where a plugin's own README.md lives -- the first page a
    # consumer reads. Five such files were in the tree, unread, when a sixth was added: a portable
    # contribution guide whose whole purpose is to be copied, and whose dead links would be copied with it.
    #
    # Both halves are asserted because each one alone is satisfiable by a wrong fix. Widening the glob
    # without deduping double-reports every file two rules now claim; deduping without widening leaves the
    # gap. And the decoy is asserted a third time: plugins/ being read whole must not become "every .md in
    # the tree", which is the property scenarios A and B2 already defend at their own boundaries.
    Write-Host "check 4 coverage -- a plugin-level document is IN the scan set, and counted once" -ForegroundColor Cyan
    $pluginDocTargets = @(
        @{ Rel = 'plugins\teams\team-alpha\README.md';         Label = "a plugin's own README (plugin level, no shape rule matches it)" },
        @{ Rel = 'plugins\teams\team-alpha\scripts\README.md'; Label = 'a README in a plugin subdirectory that no shape rule reaches' }
    )
    # The dedupe witness: an agent def is gathered by the */agents/*.md payload rule AND by the recursive
    # plugins/ glob. One dead link in it must produce exactly one [link] finding. Counted on LINES carrying
    # both the path and the [link] tag, because check 3 also names this file (no frontmatter) and a naive
    # match on the path alone would count that too.
    $dupWitnessRel = 'plugins\teams\team-alpha\agents\09-98-agent.md'
    foreach ($pd in @($pluginDocTargets.Rel + $dupWitnessRel)) {
        $pdFull = Join-Path $Fixture $pd
        New-Item -ItemType Directory -Path (Split-Path -Parent $pdFull) -Force | Out-Null
        [System.IO.File]::WriteAllText($pdFull, "# Fixture`n`nSee [nope]($deadLink) for details.`n", $Utf8NoBom)
    }
    $b5 = Invoke-Integrity -FixtureRoot $Fixture
    foreach ($pd in $pluginDocTargets) {
        Assert-True ($b5.Out -match [regex]::Escape('.\' + $pd.Rel)) `
            ("plugin-doc scan: a dead link in $($pd.Label) is reported -- " + $pd.Rel)
    }
    $dupHits = @(($b5.Out -split "`r?`n") | Where-Object { $_ -match [regex]::Escape($dupWitnessRel) -and $_ -match '\[link\]' })
    Assert-Equal 1 $dupHits.Count `
        'plugin-doc scan: a file gathered by two rules yields ONE dead-link finding -- the scan set is deduped, so widening a rule never double-reports'
    Assert-True (-not ($b5.Out -match [regex]::Escape('NOTES.md'))) `
        'plugin-doc scan: the out-of-scope decoy is STILL not reported -- plugins/ is read whole, the tree is not'

    # Removing them clears exactly those findings, so the assertions above are bound to these files rather
    # than to other noise this near-empty fixture produces.
    foreach ($pd in @($pluginDocTargets.Rel + $dupWitnessRel)) { Remove-Item -LiteralPath (Join-Path $Fixture $pd) -Force }
    Remove-Item -LiteralPath (Join-Path $Fixture 'plugins\teams\team-alpha\scripts') -Recurse -Force
    $b6 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($b6.Out -match [regex]::Escape('.\plugins\teams\team-alpha\README.md'))) `
        "plugin-doc scan: removing the plugin README clears its finding -- the report tracked the file, not the fixture"

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
    Assert-True ($r16.Out -match '\[entry-heading\].*1 unfolded entry\(ies\)') 'scenario 16: exactly ONE root file is read as an entry -- a permanent root doc is scanned but never judged as one'

    # And once the fold has taken it away, it simply drops out of the set again -- no stale reference,
    # no error about a file that no longer exists.
    Remove-Item -LiteralPath $entryPath -Force
    $r17 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($r17.Out -match [regex]::Escape('fix-my-branch.md'))) 'scenario 16: after the fold removes it, the entry file is gone from the set without complaint'

    # --- check 28: every '@'-import target resolves ----------------------------------------------------
    # 18-24. THE SIBLING OF CHECK 4, AND IT BELONGS IN THIS FILE FOR THAT REASON: it reads the same
    #        $linkFiles set and answers the same question about a different syntax. Issue #874.
    #
    #        What separates them is the COST OF BEING WRONG. A dead markdown link costs a reader one
    #        click; a dead '@'-import costs the session the WHOLE document, and nothing errors -- Claude
    #        Code drops an import it cannot resolve in silence, so the only symptom is a session behaving
    #        as if it had never read the layer that vanished. In this repo that layer is the safety rules
    #        or the roster.
    #
    #        The scenarios below pin the resolution rule and BOTH discriminators, because each of the
    #        three can fail on its own and each failure is invisible in the other two's direction: a
    #        check that resolved root-relative would pass every positive test in a root document and be
    #        wrong everywhere else, and a check without the discriminators would be born accusing correct
    #        files -- which is the shape this repo refuses on principle (see check 27's exemption note).
    Write-Host "check 28: '@'-import targets resolve" -ForegroundColor Cyan
    $impDir     = Join-Path $Fixture 'plugins\teams\team-alpha'
    $impProbe   = Join-Path $impDir 'import-probe.md'
    $impSibling = Join-Path $impDir 'import-sibling.md'
    [System.IO.File]::WriteAllText($impSibling, "# The sibling`n`nA target that exists.`n", $Utf8NoBom)

    # 18. A RESOLVING IMPORT IS SILENT, and the coverage line still reports a non-empty scan. Without the
    #     second half a check that examined nothing at all would pass this scenario.
    [System.IO.File]::WriteAllText($impProbe, "# The probe`n`n@import-sibling.md`n", $Utf8NoBom)
    $im1 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($im1.Out -match '\[import\].*import-probe')) `
        'import: a resolving import is not a finding'
    Assert-True ($im1.Out -match '\[import\] checked [1-9]') `
        'import: and the pass is not an empty scan'

    # 19. THE RESOLUTION RULE ITSELF, which is the one thing a second implementation would get wrong:
    #     an import resolves relative to the IMPORTING FILE's own directory, not to the repo root. The
    #     fixture root holds a CONTRIBUTING.md; this probe sits three levels down and must NOT find it.
    #     A root-relative reader passes scenario 18 and fails only here.
    [System.IO.File]::WriteAllText($impProbe, "# The probe`n`n@CONTRIBUTING.md`n", $Utf8NoBom)
    $im2 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True ($im2.Out -match '\[import\].*import-probe\.md:3') `
        'import: a target that exists at the REPO ROOT but not beside the importing file is dead -- the rule is file-relative'
    Assert-True ($im2.Code -ne 0) `
        'import: and it fails the gate -- a dropped import costs the session the whole document'
    Assert-True ($im2.Out -match 'importing file') `
        'import: and the finding states the base it resolved from, so the repair needs no source reading'

    # 20. A HOME-RELATIVE IMPORT IS COUNTED, NEVER REFUSED. SPECIALISTS.md imports the orchestrator's
    #     persona from the plugin marketplace clone under '~/', and CI is a machine with no clone. An
    #     error there would fail every PR for a correct file, so this assert is what keeps CI usable.
    [System.IO.File]::WriteAllText($impProbe,
        "# The probe`n`n@~/.claude/plugins/marketplaces/nothing-here/absent.md`n", $Utf8NoBom)
    $im3 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($im3.Out -match '\[import\].*import-probe')) `
        'import: a target outside the repo is not a finding -- CI has no marketplace clone'
    Assert-True ($im3.Out -match '1 outside the repo') `
        'import: but it is counted and named, so "no findings" does not mean "nothing was seen"'

    # 21. A FENCED '@(...)' IS POWERSHELL, NOT AN IMPORT. Seven of the twelve column-0 '@' lines in the
    #     real tree are exactly this, and check 4 already argues the case for links: illustrating a thing
    #     is not doing it.
    # Built from single-quoted parts and joined, so the fence delimiters are literal backticks rather
    # than an escape sequence three levels deep -- the readable form, and the one a later editor cannot
    # miscount.
    [System.IO.File]::WriteAllText($impProbe,
        ((@('# The probe', '', '```powershell', '@(Get-ChildItem .).Count', '```', '')) -join "`n"), $Utf8NoBom)
    $im4 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($im4.Out -match '\[import\].*import-probe')) `
        'import: a fenced PowerShell array expression is not an import'

    # 22. PROSE THAT WRAPS ONTO AN '@' IS NOT AN IMPORT EITHER, and this is the discriminator that keeps
    #     the check from being born with an exemption list. One line in the real tree needs it --
    #     releases/development/1.x/1.16.0.md, a paragraph that wraps onto '@-imported here (...)' -- and
    #     it sits in an archived note the language rule already exempts from repair. A target containing
    #     WHITESPACE is prose; the lib's parser takes the rest of the line, which is right for the
    #     always-on walk (it never meets prose) and wrong for a set that includes release history.
    [System.IO.File]::WriteAllText($impProbe,
        "# The probe`n`nA sentence that wraps onto`n@-imported here (which is prose, not a path).`n", $Utf8NoBom)
    $im5 = Invoke-Integrity -FixtureRoot $Fixture
    Assert-True (-not ($im5.Out -match '\[import\].*import-probe')) `
        'import: a line beginning with @ whose target contains whitespace is prose, not an import'
    Assert-True ($im5.Out -match 'read as prose') `
        'import: and the coverage line says how many were read that way, so the discriminator is visible rather than silent'

    # 23. THE SET IS CHECK 4'S SET, asserted on the count rather than on a name. If $linkFiles is ever
    #     refactored and this check is left reading something narrower, the two numbers diverge and this
    #     fails -- which is the same coverage guard the rest of this file exists for.
    Assert-True ($im5.Out -match '\[import\] checked (\d+)') 'import: the coverage line reports a count'
    $impCount  = [int]([regex]::Match($im5.Out, '\[import\] checked (\d+)').Groups[1].Value)
    $linkCount = [int]([regex]::Match($im5.Out, '\[link-scan\] checked (\d+)').Groups[1].Value)
    Assert-True ($impCount -eq $linkCount) `
        'import: the scan set IS check 4 set -- a narrower one here would go unnoticed without this'

    # 24. And the fixture is clean again once the probe is gone, so nothing above leaks into a later run.
    Remove-Item -LiteralPath $impProbe -Force
    Remove-Item -LiteralPath $impSibling -Force
    Assert-True (-not ((Invoke-Integrity -FixtureRoot $Fixture).Out -match '\[import\] \.')) `
        'import: the fixture is clean again once the probes are gone'

} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Complete-IntegritySuite
