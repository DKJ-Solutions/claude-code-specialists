## Development: `feat/bwj-issue-type-tier-label-v1` · 20260901-205940

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

Issue [#1201](https://github.com/DaveKJohn/claude-code-specialists/issues/1201): `report-issue` files a
BWJ issue with `--title` and `--body` and nothing else, so every issue it files arrives typeless and
tier-less. Both BWJ trackers were classified by hand on September 1, 2026 -- 135 issues, 100% type
coverage on both -- and that state erodes from the next filing.

#### Verified before writing anything

- `gh issue create --type` exists in the installed `gh` (2.94.0), so the type is settable at creation.
- Both repos carry a `tier-1` label; `bug` and `enhancement` are gone from both; `documentation` is still
  there. Type coverage measured live: smartwatchbanden 55 (Task 45 / Bug 8 / Feature 2, 18 `tier-1`),
  xoxowildhearts 80 (Task 46 / Bug 20 / Feature 14, 11 `tier-1`) -- exactly the issue's final comment.
- **The issue body is superseded by its own third comment**: the label is `tier-1` marking the exception,
  absence meaning tier 0. The body's `tier-0`-marks-the-exception shape was tried and rejected. What is
  encoded is the comment, not the body.

#### The one thing the issue left open, decided here

*Ask the reporter for the tier, or infer it?* -- **infer, and name the call in the report.** The backfill
inferred all 135 correctly from the issue text, the reach question is answerable from the finding itself,
and step 4 already puts the answer in front of the human at zero extra turn -- which is the ask, after the
fact, with a one-line correction beside it. Doubt resolves to tier 0, so the default is also the cheap
direction.

### CREATE

- [x] `WORKFLOW-portable.md` -- the three fields at creation, the type mapping, the tier test and the
      `documentation` asymmetry, under rule 1 where the filing happens
- [x] `skills/report-issue/SKILL.md` -- the flags on the `gh issue create` line, the decision block, the
      retrofit commands, and the type/tier in the step 4 report
- [x] `README.md` -- one clause in the one-paragraph rule, so the page does not describe a filing that
      leaves out half of what a filing now does
- [x] `skills/adopt-bwj-asana/SKILL.md` -- a step that checks the `tier-1` and `documentation` labels
      exist, because `gh issue create` fails outright on a label the repo does not have

### TEST

- [x] `check-plugin-integrity.ps1` + all suites green (the `open-pr` gate runs both)

### DEPLOY: `feat/bwj-issue-type-tier-label-v1`

`report-issue` filed every BWJ issue with a title and a body and nothing else, so each one arrived with
no issue type and no reach label. Both BWJ trackers had just been classified by hand -- 135 issues, 100%
type coverage on both -- and the tool that files the next one would not have maintained it. The skill now
sets all three fields at creation (`--type`, `--label tier-1`, `--label documentation`), states how to
decide each, and carries the retrofit commands for an issue already filed;
[`WORKFLOW-portable.md`](../plugins/workflows/bwj-codex/WORKFLOW-portable.md) carries the reasoning so a
reader can apply the conventions without the skill, and
[`adopt-bwj-asana`](../plugins/workflows/bwj-codex/skills/adopt-bwj-asana/SKILL.md) gained a step that
checks the labels exist -- `gh issue create` fails outright on a label the repo does not have, which
would have made the new line in `report-issue` a hard failure in a freshly adopted repo.

**Score:** 2

#### What makes this deploy extra special

Two things a reader of the plugin gets that the issue did not ask for. **The issue body is superseded by
its own third comment** -- `tier-0`-marks-the-exception was tried and rejected in favour of `tier-1`
marking it, and encoding the body would have inverted the whole convention; what landed is the comment.
And the one question the issue left open (*ask the reporter for the tier, or infer it?*) is answered
rather than parked: **infer, and name the call in the report**, because step 4 already puts the answer in
front of the person who knows the store, at zero extra turn, beside the one line that corrects it.

**Score:** 3

#### Pull Request

report-issue files BWJ issues with the issue type and the tier-1 label
