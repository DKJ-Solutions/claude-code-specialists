## Development: `fix/drop-v1-suffix-completion-v1` · 20260903-092526

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

Drop the unconditional `-v1` completion in `new-branch.ps1`. It ran from August 23, 2026; in 209 branches
that reached a merge carrying the suffix, none was ever bumped to `-v2`, so the completion served a case
that had not occurred while charging every caller for it. It was also the direct cause of inbound #1224 --
a consumer wrapping the script for a branch whose name it does not own (a Dependabot PR branch) had a
second branch `<their-name>-v1` created, committed to and pushed.

A `-v<N>` suffix stays valid and is still what the `final` refusal in `branch-info.ps1` points at -- it is
simply typed by hand now, never added. `new-branch` stays idempotent.

Decision by Dave, September 3, 2026 (option B of the discussion on issue #1224).

#### Scope

- `scripts/task/new-branch.ps1` (+ plugin mirror) -- remove the completion block; the name flows through
  as given.
- `scripts/release/open-pr.ps1` (+ mirror) -- the "already merged" note no longer says new-branch
  completes the follow-up name.
- `scripts/lib/entry-scaffold-lib.ps1` (+ mirror) -- one comment that said "-v2 by construction" now says
  "by convention".
- Test suites: `new-branch.tests.ps1` (inputs carry `-v1` explicitly where the test is not about
  completion; new block (b2) guards both directions), `worktree-lane.tests.ps1` (lane branch names lose
  the `-v1`).
- Docs: `05-05-extension.md`, `new-branch/SKILL.md`, `open-pr/SKILL.md`, `DEVELOPMENT-portable.md`,
  `contributing-davekjohn/CONTRIBUTING.md`.

### CREATE

- [x] `new-branch.ps1` + plugin mirror: completion block removed, validation comment trimmed, a
  "DO NOT RESTORE" note left in its place; mirrors held byte-identical.
- [x] `open-pr.ps1` + mirror, `entry-scaffold-lib.ps1` + mirror: stale "completes the name" wording fixed.
- [x] Docs updated across the five surfaces that described the suffix as automatic.
- [x] Final grep sweep: no `new-branch completes` / `every branch name ends in -v<N>` references left.

### TEST

- [x] `new-branch` suite -- 175 asserts pass, including the new (b2) block (bare name stays bare; explicit
  `-v2` left as given).
- [x] `worktree-lane` (35), `entry-scaffold` (669), `branch-info` (40), `branch-document-path` (24),
  `park-cycle` (82), `worktree-lib` (44) -- all pass.
- [x] Full lint gate + all suites via `open-pr.ps1`.

### DEPLOY: `fix/drop-v1-suffix-completion-v1`

`new-branch.ps1` no longer appends `-v1` to a branch name that carries no version suffix; the name is used
exactly as given. A `-v<N>` suffix stays valid and is typed by hand for a second cycle on a subject.
Resolves inbound #1224 -- a consumer wrapping `new-branch` for a branch whose name it does not own
(Dependabot) no longer gets a second branch created. Behaviour change for everyone who runs `new-branch`
here and in the three consuming repos, reached through a plugin update.

**Score:** 3

#### What makes this deploy extra special

For a repo consuming the workflow plugin: `new-branch` stops rewriting the branch name it is handed, which
is what inbound #1224 needed. A consumer not wrapping it for foreign branches still sees the change --
their branches stop gaining `-v1` -- noticed the next time they branch.

**Score:** 3

#### Pull Request

new-branch no longer auto-completes the -v1 suffix

