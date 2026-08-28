## Development: `feat/prune-merged-classifies-remote-heads-v1` · 20260828-212004

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

Give prune-merged.ps1 a report-only -IncludeRemote pass that reads git ls-remote --heads and classifies each head with the two proofs the script already computes locally, so a merged leftover and live parked work stop being hand-derived per head (issue #1042). Deletes nothing on the remote: a provably merged head is handed over as a paste-ready git push --delete line, a head with neither proof is reported Kept with its reason.

### CREATE

- [x] `scripts/task/prune-merged.ps1`: add the report-only `-IncludeRemote` switch -- read
      `git ls-remote --heads <remote>`, classify every head that is not the trunk with the two proofs
      the local pass already computed (ancestor of the trunk, or a merged PR), print a paste-ready
      `git push <remote> --delete <branch>` for a proven head and `Kept ... -- <reason>` for one with
      neither. No git call in the file gains a `--delete` argument.
- [x] Same file: stop the run exiting early when the trunk is the only local branch and `-IncludeRemote`
      was asked for, and make the closing `ls-remote` hint name the switch instead of standing alone
      when it did not run.
- [x] Same file: the header -- `.DESCRIPTION` (why the pass exists, and why it does not weaken the
      declined remote-delete permission), `.PARAMETER IncludeRemote`, an `.EXAMPLE`.
- [x] Regenerate the plugin mirror `plugins/workflows/contributing-davekjohn/scripts/task/prune-merged.ps1`
      via `scripts/sync/build-shared-scripts.ps1` so the drift lint stays green.
- [x] The docs that a consumer reads: the `prune-merged` skill (the new switch is required there by
      lint check 18) and Derek's lens bullet that records the declined remote-delete permission.

### TEST

- [x] `scripts/tests/prune-merged.tests.ps1`: a scenario for the remote pass -- a merged head and an
      unmerged head both pushed, `-IncludeRemote`, asserting the paste-ready line, the `Kept` line with
      its reason, and that BOTH heads are still standing on the remote afterwards.
- [x] Same suite: widen the structural assert from `'--delete` to a quote of either kind, so the
      double-quoted argument form this change makes tempting is covered too.
- [x] Run the full gate -- `check-plugin-integrity.ps1` + every suite.

### DEPLOY: `feat/prune-merged-classifies-remote-heads-v1`

`prune-merged.ps1` gains `-IncludeRemote`: it now reads `git ls-remote --heads` and says what each head
on the remote actually is, instead of only naming the command that lists them.

That list is the only read that surfaces a parked branch, and in it a merged leftover and live parked
work look identical. Telling them apart was four commands per head -- ancestry, a PR lookup, a diff
against the trunk, the head's own commit message -- and it had to be redone every time, because nothing
in the output remembers the answer. Measured three times in two days, on three separate threads (#992,
#1035, #1039); twice the session also had to hand-write a *don't sweep this one* warning about somebody
else's live head. That warning is now a printed line.

The pass puts every head that is not the trunk through **the two proofs the script already computed for
local branches**, and prints one of two things: `git push origin --delete <branch>` for a head it can
prove is merged, or `Kept origin/<branch> -- live work` for one it cannot. **It runs neither.** That is
what keeps it inside the July 27, 2026 decision rather than around it: what was declined was *executing*
a remote delete, and handing the command over paste-ready is what that decision says should happen
instead. Because a head is only ever named on positive proof, the set the report points at is exactly
the set that is safe to lose.

Two smaller things travel with it. A clone with nothing but the trunk no longer ends the run early --
that was the one state in which the closing line about the remote was never printed, and it is the state
in which the remote question matters most. And the suite's structural assert widened from `'--delete` to
a quote of either kind, because the file now contains those words in a double-quoted string on purpose;
a real call written `"--delete"` would have slipped past the old form while looking exactly like the
printed line.

**Score:** 3

#### What makes this deploy extra special

A guardrail was extended by doing more of what it already said, not less. The declined permission has
two halves -- don't run the delete, hand over the command -- and only the first had ever been built.
Reading the second half as the specification is what turned "add a remote pass" from an erosion of the
rule into an implementation of it, and the test that proves it is the same one that used to prove the
script's restraint.

**Score:** 2

#### Pull Request

prune-merged classifies the remote heads it used to only name
