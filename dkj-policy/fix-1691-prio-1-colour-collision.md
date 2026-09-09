## fix/1691-prio-1-colour-collision

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Resolve the colour collision from **this** side: `prio-1` moves off `0E8A16`, which BWJ uses for `low`
and `sync`.

#### The repair is not the one #1691 proposed, and the reason is access

#1691 proposed re-colouring **BWJ's `low`**, and said so with its own gate: *"the live half edits
labels in two repos this one does not own... so it waits for Dave rather than being taken on a
session's own initiative."* That gate is right, and it is why the issue could not simply be worked as
written.

But a collision has two sides, and the other one is the repo in front of you. Moving **`prio-1`** costs
one `gh label edit` here and is strictly smaller:

- it needs **no access to a repo this one does not own**;
- it leaves `adopt-dkj-policy-bwj` step 4's prescribed hexes untouched, so the *third state* #1691
  named — a future adopter getting a colour the two existing stores do not have — cannot arise;
- it keeps the two rows that agree on the rung on purpose (`D93F0B`/`high`, `B60205`/`very high`);
- and it is one command to reverse.

The colour was not guessed: `006B75` was verified unused across all three trackers before it was taken.

### CREATE

- [x] Re-measured the filing before repairing it. It holds exactly — and it was **one label worse than
      reported**: `0E8A16` carries *two* BWJ labels, `low` and `sync`, not one. Both BWJ repos are
      byte-identical on all four rungs, as #1691 claimed.
- [x] `gh label edit prio-1 --color 006B75` on this tracker, read back. GitHub edits in place, so
      #1654 — the one open issue carrying the label — keeps it.
- [x] Derek's lens: the rung table's colour cell, and the collision block rewritten from *"left open
      deliberately"* to what was actually done, with the two deliberate agreements marked as such.
- [x] The **stale count one screen above it**, which this branch created and which was mine from
      #1685: *"on three of the same colour codes"* is two now, and the sentence says which two and why.
- [~] Changing `FBCA04` as well — dropped, with the reason recorded rather than left silent. It is
      `prio-2` here and `tier-1` in a BWJ repo, which is a **reach** label and not a rung, so the two
      are not answers to the same question and no reader compares them as rungs. Changing it would also
      break this repo's own ramp, which is now teal → yellow → orange → red.
- [~] Touching the BWJ trackers or `adopt-dkj-policy-bwj` — dropped deliberately: that is #1691's own
      Dave-gated half, and the whole point of repairing from this side is that it becomes unnecessary
      rather than pending. BWJ keeps `0E8A16` for `low`, and that is now unambiguous in the family.

### TEST

- [x] `gh label list --search prio` read back: `prio-1` `#006B75`, `prio-2` `#FBCA04`, `prio-3`
      `#D93F0B`, `prio-4` `#B60205`.
- [x] `006B75` confirmed absent from all three trackers before the edit — so the collision moved
      nowhere.
- [x] Every `0E8A16` left in the tree checked: three in Derek's lens, all now describing what BWJ
      still uses or what this repo used to, plus the one in `adopt-dkj-policy-bwj` step 4, which is
      BWJ's own prescription and correctly untouched.
- [x] The lint gate: 0 errors — the dead-link scan covers the new issue links in the rewritten block.
- [x] The lint gate and every suite, via `open-pr.ps1`.

### DEPLOY: fix/1691-prio-1-colour-collision

A `prio-1` badge no longer means two different rungs in one family. It was `0E8A16` — the green a
reader trained in this repo knows as *"nobody is waiting for it"* — which in a BWJ store repo is `low`,
one rung **above** the floor, and also `sync`. It is now `006B75`, verified unused across all three
trackers. Nothing refuses a colour, so this was the one part of the priority-axis decision that could
still go wrong silently: `gh` judges a label's name, and a badge is read by a person with no command in
it to fail.

**It was repaired from this side rather than the one #1691 proposed, and that is the substance.** The
issue's own repair edits live labels in two repos this one does not own and would have left future
adopters in a third state, so it was correctly gated on Dave. Moving `prio-1` instead is one command in
the repo in front of you, needs no access outside, leaves `adopt-dkj-policy-bwj`'s prescribed hexes
alone, and keeps the two rows that agree on the rung on purpose.

**Score:** 2

#### What makes this deploy extra special

N/A — a consumer of the plugins notices nothing. The label lives on this repo's own tracker and the
prose is a repo-local lens; `adopt-dkj-policy-bwj`, which is what a consumer actually receives, is
deliberately untouched.

**Score:** N/A

#### Pull Request

The prio-1 badge stops meaning two different rungs in one family
