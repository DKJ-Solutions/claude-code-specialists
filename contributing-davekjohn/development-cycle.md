## Development cycle: `docs/plugin-readme-skill-table-v1` · 20260826-150621

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `
###
` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `
####
` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `
###
 PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `
####
`
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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### What #873 asked for, and what the recount changed

The report was measured on `55c7f700` and its comment recounted on `a8331dd7`; both are behind. Verified
today on `5a29170`:

- the plugin is `contributing-davekjohn/`, not `workflow-davekjohn/` -- #886 landed, so the file the report
  names has moved;
- the heading read `## The twelve skills`, the table held **14** rows, `skills/` holds **16** directories;
- the layout table's count was back (`the twelve skills a specialist invokes`) after the comment recorded it
  as gone;
- the two missing rows are still exactly the two the report named: `measure-skill` and `worktree-lane`.

So the finding stands and the specific gap survived every merge since -- which is the mechanism the
section's own warning predicted.

#### The second half is the one the report says matters, and the answer is no

Verified in `scripts/lint/check-plugin-integrity.ps1` rather than inferred: a lint-checked enumeration span
cannot hold this table, for two reasons that belong to check 10 and not to the document.

1. Its canonical set is built from every published plugin's `skills/`, so it is marketplace-wide -- a gate
   run today reports two such spans checked against 24 canonical skills. A span listing this plugin's 16
   would report the 8 team-plugin skills as missing.
2. Extraction is `` '`([^`\r\n]+)`' `` over the whole span, so every backtick-quoted token counts as a
   claimed name. Three rows of this table carry a backticked path or flag in their second column, so
   *wrap tightly* is unreachable without making the prose worse to satisfy a checker.

A generic, non-opt-in rule was measured too, and rejected on the spot: only this plugin's README enumerates
its skills at all. `team-alpha` (4 skills) and `team-shopify` (4) link to none, so a repo-wide rule would be
born with an 8-finding exemption list -- the shape this repo has scar tissue from.

- [x] Verify the report's symptom, subject, size and proposed repair against the tree
- [x] Measure whether a plugin-scoped enumeration rule could be generic (it cannot -- filed as #920)

### CREATE

- [x] Add the two missing rows: `worktree-lane` (after `park`, where the branch-lifecycle rows sit) and
      `measure-skill` (after `fix-mojibake`, with the maintenance tools)
- [x] Drop the count from the section heading and from the `skills/` row of the layout table
- [x] Rewrite the section's note: keep the three recurrences as a list, delete the sentence claiming the
      count "has dropped back to twelve for a real reason", and replace *"nothing here is machine-checked"*
      with the two verified reasons it cannot be
- [~] Give the table a lint-checked enumeration span -- dropped, it cannot carry one (see PLAN); the variant
      that would fit is [#920](https://github.com/DaveKJohn/claude-code-specialists/issues/920)

### TEST

- [x] `check-plugin-integrity.ps1` + all suites green (`open-pr.ps1` runs both before pushing)
- [x] Set equality checked mechanically, not by eye: the 16 `skills/<name>/SKILL.md` link targets in the
      README diffed against the 16 directories in `skills/` -- no missing, no extra
- [x] Swept the rest of the tree for the same stale-count class. `.claude/specialists/README.md` (4
      team-alpha skills) is correct; the figures in `specialists-init/SKILL.md`, check 26's comment and the
      published 4.19.0 audience note are history and stay. `INSTALL.md:1149` is wrong on three figures and
      is filed as [#922](https://github.com/DaveKJohn/claude-code-specialists/issues/922) rather than
      repaired here -- a different document, four different claims, one of which needs a rewrite

### DEPLOY: `docs/plugin-readme-skill-table-v1`

The workflow plugin's own skill table lists all **16** skills it ships and no longer says how many
([#873](https://github.com/DaveKJohn/claude-code-specialists/issues/873)). `measure-skill` and
`worktree-lane` had each arrived without a row; the heading read *"The twelve skills"* above 14 of them,
and the layout table's `skills/` row said twelve as well. Both counts are gone rather than corrected --
the third time this table has drifted, and every time a number is what made the gap look like a decision.

**The half that prevents recurrence got a verified answer, which is what the report actually asked for.**
It proposed a lint-checked enumeration span, the mechanism check 10 already enforces on the root `README.md`.
Held against `scripts/lint/check-plugin-integrity.ps1`, that span cannot carry this table: its canonical
set is built from *every* published plugin's `skills/` (24 skills today, so a 16-name span would report the
team plugins' as missing), and every backtick-quoted token inside a span counts as a claimed name, which a
two-column table with backticked paths in its second column cannot honour. Both constraints are now written
into the section's own note, replacing the *"nothing here is machine-checked"* sentence that recorded only
the risk. The variant that *would* fit -- scoped to one plugin, reading each row's link target instead of
its backticks -- is [#920](https://github.com/DaveKJohn/claude-code-specialists/issues/920), with the
measurement for why it must stay opt-in: `team-alpha` and `team-shopify` enumerate none of their skills, so
a generic rule starts life with an 8-finding exemption list.

**One instance of the same defect class was found and deliberately not repaired here.** `INSTALL.md` tells
a reader that *"14 of the 19 skills across the six shipped plugins"* carry `disable-model-invocation`;
measured today that is 16 of 24 across five. It is a consumer-facing document making four separate claims,
one of them needing a rewrite rather than a new number, so it is
[#922](https://github.com/DaveKJohn/claude-code-specialists/issues/922).

Nothing about the workflow changes and no script moved. What changes is that the page now agrees with the
directory beside it, and that a reader who wonders why it is not machine-checked gets the reason instead of
a warning.

**Score:** 2

#### What makes this deploy extra special

This README ships with the plugin, so it is the page a consumer reads when adopting the workflow -- and for
`worktree-lane` it is the *only* discovery route, since that skill carries
`disable-model-invocation: true` and therefore never appears in a slash list. A consumer who read this table
to find out what the workflow gives them was missing two of sixteen skills, one of them invisible everywhere
else. They notice the moment they open the page; nothing they already do changes.

**Score:** 3

#### Pull Request

The workflow plugin's README lists every skill it ships, and stops counting them

