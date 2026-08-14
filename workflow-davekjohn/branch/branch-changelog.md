## `feat/workflow-folder` changelog

### Branch title

The branch dossier moves into the workflow's own root folder

### Branch ID

20260814-085807

### Branch type

feat

### What does the change on this branch bring to main?

The `branch/` directory — the entry, the step list and the generated templates — moves from the repo
root into `workflow-davekjohn/`, the workflow's own root folder. This is phase 1 of gathering
everything portable about the workflow in that one folder at every consumer (Dave, August 14, 2026),
instead of scattering it through their root; phase 2 adds the scaffold skill that places the folder's
docs (`README.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `releases/README.md` + `audience/`).

Concretely: `Get-BranchFilePaths` and the template-dir constant now answer
`workflow-davekjohn/branch/...`, so every shared script (`new-branch`, `open-pr`, `ship-pr`, the fold,
the cut's unfolded-entry guard) and every seam-reading lint check follows in one move. The three
genuinely hardcoded sites moved with it: `Get-MojibakePaths` in `scripts/repo-config.ps1` now covers
`workflow-davekjohn/` whole (forward-compatible with phase 2's scaffolded docs), and two test fixtures
pin the new location. The PR-template placeholder names the new path — recognise four, write one: the
three older placeholder strings stay recognised because every consumer's template carries one of them
right now. The directory itself moved by `git mv`, with the moved `README.md`'s relative links
repointed one level deeper, and the live docs (portable pages, skills, lenses, root docs) now name the
new location; dated records and release notes keep the old name, as published records do.

**No dual-read of the old root `branch/` location, deliberately** (Dave): `new-branch` creates the new
directory on the first branch, and a repo still carrying a root `branch/` from before removes it by
hand. One consequence to know: `Get-MojibakePaths` is an `Adopt = 'copy'` seam, so a consumer's copy
taken before this change still names the old location and drops the moved files out of mojibake
coverage until they re-adopt — the contract record now says so, and phase 2's scaffold will surface it.

### Significance

#### Tier 0

The branch files, the templates and this repo's own muscle memory move to a new path; every script
follows the seam, so the working difference is one directory level.

**Score:** 2

#### Tier 2

Every consumer's branch dossier lands in `workflow-davekjohn/branch/` after the plugin update — the
first visible piece of the one-folder model — and a leftover root `branch/` must be removed by hand.

**Score:** 4

### Pull Request

