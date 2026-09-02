## Development: `docs/changelog-dropped-ship-cost-v1` · 20260902-175018

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN

Issue [#1235](https://github.com/DaveKJohn/claude-code-specialists/issues/1235): the folded entry for
PR [#1233](https://github.com/DaveKJohn/claude-code-specialists/pull/1233) overstates what a dropped
CI watch costs. Its audience tier says a dropped socket cost a consumer *"a re-checkout of the branch
plus a full local gate run -- lint and every suite"*. The second half is not true, and the correction
is one clause.

#### What was verified before the clause was touched

`scripts/lib/gate-lib.ps1` stores gate evidence keyed on the tree -- `Test-GateEvidence` and
`Save-GateEvidence` around `$script:GateEvidenceMaxAgeMinutes = 240` (line 80; the functions at 357
and 408, the age test at 403). So a resume within four hours against an unchanged tree skips both
gates rather than repeating them, which is what the issue measured on that branch's own ship minutes
after the 591s run it would otherwise have paid twice.

What a dropped ship does still cost is the **re-checkout**: step 2b deliberately hands the primary
checkout back to the trunk ([#1073](https://github.com/DaveKJohn/claude-code-specialists/issues/1073)),
so resuming moves a tree the session may have moved on from. That is the true and smaller claim, and
it is still a reason for the retry #1233 added.

#### Why this is a `docs/` branch on the ordinary route rather than a fix on the original one

The DEPLOY lock ([#884](https://github.com/DaveKJohn/claude-code-specialists/issues/884)) fixes that
section at the moment the PR opens, because that is what the review approved and what the fold folds.
Editing #1233's document after the fact would have refused its merge; editing the document and the PR
body in step would have passed the lock mechanically while doing precisely what it exists to prevent.
So the entry landed as written and the correction arrives here -- which is also what the safety rules
prescribe for an already-published release document.

The diagnosis half of the entry is accurate and is not touched. Nothing in `pr-issues-lib.ps1` or
`ship-pr.ps1` inherited the overstatement either: their code comments already carry the corrected
version, so the changelog entry was the one place the inflated sentence survived.

### CREATE

- [x] Replace the clause in `CHANGELOG.md` -- *"a re-checkout of the branch plus a full local gate
      run -- lint and every suite"* becomes *"a re-checkout of the branch it had just left"*, and the
      paragraph is re-wrapped to the file's width. `it` is step 2b, named in the clause immediately
      before. Three lines replace four; nothing else in the entry moves.

### TEST

- [x] `check-plugin-integrity.ps1` plus every suite, via the `open-pr` gate. There is no new
      behaviour to test -- this branch changes one sentence of prose in a file no script parses for
      this content -- so no suite is added. The gates run because prose in `CHANGELOG.md` is read by
      the entry parser and the release cut, and a re-wrap is exactly the kind of edit that could
      disturb a heading or a `**Score:**` line.

### DEPLOY: `docs/changelog-dropped-ship-cost-v1`

One clause in `contributing-davekjohn/CHANGELOG.md`. The entry for `fix/ship-pr-lost-watch-retry-v1`
(PR #1233) told a later reader that a dropped CI watch had cost a re-checkout *plus a full local gate
run -- lint and every suite*; the gate half is prevented by the evidence cache in `gate-lib.ps1`,
which keys on the tree and skips both gates on a resume within four hours against an unchanged one.
The entry now names what a drop actually costs, the re-checkout step 2b had just left. The
diagnosis half of the entry was accurate and is unchanged.

It forecloses a small mis-valuation rather than a failure: the changelog is where a later reader goes
for what a change was worth, and this one would have told them the retry saves ten minutes per drop
when it saves a checkout. Worth naming because the inflated claim had already been written three
times -- it came from issue #1219's own reasoning, was repeated on #1234, and both have been corrected
on their threads; this entry was the last copy.

**Score:** 2

#### What makes this deploy extra special

N/A -- `contributing-davekjohn/CHANGELOG.md` is this repo's own pending-changes list and is not plugin
payload, so nothing here reaches a consuming repo. The correction does land before the next cut folds
the entry into a release document, which is the only reason the timing mattered at all.

**Score:** N/A

#### Pull Request

the ship-retry entry names the checkout it costs, not a gate run the evidence cache prevents
