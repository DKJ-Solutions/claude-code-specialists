## fix/1522-adopt-bwj-scope-and-board

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

Two verified defects in plugins/dkj-policy/dkj-policy-bwj/skills/adopt-dkj-policy-bwj/SKILL.md. #1522: no step establishes the checkout is a BWJ store repo, so a clean first run in the wrong repo copies the Asana CI in -- reproduced today in the source repo itself. #1521: the skill argues there is exactly one shared board; Asana measured today holds GitHub - SWB (1218093333788681) and GitHub - WH (1218093333788678), one per store. Also the Github Type field is multi_enum, not select.

### CREATE

- [ ] #1522 -- a `## 0` step that establishes the checkout is one of the two BWJ store
      repos (`git remote get-url origin`) and REFUSES otherwise, placed before step 1 so
      steps 1-7 keep their numbers and every existing cross-reference still resolves.
- [ ] #1522 -- the frontmatter `description:` states the two-repo bound as something the
      skill enforces, not only as context a session may read past.
- [ ] #1521 -- the `Get-AsanaProjectGid` paragraph stops concluding "exactly one board".
      The two cited constraints (#1213/#1386 prio labels, and the stages on the sections)
      stay verbatim; only the conclusion drawn from them changes, to: a REAL board per
      store, never a value copied between the two repos.
- [ ] #1521 -- `Github Type` is described as multi-select, and the indirection paragraph
      beside it stays true for a field that takes an ARRAY of option GIDs.
- [ ] Edith #17 copy-edits the diff -- language, links, and that no cross-reference broke.
- [ ] Lint + test gates green locally before the push.

### TEST

The two defects are prose, so the test is that the claims in the new text hold against
the systems they describe -- both measured today, 2026-09-06, before the text was written:

- [ ] The scope claim: `grep -rEn 'smartwatchbanden|xoxowildhearts|BWJ-ecommerce'`
      over the skill directory returned exactly ONE hit before this branch, the frontmatter
      `description:`. Re-run it after the edit and confirm the slugs now also appear in an
      executable step rather than only in prose that decides whether the skill is offered.
- [x] The board claim: Asana workspace `1206473494432180`, `get_projects` limit 100, holds
      TWO GitHub boards -- `GitHub - SWB` `1218093333788681` (23 tasks) and `GitHub - WH`
      `1218093333788678` (1 task). The skill's "exactly one board" is false as written.
- [x] The field-shape claim: `get_project` on `1218093333788681` with
      `custom_field_settings.custom_field.resource_subtype` reports `Github Issue` = `text`,
      `Github Type` = `multi_enum`, `Prio-Score` = `number`. So "select" is wrong and
      multi-select is right; `report-issue` already sends an array, so no behaviour moves.
- [x] The sections claim step 5 depends on: that board's sections are numbered `1.`-`7.`.

### DEPLOY: fix/1522-adopt-bwj-scope-and-board

**Score:**

#### What makes this deploy extra special

**Score:**

#### Pull Request

adopt-dkj-policy-bwj establishes the target repo before it writes, and stops prescribing one shared board

