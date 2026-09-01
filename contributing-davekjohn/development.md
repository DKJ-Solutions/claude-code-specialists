## Development: `docs/sync-seam-grep-dialect-v1` · 20260901-213119

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

#### The assignment, and the found set it is held to

Issue [#1205](https://github.com/DaveKJohn/claude-code-specialists/issues/1205): two **seam-table
rows** call `Get-ShopifySyncReferencePattern` *"the `--grep` pattern"*. The lookup has not used
`--grep` since inbound [#819](https://github.com/DaveKJohn/claude-code-specialists/issues/819), and
the label names the wrong regex dialect to the one reader who needs it right -- a consumer about to
write their own answer to that seam.

#### What was scoped out, and where it went instead

The report named the two rows as the found set and said it had swept neither page nor tree. The sweep
turned up three more sites of the same mislabel in the **script** layer -- `sync-rules.ps1`'s
`.SYNOPSIS`, `sync-main.ps1`'s seam list, and the comment `adopt-shopify-floor.ps1` stamps into a
consumer's own `repo-config.ps1` -- each byte-identical to its `plugins/teams/team-shopify/` mirror.
Left alone here, on #1205's own reasoning: different file, layer and owner, and six files under the
shared-scripts drift lint is not a prose branch. Filed as
[#1206](https://github.com/DaveKJohn/claude-code-specialists/issues/1206).

### CREATE

- [x] `plugins/teams/team-shopify/skills/sync-main/SKILL.md` -- the seam row now names the subject
      match and the .NET engine, and says `--grep` is what the lookup no longer uses
- [x] `plugins/teams/team-shopify/README.md` -- the same correction in its own seam table, in that
      page's em-dash convention, leaving the *"narrow it, never widen it"* half of the row untouched

### TEST

- [x] Swept every `--grep` mention in the tree and classified each: the ones in `SKILL.md:280-289`,
      `sync-rules.ps1`, `sync-main.ps1`, `sync-rules.tests.ps1` and the archived release notes are the
      deliberate historical account of #801 and #819 and read correctly
- [x] Confirmed the three script sites against their plugin mirrors with `diff` before filing #1206,
      so the issue reports three edits applied twice rather than six independent ones
- [x] Read the diff: two single-line changes, nothing else touched, no encoding damage

### DEPLOY: `docs/sync-seam-grep-dialect-v1`

The two seam tables that document `Get-ShopifySyncReferencePattern` -- in the `sync-main` skill page
and in `team-shopify`'s README -- no longer call it *"the `--grep` pattern"*. Both rows now say what
the lookup actually does: the pattern is matched against the commit **subject**, read as its own
field, and is therefore a **.NET** regex rather than git's POSIX basic regex. `Get-SyncReferencePoint`
stopped passing `--grep` on inbound #819; the tables had kept the old label, and the skill page
contradicted its own row ten lines below it.

**Score:** 1

Nothing in this repo reads those two tables to decide anything -- the rule itself has been correct
since #819, and the suite pins it. What it prevents is a maintainer answering a consumer's question
from the summary row rather than from the long note under it.

#### What makes this deploy extra special

This is the row a consumer reads immediately before writing their own `Get-ShopifySyncReferencePattern`,
and it is the only place that tells them which regex dialect their answer is judged in. `--grep` says
git BRE; the truth is .NET. A pattern that works in one and not the other does not fail loudly: it
fails as **a floor that is silently too recent**, so the exclusion rule protects fewer files and the
run still reports a reference point and goes green -- the failure mode the surrounding pages spend the
most words on, and the reason `Get-SyncReferencePoint` deliberately kept no `--grep` prefilter.

**Score:** 2

#### Pull Request

the sync seam tables name the subject match and its regex dialect instead of `--grep`
