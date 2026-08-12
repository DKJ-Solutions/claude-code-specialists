## `fix/session-status-note-by-version` progress

### Steps

- [x] Sort the release notes by the version in the filename instead of by `LastWriteTime`, keeping the
      mtime path as a documented fallback for a note tree that is not named `X.Y.Z`
- [x] Regression test: identical mtimes plus a deliberately newer *lowest* version, and `1.10.0` beside
      `1.9.0` so a string sort cannot pass either
- [x] Verify the test in both directions — it must fail against the old script
- [x] Measure how far the failure reaches: a fresh clone gives every note one checkout timestamp
- [x] Fill in the changelog entry (both tiers, with scores)
- [ ] Lint + test gates green, PR merged, entry folded

### Where I left off

