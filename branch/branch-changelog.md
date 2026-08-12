## `fix/new-branch-stacked-idempotency` changelog

### Branch title

new-branch decides idempotency on the owner the branch files declare

### Branch ID

20260812-091406

### Branch type

fix

### What does the change on this branch bring to main?

`new-branch.ps1` decided whether to write the two files in `branch/` with two tests that did not ask
what the comment above them said they asked. `$changelogTaken` asked only whether the entry was
**filled**; `$progressTaken` asked only whether the owner was **not the trunk**. Both are true for any
branch created off a branch whose entry has been written but not yet folded — the ordinary stacked
branch — so both files were skipped, and the skip was printed under the **new** branch's name:
`Branch files already written for 'feat/child' - nothing done.` Nothing had been written for it, and
the files still held the parent branch's entry, heading and all. The branch silently started out
claiming another change's work as its own.

One comparison replaces both tests: the branch each file **declares**, measured against the branch you
are on. `Get-BranchFileDeclaredBranch` already returned it and was already used correctly one line
further down, and its heading regex reads either file — so the trunk's reset state means write, a
rerun on this branch means keep, and a foreign owner means write and say whose file was replaced.

Where that write would be unrecoverable, it is refused instead. Replacing a committed entry costs
nothing — git holds it on the branch it belongs to — but `git checkout -b` also carries **uncommitted**
edits into the new branch, and there they exist in exactly one place. A dirty foreign file is therefore
kept and named out loud, which still repairs what was reported: the failure was the silence and the
wrong name, not the keeping.

Reported from a consumer as inbound
[#615](https://github.com/DaveKJohn/claude-code-specialists/issues/615), verified against `main` at
`569e656` before the repair. Two regression scenarios were added to
`scripts/tests/new-branch.tests.ps1` and measured against the pre-fix script: **6 of the 12 new asserts
fail on it**, and all 110 pass after.

### Significance

#### Tier 0

The stacked-branch flow is uncommon here — `main` always carries `branch/`, so branching off the trunk
is the normal move and the defect needs a stack to fire. What this buys is the removal of a failure
that reports success: if it does fire here, the first reader who could notice is whoever reads
`CHANGELOG.md` after the fold, by which point the wrong entry has been copied twice.

**Score:** 2

Is there a tier above this one?

#### Tier 1

A whole failure shape leaves the workflow scripts: a gate whose message states the opposite of what
happened. The scaffold gate downstream cannot catch it either — it sees a fully written entry and
passes, because the entry *is* fully written, just for a different change. The repair also writes down
the overwrite-versus-refuse distinction (committed work is recoverable, uncommitted work is not) in a
place the next destructive path can reuse.

**Score:** 3

Is there a tier above this one?

#### Tier 2

This is a consumer's report from a real migration, on a script consumers receive through a plugin
update rather than by choosing to. Their stacked branch is not an exotic move — it is what you do when
the trunk does not carry `branch/` yet, which is every repo mid-adoption. Before this, that branch
started out with somebody else's entry and nothing said so.

**Score:** 4

### Pull Request
