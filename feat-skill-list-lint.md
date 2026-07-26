### Lint check: marked skill enumerations must match the real skill set · Feat · 2026-07-26

**The trigger.** On one day, four separate enumerations or counts of "all the skills" went wrong,
because the skill set is spread across four plugin folders and nobody had a single, complete source
to check against.

**Sylvester's check 10.** Added an opt-in check to `scripts/lint/check-plugin-integrity.ps1`: an
author who writes a prose enumeration meant as the complete skill set wraps it in a BEGIN/END
HTML-comment marker:

```
<!-- skills:all -->
- `skill-name`
...
<!-- /skills:all -->
```

The check compares every backtick-quoted name inside the span against the canonical skill set (every
`<plugin>/skills/<name>/SKILL.md` across all plugin folders) and fails on any name missing or any
name that isn't a known skill. Extraction is character-based, so the sentinels can sit tightly inline
around just the enumeration, mid-sentence, without breaking a running paragraph. Deliberately opt-in
rather than a generic prose scan: a generic scan was tested and rejected (far too many incidental
hits, and it would have permanently flagged QUICKSTART.md's deliberately incomplete illustrative list
as an error). A doc with zero spans passes silently.

**Follow-up fix 1: fenced code blocks are masked before the scan.** Documenting the marker syntax
literally, as above, first risked the check misreading its own written example as a real span — a
risk caught during this branch's own drafting, since the scan also covers this entry's eventual home,
`CHANGELOG.md`, once folded. Sylvester closed the actual gap rather than leaving the symptom: the
check now masks the contents of every fenced (` ``` `) block before looking for markers, so the
syntax can be shown literally, as it is above. A single pair of backticks (inline code) deliberately
does **not** get that treatment — a claimed skill name inside a real span is itself backtick-delimited,
so there's no way to tell "example" from "real claim" there. A fence is the only safe way to show the
marker literally.

**Follow-up fix 2: an orphaned or duplicate END marker no longer passes silently.** Victor's code
review turned up one real finding: the check's own docstring promised that an unpaired marker is
always a hard error, but the code only enforced that for a BEGIN without a matching END — an orphaned
or duplicate END was simply ignored. The dangerous case: a second `/skills:all` inside a genuine span
(a copy-paste slip) closes that span early, leaving the rest of the enumeration unchecked prose, the
extra END vanishing without a trace — and the check reports one clean span and goes **green** having
verified only half of it. Silent false confidence, in the very check meant to guard against silent
drift, and the same class of mistake as the two stale claims cleaned up today in `05-15-manual.md`
and the family README: a docstring asserting something the code no longer did. Sylvester's fix tracks,
per file, the offset of every END actually consumed by a valid span, then reports any END left over
after the main loop as a hard error — reusing the same masked text, so an END written inside a fence
stays invisible, symmetric with BEGIN. The docstring now matches the code again. Small related
cleanup from the same review: the fence-masking pattern (used by both this check and check 4's link
scan) was deduplicated into one shared helper instead of living twice.

**Tycho's tests.** `scripts/tests/check-plugin-integrity.tests.ps1` now carries 15 scenarios for check
10. Beyond the basics (a matching span, a missing name, an extra/unknown name), the ones worth calling
out by what they actually guard: an unmarked, deliberately incomplete enumeration must **not** fail —
the opt-in's whole reason to exist; two unpaired BEGIN markers in the same file are **both** reported
(a regression guard on an earlier loop variant that stopped scanning the rest of the file after the
first one); a marker example written inside a fence stays invisible, asserted on the span *count*, not
merely on the absence of an error, so "happened to pass" can't be mistaken for "correctly ignored"; a
genuine span placed after a fence still reports its **correct** line number, the property the whole
masking approach depends on; a marker inside inline code **is** still scanned — the deliberate design
boundary, locked in by a test so nobody "fixes" it later; a `SKILL.md` one folder level too deep does
not count toward the canonical set; and three tests for the orphaned/duplicate-END fix above,
including the double-END case that used to go quietly green on half a check.

**Tessa's markers.** Placed the marker on the one enumeration in
`claude-code-plugins/claude-specialists/README.md` that is a genuine, complete list of all skills —
the "only the skills (...) remain available there" sentence under `## Where this runs`, wrapped
tightly around the parenthetical so the three SessionStart hook names one line above stay outside the
span. The second candidate, the "most skills (...) are a thin wrapper... `cut-release` is the
deliberate exception" pair of sentences under `## How we use skills`, also turned out to be markable:
together the parenthetical list and the trailing `cut-release` mention are exactly the same eight
skills, with no other backtick-quoted terms between them, so that span is marked too — Victor
independently confirmed the judgment call and its failure mode (a loud, precisely located lint error
instead of silent drift). QUICKSTART.md's slash-only subset list stays deliberately unmarked — it
isn't meant to be complete. Also documented the marker convention itself, next to the existing "Shared
agent-def blocks" section it mirrors, in `claude-code-plugins/claude-specialists/README.md`.

**A deliberate limitation, not a gap to close later.** The check is opt-in: a future prose
enumeration that nobody wraps in the marker will not be caught. That is Sylvester's explicit
recommendation after testing and rejecting the generic-scan alternative, not an oversight — the
generic scan produced far too many false positives across the repo, including QUICKSTART.md's
intentionally partial list, which would have failed permanently.
