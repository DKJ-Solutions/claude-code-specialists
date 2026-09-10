## docs/release-title-convention

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

Dave decided 2026-09-10, at the v4.33.0 cut, that a forced one-sentence release title says nothing about a large multi-theme release. From now on the repo passes -Title 'Release version X.Y.Z'. Record it in Rendall's lens and in releases/README.md Local decisions; add one portable clause to the cut-release skill acknowledging a stable generic title is legitimate. Mechanism (-Title) is unchanged.

### CREATE

- [x] `dkj-policy/releases/README.md` › *Local decisions*: a dated Dave decision that every cut passes
      `-Title "Release version X.Y.Z"`, with the reasoning (a release rolls up everything since the last
      one; one sentence cannot describe a large multi-theme one). Notes the mechanism is unchanged and a
      single-theme repo should still use a descriptive line.
- [x] `.claude/specialists/lenses/05-06-extension.md` › *Versioning & releases*: the operating
      instruction for Rendall — pass that string on every cut here — pointing at the README for the why.
- [x] `plugins/dkj-policy/skills/cut-release/SKILL.md`: one portable clause by the `-Title` explanation,
      that a stable `Release version X.Y.Z` is a legitimate title where a release rolls up too many
      unrelated changes for one sentence to fit.

### TEST

- [x] Lint gate + suites green from the trunk baseline before the branch; the change is prose only —
      `-Title` is free-text and no script or test reads its shape, so there is nothing behavioural to
      pin. Copy edit on the diff (Edith) and `open-pr`'s own gates cover the rest.

### DEPLOY: docs/release-title-convention

From `v4.33.0` on, this repo titles every release `Release version X.Y.Z` and stops composing a
one-sentence summary that a large multi-theme cut makes meaningless. The decision and its reasoning are
in `dkj-policy/releases/README.md`'s *Local decisions* section; Rendall's lens carries the operating
instruction. The `-Title` parameter is untouched — a descriptive sentence is still valid for a repo
whose releases each carry one theme, and `-SummaryFile` still handles a genuine milestone.

**Score:** 1

The failure it prevents: a `history.md` title column and a GitHub Release heading filling up with
forced one-liners that describe none of the dozens of unrelated entries beneath them.

#### What makes this deploy extra special

One portable clause reaches a consumer, in the `cut-release` skill they read: a stable
`Release version X.Y.Z` is named as a legitimate title rather than something to apologise for. It
changes no command and no behaviour — the entries and attachments carry the detail either way.

**Score:** 1

#### Pull Request

Record that this repo titles every release Release version X.Y.Z

