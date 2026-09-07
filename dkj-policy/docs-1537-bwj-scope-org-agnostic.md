## docs/1537-bwj-scope-org-agnostic

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

Measured: BWJ-ecommerce/smartwatchbanden is archived, BWJ-Development/smartwatchbanden is live, and BOTH xoxowildhearts repos exist (ecommerce not archived, pushed most recently). So the two-orgs shape is real today and may still move. Drop the org from the scope statements and gate on what the plugin needs; keep the 3 github.com permalinks as historical citations.

#### What I measured before repairing, and where it changed the repair

The report's symptom stands exactly: **14 scope-bearing lines across 5 files**, reproduced with the
report's own command. Two things I measured changed what got written:

- **The org question the reporter could not answer has a messy answer, not a clean one.**
  `BWJ-Development/xoxowildhearts` **already exists** (pushed 2026-09-07 13:18Z) while
  `BWJ-ecommerce/xoxowildhearts` is **not archived** and was pushed more recently (14:40Z). So the
  two-orgs shape is real *today* and may not be final. That is what makes the report's **second**
  proposal the right one rather than a toss-up: dropping the org is correct under either future,
  whereas naming the org per repo would be wrong again the moment the second store moves.
- **`WORKFLOW-portable.md`'s issue-types claim did not need a seam.** The report flagged it as needing
  to be true of both orgs or move to a seam. Measured: `gh api orgs/<org>/issue-types` returns exactly
  Task, Bug and Feature in `BWJ-ecommerce` **and** in `BWJ-Development`. So it only had to stop naming
  one org, and it now carries the measurement.

#### Where I went LESS far than the report proposed, and why

`WORKFLOW-portable.md:244` is in the report's table of 14 and is **left as written**. It reads
*"In `BWJ-ecommerce/smartwatchbanden`, #388 was closed on 2026-09-01..."* -- a dated measurement, past
tense, sitting directly above its own permalink. That is the same class as the three permalinks the
report itself says to keep, and the convention is stated in this repo's own connector manifests:
*"keep the names they were WRITTEN with... rewriting one to match today's names is the defect #952 was
made of."* So 13 lines moved and 1 stayed.

### CREATE

- [x] The three scope headers name the two **stores** and say why the org is left out --
      `README.md`, `WORKFLOW-portable.md`, `SYNC-LOG-portable.md`
- [x] `report-issue/SKILL.md`: the frontmatter description, and the step-1 precondition rewritten to
      match the repo **name** with the reason a name outlives an org
- [x] `report-issue/SKILL.md`: the issue-types claim carries the both-orgs measurement
- [x] `adopt-dkj-policy-bwj/SKILL.md`: the frontmatter, and the **refusal** -- which is the one that
      actually gated behaviour -- now matching the last path segment, with why an org-path match refuses
      the one adoption it exists to serve
- [x] `adopt-dkj-policy-bwj/SKILL.md:167`: the present-tense `Get-AsanaProjectGid` sentence
- [x] `WORKFLOW-portable.md:74`: the issue-types claim
- [x] The 3 `github.com/BWJ-ecommerce/...` permalinks left untouched, as the report asks
- [~] `WORKFLOW-portable.md:244` left as written -- a dated measurement, per #952. Reason above.

### TEST

- [x] `grep -rIn "BWJ-ecommerce" | grep -v "github.com/"` -- every survivor is either a deliberate
      dated explanation of the move or the #952 citation above; no line still states a live scope by org
- [x] The 3 permalinks still present and unchanged
- [x] `dkj-policy-bwj.tests.ps1` green, and the full lint + test gate via `open-pr`
- [~] No new test added. Nothing here is machine-read: the refusal is an instruction a session
      executes, and there is no lint that could tell a live scope claim from a dated citation without
      the judgement this branch just applied by hand. Recorded as a gap rather than faked.

### DEPLOY: docs/1537-bwj-scope-org-agnostic

`dkj-policy-bwj` states its scope by **store** rather than by org: `smartwatchbanden` and
`xoxowildhearts`, in whichever organisation each currently sits. Thirteen lines across five files
carried `BWJ-ecommerce/<store>`, and on September 7, 2026 that stopped being true --
`smartwatchbanden` moved to `BWJ-Development` as a fresh repo, the old one was archived, and a fresh
repo carries no redirect.

**What that cost was a refusal pointed at the wrong thing.** Two of those lines are preconditions a
session is told to enforce: `report-issue` step 1 says *"confirm you are in a BWJ store repo"* and
`adopt-dkj-policy-bwj` step 0 refuses outright, both by matching an org path against `git remote get-url
origin`. In the live consumer that match now fails, so the correct response to a stated precondition --
stop -- became the wrong answer, and nothing errors on the way. A session either declines a filing it was
always allowed to make, or files while knowingly ignoring a written instruction. Both checks match the
repo **name** now, which is the half that does not move; the names are still exactly two, so neither
refusal is any weaker.

**The org is left out rather than corrected per repo, and that is the measured choice.** The two stores
are no longer in one organisation, and the move may not be finished: `BWJ-Development/xoxowildhearts`
already exists while `BWJ-ecommerce/xoxowildhearts` is still live and more recently pushed. Naming an
org per repo would be wrong again the day the second store moves; naming neither is right under either
outcome. The one claim that genuinely was about an org -- *"the org has exactly three issue types"* --
was measured in both and holds in both (Task, Bug, Feature), so it carries that measurement instead of a
seam.

Dated measurements keep the names they were written with, per #952, so the three `github.com` permalinks
and the one prose citation of where the #388 measurement was taken are untouched.

**Score:** 3

#### What makes this deploy extra special

N/A -- this repo's audience is its own developers and the consuming repos, and a BWJ store's customers
are not subscribers of a service. The two BWJ consumers do get the substance at the next release: the
skill that tells them to stop in a repo they are allowed to work in stops telling them that.

**Score:** N/A

#### Pull Request

dkj-policy-bwj states its scope by store, not by org

