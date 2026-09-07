## fix/1523-connectors-bwj-rename-catchup

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

#### The finding (#1523), and what re-measuring it showed

`connectors/smartwatchbanden.json` and `connectors/xoxowildhearts.json` named the pre-4.31.0 plugin
ids -- `team-alpha@`, `team-shopify@`, `team-ecomm@`, `contributing-davekjohn@` -- none of which the
marketplace declares any more, so `check-connectors` reported an `[INFO]` per id and **skipped every
plugin block** for both consumers: the two repos furthest ahead were the ones the register could say
least about.

Verified against each consumer's own `origin/main` after a fresh fetch (not a local working copy):

- **smartwatchbanden** `fcd54c4` (2026-09-06, unchanged since #1523 was filed) --
  `.claude/settings.json` enables `dkj-team-alpha@`, `dkj-team-shopify@`, `dkj-team-ecomm@`,
  `dkj-policy@`, `dkj-policy-bwj@`. Fully migrated; the manifest was not.
- **xoxowildhearts** `0aafe90` (2026-09-06) -- **the same five**, identical to smartwatchbanden.
  #1523 measured this consumer at `92facf1` (2026-09-01), before commit `aba1905`
  ("tooling: migrate to the 4.31.0 plugin renames", 2026-09-06 18:27Z) landed, so the issue's
  "`bwj-codex@` unregistered" is now understated: the live gap is the whole rename plus the fifth
  plugin, `bwj-codex@` having itself been renamed to `dkj-policy-bwj@`.
- Lens inventories on both consumers' `origin/main` match what the manifests record (19 + 3 + 3), so
  only the plugin `id` fields drifted.

`dkj-policy@` and `dkj-policy-bwj@` both ship no `agents/`, so both take `extensions: []`.

### CREATE

- [x] `connectors/smartwatchbanden.json`: rename the four ids to their `dkj-` forms, add
  `dkj-policy-bwj@` with `extensions: []`, append a dated `CAUGHT UP 2026-09-06 (#1523)` note that
  keeps every earlier sentence as written (per #952).
- [x] `connectors/xoxowildhearts.json`: same four renames, same added plugin, same style of note --
  recording that the issue's snapshot predated the consumer's own migration commit.
- [x] Extension arrays left as measured; no other bookkeeping (machine version, cache drift) touched.

### TEST

- [x] Both manifests parse as JSON.
- [x] `check-connectors.ps1 -SkipDrift`: the two BWJ manifests together dropped from 8 `[INFO]`
  (four retired ids each) to 1 -- smartwatchbanden fully `[OK]`; xoxowildhearts now version-checks
  (19 + 3 + 3 extensions present, all machine records on `v4.31.0`). The one residual `[INFO]` is on
  xoxowildhearts: `dkj-team-shopify@` has no machine install record for that checkout path -- a
  consumer-side, other-machine state that was invisible while the whole block was being skipped, now
  surfaced where the doctrine wants it (the consumer's own move, not this repo's).

### DEPLOY: fix/1523-connectors-bwj-rename-catchup

The `connectors/` register now records the plugin ids the two BWJ consumers actually enable, so
`check-connectors` resolves and version-checks all five of each consumer's plugin blocks -- where
before it skipped the four it could not resolve and never saw the fifth. Both manifests carry a
dated `CAUGHT UP` note; no extension inventory or version bookkeeping was otherwise changed.

**Score:** 3

#### What makes this deploy extra special

N/A. `connectors/` is workshop administration -- it does not travel to consumers' plugin caches and
a subscriber of the specialists service notices nothing.

**Score:** N/A

#### Pull Request

connectors/ registry catches up with the two BWJ consumers' dkj- plugin renames

