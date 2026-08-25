# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections. The `##` heading is the change's own — `` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `### What makes this PR extra special` for the second audience, and `### Pull Request`.
The tier numbers live in the parser rather than in any heading. That second heading said `deploy` rather
than `PR` for one day, August 23 to 24, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was. Entries written before August 23, 2026
carry that first answer under a `###` question of its own with the second nested at `####` beneath it;
entries before August 16 carry the longer set of headings that shape replaced, and every earlier shape is
read exactly as it always was. Every release ever cut is listed in
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

## DEPLOY: `fix/release-notes-at-the-changelogs-own-level-v1` · 20260825-125958

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

Plugins: workflow-davekjohn

[PR #883](https://github.com/DaveKJohn/claude-code-specialists/pull/883)

---

