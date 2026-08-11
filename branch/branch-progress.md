## `docs/v4-4-0-release-note` progress

### Steps

- [x] Note the clock before the cut (step 0a) and record the measurable legs from git timestamps
- [x] Rewrite the consumer section of `releases/notes/4.x/4.4.0.md` against the seven tests
- [x] Write *What it is worth*, with the end-to-end timing and its blocking/background split
- [x] Write *What was still open at this release*
- [~] Repair the stale tier table in `releases/README.md` — dropped: it is the technical writer's
      change, not this document's, and folding it in here would put an unrelated edit in a release-note PR
- [ ] Open the PR, wait for `lint-en-tests`, merge, fold
- [ ] Publish the GitHub Release with the generated body and the three attachments

### Where I left off

The release is cut and pushed (`f241d9d`, tag `v4.4.0`). This branch carries the one hand-written
document. The two legs the document cannot contain — the PR's CI gate and the publish — are reported in
the closing report, per the boundary the document names.
