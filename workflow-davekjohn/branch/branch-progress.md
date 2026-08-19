## `docs/release-history-to-root` progress

### Steps

#### PLAN

- [x] Draw the line by asking what survives the workflow folder being deleted, rather than moving
      everything: the release **list** is the repo's history, the `audience/` notes are the
      workflow's, because they exist only because the tier model does.
- [x] Check the two mechanisms before touching anything: the row inserter matches a specific
      `| Version | Date | Type | Title |` header (so the new page's own directory table cannot be
      mistaken for it), and the major-heading pattern accepts `###` as well as `####`.

#### CREATE

- [x] Move the list — 135 lines — to `releases/README.md`, with links rewritten for the new depth and
      the `davekjohns-workshop` note moved along.
- [x] `scripts/repo-config.ps1`: `Get-ReleaseHistoryPath` back to its shared default, with the round
      trip and its reasoning written above the value.
- [x] Both release pages rewritten around the new split, each stating the asymmetry so it is not
      "tidied up" later; the mirroring instruction now tells a consumer to move a list they already
      have rather than delete it.
- [x] Payload corrected: `adopt-workflow-folder` no longer tells a consumer to repoint the seam, in
      the script output and in its skill page; `script-contract-lib`, `release-lib` and `cut-release`
      comments follow. Mirrors and blueprint regenerated.
- [x] Sweep the 40 inbound references and repoint the ones meaning *the list* across `README.md`,
      `INSTALL.md`, `CLAUDE.md`, `CHANGELOG.md`'s intro, `ADOPTION.md`, `language-layers.md` and two
      lenses.

#### TEST

- [x] Suites: 5 failed on the first run, all four causes fixed, then all 43 pass.
- [x] `check-plugin-integrity.ps1`: 0 errors. `check-script-contract.ps1`: 0 errors.

### Where I left off

Nothing open.

Two things recorded rather than acted on:

- **`CHANGELOG.md`'s #753 entry still names the old seam value.** That was true when written
  yesterday, so it is protected by the record rule — going stale is the record working. Do not
  "correct" it.
- **`find-specialist-mentions.ps1` classifies both `releases/*` and `workflow-davekjohn/releases/*`
  as history.** Both branches are still correct after the move — a consumer may have either — so it
  was deliberately left alone rather than narrowed to the one this repo now uses.
