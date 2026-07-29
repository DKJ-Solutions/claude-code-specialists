### Teardown can hand back working copies of the shared scripts · Feat · 2026-07-29

The runtime dependency that no teardown could fix now has a built-in way out. `teardown.ps1 -Apply
-VendorScripts` copies the plugin's shared script payload (`scripts/task`, `scripts/release`,
`scripts/lib`, `scripts/sync`) into the consumer's own `scripts/`, structure preserved, so the daily git
workflow keeps running once the plugin is uninstalled — instead of the resolver throwing and taking
`start-task`, `open-pr` and `fold-changelog-entry` down with it.

**Why it works, and why that was not obvious until it was checked.** The shared scripts were built to
travel as a payload: they locate the repo through `CLAUDE_PROJECT_DIR` / `git rev-parse --show-toplevel`
— never their own location — and dot-source their siblings `$PSScriptRoot`-relative. A copy therefore
behaves identically anywhere inside the repo, provided the *structure* comes along; a flattened copy would
break at the next branch rather than at copy time. This repo is the standing proof, and it settled the
design choice: its five `scripts/` copies are **byte-identical** to the plugin's, so the workshop has been
running the vendored model all along. That is why vendoring won over the alternative of making the
resolver degrade gracefully — one option ends with a repo that works, the other with a repo that fails
clearly.

**It is the one additive act in a subtractive script**, hence opt-in, and it never overwrites. A
destination that exists and differs is reported and left alone — typically the consumer's own wrapper
around the shared script, so the rule that protects a filled-in lens protects it too; an identical
destination is reported as already current, making re-runs safe. The report also states the one
combination that hands back scripts with nothing to dot-source: if the same run removed
`repo-config.ps1`/`branch-info.ps1` because they were still unfilled scaffolds, the vendored scripts
cannot run — and a repo in that state had no working workflow to preserve in the first place.

Twelve new asserts (89 total in `teardown.tests.ps1`) cover the properties rather than the happy path:
the dry run writes nothing, the payload arrives byte-identical to the plugin's, the sibling lib comes
along, a differing destination is provably **not** overwritten, the collision is reported rather than
silent, a second run recognises its own work, and without the switch nothing is written at all.
