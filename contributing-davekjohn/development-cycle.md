## Development cycle: `fix/scaffold-guidance-concat-v1` · 20260826-153119

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### The branch it was opened for was already fixed, and that recount is the plan

Opened to repair the comma-versus-`+` defect in the guidance array
([#924](https://github.com/DaveKJohn/claude-code-specialists/issues/924), filed from a checkout at
`5a29170`). `origin/main` was at `fda2851`:
[#921](https://github.com/DaveKJohn/claude-code-specialists/pull/921) had landed it twenty minutes earlier
against [#915](https://github.com/DaveKJohn/claude-code-specialists/issues/915) -- the parentheses, both
mirrored files, and the regression test #924 proposed. Verified rather than assumed: the current lib returns
30 guidance elements, none of them a bare marker. So #924 is a duplicate of #915 on its main body, and the
first of the five inbound patterns applied to a report this house wrote itself. One `git fetch` was the
whole difference.

**Why the lane made it look unrepaired, which is worth keeping.** `worktree-lane.ps1` bases the lane on
`origin/main`, so the lane's tree HAD the fix -- but the scaffolding is delegated to `new-branch.ps1` in
the **primary** checkout, which was standing on a branch cut before it. Fixed source tree, broken document.
A lane's dossier is written by the primary's scripts, not the lane's.

#### What survives is the last section of that report, and it is real

`check-branch-entry.ps1` derives the phase level from the document's own title and its `[OK]` line quotes
that derivation, under a comment saying why: *"the level in this line is the one that was actually READ,
not a literal"*. Six markers on the failure path are typed anyway, so on August 26 the gate refused
documents for the new levels while reporting the old ones -- it told a reader to demote a `###` to a `###`,
and pointed above "the first `##`" in a document whose phases are `###`. The success path level-aware and
the failure path not is the worse way round of the two: the failure message is the one somebody reads while
they cannot yet see what is wrong.

- [x] Verify #924 against `origin/main` rather than against the checkout it was filed from
- [x] Recount it in public, retitle it to what still stands, and name #915/#921 as the repair

### CREATE

- [x] Compose `$phaseMark` and `$subMark` once, beside the `$phaseLevel` the checks already derive
- [x] Quote them in all six typed places: the heading count, the echoed stray heading, the demote target,
      the preamble finding, its remedy, and the `[OK]` line (which composed a second time)
- [x] Two live comments described the region as *"between the H1 and the first `##`"* and a reset DEPLOY
      section as opening with *"its own `##`"* -- both now name the thing rather than a level. The three
      that narrate a past measured defect keep their literals: that history happened at `##`
- [x] Mirror held byte-identical: `plugins/workflows/contributing-davekjohn/scripts/lint/check-branch-entry.ps1`

### TEST

- [x] `branch-entry-gate.tests.ps1` scenario 9: the same defect fed at two levels through one code path --
      a current-level document must be told `###`/`####`, a legacy-level one `##`. Confirmed **red** on
      both new asserts against the literals before being trusted; the legacy assert stays green under the
      defect, which is exactly why one level alone proves nothing
- [x] `check-plugin-integrity.ps1` green in the lane, and the full suite run by `open-pr.ps1`
- [x] Scenario 2's existing assert (`the finding says to demote it`) still passes -- its fixture is
      legacy-level, where `$subMark` is `###`, so the change is invisible to it rather than tolerated
- [x] Proved the new message on a real refusal rather than only in the suite, and that turned up a second
      defect: `new-branch -Intent` writes the intent as a bare paragraph in exactly the region the preamble
      rule refuses, so `-Intent`, `park-branch` and `worktree-lane -Intent` each produce a document
      `branch-entry` rejects. Two deliberate designs colliding rather than an oversight, so it is filed for
      a decision -- [#925](https://github.com/DaveKJohn/claude-code-specialists/issues/925) -- and this
      document's own intent paragraph moved under PLAN by hand

### DEPLOY: `fix/scaffold-guidance-concat-v1`

`check-branch-entry.ps1` now prints the heading level it actually read in its **findings**, not only in its
`[OK]` line ([#924](https://github.com/DaveKJohn/claude-code-specialists/issues/924)). The gate derives that
level from the document's own title -- deliberately, so a shape change needs no era flag -- and one line
quoted the derivation while six typed `##` or `###`. When the format shifted one level down on August 26,
2026, every refusal therefore described the shape the document no longer had: it named `'##'` headings in a
`###` document, misquoted the stray heading it had just found, and told the reader to demote a `###` to a
`###`. The success path was level-aware and the failure path was not, which is the worse way round -- the
failure message is the one somebody reads while they cannot yet see what is wrong.

The six now quote one composed pair, `$phaseMark` and `$subMark`, built beside the `$phaseLevel` the checks
already use, so there is a single source rather than a literal per message. Two live comments naming a level
were rewritten to name the thing instead; the three that narrate a past measured defect keep theirs, because
that history really did happen at `##`.

**The guard is what makes this more than a rewording.** `branch-entry-gate.tests.ps1` gains scenario 9: the
same defect fed through the same code path at two levels, asserting that a current-level document is told
`###`/`####` and a legacy-level one `##`. Both new asserts were confirmed red against the literals before
being trusted -- and the legacy assert stays *green* under the defect, which is the reason one level on its
own proves nothing.

**This branch was opened for something else and that is the more useful half of its story.** It was meant
to repair the comma-versus-`+` defect in the guidance array; `#921` had already landed that against `#915`
twenty minutes before the report was written, including the regression test the report proposed. The report
was filed from a checkout one commit behind and never fetched -- the first of the five inbound patterns,
applied to a report this house wrote itself. What made it convincing is worth naming: a lane is based on
`origin/main`, but its dossier is scaffolded by the **primary** checkout's scripts, so the lane held a fixed
source tree and a broken document at the same time.

Nothing changes about what the gate accepts or refuses. What changes is that a refusal now describes the
document in front of the reader.

**Score:** 2

#### What makes this deploy extra special

`check-branch-entry.ps1` ships with the plugin, and it is the gate a consumer meets in CI rather than one
they run by hand -- so a consumer who is refused reads this message with no context and no repo history to
fall back on. Being told to demote a heading to the level it already has is worse there than here: a
maintainer of this repo knows the format shifted, and a consumer taking the workflow does not. They notice
the first time a branch of theirs is refused; nothing they already do changes.

**Score:** 3

#### Pull Request

The gate's findings name the heading level they actually read

