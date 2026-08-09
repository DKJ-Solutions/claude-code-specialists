## `fix/pr-template-restates-the-entry` changelog

### Branch title

The PR template stops restating the changelog entry

### Branch ID

20260809-113542

### Branch type

fix

### What does the change on this branch bring to main?

`.github/pull_request_template.md` is one section now — the changelog entry — because `open-pr.ps1`
composes the body from `branch/branch-changelog.md`, so everything else the form asked was already
answered a few lines lower in the same body.

**Measured over 60 PRs (#468–#537) before removing anything:**

| section | what the measurement says |
|---|---|
| `## What does this change do?` | filled with the **Branch title**, then the whole entry follows — including `### What does the change on this branch bring to main?`, which answers the H2's question properly eight lines below it |
| `## Type of change` | exactly **one of four** boxes ticked in **60/60** PRs. The entry states the same fact under `### Branch type`, and the GitHub label comes from `Get-BranchInfo`, not from the tick |
| `## Checklist` | `Changelog entry written` **60/60** ticked, `check-plugin-integrity.ps1 green` **0/60**, `Shared agent defs change here only` **0/60** |
| `## Explicit approval` | `Requested by Dave` **60/60** ticked |

Not one box has ever varied. Two are ticked by `open-pr.ps1` itself — a script asserting something
about its own run — and the two the docstring called "human judgement checks the script cannot honestly
verify" have never been verified by a human, while both are already enforced by gates that block the
PR. **A box that is always ticked and a box that is never ticked carry the same information.**

**A fourth finding the report did not ask about:** the form still offered a `chore/` row, four days
after `Test-BranchName` began refusing that prefix outright. It was the one line in the template that
could actively mislead — an invitation to a branch name `new-branch.ps1` rejects.

**The heading is `## Changelog entry`, not the entry's own question, and that is a deliberate
departure from the request.** Replacing the H2 with `## What does the change on this branch bring to
main?` literally would have produced that exact heading twice, four lines apart — an H2 and an H3 with
identical text — because the section it duplicates lives *inside* the block it introduces. The goal was
that the question is asked once, in the entry's wording; a label above the entry achieves it, a second
copy of the question does not.

**`open-pr.ps1` keeps filling in every section that was removed.** A consumer's PR template is their
file; all of them still carry these sections and they receive this script through a plugin update
rather than by choosing to. Recognise both, write one. What changed in the script is smaller and in the
other direction:

- the new placeholder string joins the two it already recognised, so the substitution keeps firing;
- `-RefreshBody` falls back to the previous headings when the current one is not found. It reads the
  target heading from the template's first `## ` line, which is right for every PR opened since — but a
  PR opened *before* the rename carries the old heading, and `Update-PrBodySection` returns the body
  untouched when it cannot find one. Without the fallback such a PR would report "already matches the
  entry" while matching nothing.

**Two guards, because this coupling fails silently.** The body is built by replacing a placeholder
*line* matched on exact string equality: a typo fix or a reworded hint in the template stops the match,
and the PR is then opened with the placeholder still in it and no description at all — valid markdown,
exit 0, visible only to whoever reads the published body. So `pr-body.tests.ps1` now asserts from
**both files** that the template's comment appears verbatim in `open-pr.ps1`'s recognised list, and
`shared-scripts.tests.ps1` gained a scenario running the pre-#538 template end to end, since the
ticking used to be proved incidentally by the repo's own template and would otherwise have been kept
with nothing watching it.

**One documented reason had to be rewritten rather than left standing.** Lint check 20 matches an
entry's section *count* and not its section *names*, and the recorded justification is that
`What does this change do?` and `Type of change` are retired entry sections **and** live PR-template
headings — so a name-matcher accused two correct documents. That collision is gone as of this change,
and the choice does not move with it: name-matching also lost on its narrowed variant (3 findings, 2
false, against 4 claims with 3 correct), and a rule keyed on names is one rename away from going silent
— which is precisely what just happened to the collision itself. The measurement is kept in the past
tense in `CLAUDE.md`, the lint and its suite, because a superseded measurement is worth something only
while it says when it was taken.

### Significance

#### Tier 0

Every PR body here loses four sections that said nothing, and the one question a reviewer opens the PR
for is asked once instead of twice. The measurement is the argument: 60 PRs, no box that ever varied,
and a `chore/` row inviting a branch name the tooling refuses.

**Score:** 3

#### Tier 1

Anyone reading a PR in this project gets a body that is the changelog entry and nothing else, so the
reviewable content starts at the top instead of after a form. The `chore/` row is the part that was
actively costing someone eventually.

**Score:** 2

#### Tier 2

A consumer's own template is untouched and keeps being filled in exactly as before — that is the whole
point of the back-compat half. What reaches them is the `-RefreshBody` fallback, which prevents a PR
opened before any template rename of *their* own from silently becoming unrefreshable, and a skill page
that now explains which heading the refresh targets and why.

**Score:** 1

### Pull Request

