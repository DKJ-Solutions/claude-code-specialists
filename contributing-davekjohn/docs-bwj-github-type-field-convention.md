## docs/bwj-github-type-field-convention

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

Fixes [#1385](https://github.com/DaveKJohn/claude-code-specialists/issues/1385). The board's
`Github Type` field holds a value `report-issue` step 1 has **already chosen** -- its `--type`, one of
`Bug`/`Feature`/`Task` -- and then throws away, so a colleague re-derives it by hand from the card.
Mirror the shape [#1377](https://github.com/DaveKJohn/claude-code-specialists/issues/1377) landed on
in [#1384](https://github.com/DaveKJohn/claude-code-specialists/pull/1384): an optional seam plus a
step-2 write, so the answer is carried one step forward instead of retyped.

#### The six inbound checks, run before routing

All six pass. Symptom still stands (`grep -rn "Github Type" plugins/ scripts/` is empty); subject
exists (GID `1218174803433581`, `multi_enum`, options `Bug`/`Feature`/`Task` -- exactly step 1's
three); reason holds; repair names mechanisms that exist (`create_tasks` takes `custom_fields` keyed
by field GID, multi-select as an array of option GIDs); size is as reported (19 `Task`, 4 `Feature`
over 23); repo is right.

**One claim in the issue is loose and is not repeated.** It says the enum options come back "on the
`get_project` call the skill already makes". A project read is indeed already made -- for the
section -- but Asana's `opt_fields` takes **no wildcard**, so `custom_field_settings.*` returns the
options *absent* rather than erroring. They cost one longer `opt_fields` string on a call already
happening, not nothing, and `report-issue` now says so with the string spelled out.

#### The drift the issue left unmeasured -- measured

The issue flagged it as "worth checking as part of any repair, **not measured here**". Measured
September 4, 2026 against the GitHub issue types: **5 of the 23 cards disagree**, in both directions.

| issue | board `Github Type` | GitHub type |
|---|---|---|
| `334` | `Task` | **Bug** |
| `333` | `Task` | **Feature** |
| `478` `479` `480` | **Feature** | `Task` |

**That is not a drift rate for the procedure**, which is the reading to avoid: nothing has ever
written this field, so all 23 values are hand-set and what the number measures is the accuracy of a
hand-fill, not of a step. It argues for carrying the value forward at creation -- which this branch
does -- and for a one-time correction of those five cards, which is a write to a colleague-facing
board and is filed rather than done here.

### CREATE

- [x] `WORKFLOW-portable.md`: state the `Github Type` rule beside the `Github Issue` one -- set from
      step 1's own answer, never re-derived -- and record the measured hand-fill drift with it.
- [x] `adopt-bwj-asana`: add the optional `Get-AsanaTypeFieldGid` seam, and say why the field's
      **option** GIDs are deliberately *not* configured beside it.
- [x] `report-issue`: read the new seam in the pre-flight, and write the field in step 2 from the
      `--type` step 1 passed -- with the `opt_fields` string, the array-vs-bare-GID distinction, and
      the refusal to guess when no option matches.
- [x] `bwj-codex/README.md`: register both field seams in the seam list. #1384 added
      `Get-AsanaIssueFieldGid` without listing it, so this branch would otherwise have left that
      register staler than it found it. The stale `two functions` count above the list goes with it,
      replaced by no count rather than by a bigger one.
- [~] A fourth `asana-mirror.ps1` sweep pushing the GitHub type onto the card -- **dropped**. It was
      the issue's candidate 3, explicitly conditional on the hand-set values having drifted. They
      have, but only as legacy: once step 2 writes the field the two agree at creation, and the sole
      remaining exposure is somebody changing the type afterwards with `gh api --method PATCH`, which
      is rare and made by the same person in the same session. A daily sweep costs an API call per
      open issue to catch it. What would change the answer is a measurement showing post-creation
      type changes are common; nothing here suggests they are.
- [~] Correcting the five drifted cards -- **dropped from this branch**. It is a write to a
      colleague-facing Asana board rather than a change to this tree, so it leaves the session as
      its own issue.

### TEST

- [x] `check-plugin-integrity.ps1` and every suite green via `open-pr.ps1` -- the gate that reads
      this plugin's manifests, frontmatter and dead links, including the two new intra-document
      anchors.

### DEPLOY: docs/bwj-github-type-field-convention

`bwj-codex` now carries the board's `Github Type` field the same way it carries `Github Issue`: an
optional `Get-AsanaTypeFieldGid` seam in `adopt-bwj-asana`, and a `report-issue` step 2 that sets the
field **from the issue type step 1 already chose** rather than deciding it a second time. Because the
value is carried forward rather than re-derived, a ticket this workflow files cannot end up with a
board type its own GitHub issue contradicts.

The field's **option** GIDs are deliberately not part of the seam -- they are resolvable at run time
from the project `report-issue` is already reading for the section, so pinning three more GIDs per
repo would only add three more values that go stale in silence. What that buys is stated where a
maintainer will meet it: rebuild an option and nothing breaks; rename one away from `Bug`, `Feature`
or `Task` and the write is skipped with a note rather than guessing.

Two things measured on the way in are written down with it. Asana's `opt_fields` takes **no
wildcard**, so the enum options are not free on the call already being made and the exact string is
spelled out; and of the 23 cards on the BWJ board, whose `Github Type` had only ever been filled by
hand, **5 disagreed with the GitHub issue** in both directions -- which is what a hand-fill costs
rather than a drift rate for a step that had never run.

**Score:** 3

#### What makes this deploy extra special

A consuming repo whose board carries the field gets it filled at creation instead of by hand, and
`adopt-bwj-asana` now proposes the seam that turns it on. A consumer whose board carries no such
field sets nothing and sees no change -- `$null` stays the default and the write is skipped silently.
The `bwj-codex` seam register in the plugin README lists both GitHub field seams for the first time,
so the set of values a consumer is expected to answer is readable in one place again.

**Score:** 3

#### Pull Request

set the board's Github Type field from the issue type report-issue already chose
