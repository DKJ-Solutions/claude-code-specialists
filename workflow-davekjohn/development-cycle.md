# Development cycle: `fix/release-notes-at-the-changelogs-own-level-v1` · 20260825-122329

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

## PLAN

Issue [#881](https://github.com/DaveKJohn/claude-code-specialists/issues/881) measured it and left the
choice open: the generated developer notes sat one heading level deeper than the `CHANGELOG.md` the
entries were copied out of, because `Build-ReleaseNotes` opened each tier group with
`## Tier <n> - <audience>`. Dave chose the flat answer — the levels go back to the changelog's own and the
grouping heading goes, because *where a change reached* is a claim about attribution while this document
is the record of *what changed*.

What the exploration turned up that the report did not: the heading was **machine-read**.
`scripts/release/new-internal-note.ps1` filtered tier 0 out of the internal note by walking those
headings, and `releases/development/4.x/4.8.0.md` had recorded exactly that ("it is machine-parsed by the
internal-note generator") when it left the wording alone. So removing the heading without repairing that
reader would have carried every tier-0 entry into the one document tier 0 exists to stay out of — no
error, plausible output.

## CREATE

- [x] `Build-ReleaseNotes` renders `-TierGroups` at `-EntryLevel 2` with no group heading, and joins the
      groups with the same `---` rule it already puts between entries — a bare blank line would make the
      tier seam the one boundary in the document without a rule, which is a heading in all but name
- [x] `new-internal-note.ps1` reads each entry's OWN declaration through `Resolve-EntryImpact` — the same
      reader `Get-PullRequestEntriesByTier` groups on — and keeps the container heading as the fallback for
      an archived note whose entries pre-date the declaration, since the script takes a version and can be
      run against any release ever cut
- [x] `Get-ReleaseTierHeading` and the `Heading` field are kept and documented as unrendered: they are the
      single source of that wording, every note ever cut carries it, and removing a published field of that
      contract is a separate decision — the same answer v4.8.0 recorded for this heading
- [x] `releases/development/4.x/4.19.0.md` regenerated from the pre-cut changelog at `9983299`, not
      hand-edited: 35 entries, `tier2=24 tier0=11`, and the normalised diff against the published file is
      exactly the two tier headings gone plus one `---` at the seam
- [x] the docs that described the old shape: `RELEASES-portable.md` (the payload a consumer receives), the
      release lens, and the `cut-release.ps1` comment above the call
- [x] mirrors rebuilt with `scripts/sync/build-shared-scripts.ps1`

## TEST

- [x] `release-lib.tests.ps1` — 421 asserts. The tier-heading assertions became level assertions plus a
      rule count (two rules for three entries: one per boundary, inside a tier and between tiers alike)
- [x] `internal-note.tests.ps1` — 90 asserts, seven of them new: the flat shape with no tier heading, where
      the tier-0 entry is filtered out on its own declaration, and the all-tier-0 flat note whose warning
      still names the tier rather than reporting a parse failure. The existing tiered fixtures are
      unchanged and still pass, which is the archive still parsing
- [x] `check-plugin-integrity.ps1` — 0 errors
- [x] `cut-release-drive`, `cut-release-guardrail`, `fold-changelog`, `entry-scaffold`,
      `release-notes-page` — all green

## DEPLOY: `fix/release-notes-at-the-changelogs-own-level-v1`

**The generated developer release notes now render at `CHANGELOG.md`'s own heading levels.** Entries sit at
`##` and their sections at `###`, exactly where the fold wrote them, so an entry copied out of the record
into a hand-written note pastes at the level it was written at instead of needing a manual shift.
`Build-ReleaseNotes` no longer opens each tier group with `## Tier <n> - <audience>` — measured at `v4.19.0`
in [#881](https://github.com/DaveKJohn/claude-code-specialists/issues/881), that wrapper put all 35 entries
at `###` where their source had them at `##`, a pure one-level shift of every heading in the file. The tier
still decides the order (highest first, ranked inside a tier); it no longer prints a heading to say so,
because where a change reached is a claim about attribution and this document is the record of what changed.
Each entry states its own reach, so nothing is lost with the heading.

**The heading was machine-read, and that is the half the report did not see.** `new-internal-note.ps1`
filtered tier 0 out of the internal note by walking those `## Tier <n>` headings, with a documented
fallback — no tier headings means take everything — that would have carried all 11 tier-0 entries of a
release into the one document tier 0 exists to stay out of: no error, plausible output, a document written
for colleagues listing repo-internal housekeeping. `releases/development/4.x/4.8.0.md` had recorded this
dependency in so many words when it left the wording alone. The filter now reads each entry's **own**
declaration through `Resolve-EntryImpact` — the same reader `Get-PullRequestEntriesByTier` groups on, so
the two cannot disagree — and keeps the container heading as the fallback, because it is the only tier
information an archived note carries whose entries pre-date the declaration entirely, and this script takes
a version: it can be run against any release ever cut.

**`v4.19.0`'s own notes were regenerated rather than edited.** The 35 entries were read back out of
`CHANGELOG.md` at `9983299`, the commit before the cut, and re-rendered by the new generator; the
normalised diff against the published file is exactly the two tier headings gone plus one `---` at the
seam, and the heading profile now matches the pre-cut changelog's 35/70/7 line for line.
`Get-ReleaseTierHeading` and the `Heading` field are kept and documented as unrendered, for the reason
v4.8.0 already gave for this same heading: they are the single source of that wording, every note ever cut
carries it, and removing a published field of that contract is a decision of its own.

**Score:** 2

### What makes this PR extra special

A consumer's cut writes this document too, so the level correction and the repaired tier filter both
arrive with the plugin — including the failure the filter prevents, which a consumer would have met as
repo-internal entries appearing in the note they hand to colleagues. `RELEASES-portable.md` states the new
shape, so the page describing the document and the generator writing it agree.

**Score:** 3

### Pull Request

Developer release notes render at CHANGELOG.md's own heading levels
