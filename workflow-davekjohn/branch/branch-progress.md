## `fix/rename-continue-skill-to-handover` progress

### Steps

#### PLAN

- [x] Measure where the name is load-bearing before touching anything: 12 files outside `releases/`,
      plus the folded entries in `CHANGELOG.md` (left alone as records).

#### CREATE

- [x] `git mv skills/continue` → `skills/handover`, frontmatter `name: handover`, body renamed.
- [x] Say on the page WHY it is not `/continue` (the built-in collision), so nobody restores the old name.
- [x] `/lock`'s page: the three-step block, the four cross-references, and a line on the rename.
- [x] `session-status.ps1` docstring, in both mirrors — held byte-identical afterwards.
- [x] `shared-scripts-lib.ps1`: the comment explaining why two skills share one script.
- [x] Docs: both `<!-- skills:all -->` spans + the prose in the root `README.md`, the plugin's skill
      table, `scripts/README.md`, the `.gitignore` comment, lenses 05-15 and 06-25.
- [~] Rename `.claude/handover.md` — dropped: the file keeps its path, and after this rename the
      reading command and the file it reads finally share a name.
- [~] Rename `lock` → `catch` — dropped from this branch on Dave's instruction ("eerst continue"), since
      the collision is the defect and the second rename is a preference. It follows on its own branch.

#### TEST

- [x] `check-plugin-integrity.ps1` green, including `[skill-list]` over both spans (19 canonical skills).
- [x] `check-script-contract.ps1` green — the registry's `Skill = 'lock'` entry is untouched by this rename.
- [x] Tree-wide grep: no `/continue` or `skills/continue` left outside the four deliberate mentions of
      the built-in and the untouched records.

### Where I left off

Ready for the PR. `lock` → `catch` is the agreed follow-up and gets its own branch.
