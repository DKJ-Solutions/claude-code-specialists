## fix/1673-ignore-agent-worktrees

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

Ignore `.claude/worktrees/` so a dispatched agent's worktree no longer reads as a dirty tree; decide
what, if anything, reports a stranded worktree once `git status` cannot.

#### What verifying the report changed about the plan

The reported symptom held -- `git check-ignore -v .claude/worktrees/x` matched nothing, and all four
refusals #1673 names are real. But the *reason* was only half of it. The tree walks that matter here
are **filesystem** walks, which `.gitignore` does not affect at all, so the plan grew a second half
and shed a third:

- **In:** the ignore, a way to ask "is a worktree standing inside this tree", and the lint gate
  naming that cause instead of leaving an operator inside 26 findings that point at the wrong files.
- **Out, and filed as [#1678](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1678):**
  making the gate work *through* a nested worktree. That is ~20 walk sites plus three suites behind
  one predicate, it needs its own meta-gate or it is the enforced-by-memory shape #1665 was filed
  against, and "refuse cleanly" is a defensible permanent answer. Not a decision to make silently in
  a `.gitignore` commit.

### CREATE

- [x] `.gitignore`: anchored `/.claude/worktrees/`, in the house style of the `/Microsoft/` block --
      stating that the harness writes it, why it is anchored, and the honest cost (a stranded
      worktree is now invisible to `git status`).
- [x] `scripts/lib/worktree-lib.ps1`: `Get-NestedWorktreePath`, a pure function of the same porcelain
      the file's other readers take, reusing `Get-WorktreePathKey` rather than re-deriving the
      separator/case/trailing-slash normalisation a third time.
- [x] Mirror it into `plugins/dkj-policy/scripts/lib/worktree-lib.ps1`, byte-identical, as the
      shared-scripts drift lint requires.
- [x] `scripts/lint/check-plugin-integrity.ps1`: a pre-flight block that reads the porcelain and
      `Add-Error`s a finding naming the worktree, ahead of the findings it explains.
- [~] Exclude the nested path from the walk sites -- dropped, and filed as #1678. See PLAN above for
      why this is a decision rather than an omission.

### TEST

- [x] `scripts/tests/worktree-lib.tests.ps1` section 9: nested found, sibling `<repo>-lanes/` not
      reported, the shared-text-prefix trap, the primary never self-reported, empty/malformed
      porcelain, and an unreadable root answering empty rather than matching everything.
- [x] Whole suite green -- 73 asserts.
- [x] End-to-end against a **real** nested worktree, which is the one thing the unit tests cannot
      reach: with a probe standing, `git status --porcelain` no longer reports it (the ignore holds),
      and the gate's finding prints at output line 110 against the first duplicate-id at line 112.
- [x] Probe worktree removed; `git worktree list` back to the primary alone.
- [x] Full lint gate + all suites via `open-pr.ps1 -GatesOnly`.
- [x] Pure ASCII confirmed in all four changed `.ps1` files.
- [x] Review round -- Victor #19, Sebastian #23, Edith #17 in parallel on the diff. Two independent
      reviewers converged on the same blocking finding (the raw printed path); all three findings
      folded in, and re-verified against a worktree registered at `.claude/worktrees/pro be; rm -rf x`.

### DEPLOY: fix/1673-ignore-agent-worktrees

A dispatched agent's worktree lands inside the repo at `.claude/worktrees/agent-<id>`, and nothing
ignored it -- so the primary checkout read as dirty for as long as one stood, which is a refusal in
`cut-release.ps1`, in `prune-merged.ps1` on a branch, and in `worktree-lane.ps1 -HandBack`. It is now
ignored, anchored so it cannot silence a legitimately-named folder deeper in the tree.

The larger half is one `.gitignore` cannot reach. The lint gate and three of the suites walk the tree
with `Get-ChildItem -Recurse`, which reads the filesystem rather than git, so a nested worktree is a
second complete copy of the repo they are standing inside: every count doubles (`*-agent.md` 26 to
52, `*.ps1` 236 to 472) and `check-plugin-integrity.ps1` fails with 26 duplicate-id errors, each one
accusing the **real** file and naming the worktree's copy as the legitimate claimant. An operator
reading that has no route back to the cause. The gate now reads `git worktree list --porcelain`
through the new `Get-NestedWorktreePath` and reports the worktree first, saying in as many words that
the duplicate findings below it are a consequence rather than real.

The path that finding prints is guarded, which is not incidental: `git worktree add` is not held to
`check-ref-format` the way a branch name is, so a registered path may carry spaces, shell
metacharacters or format characters that make a printed line read as something other than what it
says -- and the finding names the path twice, once as prose and once inside a remedy the reader is
invited to run. This repo had already answered that shape at
[#1637](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1637) and
[#1638](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1638); the answer is reused
rather than re-derived, so the command reads `<path>` when the real one is unsafe to paste and a note
says why.

Whether the gate should instead *work through* a nested worktree is left open deliberately and filed
as [#1678](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1678): it is ~20 walk sites
plus three suites, it needs a gate of its own or it is enforced by memory, and refusing cleanly is a
defensible permanent answer.

**Score:** 3

#### What makes this deploy extra special

N/A. The two things that change behaviour are both repo-local -- the `.gitignore` entry and
`check-plugin-integrity.ps1`, which is not mirrored into any plugin. A consumer receives the new
`Get-NestedWorktreePath` in the `dkj-policy` mirror of `worktree-lib.ps1`, but nothing on their side
calls it yet, so nobody downstream notices this release.

**Score:** N/A

#### Pull Request

Ignore the harness's agent worktree directory
