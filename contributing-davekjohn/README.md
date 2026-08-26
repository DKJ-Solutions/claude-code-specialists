# `contributing-davekjohn/` — the workflow's own folder in this repo

Everything portable about the `contributing-davekjohn` workflow gathers here, so the workflow occupies one
folder in the repo root instead of scattering through it (Dave, August 14, 2026). The conventions
themselves travel with the plugin as four portable pages; each page in this folder is **this repo's own
set of answers** to them.

| here | what it holds | portable half |
|---|---|---|
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | **the centre of this folder** — the workflow's contributing layer AND the working rules a session needs here, merged into one page on August 26, 2026 (#886). It wins over both the [root CONTRIBUTING.md](../CONTRIBUTING.md) and the [root CLAUDE.md](../CLAUDE.md) on conflict | [`CONTRIBUTING-portable.md`](../plugins/workflows/contributing-davekjohn/CONTRIBUTING-portable.md) |
| `development-cycle.md` | the branch's own document, present only while a branch is open: its plan, and the DEPLOY section that folds into the changelog | [`DEVELOPMENT-portable.md`](../plugins/workflows/contributing-davekjohn/DEVELOPMENT-portable.md) |
| [`releases/`](releases/) | the release history and the published audience notes | [`RELEASES-portable.md`](../plugins/workflows/contributing-davekjohn/RELEASES-portable.md) |

In this repo the portable pages resolve as relative links because this is the plugin's **source**; in a
consumer they live in the plugin install instead, which is why the consumer version of this page (the
`adopt-workflow-folder` skill scaffolds it) names them in code rather than linking them.

Two things a consumer's folder has that this one deliberately does not carry as its own: the generated
`releases/development/` and `releases/github/` trees stay at this repo's root (they are the
machine-written record and the publish artefact, not hand-kept pages), and this page itself is
hand-written rather than scaffolded — the scaffold refuses a repo that publishes plugins.
