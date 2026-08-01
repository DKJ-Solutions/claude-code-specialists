### The teardown reports what it keeps, and the pre-flight measures commits · Fix · 2026-08-01

Two findings from test round v10 (#340), both on the teardown's own correctness — and the second is the
third generation of one defect, so it arrives with a fixture rather than a third correction.

**#332 — the pre-flight measured the index, not the commits.** `git ls-files .claude` reports the
**index**: measured in v10, a `git add -A` went through, the following `git commit` failed, and the command
flipped from empty to 20 lines with **zero commits in the repository**. Its comment — `# empty = not
committed yet` — was therefore false in the direction that matters, and this is the one section whose whole
purpose is answering *"do I have an undo?"*. Both printed copies (`UNINSTALL.md` and the skill's own
pre-flight) now run `git ls-tree -r --name-only HEAD`, with the `fatal: ... HEAD` outcome named as the
"no commits at all" case. The skill's *explanation* was wrong in the same way — it said `ls-files` "lists
committed files only" — and is corrected too.

**The gate, because the lineage is #280 → #283 → this.** `teardown-protocol.tests.ps1` gains a seventh
fixture: a tree that is **staged and not committed**. It asserts both directions, because a fixture that
only checks the new command proves nothing — the old command must *also* be shown reporting this state as
committed, which is the false green a reader was handed. The command assertions are scoped to the **fenced
block** rather than the section, so the prose stays free to name `git ls-files` while explaining what it
used to be; a test that banned the string outright would force the document to drop its own history to stay
green.

Two companion observations from the same pre-flight, both now written down: **command 1's success case exits
`1`** (invisible in a shell, reads as a failed command in an agent harness — it is the answer you want), and
**the safety-net commit was scoped too narrowly** — it named only the lens tree, while the teardown also
edits `CLAUDE.md` and, with `-VendorScripts`, writes under `scripts/`.

**#331 — `[FREE]` while bootstrap-written prose survived, reported as neither `[remove]` nor `[KEEP]`.** On
a consumer that had no `CLAUDE.md` before adoption, every byte of that file is `specialists-init`'s, and
after `-Apply` two prose lines stayed — unreported, while the audit printed `[FREE]`. The audit's claim was
narrowly *true* (those lines name no specialist, persona, roster or lens, so nothing loads because of them),
and that is exactly what made the silence the finding: this script's contract with a reader is that
`[remove]` versus `[KEEP]` tells them which case they were in.

They are now reported per line as `[KEEP]`, with a note, and **not removed** — deliberately. The boundary
the teardown keeps is that it takes out lines whose authorship is knowable *and* whose removal costs the
owner nothing: an `@`-import loads something, prose does not, and cutting sentences out of a governance file
to satisfy a counter is the wrong side of that line. `UNINSTALL.md` gains the fifth row in *"What is left
behind, honestly"* — the only entry in that list the plugin itself wrote — and the section's intro count
moved from three to four to match.

**The literal lives in one place.** `Get-ClaudeMdScaffold` + `Test-IsClaudeMdScaffoldProseLine` join
`Get-SeamPaths` and `Get-OrchestratorNote` in `check-report-lib.ps1`, and `bootstrap.ps1` now builds its
scaffold from that source. Third literal to cross the writer/recogniser boundary, and a hand-mirrored
literal is what produced *both* instances of the accumulation bug those functions exist for.

**Second half of #331: `scripts\lib\` was left behind as an empty directory.** The single pruning pass ran
before section 3 put the only file in it on the removal list. It is now one callable invoked twice — deepest
first, returning its labels so the caller keeps one tally, because a second tally is how the #275
preview/apply drift started.

**Verified.** Lint 0 errors, all suites green. `teardown.tests.ps1` gains the **fresh-consumer** fixture
this suite never had — every existing fixture hands the bootstrap a `CLAUDE.md` it already has, so the
branch that *creates* one was never exercised, which is the same blind-spot shape `bootstrap.ps1` documents
about itself. And the refactor was checked against the series' own anchor: a freshly generated `CLAUDE.md`
is still **463 bytes, 0 CRLF, 8 lone LFs** — byte-identical to v10's virgin-profile measurement and to
v5/v6 on a different machine and release.
