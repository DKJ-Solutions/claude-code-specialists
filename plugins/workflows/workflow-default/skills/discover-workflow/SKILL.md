---
name: discover-workflow
description: >-
  Read what this repo already says about how work moves through it -- its contribution guide, its CI,
  its branch names, its commit subjects, the scripts it already has -- and write the answer down once, so
  a specialist arrives at it instead of re-deriving it every session. Names what the repo does not say
  rather than filling the gap with a habit from elsewhere. Use this when a specialist lands in a repo that
  has not written its working method down anywhere central, or when `.claude/specialists/repo-workflow.md`
  looks stale against the repo's current conventions.
---

# discover-workflow -- read the repo's own answer, once

The specialists carry a rule in every agent def: read the repo before proposing anything about process,
and where the repo is genuinely silent say so rather than importing a convention from elsewhere (see
[`plugins/agent-shared/repo-way-of-working.md`](../../../../agent-shared/repo-way-of-working.md)). This
skill is that rule, run once and written down, so it does not have to be re-derived at the start of every
session.

## Run it

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/skills/discover-workflow/discover-workflow.ps1"
```

`${CLAUDE_PLUGIN_ROOT}` resolves only inside a plugin-owned component -- when your Claude runs this as a
skill. Typed by hand in a terminal it needs the absolute path to your own plugin cache instead, which is
the reason to ask for the skill rather than to copy the command.

## Parameters

| parameter | what it does |
|---|---|
| `-ConsumerRoot` | The repo to read. Defaults to `$env:CLAUDE_PROJECT_DIR`, then the git root of wherever the script runs from. Point it at a specific checkout when neither of those is the repo you mean. |
| `-OutputPath` | Where the document is written -- absolute, or relative to `-ConsumerRoot`. Defaults to the seam: `.claude/specialists/repo-workflow.md`. |

## What it reads

Eight questions, each answered from evidence rather than assumed -- branch names, the last 100 commit
subjects, the merge history, whether `.github/workflows/` holds CI and which job ids it defines, whether a
PR template or a merge history referencing PR numbers exists, a contribution guide's own headings, whether
the repo addresses its agents directly (`CLAUDE.md`/`AGENTS.md`), and what the repo already scripts for
itself (`scripts/`, `bin/`, `tools/`, a `Makefile`, a `justfile`, a `Taskfile.yml`). Read-only throughout:
it runs `git` queries and reads files, and the one thing it writes is its own output document.

**Every question can come back `SILENT`, and that is a real answer, not a failure to find one.** A repo
that deletes its branches after merging, or that has never written a contribution guide, genuinely has
nothing to read on that question -- and the document says so plainly rather than guessing, exactly the
posture [`workflow-default`](../../README.md) exists to hold.

## Branch names only -- commit subjects are deliberately not mined

The branch-convention question reads **branch names**, and stops there on purpose. An earlier version of
this script also scanned commit subjects, on the reasoning that a repo which deletes branches after
merging keeps their names nowhere else -- and, measured against this very repo, it reported `plugins/`,
`releases/`, `branch/` and `templates/` as branch prefixes. All four were directory paths quoted inside
commit messages, not branches: a `<word>/` token in prose is the same shape as a branch reference, and no
amount of sharpening the pattern can tell the two apart reliably, because they *are* the same shape. So a
ref is evidence and prose is not -- a repo whose branches are all gone answers `SILENT` on this question,
which is the correct answer: it means a specialist asks rather than infers.

## One document, written once, never overwritten

The skill writes exactly one file, `.claude/specialists/repo-workflow.md`, inside the seam that
`specialists-init` already owns -- so a teardown that removes the seam removes this document with
everything else in it, and adopting `workflow-default` adds no second cleanup path of its own.

**It never overwrites.** If the document already exists, the skill leaves it exactly as it is and instead
reports, question by question, which answers would now read differently -- so a person's later
corrections or additions to the file are never silently discarded by a re-run. Delete the file and run
the skill again to regenerate it from scratch. The document itself says the same thing about its own
freshness: it is a snapshot, not something anything keeps in sync.
