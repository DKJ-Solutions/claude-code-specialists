## feat/tidy-machine-skill

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Design settled with Dave: tidy-machine conducts existing scripts, deletes only on prune-merged's existing proof, reports the residue with paste-ready commands. Scope: this checkout + machine-wide lanes.

#### The measurement this branch is built on

`prune-merged -DryRun -IncludeRemote`, September 10, 2026: 32 local branches beside the trunk, 27
provably merged, 5 kept -- and none of the five live work. A 7-day pre-sync backup, three branches
whose PRs were CLOSED unmerged (#1299, #1243, #1260), and one merged-with-the-tip-past-it (#1599).
One of the three also held a whole second checkout, a lane for a PR closed eight days earlier.

#### Two findings filed rather than folded in

- **#1760** -- `prune-merged`'s candidate list carries no worktree filter, so a lane-held merged
  branch dies on git's worktree refusal. Probed here: that refusal takes precedence over the
  unmerged check. This branch orders around it (lane 1 first) and does not repair it.
- **#1762** -- `Get-PasteableRef -Kind Path` refuses every absolute Windows path, because it reuses
  the ref allowlist. This branch carries a local formatter on the single-quote-is-literal reasoning
  and points at that issue.

### CREATE

- [x] `scripts/lib/tidy-lib.ps1` -- the pure classification: the proof ladder, the stale-lane
      decision, orphaned install records, the scratch verdict, the path formatter
- [x] `scripts/maintenance/tidy-machine.ps1` -- the conductor, ten lanes, six of them delegations
- [x] `plugins/dkj-policy/skills/tidy-machine/SKILL.md` -- the page
- [x] Mirror both files into `plugins/dkj-policy/scripts/`, and register them in
      `Get-SharedScriptPairs` so the drift lint holds them
- [x] Register the skill in the three spans the gate names: `README.md` (twice),
      `plugins/dkj-policy/README.md`, `plugins/dkj-policy/scripts/README.md`
- [~] A `-ReapScratch` flag to delete leftover fixture trees -- DROPPED. `scripts/README.md`
      already decided those stay standing (#1668) and names a pattern sweep as the delete
      primitive `New-ScratchPath` exists to remove (#1659). The lane attributes instead, and the
      suite pins the flag's absence

### TEST

- [x] `scripts/tests/tidy-lib.tests.ps1` -- 51 asserts, all green. The pair test in both
      directions (a CLOSED name with a different tip is `recycled`, never `abandoned`), the
      missing-lookup fallback, the age bound applying to `backup/` and nothing else, and three
      structural asserts pinning what the script may never contain
- [x] Driven against this checkout end to end: `-CheckoutOnly` finds the lane and the two
      abandoned branches, `-MachineOnly` finds 13 leftover fixture trees and skips 5 retained
- [x] The first run found ZERO abandoned branches in a repo that has three -- `--state closed`
      is dominated by merged PRs, so the limit never reaches them. Repaired with
      `--search is:unmerged`, and the suite pins that filter
- [x] `check-plugin-integrity.ps1` green (0 errors)

### DEPLOY: feat/tidy-machine-skill

A new `tidy-machine` skill and script clear the clutter this workflow leaves on a machine, in one
command and ten lanes: stale worktree lanes, branches whose pull request was CLOSED without merging,
expired `backup/*` branches, old stashes, an unfolded changelog entry, the `~/.claude` plugin
administration, install records pointing at a checkout that has moved, plugin staleness, and fixture
trees under the scratch root.

It is a conductor rather than a second implementation: six of the ten lanes call a script that
already exists and already has its own suite, and the new logic is pure and testable in
`tidy-lib.ps1`. The one thing it adds to the workflow's vocabulary is a **second proof** -- a pull
request CLOSED without merging, which is the only evidence that separates abandoned work from
unfinished work without guessing from a date. That proof is held to the same name-AND-tip pair test
as the merged one, through the same shared functions, because a name-only match is what inbound
#1190 and #1191 both cost.

It deletes only what `prune-merged` can already prove, on Dave's answer of September 10, 2026;
everything else is classified and handed over with the command. Lane 1 runs first because git
refuses to delete a branch held by a worktree, and that refusal outranks the merge question (#1760).

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo publishes a plugin rather than a subscribed service, so no subscriber notices a
maintenance command. The reader who does is a consumer developer, and that is the tier-0 answer above.

**Score:** N/A

#### Pull Request

A machine-wide tidy: one command for the clutter this workflow leaves behind

