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

## `feat/lock-and-continue` changelog

### Branch title

Two commands to fix the next topic across a cleared session: /lock and /continue

### Branch ID

20260811-213120

### Branch type

feat

### What does the change on this branch bring to main?

Clearing the context throws away exactly one thing the repo cannot reconstruct: **which subject was
agreed as next.** Everything else — the tree, the branch, parked work, open issues, pending entries, the
last release's open items — is still a fact the repo holds. So two skills split the problem by who owns
which half, over one shared reporter:

| | | |
|---|---|---|
| **`/lock`** | writes `.claude/handover.md` | a **decision**: not derivable from the tree, because a priority is a judgement about what matters rather than a fact about what is true |
| `/clear` | Claude Code's own | a skill cannot run it, which is why this is two commands and not one |
| **`/continue`** | reads the lock **and** re-reads the repo | the **authority**: a lock that has been overtaken shows up as a disagreement instead of being followed off a cliff |

`scripts/task/session-status.ps1` is the reporter both run — shared and mirrored, so a consumer gets it
rather than rebuilding it. It prints the locked topic first (verbatim, with its age), then the branch and
tree, recent commits, parked branches on `origin`, open issues, pending entries with their tiers, the
last tag, and the previous release note's *still open* section.

**THE LOCK IS RECORDED INTENT, NOT A REFUSAL**, and that sentence is load-bearing in both skill pages
rather than decorative. Nothing enforces the lock and nothing should: without that written down, the
obvious next repair is to make `/continue` obey it without re-reading, which reintroduces the failure
this repo has already measured from the other direction — a self-verifying start prompt that arrived
three times identically truncated, breaking off mid-word, with nothing in the visible list announcing
what was missing. A handover is a pointer; the repo is the inventory.

**Deliberately a reporter and nothing else.** It reads; it never writes, commits, pushes or edits, which
is what makes both commands safe on a dirty tree mid-branch — asserted, because both pages promise it.
It also **dot-sources no library and needs no seam function**, so a repo that has adopted none of this
workflow still gets a useful answer; every optional source (`gh`, tags, `CHANGELOG.md`,
`releases/notes/`) degrades to a stated line rather than an error. An absent source is *said* rather than
skipped, since a blank where a block should be reads as "nothing to report" — a different claim from
"this could not be read".

**A bug found by running it once, and it is the one this repo has a whole lint check about.** The first
run printed the previous release note's em dashes as mojibake: PowerShell 5.1's `Get-Content` reads a
**BOM-less** file in the system ANSI codepage, and this repo's markdown is BOM-less by convention. Every
markdown read here now names `-Encoding UTF8`, and the regression is pinned — the fixture's em dash is
built from its code point so the test stays pure ASCII while the file on disk carries a real multi-byte
character. The first draft of that assert typed the *mangled* form literally and broke its own parser,
which is the same mistake one layer up.

**`/lock` is deliberately not `/propose`, `/hold` or `/pin`.** `hold` collides with the existing `park`
skill and with "on hold", which means the opposite of what the command does. `propose` says nothing about
persistence, which is the entire point, and invites re-proposing — the behaviour `/continue` must not
have. `pin` was the close runner-up; `lock` won on which flaw is cheaper to fix: a word's baggage
(implying prevention) is correctable in one written sentence, a word's weakness (a marker is easy to
ignore) is not.

Registration, so it actually reaches a consumer: the shared-scripts registry (24 pairs now, with
`-StoreOverride` declared exempt as a test-only fixture path), both `skills:all` spans in the README, and
a new 24-assert suite. `.claude/handover.md` is gitignored — one developer's working intent, stale within
hours, and all three steps run on one machine within minutes, so committing it would mean a pull request
per session close.

**Two skills naming one script is new here**, and the registry's `Skill` field stays a single string
because it answers *"which page documents this script's surface"*, not *"who calls it"*.

### Significance

#### Tier 0

The most-used prompt in this repo stops being retyped from memory, and the session-start verification
ritual that Chris's lens spells out by hand is now one command that cannot forget a block. It found an
open issue on its first run that the previous close-out had missed.

**Score:** 4

#### Tier 1

A colleague picking up this repo after a clear gets the standing and the agreed subject together, with
the disagreement between them stated rather than left to be noticed.

**Score:** 3

#### Tier 2

Two new opt-in commands and the reporter behind them travel in `workflow-davekjohn`, and the reporter
works in a repo that has adopted none of the rest of the workflow.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #614](https://github.com/DaveKJohn/claude-code-specialists/pull/614) · merged 2026-08-11

---

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

[PR #613](https://github.com/DaveKJohn/claude-code-specialists/pull/613) · merged 2026-08-11

---

