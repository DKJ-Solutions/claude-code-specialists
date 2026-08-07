## `docs/ship-pr-is-the-whole-chain` changelog

### Branch description

ship-pr is the whole chain, and the merge subject has one format

### Branch ID

20260807-163845

### Branch type

docs

### What does the change on this branch bring to main?

Two repairs, both of defects introduced or exposed on August 7, 2026, and both found because Dave asked a
plain question: *is thirteen minutes normal for opening a PR?*

**`ship-pr` is the whole chain, and the lens no longer points away from it.** Its step 1 *is* `open-pr` --
gate, push, open -- after which it waits for CI, merges and folds. One command, one gate run. Running
`open-pr` first and then `ship-pr` therefore puts the lint and all 26 suites through **twice**, about 13
minutes each, on top of the ~11 CI spends on the same commit. Measured: seven PRs that day, roughly **91
minutes** spent on a check that had already passed.

That was a way of working rather than a design flaw -- but the documentation led into it. Derek's
"Merging to main" showed a bare `gh pr merge` and never named `ship-pr` at all. It now names it first, and
demotes the by-hand sequence to the fallback it always was. The `open-pr` step says when to reach for it
alone: when you are deliberately stopping at the PR.

**And the merge subject has one format again.** `ship-pr` began writing `merge: PR #NN <branch>` that
afternoon while Derek's lens had prescribed `merge: <branch> (#NN)` since `ba7081e` -- because the lens was
not read before the shape was chosen. Two formats for one line is precisely the defect the same day's work
removed in five other places, reintroduced by the change that removed it. The older one wins: it matches
the fold commit beside it field for field.

```text
merge: feat/x (#504)
chore: fold changelog entry feat/x (#504)
```

Both are now written down beside each other, in the script and in the lens, with the note that this was
invented twice -- so the next person choosing a shape reads that before choosing.

### Significance

#### Tier 0

Roughly 13 minutes back on every PR that goes all the way through, and the graph keeps one shape for its
merge lines instead of two.

**Score:** 4

#### Tier 1

The documentation pointed at the expensive route, which is why the expensive route was taken seven times
in a day. That is worth more than the minutes: a lens that describes a slower path than the one the
scripts implement will be followed.

**Score:** 3

#### Tier 2

`ship-pr` and its skill page are plugin-carried, so a consumer's merge commits change shape once -- and
the same two-step trap is documented away for them too.

**Score:** 2

### Pull Request
