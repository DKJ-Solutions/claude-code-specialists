## docs/1769-marketplace-rename-prep

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

Fase 0 of the #1769 migration (`claude-code-specialists` -> `dkj-claude-plugins`): the reversible prep
that carries no rename edit. No `marketplace.json` name, no `@`-ref, no slug is touched on this branch --
only the carve-out comment in `scripts/repo-config.ps1`, plus this document.

#### Decision (a) and the phased plan

Recorded verbatim on the issue: <https://github.com/DKJ-Solutions/claude-code-specialists/issues/1769#issuecomment-5616120403>

Decision (a), September 10, 2026: the marketplace NAME is renamed too (not only the GitHub slug),
knowingly overruling the August 14, 2026 carve-out in `scripts/repo-config.ps1`. The cost that
reasoning identified still stands in full -- every consumer's `enabledPlugins` key breaks, no redirect
exists for a marketplace name -- so it runs as a phased migration (fase 0-5 on the issue), not a
big-bang branch. Fase 3 is the coordinated flag day; fase 4 decides separately whether the business
mirror follows the new name.

#### Consumer / machine inventory (from `connectors/`)

Five external consumers plus this repo consuming itself:

| Repo | Visibility | localCheckout (relative) | Marketplace plugins enabled |
|---|---|---|---|
| `DKJ-Solutions/claude-code-specialists` (self-consume) | public | `.` | all six |
| `DaveKJohn/djcylow-react` | public | `../djcylow-react` | alpha, policy |
| `DaveKJohn/life-hub` | private | `../life-hub` | alpha, lifehub, policy |
| `DaveKJohn/thumbnail-generator` | private | `../thumbnail-generator` | alpha, policy |
| `BWJ-Development/smartwatchbanden` | private | `../../bwjecommerce/smartwatchbanden` OR `../../GitHub/bwjecommerce/smartwatchbanden` | alpha, shopify, ecomm, policy, policy-bwj |
| `BWJ-ecommerce/xoxowildhearts` | private | `../../bwjecommerce/xoxowildhearts` OR `../../GitHub/bwjecommerce/xoxowildhearts` | alpha, shopify, ecomm, policy, policy-bwj |

Notes for fase 2 / fase 3:
- Every `connectors/*.json` already carries **stale plugin ids** (`team-alpha@`, `dkj-team-alpha@`,
  `contributing-davekjohn@`, `team-lifehub@`, `dkj-team-shopify@` ...) that predate the current names
  (`dkj-subagents-*`, `dkj-policy`). Fase 1 rewrites these files anyway, so this is folded into that
  work rather than filed separately.
- The two BWJ repos list two candidate `localCheckout` paths -- different machines lay the tree out
  differently. The install record is keyed on the folder path **per machine**, so the machine
  enumeration (`claude plugin list` / `installed_plugins.json` per checkout) can only be done on each
  machine at flag-day time. This repo's own `connectors/claude-code-specialists.json` note already
  documents that pattern.

#### For Rendall -- the version bump

This migration breaks every existing consumer install (re-add the marketplace under a new name). That
is a tier-2, significance-5 change by the rubric, so the cut in fase 3 is a **major**. A major needs
the two prep commits ahead of the release commit: the new `#### N.x` section in
`dkj-policy/releases/history.md` and the assert in `scripts/tests/release-lib.tests.ps1` that pins
which major the overview targets. Both are in scope of the fase 3 cut request, not this branch.

### CREATE

- [x] Claim #1769 (`scripts/task/claim-issue.ps1 1769`) and open this branch.
- [x] Record decision (a) + the phased plan on #1769 (comment `5616120403`) and mirror the summary into
      the PLAN section above.
- [x] Amend the August 14, 2026 carve-out comment in `scripts/repo-config.ps1` so it no longer
      contradicts decision (a) -- the August 14 paragraph kept as written, a dated September 10
      amendment appended (#952 "recognise both, keep both legible" rule). No name value changed.
- [x] Take the consumer / machine inventory from `connectors/` and record it above.
- [x] Note the major-version + two-prep-commit requirement for Rendall (in PLAN above).

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` green -- the edit is a comment in a `.ps1`, so check 27
      (`[script-ascii]`) and the script-contract check are the relevant ones; the amendment is pure
      ASCII.
- [x] All `scripts/tests/*.tests.ps1` green -- `config-blueprint.tests.ps1` reads `repo-config.ps1`
      wording (adopt-config copies it verbatim), so a comment change is exercised there.

### DEPLOY: docs/1769-marketplace-rename-prep

The `claude-code-specialists` -> `dkj-claude-plugins` rename (#1769) now has a recorded decision and a
phased migration plan on the issue, and `scripts/repo-config.ps1`'s carve-out comment no longer
contradicts it. No rename has been performed -- this is the reversible fase 0 groundwork only.

**Score:** 2

#### What makes this deploy extra special

N/A -- no subscriber of any consuming service sees a prep branch. The rename itself reaches tier 2 at
significance 5, but that lands in fase 3, not here.

**Score:** N/A

#### Pull Request

Prepare the claude-code-specialists to dkj-claude-plugins rename

