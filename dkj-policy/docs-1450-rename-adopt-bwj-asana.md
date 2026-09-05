## docs/1450-rename-adopt-bwj-asana

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

The skill now scaffolds chapter two's SYNC-LOG.md as well as the Asana ticket-handling seams (step 7, already merged to main), so its name is renamed from adopt-bwj-asana to adopt-dkj-policy-bwj to match the whole plugin it adopts, not one chapter of it. Pure rename: the skill directory, its frontmatter name and internal prose, and every cross-reference in README.md (root), the plugin's own README.md, report-issue/SKILL.md, SYNC-LOG-portable.md, WORKFLOW-portable.md, templates/asana-mirror.ps1's comment, and scripts/tests/dkj-policy-bwj.tests.ps1. Archived release notes under dkj-policy/releases/ are history and are NOT touched -- they correctly recorded the old name at the time.

### CREATE

- [x] `git mv` the skill directory: `skills/adopt-bwj-asana/` -> `skills/adopt-dkj-policy-bwj/`.
- [x] Updated the skill's own frontmatter `name:`, its H1 heading, and its opening paragraph (now
      naming all three things it places, across both chapters, instead of "the two things").
- [x] Updated every cross-reference: `README.md` (root, including both `skills:all` marker spans),
      the plugin's own `README.md` (three spots: the skill table, the seam-proposal prose, and the
      "enabling it" section), `report-issue/SKILL.md`, `SYNC-LOG-portable.md` (two spots),
      `WORKFLOW-portable.md`, `templates/asana-mirror.ps1`'s docstring, and
      `scripts/tests/dkj-policy-bwj.tests.ps1` (the shipped-files list and the
      frontmatter-name-matches-folder loop).
- [x] Left the WORDING of `dkj-policy/releases/**` untouched -- those are archived release notes and
      correctly recorded the name that was live when each one was cut. One exception, matching the
      precedent the earlier `bwj-codex` -> `dkj-policy-bwj` folder rename already set in this same
      tree (`dkj-policy/releases/changelog/4.x/4.29.0.md:848`, where the link text still reads
      `bwj-codex`'s-era path segment while the URL points at the current folder): a LIVE MARKDOWN LINK
      in `4.29.0.md` pointed at `skills/adopt-bwj-asana/SKILL.md` and went dead the moment the
      directory moved. The lint gate's dead-link check (4) does not exempt `dkj-policy/releases/**` --
      only three OTHER checks (11, 12, entry-shape) explicitly do, for lifecycle commands and section
      counts, not for link resolution -- so a stale target there is a real, reported defect. Repaired
      by repointing only the URL to `skills/adopt-dkj-policy-bwj/SKILL.md`; the visible link text stays
      `adopt-bwj-asana`, since that is what the skill was called on the day that entry was cut.

### TEST

- Lint gate (`scripts\lint\check-plugin-integrity.ps1`): 0 errors -- in particular check 4 (dead
  links, including the one historical link above) and the `skills:all` marker list check.
- `scripts\tests\dkj-policy-bwj.tests.ps1`: pass, including the frontmatter-name-matches-folder
  assertion for `adopt-dkj-policy-bwj`.
- Full local test gate (`Invoke-TestSuiteGate`): all suites pass.
- Manual grep sweep: no LIVE markdown link to the old skill path remains anywhere in the tree; every
  remaining occurrence of the bare string `adopt-bwj-asana` is either a backtick-only prose mention
  inside archived history (correct, unedited) or this branch's own document naming the rename it
  describes.

### DEPLOY: docs/1450-rename-adopt-bwj-asana

`adopt-bwj-asana` grew a second chapter it was never named for: since today it also scaffolds
`dkj-policy-bwj/SYNC-LOG.md` (step 7), the record chapter two's sync branches write into. A skill named
after one chapter while it sets up both reads as narrower than it is, and the next reader has no reason
to expect chapter two's setup to be hiding inside a name that only says "Asana."

Renamed to `adopt-dkj-policy-bwj` -- the whole plugin it adopts, not one chapter of it. Pure rename, no
behaviour change: same seven steps, same additive/dry-run-by-default guarantees, same two things it
places in a store repo's own tree.

**Score:** 2

#### What makes this deploy extra special

N/A -- an internal skill name in a workflow only two repos enable. Nobody outside this repo's own
maintenance ever sees the string `adopt-bwj-asana` or `adopt-dkj-policy-bwj`.

**Score:** N/A

#### Pull Request

adopt-bwj-asana renamed to adopt-dkj-policy-bwj -- it covers the whole plugin, not just Asana

