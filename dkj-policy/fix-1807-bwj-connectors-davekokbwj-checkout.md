## fix/1807-bwj-connectors-davekokbwj-checkout

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

#### The finding (#1807)

Both BWJ connector manifests record only `../../bwjecommerce/<repo>` and
`../../GitHub/bwjecommerce/<repo>` as `localCheckout` candidates. Neither resolves on the
maintenance machine, where the checkouts sit at `GitHub/davekokbwj/<repo>`, so
`check-connectors.ps1` prints a false `[SKIP] checkout ... not present on this machine` that
exits 0 and suppresses the whole connector block for both consumers -- the two with the most
machinery in them. This is #1524 again one machine over: that repair turned `localCheckout`
into a candidate list so no layout would have to be evicted, then evicted `davekokbwj/`.

Repair: **append** `../../davekokbwj/<repo>` to each list rather than replace. The
`bwjdevelopment/` path #1807 anticipated is not added -- that folder is not on this machine.

### CREATE

- [x] `connectors/smartwatchbanden.json`: append `../../davekokbwj/smartwatchbanden` to `localCheckout`
- [x] `connectors/xoxowildhearts.json`: append `../../davekokbwj/xoxowildhearts` to `localCheckout`
- [x] Record a `CORRECTED 2026-09-10 (#1807)` paragraph in each manifest's `notes`: append-not-replace, the measurement, what was deliberately not added, and the recorded-not-decided first-match-wins limitation

### TEST

- [x] Both manifests parse as JSON (`ConvertFrom-Json`)
- [x] `scripts/sync/check-connectors.ps1`: the false `[SKIP]` is gone for both BWJ connectors; each now resolves `../../davekokbwj/<repo>` and runs its plugin + drift checks
- [x] `scripts/lint/check-plugin-integrity.ps1`: 0 errors
- [x] `scripts/tests/connectors.tests.ps1` green
- [x] Full test-suite gate green

### DEPLOY: fix/1807-bwj-connectors-davekokbwj-checkout

`connectors/`: both BWJ manifests (`smartwatchbanden`, `xoxowildhearts`) now list
`../../davekokbwj/<repo>` as a third `localCheckout` candidate, appended rather than replacing
the `bwjecommerce/` ones. On the maintenance machine the checkouts live under `davekokbwj/`, so
`check-connectors.ps1` was emitting a false `[SKIP] checkout ... not present` that exits 0 and
suppresses the whole connector block for both consumers. #1524 made this field a candidate list
so no machine's layout would be evicted; its fix then evicted `davekokbwj/`. The list is
first-match and additive, so this restores the evicted layout without losing the ones that are
true on other machines.

**Score:** 3

#### What makes this deploy extra special

N/A -- register data internal to this repo; no subscriber of any service reaches it.

**Score:** N/A

#### Pull Request

Append the davekokbwj/ layout to both BWJ connectors' localCheckout candidates

