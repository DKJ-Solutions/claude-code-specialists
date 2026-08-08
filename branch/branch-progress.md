## `docs/v3-9-0-release-documents` progress

### Steps

- [x] Cut `v3.9.0` (minor, earned by two tier-2 entries), inspect the artefacts, push commit + tag
- [x] Generate the internal note skeleton and write it — what the release is worth, and what stays open
- [x] Rewrite the highlights draft for a consumer deciding whether to update, not for a reviewer
- [x] Verify the consumer-facing command actually resolves; correct it to the skill route
- [~] Repair the `adopt-config` skill page's hardcoded cache paths — dropped here on purpose: it is an
      unrelated live defect and belongs to its own branch, recorded in this branch's entry
- [x] Ship both documents via this branch + PR

### Where I left off

Both documents written and shipped. Publishing the GitHub Release is the next step of the release
checklist rather than of this branch — it can only run once this PR is merged, since its body is the
internal note this branch adds.
