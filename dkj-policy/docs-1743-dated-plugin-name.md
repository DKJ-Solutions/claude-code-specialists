## docs/1743-dated-plugin-name

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

#### Verifying #1743 -- git settles it, which is what the reporter could not do from the tree

#1743 reports that `README.md`'s *"Measured on August 8, 2026, the `dkj-team-alpha` plugin shipped
1,973,691 bytes"* names a plugin that did not exist on that date, and Tessa flagged it rather than
guessing because the working tree alone cannot answer it. It can be answered:

- The tree as of the last commit before August 9, 2026 (`0f22d747`) holds
  `plugins/teams/team-alpha/.claude-plugin/plugin.json`. On the measurement's own date the plugin was
  **`team-alpha`**.
- `eaeb832b` (September 5, 2026) is the rename -- *"rename plugins/teams to plugins/dkj-teams and
  prefix the four team plugins with dkj-"* -- confirming #1480's date, four weeks after the figure.

**The issue's suggestion to check the neighbours was taken, and the count of one holds.** `README.md`
carries exactly one `Measured on <date>` sentence, and it is this one; the dated statements around it
(the #1699 correction, *"Decision by Dave, August 8, 2026"*, the `dkj-policy` paths) are
present-tense claims or current link targets, which the rule does not reach. The three figures
themselves appear nowhere else in the tree outside the release archive, which is carved out.

- [x] Establish the August 8 spelling from `git`, not from the tree.
- [x] Confirm the rename's date and issue number.
- [x] Check the neighbouring dated sentences and the other two figures.

### CREATE

- [x] `README.md`: name the plugin `team-alpha`, and say in the same breath that it is
      `dkj-team-alpha` since #1480 -- so the citation stays usable rather than merely correct.
- [x] Tessa's lens: write the #952 rule down. It was stated in the `#1437` commit message and applied
      at every rename since, but it lived in no document -- which is the one place a rule cannot be
      read *before* the sweep. With the measured instance and the three things to take from it.

### TEST

- [~] No test. The rule is deliberately not gated, and #1743 says why: deciding whether a name inside
      a dated sentence is historical or current needs the sentence's meaning, so a matcher on
      "dated paragraph containing a plugin name" would fire on every correct one too.
- [x] Full gate: lint (dead links included, since the repair adds one) + every suite, via open-pr.

### DEPLOY: docs/1743-dated-plugin-name

`README.md`'s one dated measurement names its subject as it was spelled on the day it was taken --
`team-alpha`, not the `dkj-team-alpha` two later rename sweeps left there -- and says what it is
called today, so the figure can still be re-verified against the tag it came from. The rule behind it
(#952: a dated measurement keeps the name it was written with) is now in Tessa's lens, where a sweep
can meet it beforehand; until now it existed only in the commit messages of the renames that observed
it.

**Score:** 2

#### What makes this deploy extra special

N/A -- this repo's own README and one repo lens. A consumer receives neither.

**Score:** N/A

#### Pull Request

Name the plugin in README's August 8 measurement as it was spelled on that date

