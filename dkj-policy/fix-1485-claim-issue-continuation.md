## fix/1485-claim-issue-continuation

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

#### What is being repaired, and what is deliberately not

The defect is a boundary with no arrow on the far side of it. Every framing of `claim-issue` says
what the step is NOT -- the frontmatter's *"not a replacement for new-branch"*, the three lines under
`## What this skill is NOT`, and a success line reading *"the work **can** start"* -- and none says
what it is followed **by**. So a session that obeys the page stops after a clean claim and asks
whether to proceed, which is the intermediate question Chris's persona body forbids.

Verified against the tree before any edit, all three citations standing (only the report's path is
stale by one rename, `plugins/workflows/` -> `plugins/dkj-policy/`). The report's own **Not verified**
lead was answered rather than carried forward: `park`, `new-branch`, `open-pr` and `start-task` all
pair a boundary section with a forward statement, and both `CONTRIBUTING` pages sit inside a numbered
cycle -- `claim-issue` is the only page whose fence is terminal. So the scope is exactly the three
surfaces #1485 names, and no wider.

### CREATE

- [x] `SKILL.md` frontmatter: the description ends on a forward statement, since it is the half a
      session reads before opening the page
- [x] `SKILL.md`: a positive counterpart to `## What this skill is NOT`, placed directly after it, so
      the fence is immediately followed by the arrow
- [x] `scripts/task/claim-issue.ps1`: the fresh-claim verdict hands over the way `already-yours`
      already does, and `-- the work can start` stops reading as permission
- [x] Regenerate the plugin mirror via `scripts/sync/build-shared-scripts.ps1`
- [x] Chris's persona body: say out loud that a claim establishes the chain

### TEST

- [ ] Lint gate + all suites green (`open-pr.ps1` runs both)

### DEPLOY: fix/1485-claim-issue-continuation

`claim-issue` now says what follows a successful claim, so a session that obeys the page carries
straight on into the work instead of stopping to ask. Three surfaces changed: the skill page gains a
forward-pointing section beside its `## What this skill is NOT` fence (and a description that ends on
the arrow rather than the boundary), the script's fresh-claim verdict hands over the way its
`already-yours` verdict always has, and Chris's persona body states out loud that a claim is what
establishes the chain.

The defect was never a missing rule -- it was a boundary with no arrow on the far side of it. Every
framing of the step said what it is NOT, so stopping after a clean `[OK]` read as obedience rather
than as the failure it is.

**Score:** 4

#### What makes this deploy extra special

A consumer running this workflow meets the same stall on every issue pickup: their session claims
correctly and then hands the turn back with *"say the word"*. The repair travels with the plugin, and
it costs them no adoption step -- the page, the script and the persona all arrive on the next update.

**Score:** 3

#### Pull Request

claim-issue says what follows a successful claim, so the work continues in the same turn
