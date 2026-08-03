### Mirror ship-pr, verify-resolved-issues and fix-mojibake into the plugin · Feat · 2026-08-03

Three scripts that consumers could not reach are now mirrored into the plugin, closing the two
largest remaining gaps in the consumer flow. `cut-release.ps1` stays workshop-only, and now for a
reason that survives reading it: lockstep across a marketplace's plugins is meaningless in a
consumer.

**`ship-pr.ps1` (#411) — merge + fold was hand work in every consumer.** It was excluded as
workshop-local because "merge policy and the CI check name are repo-specific", and only half of that
held up. The check name never entered the logic at all — step 3 watches whatever checks the PR has
and reads the exit code, so the name only ever appeared in a progress message, which is now generic.
Merge policy *is* real (this workshop merges; the repo that filed the issue squashes), so it moved
into the seam as the optional `Get-PrMergeMethod`, validated against `merge`/`squash`/`rebase` before
it can reach `gh` at the moment the script is about to write to `main`. Note that the issue predicted
no new contract function would be needed — that is the one part of it that did not survive reading
both files, and building on it would have shipped one repo's merge policy to the other.

**And mirroring it surfaced a defect worth more than the mirror.** Step 5 folded the changelog and
then ran its own `git add -A` + commit + push. `git add -A` stages the *whole tree*, so anything else
modified or already staged rode along into a commit landing directly on `main` under one of the two
named exceptions to "never commit directly". `CLAUDE.md` has stated since August 2, 2026 that the
fold commit "names its paths, so nothing else in the tree can ride along" — true of
`fold-changelog-entry.ps1`, false of this orchestrator, which is the more commonly used of the two
routes. The fold, its commit and its push are now all delegated to that script (`-Push` implies
`-Commit`), so the promise holds on both paths and the exception stays the size it was granted at.

**`verify-resolved-issues.ps1` travels with it** — it *is* ship-pr's step 6, and a consumer whose
ship-pr called a file outside the mirror would fail at the last step of a sequence that has already
merged.

**`fix-mojibake.ps1` (#413) — three repos had each written their own copy.** The part that made it
unusable elsewhere was its default file set: it walked `plugins/**` and `releases/**`, neither of
which exists in a consumer, so the `Test-Path` filter quietly reduced the default to whatever root
docs happened to be there. A gate that examines almost nothing while reporting "clean" is worse than
no gate — the same argument that replaced its lookup table with the inverse round trip. The set is
now repo-owned (`Get-MojibakePaths`, optional), and the tool's own fallback is every `*.md` in the
repo root: the changelog, the root docs, **and any unfolded entry file** — a case the old hardcoded
list never covered, though an entry file is the freshest, most non-ASCII-carrying file in any repo
using this flow.

**One real bug found while moving that list.** PowerShell silently ignores `-Include` when the path
is given as `-LiteralPath`, so
`Get-ChildItem -LiteralPath $pluginRoot -Recurse -File -Include 'CHANGELOG.md','RELEASE.md'`
returned *every* file under `plugins/` while the comment above it named two file names. Nothing was
broken — the extra files were clean, and the tool leaves anything that is not mojibake alone — but
the code and its own description disagreed, and that description is what the lint gate quotes to the
reader as its coverage. Now `-Filter '*.md'`, and the gate's coverage line says what is actually
walked. The same quirk sits in `teardown.ps1:736`, where its `-Include` list is broad enough that
ignoring it yields a superset; filed separately rather than repaired in passing.

Contract: `Get-PrMergeMethod` and `Get-MojibakePaths` declared OPTIONAL, `Get-RepoName` now
attributed to `ship-pr` and `verify-resolved-issues` as well, and the "workshop-only" paragraph
rewritten to cover `cut-release.ps1` alone.

Tests: `fix-mojibake.tests.ps1` gains three scenarios that exercise the default set for the first
time (every other scenario names its file explicitly and so never reached that code) — the fallback,
a configured set that replaces rather than extends it, and a broken `repo-config.ps1` degrading to
the fallback with a warning; `repo-config.tests.ps1` pins both new knobs against the real repo tree;
`script-contract.tests.ps1` covers the two new records and the widened `Get-RepoName` attribution.
