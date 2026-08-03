### cut-release moves to the shared mirror, with the repo differences in the seam · Feat · 2026-08-03

**Phase 1 of [#417](https://github.com/DaveKJohn/claude-code-specialists/issues/417)** — the issue
stays open for phase 2. Dave chose option 2 (deduplicate, rather than re-synchronise two files that
will drift again) on August 3, 2026, and chose to stage it after the measurement below.

**The issue's premise did not survive reading both files, and that changed the shape of the work.**
It described the two `cut-release.ps1`s as *"pure changelog→release-notes generators"* differing in
three ways. True of the shared core; it misses two whole halves. The source carries ~80 lines of
marketplace machinery with no counterpart in the consumer (manifest enumeration, per-plugin
`CHANGELOG.md`, `RELEASE.md` cards, the lockstep `plugin.json` bump), and the consumer carries ~70
lines of highlights + HTML + developer-block with no counterpart here. So the seam needs six things,
not three — and the largest, the plugin tier, was not on the list:

| # | knob | named in #417 |
|---|---|---|
| 1 | `Get-ReleaseNotesGrouping` — notes per major or per minor | yes |
| 2 | the highlights tier | yes — **phase 2** |
| 3 | `Get-ReleaseLiveMarker` — the "currently live" suffix | yes |
| 4 | `Get-ReleasePluginTier` — whether the marketplace half runs at all | **no** |
| 5 | `Get-ReleaseCategoryTitles` — the category labels | **no** |
| 6 | `Get-ReservedRootMd` — which root docs are permanent | **no** |

All five landing now are OPTIONAL in the script contract, and every fallback is what the script did
while it was workshop-only, so a consumer that defines nothing gets the unchanged behaviour. Knob 2
is deliberately absent rather than stubbed: it is a feature to port, not a switch, and declaring
config that nothing reads is the dead knob `repo-config.ps1` exists to avoid.

**Knob 6 is the interesting one, because it has already cost three releases.** The reserved-root-docs
list lived in the script and went stale three times — [#165](https://github.com/DaveKJohn/claude-code-specialists/issues/165),
then `QUICKSTART.md` + `UNINSTALL.md` in #405 when flattening moved them to the root, then
`ADOPTION.md` in #408 earlier today. Each time it would have refused a release over a document nobody
had failed to fold. Which root docs a repo has is by definition not knowable by a shared script, so it
belongs in the seam and now lives there.

**`release-lib.ps1` travels with it, and its one repo-owned dependency does not.** The lib
dot-sourced `branch-info.ps1` as a same-folder sibling; the branch table is repo-owned and therefore
does not go into the mirror. `cut-release` now loads the consumer's own `branch-info` from the repo
root before calling in, the sibling dot-source is guarded, and `Get-ReleaseCategories` probes for
`Get-BranchTypes` and `Get-ReleaseCategoryTitles` instead of assuming either — the pattern
`teardown.ps1` already uses. Measured en route: the old unguarded dot-source does fail outright when
the lib is loaded from anywhere but its own folder, so this coupling had to go before the mirror
could work at all.

**"Behaviour unchanged" is verified rather than asserted.** Two throwaway clones, same probe release
(`-Bump patch -NoPush`), one on `main` and one on this branch. Both produced `v3.1.3` with 18 entries,
four plugins carded and bumped; every artefact hashed identical — the notes file, `releases/README.md`,
`CHANGELOG.md`, the per-plugin CHANGELOGs, the `RELEASE.md` cards and `plugin.json`.

**One pre-existing defect found in passing, deliberately NOT repaired here.** An em-dash in an
*existing* `## Releases` heading is re-emitted on a line of its own when that block is carried over.
It reproduces against `release-lib.ps1` as it stands on `main`, so it is not this change's doing — and
it did **not** reproduce against this repo's real `CHANGELOG.md`, which is why it is recorded with a
note in the test rather than fixed: the cause is not isolated, and repairing an unisolated cause is
the failure mode `CLAUDE.md` names outright.

Tests: the five knobs are in the contract check (its deliberate drift counts moved 14 → 19), the
override-merge and marker-moves behaviour is asserted in `release-lib.tests.ps1`, and the mirror is
covered by the existing shared-scripts drift lint.

**To do / where I left off:** phase 1 done — lint gate green, all 23 suites green. Phase 2 (porting
the highlights tier + the developer-block wording knob) is still open on #417, and will stop for
Dave's word rather than merging on the gates, because it renders stakeholder-facing HTML.
