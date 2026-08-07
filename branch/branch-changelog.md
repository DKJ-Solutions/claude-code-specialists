## `feat/one-script-per-concept` changelog

### Branch description

new-branch is one script instead of two

### Branch ID

20260807-140842

### Branch type

feat

### What does the change on this branch bring to main?

`new-changelog-entry.ps1` is gone; `new-branch.ps1` does the whole job. Creating a branch and writing the
files it works in were one concept split across two scripts, and the second one's name had stopped being
true twice over: the `branch/` split gave it a step list to write, and the templates repair gave it two
more files. It described **one of four outputs**, and no document told anyone to run it -- it had no skill
of its own and nothing but `new-branch` ever called it.

**What the split was actually buying, since it was not nothing.** The inner script used `exit` as control
flow, and running it as a child process is what kept those exits from killing the caller. Each was answered
rather than deleted:

- the missing-`branch-info.ps1` pre-flight was **already** in the outer script -- a duplicate, now gone;
- the trunk refusal **moved up, in front of the checkout**, so it refuses before touching `HEAD` instead of
  after. It looks like dead code (`Test-BranchName` rejects `main`) and is not: that check only knows the
  literal `main` while the trunk is configurable, so a consumer whose trunk is `master` still reaches it.
  Deleting it as unreachable would have broken exactly that consumer;
- *"the files already exist"* was an `exit 0` the caller read as success and carried on from. It is a
  **skip** now, which is what it always meant -- as an inline `exit` it would have ended the run and a
  `-Park` would silently not have happened.

The injection-safe environment-variable handoff went with the process boundary: `-Title` and `-Intent` are
ordinary parameters again, because there is no argv to requote across. The test that guarded that handoff's
precedence went with it, and the half of it worth keeping was already asserted elsewhere on a nastier
payload.

**The 93-assert `new-branch` suite is what made this safe**, and it is why the merge was worth attempting
at all: it runs the real script end to end, so a behaviour that survived the splice is one those asserts
saw.

**Two more things the branch workflow says out loud now, both about the same thing: making every line of
the history state its own type.**

**`chore/` is refused as a branch prefix.** There are three -- `feat`, `fix`, `docs` -- because chore is
the name for work that lands *directly on the trunk* under one of the named exceptions, so a chore branch
is a contradiction. The commit log agrees emphatically: 15 of the last 30 first-parent commits are
`chore:` and every one is a direct commit. **The rule always held and was never enforced**: measured on
the day it was written down, `chore/` had been used 12 times, and Dave's answer on seeing that count was
that all twelve were wrong at the time too. `Chore` stays a recognised changelog **type** -- entries
already carry it, and it is still the fallback for an unknown prefix. Refused in `Test-BranchName` rather
than merely dropped from the table: that file is repo-owned and does not travel, so this states our rule
without touching a consumer who runs chore/ branches of their own.

**The merge commit is named `merge: PR #NN <branch>`.** GitHub's default,
`Merge pull request #NN from Owner/branch`, was the one line in the graph with no type in front of it
while everything around it had one -- so scanning the history meant reading two shapes. It now pairs with
the fold commit that follows it. Checked before changing: nothing parses that subject.

### Significance

#### Tier 0

One script fewer to keep in step, one name that no longer lies, and a duplicated pre-flight removed. The
trunk refusal also got strictly better -- it now fires before `HEAD` moves.

**Score:** 3

#### Tier 1

Every line in the git graph now starts with its type -- `feat:`, `fix:`, `docs:`, `chore:`, `merge:`,
`release:` -- so the history reads as one shape instead of two. That is what a colleague scanning back
through a week of work actually uses. It also closes a rule that had been silently unenforced twelve
times, and records why the release stays off a PR, in Dave's own words.

**Score:** 3

#### Tier 2

A shared script disappears from the plugin. Nothing documented ever told a consumer to call
`new-changelog-entry.ps1` -- it had no skill page, and `new-branch` is what every document names -- so
following the documented path is unaffected. Anyone who wired their own tooling to it directly must point
that at `new-branch.ps1`.

**Score:** 2

### Pull Request
