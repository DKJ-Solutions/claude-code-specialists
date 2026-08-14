## `feat/claude-code-workflows` progress

### Steps

- [x] Write the changelog entry: description, tier 0 score, tier 2 answer
- [x] `README.md` repo layout — the `.github/` enumeration named only `workflows/ci.yml`, and there are three workflows now
- [x] Sylvester's lens (`05-15`) — a bullet for the two new workflows, carrying the hardening reasons so they are not re-derived
- [x] `workflow-davekjohn/CONTRIBUTING.md` — say which of the two PR checks blocks the merge and which is advisory. Target corrected mid-branch: the gates section moved out of the root page in `627f030` earlier the same day, and the first measurement of what goes stale was taken on the PR branch, which predates that commit
- [~] Root `CONTRIBUTING.md` — dropped. Its point 2 names `lint-en-tests` as the required check, which stays exactly true, and that page is deliberately thin; a second copy of the advisory-check paragraph would be the duplication this repo keeps paying for
- [~] Lint gate + test suites green — dropped as a step. `open-pr` runs both and refuses to push on a failure, so a box here is enforced by a gate and carries no information; that is the same measurement that emptied this repo's PR template
- [~] PR — dropped for the same reason: it is the movement this list is checked by, not a step inside it

### Where I left off

Entry + the three documents that go stale: README repo layout, Sylvester lens, CONTRIBUTING gates section.

The workflows themselves already landed on `main` via PR #658 (merge `3a79e3c`), which was opened by the
GitHub App installation flow rather than by `new-branch` — so it carried no entry and no step list, and
its branch name had no valid prefix. This branch is the record that merge could not write.

Still open and NOT part of this branch: PR #658's body is the upstream installation template, and it
describes tool access this repo deliberately removed before the merge. Whether to replace that body or
correct it in a comment is Dave's call, and a merged PR's body can still be edited.
