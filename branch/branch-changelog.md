## `feat/the-fold-commit-says-fold` changelog

### Branch title

The fold commit says fold, not chore

### Branch ID

20260810-130047

### Branch type

feat

### What does the change on this branch bring to main?

The commit that folds a branch's entry into `CHANGELOG.md` is typed **`fold:`**:

```text
fold: feat/the-fold-commit-says-fold changelog (#NN)     one entry
fold: 3 changelogs: a (#1), b (#2), c (#3)               a fold-all run
```

It read `chore: fold changelog entry <branch> (#NN)` until now. **`chore` said only "housekeeping"** and
left the reader to parse the rest of the line to find out which housekeeping — while folding is a named
act with its own script, its own step in the cycle, and its own exception to "never commit directly on
`main`". The type now says that.

**It is the second half of a shape this repo already chose.** `merge: <branch> (#NN)` was invented on
August 7, 2026 for exactly this reason: a commit that belongs to no branch still deserves a type. A merge
and its fold are one movement written as two commits — measured on August 10, 2026 at 394 of 410 folds
sitting directly on their merge — so they now read as a pair rather than as a typed commit followed by a
generic one. It also removes the last thing in the repo producing a `chore:` subject: `chore/` has been
refused as a branch prefix since August 7.

**The PR number stays**, chosen over the shorter form that dropped it. It is the only link from the fold
commit back to the PR it folded, and it is what makes the subject line up field for field with the
`merge:` commit below it.

**Nothing is left to recognise on the way out, and that was checked rather than assumed.** No script,
gate or hook parses this subject — only `fold-changelog-entry.ps1` writes it and one assert in
`fold-changelog.tests.ps1` reads it back. (`^chore(/|$)` in `branch-info.ps1` matches a *branch name* and
is untouched; `workflow-default`'s discovery script keys on the shape `^[a-z]+:` rather than on a list of
types, so `fold:` still reads as conventional there.) So the standing "recognise both, write one" rule
has nothing to attach to here: every `chore: fold ...` already in this repo's history and in every
consumer's log stays exactly as valid as it was, because nobody was reading it. **There is nothing to
migrate**, and the skill page says so, since the first thing a consumer will wonder on seeing the new
type is whether their old commits still count.

**The plural form is now tested, and the reason is a measurement.** Of the **410** fold commits in this
repo's history exactly **one** folded more than one entry (`976e8f4`, July 2026), and it did so under
wording that has been replaced twice since — so the plural subject the script writes has never been
produced by a real run. "We only ever merge one PR at a time" is true and does not close it: two entries
reach one fold in two ways that have nothing to do with merging twice — a **fold-all** run (no `-Branch`)
picks up every legacy root entry, which is the normal state of a consumer that has not migrated to
`branch/`, and even `-Branch` mode folds `branch/branch-changelog.md` *and* a legacy `<branch>.md`
together when both exist. A code path that writes directly to `main` under a named exception and that no
reviewer has ever seen the output of is the one that most needs an assert, not the least.

The test that guards it now asserts the **type** separately from the branch name: that fixture has no PR
to look up, so a branch-name match alone would still pass against a subject typed anything at all — which
is precisely the half a rename takes away silently.

Plugins: workflow-davekjohn

### Significance

#### Tier 0

Every fold commit made here from now on says what it is. The `git log` of this repo is read often enough
— by the discovery script, and by whoever is reconstructing what happened on a given day — for that line
to be worth reading rather than parsing.

**Score:** 2

#### Tier 1

Names the rule behind both halves for anyone working on the shared scripts: a commit that belongs to no
branch still deserves a type, and the fold and the merge are one movement. That is what `merge:` decided
three days ago; this applies the same answer to the only other commit in the cycle that had escaped it.

**Score:** 2

#### Tier 2

A consumer's own fold commits change shape on the next plugin update, unasked — so the change is visible
in their log whether or not they went looking for it. Nothing breaks and nothing needs migrating, which
is exactly why the skill page now states that outright instead of leaving them to work it out.

**Score:** 2

### Pull Request
