## Development: `fix/major-advice-inherits-its-condition-v1` · 20260830-161202

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

Inbound [#1152](https://github.com/DaveKJohn/claude-code-specialists/issues/1152): `cut-release.ps1`'s
new-major guardrail tells the reader the pin edit is theirs only *IF* this repo pins the targeted major --
capitalised, deliberately conditional -- and then closes with *"Both edits belong to this cut"*, which
counts two unconditionally. Reword the closing sentence to inherit the condition, mirror to the plugin,
and pin it in `cut-release-guardrail.tests.ps1`.

#### Verified before building, not inferred

The sentence stands at `scripts/release/cut-release.ps1:831` (pre-change), and the comment directly above
it argues for the conditional reading in so many words -- *"a consumer without one reads a sentence that
does not apply"* -- so the closing sentence contradicts its own stated intent rather than merely reading
oddly. The lens statement in `.claude/specialists/lenses/05-06-extension.md` that also says "both edits"
is correct and untouched: it describes THIS repo, which does have the pin.

### CREATE

- [x] The closing sentence carries the section edit unconditionally and the pin conditionally
- [x] The reasoning above it, beside the paragraph whose intent it was taking back
- [x] Mirrored to the plugin copy with `scripts/sync/build-shared-scripts.ps1`
- [x] The same contradiction one file over, in the consumer-facing `cut-release` skill page: *"Clearing it
      takes two edits"*, *"Neither is done for you"*, *"Both commits go directly on the trunk"* and
      *"those two files only"* all counted two around a bullet that says *"the pin, if your repo has one"*.
      Raised by the code review on this diff and repaired here rather than filed -- it is the same defect
      for the same reader, and a script that has stopped over-counting beside a page that has not is worse
      than either alone

### TEST

- [x] `scripts/tests/cut-release-guardrail.tests.ps1` pins it from both sides -- the count must not come
      back, and the condition must not be dropped in its place -- and its now-stale block heading and
      assertion message follow the text: 92 asserts green
- [x] Built in a lane worktree, so PR [#1154](https://github.com/DaveKJohn/claude-code-specialists/pull/1154)
      could ship from the primary checkout at the same time
- [x] The lint gate and every suite run as `open-pr.ps1`'s own gate; nothing is pre-run beside it

### DEPLOY: `fix/major-advice-inherits-its-condition-v1`

The new-major guardrail's closing sentence no longer counts an edit a repo may not have. The advice refuses
a `X.0.0` cut whose history section does not exist yet, prints the heading to add, and then says the pin in
a test has to be repointed too -- *IF* this repo pins the targeted major, capitalised, because the pin is
repo-owned. The sentence after it took that back: *"Both edits belong to this cut"* counts two, so a reader
who had correctly concluded the pin paragraph was not theirs was told one line later to make a second edit,
and went looking for it. It now reads *"The section edit belongs to this cut, and the pin with it if this
repo has one"* -- naming the edit rather than pointing back at one, and taking the plural with it -- and two
assertions hold it there from both sides: the count must not return, and the condition must not be dropped
in its place. **The `cut-release` skill page carried the same contradiction** around its own conditional
bullet, and it is repaired in the same movement.

This repo has the pin, so its own maintainers read the sentence that was true. The failure this prevents is
the one this repo cannot meet: it lands entirely on a consumer, which is why the fix is in the shared script
rather than in a lens.

**Score:** 1

#### What makes this deploy extra special

A consumer opening their first major meets this refusal at a milestone moment, having just been told the
step is manual because it is deliberate. Until now the message ended by contradicting its own conditional
one line earlier, sending a reader with no pin to hunt for a second edit that was never theirs. Measured on
the documented path in a fresh consumer: after adding the section alone -- one edit, no pin -- the re-run cut
`v1.0.0` cleanly, so the conditional reading was the correct one and the closing sentence was simply wrong
for them.

**Score:** 2

#### Pull Request

The new-major advice's closing sentence inherits the pin condition
