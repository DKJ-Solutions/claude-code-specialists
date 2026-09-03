## Development: `docs/fold-hold-divergence-lesson-v1` · 20260903-095913

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

Bypass restored and verified; update the stale claim in Rendall's lens and record the divergence lesson.

#### Where this came from

A session was asked to sync `main` with origin and resolve its merge problems. The working copy stood on
`main`, 39 commits behind, with an unmerged `CHANGELOG.md` and no `MERGE_HEAD` to abort -- the residue of a
fold commit held locally while `GH013` blocked its push. That same fold had since landed from elsewhere, so
the held copy was a duplicate of `eb4a4ae7` (identical entry, identical `· 20260902-210200` timestamp).
Two things came out of untangling it: three docs claim a bypass state that no longer holds, and nothing
anywhere says what to do when a fold cannot push.

### CREATE

- [x] Date Rendall's bypass paragraph (`05-06`, was *"gone at the moment of writing"*) and add the
      fold-side rule: a blocked fold is waited out, never committed locally
- [x] Date Sylvester's `THAT LIST IS EMPTY RIGHT NOW` paragraph (`05-15`) and keep it, naming the push's
      own answer -- `GH013` vs `Bypassed rule violations` -- as the measurement that tells the two states
      apart without admin rights
- [x] Close the `#1244 owns this and this change does not repair it` loose end in `05-15`, now that both
      stranded folds (#1253, #1261) have landed
- [~] `.claude/rules/language-layers.md:151` left alone -- it states what the transfer *did*, in the past
      tense, and is still accurate

### TEST

- [x] `check-plugin-integrity.ps1` + all suites, via `open-pr.ps1`
- [x] The restored bypass verified by the act rather than the settings page: `79897ba9` pushed to `main`
      answering `Bypassed rule violations for refs/heads/main`, where the same commit answered `GH013`
      the day before
- [x] `git ls-tree origin/main contributing-davekjohn/` returns no branch document -- the trunk is clear

### DEPLOY: `docs/fold-hold-divergence-lesson-v1`

Three docs stated that `main-ci-gate`'s bypass list is empty, which stopped being true on September 3,
2026 when Dave restored it. Each is dated rather than swept, per this repo's convention, and the two
lenses gain what the day actually taught.

The load-bearing addition is a rule that did not exist: **a fold whose push is blocked is waited out, not
committed locally.** Holding it looks like a neutral pause and is not one -- it is a `main` commit living
on a single machine, and `main` is what every other machine syncs. Measured the same day: a held fold met
the same fold landing from elsewhere, and `git pull` produced a duplicate entry plus an unmerged
`CHANGELOG.md` with no `MERGE_HEAD`. A session went into untangling it, and the trunk leftovers the hold
was meant to prevent had accumulated anyway. Waiting costs a visible unfolded document; holding costs a
duplicate commit on the shared trunk, and only one of those is cheap to undo.

Sylvester's lens also gains the measurement that identifies the condition without admin rights: the push
answers `GH013 ... Required status check "lint-en-tests" is expected` when the list is empty, and
`Bypassed rule violations for refs/heads/main` when it is not. Nothing in the GitHub UI distinguishes
them for an account that cannot read the ruleset.

**Score:** 3

#### What makes this deploy extra special

It is written from the wreckage rather than from a design discussion. Every claim in it was measured on
the working copy that had to be repaired, including the one that matters most -- that the two folds the
blockage stranded folded unchanged once the bypass returned, which is the whole argument for waiting.

**Score:** N/A

#### Pull Request

The lens's bypass paragraph is dated, and a held fold is not a neutral wait

