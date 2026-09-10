## fix/connector-record-catch-up

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

Rename dkj-team-alpha@ to dkj-subagents-alpha@ and register the four enabled plugins the record never listed; measured on this machine after running the #1698 migration.

### CREATE

- [x] Run the #1698 migration on this machine -- uninstall the four `dkj-team-*` ids, install the four `dkj-subagents-*` ids, all `--scope project`, with the marketplace refresh on both sides, exactly as `INSTALL.md` prescribes.
- [x] Fast-forward this checkout, which was 46 commits behind `origin/main` and therefore reported the machine as ahead of the source at v4.33.0 against v4.32.0.
- [x] Rename `dkj-team-alpha@` to `dkj-subagents-alpha@` in `connectors/claude-code-specialists.json`.
- [x] Register the four plugins the record never listed -- `dkj-subagents-ecomm@`, `dkj-subagents-lifehub@`, `dkj-subagents-shopify@`, `dkj-policy-bwj@` -- with inventories counted from the marketplace clone's own payload rather than carried over.
- [x] Append the dated measurement note in the register's house style, keeping every earlier sentence at the names it was written with (#952).
- [~] Repair the checker so an enabled-but-unregistered plugin is reported. Dropped deliberately: this branch corrects data, and the checker change is filed as #1775 so it can be argued on its own.

### TEST

- [x] `scripts/sync/check-connectors.ps1` -- this repo's block went from one plugin checked and one `[INFO]` skip to all six checked `[OK]`, on 19 + 3 + 5 + 3 + 0 + 0 extensions.
- [x] The 30 registered ids counted against `.claude/specialists/lenses/`, which holds exactly 30 files -- one per id, no surplus and no shortfall.
- [x] `ConvertFrom-Json` on the edited manifest, before and after the note was appended.
- [x] The lint gate and every suite, via `open-pr.ps1`.

### DEPLOY: fix/connector-record-catch-up

This repo's own connector record described two plugins while the repo runs six, so five of them sat outside `check-connectors.ps1` entirely -- one skipped behind an `[INFO]` for the retired `dkj-team-alpha@` id, and four never looped over at all because a plugin absent from the array is silent rather than reported. The record now names all six at the ids the 4.33.0 rename gave them, with each inventory counted from the marketplace clone's payload rather than carried forward, and the note says what the two gaps cost in the register of the repo that owns the check. The half this does not do is the checker itself: the 2026-08-21 argument for leaving the silent route unreported rested on its population being zero, that stopped being true on 2026-09-08, and #1775 carries it.

**Score:** 3

#### What makes this deploy extra special

N/A -- `connectors/` is this repo's own register of who consumes what, read by a maintenance script here. It ships in no plugin and reaches no consumer of the specialists system.

**Score:** N/A

#### Pull Request

Catch this repo's own connector record up to the six plugins it has
