## `feat/pr-title-is-derived` progress

### Steps

- [x] Rename the entry section to `Branch title`, with `Branch description` recognised and never written
- [x] Compose the PR title in ONE shared place: the type from the branch prefix, the words from the entry
- [x] `open-pr` derives it; `-Title` is accepted, ignored and says so; `ship-pr` follows
- [x] The documents that state the old `-Title` convention: Derek's lens, `branch/README.md`, the skills, `CONTRIBUTING.md`, `CLAUDE.md`
- [x] Tests, the plugin mirrors, and the script contract

### Where I left off

Lint 0 findings, all 26 suites green, script contract 0 errors.

**Three things worth carrying forward.**

The rename was not a one-line change, and every place it broke was a reader that asked a **per-section**
question of the **flattened** list of retired headings. That shortcut was invisible while every retired name
belonged to a section no other document carried. If another section is ever renamed, look at
`Get-EntryRetiredSectionHeadings`' callers first -- the lint and `new-internal-note` genuinely want the flat
set, and nothing else does.

The `shared-scripts` fixture carried a heading shape (`- Feat - 2026-07-21`) that appears **zero** times in
`releases/`. It sat there harmlessly for as long as nothing parsed the heading. A fixture in an invented
shape proves nothing the day something starts reading it.

`branch/templates/*` are **generated** from `Get-BranchTemplates` -- editing one by hand is caught by the
lint's branch-template check. Change the guidance in `entry-scaffold-lib.ps1` and regenerate.

Next in the queue: #509, #507, #508, then #512 and #456.
