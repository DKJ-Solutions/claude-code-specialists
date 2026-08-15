# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`workflow-davekjohn/releases/README.md`](workflow-davekjohn/releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `docs/v4-11-0-release-note` changelog

### Branch title

The v4.11.0 release note

### Branch ID

20260815-153845

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this afternoon: the consumer section rewritten from
the cut's draft against the seven writing tests, and the two organisational sections no script can
generate.

**The migration item leads for a second release running, and the wording changed rather than being
copied.** A consumer updating from 4.8.0 or earlier straight to *4.11.0* is no more carried past
v4.9.0's two actions than one updating to 4.10.0 was, so the item stands -- but it now says so in those
terms and points at both intervening notes, because the reader arriving here has a longer gap to cross
than the reader of the previous note did. Test 3 orders by urgency rather than by which release a change
belongs to.

**The prompt inbox is written as what the reader can do, and the adoption command was verified against
the tree before it was printed.** `adopt-workflow-folder` is what places `workflow-davekjohn/prompts/`
(`scripts/task/adopt-workflow-folder.ps1`) and `/prompt` is a real skill in the plugin's `skills/`
directory -- both checked rather than inferred, which is the #566 rule applied to a document written to
be acted on. The untracked inbox is given as *what you are part-way through writing is yours*, not as a
`.gitignore` decision.

**The token calibration reaches a consumer as a specialist that behaves differently**, not as a
corrected figure. The 19% and the ~41,800 are this repo's numbers and stay in the lens; what a consumer
gets is Nolan naming which copy he read and how his conversion factor was arrived at. The miss is quoted
once, as the reason the rules exist, because a rule with its failure attached is the half a reader can
use.

**The release-craft move is offered as a method, because the saving demonstrably does not travel.** A
consumer's `CLAUDE.md` is their own file and nothing here edits it -- so the section says that first,
then gives the three transferable parts (separate decision from evidence, measure the block before
cutting it, move the prose verbatim). The 87% figure sits in *what it is worth* rather than in the
consumer section: it is a fact about how the split was decided here, which is test 2's line exactly.

**One entry got no heading of its own, for the second release running and for the same reason.** The
v4.10.0 timing total scored tier 2 at 2 with its author's reason ending *"nothing they do changes"*, and
its content is an internal cost measurement. It survives as one clause -- that the v4.10.0 notes ask
nothing of the reader -- under the migration item.

**`What was still open` names five items, and the first is again this document.** The end-to-end total
cannot exist while the words are being written; the merge that re-runs the tests the PR already proved
is named for the **fifth** release running; the two degraded specialists are unchanged from v4.10.0
while the organisation set is not -- it was published at 4.10.0 on 2026-08-15T10:56:22Z, so it is one
release behind rather than unpublished; and the priced options from the token measurement are
recorded as not exhausted, with the next cut owing its own measurement rather than inheriting this one's
momentum.

**Step 0a's first pass is a subtotal of 5m 25s to the pushed tag**, against `v4.10.0`'s 5m 12s,
`v4.9.0`'s 5m 36s and `v4.8.0`'s 5m 02s -- the fourth consecutive head inside a thirty-five second band,
which is the 218s test gate being the floor. About 40 seconds of it blocked a person: reading the
assembled notes before the push, and naming the release.

### Significance

#### Tier 0

The release procedure's own record of what this cut cost, written while the head still exists -- that
half is unrecoverable afterwards, which is why step 0a splits into two passes at all. It also hands the
next person the legs to add and says where they go.

**Score:** 3

#### Tier 2

This is the only document in the release that tells a consumer whether they must act, and for anyone
updating from 4.8.0 or earlier the answer is still yes -- a required migration they would otherwise meet
as a session-start `[ERROR]` with nothing in this release explaining it. For everyone else it is the
plain statement that nothing is asked of them, plus the one thing they can newly do: write an assignment
in an editor rather than into a terminal.

**Score:** 4

### Pull Request

[PR #692](https://github.com/DaveKJohn/claude-code-specialists/pull/692) · merged 2026-08-15

---

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

Plugins: workflow-davekjohn

[PR #694](https://github.com/DaveKJohn/claude-code-specialists/pull/694) · merged 2026-08-15

---

## `docs/v4-11-0-timing-total` changelog

### Branch title

The v4.11.0 release note gains its end-to-end total

### Branch ID

20260815-155745

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.11.0`'s note was frozen at a **5m 25s** head; the five remaining legs -- writing the
document (2m 55s), its own gates (4m 02s), CI (7m 40s), the merge with the fold (4m 18s) and the publish
(28s) -- are added, giving a **total of 25m 07s** from clock start to a published Release with its
attachments.

**The tail is 19m 42s, and this is the FIFTH consecutive release to land inside a seventy-second band**
-- 19m 26s, 18m 47s, 19m 55s, 19m 50s, 19m 42s -- while the head over the same span moved from 15m 31s
to about five minutes and stayed there. Four measurements made the tail look stable; the fifth is what
makes it a **property of the procedure** rather than a run of coincidences, and the document says so in
those terms. It gives both series rather than the tail's percentage, for the reason the previous note
already established: the tail is fixed legs and barely moves, so a rising *share* is the head having
been fixed, not the tail getting worse.

**The blocked-a-person figure fell from 4m 05s to about 3m 35s, and that is not reported as an
improvement.** The head's two intake moments were the same 40 seconds; what changed is that writing the
document took 2m 55s against 3m 24s -- one document rather than two registers, on a release whose
consumer selection was clearer. It is inside the noise of a single measurement and is given as the leg it
came from rather than as a trend, because two points are not a series.

**The duplicated merge leg is measured a fifth time and is unchanged**: `ship-pr` re-runs the suites the
pull request already proved, inside a 4m 18s merge leg here, against roughly 3m 27s, 3m 18s, three
minutes and 4m 02s at the four releases before. Five consistent measurements make it the largest single
saving left in the procedure and the best-evidenced one; it stays named in *what was still open* rather
than being acted on here, which is the fifth release running that this sentence has been true.

**The attached copy stays frozen**, and the note now says so in place of the bullet that promised this
edit -- the rule `v4.7.0` set: an attachment is what was published at the moment of publication, and
silently replacing it is the opposite of the record the document is for. The bullet it replaces would
otherwise have become false the moment this merged, which is the failure mode of writing a promise into
a published record instead of a condition.

### Significance

#### Tier 0

The release procedure's own cost, complete for the fifth release running, in the unit the question was
asked in. What it buys here specifically is the fifth point on the tail series -- the one that turns a
stable-looking figure into a measured property, and therefore turns "the merge re-runs the suites" from
a recurring observation into the best-evidenced saving this procedure has.

**Score:** 3

#### Tier 2

A consumer reading this release's note gets the whole cost rather than the fifth of it that was visible
when the document was frozen, and is told plainly that the attached copy is the frozen one. Nothing they
do changes.

**Score:** 2

### Pull Request

[PR #693](https://github.com/DaveKJohn/claude-code-specialists/pull/693) · merged 2026-08-15

---

