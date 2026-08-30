# Changelog

Everything merged since the last release sits under **`## [Unreleased]`**, **newest first**: **one `###` per
change**, and under it two named `####` sections. The `###` heading is the change's own —
`` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `#### What makes this deploy extra special` for the second audience, and `#### Pull Request`.
Every level here moved one deeper on August 26, 2026, when the pending section above them was introduced and
the development cycle beside them shifted to match; entries written before that day carry the whole set one
level shallower and are read exactly as they always were.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
[`releases/history.md`](releases/history.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`contributing-davekjohn/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## [Unreleased]

### DEPLOY: `fix/blueprint-record-carries-only-its-own-value-v1` · 20260830-111440

The config blueprint's generator handed the first function under a shared assignment block every value
in that block, while each of the block's other functions already shipped its own. Three variables
therefore arrived in a consumer's `scripts/repo-config.ps1` assigned twice, the second assignment
silently winning. `Get-FunctionBlock` now trims its walk back to the values the function itself reads,
asked of that function's own AST rather than of the assembled text -- where an assignment target is
indistinguishable from a read.

Nothing errored and a fresh adoption behaved correctly, because the duplicate values agreed. The cost
lands on the next reader: these four strings are the entry-scaffold wording, and they exist to be
translated (#410). A consumer editing them under the comment that explains them would have had an
assignment three lines further down -- one they had no reason to read past -- put the English back,
after which `new-branch` writes English stubs and `open-pr`'s body-heading gate goes on recognising
only the English marker, with nothing anywhere saying why.

**Score:** 3

#### What makes this deploy extra special

It is only visible in a file `adopt-config` has written. The source repo's own `repo-config.ps1`
assigns each of these variables exactly once, so no amount of reading this tree shows the defect --
which is why the regression test asserts on the placed consumer lib and not only on the artefact.

The measurement that mattered was not the fix but the test: the natural way to write the per-record
assert passes against the broken artefact, because the parser cannot distinguish an assignment target
from a read. Running the new asserts against the old generator is what caught it.

**Score:** N/A

#### Pull Request

a blueprint record carries only the values its own function reads

Plugins: contributing-davekjohn

[PR #1129](https://github.com/DaveKJohn/claude-code-specialists/pull/1129)

---

### DEPLOY: `docs/portable-cycle-begins-at-the-issue-v1` · 20260830-102958

**The portable half of the cycle began at `new-branch`.** This repo's own page has opened at
`## 1. NEW ISSUE / TASK` since August 29, 2026 ([PR #1058](https://github.com/DaveKJohn/claude-code-specialists/pull/1058)),
so for a day the document every consumer reads described a cycle starting one step later than the cycle it
describes — and the step it was missing is the one that says where the work comes from.

`CONTRIBUTING-portable.md` now opens at `### 1. New issue or task`, with `Human` and `Claude` as **kinds
rather than sub-steps** — neither precedes the other, both end in one issue in the repo the branch will be
opened in — and Branch through Fold renumbered 2 to 6, in-page back-references included. It is the only step
that names no skill, and that is stated on the page: no script runs it, which is exactly why it was the step
the page went without.

**`TICKETWORK-portable.md` is gone, folded in whole** as `## Ticket work — the layer before the branch`,
which step 1's `Human` half points at. It had been a fourth portable page for three weeks, and what retired
it was reach rather than size: the cycle document never mentioned it once, and the plugin README framed it as
an optional extra — so a reader following the cycle end to end met neither the section nor the step it
belonged to. Nothing was dropped in the move; the ten rules keep their own headings one level down, and the
framing that makes them survivable (one repo, one day, rules rather than a format) travels with them.

Its four live references follow it: the plugin README's pointer paragraph and its table row, the folder
README both copies of `adopt-workflow-folder.ps1` scaffold, and this repo's own step 1. The two archived
`4.5.0` documents that linked to the file are **de-linked rather than repointed** — the dead-link scan reads
`releases/` recursively, and an archived note should keep saying what was true on its day rather than
pointing at a page whose name it does not carry.

**Score:** 2

#### What makes this deploy extra special

**A consumer's route no longer has a hole at the front.** The cycle they read starts where their work
actually starts, and the ticket-work rules are reachable from it instead of from a page the cycle never
named. Nothing to run and nothing to migrate: no script, gate or seam changed, and a repo where nothing
arrives from an upstream tracker skips that section exactly as it skipped the page.

**Score:** 3

#### Pull Request

The portable cycle begins where the local one does, and ticketwork moves into its first step

Plugins: contributing-davekjohn

[PR #1125](https://github.com/DaveKJohn/claude-code-specialists/pull/1125)

---

