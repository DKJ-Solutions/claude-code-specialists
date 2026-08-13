# `branch/` — the two files a branch works in

Everything a branch needs to carry lives here, split into two files with one job each — the entry
(`branch-changelog.md`) and the step list (`branch-progress.md`). **The convention is not this repo's
own** — it is what the `workflow-davekjohn` plugin does, in every repo that enables it, and it is
described once, with the plugin:

📄 **[The `branch/` files — the portable half](../plugins/workflows/workflow-davekjohn/BRANCH-portable.md)**

Read that first. It covers the two files and their jobs, the dossier form, the three step marks, the
reset state on the trunk, the rules, what the fold does at the merge, and working from more than one
machine. **This page is this repo's set of answers to it**, and nothing more.

The split is the same one [`CONTRIBUTING.md`](../CONTRIBUTING.md) and [`releases/README.md`](../releases/README.md)
already use: the portable half travels with the plugin, the local half stays in the repo (Dave,
August 13, 2026 — proposed as a "PR-portable" and narrowed to this page, because the PR cycle itself
already travels in `CONTRIBUTING-portable.md`).

---

## Specific to this repo (claude-code-specialists)

> *Everything in the portable half is the convention, and it travels to every repo that enables the
> plugin. This part is the claude-code-specialists lens: if you adopt the convention in your own repo,
> this is the section you replace.*

- **The directory's contents here:** [`branch-changelog.md`](branch-changelog.md) ·
  [`branch-progress.md`](branch-progress.md) · the generated references in [`templates/`](templates/).
- **The audience tier is `2`** (`Get-ReleaseAudienceTier`), so the entry scaffolds `#### Tier 0` and
  `#### Tier 2` — the worked example in the portable half is this repo's own shape.
- **The lint gate enforces the convention here**, which a consumer's repo typically cannot: the
  templates are held byte-for-byte to the formatters `new-branch` calls (`Get-BranchTemplates`), the
  entry-shape claims on this page's portable predecessor are checked against the scaffolder, and the
  heading-level rules the portable half describes are all checks in
  [`check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1). In a consumer, the
  scaffolder's refresh-on-drift is what keeps the templates current instead.
