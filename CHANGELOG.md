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
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`contributing-davekjohn/CONTRIBUTING.md`](contributing-davekjohn/CONTRIBUTING.md).

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

### DEPLOY: `fix/fold-legacy-entry-level-v1` · 20260827-104841

The fold brought a legacy entry to the current heading level by rewriting its first line, and it found that
line with a range derived from today's level -- `#{level,level+1}`, which has read as H3-or-H4 since the
entry level moved to 3 on August 26, 2026. H4 is a level no entry has ever opened with, and H2 -- what
every entry written in the flat window (August 5-26, 2026) carries -- fell outside it, so such an entry
folded unpromoted and landed as a sibling of `## [Unreleased]` rather than a child of it. Widening the
range would have made it worse: a flat-window entry has H3 sections under its H2 heading, so lifting the
heading alone leaves entry and sections at one level and `Split-EntryBlocks` reads one entry as four.

It now calls `Set-EntryHeadingLevel`, which measures the block's own level and shifts every non-fenced
heading by that delta -- the repair the release renderers got on August 5, 2026 for the identical reason.
That function moved down from `scripts/lib/release-lib.ps1` into
`scripts/lib/entry-scaffold-lib.ps1`, where the entry format is defined and the fold can reach it, because
the fold's dependencies were narrowed to the small libs on purpose. Its inline level walk became
`Get-EntryBlockHeadingLevel`, so the shift and the fold's report of it read the level once.

Filed as inbound [#953](https://github.com/DaveKJohn/claude-code-specialists/issues/953), measured in a
consumer. Both halves are now regression-tested against a fixture in the shape a consumer actually
carries -- the suite had none, because the one legacy fixture it did have was itself rewritten to derive
from today's level and models a block with no sections to move.

For the maintainers of this repo, the same defect class ends in two places at once: one re-leveller in the
system instead of two answers to one question, and a test fixture that no longer masks the bug it exists
to catch. The fold is this repo's own release machinery, and an entry that stops being an entry boundary is
the failure shape this repo keeps paying for -- the cut leaves it out of every release document after the
entry file has already been deleted.

**Score:** 4

#### What makes this deploy extra special

A consumer who folds a pending entry written before their v4.20.0 update meets this on their next merge:
the entry lands as a stray sibling of `## [Unreleased]` and has to be repaired by hand, which is exactly
what happened in `djcylow-react`. Nothing to migrate and nothing to act on -- the repair arrives with the
plugin -- but it is noticed the moment they touch a fold with a legacy entry pending.

**Score:** 3

#### Pull Request

The fold re-levels a legacy entry whole, so its sections move with its heading

Plugins: contributing-davekjohn

[PR #961](https://github.com/DaveKJohn/claude-code-specialists/pull/961)

---

