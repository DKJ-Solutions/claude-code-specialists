## docs/1517-unreleased-label-not-a-seam

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

#### The choice the issue left open, and why option 2

Issue #1517 measured a doc-versus-code contradiction and named two ways to close it, deliberately
without picking: make the comment true (the label is a constant), or make the code true (probe an
optional override and register it in the contract). The tree answers it:

- **Nothing migrates the document.** `## [Unreleased]` already stands committed in this repo's
  `CHANGELOG.md` and in every consumer's, and no script here rewrites it. Every function in the block
  derives from the one constant, so an override would move the writer and the reader together, off the
  heading they are pointed at -- taking the fold's insertion point with them.
- **`Get-PreFlatChangelogRefusal` hands the literal to a consumer** as the string to type when migrating
  a pre-flat changelog, which is a fixed anchor stated from the other side.
- **The neighbouring seam draws the line where option 2 wants it.** The tally one block down IS seamed
  (`Get-ChangelogPendingSummaryOverrides`) because it is prose, rendered fresh on every fold and read by
  a person. The label is matched by an anchored regex and never read.
- **The file already has this vocabulary.** `$script:EntryScaffoldLegacyMarkers` is documented as
  "deliberately NOT repo-configurable: it is a historical string, so there is nothing for a consumer to
  choose about it."

Verified before deciding: no override probe, no `Get-SeamValue` call, no line in
`scripts/lib/script-contract-lib.ps1`, and no second place in the tree claiming the label is
configurable -- so the contradiction lives in exactly that one comment.

### CREATE

- [x] Rewrite the pending-section comment in `scripts/lib/entry-scaffold-lib.ps1`: keep the LEVEL half
      (true and demonstrable), replace the LABEL half with what the code does and why, and name the
      half-seam hazard the old comment set up for the next maintainer.
- [x] Mirror to `plugins/dkj-policy/scripts/lib/` via `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] Lint gate + all suites green (`open-pr.ps1` runs both).
- [~] No new test. The change is a comment; the behaviour it now describes correctly is already pinned
      by `release-lib.tests.ps1` (the derived heading and level) and `entry-scaffold.tests.ps1`. A test
      asserting a comment's wording would pin prose, not behaviour.

### DEPLOY: docs/1517-unreleased-label-not-a-seam

The comment over `$script:ChangelogUnreleasedLabel` said the `[Unreleased]` label was a seam a consumer
may translate. It never was: `Get-ChangelogUnreleasedLabel` returns the bare constant, with no
`Get-Command` probe, no `-OverrideCommand`, and no line in the script contract. It now says what the code
does -- a single constant, deliberately not repo-owned -- and gives the reason: nothing migrates the
document the pattern is pointed at, so an override would move writer and reader together, off the
`## [Unreleased]` already committed in every changelog, and take the fold's insertion point with it.

The hazard was the next repair rather than today's behaviour. Writer and reader agree because both derive
from the same constant, so nothing is failing; but a maintainer trusting the comment would most cheaply
have added the override to `Get-ChangelogUnreleasedPattern` -- the reader's half of a seam with no writer's
half -- and the pattern would then have stopped matching the heading, silently.

**Score:** 2

#### What makes this deploy extra special

N/A. A comment in a shared script: nobody outside this repo's maintainers reads it, and no behaviour
changes for a consumer. The mirror copy is updated in the same commit, so the plugin ships the corrected
text at the next release.

**Score:** N/A

#### Pull Request

The pending heading's label is a constant, not a seam
