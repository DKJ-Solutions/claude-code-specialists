## docs/1846-adopt-step4-documentation-label

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

#### The report this branch came from, and why most of it is not repaired here

[#1846](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1846) reported that
`BWJ-Development/smartwatchbanden` carries no `tier-1` label, so every `report-issue` filing that
reaches tier 1 fails at the `gh issue create`. The symptom is real and was re-measured today. **Its
reasoning is not, and the repair it proposed would have made the repo worse** -- verified before
anything was written:

- **The reason given was that the store never had the label.** It had it and **renamed** it to
  `minor` on September 11, 2026, keeping all 24 issues that carried it
  ([#1841](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1841)). `minor` in
  `smartwatchbanden` carries hex `fbca04`, which is byte-identical to `tier-1` in
  `xoxowildhearts` -- read back from `gh label list --json name,color` on both stores.
- **The repair it proposed** -- `gh label create tier-1` in that store -- is exactly the state the
  step 4 paragraph merged hours earlier forbids by name: two labels for one axis, one of them empty,
  every existing issue on the other, and nothing reporting it.
- **Its claim to be distinct from #1841** does not hold in either direction. #1841's repair,
  [PR #1845](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1845), merged at 11:52 the same
  day and went **further** than #1846 proposed for the reach label: it does not merely report the
  absence, it refuses to create on it.
- **The consumer half is already tracked where it belongs** --
  [smartwatchbanden#548](https://github.com/BWJ-Development/smartwatchbanden/issues/548), open. That
  store answers `Get-ReachLabel` with `'minor'` and the filing works again; this repo neither owns
  that tracker nor that file.

#### What survives, and it is the half #1846 named as this repo's own

Step 4's existence check greps for **two** labels and the step created **one**:

```bash
gh label list --repo <owner>/<repo> | grep -E '^(<reach label>|documentation)\b'
gh label create "<reach label>" ...        # and nothing for documentation
```

So a repo missing `documentation` got a hit in the check and no instruction -- which is #1846's own
phrasing of the defect class, narrowed to the half that still stands. `report-issue` files
`--label documentation` on a doc finding, and `gh issue create` fails on it exactly as it fails on the
reach label. It has never bitten because `documentation` is one of GitHub's default labels and both
BWJ stores carry it; that is what kept the gap invisible rather than what makes it safe.

### CREATE

- [x] Step 4 gains a `gh label create documentation` line, with the colour both stores already carry
      (`0075ca`) and a description stating what the label means here rather than GitHub's default
      wording.
- [x] A paragraph recording the gap, why it never bit, and that the label is load-bearing -- 42 doc
      issues across the two stores, kept where `bug` and `enhancement` were deleted.
- [x] A second paragraph stating that `documentation` gets **no seam**, so this does not read as
      half-answering the reach label's question: nobody has renamed it, so what was missing is a
      command, not a seam. That is the same "written where it has been paid for" answer #1841's own
      paragraph gives one block below.
- [x] `Every other label below` -> `Every other label in this step`, since `documentation` now sits in
      the same block rather than under it.

### TEST

- [x] A guard in `scripts/tests/dkj-policy-bwj.tests.ps1` asserting **the invariant, not the one
      name**: every literal label in step 4's grep has a `gh label create` for it. A third name added
      to the check without its own create line reopens precisely this gap, and an assert pinned to
      `documentation` would pass over it. The `<reach label>` placeholder is skipped -- it is the
      seam's, and its create line is guarded by the reach-label block above.
- [x] Proven to fail on the defect it guards: with the new create line removed the suite reports
      `[FAIL] step 4 creates the 'documentation' label its own check greps for`, 239 passed / 1
      failed. Restored, it is 240 passed.
- [x] Full local gate: `check-plugin-integrity.ps1` plus every suite, via `open-pr.ps1` -- all 92
      suites green.
- [x] Review round on the diff, in parallel: code review, copy edit and security review.
      **Three items came back on the guard and all three are applied.** The tail now anchors on
      `(?=\s|["']|$)` rather than a bare `\b`, which also fires on a hyphen -- a step that gained a
      `documentation-only` label would otherwise have satisfied the assert for `documentation`; the
      locator asserts **exactly one** check line rather than binding to the leftmost of several, since
      the file mentions `gh label list` in prose too; and the loop is gated on that match, so a
      vanished check cannot emit a `[PASS] ... '' label` for a triager to puzzle over. Re-proven on
      both defect shapes: create line removed -> FAIL, renamed to `documentation-only` -> FAIL
      (it passed before this round), repaired -> 240/240.
      The copy edit returned one reordering, applied; the security review returned nothing, and
      confirmed the private-consumer citations sit inside this repo's excerpt bound.

### DEPLOY: docs/1846-adopt-step4-documentation-label

`adopt-dkj-policy-bwj` step 4 now creates every label its own existence check greps for.
`documentation` was checked for and never created, so a repo without it got a hit in the check and no
instruction -- while `report-issue` files `--label documentation` on a doc finding and `gh issue
create` fails outright on a label the repo does not have, exactly as it does for the reach label. The
step gains the create line, a paragraph recording why the gap never bit (`documentation` is a GitHub
default and both BWJ stores carry it) and why the label is load-bearing rather than decorative, and a
second stating that it deliberately gets no seam: nobody has renamed it, so what was missing is a
command and not a seam. A guard in `dkj-policy-bwj.tests.ps1` asserts the invariant rather than the
one name -- every literal label in the grep has a create line -- so a third name added to the check
without one is refused.

**Score:** 2

#### What makes this deploy extra special

The report behind it, [#1846](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1846), was
right about the symptom and wrong about everything else, and its headline repair would have damaged
the consumer it was filed from: `smartwatchbanden` did not lack `tier-1`, it **renamed** it to `minor`
with all 24 issues intact, so creating it back is the empty-duplicate state
[#1845](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1845) had forbidden by name hours
earlier. Verifying the reason rather than the symptom is what turned a harmful one-line fix into the
one narrow thing that actually stood.

**Score:** N/A

#### Pull Request

adopt-dkj-policy-bwj step 4 creates every label it checks for
