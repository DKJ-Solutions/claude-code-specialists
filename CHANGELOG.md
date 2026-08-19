# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections answering what a reader arrives with. Entries written before August 16, 2026 carry
six, and are read exactly as they always were. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier, each closing with its score. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## Branch `docs/v4-14-0-release-note` changelog - 20260819-133819

### What does the change on this branch bring to main?

#### Tier 0

The hand-written document for `v4.14.0`: the eight tier-2 entries rewritten for somebody deciding whether
to update, plus the two organisational sections a script cannot generate. Three of this release's items
carry an action, so the page is ordered on that rather than on score — the tier-1 release-note repair
leads, because a tier-1 repo's published notes are missing a section and the failure was silent.

**Two entries had to be written in by hand, and the reason is a generator gap worth recording rather than
the writing.** The audience draft rendered `docs/destination-reach` and `feat/agent-shared-under-teams` as
a tier-2 heading with an **empty body**, and neither score sorted. Both were written before the entry-format
change of August 16, 2026, so they head their second section `#### Tier 2` where newer entries head it
`#### Higher than tier 0?` — and the audience renderer reads only the newer wording. The grouping is not
affected: `releases/development/4.x/4.14.0.md` files all eight under *Tier 2 - consumers* correctly, so the
record is complete and only the draft was short. Named in the release note with its measurement and
deliberately **not** repaired mid-release, since a repair reaches the next release either way.

**One carried-forward claim was wrong and is corrected rather than inherited**, which is the rule
`v4.13.0`'s own note stated and this branch is the first to test. That note recorded colleagues as being on
**4.11.0**, two releases behind. Read at the target instead — `BWJ-ecommerce/claude-plugins-bwj`, commit
`9ea8dcf`, 2026-08-16T19:40:08Z, from the published `plugin.json` files — they are on **4.13.0**, one
release behind: a publication landed the same evening the note was written and overtook it. The published
note is left as it stands, because it was true when written; this one states what is true now and says which
figure it replaces.

**The timing is the first pass only**, per the two-pass rule: 8m 35s from clock start to the pushed tag, with
the orientation pass and the cut split out and the 43-suite gate named at 364s inside it. The three legs after
this file is frozen — its own gate, CI and the merge, and the publish — follow in their own small edit once
they exist. That gate reading is itself listed as an open observation: 364s against 147s for the same 43
suites at `v4.13.0`, two single readings on different machine states, named rather than diagnosed.

**Score:** 2

#### Higher than tier 0?

It is the one document a consumer reads to decide whether to update, so it reaches every one of them through
this release's GitHub Release. Three items on the page carry an action — the tier-1 note repair, the
`/continue` → `/handover` rename for anyone coming from 4.12.x or earlier, and `Get-ReleaseHistoryPath` for
a repo that repointed it — and each says plainly what to do; every remaining item says **no action needed**
rather than leaving it to be inferred.

**Score:** 4

### Pull Request

The v4.14.0 release note

[PR #757](https://github.com/DaveKJohn/claude-code-specialists/pull/757) · merged 2026-08-19

---

