## fix/1771-plugin-details-agent-count

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

#1771 reported that the manifest's `agents` key registers nothing and asked for `subagents/` to be
renamed back to `agents/` across 44 occurrences, the key dropped, and check 38 changed to refuse the key
outright. Verifying the *reason* rather than the symptom overturned it: the key is honoured by the loader
and honoured exclusively, so none of that was built. What #1771 actually found is a defect in the
instrument it measured with, and that is this branch.

#### The control that settled it

A throwaway local marketplace, one plugin, two agent defs in one non-default directory with only
**one** of them named in the `agents` key — installed into a scratch project and read back from a real
session with `claude -p`:

| def | in the key | `claude plugin details` | a real session |
|---|---|---|---|
| `zebrafish` | yes | not counted | **present** |
| `quokka` | no, same directory | not counted | absent |

The rig was removed and its marketplace entry unregistered in the same run.

### CREATE

- [x] `measure-skill-lib.ps1`: `Read-PluginDetailsOutput` reads the component inventory's own COUNTS
      (`InventoryCounts`, `RowProducingCount`), and `Get-PluginDetailsParseProblems` judges an empty table
      against them — three states, with `$null` for an inventory that could not be read at all
- [x] `measure-skill.ps1`: an inventory declaring nothing tabulatable is an `[INFO]` naming why instead of
      an `[ERROR]`; a plugin whose agents go uncounted gets the caveat, and its ≥100% share note no longer
      claims the skills are the plugin's whole cost
- [x] both mirrored into `plugins/dkj-policy/scripts/` for the drift lint
- [x] check 38's header records the loading measurement and the DECLINED proposal to refuse the key
- [x] the lesson written into Nolan #25's lens (the measurement) and Sylvester #15's lens (the declined
      gate change), and the `measure-skill` skill page

### TEST

- [x] `measure-skill.tests.ps1`: 15 asserts added — the inventory counts, the `$null` third state, the
      `(3)`-in-a-description trap, the agents-only fixture that must NOT be a problem, and the
      table-stripped mirror case that must stay one. 77 pass, 0 fail
- [x] `measure-skill.ps1` over all six enabled plugins: 0 errors, where it reported 2 before
- [x] the full lint + test gate via `open-pr`

### DEPLOY: fix/1771-plugin-details-agent-count

`measure-skill` no longer refuses a plugin that ships only subagents. `claude plugin details` prints no
per-component table for a plugin whose inventory is all zeroes, and reading that as a CLI format change
put an `[ERROR]` on two of this repo's six enabled plugins — `dkj-subagents-ecomm` and
`dkj-subagents-lifehub` — over output that was entirely intact. The emptiness is now judged against the
inventory's own counts, so nothing owed is an `[INFO]` naming why, something owed is still an `[ERROR]`,
and an unreadable inventory stays the `[ERROR]` the check exists for.

It also says what its figures do not cover. The inventory's `Agents (N)` counts only defs discovered by
convention in a plugin's default `agents/` directory; a def named by the manifest's `agents` key loads in
a session and is counted as 0. Every always-on figure for such a plugin is therefore skills only, which
made the report read as *"the skill descriptions account for effectively ALL of this plugin's always-on
cost"* over `dkj-subagents-alpha`, whose 15 uncounted agent descriptions are roughly three times the
figure printed. Both readings are now stated in the output — including that `Agents (0)` means *not
counted here*, never *ships none*, which is the misreading #1771 was filed on.

**Score:** 3

#### What makes this deploy extra special

N/A — the tool measures what a plugin costs a session; it ships to no subscriber and changes nothing a
consumer's own repo does.

**Score:** N/A

#### Pull Request

measure-skill stops misreading an agents-only plugin as a CLI format change

