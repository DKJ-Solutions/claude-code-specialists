## Development: `fix/fold-insert-by-landing-stamp-v1` · 20260903-110958

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Derive `Get-EntryInsertOffset`'s position from the entry's own merge stamp against the stamps already in
the list, so a LATE fold lands where it landed. Insert-only is preserved: one entry moves, nothing else
is touched.

#### The report, and what verifying it added

Issue [#1280](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1280) holds on every
count, and reading the tree for it turned up two things the report could not know:

* the misplacement is **no longer hypothetical**. #1280 was filed from an uncommitted fold and says so
  ("nothing about this is in the tree"). That fold has since landed: on the trunk this branch was cut
  from, `20260903-102422` sat above `20260903-103107` -- and a second, older pair with it,
  `20260903-014524` above `20260903-015507`, which nobody had noticed. So the class had already fired
  twice.
* the stamp and the position had **two different sources and nothing compared them**. The stamp comes
  off the PR's own `mergedAt` (`Format-EntryMergeStamp`); the position was a premise in a docstring.
  That is what makes the defect silent -- both halves are individually correct, and only reading two
  adjacent headings shows they disagree.

#### The one thing measured and NOT built

A **lint check on the pending list's order** was considered and declined. It would go red on a
misplacement that is already on `main`, so it would block an unrelated branch's PR for somebody else's
fold -- and the fold cannot be gated by a check that runs before a PR, because it happens after the
merge. Same shape as the stale-path check this repo declined at 124 findings, all false. The console
line reports both sides of the position instead, which is where a late fold is visible at the moment it
happens.

### CREATE

- [x] `Get-EntryHeadingStamp` in `../scripts/lib/entry-scaffold-lib.ps1` -- the inverse of
  `Format-EntrySectionHeadingSuffix`, placed beside it. Strict about the shape where
  `Get-EntrySectionHeadingTail` is deliberately loose, so the template's own placeholder cannot sort as
  a date.
- [x] `Get-EntryInsertOffset` gains `-Stamp` and derives the position: the first entry whose own stamp
  is strictly older. Equal stamps continue, so a tie keeps the entry folded first on top; an unreadable
  stamp stops the walk, which can only ever place higher than the old behaviour and never lower; no
  stamp at all is the pre-#1280 answer, which is what a no-PR fold and every consumer's older fold
  script get.
- [x] `../scripts/release/fold-changelog-entry.ps1` passes `-Stamp $mergeStamp` -- the same moment it
  has just written onto the heading, so one source feeds both. `$mergeStamp` is cleared per iteration,
  or in fold-all mode an entry with no PR would be placed by the previous entry's landing moment.
- [x] The console line reports both sides of the position, and names a late fold as one. Only "above N"
  was printed, which is indistinguishable from the always-top line when the entry lands mid-list.
- [x] The residue repaired: the two out-of-order pairs already in `CHANGELOG.md` are put back in
  landing order. Done here rather than in the fold on purpose -- the fold is a direct push to the trunk
  and stays insert-only, so a re-sort belongs on a branch under review. Verified as a pure reorder: 82
  insertions, 82 deletions, identical block set, identical byte length.
- [x] `../scripts/sync/build-shared-scripts.ps1` run -- both plugin mirrors updated.

### TEST

- [x] `entry-scaffold.tests.ps1` -- 17 new asserts: the stamp reader (round-tripped through the
  writer, both placeholders rejected, any other date shape rejected) and the offset (newest still
  leads, the measured late fold lands between the two it belongs between, older-than-everything lands
  at the list's end, a tie is stable, no stamp / an unreadable stamp / an omitted parameter all give
  the top, an unstamped entry in the list stops the walk, CRLF, and a stamp quoted inside a fence
  ordering nothing).
- [x] Three wiring asserts on the fold's text: it passes `-Stamp`, and it clears `$mergeStamp` before
  the PR lookup that may not fill it.
- [x] `check-plugin-integrity.ps1` + the full suite run via `open-pr.ps1`.

### DEPLOY: `fix/fold-insert-by-landing-stamp-v1`

`fold-changelog-entry.ps1` inserted every entry at the **top** of `CHANGELOG.md`'s pending list, on the
premise that "the entry being folded is the most recently merged one". A **late** fold is exactly what
breaks that premise, and this script is where late folds come from: its commit is a direct push to the
trunk under one of this repo's named exceptions, so a push it cannot make holds the entry while later
branches merge and fold ahead of it. The held entry then led a list it was no longer the newest member
of -- while the stamp on its own heading, read off the PR's `mergedAt`, said otherwise. Two sources, no
comparison, and nothing that errors: the only way to see it is to read two adjacent headings.

The position is derived now. `Get-EntryInsertOffset` takes the same `$mergeStamp` the fold writes onto
the heading and places the entry above the first one that landed earlier, so the two facts come from one
source and cannot contradict each other. **Insert-only is untouched** -- it derives a position and sorts
nothing, which is what keeps a bug in a commit that lands on `main` able to misplace at most the one
entry being folded. A new `Get-EntryHeadingStamp` reads a stamp back, strictly: the heading tail pattern
tolerates any text after the separator, so the template's `<timestamp of the moment this branch was
merged>` placeholder had to be excluded from an ordering decision by name. Passing no stamp is the
pre-change answer, which is both the no-PR fold and every consumer whose fold script is a release
behind.

Two out-of-order pairs the old behaviour had already left in the document are repaired here, on a
branch, for the same reason the fold does not do it. The console line now names a late fold when one
happens; a lint check on document order was measured and declined, because it would refuse an unrelated
branch's PR over a misplacement already on `main`.

Closes [#1280](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1280).

**Score:** 3

#### What makes this deploy extra special

A repo that runs this workflow folds with the same script, so its own held folds were misplacing their
entries too -- and the reason a consumer never noticed is the reason this matters to them: nothing errors,
and the wrong order only surfaces in a **published** release document. The changelog is the cut's input,
and one section inherits its document order rather than re-ranking: the development notes' **tier 0**
section, whose own comment asks for "complete and chronological, which is what a record is for". The
ranked documents were never affected -- `Build-ReleaseNotes` and `Build-ConsumerNotes` re-rank from the
scores -- so the reach is narrow, and it is the kind of narrow that lands in a document nobody corrects
afterwards. Arriving by plugin update, with no migration: a fold script one release behind keeps working
because the new parameter's absence is the old behaviour.

**Score:** 2

#### Pull Request

The fold places an entry by its landing stamp, not always at the top
