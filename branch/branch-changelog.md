## `feat/branch-portable` changelog

### Branch title

The branch dossier convention ships with the plugin as BRANCH-portable.md

### Branch ID

20260813-145422

### Branch type

feat

### What does the change on this branch bring to main?

The `branch/` convention — the two files, the dossier form, the three step marks, the reset state, the
rules, what the fold does at the merge, and multi-machine parking — now travels with the plugin as
`plugins/workflows/workflow-davekjohn/BRANCH-portable.md`, the third member of the portable family
beside `CONTRIBUTING-portable.md` (#566) and `RELEASES-portable.md` (#646). Requested by Dave on
August 13, 2026 as a "PR-portable" and deliberately narrowed to this page: measured against the tree,
the PR cycle itself already travels in `CONTRIBUTING-portable.md` §§3–5, and a second statement of it
would be the drift class this repo keeps paying for — while `branch/README.md` was the one piece of the
PR workflow a consumer could only hand-copy, which is why the `new-branch` and `ship-pr` skills linked
it as an absolute GitHub URL into the source tree.

The portable page follows the conventions `RELEASES-portable.md` set the same day, and says so: *this
repo* names the source, whose measurements (the 105-branch post-merge-step count, the 89/81 tier-1
measurement) travel as evidence; links into the source's script tree are absolute; the files every
adopting repo owns — the two branch files, `branch/templates/` — are named in code rather than linked.
Its cross-references land on the portable siblings (`CONTRIBUTING-portable.md` for the Significance
model) instead of on the source's root docs.

`branch/README.md` keeps what only this repo can own — the directory's own links, the audience-tier
answer that shapes the scaffolded entry here, and the note that this repo's lint enforces byte-for-byte
what a consumer's scaffolder enforces by refresh — and opens with a pointer, exactly like
`CONTRIBUTING.md` and `releases/README.md` now do. The references in `CLAUDE.md`, `CONTRIBUTING.md`,
the plugin README, `CONTRIBUTING-portable.md` and the two skills point at the portable page; the skills'
absolute source-tree URLs became relative plugin links, since the file now travels with them.

### Significance

#### Tier 0

This repo reads the same convention one directory over, and its own answers now have a page that says
only that.

**Score:** 2

#### Tier 2

The last hand-copy-only piece of the PR workflow now reaches a consumer through plugin updates: the
step-mark convention their gates enforce (`open-pr` and `ship-pr` refuse on it) was documented in a file
their tree did not carry, behind an absolute URL — the convention a gate enforces on you is now on a
page you have.

**Score:** 3

### Pull Request

