## `docs/v4-5-0-release-note` changelog

### Branch title

The v4.5.0 release note

### Branch ID

20260811-205512

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this evening: the consumer section rewritten from the
cut's draft against the seven writing tests, and the two sections no script can generate.

**The release had a theme, and naming it is most of what the document is for.** Eleven of its fifteen
changes are one defect wearing different clothes — something that named a thing which is not there. A gate
asking for a column in a format made of headings, a gate calling a written reason missing, a blueprint
describing a directory the script never writes, an overview page describing three documents where there is
one, a checklist asking for a number its own document cannot contain. None broke a build; each cost somebody
time while looking authoritative. So the organisational section states the rule the release makes explicit:
**a gate's wording is part of its correctness**, because a refusal is the only part of a tool that speaks to
somebody who is already stuck, and one that points at the wrong thing sends them to check something that
cannot be wrong — after which what they distrust is the gate rather than the message.

**The second recorded finding is about where the reports came from.** Four inbound issues close in this
release, three filed by a consuming repo, and **two could not be reproduced here at all** — this repo's own
PR template has a single section, and its own entries were already in the current shape. A source repo
cannot measure the defects that exist only downstream, which is an argument for the inbound route rather
than for local workarounds, measured three times in one release.

**Two things are written down against this release rather than smoothed over**, since a note that only
records what went well teaches nothing:

- **Step 0a was not followed.** No clock was noted before the cut, so this release has no total and it
  cannot be reconstructed. What is provable is given instead — the cut's 30 suites at 223s, the preceding
  pull request's 8m 55s of CI, and `lint-en-tests` over the last seven completed runs at a median of 8m 57s
  across 6m 11s to 13m 30s (n=7). That last figure is deliberately in the population form this same release
  added a rule about: the one-run citation would have read 8m 55s, near the median by luck, and would have
  been out by four and a half minutes had the 13m 30s run been the one in hand.
- **The GitHub Release was published before this document's pull request**, the reverse of the checklist's
  step 4 then step 5. The generated body was correct so nothing was published wrong, but the ordering exists
  to stop a Release page pointing at a draft, and for a short while it did.

Both are in the *what was still open* section, alongside #596's unbuilt structural half and the stale table
vocabulary still in `fold-changelog-entry.ps1`'s docstring.

### Significance

#### Tier 0

The record for v4.5.0 is complete, and it carries the two process failures of this cut — the missing clock
and the out-of-order publish — where the next cut will read them rather than repeat them.

**Score:** 3

#### Tier 1

The release's own lesson is written where colleagues meet it: gate wording is part of gate correctness, and
a source repo cannot see the defects that only exist downstream.

**Score:** 3

#### Tier 2

This is the document a consumer reads to decide whether to update, and this release genuinely asks two
things of them — check any refreshed pull request body, and correct one adopted comment.

**Score:** 3

### Pull Request

