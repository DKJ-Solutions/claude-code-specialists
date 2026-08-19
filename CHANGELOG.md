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

## Branch `docs/v4-14-0-timing-total` changelog - 20260819-135552

### What does the change on this branch bring to main?

#### Tier 0

The second timing pass on the `v4.14.0` release note: the end-to-end total, **26m 40s**, plus the four legs
the document could not see while it was being written -- its own gates, CI and the merge, the fold, and the
publish. The head it was frozen with was 8m 35s, so **68% of the release happened after the page describing
it was final**, which is what the two-pass rule exists for.

**Four releases now agree on the split, and the figures are stated so the next reader can check them rather
than trust them.** The head was 32% of the total here, 30% at `v4.13.0`, 24% at `v4.12.0` and 35% at `v4.4.0`
-- all four under a third, each taken from that release's own document. Four readings are not a distribution
and the note says so; what they support is the older claim that the tail is a property of the procedure rather
than a run of coincidences.

**This release ran six minutes longer than either of the two before it, and the note names where rather than
leaving it to be inferred.** All of it is tail: 18m 05s against roughly 14m 23s at `v4.13.0`. Two legs carry
it -- the test gate inside the cut read **364s** where `v4.13.0`'s cut read **147s** for the same 43 suites,
and CI ran **7m 27s** -- and a refused command is in there too: the first `ship-pr` was stopped by the
step-list gate over a step that named the ship chain itself. The gate was right, the step should not have been
written, and it is recorded because the same shape is available to the next person filling in a step list.

**The attachment on the GitHub Release keeps the head-only version and is deliberately not replaced**, per the
published-record rule -- an attachment is what was published when it was published. The bullet saying so is
rewritten from a promise into a statement now that the number exists, and it names this page as the current
version.

**Score:** 2

#### Higher than tier 0?

N/A -- the edit lands in the organisational half of the note, in a figure about what a release cost this repo.
A consumer's decision to update is unaffected, and the section they read is untouched.

**Score:** N/A

### Pull Request

The v4.14.0 release note gains its end-to-end total

[PR #758](https://github.com/DaveKJohn/claude-code-specialists/pull/758) · merged 2026-08-19

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

