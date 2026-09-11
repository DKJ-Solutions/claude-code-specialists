## docs/1851-two-propagation-channels

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
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

State the second propagation channel in `CLAUDE.md`'s repo slot -- issue #1851.

#### The two statements that cannot both be the whole picture

The repo slot says a change that lands without a version bump *"reaches no session at all, and an
agent def you modify on a branch takes effect after merge, push **and a release** -- not after a
refresh."* True, and it is the always-on statement of how change reaches a consumer -- so it reads
as the whole model. It is not: the three runners `adopt-dkj-policy` scaffolds check this repository
out at `ref: main` and run a path into it, so a change to `check-branch-entry.ps1`,
`check-unfolded-entry.ps1`, `fold-changelog-entry.ps1` or `verify-resolved-issues.ps1` is live in
every adopted consumer's next CI run with nothing bumped.

#### Verified before repairing, not taken from the report

Both halves read against the tree: `consumer-runner-lib.ps1`'s header carries the checkout step
verbatim with `ref: main`, and `plugins/dkj-policy/skills/adopt-dkj-policy/SKILL.md` argues that pin
by name at "**The workflow pins `ref: main` rather than a tag**" -- with #1805's own sharpening of it
directly beneath. So the mechanism is deliberate and the repair is prose only; nothing about the
runners changes, exactly as the report proposed.

### CREATE

- [x] A two-paragraph addition to the repo slot in `CLAUDE.md`, directly after the paragraph it
      qualifies. The first names the second channel and what it is gated by -- nothing; the second
      says the pin is not the defect and points at the skill page's existing argument rather than
      restating it.
- [x] The rule it leaves behind is a writing rule, not a mechanism: **name the two channels together
      or name neither**, because a release doctrine stated alone is read as covering everything.

### TEST

- [x] Lint gate: the dead-link scan resolves the new link to the skill page and both issue links.
- [x] Full suite via `open-pr.ps1` -- this touches always-on prose, which `measure-always-on` and the
      consumer-prose gate both read.

### DEPLOY: docs/1851-two-propagation-channels

`CLAUDE.md`'s repo slot named one way a change reaches a consumer -- the plugin payload, gated by a
release and a version bump, landing in a session after `plugin update`. There are two. The three
runners `adopt-dkj-policy` scaffolds check this repository out at `ref: main` and run a path into
it, so a change to `check-branch-entry.ps1`, `check-unfolded-entry.ps1`, `fold-changelog-entry.ps1`
or `verify-resolved-issues.ps1` is live in every adopted consumer's next CI run: no tag, no bump, no
refresh, no restart.

Strictly the old sentence was never false -- CI is not a session. What made it worth repairing is
that the paragraph reads as the whole propagation model, and it is the document every session loads,
so a reader reasoning from it concludes that a shared gate script cannot reach a consumer before a
cut. That is the opposite of what happens, and the layer it was silent about is the one that can
change a consumer's required check with nobody bumping anything.

Nothing about the runners changes. The `ref: main` pin is argued by name in `adopt-dkj-policy`'s
skill page and #1805 already sharpened that argument; the addition points at it rather than
restating it. What is new is the writing rule: name the two channels together or name neither.

**Score:** 2

#### What makes this deploy extra special

A consumer reading this repo's `CLAUDE.md` as the model for their own now sees that adopting these
runners means tracking this trunk -- which is the one thing about the arrangement they cannot learn
from their side, and the reason a tag they own the bump on is offered as a trade in the skill page.
Nothing they run changes.

**Score:** 1

#### Pull Request

CLAUDE.md names the consumers' CI second checkout as the second propagation channel
