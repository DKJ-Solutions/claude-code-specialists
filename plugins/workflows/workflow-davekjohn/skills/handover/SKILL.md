---
name: handover
description: >-
  Resume work after clearing the context: read the topic that /lock recorded in .claude/handover.md,
  re-verify it against what the repo actually says now via the shared session-status script, report any
  disagreement between the two, and then start. Use this as the LAST of three steps -- /lock, then
  /clear, then /handover. The repo is the authority, not the lock: if the locked subject was already
  done or overtaken, say so instead of building it. Reads only; it opens no branch and commits nothing
  by itself.
disable-model-invocation: true
---

# handover -- resume the locked topic, with the repo as the authority

The second half of `/lock`. That command recorded a **decision** and wrote it to `.claude/handover.md`;
this one supplies the **facts** and checks the two still agree.

```text
/lock       name the next subject and write it down
/clear      Claude Code's own built-in command
/handover   read the lock, re-verify against the repo, resume   <- this page
```

**This command is called `/handover` because `/continue` is taken.** Claude Code ships its own
`/continue`, so a skill by that name collides with a built-in and the requester cannot reliably reach
the one they meant. `handover` is also the name of the file this command reads, which is the second
reason to prefer it: the command and its input now say the same word. **Do not "restore" the old name**
— the collision is the whole reason it changed (Dave, August 16, 2026).

## What to do

**1. Read both halves in one command.** Run the shared script from the root of the consuming repo:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/session-status.ps1"
```

**In the source repo, run its own copy instead -- `scripts/task/session-status.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own, so
for them the line above is the correct one.

It prints the locked topic first -- verbatim, with how long ago it was set -- and then the repo's own
answer: branch and tree, recent commits, parked branches on `origin`, open issues, pending changelog
entries with their tiers, the last tag, and what the last release note recorded as still open.

**2. Verify the lock against those blocks before acting on it.** This is the step, not a formality. Ask
of the locked subject:

- **Has it already been done?** Check the recent commits and the pending entries. Filing and repairing
  can cross inside one morning, and starting a second repair on a defect nobody has is worse than
  wasted effort.
- **Has it been overtaken?** Work merged since can change what the right fix is, or remove the thing the
  lock proposed changing.
- **Do its load-bearing facts still hold?** A lock's *reasoning* expires independently of its subject:
  the ask can still be open while the argument for it has gone. Where that happens, say the argument
  needs re-establishing rather than inheriting it.
- **Does anything it names still exist?** A lock written from the outside can name a function, flag or
  file that was inferred rather than read. Grep each one before building on it.
- **Is the cause it states actually the cause?** A lock is a *summary*, and where it summarises a filed
  report the report is the source. Open the code the lock points at and read the mechanism before editing
  it -- and treat a lock's own claim to have checked already (*"confirmed at the code level"*,
  *"verified, not taken from the report"*) as a claim to test rather than a step it has done for you.

  **Measured, August 19, 2026.** A lock written six minutes earlier named its subject correctly -- an open,
  still-standing inbound issue -- and stated the cause as a parameter filtering entries out. That parameter
  only **sorts**; it drops nothing, and the real hardcode sat in a different file from the one the lock
  routed to. **The report it summarised had named the right line.** So the lock passed all four checks
  above and was still wrong about the one thing that decides where the fix goes.

  This mode is the hardest of the five to catch, for two reasons worth stating: the lock was **fresh**, so
  every staleness instinct said to trust it, and its self-certification was the exact sentence that would
  otherwise have prompted a re-read. Had the pickup not opened the function first, the repair would have
  landed in the wrong file, left the defect standing, and shipped a code comment citing a mechanism that
  does not exist -- a defect that reads as authoritative.

**3. Say the disagreement out loud.** Where the lock and the repo differ, the **repo wins** -- and the
difference is itself worth reporting, not quietly worked around. Naming it is how the requester learns
their lock was stale; silently doing something else is how they stop trusting the command.

**And naming it is the whole of it.** A lock that has outlived its session is **spent, not broken** --
a `/lock` is written once, read once, and then waits to be overwritten by the next one, so being out of
date is its resting state rather than a defect in it. Report what has changed and carry on; do not
offer to clear it, do not propose re-locking it, and above all do not carry it into a list of what is
still open. Measured on this repo, August 20, 2026: a session asked whether anything important was
still outstanding, swept the tree correctly, and then put "the lock is stale, three of its items are
done" at the **top** of the answer as the item that most needed action -- inventing work out of the
mechanism working exactly as designed. The requester's correction is the sentence to keep: *you use it
once and wait for the next lock.*

**4. Then start.** Read the route the lock named, announce which specialist is acting, and begin.

**5. If nothing is locked**, the script says so. Read the blocks it printed, propose the highest-priority
subject from what is actually there, and offer to `/lock` it.

## What this command deliberately does not do

- **It does not enforce the lock.** Nothing refuses to deviate, and nothing should: the lock is recorded
  intent. A version that followed it without re-reading the repo would reintroduce the failure this
  family has measured -- a start briefing arriving three times identically truncated, breaking off
  mid-word, with nothing in the visible list announcing what was missing. A handover is a pointer; the
  repo is the inventory.
- **It does not delete the lock after reading it, and it does not ask anyone else to.** Re-running is
  free, a cleared context may need the subject twice, and `/lock` overwrites. A command that consumed
  its own input would leave a second `/handover` with nothing -- which is also why a leftover lock is
  never a chore to hand back to the requester. Overwriting it is `/lock`'s job, on the day there is a
  next subject.
- **It does not run the gates.** They cost minutes each, and a resume command that costs minutes gets
  avoided -- at which point it reports nothing at all. It prints the commands so the reader runs
  whichever the work in front of them needs.
- **It does not clear anything.** `/clear` is a built-in CLI command and stays yours; this command
  assumes it has already happened but is equally correct without it.

## Requirements in the consumer

Identical to `/lock` -- `git` and a repo root, nothing else. The script needs no library and no seam
function to produce its answer, so a repo that has adopted none of this workflow still gets a useful one;
every optional source (`gh`, tags, `CHANGELOG.md`, the release-note tree `Get-ReleaseNoteRoot` names)
degrades to a stated line rather
than an error.

`.claude/handover.md` should be gitignored -- see the `lock` page for why.

## Related

- **`/lock`** -- writes the topic this command reads, and carries the file's suggested shape.
- **`park`** -- sets a **branch** aside on the remote for another device. Different question: parking
  moves code, locking records which subject is next. Neither implies the other.
