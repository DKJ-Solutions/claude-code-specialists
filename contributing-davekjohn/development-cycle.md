## Development cycle: `feat/the-branch-document-is-called-development-v1` · 20260827-205719

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

Rename development-cycle to development throughout: the heading (ProgressTitle), the filename in Get-BranchFilePaths, the DevelopmentCycle identifiers, and the prose. Recognise all, write one -- the prior name joins the read-only candidates, the placeholder tolerance list gets an APPENDED form, and the released documents plus CHANGELOG.md keep the name they were written with.

### CREATE

- [x] **The heading**: `ProgressTitle` in `$script:BranchFileDefaults` -> `'Development'`. One constant,
      because it is a wording seam. No reader changed: `Get-BranchFileDeclaredBranch` has matched
      anything up to the first backtick since August 23, so it is title-agnostic already.
- [x] **The filename**: `Get-BranchFilePaths` writes `contributing-davekjohn/development.md`, and
      `PriorNameFile` joins the names that are READ. Eight read, one written.
- [x] **The candidate order**: the prior name sits directly after today's and before the `branch/` pair,
      because it is the nearest predecessor -- every branch open on August 27 carries it.
- [x] **The identifiers**: `DevelopmentCycle` -> `Development` across 14 files, so
      `Split-Development`, `Format-Development`, `Format-DevelopmentReset`,
      `Get-DevelopmentEntryPattern` and `Get-DevelopmentEntryText`. Checked against
      `check-script-contract.ps1` first: none of them is a seam, so caller and callee ship together.
- [x] **The placeholder tolerance list**: one form APPENDED, nothing replaced -- the discipline #952
      established this morning, applied the same day to the rename that would have broken it again.
      The two PR templates carry the new written form.
- [x] **The prose**: 46 files. Document-referring text became "the development document"; the heading
      examples became `## Development:`.
- [x] **The mirrors**: regenerated with `build-shared-scripts.ps1` and `build-config-blueprint.ps1`
      rather than copied by hand, so the 12 mirrored files cannot drift from their roots.
- [x] **`CLAUDE.md`**: the fold exception's second path is now named by its resolver instead of spelled
      out, which closes a gap this rename exposed -- see DEPLOY.
- [~] `park-cycle.ps1`, `cycle-autopark.ps1`, `New-CycleDocument`, `Invoke-ParkCycle`,
      `Get-BranchCycleHeadingLevel` -- **not renamed**. They say "cycle", not "development-cycle", and
      the first two are consumer-facing entry points (a skill and a hook) whose rename is a breaking
      change neither issue asked for.
- [~] Process prose -- **not renamed**, and this is the judgement call in the branch. See DEPLOY.

### TEST

**The branch is its own test case, and that is the strongest assert here.** This document was
scaffolded as `development-cycle.md` before the writer moved, so if the dual-read were wrong the rename
could not ship -- its own entry would be invisible to its own fold. Measured on this tree:

```
File        : contributing-davekjohn/development.md
PriorName   : contributing-davekjohn/development-cycle.md
Resolve-BranchFilePath -Kind File        -> contributing-davekjohn/development-cycle.md
Resolve-BranchFilePath -Kind Cycle       -> contributing-davekjohn/development-cycle.md
Resolve-BranchFilePath -Kind Deployment  -> contributing-davekjohn/development-cycle.md
```

Ten new asserts in `entry-scaffold.tests.ps1` state that on a fixture instead of on this branch, and
they were proved to have teeth by removing the `PriorNameFile` row from the candidate list:

| run | result |
|---|---|
| after the rename | `OK: all 604 asserts passed.` |
| with the prior-name row removed | `FAILS: 4 failed, 600 passed.` -- exactly the four describing a stranded branch |

- [x] `check-plugin-integrity.ps1`: `Summary: 0 error(s).`
- [x] The twelve suites the rename actually touches, run first and individually.
- [x] `Resolve-BranchFilePath` finds this branch's own pre-rename document for all three `-Kind` values.
- [x] No dead reference to the old filename anywhere outside history and the legacy rows -- swept.
- [x] Full gate: `check-plugin-integrity.ps1` plus every suite, the run `open-pr.ps1` performs.

