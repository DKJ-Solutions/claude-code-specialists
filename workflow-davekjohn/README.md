# `workflow-davekjohn/` — the workflow's own folder in this repo

Everything portable about the `workflow-davekjohn` workflow gathers here, so the workflow occupies one
folder in the repo root instead of scattering through it (Dave, August 14, 2026). The conventions
themselves travel with the plugin as four portable pages; each page in this folder is **this repo's own
set of answers** to them.

| here | what it holds | portable half |
|---|---|---|
| [`CLAUDE.md`](CLAUDE.md) | the working rules a Claude session needs in this folder | — |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | the workflow's contributing layer — it wins over the [root page](../CONTRIBUTING.md) on conflict | [`CONTRIBUTING-portable.md`](../plugins/workflows/workflow-davekjohn/CONTRIBUTING-portable.md) |
| `development-cycle.md` | the branch's own document, present only while a branch is open: its plan, and the DEPLOY section that folds into the changelog | [`DEVELOPMENT-CYCLE-portable.md`](../plugins/workflows/workflow-davekjohn/DEVELOPMENT-CYCLE-portable.md) |
| [`prompts/`](prompts/) | the prompt inbox: an assignment written in an editor instead of the terminal | the `prompt` skill |
| [`releases/`](releases/) | the release history and the published audience notes | [`RELEASES-portable.md`](../plugins/workflows/workflow-davekjohn/RELEASES-portable.md) |

`prompts/` is the one row whose portable half is a **skill** rather than a page, and deliberately: the
other three describe a convention with a local half each repo answers, while this mechanism has none —
one file, one command, and no value anyone configures. A portable page would restate the skill under
another name.

In this repo the portable pages resolve as relative links because this is the plugin's **source**; in a
consumer they live in the plugin install instead, which is why the consumer version of this page (the
`adopt-workflow-folder` skill scaffolds it) names them in code rather than linking them.

Two things a consumer's folder has that this one deliberately does not carry as its own: the generated
`releases/development/` and `releases/github/` trees stay at this repo's root (they are the
machine-written record and the publish artefact, not hand-kept pages), and this page itself is
hand-written rather than scaffolded — the scaffold refuses a repo that publishes plugins.
