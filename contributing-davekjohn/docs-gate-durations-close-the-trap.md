## docs/gate-durations-close-the-trap

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

PR #1364 made the test gate record per-suite durations. That falsified two statements written earlier the
same day on [#1358](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1358), both by this
chain:

- `../.github/workflows/ci.yml` -- *"the gate records no per-suite duration"*, inside a paragraph headed
  BEWARE THE RECONSTRUCTION TRAP.
- `../.claude/specialists/lenses/06-25-extension.md` -- the same claim opening its reconstruction-trap
  section.

**Wrong in the direction that matters:** both tell the next reader to reconstruct a duration from log
timestamps, which is the exact method that produced the bad figures on #1358, and they now say it of a gate
that prints the answer.

#### And a second, less obvious staleness in the same lens section

That section closes by concluding *"the plateau is four files, not five"* and proposing a decision on it.
That conclusion was itself re-derived from the same reconstructions it was correcting -- it fixed the two
bad members and then trusted the method for the membership list. The first recorded run shows a band of
about a dozen suites and a different makespan-setter. Corrected rather than deleted: the parts that hold
(entry-scaffold is genuinely not a member; the four `check-plugin-integrity-*` figures were genuinely
exact) are kept, and the overreach is named as the same error one level up.

### CREATE

- [x] `../.github/workflows/ci.yml`: the paragraph now opens **DO NOT RECONSTRUCT DURATIONS FROM LOG
      TIMESTAMPS -- THE GATE PRINTS THEM**, points at the per-shard table, and keeps the warning with its
      reason restated -- the buffered output still makes every log timestamp a finish time, so the trap is
      live for anyone who ignores the table.
- [x] `../.claude/specialists/lenses/06-25-extension.md`: the trap section's opening claim is now past
      tense with a forward link, and the trap itself is kept because the misleading timestamps are still
      in every log.
- [x] Same file: the *"four files, not five"* close is corrected, and a new section records the instrument,
      the first recorded run, and the two facts it changed (`new-branch` sets the makespan; seven suites in
      the band appear in none of the five).
- [x] That new section carries the generalisable lesson rather than only the numbers: **build the
      instrument before the argument**, and print a derivation's assumption beside the figure -- which is
      why the table carries the lane offset and not just the duration.
- [x] Every figure in the new section states **30 lanes on a 32-core workstation**, because #1351 measured
      3.7x between that and the 4-lane CI shape, and this document's own standing rule is that a gate
      figure without its lane count says nothing.

#### And a third falsified claim arrived mid-branch, from another session

While this branch waited on CI, [PR #1363](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1363)
(`docs/shard-floor-is-the-slowest-file`, @maikel-bwj) merged **after** #1364 and added a docstring paragraph
to `Invoke-TestSuiteGate` -- the very function #1364 had just instrumented -- stating *"it records no
per-suite duration"*, plus *"recording durations to feed one buys nothing here."*

**Git merged it cleanly, because the two edits sat in different parts of the same docstring.** So `main`
carried both *"PER-SUITE DURATIONS ARE RECORDED, NOT RECONSTRUCTED"* and *"it records no per-suite
duration"*, 21 lines apart in one comment block. Neither branch was wrong when written; #1363 was cut
before #1364 existed and landed after it.

- [x] `../scripts/lib/native-capture-lib.ps1`: the warning now opens **READ THE TABLE THIS FUNCTION
      PRINTS, NOT THE LOG TIMESTAMPS** and keeps the rest of #1363's paragraph intact -- its shard-scale
      crossover, its plateau evidence and its 3.6-4.0x local-to-CI ratio are all correct and none of it
      needed touching.
- [x] Same file: *"recording durations to feed one buys nothing"* is kept for the **bin-pack** it was
      written about, where it is true, and separated from the reason recording them does pay -- a
      partition cannot beat its longest file, but that only helps once you know which file that is.
- [x] Both mirrors regenerated again after the reconciliation.
- [x] `../.github/workflows/ci.yml`: #1363's `~35s -> ~20s` provisioning correction is kept (theirs is
      the newer measurement); the paragraph is checked to read as one argument rather than two stitched
      together.
- [x] Same file: the phrase *"a five-file plateau with four members"* no longer asserts a corrected
      count. The recorded run disproved *"four"* as thoroughly as it disproved *"five"*, so the comment
      now names the error and sends the reader to the table instead of to any number in prose.

### TEST

- [x] Full local gate (lint + all 65 suites) via `open-pr.ps1`, then the same gate as CI. No script
      changed on this branch, so the gates are here to catch the link-scan and doc-shape checks that do
      read these two files -- check 4 resolves the new relative links and the new intra-document anchor.
- [x] `grep` for the falsified phrasing across the tree: no remaining occurrence of the claim that the
      gate records no per-suite duration.

### DEPLOY: docs/gate-durations-close-the-trap

Two documents were telling readers to do the thing that had just been fixed. `ci.yml`'s floor comment and
the performance lens both said *"the gate records no per-suite duration"* and instructed the next reader to
reconstruct one from log timestamps -- written hours before PR #1364 made the gate print those durations
directly, and left standing by it.

That is the wrong way round to be stale: the sentence does not merely go out of date, it actively
recommends the method that produced the bad numbers on #1358 in the first place. Both now point at the
per-shard table the gate prints, and both keep the warning with its reason intact, because the buffered
output still makes a log timestamp a finish time for anyone who reads the log instead of the table.

The lens also closed with *"the plateau is four files, not five"*, a conclusion re-derived from the same
reconstructions it was correcting. The recorded run puts about a dozen suites in the band and a different
suite at the top, so that section now records the instrument and what it changed -- and keeps the parts of
the earlier correction that survived.

**Score:** 2

#### What makes this deploy extra special

It is a branch whose entire subject is prose this chain wrote a few hours earlier and then invalidated by
succeeding. Worth doing rather than filing, because a stale sentence that names a *method* is worse than
one that names a number: the number is checkable, the method just gets followed. The lesson kept in the
lens is the one that generalises past this issue -- build the instrument before the argument, and print a
derivation's assumption next to the figure it produced.

**Score:** N/A

#### Pull Request

Close the reconstruction trap in the docs that still describe it as open
