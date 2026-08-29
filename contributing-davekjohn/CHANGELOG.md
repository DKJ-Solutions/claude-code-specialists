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

### DEPLOY: `fix/testrun-2-cut-release-and-adoption-defects-v1` · 20260829-183627

Three defects testrun 2 found in the layer a fresh consumer meets first, all of them in the release cut and
the folder adoption.

The cut no longer reads an ordinary root document as an unfolded changelog entry. Its branch-name test scans
every heading, so a single backticked word in any heading below the title declared a branch and stopped the
release -- which in a technical repo is close to unavoidable. The root scan now reads only the document's
opening heading, which is where every real entry declares itself. And when it does refuse, it names `Get-ReservedRootMd` alongside the fold,
because *"fold them first"* is the right remedy for one of the two ways that gate fires and a destructive one
for the other.

Every release document the cut generates is now free of trailing whitespace. The markdown hard break under
`**Date:**` was two trailing spaces, which fails an ordinary lint rule -- and the cut runs its gate *before*
those documents exist, so it cannot catch its own output: the failure surfaced on the next branch, on files
that branch had not written. The break is kept, spelled as the backslash CommonMark also allows.

And the `CHANGELOG.md` that `adopt-workflow-folder` scaffolds now states the heading level the fold actually
writes, composed from `Get-EntryHeadingLevel` so the sentence cannot drift from the constant again.

**Score:** 3

#### What makes this deploy extra special

A consumer cutting their first release meets two of these three on that one command: the cut refuses over a
run log or an `ADOPTION.md` and tells them to fold it -- which would paste that file into their changelog and
delete it -- and once past that, their trunk fails its own lint gate on files the release wrote, at the one
moment the tree is least inspectable. Both were measured on a real first release, and the third quietly
misinforms every consumer about the shape of their own changelog.

**Score:** 4

#### Pull Request

cut-release stops misreading an ordinary root doc, stops leaving the trunk red, and the adopted CHANGELOG intro states the level the fold writes

Plugins: contributing-davekjohn

[PR #1102](https://github.com/DaveKJohn/claude-code-specialists/pull/1102)

---

