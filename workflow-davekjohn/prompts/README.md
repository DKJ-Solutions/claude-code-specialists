# `workflow-davekjohn/prompts/` — the prompt inbox

A terminal is the worst surface available for a long assignment: no wrapping, no editing, no saving it
half-finished, and a paste that mangles anything with a newline in it. So the assignment gets written in
an editor instead, into `prompt.md`, and a session picks it up with `/prompt` (Dave, August 15, 2026).

It is the **mirror of `/lock`**. That one is Claude writing a note for the next Claude; this one is Dave
writing for the next session.

```text
he writes    workflow-davekjohn/prompts/prompt.md, in his own editor, and saves
/prompt      the session reads it and takes it through the ordinary intake
-Archive     once the work is under way: filed under the date, the inbox reset
```

**The procedure travels with the plugin as the `prompt` skill, and there is deliberately no
`PROMPTS-portable.md` beside the other three portable pages.** Those pages exist because a convention
has a portable half and a local half a repo has to answer — the branch prefixes, the release tiers, who
approves what. This mechanism has no local half to answer: one file, one command, and "is something
waiting" is decided structurally rather than by a value anyone configures. A portable page would be the
skill again under another name, which is the duplication `agent-shared/` exists to prevent.

## What is here

| path | what it is | committed |
|---|---|---|
| `prompt.md` | the inbox — Dave writes here | **no** |
| `archive/` | assignments already handed over, by date | **no** |
| `templates/prompt_template.md` | the generated reference of the reset state | yes |
| `.gitignore` | keeps the first two out of git | yes |

**The inbox is not committed, and that is the design rather than an oversight.** It is one person's
working input on one machine, changing between saves; a tracked copy would dirty the tree continuously,
which is exactly what `cut-release.ps1` refuses to run on — the failure a tracked PowerShell cache
already caused here twice. The template is tracked *because* the inbox is not: without it a fresh clone
would carry no trace that the mechanism exists.

The folder ships **its own** `.gitignore` rather than lines in the repo's root one, so a consumer adopts
the inbox with a single command and no edit to a file they already own.

## Rules a session needs

- **Everything inside HTML comments is scaffold** and is stripped before the body is read. An inbox
  holding only comments counts as empty — nothing is announced, nothing is picked up, and the comments
  are never read as instructions.
- **`prompt.md` is created when absent and never overwritten**, whatever it holds. The one file
  `/prompt` may rewrite is the generated template, on drift — the same exception `new-branch` makes for
  `branch/templates/`.
- **Archive only once the work is genuinely under way.** A session that loses its context between the
  read and the start would find an empty inbox and no record of what was asked — and the archive, being
  untracked, is not something a colleague can recover from the repo.
- **A written prompt cannot answer a follow-up question.** Where a course-defining point is genuinely
  ambiguous, ask in the session as usual; do not assume, and do not write back into the file.

---

## Specific to this repo (claude-code-specialists)

> *Everything above is the mechanism, and it travels to every repo that enables the plugin. This part is
> the claude-code-specialists lens.*

- **The inbox places itself here, not through `adopt-workflow-folder`.** That scaffold refuses a repo
  publishing plugins, so this folder arrived from the first `/prompt` run — which is the same route a
  consumer takes anyway, since the command places what is missing before it reads.
- **The hook lags this branch.** `prompt-sessioncheck` runs from the plugin cache, which holds the last
  **pushed** version, so the session-start announcement only starts working here after this work is
  merged and pushed. The command itself runs from `scripts/task/prompt-inbox.ps1` immediately.
