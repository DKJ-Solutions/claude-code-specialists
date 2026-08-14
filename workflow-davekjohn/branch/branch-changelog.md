## `feat/workflow-folder-scaffold` changelog

### Branch title

A consumer gets the workflow folder scaffolded, and the session check reports it missing

### Branch ID

20260814-094602

### Branch type

feat

### What does the change on this branch bring to main?

Phase 2 of the workflow folder (Dave, August 14, 2026): a consumer can now receive the folder's
contents, and hears about it while they have not. Three pieces:

**The `adopt-workflow-folder` skill + shared script** (`scripts/task/adopt-workflow-folder.ps1`,
mirrored and registered like its sibling `adopt-config`) scaffolds `workflow-davekjohn/` in one move:
`README.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `releases/README.md` with the history table header the
cut inserts its row after, `releases/audience/` (a `.gitkeep` until the first cut), and the branch
dossier in its reset state — written by the same formatters `new-branch` and the fold call, so the
scaffold cannot write a shape of its own. Dry-run by default, strictly additive, never overwrites;
refused in a repo that publishes plugins, because the source keeps its docs at its root (Dave's
decision when the folder was scoped). A plugin install writes nothing into a repo, which is why this
is a skill and not an install step.

**The session signal**: `check-script-contract.ps1` now reports `[ERROR]` while `workflow-davekjohn/`
does not exist — existence only, since the folder's contents legitimately differ per repo — surfaced
at session start by the script-contract hook, naming the skill that closes it.

**Two release-machinery repairs the relocated releases root needed**, both latent until a consumer
answers `Get-ReleaseNoteRoot` with `workflow-davekjohn/releases/audience`: the history-table row is
now computed relative to the history file's own directory (`Get-RelativeLinkPath`, new in
`release-lib.ps1`) instead of stripping a hardcoded `^releases/` prefix — the exact "root outside
releases/ would need a `../` here" case the old comment said no repo had asked for yet — and the
hand-written note's link prefix is derived from the note's own depth instead of the fixed `../../../`.
For this repo both derivations produce byte-identical output to the old code, which is what made
replacing them safe.

### Significance

#### Tier 0

The two release repairs are latent here (this repo's layout produces byte-identical output), and the
new script is refused in this repo by design — the working difference is one more registered mirror
and one more [OK] line at session start.

**Score:** 1

#### Tier 2

The folder model becomes usable: a consumer installing the workflow gets told at session start what to
run, one skill places everything portable in one folder, and the first cut against the relocated
releases root writes working links instead of dead rows.

**Score:** 4

### Pull Request

