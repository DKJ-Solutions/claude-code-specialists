# Development cycle: `feat/cycle-file-branch-lifetime-v1` · 20260823-154316

<!--
     The plan for this branch. Every step must be resolved before the PR: open-pr and
     ship-pr both refuse while anything is still "- [ ]", and there is no -Force.

       - [ ] not done yet
       - [x] done
       - [~] dropped -- why it turned out not to be needed

     The dropped mark exists so nobody is pushed into ticking a box for work they did
     not do. It keeps its line and its reason, which is the half worth reading later.

     PLAN / CREATE / TEST / DEPLOY are the arc, not a quota: a phase with nothing
     under it is a statement that this branch had nothing there. The headings are
     invisible to the gate, which reads step marks only.

     DEPLOY takes no steps of its own. It is not a step but the result -- the
     section at the foot of this file, which is the part that travels verbatim into
     CHANGELOG.md at the merge. So a step written for after the merge is refused
     here: what happens after the merge is what DEPLOY describes, not a box to tick.
-->

## PLAN

The shape this branch implements: `development-cycle.md` exists only while a branch is open.
`new-branch` creates it, the fold REMOVES it instead of resetting it, and the trunk carries no copy.
The form stays in `Format-DevelopmentCycle` and no template file is added -- the form is parameterised
(the wording seam, the trunk name, the branch name, two stamps), so a static copy in the repo would be
a second definition of the same shape.

Two decisions taken with it. **`Resolve-BranchFilePath` keeps its declared-branch test** rather than
reverting to a plain existence test: a branch created before this change carries the trunk's reset copy
beside its legacy pair, and existence alone would hand it the empty file, so the simplification is not
free while those branches exist. And **a consumer needs no migration** -- on update their trunk keeps a
stale reset copy until their next fold, which then removes it, so the release note states that instead.

Two more settled by Dave on August 23, 2026, after the plan was read:

**The `[branch-template]` check is inverted** (`scripts/lint/check-plugin-integrity.ps1:1614-1633`). It
asserted that the trunk file EXISTS and equals the formatter byte-for-byte; it now asserts the file is
ABSENT on the trunk, and present and declaring the branch on a branch.

**`Format-DevelopmentCycleReset` goes.** It is an alias for `Format-DevelopmentCycle -Branch ''`, and after
this change nothing writes a reset state, so the name has no writer left. The CONCEPT does not go with it:
a branch created before this change still carries a trunk-declaring copy, and `Get-BranchFileDeclaredBranch`
must keep recognising one. So the fixtures that need such a document call `Format-DevelopmentCycle -Branch ''`
directly -- the alias is retired, not the state it produced.

## CREATE

- [x] `scripts/release/fold-changelog-entry.ps1`: the `$isBranchFile` arm is gone -- every folded entry's file is deleted, the printed word is `removed`, and the commit records the deletion. The legacy `branch/` step list is deleted beside it rather than rewritten, and the re-read note is no longer printed here (the script writes nothing to re-read).
- [x] `scripts/task/adopt-workflow-folder.ps1`: the document is no longer placed, and the three scaffolded prose sites that described it say so.
- [x] `scripts/lint/check-plugin-integrity.ps1`: `[branch-template]` inverted -- absent is the trunk's normal state, a document naming a branch is work in progress, one naming the trunk (or naming nothing) is an error. The entry-reading sites already tolerated absence.
- [x] `scripts/lib/entry-scaffold-lib.ps1`: `Format-DevelopmentCycleReset` retired with a tombstone in the file's own convention; `Get-BranchFilePaths` and `Resolve-BranchFilePath` carry the new reasoning, and the resolver KEEPS its declared-branch test.
- [x] Mirrored into `plugins/workflows/workflow-davekjohn/scripts/**`; parity confirmed by equal change counts and by the shared-script gate.
- [x] Docs: `CLAUDE.md`, `workflow-davekjohn/README.md`, `workflow-davekjohn/CLAUDE.md`, `workflow-davekjohn/CONTRIBUTING.md`, `DEVELOPMENT-CYCLE-portable.md`, `CONTRIBUTING-portable.md`.
- [x] Swept: five workflow skills, the lenses `05-05` and `05-06`, both `scripts/README.md` files. Two markdown links to the document were turned into plain code -- they would be dead links on the trunk. `INSTALL.md` and lens `05-15` named the file but not its lifetime, so neither needed a change.
- [x] `scripts/lint/check-branch-entry.ps1` and `.github/workflows/branch-entry.yml`: wording corrected. The gate triggers on `pull_request` only, so the trunk case never arises in CI.
- [x] The file was not removed by hand; the fold does it at the merge.

