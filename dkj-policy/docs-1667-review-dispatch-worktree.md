## docs/1667-review-dispatch-worktree

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

Take the decision #1667 left open: whether a dispatched review should run in `isolation: "worktree"`
instead of relying on the working-copy boundary #1665 is writing.

#### Why this is a measurement and not a weighing

#1667 names one correctness cost as its first bullet -- "a worktree checks out a commit; it does not
carry uncommitted work" -- and files the decision as the owner's because that cost was **inferred**
rather than read. The verification rule this repo applies to an inbound report applies to a report it
filed against itself: read what would have to be true for the explanation to hold. So the branch
probes the harness first and decides on what comes back, rather than reasoning from the name of a
flag.

### CREATE

- [x] Probe `isolation: "worktree"` in this checkout: dispatch an agent with the flag, with an
      untracked file and a tracked edit sitting uncommitted in the primary, and have it report what
      it can see.
- [x] Probe the second half the report does not mention: where the harness puts that worktree, and
      what the primary's own `git status` says while it stands there.
- [x] Record the decision in Chris's portable manual, under *Delegating parallel work* -- the
      section that already names worktree isolation as an option, and therefore the one place a
      reader meets the question.
- [x] File the finding the probe turned up that is not this decision's to make: `.claude/worktrees/`
      is not ignored, so any dispatched worktree reads as a dirty tree while it stands -- #1673.

### TEST

- [x] Probe 1, a dispatched agent carrying `isolation: "worktree"`, September 8, 2026: `pwd`
      reported `.claude/worktrees/agent-<id>`, `git rev-parse HEAD` the primary's own HEAD
      (`73993473`), `git branch --show-current` a branch of the harness's own making
      (`worktree-agent-<id>`), and `git status --porcelain` **clean**. The untracked probe file did
      not exist there and the tracked edit was absent from the file -- so #1667's first bullet is
      **confirmed**: the change under review would not have been in the tree.
- [x] Probe 2, `git worktree add --detach .claude/worktrees/probe-1667 HEAD` in the primary: the
      primary's `git status --porcelain` then carries `?? .claude/worktrees/`, and
      `git check-ignore .claude/worktrees/x` matches nothing. So the worktree the harness opens
      **dirties the checkout it was meant to protect**, for as long as it stands.
- [x] Both probes reverted: worktree removed, probe file deleted, `README.md` restored,
      `git status` clean and `git worktree list` back to the primary alone.
- [x] Review round on the committed diff -- Edith, Nolan and Sebastian in parallel, in the primary
      checkout, which is what this branch decides. Sebastian: no blocking findings, and one claim of
      his that did not hold on checking -- he read `fix/1665-working-copy-boundary` as merged, where
      it is parked. Nolan: the manual is confirmed on-demand and not always-on (its `@`-import is the
      persona body, not the manual), +33 lines / +2,446 B paid only by a session that opens it. Edith
      and Nolan converged on the same defect from opposite ends, and it is repaired: the manual named
      the `working-copy-boundary` block as an established fact, which it is not -- the block is on a
      parked branch, so on the trunk today nothing forbids the hazard. The manual now says that
      plainly and names no artefact that has not landed. Two more taken: the sentence claiming the
      prevented failure "leaves a diff behind" was cut, because #1665 measured that failure as silent
      too, and the closing paragraph now restates **both** costs for the writing case, which is what
      the DEPLOY section already claimed it did.
- [x] Lint gate + all suites green before the push.

### DEPLOY: docs/1667-review-dispatch-worktree

A dispatched review runs in the primary checkout and never in `isolation: "worktree"`, and Chris's
portable manual now says so at the one place a reader meets the question -- the *Delegating parallel
work* section, which already named worktree isolation as an option. #1667 filed the call as the
owner's because its own first bullet was inferred; both halves were probed instead, in this repo, on
September 8, 2026.

The flag is worse than the hazard it would remove. A dispatched worktree is a fresh checkout of the
primary's **HEAD commit** on a branch of the harness's own making, with a clean `git status`: an
untracked file and a tracked edit made seconds earlier were both invisible inside it. A review sits
*before* the PR, so the tree it would read is the one without the change, and what comes back is a
confident "no findings" carrying nothing that says which tree it read. And the worktree lands at
`.claude/worktrees/agent-<id>` **inside** the checkout, ignored by nothing, so while it stands the
primary's own `git status` carries `?? .claude/worktrees/` -- it dirties the tree it was dispatched
to protect. That is why the repo's lane mechanism puts its worktrees in a sibling directory; the
harness flag does not offer the choice.

So the working-copy boundary #1665 is writing stays the whole of the answer for reviewers, and it is
not weakened by being unenforceable: `isolation` is set by the caller at dispatch and lives in no
agent def, so no lint gate could ever have reached it. The existing bullet stands for the case it
was written for -- several sub-agents writing the same files at once -- with both costs now named
there rather than waived.

**Score:** 2

#### What makes this deploy extra special

N/A -- nothing a subscriber of a service sees. This is guidance in an orchestrator's on-demand
manual about how sub-agents are dispatched; no behaviour anybody invokes changes.

**Score:** N/A

#### Pull Request

The review chain is not dispatched into a worktree, and the measurement says why

