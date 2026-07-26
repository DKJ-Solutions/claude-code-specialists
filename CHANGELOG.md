# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #189 · Lint check: marked skill enumerations must match the real skill set · Feat · 2026-07-26

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

[PR #189](https://github.com/DaveKJohn/davekjohns-workshop/pull/189)

---

### #188 · Family README: correct the cut-release skill claim and cross-link the restart rule · Docs · 2026-07-26

Edith's copy edit on #187 recommended cross-linking the family README to QUICKSTART.md's
restart-on-new-skill rule. Following up on that surfaced two further problems in
`claude-code-plugins/claude-specialists/README.md`.

**The `cut-release` claim was stale and self-contradicting.** `## How we use skills — and what we
deliberately don't` still called `cut-release` "deliberately not a skill" and cited
`scripts/sync/check-script-contract.ps1` as the source for that — but the `cut-release` skill has
existed since v2.6.0 (issue #177, PR #184), and that same script's own comment draws the opposite
distinction: the workshop-only *script* `scripts/release/cut-release.ps1` is not mirrored, while the
shared `cut-release` skill is "a different thing entirely". Rewrote the living example to state the
actual split — the marketplace-specific script (reading `.claude-plugin/marketplace.json` as the
source of truth for what a plugin is and bumping every `plugin.json` it lists in lockstep) stays
workshop-only, while the closing-steps *procedure* around it shipped as the `cut-release` skill
because that value covered the maintenance cost.

**The skill enumeration was missing one, in two places.** The list of "every skill" in the same
section did not include `cut-release`, and the claim that every skill is "a thin wrapper around a
script" no longer held for it (the skill's own description: "a checklist ... no script is run or
mirrored"). Added it and marked it as the deliberate exception to that generalization. The identical,
equally stale list turned up one section up too, in `## Where this runs: Chat, Cowork, and Claude
Code` (which enumerates the skills that remain available in a plain Claude.ai Chat session) — added
`cut-release` there as well, in the same order. `disable-model-invocation: true` only removes a
skill from autonomous model invocation (and from the `/reload-*` skill counters), not from
availability as an explicit slash command, which four of the seven skills already in that list
(`fold-changelog`, `open-pr`, `park`, and `start-task`) demonstrate.

**The cross-link (Edith's original point).** Added a short pointer from `## Which release am I on?`
to QUICKSTART.md's `## Staying up to date` section, for readers of the family README who would
otherwise miss the restart requirement for a newly added skill and the unreliability of the skill
counters as evidence.

**Two inaccuracies of my own, flagged on review before this landed.** The living-example paragraph
claimed the script "would crash on its very first line" in a fresh consumer — untrue: line 1 is a
comment block, and the actual repo-specific dependency (a missing `marketplace.json`) is a
controlled `Write-Error` + `exit 1`, not a crash. Dropped that clause, and the line-count figure
alongside it, since a number like that goes stale with every edit to the script. Separately, the
paragraph listed the skill's Minor/Major GitHub Release step as part of the portable procedure
without noting that this workshop itself deliberately does not publish GitHub Releases
(`releases/README.md`) — reworded so that step reads as being for a consumer that does, and split
into its own sentence so the paragraph does not nest a parenthetical inside an em-dash inside a
parenthetical.

[PR #188](https://github.com/DaveKJohn/davekjohns-workshop/pull/188)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.6.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.6.1.md](releases/development/2.x/2.6.1.md) for the full release notes.

---

### [v2.6.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.6.0.md](releases/development/2.x/2.6.0.md) for the full release notes.

---

### [v2.5.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.5.0.md](releases/development/2.x/2.5.0.md) for the full release notes.

---

### [v2.4.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.4.1.md](releases/development/2.x/2.4.1.md) for the full release notes.

---

### [v2.4.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.4.0.md](releases/development/2.x/2.4.0.md) for the full release notes.

---

### [v2.3.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.3.0.md](releases/development/2.x/2.3.0.md) for the full release notes.

---

### [v2.2.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.2.1.md](releases/development/2.x/2.2.1.md) for the full release notes.

---

### [v2.2.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.2.0.md](releases/development/2.x/2.2.0.md) for the full release notes.

---

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
