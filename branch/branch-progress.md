## `docs/v4-2-0-release-documents` progress

### Steps

- [x] Run `new-internal-note.ps1 -Version 4.2.0` (skeleton + the overview row's Version cell)
- [x] Write the internal note: what is different, what it is worth, what was still open at this release
- [x] Rewrite the generated consumer draft for the reader who decides whether to update
- [x] Hold the consumer document against all seven tests, check 25 included
- [x] Lint gate green, check 25 reading 12 consumer documents instead of 11

### Where I left off

Both documents are written and the gate has read them. What remains is the PR itself, which is not a step
of this branch's plan: `open-pr` runs the lint and all 30 suites again on the way out.
