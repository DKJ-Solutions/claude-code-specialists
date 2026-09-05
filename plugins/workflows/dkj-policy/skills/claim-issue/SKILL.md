---
name: claim-issue
description: >-
  Claim a GitHub issue on the tracker before any work on it begins -- assign it to the account THIS
  checkout commits as, and refuse when the issue is closed, missing, or already somebody else's. Use
  it the moment an issue number is named as the work -- "fix issue 1234", "pick up #87", "take this
  one", in whatever language the request arrives -- and again when resuming one, BEFORE reading the
  code or opening a branch. It writes one assignee and nothing else -- no branch, no commit, no
  comment -- so it is the step that runs first, not a replacement for new-branch.
---

# claim-issue -- the claim rule, performed

The rule has been written down for as long as this workflow has existed:
[`CONTRIBUTING-portable.md`](../../CONTRIBUTING-portable.md) states it
("**Claim an issue before working it**, and read the claim as well as write it"), and Chris's persona
body states it with the command -- `gh issue edit <n> --add-assignee @me`. **Both leave it to a
session to remember, to type, and to read the result of.** This skill is that step, so that
*"fix issue 1234"* cannot begin before the tracker says who is on it.

**Why the tracker and not a branch.** It is the only thing two sessions share. The same owner may be
running a second machine and a colleague may be working the same board; neither session sees the
other's branch or intent, so an unassigned issue is indistinguishable from an untouched one -- which
is how the same work gets built twice and discovered at the merge.

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/claim-issue.ps1" 1234
```

**In the source repo, run its own copy instead -- `scripts/task/claim-issue.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own,
so for them the line above is the correct one.

The script:

1. Resolves **which account** this checkout claims under -- see the next section. It never sends
   `@me`.
2. Reads the issue (`gh issue view --json number,title,state,url,assignees`).
3. **Judges it** -- five verdicts, three of them refusals (below).
4. Writes the assignee, then **reads the claim back** and fails if it did not land.

## Two parameters

- **`-Issue <n>`** (positional, required) -- the issue. A bare number (`1234`), a hash-prefixed one
  (`#1234`), or the issue's own URL: all three are what a person has in their hand at that moment,
  and requiring one spelling would only teach the caller to strip characters the script strips
  itself.
- **`-DryRun`** -- read and judge, write nothing. Prints the verdict it would act on, so you can see
  **who holds an issue without taking it**.

## Which account -- and why never `@me`

`@me` resolves through the GitHub API, so it binds to whatever `gh` is authenticated as. The branch a
second session correlates the claim **with** carries the *git* identity. A machine can hold both --
a personal login on the tracker, a work account on the commits -- and then `@me` claims under one
name while every commit lands under the other. Nothing errors, no gate fails, and the claim answers
the wrong question.

Measured, September 3, 2026
([#1315](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1315)): `gh` authenticated as
`DaveKJohn` on a checkout committing as `davekokbwj`, so claiming #1314 with the documented idiom put
the wrong account on it and it had to be corrected by hand.

So this script reads **both** and claims **by name**, which is exactly what
`check-git-identity.ps1`'s own report already instructs on such a checkout. On a split identity it
says so before it writes, and picks the **git** name -- the tracker is made to agree with the
commits, because the commits are the half nothing can rewrite afterwards. A `git config user.name`
holding a display name ("Ada Lovelace") is not an account at all and is no evidence of a split, so a
normal repo never sees this.

## The five verdicts

| Verdict | What happens |
|---|---|
| **open, unassigned** | Claimed, read back, and the work may start. |
| **already yours** | Nothing to write -- this is a resume. Read the branch and its document before carrying the work. |
| **closed** | **Refused.** |
| **held by somebody else** | **Refused.** |
| **no account** | **Refused** -- `gh` is absent or logged out, so there is nobody to claim as. A step whose whole job is to say who is working cannot proceed anonymously. |

**The closed refusal is the one this step was built for.** `gh issue edit <n> --add-assignee`
**succeeds silently on a closed issue**, so the documented one-liner gives a session every signal of
having taken ownership of work that is already done. That is the case recorded in `new-branch.ps1`'s
stale-base block: a branch cut, committed, pushed and PR'd against an issue another session had
closed by a merged PR **four minutes earlier**, found only when the PR sat without a check suite.
Nothing downstream catches it, because every gate reads the branch and the branch is fine.

If a closed issue is still broken, **reopen it first**. The reopening is the record that the earlier
repair did not hold, and this step is not the place to make that record silently.

**There is deliberately no flag past that fourth verdict.** An assignee that is not this checkout's own
account stops the work; the way through is asking whoever holds it, and a switch cannot have a
conversation. A **co-assignment stops it too**, including one this account is part of: two people on
one issue is the duplicate-work hazard itself, and being one of the two is no evidence about what the
other is building.

## The claim is read back, because the write is not the proof

`--add-assignee` reports success for a login GitHub silently drops -- most often an account with no
write access to the repo. An unverified claim is worse than none: the session believes the tracker
says something it does not. So the script re-reads the assignees and **fails** when its own account
is not among them, telling you to treat the issue as unclaimed.

## What this skill is NOT

- **Not a branch.** It writes one assignee and nothing else. Opening the branch is
  [`new-branch`](../new-branch/SKILL.md), and it stays a separate decision because the branch name is
  a judgement about the work -- which this step has not read yet.
- **Not a filing step.** It claims an issue that exists; it does not create one.
- **Not a substitute for reading the issue.** A claim says who is working, not what the work is.

## Requirements in the consumer

`gh`, authenticated (`gh auth status`) with write access to the repo. `scripts/repo-config.ps1` is
read **defensively**: `Get-RepoName` pins the tracker explicitly, which matters in a worktree or when
the run starts outside the checkout, and without it `gh`'s own resolution stands and is said out
loud. The repo root resolves dual-context via `${CLAUDE_PROJECT_DIR}` like every other shared script.

## Important

- This script is maintained in the source repo; do not modify it locally in the consumer. A change
  lands first in the source (`scripts/task/claim-issue.ps1`) and then travels via a release to the
  plugin mirror -- guarded by the shared-scripts drift lint.
- **It is deliberately model-invocable**, unlike `start-task` and `sync-roster`. The pain it removes
  is that a session hears *"fix issue 1234"* and starts fixing; a skill nobody may invoke until it is
  typed leaves exactly that path open.
