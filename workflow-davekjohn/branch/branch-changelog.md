## `docs/v4-11-0-note-correction` changelog

### Branch title

the v4.11.0 note's false publication line, and the rule that lets it be corrected

### Branch ID

20260815-162419

### Branch type

docs

### What does the change on this branch bring to main?

`v4.11.0`'s published note told its readers that colleagues installing internally were **two** releases
behind. They were one. Read at the target rather than inferred -- `BWJ-ecommerce/claude-plugins-bwj`,
commit `07a1eb9`, 2026-08-15T10:56:22Z -- the organisation is on the four team plugins at 4.10.0. The
clause is corrected, and the page carries a `## Correction to this page` section naming the date, the
original wording, and the fact that the copy attached to the GitHub Release still contains the error and
is deliberately not replaced. `CHANGELOG.md`'s pending intro carried the same wrong characterisation and
is fixed outright, being nothing's published record yet.

**The clause was false at the moment it was typed, and that is what makes this more than a typo.** It was
carried forward from `v4.10.0`'s note, where *"has not been published"* was true at the merge and was
overtaken an hour later when the publication ran. The count was updated; the target was never re-read.
**A stale line copied forward becomes a false line** -- and every release that reuses the previous note's
*what was still open* block runs that risk, which is now the standing habit.

So the rule that governs both goes in writing, because the published-record convention will otherwise be
quoted as a reason to freeze an error. It protects a line that was **true when it was published**; a
snapshot going stale afterwards is the record working. It has never covered a line that was **false when
it was written** -- correcting one restores the record, freezing it preserves a mistake. The portable
statement, with how to mark a correction and why the attached asset stays frozen, lands in
`RELEASES-portable.md`, so it travels to every repo that cuts releases this way. This repo's
`workflow-davekjohn/CLAUDE.md` points at it and keeps the part only this repo can supply: the two adjacent
notes that demonstrate one case each. `4.10.0.md` is **left untouched on purpose** -- it is the stale
twin, and the contrast is the teaching case.

No check was built for it. "A prose claim about an external repo's state must be verified" is not
something a regex holds, and this repo has already priced that shape twice. What is buildable is the
habit: verify the target, not the previous note.

### Significance

#### Tier 0

A defect in a published document is corrected, and a convention that would have been quoted wrongly the
first time anyone met it is settled in one pass -- with two adjacent documents demonstrating opposite
treatments, which is the cheapest worked example this repo will get. It also names the mechanism that
produced the error, so the next release's carried-forward items get verified instead of recounted.

**Score:** 3

#### Tier 2

A page a reader may already have opened no longer states something untrue, and the correction says
plainly that the downloadable attachment still does. The portable half gains the rule itself, so a repo
running releases this way learns when a published note may be corrected and when it must be left alone --
useful the first time they face the question, invisible until then.

**Score:** 2

### Pull Request
