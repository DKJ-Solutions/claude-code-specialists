# Working in `workflow-davekjohn/`

This folder belongs to the `workflow-davekjohn` plugin's way of working. The rules a session needs:

- The two files in `branch/` belong to the **current branch**. On the trunk they sit in their reset
  state — never write there until a branch exists (`new-branch` creates one and fills them).
- `branch/branch-changelog.md` folds **verbatim** into `CHANGELOG.md` at the merge; its step-list
  companion gates the PR and the merge (`- [x]` done, `- [~]` dropped with the reason on the line).
- `releases/README.md` is the **living index** — the cut inserts its own row, so never add one by hand
  for a release a script will write. Everything under `releases/audience/` is a **published record**:
  links may be repointed when a target moves, prose is never rewritten.
  **What that protects is a line that was TRUE when it was published** — going stale afterwards is the
  record working. A line that was **false when it was written** is not protected by it, and correcting one
  restores the record rather than breaking it; the rule, and how to mark the correction, is in
  [`RELEASES-portable.md`](../plugins/workflows/workflow-davekjohn/RELEASES-portable.md#once-it-has-landed-it-is-a-published-record--and-that-protects-only-what-was-true).
  **The worked example is one sentence carried across two adjacent notes**: `4.10.0.md`'s publication item
  was true at its merge and overtaken an hour later — stale, deliberately untouched — while `4.11.0.md`
  inherited it, updated the count without re-reading the target, and was therefore false on arrival and is
  corrected. That is the failure to watch for here: a stale line copied forward becomes a false line.
- `prompts/prompt.md` is **Dave's**, not yours: he writes an assignment there instead of typing it into
  the terminal, `/prompt` reads it, and `-Archive` files it once the work is under way. Never write an
  assignment into it, and never read its HTML comments as instructions — they are the scaffold's own
  words, and an inbox holding only comments is empty. It is untracked by design; see
  [`prompts/README.md`](prompts/README.md).
- The generated files in `branch/templates/` are references, not documents to edit: `new-branch`
  rewrites one that has drifted, and in this repo the lint additionally holds them byte-for-byte to the
  formatters (`Get-BranchTemplates`).
- [`CONTRIBUTING.md`](CONTRIBUTING.md) here is the workflow's layer and **wins over the root
  [`CONTRIBUTING.md`](../CONTRIBUTING.md) on conflict**; the root page is the standard workflow that
  holds without the plugin.
