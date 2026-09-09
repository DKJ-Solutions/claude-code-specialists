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
in both stores and for `sync` in one of them.

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
      reported**: in `xoxowildhearts`, `0E8A16` carries `sync` as well as `low`. Only there; in
      `smartwatchbanden` that label is grey (`6e7781`). Both BWJ repos are byte-identical on all four
      *rungs*, as #1691 claimed.
- [x] `gh label edit prio-1 --color 006B75` on this tracker, read back. GitHub edits in place, so
      #1654 — the one open issue carrying the label — keeps it.
- [x] Derek's lens: the rung table's colour cell, and the collision block rewritten from *"left open
      deliberately"* to what was actually done, with the two deliberate agreements marked as such.
- [x] The **stale count one screen above it**, which this branch created and which was mine from
      #1685: *"on three of the same colour codes"* is two now, and the sentence says which two and why.
- [~] Changing `FBCA04` as well — dropped, and the reason is **weaker than the one the green moved
      for**, which the lens now says out loud rather than declaring it harmless. It is `prio-2` here and
      `tier-1` in a BWJ repo — a **reach** label, not a rung — so a misread there gets the *kind* wrong
      and not the rung. What it does not buy is safety by this branch's own argument: *"a badge has no
      command in it to fail"* says nothing about axes, and `tier-1` can sit on a BWJ issue beside any of
      its four prio labels. Changing it would also break this repo's own ramp, now teal → yellow →
      orange → red. No instance of either misread has been observed.
- [~] Touching the BWJ trackers or `adopt-dkj-policy-bwj` — dropped deliberately: that is #1691's own
      Dave-gated half, and the whole point of repairing from this side is that it becomes unnecessary
      rather than pending. BWJ keeps `0E8A16` for `low`, and **that green no longer means two different
      rungs across the two families** — which is not the same as unambiguous, and the first draft of
      this line claimed the stronger thing while the CREATE step two items up refuted it. Inside
      `xoxowildhearts` the same green still carries `sync` as well; that is a BWJ-internal question this
      branch does not reach and does not claim to have closed.

### TEST

- [x] `gh label list --search prio` read back: `prio-1` `#006B75`, `prio-2` `#FBCA04`, `prio-3`
      `#D93F0B`, `prio-4` `#B60205`.
- [x] `006B75` confirmed absent from all three trackers before the edit — so the collision moved
      nowhere.
- [x] Every `0E8A16` left in the tree checked — **at the second attempt.** The first sweep excluded
      `dkj-policy/CHANGELOG.md` and reported four sites; the red-team found a fifth there, pending and
      wrong. The five are: three in Derek's lens (all now describing what BWJ still uses or what this
      repo used to), the one in `adopt-dkj-policy-bwj` step 4 (BWJ's own prescription, correctly
      untouched), and #1686's still-unreleased changelog entry, corrected.
- [x] The lint gate: 0 errors — the dead-link scan covers the new issue links in the rewritten block.
- [x] The lint gate and every suite, via `open-pr.ps1`.
- [x] Copy edit (Edith) and conclusion red-team (Marlowe) on the diff. Edith found nothing and
      re-verified every colour claim against all three live trackers. Marlowe returned **WOBBLES** on
      four points, two of them hard; all four are repaired below rather than argued with.

#### What the red-team caught, and the two that were hard

1. **A stale line that would have SHIPPED.** `dkj-policy/CHANGELOG.md` still carried #1686's pending
   entry saying, present tense, *"`0E8A16` is the floor here"* — false the moment `prio-1` moved, and
   under `## [Unreleased]`, so the next cut would have published it. This branch's own TEST step had
   claimed *"every `0E8A16` left in the tree checked"* and that claim was **false**: the sweep behind it
   excluded `dkj-policy/CHANGELOG.md` from its grep. Corrected in place — the tense, plus a sentence
   saying which way the repair actually went — because the entry is still pending and an entry that has
   not shipped is an ordinary edit.
2. **A self-contradiction inside this document.** It said BWJ's green *"is now unambiguous in the
   family"* while the CREATE step two items above recorded `0E8A16` carrying two labels in
   `xoxowildhearts`. Corrected to the claim that actually holds: the green no longer means two different
   **rungs** across the families, which is what this branch closed and all it closed.
3. **The `FBCA04` dismissal used an argument the branch itself had refuted.** *"Nobody compares them as
   rungs"* assumes the reader checks the label's name — which is precisely the failure mode
   *"a badge has no command in it to fail"* says does not happen. Softened in the lens to name the
   residual risk and to say plainly that the reason for leaving it is weaker than the reason the green
   moved: a misread there gets the *kind* wrong, not the rung.
4. **`006B75` was checked for exact-hex uniqueness, not perceptual distinctness.** It sits ~14 degrees
   of hue from `help wanted`'s `008672`, so two dark teals now mean opposite things in one picker.
   Accepted rather than churned, and **measured first**: `help wanted` has been used once in this
   repo's whole history (the closed #1215) and never on a pull request, while a third colour inside one
   day would re-stale this document, the lens block and the changelog entry above. Recorded in the lens
   with that number, together with the cost that is not free — the floor no longer wears green, so the
   traffic-light reading is one rung off here.

#### The colour choice, stated as an assumption rather than left implicit

#1691 named two gated things: touching a repo this one does not own, **and** which colour replaces the
green. Repairing from this side answers the first and does **not** answer the second — the pick is
this session's, made while Dave is away under his standing *"I follow the specialist's advice here."*
So it is recorded as an assumption, not as a settled decision: `006B75` was verified unused across all
three trackers, and overriding it is one `gh label edit`. That is a fact in the record rather than a
question at a close-out, which is why it sits here and not in a reply.

### DEPLOY: fix/1691-prio-1-colour-collision

A `prio-1` badge no longer means two different rungs in one family. It was `0E8A16` — the green a
reader trained in this repo knows as *"nobody is waiting for it"* — which in both BWJ store repos is
`low`, one rung **above** the floor, and in one of them `sync` as well. It is now `006B75`, verified
unused across all three trackers. Nothing refuses a colour, so this was the one part of the
priority-axis decision that could still go wrong silently: `gh` judges a label's name, and a badge is
read by a person with no command in it to fail.

**It was repaired from this side rather than the one #1691 proposed, and that is the substance.** The
issue's own repair edits live labels in two repos this one does not own and would have left future
adopters in a third state, so it was correctly gated on Dave. Moving `prio-1` instead is one command in
the repo in front of you, needs no access outside, leaves `adopt-dkj-policy-bwj`'s prescribed hexes
alone, and keeps the two rows that agree on the rung on purpose.

**What it does not settle, and says so rather than implying otherwise.** #1691 gated two things — the
outside access *and* the colour itself. Repairing from this side answers the first; `006B75` is this
session's pick, verified unused before it was taken, and one `gh label edit` to override. Inside a BWJ
repo the same green still carries two labels, which is a BWJ-internal question this branch does not
reach. And `FBCA04` stays `prio-2` here and `tier-1` there on a weaker argument than the one the green
moved for: a misread there gets the *kind* wrong, not the rung.

**Score:** 2

#### What makes this deploy extra special

N/A — a consumer of the plugins notices nothing. The label lives on this repo's own tracker and the
prose is a repo-local lens; `adopt-dkj-policy-bwj`, which is what a consumer actually receives, is
deliberately untouched.

**Score:** N/A

#### Pull Request

The prio-1 badge stops meaning two different rungs in one family
