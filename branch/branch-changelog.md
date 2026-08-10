## `feat/consumer-facing-document-named-for-its-reader` changelog

### Branch title

The consumer-facing release document is named for its reader

### Branch ID

20260810-145624

### Branch type

feat

### What does the change on this branch bring to main?

The tier-2 release document was called **highlights** everywhere — the directory, the seam, the
renderer, some ten documents of prose — and that name described the **form** (a selection of the nice
bits) instead of the audience. Its two neighbours name their reader, and the tier table has always said
tier 2 is "consumers", so this was the one of the three whose name disagreed with the model it belongs
to. It is `releases/consumer/` now, and the seam is `Get-ReleaseConsumerBumps`.

**The measurement that decided it.** Five dev-tool changelogs in the field were read before renaming —
Linear, Stripe, Vercel, Raycast and GitHub — and **not one publishes anything called "highlights"**. The
live names are *Changelog*, *Release notes* and *What's new*, every one of which names the document or
its reader. The same pass found the split this repo already runs: GitHub keeps a terse engineering
changelog beside readable announcements, which is `development`/`internal` beside this tier. The form-name
was also earning its keep in the wrong direction — it invites the register a self-selected best-of
invites, which is what a review of `v4.0.0`'s own document had just found it guilty of.

**The one thing that could have broken a consumer in silence is the seam, and it is read under both
names.** `Get-ReleaseConsumerBumps` is tried first and `Get-ReleaseHighlightsBumps` second, because the
fallback for an undefined seam is `@()` — the tier switched **off**. A repo still carrying the old name
would otherwise cut a minor, write no document for the very consumer it was cut for, and report success;
consumers receive this rename through a plugin update rather than by choosing to. `Get-SeamValue` takes a
list of names now, and three asserts hold the pair: both names present in the code view, the current one
**first**, and the reader accepting more than one.

**What was deliberately not renamed.** No GitHub Release body links to a `releases/highlights/…` path —
checked, not assumed — so there was no external permalink to protect and all eleven documents moved. The
**prose** in the archived `releases/development/` notes and in the already-folded `CHANGELOG.md` entries
keeps the old word: those describe what the document was called on the day they were written, which is
the same published-record rule that left seven wrong merge dates standing. Their **links** were
repointed, because a dead link in a record is worse than a relocated one and repointing one changes no
claim. `Get-ReleaseHighlightsStakeholderTypes` and `Get-ReleaseHighlightsWording` keep their names too —
they name functions that no longer exist under any name.

### Significance

#### Tier 0

Roughly ten hand-maintained documents, six scripts and six suites described this tier by a name that
contradicted the tier table two screens above them. The rename costs a developer nothing to read and
removes the question "is the highlights document the tier-2 one?" from every future pass over the
release machinery.

**Score:** 2

#### Tier 1

The reason travels further than the word: a document named after its form invites a best-of register,
and a document named after its reader invites the reader's question. That is the half a colleague can
apply to their own outward-facing writing, and it is now written down with the five-changelog measurement
behind it rather than as taste.

**Score:** 3

#### Tier 2

A consumer who overrode `Get-ReleaseHighlightsBumps` keeps working — the seam reads both names — but the
directory their release documents land in changes name, and their own repo-config should follow. The
silent-failure mode this rename could have had is exactly the class of defect the previous release was
about, so it is worth one line of their attention: check the seam name, expect `releases/consumer/`.

**Score:** 3

### Pull Request

