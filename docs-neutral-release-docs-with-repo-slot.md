### The release docs become one page, portable-half first, with the repo-unique half in a named slot · Docs · 2026-08-04

**`releases/README.md` and `releases/HISTORY.md` are one page again — `# Releases` — restructured on the
model `CLAUDE.md` already used: portable content first, everything repo-specific in one named slot at the
end** (Dave, August 4, 2026). The driver was mirroring. These pages describe a workflow shared with every
consumer, but were written as if only this repo would ever read them, so a second repo could not take the
explanation without editing the whole file.

**The merge is the second half of one decision, not a reversal of the first.** The list lived in its own
`HISTORY.md` for a single day, on the reasoning that one page should describe the *process* and another the
*outcome*. Once the portable/repo-specific split exists, that boundary stops earning a file: the outcome
**is** repo-specific content, so it is simply the last section of the slot. Merging also removed the four
cross-references the two pages needed to introduce each other, and leaves a consumer with one file to mirror
instead of two. `Get-ReleaseHistoryPath` is therefore back at its **default**, `releases/README.md`, which is
one less seam a new repo has to set.

**The repo heading says what to do, not merely what not to do:
`## claude-code-specialists (REPLACE WHEN MIRRORING)`.** The first draft read `DO NOT COPY`, which Dave
corrected — and the correction is a real distinction rather than wording. The *structure* of that section
should travel; only its content must not. `DO NOT COPY` would tell a mirroring agent to omit the section,
and a page without it has nowhere to put its own history — the next release would then write a row into a
document that never declared where rows go. The heading is followed by a blockquote addressed directly to
such an agent: keep the shape, replace the content, do not fold any of it upward, do not delete it.

**`## The three tiers` now has a heading per tier** — `### Tier 1 - development`, `### Tier 2 - internal`,
`### Tier 3 - highlights` — plus `### Where the two hand-written tiers land` for the branch + PR route the
last two share. Lowercase names throughout, matching the directory names. Each tier now carries the fact
that belongs to it rather than to the page: tier 1 the 125,000-character limit that makes it an attachment
and never a body, tier 2 that it is *published output* whose "still open" section goes stale in place, tier 3
that the marker is a proposal.

**The repo slot got `###` subheadings of its own** — `How to mirror this page`, `Seam values in force here`,
`Local decisions`, `Measured instances behind the portable rules`, `The release list` — and the major
sections moved from `###` to `####` beneath the last of them, which is what the hierarchy actually is.

**That cosmetic-looking promotion would have switched the guardrail off in silence, so it came with a
script change.** `Get-OverviewTargetMajor` matched `^###\s+(\d+)\.x$` — exactly three hashes. At four it
finds nothing and returns `$null`, and `cut-release.ps1` refuses only when a target was **found** and
differs, so no target means **no refusal**: the next major would file a `v4.0.0` row under `#### 3.x`
without a word, in the document whose only job is saying which release is which. **The guardrail would have
been off while the page still claimed to be protected.** The pattern now accepts `#{3,4}` — deliberately a
tolerance rather than a move, because the heading level is a function of how deeply the list is nested,
which is a layout choice each repo owns. Five hashes is still refused, so the tolerance is two levels and
not "any".

**A second reader of that pattern was needed, and it removed a hardcoded `###` from the error message.**
`cut-release.ps1`'s new-major refusal printed the target heading *and* the heading to add, both at `###`. On
a page nesting one deeper, following that advice literally produced a heading the guardrail could not read —
advice that disables the check it is protecting. The new `Get-OverviewSectionHeading` reports the heading
verbatim (`#### 3.x`), and the message derives the new one from it. Both functions read **one** shared
pattern, held in a single `$script:` variable, so the level and the number cannot disagree — a hand-copied
second regex is how this repo's accumulation bugs start.

**Nine asserts pin all of it**, including the two shapes that must *not* match: `##### 5.x` (five hashes)
and `### Tier 1 - development`, which is a heading containing a number sitting directly above the list on
this very page.

**Three structural rules are stated next to the tables they protect, because the restructure could have
broken a release silently.** `cut-release.ps1` inserts a new row after the **first** release table in the
document, and the guardrail against a misfiled major reads the **last `### <n>.x` heading** above it. So the
repo slot stays last, the `<n>.x` heading text stays recognisable (its *level* may now change), and no table
may be introduced above the release tables — which is the one thing to check when adding a section anywhere
on this page. Verified rather than assumed, against the merged file: the guardrail answers `3`,
`Get-OverviewSectionHeading` answers `#### 3.x`, the inserter's first match is that section's header with a
new row landing above `3.4.0`, and the tiers table near the top is correctly skipped.

**The table header is described in prose everywhere and quoted nowhere on the page**, because the inserter
matches that exact line. An earlier draft did quote it while explaining the mechanism; it could not have
fired (the regex also requires the `|---|` row directly beneath, which prose does not have), but a document
explaining a pattern should not be one edit away from triggering it. Same care as stripping code spans before
the PR gate reads closing keywords.

**A stale error message was repaired, since this branch is what made it wrong.** On a new major,
`cut-release.ps1` said *"Add the section first — directly under `## Overview`"*. That heading stopped existing
when the overview first moved out of `releases/README.md`, and naming any fixed heading is wrong on principle
now: the history file is repo-owned via `Get-ReleaseHistoryPath`, so a consumer's may be structured
differently. The message positions the new section **relative to the `### <n>.x` heading it actually found**.

**And one test earned its design twice in one day, in opposite directions.**
`release-lib.tests.ps1`'s live-overview assertion reads the path from `Get-ReleaseHistoryPath` instead of
restating it. That survived the move *out* of `README.md` and the move back *in* without a single edit; a
hardcoded copy would have broken both times, each time by asserting against a file that no longer held the
table — passing by looking at nothing. Recorded in the test's own comment as the reason a test may not
restate a value the repo already answers.
