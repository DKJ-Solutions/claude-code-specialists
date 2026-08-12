---
name: lock
description: >-
  Fix the next topic before clearing the context: read where the repo actually stands via the shared
  session-status script, name the single highest-priority next subject, and write it to
  .claude/handover.md so the next session picks up that subject instead of re-deriving one. Use this
  as the FIRST of three steps -- /lock, then /clear, then /continue. The lock is recorded intent, not
  a refusal: /continue re-reads the repo and may report the locked topic was already done or
  overtaken. Writes one gitignored file; it opens no branch, commits nothing and pushes nothing.
disable-model-invocation: true
---

# lock -- fix the next topic across a context clear

Clearing the context throws away exactly one thing the repo cannot reconstruct: **which subject was
agreed as next.** Everything else -- the tree, the branch, parked work, open issues, pending entries,
the last release's open items -- is still a fact the repo holds, and reading it beats reading a summary
of it.

So this is the half that records a **decision**. `/continue` supplies the other half by re-reading the
repo.

## The three steps

```text
/lock       name the next subject and write it down   <- this page
/clear      Claude Code's own built-in command
/continue   read the lock, re-verify against the repo, resume
```

**A skill cannot run `/clear`** -- that is a built-in CLI command, so the clear stays yours. That is
also why this is `/lock` and not one combined command.

## What to do

**1. Read where the repo actually stands.** Run the shared script from the root of the consuming repo:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/session-status.ps1"
```

**In the source repo, run its own copy instead -- `scripts/task/session-status.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own, so
for them the line above is the correct one.

It prints, in this order: any topic already locked, the branch and tree, the recent commits, parked
branches on `origin`, the open issues, the pending changelog entries with their tiers, the last tag,
what the last release note recorded as still open, and the gate commands. It **reads only** -- nothing
is written, committed or pushed, so it is safe on a dirty tree mid-branch.

Every optional source degrades to a stated line rather than an error: no `gh`, no tags, no
`CHANGELOG.md`, no release-note tree at the root `Get-ReleaseNoteRoot` names each print what could not be
read. A repo that has adopted none of this workflow still gets a useful answer.

**2. Name ONE subject.** Not a backlog -- the single thing that should happen next, with the reason it
outranks the others. If two things genuinely tie, say so and pick one; a lock naming three subjects is
a list, and a list is what the next session will have to re-prioritise, which is the work this command
exists to avoid.

**3. Write it to the path the script printed** (`.claude/handover.md` at the repo root). The script
owns that path and prints it, so this page and `/continue` cannot drift apart on where the file lives.

**4. Show the requester what you wrote, before they clear.** The point of a separate command is that
the decision is visible and correctable while they are still in the conversation that produced it.

## What goes in the file

A heading, a stamp, and then the subject with its reasoning. The shape below is a suggestion, not a
parsed format -- nothing reads this file mechanically, and that is deliberate: a machine-read handover
would need a schema, a validator and a migration the first time it changed.

```markdown
# Locked topic
**Stamped:** 2026-08-11 · **Repo at:** <short sha> · **Last release:** vX.Y.Z

## The subject
<one sentence: what happens next>

## Why this one
<why it outranks what else is pending -- the half that cannot be re-derived>

## Route
<which specialist(s), in order, and the branch prefix>

## Watch for
<the trap somebody would walk into: a decision already recorded, a function that does the
 opposite of what its name suggests, a test that asserts the wrong layer>

## Waiting on the requester -- do NOT build
<anything that needs their word first, and what you would advise>
```

**Include what the repo cannot tell the next session**: the reasoning behind the ranking, decisions the
requester already made (including "we decided NOT to build this"), and traps you only found by reading
the code. Leave out what the repo states better itself -- the script re-reads the tree, the issues and
the pending entries every time, so restating them here only creates something that can go stale.

## The lock is recorded intent, not a refusal

Nothing enforces it. `/continue` re-reads the repo on every run and **must** be able to report that the
locked subject was already done, or overtaken by work merged since -- filing and repairing can cross
inside one morning.

**Do not "improve" this by making `/continue` obey the lock without re-reading.** That is the failure
this family has already measured from the other direction: a self-verifying start prompt arrived three
times identically truncated, breaking off mid-word, and nothing in the visible list announced what was
missing. A handover is a pointer; the repo is the inventory.

## Requirements in the consumer

- `git`, and a repo root -- resolved dual-context (`CLAUDE_PROJECT_DIR` where the mirror runs,
  otherwise the git root).
- **Nothing else.** The script needs no library and no seam function to produce its answer.
  `scripts/repo-config.ps1` is read only if it happens to define `Get-ReleaseNoteWording`, to learn what
  that repo calls its "still open" section; absent, any heading saying *still open* is matched. It also
  loads `source-repo-guard-lib.ps1` if the payload carries it, which either stops the run outright (you
  are in the repo that maintains this script, and ran a released copy of it) or contributes nothing.
- `.claude/handover.md` should be **gitignored**. It is one developer's working intent, it goes stale
  within hours, and all three steps run on one machine within minutes -- committing it would mean a
  pull request per session close.

## Related

- **`/continue`** -- the other half: reads this lock and re-verifies it.
- **`park`** -- adjacent but different, and worth keeping apart. Parking sets a **branch** aside on the
  remote so it is continuable on another device; locking records **which subject** to pick up next. A
  branch can be parked with no lock set, and a lock can name work no branch exists for yet.
