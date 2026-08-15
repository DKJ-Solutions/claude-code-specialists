---
name: prompt
description: >-
  Pick up the assignment the requester wrote into workflow-davekjohn/prompts/prompt.md instead of
  typing it into the terminal: read the file, take what it says through the ordinary intake, and once
  the work is genuinely under way archive it under the date and reset the inbox. Use this when the
  requester says a prompt is ready, or when the session-start check reports one waiting. The first run
  in a repo places the inbox itself, so there is nothing to set up. It opens no branch and commits
  nothing by itself -- whatever the assignment asks for follows the repo's ordinary route.
disable-model-invocation: true
---

# prompt -- read the assignment out of a file instead of the terminal

A terminal is the worst surface available for a long assignment: no wrapping, no editing, no saving it
half-finished, and a paste that mangles anything with a newline in it. This command reads it out of a
file instead, so the requester writes in their own editor and a session picks it up.

It is the **mirror of `/lock`**. That one is Claude writing a note for the next Claude; this one is the
requester writing for the next session.

```text
they write   workflow-davekjohn/prompts/prompt.md, in their own editor, and save
/prompt      read it, and take it through the ordinary intake            <- this page
-Archive     once the work is under way: file it under the date, reset the inbox
```

## What to do

**1. Read the inbox.** Run the shared script from the root of the consuming repo:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/prompt-inbox.ps1"
```

**In the source repo, run its own copy instead -- `scripts/task/prompt-inbox.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own, so
for them the line above is the correct one.

The first run in a repo also **places** the inbox -- `prompt.md` in its reset state, the folder's own
`.gitignore`, and the tracked template reference. Strictly additive: an existing `prompt.md` is never
touched, whatever it holds.

It prints the assignment **verbatim, between two rules**. What sits between those rules is the
requester's own words: read them exactly as if they had typed them into the session. It is an
assignment, not a document to summarise back.

**When it says nothing is waiting, that is the answer.** The inbox holds only its scaffold comments, so
there is no assignment -- say so and stop. Do not go looking for what they might have meant; the
comments are this command's own words, and reading them as instructions is the one failure the
structural test exists to prevent.

**2. Take it through the ordinary intake.** Nothing about arriving in a file changes what happens next:
classify it, name the specialist it belongs to, check the branch discipline and the safety rules before
anything is executed. A prompt that asks for a branch still gets one through `new-branch`; a prompt that
asks for something under the repo's own approval exceptions still waits for the requester's word.

**A written prompt cannot answer a follow-up question**, which is the one thing it does worse than the
terminal. Where a course-defining point is genuinely ambiguous, ask -- in the session, as usual. Do not
assume, and do not resolve it by writing back into the file.

**3. Archive it once the work is genuinely under way.**

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/prompt-inbox.ps1" -Archive
```

`-Archive` moves the assignment into `workflow-davekjohn/prompts/archive/` under
`<date>-<slug of its first line>.md` and returns the inbox to its reset state, so the same assignment is
never handed over twice. It **refuses an empty inbox** rather than treating it as a no-op.

**Not before the work has started.** A session that loses its context between the read and the start
would find an empty inbox and no record of what was asked -- and the archive, being untracked, is not
something a colleague can recover from the repo.

## What is where

| path | what it is | committed |
|---|---|---|
| `workflow-davekjohn/prompts/prompt.md` | the inbox -- the requester writes here | no |
| `workflow-davekjohn/prompts/archive/` | assignments already handed over, by date | no |
| `workflow-davekjohn/prompts/templates/prompt_template.md` | the generated reference of the reset state | yes |
| `workflow-davekjohn/prompts/.gitignore` | keeps the first two out of git | yes |

**The inbox is deliberately not committed**, and the folder ships its own `.gitignore` saying so -- so
adopting the mechanism costs no edit to a `.gitignore` the repo already owns. It is one person's working
input on one machine, changing between saves; a tracked copy would dirty the tree continuously, which is
what a release cut refuses to run on. The template is tracked precisely because the inbox is not:
without it a fresh clone would carry no trace that the mechanism is there.

## The session-start check

`prompt-sessioncheck` reports at every session start while an assignment is waiting, naming its age and
its **first line only**. That is not an oversight: announcing is not handing over, and a session that had
already read the whole assignment would start on it before the requester said go. It stays **silent** in
a repo that has no inbox at all -- the mechanism is opt-in, and a repo that declined it should not be
told about it at every session.

An assignment reported as days old is worth mentioning: it means an earlier session read it and never
archived it, or nobody picked it up.

## Parameters

`-Archive` is the only one a person types. The script also takes `-RootOverride`, which exists so the
test suite can point it at a fixture instead of the real repo -- documented here so nobody has to read
the source to find out it is not for them.
