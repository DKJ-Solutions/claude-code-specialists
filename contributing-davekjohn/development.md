## Development: `fix/prune-merged-proof-by-oid-v1` · 20260901-150725

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

Issue #1191: both passes matched the merged-PR set by branch NAME, so a recycled name inherited the
previous branch's merge and its unmerged work was force-deleted. The repair is the name-and-tip pair,
applied in both passes.

### CREATE

- [x] `prune-merged.ps1`: ask gh for `headRefName,headRefOid` and build a name -> head-commits map
      (several per name, since a recycled name merged twice has two). No `--jq` -- `ConvertFrom-Json`
      needs no Windows quoting for two fields, and an unparseable body is treated as a non-zero exit.
- [x] `Get-MergedProof`: one function for both passes, three answers -- `merged PR`, `recycled`, none.
- [x] The local pass resolves its own tip (`rev-parse --verify --quiet refs/heads/<b>^{commit}`); an
      unreadable tip reads as "not this commit", the safe direction.
- [x] The remote pass uses the sha `ls-remote` already reported. It matters most there: that pass hands
      over a `git push --delete` line for the copy of last resort.
- [x] A recycled name gets its own kept reason, because "no merged PR" describes a lookup that came up
      empty when this one came up full.
- [x] Header block 4b rewritten -- it claimed the proof this branch repairs.
- [x] Mirror `plugins/workflows/contributing-davekjohn/scripts/task/prune-merged.ps1` byte-identical.
- [x] `skills/prune-merged/SKILL.md` and Derek's persona both stated the name-based proof; both corrected.

### TEST

- [x] Three cases added to `prune-merged.tests.ps1`: (o) a recycled name survives, (p) a genuine squash
      merge is still deleted, (q) `-IncludeRemote` prints no delete command for a recycled head.
- [x] The suite had NO gh at all, so proof (b) -- the arm that force-deletes -- was never exercised. A
      `gh.cmd` stub beside the fixture supplies it: no network, no GitHub, no credential.
- [x] The stub honours `--jq`. Arg-blind it was green on the BROKEN script too, because the pre-fix
      source asked for `--jq` and read a JSON array as one unusable line -- a test that passes on the
      defect it was written for. Verified in both directions: (o) and (q) fail against the pre-#1191
      source, (p) passes against both, so the squash case is not what the repair cost.
- [x] Full suite green: 91 pass, 0 fail (was 77).
- [x] `check-plugin-integrity.ps1` + all suites, via `open-pr.ps1`.

### DEPLOY: `fix/prune-merged-proof-by-oid-v1`

`prune-merged.ps1` proved a merge by branch **name**, so a name that had been merged once and then
recreated inherited the old branch's proof forever -- and its new, unmerged commits were force-deleted
with `merged PR` printed beside them. That is not hypothetical recycling: `deleteBranchOnMerge`, which
this script's own header leans on for the remote half, is exactly what frees a name for reuse. Measured
in a consumer whose pre-task sync names its branches `sync/live-<date>`, where a second sync the same day
reuses the name: `sync/live-2026-09-01` was deleted on PR #141's merge while the commit it stood on
belonged to #159, still open. Both passes now require the branch's tip to BE the merged PR's head commit,
and a recycled name is kept with a reason saying so. It matters most in `-IncludeRemote`, which hands over
a `git push --delete` line for the copy of last resort.

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo's own maintenance tooling. No subscriber of a service notices a local branch-reaping
script, and nothing about the consumer-facing product changes.

**Score:** N/A

#### Pull Request

prune-merged proves a merge by the PR's head commit, not by its branch name
