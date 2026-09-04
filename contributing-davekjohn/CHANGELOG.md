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

### DEPLOY: fix/release-note-entry-heading-level-v1 · 20260904-101415

A generated release note keeps a `DEPLOY:` heading at the H3 it was written at, under a
`## Version <X.Y.Z> (<Mon DD, YYYY>)` heading naming the release the entries landed in. It came out
an H2, so the record contradicted the changelog the entry had been copied out of -- and an entry
pasted back out of it landed a level shallower than it was written.

**The defect is a repaired one that came back through its own repair.** `#881` set these entries to
`##` because that was `CHANGELOG.md`'s entry level on August 25, 2026; on August 26 that document
gained `## [Unreleased]`, every entry moved to H3, and this renderer went on promoting them. Nothing
errored and no gate fired: the docstring above the literal and the assert below it both still stated
the repaired claim, so the suite passed against a document that had started disagreeing with its
source again. Every release from v4.11.0 on carries the demoted shape. The level is now asked for --
`Get-EntryHeadingLevel`, the one function that owns it -- so the next move of that pair carries this
document with it instead of leaving it behind.

**The H2 is what the level change needed, and the H1 pays for it.** Entries at their written level
would hang under an H1 with H2 empty, so the release occupies H2 and states its own version and date;
the H1 becomes the constant `# Changelog Releases`, mirroring `CHANGELOG.md`'s own `# Changelog`, so
the version is stated once by the heading that owns the entries rather than twice in four lines. The
date is formatted through the invariant culture: a published record must not read differently
depending on the machine that cut it, and `nl-NL` abbreviates September as `sep.` -- the assert runs
under that culture rather than trusting the flag.

**The `**Date:**` and `**Type:**` pair stays, and that is a reader rather than a preference.**
`new-internal-note.ps1` parses both labels out of this document to build the internal note, so
dropping them would silently degrade a consumer's two-document flow to `(fill in)` and a warning.

**Existing notes are untouched.** They are published records and are not rewritten, so the 60-odd
already cut keep the shape they were cut with; this changes what the next cut writes.

**Score:** 2

#### What makes this deploy extra special

N/A -- a subscriber of a service reads none of this. The document is the raw record written for this
repo's own developers, and the change is to the heading levels inside it.

**Score:** N/A

#### Pull Request

Release notes keep DEPLOY at the H3 it was written at, under a version heading

Plugins: contributing-davekjohn

[PR #1372](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1372)

---

### DEPLOY: fix/duplicate-entry-section-heading · 20260904-094044

`check-plugin-integrity.ps1`'s entry-heading check (check 13) now refuses a changelog entry whose
declared section heading appears more than once -- `#### Pull Request` written twice, say. Both copies
are valid names, so nothing errored before: the entry validated, every gate passed, and the split only
showed in a published GitHub Release body, because the fold stamps and links the last `Pull Request`
heading while the PR body and the release notes read the first. `v4.29.0`'s Release body shipped a
bullet with no PR link that way (issue #1367). The check catches it in both places it already
walks -- the branch's development document (on the PR, and in CI) and `CHANGELOG.md` below its intro
(after a fold, the one write that lands directly on `main`) -- and a heading quoted inside a code fence
is a mention, not a finding.

**Score:** 2

#### What makes this deploy extra special

N/A -- an internal lint gate. No subscriber of any service reaches it; the entry files and `CHANGELOG.md`
it guards are developer-facing.

**Score:** N/A

#### Pull Request

refuse an entry whose section heading appears more than once

[PR #1368](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1368)

---

