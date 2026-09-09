## docs/1678-nested-worktree-refusal

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
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

#### The fork this branch answers

[#1678](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1678) does not report an
unrepaired symptom -- [#1673](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1673)
(PR #1684) is landing the `.gitignore` entry and the gate's named finding. What it leaves open is a
fork: should the gate be made to work *through* a nested worktree (~20 `Get-ChildItem -Recurse` sites
plus the suites, behind one shared predicate and a meta-check of its own), or is refusing cleanly the
permanent answer? Either is defensible, which is why it was filed rather than decided in a
`.gitignore` commit. This branch decides it, and records the decision where a later reader already
looks for the gate's declined rules.

#### The verdict

Refuse cleanly; the exclusion is DECLINED. Four grounds, each measured on this tree rather than
transcribed from the report.

### CREATE

- [x] Verify the symptom and the doubling with a probe worktree, rather than taking the report's
      numbers on trust
- [x] Verify the chokepoint claim -- that a lint failure returns before the test gate is reached
- [x] Verify the three suites the report names, one by one
- [x] Record the declined rule in Sylvester's lens, beside the other measurements the gate's shape
      rests on

### TEST

- [x] The lint gate and every suite are green (the gate run before the push)

### DEPLOY: docs/1678-nested-worktree-refusal

The lint gate's tree walks are filesystem walks, so a worktree registered inside the repo is a second
complete copy of the tree it is standing in: every recursive count from the root doubles exactly
(`*-agent.md` 26 to 52, `*.ps1` 233 to 466) and the gate fails with 26 duplicate-id errors, each one
accusing the **real** file. #1673 repairs what an operator reads. What it deliberately left open, and
what this branch answers, is whether the gate should instead be made to work *through* such a worktree
-- roughly twenty `Get-ChildItem -Recurse` sites plus the suites that walk the root, behind a shared
predicate and a meta-check of its own.

It should not, and the exclusion is now recorded as DECLINED beside the gate's other measured-and-
declined rules, so the option is priced rather than re-argued the next time somebody meets the 26
errors. Four grounds, each measured on this tree: the lint half of `Invoke-WorkflowGates` returns
before the test gate is ever reached, so on the documented route the doubling suites never run and
excluding the path from them buys a caller nothing; the report's price was one suite too high --
`template-selfcontained.tests.ps1` walks `plugins/`, not the root, and its count is unmoved by a probe
worktree, leaving two rather than three; a predicate every future walk must remember to call is the
enforced-by-memory shape #1665 was filed against, in a file already carrying 36 numbered checks; and
`worktree-lane.ps1` has already decided where a worktree belongs, placing lanes outside the tree for
exactly this reason. The residual is stated rather than left to be found: under `-SkipLint` those two
suites still take a doubled set in silence, which is what that switch means everywhere here.

**Score:** 2

#### What makes this deploy extra special

N/A. One repo lens changes and nothing else -- no script, no manifest, no plugin payload. The gate it
describes is `check-plugin-integrity.ps1`, which is not mirrored into any plugin, so a consumer
receives nothing from this and their own gate's answer to the same fork stays theirs.

**Score:** N/A

#### Pull Request

The lint gate refuses a nested worktree rather than walking through one