#### The two boundaries this branch drew, so they can be argued with rather than discovered

**"development cycle" means two things, and only one of them was renamed.** It is the name of the
*document*, and it is also the name of the *arc of work* -- four phases, which is literally a cycle.
The document is renamed; sentences about the process are not, because "a second development on the
same subject" and "the development is complete" are not English. So `05-05`'s branch-versioning rule,
`CONTRIBUTING.md`'s "the development cycle is complete", and the comments calling DEPLOY "the
development cycle's fourth phase" all stand. If that reads as a half-done rename, the fix is to name
the process something else -- which is a separate decision, not this one.

**#963 asked for two different words.** Its title said `## Development:`, its body said
`## Developing:`. Dave settled it on `Development` the same day, which is #958's word too, so the file,
the heading and the identifiers all say one thing. Recorded at `ProgressTitle` rather than only here,
because that is where the next reader will ask.

### DEPLOY: `feat/the-branch-document-is-called-development-v1`

The branch's working document is called **Development**. `contributing-davekjohn/development-cycle.md`
becomes `contributing-davekjohn/development.md`, its heading becomes ``## Development: `<branch>` ``, and
the four functions that carried `DevelopmentCycle` in their names carry `Development`. Shorter, and
"cycle" was doing no work the four phase headings underneath it -- PLAN, CREATE, TEST, DEPLOY -- were not
already doing.

**Recognise all, write one**, for the fifth time on this document, and by now the answer is the pattern
rather than a decision: `PriorNameFile` joins the names `Resolve-BranchFilePath` reads and nothing writes
the old one again. Eight names read, one written. A branch open across the rename -- including the branch
that performed it, which is why this is measured rather than asserted -- resolves to its own document for
every `-Kind`. The pair that never existed, `workflow-davekjohn/development.md`, is deliberately absent:
the folder was renamed on August 26 and the document on August 27, so no branch can ever have carried it,
and a row for it would be a name to read that nothing wrote.

**The PR-placeholder tolerance list got a form APPENDED, not substituted** -- which is the
[#952](https://github.com/DaveKJohn/claude-code-specialists/issues/952) discipline applied the same day
it was established, to the very next rename that would have broken it. Its structural assert had to learn
one thing in the process: it demanded every folder-naming form under *both* folder names, and the new
`contributing-davekjohn/development.md` form has no old-folder counterpart. That assert is now
one-directional -- old implies new, never the reverse -- because demanding the reverse would force a name
into the list that nothing can ever have written, which is a different way of making the list lie about
history.

**And the rename exposed a gap in `CLAUDE.md`'s own safety bound, which is the part worth keeping.** The
fold exception is bounded to two paths, and the second was stated as a *filename*. This document has now
been renamed four times -- so on the day of each rename, every branch already open carried a name the
bound did not list, which put its own fold outside the exception it runs under. Nobody noticed, three
times. The bound is now named by its resolver: still exactly two paths, still checkable after the fact
because the commit prints what it touched, and no longer a spelling that goes stale under the tooling it
governs.

Closes [#963](https://github.com/DaveKJohn/claude-code-specialists/issues/963) and
[#958](https://github.com/DaveKJohn/claude-code-specialists/issues/958). #963 named two different words
-- `Development` in its title, `Developing` in its body -- and Dave settled it on `Development`, which is
also #958's word.

**Score:** 4

#### What makes this deploy extra special

`new-branch` writes `contributing-davekjohn/development.md` from here on, with
``## Development: `<branch>` `` as its heading. **Nothing to migrate and nothing breaks.** A branch you
have open right now keeps its `development-cycle.md`: every script and all four gates still read it, fold
it and clear it, exactly as they still read the four names before it and the pre-rename folder. Your next
branch simply gets the shorter name.

Two things you may want to touch, both optional. If your PR template still names the old file, `open-pr`
fills your description in either way -- both forms are recognised -- and the shipped reference template
carries the new one if you would rather copy it. And if you overrode the heading via
`Get-BranchFileWordingOverrides`, your word is untouched: this changed the default, not your answer.

**Score:** 3

#### Pull Request

The branch document is called Development, not Development cycle

