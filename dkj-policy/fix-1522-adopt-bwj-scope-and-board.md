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

- [x] #1522 -- a `## 0` step that establishes the checkout is one of the two BWJ store
      repos (`git remote get-url origin`) and REFUSES otherwise, placed before step 1 so
      steps 1-7 keep their numbers and every existing cross-reference still resolves.
- [x] #1522 -- the frontmatter `description:` states the two-repo bound as something the
      skill enforces, not only as context a session may read past.
- [x] #1521 -- the `Get-AsanaProjectGid` paragraph stops concluding "exactly one board".
      The two cited constraints (#1213/#1386 prio labels, and the stages on the sections)
      stay verbatim; only the conclusion drawn from them changes, to: a REAL board per
      store, never a value copied between the two repos.
- [x] #1521 -- `Github Type` is described as multi-select, and the indirection paragraph
      beside it stays true for a field that takes an ARRAY of option GIDs.
- [x] Edith #17 copy-edited the diff. Four findings: the `xoxowildhearts'` possessive (repo
      precedent is the bare apostrophe), "settled onto" -> "settled on", "tell apart" ->
      "distinguish" -- all three applied. The fourth (quoting step 1's guard rather than
      re-bolding it) was declined: step 0 cross-references that rule, it does not restate it.
      Her out-of-scope note -- this file citing two different repo owners -- is filed as #1526.
- [x] `check-plugin-integrity.ps1` run locally: **0 errors** across all checks. The test suites
      are not a step of their own -- `open-pr` runs lint AND every suite as its own gate, and a
      copy set going ahead of it proves nothing that gate would not catch.

### TEST

The two defects are prose, so the test is that the claims in the new text hold against
the systems they describe -- both measured today, 2026-09-06, before the text was written:

- [x] The scope claim: `grep -rEn 'smartwatchbanden|xoxowildhearts|BWJ-ecommerce'`
      over the skill directory returned exactly ONE hit before this branch, the frontmatter
      `description:`. Re-run after the edit: **7 hits**, and line 23 is the step 0 check itself --
      an executable step, not only prose that decides whether the skill is offered.
- [x] The board claim: Asana workspace `1206473494432180`, `get_projects` limit 100, holds
      TWO GitHub boards -- `GitHub - SWB` `1218093333788681` (23 tasks) and `GitHub - WH`
      `1218093333788678` (1 task). The skill's "exactly one board" is false as written.
- [x] The field-shape claim: `get_project` on `1218093333788681` with
      `custom_field_settings.custom_field.resource_subtype` reports `Github Issue` = `text`,
      `Github Type` = `multi_enum`, `Prio-Score` = `number`. So "select" is wrong and
      multi-select is right; `report-issue` already sends an array, so no behaviour moves.
- [x] The sections claim step 5 depends on: that board's sections are numbered `1.`-`7.`.

### DEPLOY: fix/1522-adopt-bwj-scope-and-board

`adopt-dkj-policy-bwj` refuses a checkout that is not one of the two BWJ store repos, in a new step 0
ahead of anything it writes. The constraint had lived only in the skill's frontmatter `description:` --
a grep for the two store slugs over the whole skill directory returned exactly one hit, that line -- so
none of the seven steps ever established which repo the session was standing in. Step 1's existing
"stop and diff" guard does not cover it, and reads as though it does: that guard protects a repo which
has *already* adopted, while a first run in the wrong repo finds no file at either target, so it passes
cleanly and the copy proceeds. Measured here on September 6, 2026 -- the skill was invoked in this
source repo, which is where its own templates are copied *from*, so every file step 1 wants is already
in reach and nothing about running the steps in order says otherwise. A person stopped it; the skill did
not. Left alone, step 1 would have placed an Asana mirror workflow -- `issues: write`, a daily cron, and
a project GID this repo does not own -- on the public tracker that receives every consumer's inbound
reports. The step is numbered 0 so steps 1-7 keep their numbers and every cross-reference still
resolves, and it ships with no override flag, there being no legitimate third adoption target.

**Score:** 3

#### What makes this deploy extra special

The same page stops telling both stores to use one shared Asana board. It did not merely permit that
answer, it argued for it, and the two constraints it cited are what made the argument persuasive: both
are true, and both are satisfied by a per-store board exactly as well as by a shared one, so they argue
for a *real* board rather than a *provisional* one -- never for one board rather than two. Measured over
the workspace on September 6, 2026: there are two GitHub boards, one per store. Both bullets are kept
verbatim and only the conclusion changes -- each store repo answers `Get-AsanaProjectGid` with a board
of its own, and the value is never copied between them. What a copied value costs is nothing visible,
which is the reason this is worth a release note: the create call succeeds, the fields write, the
sections still move a card, and the only symptom is colleagues on one store finding the other store's
tickets sitting on theirs. **A store that adopted under the old wording should check which board its
GID actually names.** Same page, wording only: `Github Type` is a multi-select and takes an array of
option GIDs, not a plain select -- `report-issue` already sent the array, so no behaviour moves.

**Score:** 4

#### Pull Request

adopt-dkj-policy-bwj establishes the target repo before it writes, and stops prescribing one shared board
