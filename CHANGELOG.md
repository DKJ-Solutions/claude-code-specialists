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

## `docs/v4-0-0-release-documents` changelog

### Branch title

The v4.0.0 release documents

### Branch ID

20260809-202557

### Branch type

docs

### What does the change on this branch bring to main?

The two documents `cut-release.ps1` deliberately does not write, for the major tagged earlier today: the
**internal summary** and the **consumer-facing highlights**. They arrive via a branch and a PR because the
release commit is already tagged, and neither is one of the two changes allowed to land directly on the
trunk.

**A major is a recap, so the milestone block was the first thing written and it went into the development
notes rather than here.** `v4.0.0` closes chapter 3 — twenty-one releases and fifty-one pull requests
between `v3.0.0` and `v3.10.0` — and `-SummaryFile` is the parameter that exists for exactly that: a
`-Title` is one sentence and the entries are per-PR, so neither can carry the arc. The recap was authored
against the release register and the chapter's own highlights rather than from memory, and it names the
thing a reader of a major most needs and is least likely to be told: chapter 3 shipped **two** silent
breakages — the marketplace rename in `v3.2.0` and the plugin-id rename in `v3.10.0` — neither of which
produces an error message.

**The highlights went from 319 lines to 87, and the cutting was not the work.** The generated draft is the
nine tier-2 entries verbatim, still in the words their authors wrote for someone reviewing a diff. What a
consumer needs from a `v4.0.0` page is almost the inverse of what those entries say: this release asks
nothing of them, so the page leads with that, and then spends its length on the question the version number
actually raises — *where are you updating from?* Three sections at the bottom route a reader to `v3.2.0`,
`v3.8.0` or `v3.10.0` by the state they are actually in, because those are the releases that do require an
action and none of them announces itself.

**The internal note is the published Release body, which is why its "what was still open" section is
written as a snapshot.** That is the section this repo has already measured going stale in hours rather
than months — once by a line stating that the previous release had no public page, published by the very
act it was describing. It says what was open *at the cut* and names nothing that the publish step itself
resolves.

**Two commits landed directly on `main` ahead of the cut, and they are named here rather than left in the
log.** `cut-release.ps1` refuses to file a `v4.0.0` row under a `3.x` heading and deliberately does not
open a new major's section itself; opening it then turned the live-document assert in
`release-lib.tests.ps1` red, by that assert's own instruction to be updated whenever a major section is
opened. The two halves are one fact written twice, and a cut is the one moment they may disagree — so both
were committed as release preparation, in the same spirit as the release commit they exist to enable.

### Significance

#### Tier 0

Neither document can be regenerated: the internal note is the one tier with no source to rebuild it from,
and the highlights draft is overwritten by any re-run of the cut. Writing them the same day is what keeps
the release record complete rather than "to be filled in".

**Score:** 2

#### Tier 1

This is the tier that reads the internal note, and on a major it is the one asking what ten days of work
added up to. It answers that with the chapter's arc rather than with the eleven entries that happen to
have been pending on the day the version was bumped.

**Score:** 3

#### Tier 2

The highlights are the consumer's page for a major, and the version number is what makes them open it.
The routing sections are the substance: a reader arriving at `v4.0.0` from before `v3.10.0` or `v3.2.0`
has a broken install and no error message telling them so, and this is the page where they find that out.

**Score:** 4

[PR #552](https://github.com/DaveKJohn/claude-code-specialists/pull/552) · merged 2026-08-09

---

