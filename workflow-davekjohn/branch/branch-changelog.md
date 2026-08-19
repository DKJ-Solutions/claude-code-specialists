## Branch `fix/tier1-note-what-changed` changelog - 20260819-120343

### What does the change on this branch bring to main?

#### Tier 0

The one hand-written release document is drafted with a section saying **what changed**, drawn from the
repo's own audience tier instead of a hardcoded 2. In this repo the answer *is* 2, so **nothing about our
own releases moves** — verified byte-for-byte, 7834 bytes identical across all six shapes the tier-2 path
can take, including both wording overrides and the empty case.

**Two things this repair had to correct before it could be built, and both are the point.** Inbound
[#747](https://github.com/DaveKJohn/claude-code-specialists/issues/747) was right that the section is
missing and right about where the gate sits. The session that picked it up recorded the cause as
`-RankByTier 2` acting as a filter that nothing survives — and that mechanism does not exist.
`Format-RankedEntries` only **sorts** on that parameter; it drops nothing. The real hardcode was one line
in `cut-release.ps1`, selecting `Tier -eq 2` before the renderer was ever reached, which means the bug was
in the **selection** and not in the renderer the pickup was aimed at. Caught by reading the function rather
than the summary of it.

**And the report's own load-bearing premise was wrong in the other direction.** #747 proposed an *empty*
heading plus a hint, reasoning that a tier-1 repo has no generatable source for it. It has exactly the
source a tier-2 repo has — its tier-1 entries — which the grouper already returns and which render
unchanged through the same five switches. Measured by rendering a synthetic tier-1 changelog before writing
any fix. So the repair is symmetric rather than special-cased, and the section arrives **pre-filled** rather
than merely asked for. Dave chose that shape over the narrower one.

**Why no gate here could see it.** `Get-ReleaseAudienceTier` answers 2 in this repo, so every local run, every
suite and every CI job produced a correct document. The lib-level test that came closest asserted the
suppression was correct — *"no consumer section where no entry reached tier 2"* — which is true of a tier-2
repo's occasional tier-1-only minor and was silently read as universal. That assert now says which repo it is
about, and `cut-release-drive.tests.ps1` grew two scenarios that drive the real script against a fixture whose
seam answers 1, plus one that pins tier 2 as unmoved. The four new asserts were confirmed to **fail** against
the previous code and pass against this one.

**The docs said so too, which is the part worth keeping.** `RELEASES-portable.md` described the defect as
intended behaviour — *"which is every minor in a repo whose audience is tier 1"* — and the word *every* was
the tell nobody read: not an unlucky minor, all of them, because no entry in such a repo can declare tier 2
at all. The shape generalises past this bug: **a rule stated for one seam value, then read as though it held
for every value.**

Also repaired, from the same report's second finding: at tier 1 the audience line promised *"consumers of
this product, and colleagues in the organisation — one section each"* in a document that renders one reader
and two sections, so the generator shipped a promise the same function guaranteed it would not keep. The
value hint's *"not for the consumer"* went the same way — at tier 1 both sections belong to the same reader,
so that sentence denied the audience its own document.

**Score:** 3

#### Higher than tier 0?

A consuming repo that answered tier 1 gets a release note that says what shipped. Until now its outward-facing
document could be finished, attached to a GitHub Release and published while carrying only the two sections
that cannot be generated — and the failure was quiet: the draft looked complete and every gate passed. The
reporting repo had written the missing heading down as a hand step in its release aftercare; that step can go,
and it should be **deleted rather than filled in**, because the section now arrives pre-filled rather than
empty as their own proposal expected.

`SectionConsumers` and `HintConsumers` are renamed to `SectionAudience` and `HintAudience`, and **both old
names are still read** — a repo that overrode either keeps its heading through the update. It is payload, so
it reaches consumers only through a release; nothing in an existing consumer tree is edited.

**Score:** 4

### Pull Request

a tier-1 repo's release-note draft gets the section that says what changed
