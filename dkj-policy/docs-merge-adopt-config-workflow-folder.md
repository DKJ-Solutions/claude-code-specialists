## docs/merge-adopt-config-workflow-folder

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

Skill-level merge only (Dave's explicit scope decision): one new SKILL.md, adopt-dkj-policy, replaces both adopt-config and adopt-workflow-folder as two named parts of one page. The two underlying scripts (adopt-config.ps1, adopt-workflow-folder.ps1), their own tests, and their registry Name fields are UNCHANGED -- only each script's Skill field in shared-scripts-lib.ps1 now points at adopt-dkj-policy. Every doc cross-reference, the printed session-hook remediation message in check-script-contract.ps1 (root+mirror), the check-roster-sync.ps1 comment describing that message, the generated masthead text adopt-workflow-folder.ps1 writes into a consumer's scaffolded README, and the check-plugin-integrity.ps1 comments citing the old message as their own worked example, all updated to match. One test assertion (script-contract.tests.ps1) that checked the literal old skill name in printed output was updated to the new name. Consistent with the same-day precedent: adopt-bwj-asana was renamed to adopt-dkj-policy-bwj earlier today for the identical reason (a name naming one plugin should not leave a sibling operation for that plugin looking unrelated).

### CREATE

- [ ] TODO: the first step of this branch

### TEST

### DEPLOY: docs/merge-adopt-config-workflow-folder

**Score:**

#### What makes this deploy extra special

**Score:**

#### Pull Request

adopt-config and adopt-workflow-folder merged into one skill, adopt-dkj-policy

