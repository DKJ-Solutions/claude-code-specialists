# `branch/` — the two files a branch works in

Everything a branch needs to carry lives here, split into two files with one job each:

| file | subject | who reads it | lifetime |
|---|---|---|---|
| [`branch-changelog.md`](branch-changelog.md) | what the change **does** | whoever reads `CHANGELOG.md` later | folded at the merge, then reset |
| [`branch-progress.md`](branch-progress.md) | what still **must happen** | whoever is working on the branch | reset at the merge; never folded |

Both are written by [`scripts/task/new-branch.ps1`](../scripts/task/new-branch.ps1) at the moment the
branch is created. You do not create them by hand, and you do not delete them.

## Why two files and not one

One file used to do both jobs. It was scaffolded with a bold *to do / where I left off* heading **and**
folded verbatim into `CHANGELOG.md`, which meant "replace this whole block before the PR" had to be a
written instruction rather than something the format made obvious. It did not always happen: three of
v3.2.0's twenty-one entries shipped with that heading and a status appended behind it, into the release
notes *and* into the per-plugin `CHANGELOG.md` files that travel to consumers.

Two files make it obvious. The entry asks what the change does. The step list asks what is left.

## Why the names are fixed

`branch-changelog.md` and `branch-progress.md` are the same on every branch, which looks like it should
collide the moment two branches exist. It cannot: **git already tracks these files per branch**, so each
branch carries its own version of the same path and a checkout swaps them. The per-branch filename this
replaced was solving a problem version control had already solved, and it cost a repo root that filled
up with other people's in-flight work.

## The reset state, and the warning on the trunk

On `main` both files sit in an empty **reset state** — a short explanation, and a warning under the
branch line saying not to write here until a branch exists. That is what you are looking at if you open
them on the trunk: the empty state, not a lost entry.

The reset state opens with an `#` (an H1), and that is load-bearing rather than cosmetic. The fold
recognises an entry by its heading level, and an entry heading is an `##`. So the trunk's own empty file
can never be folded as if it were a change, and folding twice is impossible rather than merely unlikely.

## Rules

1. **The entry holds the entry block and nothing around it** — no title, no branch line, no preamble.
   That is what makes it pasteable into `CHANGELOG.md` in one go, which is its whole reason for
   existing. The branch name lives in `branch-progress.md`, which has room for it.
2. **Links in the entry are written root-relative**, as if the file were already in the repo root —
   because after the fold it is. The lint gate checks them from there. Links in `branch-progress.md`
   follow the ordinary nested convention (`../scripts/...`): that file never travels.
3. **Every step is resolved before the PR.** `open-pr.ps1` and `ship-pr.ps1` both refuse while anything
   is unresolved. Three marks:

   ```text
   - [ ] not done yet          -> blocks the PR and the merge
   - [x] done
   - [~] dropped -- <why it turned out not to be needed>
   ```

   `- [~]` exists because a plan legitimately grows items that stop making sense. Without it a gate
   teaches people to tick boxes for work they did not do, and then reports success — worse than no gate.
   A dropped step keeps its line and its reason, which is the half worth reading later. **There is no
   `-Force` for this gate**; the dropped mark already is the way past a step that should not be done.
4. **A step still carrying the scaffold's own placeholder is refused, ticked or not.** Ticking the
   scaffolded first step without replacing it reports a plan as finished that was never written.
5. **Fill in the entry's impact table before the PR.** How far the change reaches and what it weighs
   there decides which release documents it appears in and where in them it sits — see
   [`CONTRIBUTING.md`](../CONTRIBUTING.md).
6. **Never edit `CHANGELOG.md` from a branch.** Every branch would be editing the same region of the
   same file; that is the merge conflict this directory exists to avoid.

## What happens at the merge

[`scripts/release/fold-changelog-entry.ps1`](../scripts/release/fold-changelog-entry.ps1), run on `main`
right after the merge:

1. inserts the entry into `CHANGELOG.md` at its ranked position (furthest reach first, highest
   significance first within a tier), with the PR link and merge date appended as its closing line;
2. **resets both files** to the empty state you see on the trunk;
3. commits exactly those three paths.

The branch name it needs for the PR lookup comes from `branch-progress.md`'s own branch line — the file
name no longer carries it, which is why that line is in the document rather than only in the
scaffolder's head.

## Working from more than one machine

Park a branch with [`scripts/task/park-branch.ps1`](../scripts/task/park-branch.ps1), or create it with
`new-branch.ps1 -Park`: both commit **both** files and push, with no PR. The step list is the half that
says what was still in flight, so parking the entry without it defeats the point.

Before picking a parked branch back up, measure its plan against `main`. A plan that reads as current is
not evidence that it is — see the `park` skill for what to check and why.
