---
name: continue
description: >-
  Resume work after clearing the context: read the topic that /lock recorded, re-verify it against what
  the repo actually says now via the shared session-status script, report any disagreement between the
  two, and then start. Use this as the LAST of three steps -- /lock, then /clear, then /continue. The
  repo is the authority, not the lock: if the locked subject was already done or overtaken, say so
  instead of building it. Reads only; it opens no branch and commits nothing by itself.
disable-model-invocation: true
---

# continue -- resume the locked topic, with the repo as the authority

The second half of `/lock`. That command recorded a **decision**; this one supplies the **facts** and
checks the two still agree.

```text
/lock       name the next subject and write it down
/clear      Claude Code's own built-in command
/continue   read the lock, re-verify against the repo, resume   <- this page
```

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

**3. Say the disagreement out loud.** Where the lock and the repo differ, the **repo wins** -- and the
difference is itself worth reporting, not quietly worked around. Naming it is how the requester learns
their lock was stale; silently doing something else is how they stop trusting the command.

**4. Then start.** Read the route the lock named, announce which specialist is acting, and begin.

**5. If nothing is locked**, the script says so. Read the blocks it printed, propose the highest-priority
subject from what is actually there, and offer to `/lock` it.

## What this command deliberately does not do

- **It does not enforce the lock.** Nothing refuses to deviate, and nothing should: the lock is recorded
  intent. A version that followed it without re-reading the repo would reintroduce the failure this
  family has measured -- a start briefing arriving three times identically truncated, breaking off
  mid-word, with nothing in the visible list announcing what was missing. A handover is a pointer; the
  repo is the inventory.
- **It does not delete the lock after reading it.** Re-running is free, a cleared context may need the
  subject twice, and `/lock` overwrites. A command that consumed its own input would leave a second
  `/continue` with nothing.
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
