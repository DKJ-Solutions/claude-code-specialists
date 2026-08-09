# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `docs/v3-10-0-release-documents` changelog

### Branch title

The v3.10.0 release documents

### Branch ID

20260809-122825

### Branch type

docs

### What does the change on this branch bring to main?

The two documents `cut-release.ps1` deliberately does not write, for the release tagged earlier today:
the **internal summary** and the **consumer-facing highlights**. They arrive via a branch and a PR
because the release commit is already tagged, and neither is one of the two changes allowed to land
directly on the trunk.

**The highlights went from 593 lines to 92, and the cutting was most of the work.** The generated draft
is the tier-2 entries copied verbatim — still in the words their authors wrote for a reviewer of this
repo, complete with branch names, scores, and the internal reasoning behind each decision. A consumer
needs none of that. What survives is what they must do, what is new, and what was repaired, in that
order: the document opens on the reinstall rather than on the feature, because a reader scanning ten
lines has to learn that their install is about to stop resolving.

**It also carries forward the trap that a mechanical rename hides.** A consumer who never enabled the
old workflow plugin gets every team back and, silently, no workflow — nothing about their session
announces it, because enabling none is a legitimate state the new session check is deliberately quiet
about. That is stated as a property of the mechanism rather than by naming which repos it applies to;
who is in that position is this project's register, not the reader's business.

**The internal summary answers a different question and is written to it.** Not what changed, but what
the organisation gets: the naming was costing a decision on every addition to this product, the
reinstall is a one-off cost that gets more expensive with every consumer added rather than less, and
the largest reduction in dependence on a developer is the one easiest to miss — five scripts that each
kept their own answer to "which plugins exist and where do their folders sit" now read one, which is
why the directory move in this same release needed no production script change at all.

Its "what was still open" section is written as a **snapshot**, per the skeleton's own warning, and
records four things: the three connected repos had not migrated, a second checkout on another machine
was still on the old ids, the pre-seam lens caveat is documented rather than repaired, and this release
is `3.10.0` rather than `4.0.0` — the rule that a major recaps ten minors met a line that had nine, the
rule won, and the next release can be the major without overruling anything.

### Significance

#### Tier 0

The release is only finished once these two exist; until then the history page points at a note that is
a skeleton. Nothing else in the repo changes.

**Score:** 2

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Yes — the internal summary is written for exactly this reader, and it is the only document in the set
that answers what the release was worth rather than what it contained.

**Score:** 3

#### Tier 2

Is this next one still relevant for a consumer of the product?

Yes, and more than usual for a release-documents branch. Every existing install stops resolving with
this release, so the highlights are not a summary anybody may skip — they are where a consumer finds
out they have to act, and the one place that warns them a straight id swap can leave them without a
workflow.

**Score:** 4

### Pull Request

[PR #542](https://github.com/DaveKJohn/claude-code-specialists/pull/542) · merged 2026-08-09

---

## `fix/pr-body-starts-at-the-answer` changelog

### Branch title

The PR body starts at what the change brings

### Branch ID

20260809-122742

### Branch type

fix

### What does the change on this branch bring to main?

A PR body now opens with the sentence that describes the change. Yesterday's cut removed the form
around the entry; this removes the entry's own front matter, which the page around the body was
already saying.

**What a reviewer met before the first substantive line**, measured on
[PR #540](https://github.com/DaveKJohn/claude-code-specialists/pull/540):

| line | why it added nothing |
|---|---|
| the **Branch title** | it **is** the PR title — `open-pr` composes `fix: <this>` from the same section and GitHub prints it above the body |
| `### Branch ID` | a creation timestamp; there is nothing a reviewer can do with it |
| `### Branch type` | the PR's **label**, and the prefix of the title one line up |

And at the bottom, an empty `### Pull Request`: the **fold** fills that section, from the merge — so in
a PR body it is a heading with nothing under it, every time, by construction.

The template's heading is therefore the entry's own question, which is what it should have been
yesterday. The reason it was not is that the wrapper sat *above* the whole dossier, so using the
question there would have printed it twice, four lines apart. Dropping the front matter is what makes
the obvious heading correct:

```markdown
## What does the change on this branch bring to main?
<!-- Filled from branch/branch-changelog.md. Opening a PR by hand? Paste that file's body here. -->
```

**`### Significance` stays, and that is a judgement rather than an oversight.** It is not front matter:
it is the author saying how far the change reaches and what it is worth to each audience, which is the
thing a reviewer is deciding about.

**`CHANGELOG.md` is untouched.** The fold still receives the dossier verbatim — branch line, ID, type
and all — which is what was chosen on August 6, 2026 and what the release documents inherit. The two
readers now differ because their readers do: a record wants provenance, a review wants the argument.

**The back-compat half is one line and it is the whole story.** `Get-PrDescription` returns `''` when
the entry has no `What does the change...` section, and `open-pr` then falls back to
`Get-EntryDescription` — today's behaviour, verbatim. A pre-dossier entry kept its description straight
under the heading, and every consumer with a branch in flight has one; they receive this script through
a plugin update rather than by choosing to. The retired section name is read too, for the same reason,
and `-RefreshBody` gained `## Changelog entry` in its fallback list so the PRs opened under yesterday's
heading stay refreshable.

**Fence-aware, and not hypothetically:** this entry quotes those headings inside a fence. A reader that
cut at the first `### Pull Request` it saw would end the description mid-entry and return something
plausible rather than failing — the worst shape, and the one this format's other readers were already
built against.

### Significance

#### Tier 0

Every PR opened here starts at the argument instead of at three restatements and a timestamp. Small per
PR, and it lands on every single one — the same reasoning as yesterday's cut, applied to what that cut
left standing.

**Score:** 3

#### Tier 1

A reviewer's first screen is now the change rather than provenance. What it prevents is the habit that
follows from a body with a preamble: scrolling past the top of it by default, which is how the
Significance sections would have stopped being read.

**Score:** 2

#### Tier 2

Consumers get the trimming through a plugin update, and their pre-dossier entries are explicitly
unaffected — the fallback keeps those PRs exactly as they were. What is worth naming is the failure it
prevents for them: a consumer who adopts the dossier form does not have to discover for themselves that
the PR body repeats its first three fields.

**Score:** 1

### Pull Request

Plugins: workflow-davekjohn

[PR #541](https://github.com/DaveKJohn/claude-code-specialists/pull/541) · merged 2026-08-09

---

