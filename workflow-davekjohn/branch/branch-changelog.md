## `feat/contributing-into-workflow-folder` changelog

### Branch title

This repo's CONTRIBUTING.md moves into the workflow folder

### Branch ID

20260814-105051

### Branch type

feat

### What does the change on this branch bring to main?

The contributing documentation becomes **two layers, deliberately** (Dave, August 14, 2026). The root
`CONTRIBUTING.md` does not move and does not describe the plugin any more: it is the **standard
workflow** — branch + PR, CI green, merge — the page that stays meaningful in a repo where the plugin
is absent: a fresh checkout, a teardown, a contributor who installed nothing. Beside it, as an **extra
file**, `workflow-davekjohn/CONTRIBUTING.md` carries the workflow's layer: everything the plugin owns
(the branch dossier, the folded entry, the significance model, the release cycle) plus this repo's
answers to the seams — the content the root page used to hold. **Where the two disagree, the workflow's
page wins**; the rule is stated on both pages, in the portable half
(`CONTRIBUTING-portable.md` gained a "two contributing pages" section), and in the
`adopt-workflow-folder` scaffold, whose consumer template now opens with it.

An earlier reading of this assignment moved the root file into the folder; Dave corrected it mid-build
— "het verhuist niet, het komt als extra bestand erbij" — and the move was reverted before anything
shipped: `Get-ReservedRootMd` still lists `CONTRIBUTING` (the root page is permanent), README and
SECURITY keep pointing at the root page as the entry point, and `CHANGELOG.md`'s intro points its
mechanism sentence at the workflow layer, which is the page that actually describes the mechanism.

### Significance

#### Tier 0

Where a rule lives is now answerable in one sentence — standard rules in the root, plugin rules in the
folder, folder wins — and this repo's seam-answers table moved to the page a reader of the folder finds
first.

**Score:** 2

#### Tier 2

A consumer's root CONTRIBUTING.md is never rewritten by adoption: the scaffolded folder page arrives
beside it, states that it wins on conflict, and the portable page now says so — closing the open
question of what adopting the workflow means for a repo that already has contribution rules.

**Score:** 3

### Pull Request

