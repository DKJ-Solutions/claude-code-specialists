## docs/1477-retired-adopt-skill-names

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

Six live sites name the two merged-away skills; the registry bullet in #1477 was verified and does NOT stand.

### CREATE

- [x] `plugins/dkj-policy/README.md` -- the seam section names `adopt-dkj-policy`'s Part 2, so the page
      stops contradicting its own skill table two screens up
- [x] `INSTALL.md` -- step 4's list of adopt skills, and the folder-rename warning further down
- [x] `plugins/dkj-policy/CONTRIBUTING-portable.md` -- the paragraph on what places the CI gate's six lines
- [x] `scripts/README.md` -- the entry-point table's Skill cell for `task/adopt-config.ps1`
- [x] `plugins/teams/team-shopify/skills/adopt-shopify-floor/SKILL.md` -- cites `adopt-config.ps1`, the
      script that still exists, rather than the page that was deleted
- [~] `scripts/lib/shared-scripts-lib.ps1` -- dropped: the bullet was read against the code and does not
      stand. `Name` is the script's own filename (`scripts\task\adopt-config.ps1`, which exists) and the
      field that resolves a documenting page, `Skill`, already reads `adopt-dkj-policy`. #1477 marked this
      one "not verified" itself.

### TEST

- [x] `git grep` for both names over the whole tree: every surviving hit either names a `.ps1` that exists
      and was never renamed, or sits in `CHANGELOG.md` / the archived release notes, where it is history
      and correct as history

### DEPLOY: docs/1477-retired-adopt-skill-names

Five live pages still told a reader to invoke `adopt-config` or `adopt-workflow-folder` -- the two skills
[#1471](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1471) merged into `adopt-dkj-policy`,
deleting both `SKILL.md` pages. They now name the surviving skill and the part of it that does the work.
Three of the five were beyond what [#1477](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1477)
listed, which said so in as many words: the class is wider than the lines it had measured.

The sixth site the issue named, the registry entry in `scripts/lib/shared-scripts-lib.ps1`, is deliberately
untouched. It was filed as inferred rather than measured, and reading the code collapses it: `Name` is the
script's own filename and the field a gate resolves a documenting page from is `Skill`, which has read
`adopt-dkj-policy` since the merge.

**Score:** 2

#### What makes this deploy extra special

Both halves of the adoption path were wrong for a consumer: `INSTALL.md` step 4 named two skills their slash
list does not hold, and the plugin's own README named a third one two screens below its skill table naming
the right one. That is the first page a new consumer reads and the one moment a wrong skill name costs them
a support round rather than a shrug.

**Score:** 3

#### Pull Request

the retired adopt-config and adopt-workflow-folder names off the live pages