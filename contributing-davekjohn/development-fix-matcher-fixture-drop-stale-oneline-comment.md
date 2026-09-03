## Development: `fix/matcher-fixture-drop-stale-oneline-comment` · 20260903-172450

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

Issue #1331. `New-MatcherFixture` in `scripts/tests/source-repo-guard.tests.ps1` carries a
three-line comment demanding its fixture path stay on one physical line, because the test-suite
gate scanned line by line. #1326 (PR #1329) made `test-suite-gate.tests.ps1` fold backtick
continuations before judging a path, so that constraint no longer exists. `New-Tree` above uses
the same one-line shape with no such comment.

### CREATE

- [x] Drop the three stale comment lines above the `$p = Join-Path ...` line in `New-MatcherFixture`; leave the one-line form (issue says it is fine, and it matches `New-Tree`).

### TEST

- [x] `scripts/tests/source-repo-guard.tests.ps1` -- 40 asserts pass.
- [x] `scripts/tests/test-suite-gate.tests.ps1` -- 56 pass, 0 fail; the per-process fixture scan still sees `srguard-$PID-matcher-...`.
- [ ] Lint + tests green, then PR + merge + fold.

### DEPLOY: `fix/matcher-fixture-drop-stale-oneline-comment`

A stale regression comment in `source-repo-guard.tests.ps1`'s `New-MatcherFixture` is removed.
It claimed the fixture path had to stay on one physical line because the test-suite gate scanned
line by line; #1326 taught that gate to fold backtick continuations first, so the constraint it
documented is gone. The one-line path form is kept as-is -- it is fine and matches `New-Tree`
above it, which never carried the comment.

**Score:** 1 -- cosmetic. The comment described a gate behaviour that no longer exists; leaving it
would mislead the next reader of this helper into preserving a constraint that was already lifted.

#### What makes this deploy extra special

N/A -- a comment in a test file; no subscriber of any service reaches it.

**Score:** N/A

#### Pull Request

Drop the stale one-line constraint comment on New-MatcherFixture

