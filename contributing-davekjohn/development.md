## Development: `fix/entry-links-judged-where-the-fold-writes-v1` · 20260828-210550

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

Issue [#1041](https://github.com/DaveKJohn/claude-code-specialists/issues/1041): check 4 of the plugin
gate judges the branch document's links from `$RepoRoot`, and `CHANGELOG.md` left the root on
August 27, 2026. The base has to become the changelog's own directory -- the value
[`open-pr.ps1`](../scripts/release/open-pr.ps1) already computes for its link gate.

#### What the report got right, and the one thing it did not

The symptom, the reason and the cost all stand: there is no root `CHANGELOG.md`, both files sit in
`contributing-davekjohn/`, and the gate demanded a form the fold then breaks.

Its proposed repair does not. Dropping the branch entirely would judge the LEGACY names
(`contributing-davekjohn/branch/branch-deployment.md` and its older sibling) where they sit, one level
BELOW the changelog -- the original defect at a smaller radius. The report flagged those names as
wanting a check before they were dropped with it, and that check is what changed the repair.

### CREATE

- [x] Move the `$changelogRel` resolution above the link scan -- check 4 runs 500 lines before its first
      other consumer, so the value has to exist by then -- and derive `$changelogDirForLinks` from it.
- [x] Repoint the entry branch's base from `$RepoRoot` to that directory, and rewrite the comment block
      that argued for the root.
- [~] Drop the special case, as the report proposed -- declined: the legacy names still need it.

### TEST

- [x] Scenario B4 in `check-plugin-integrity-links.tests.ps1` rewritten: it asserted the repo root BY
      NAME, so it passed while the check was wrong. It now exercises both names -- today's document
      (base = its own directory) and a legacy one (base = one level up) -- and pins the direction by
      asserting the root form DEAD on the legacy file.
- [x] Held against the pre-fix script: exactly the three new asserts fail, 89 pass. They are witnesses,
      not decoration.
- [x] Full gate green, and this section's own link is the live proof -- written as it reads here, which
      the gate refused before this change.

### DEPLOY: `fix/entry-links-judged-where-the-fold-writes-v1`

A changelog entry's relative links are judged where the fold actually writes them, not at the repo root.

Check 4 of [`check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1) validates the branch
document against a different base than its own directory, because its DEPLOY section is pasted verbatim
into the changelog and has to resolve THERE. That base was `$RepoRoot`, which was right for as long as
`CHANGELOG.md` was -- and on August 27, 2026 it moved into `contributing-davekjohn/`, beside
`development.md`. From that day the gate demanded the root form and the fold broke it: a link written as
`../plugins/...`, correct for BOTH files now that they share a directory, was refused as dead, while the
form the gate accepted resolved from `contributing-davekjohn/` after the fold and was dead there. The
document's own guidance had already been repaired -- it says *resolve FROM THIS DIRECTORY* -- so the gate
was the half arguing with the tooling around it. Latent rather than firing: no folded entry carried a
relative link, and the first one to write one got it wrong whichever form it picked.

The base is now the changelog's own directory, read from the same seam the fold and open-pr's link gate
read, so the three cannot disagree about where an entry's text lands. The special case SURVIVES that
repair rather than being dropped, which is the part the report did not have: for today's filename the new
base equals the file's own directory and the branch looks like dead weight, but the legacy
`branch/branch-*.md` names sit one level BELOW the changelog, and a branch open since before the
August 23 merge still carries one. Dropping the case would have reproduced the original defect at a
smaller radius.

The suite had been asserting the root by name, which is why it stayed green through the move. It now
covers both names and pins the direction: the root form is asserted DEAD on the legacy file, so neither
leaving `$RepoRoot` in place nor deleting the case passes.

**Score:** 3

#### What makes this deploy extra special

N/A -- `check-plugin-integrity.ps1` is this repo's own gate and ships to nobody. The portable half of the
convention, `Get-EntryLinkFindings`, was already correct.

**Score:** N/A

#### Pull Request

the entry's links are judged where the fold actually writes, not at the repo root
