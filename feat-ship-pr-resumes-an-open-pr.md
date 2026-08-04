### ship-pr resumes a branch whose PR is already open · Feat · 2026-08-04

**`ship-pr` was unusable on exactly the branch you most want it for: one whose PR is already open.**
Step 1 calls `open-pr.ps1`, whose `gh pr create` was unconditional. A duplicate makes `gh` exit non-zero,
step 1 dies, and **steps 2 through 6 never run** — the CI watch, the merge, the fold, and the issue
verification. So a branch whose PR was opened in an earlier session had to be merged and folded by hand,
which is the five-step sequence `ship-pr` exists to remove. Measured on
[PR #457](https://github.com/DaveKJohn/claude-code-specialists/pull/457): merge, sync, and fold were all
done by hand that evening, one command at a time, because the one script that does it refused the branch.

**The repair is in `open-pr.ps1`, not in the orchestrator, and that placement is the whole design.** One
`gh pr list --head <branch>` up front, and if there is a PR the *only* thing skipped is the create — the
resolves gate, the scaffold gate, the lint gate, the test suites and the push all still run against the
new commits, and the script exits **0** with the PR number. Putting the check in `ship-pr` instead would
have skipped the gates and the push along with the create, and left `open-pr` on its own still failing on
the same branch.

**Title and body are left alone, with one exception that is not a matter of taste.** A body edited on
github.com must not be overwritten by a freshly generated template — a stale title is at least visible on
the PR, an overwritten body is gone. But a `-Resolves` the existing body does not yet carry **is
appended**, because dropping it is the #341–#343 failure arrived at from the other side: GitHub closes
what the body says *at merge time*, so the issue would stay open, and `ship-pr`'s step 6 reads that same
body back and would confirm the same silence. `Add-ResolvesBlock` is idempotent per issue, so nothing is
duplicated and a run with nothing to add writes nothing at all. A failed append is a hard `exit 1`: the
branch is pushed by then, and merging it would publish the loss.

**Symmetrically, an existing body that already says `Closes #332` now satisfies the resolves gate.**
Without that, resuming such a branch would be blocked for not repeating a decision that is already
published on the PR — and that the gate could not change anyway, since GitHub honours the body it has,
not what the run declares.

**The parse became a library function so it could be tested at all.** `Get-ExistingPrRecord` in
`pr-issues-lib.ps1` is a pure function of the JSON text, which is the part worth a test: Windows
PowerShell 5.1 hands a parsed JSON array to the pipeline as a **single** object, and indexing the result
with `[0]` returns `$null` on an empty list — a wrong answer that looks like a right one. Both shapes have
already cost this repo a silent bug. Sixteen new asserts cover the empty list, the single record, several
records, unparseable JSON, a record without a number, and the append being idempotent. `open-pr.ps1`
itself remains the known test gap it always was: it drives a live remote.

**The review of that lookup found a second, worse defect in `ship-pr` itself — and this one was already
shipped.** Step 2, which finds the PR number to merge, parsed gh's answer as
`$prs = @($prList.Output | ConvertFrom-Json)` and then read `$prs[0].number`. Both halves fail on Windows
PowerShell 5.1, and it was **measured, not reasoned**: the count is `1` even for `[]`, so the
`if ($prs.Count -lt 1)` guard — "No open PR found, stopping" — was **dead code that could never fire**;
and `$prs[0]` is the whole `Object[]`, whose `.number` works only by member enumeration, yielding the
**empty string** when there is nothing. With no open PR, `$pr` became `''` and the script went on to run
`gh pr checks ''` and `gh pr merge ''` — in the one script that writes to `main`, with nothing in the
output naming which PR it thought it was merging. It now uses the same tested `Get-ExistingPrRecord`, so
`$null` means no PR and the guard is real. Two asserts pin the old shape as wrong, so a future
simplification back to it fails in the suite rather than on `main`.

**Both lookups now pin `--base main`, which is load-bearing rather than symmetry.** Without it the query
answers "does this branch have an open PR *anywhere*", and a consumer running stacked PRs
(`branch -> branch -> main`) would get the wrong one: `open-pr` would skip creating the PR to `main`, and
`ship-pr` would find and **merge the stacked PR into its intermediate base**. GitHub allows one open PR
per `(head, base)` pair, so with the base pinned there is at most one answer — which is also why
`--limit 1` cannot hide a second candidate.

**Every unreadable answer collapses to "no existing PR", deliberately.** A failed query or a bad payload
falls back to precisely the behaviour this script had all along — a duplicate `gh pr create` that `gh`
refuses with its own message — rather than wedging the PR flow on a network hiccup. Same reasoning as the
resolves gate's undeterminable-state branch.
