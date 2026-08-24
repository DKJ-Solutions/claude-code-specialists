# Development cycle: `docs/correct-a-pending-entry-in-place-v1` · 20260824-212431

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

## PLAN

One rule, recorded where it travels. It came out of the round that closed
[#875](https://github.com/DaveKJohn/claude-code-specialists/issues/875), where a pending entry from the
day before had to be withdrawn rather than superseded, and nothing in either portable document said
which of the two to do.

## CREATE

- [x] A section on `fold-changelog/SKILL.md` -- the page that owns what lands in `CHANGELOG.md` -- with
      the rule, the measured instance, and the two limits (only while pending; sign the withdrawal).

## TEST

- [x] Lint gate green, all suites green via `open-pr`.

## DEPLOY: `docs/correct-a-pending-entry-in-place-v1`

**A folded entry is not history until a release is cut, and until then a later branch can make it
false.** Nothing said what to do about that, so the answer got worked out on the spot: correct it **in
place**, do not supersede it in the new entry. Both entries reach the reader in the same release
document, so a "reversed the next day" paragraph three entries down publishes the contradiction instead
of resolving it -- and where the new entry ranks higher, the reader meets the correction before the
claim it corrects.

**The measured instance is in the page, because the reasoning is the reusable half.** #876's entry
declared its new script *"deliberately repo-local... nothing about it ships. That is the point rather
than an omission"*, and #875's branch registered that script in the plugin within the day. What was
false was never the description of what shipped -- it was the **principle** the section reached for,
which is why the correction withdraws that and leaves the section's factual answer (an audience score
of `N/A`, correct for a change that genuinely reached nobody) exactly where it was.

Two limits are stated with it: the rule holds **only while the entry is pending**, since after a cut an
edit is a rewrite of the record and a new entry is then the right instrument; and the withdrawal is
**signed rather than silent**, because a quietly edited entry teaches its next reader nothing.

**Score:** 2

### What makes this PR extra special

Every consumer running this workflow folds entries into a `CHANGELOG.md` that sits pending for as long
as the gap between merges and cuts -- which in a repo that cuts monthly is most of the month. The page
they read to learn folding now answers a question that only comes up in that window, and answers it
before the day it comes up rather than after.

**Score:** 2

### Pull Request

A pending changelog entry your branch contradicts is corrected in place