## TEST

- [x] `scripts/tests/fold-changelog.tests.ps1`: asserts the document is GONE, that the run says `Folded and removed` and never says `reset`, and that no re-read note is printed.
- [x] `scripts/tests/check-plugin-integrity-entries.tests.ps1`: 13 asserts over the inverted check -- absent, a branch's work, a trunk leftover, a nameless document, and both directions of the trunk-name seam on a fixture whose trunk is `master`.
- [x] `scripts/tests/adopt-workflow-folder.tests.ps1`: the document is not placed, and the expected-files list no longer names it.
- [x] `scripts/tests/branch-entry-gate.tests.ps1` and `scripts/tests/entry-scaffold.tests.ps1`: fixtures moved onto `Format-DevelopmentCycle -Branch ''`.
- [x] Lint and the full suite green through `open-pr.ps1`.
- [x] One full cycle by hand: `new-branch` on a trunk with no document creates it, and the fold removes it and records `D workflow-davekjohn/development-cycle.md` in the commit. **It proved that by accident, in this repo rather than in the throwaway fixture** -- `$PID` differs between PowerShell processes, so the `Set-Location` into the temp path failed and the rest of the block ran here. Two commits landed on this branch and were undone; the working tree was restored from git and `git reset --soft` cleared the history, with Dave's word for the reset. Recorded because the lesson is about the probe, not the change: a scripted end-to-end must fail closed when its own `cd` fails.

## DEPLOY: `feat/cycle-file-branch-lifetime-v1`

The branch's own document now exists only while a branch is open. `new-branch` creates it, the fold
**removes** it instead of rewriting it to an empty state, and between branches the trunk carries no copy at
all — so `workflow-davekjohn/` holds its three pages and its two directories and nothing else. What the
empty copy was really for, letting a reader see the whole form at once, moves to
`plugins/workflows/workflow-davekjohn/DEVELOPMENT-CYCLE-portable.md`, which reaches a consumer with every
plugin update rather than being scaffolded once and frozen.

Three things follow. `adopt-workflow-folder` places one file fewer, so a consumer is no longer handed a
document their own first fold deletes. `Format-DevelopmentCycleReset` is retired — an alias with no writer
left — while the state it produced is still recognised, because a branch cut before today is carrying one.
And `check-plugin-integrity`'s `[branch-template]` check is inverted: it held the trunk copy to the
formatter byte-for-byte, and now asserts that no document declaring the trunk survives a fold anywhere in
the tree, which also catches the leftover a consumer updating from an older plugin has until their next
fold clears it.

`Resolve-BranchFilePath` deliberately keeps its declared-branch test rather than reverting to the plain
existence test that is now available again. Every branch cut before this change is carrying the trunk's old
empty copy beside its real work, here and in every consumer, and existence alone would hand each of them
the empty document. That simplification is available on the day those branches are gone, and not before.

**Score:** 3

### What makes this deploy extra special

A consumer's fold changes behaviour without them choosing it, and their trunk loses a file that has been
there since they adopted the folder. Nothing breaks and no migration is needed — the stale empty copy their
last fold wrote is removed by their next one — but the folder they read to learn the convention looks
different the first time they open it after the update, which is worth knowing before it surprises them.

**Score:** 3

### Pull Request
<!-- the PR title on the first line -- no feat:/fix:/docs: prefix, open-pr puts the branch type in front.
     link to the PR in github when branch is merged to main and the date this happened-->

The development cycle exists only while a branch is open
