# Working in `workflow-davekjohn/`

This folder belongs to the `workflow-davekjohn` plugin's way of working. The rules a session needs:

- The two files in `branch/` belong to the **current branch**. On the trunk they sit in their reset
  state — never write there until a branch exists (`new-branch` creates one and fills them).
- `branch/branch-changelog.md` folds **verbatim** into `CHANGELOG.md` at the merge; its step-list
  companion gates the PR and the merge (`- [x]` done, `- [~]` dropped with the reason on the line).
- `releases/README.md` is the **living index** — the cut inserts its own row, so never add one by hand
  for a release a script will write. Everything under `releases/audience/` is a **published record**:
  links may be repointed when a target moves, prose is never rewritten.
- The generated files in `branch/templates/` are references, not documents to edit: `new-branch`
  rewrites one that has drifted, and in this repo the lint additionally holds them byte-for-byte to the
  formatters (`Get-BranchTemplates`).
- [`CONTRIBUTING.md`](CONTRIBUTING.md) here is the workflow's layer and **wins over the root
  [`CONTRIBUTING.md`](../CONTRIBUTING.md) on conflict**; the root page is the standard workflow that
  holds without the plugin.
