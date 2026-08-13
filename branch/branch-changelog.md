## `fix/untrack-powershell-module-cache` changelog

### Branch title

a machine-local PowerShell cache stops dirtying the tree and blocking release cuts

### Branch ID

20260813-103458

### Branch type

fix

### What does the change on this branch bring to main?

`Microsoft/Windows/PowerShell/ModuleAnalysisCache` was committed by accident in `65902dd` — a
machine-local binary that PowerShell **rewrites in place** on almost every run. A tracked copy of a file
like that dirties the working tree continuously, and `cut-release.ps1` refuses to run on a dirty tree, so
it **blocked the `v4.6.0` cut twice**; it was restored by hand both times to get the cut to start. It is
untracked here with `git rm --cached`, so the file stays on disk where it belongs — it is PowerShell's to
write, not ours to delete.

**The ignore is anchored at `/Microsoft/`, the whole tree, rather than at that one path**, because the
cause is the redirected per-user data directory rather than the file: PowerShell writes startup-profile
data as a sibling under the same root, so a path-specific rule would let the next artefact from the same
cause straight back in. The leading slash keeps it from ever silencing a legitimately-named folder deeper
in the tree. The observed instance is the one file, and that is the only one this branch deletes.

**Why it was not folded into the release fixes it was blocking.** Untracking a stray binary is repo
hygiene with nothing to do with a release, and putting it in the same pull request as a release-blocking
script fix would have meant two unrelated changes under one review. It was recorded in `v4.6.0`'s own
"still open" list and waited for its own branch, which is this one.

Plugins: none

### Significance

#### Tier 0

A long-standing blocker is gone: anyone cutting a release here met a dirty tree and had to restore a
binary by hand before the cut would start. It cost two manual interventions in the last release alone,
and the next person to hit it would have had no way of knowing it was expected.

**Score:** 4

#### Tier 2

Nothing reaches a consumer. The file was only ever in this repository's own tree, no plugin ships it, and
`.gitignore` is not plugin payload — a consumer's own repo is unaffected either way.

**Score:** N/A

### Pull Request

