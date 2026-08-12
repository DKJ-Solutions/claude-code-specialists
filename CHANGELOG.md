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

## `feat/release-note-root-seam` changelog

### Branch title

The release note's root directory becomes a seam, and reaches both its readers

### Branch ID

20260812-095228

### Branch type

feat

### What does the change on this branch bring to main?

`Get-ReleaseConsumerBumps` says *whether* the hand-written release note is written. Nothing said
*where*: `cut-release.ps1` built that path from the literal `releases/notes`, while every neighbouring
path in the same file was already answered per repo — the folder component by
`Get-ReleaseNotesGrouping`, the release list by `Get-ReleaseHistoryPath`. The file already accepted that
the folder *inside* this path varies while its root did not.

That left the knob above it **unanswerable** for a repo whose hand-written notes live elsewhere: naming
the bumps would point the cut at a directory that does not exist there and leave the one that does out
of the release, so the only safe value was `@()` — the tier switched off, which is not an answer to the
question the knob asks. `Get-ReleaseNoteRoot` is that answer, defaulting to today's value, so nothing
changes for anyone who does not set it. `Get-ReleaseHistoryPath` is the precedent and carries the same
sentence: a location convention rather than a fact about the repo.

**The seam reaches both of its readers, which is the half that could have failed in silence.**
`session-status.ps1` looks for the newest note; had it kept the default, a repo that repointed the root
would have its note written to one place and looked for in the other, and the miss prints as *"no
release note was found"* — which reads like a repo that has not cut one yet. It reads the seam the way
it already reads the wording beside it: `repo-config.ps1` directly, inside the try that degrades to the
default, because that script deliberately dot-sources no library. Its scan now starts *at* the notes
root instead of walking `releases/` behind a `[\\/]notes[\\/]` filter — a filter that could not have
honoured a seam whose whole subject is the segment it matched on, and that already matched every file
in the tree whenever the checkout itself sat under a folder of that name.

The same report's smaller finding, in the same neighbourhood: of the three messages about the release
list, the two that fire on success used `$historyRelPath` and the one that fires when the file is
**missing** used the literal — so the seam failed exactly where the reader is about to go looking for
the path it names.

`releases/development/` is deliberately given no equivalent knob. The reporter could show a repo that
genuinely differs on the note root and none that differs on that one, and a seam nobody can be shown to
need is a knob every reader has to read past.

Reported from a consumer as inbound
[#616](https://github.com/DaveKJohn/claude-code-specialists/issues/616), verified against `main` before
the repair. The proposed name `Get-ReleaseConsumerNotesRoot` was not taken: since the two hand-written
documents merged there is one release note with a named section per reader, so the consumer is a
*section* of that document rather than its title, and the name follows the file's own vocabulary
(`Get-ReleaseNoteWording`, twenty lines below it).

### Significance

#### Tier 0

This repo sits on the default, so the seam itself changes nothing here. What does change is the
`releases/` scan, which stopped keying on a path segment that any checkout could carry in its own
directory name, and the missing-file warning, which stopped being the one message of three that
disagreed with the other two.

**Score:** 2

Is there a tier above this one?

#### Tier 1

The consumer tier stops being half-configurable: the knob that decides whether the document exists and
the knob that decides where it goes are answerable together now, and a test pins the writer and the
reader to the same seam — the pairing nothing else in the tree compares.

**Score:** 3

Is there a tier above this one?

#### Tier 2

A consumer could not turn the tier on at all, and wrote the reasoning for the workaround into their own
`repo-config.ps1`; that workaround is an answer now. Deliberately not scored 5, though band 5 names a
long-standing blocker that is gone: this one blocked the subset of repos that already keep their notes
somewhere else, and nobody outside that subset has anything to do.

**Score:** 4

### Pull Request

Plugins: workflow-davekjohn

[PR #618](https://github.com/DaveKJohn/claude-code-specialists/pull/618) · merged 2026-08-12

---

## `fix/new-branch-stacked-idempotency` changelog

### Branch title

new-branch decides idempotency on the owner the branch files declare

### Branch ID

20260812-091406

### Branch type

fix

### What does the change on this branch bring to main?

`new-branch.ps1` decided whether to write the two files in `branch/` with two tests that did not ask
what the comment above them said they asked. `$changelogTaken` asked only whether the entry was
**filled**; `$progressTaken` asked only whether the owner was **not the trunk**. Both are true for any
branch created off a branch whose entry has been written but not yet folded — the ordinary stacked
branch — so both files were skipped, and the skip was printed under the **new** branch's name:
`Branch files already written for 'feat/child' - nothing done.` Nothing had been written for it, and
the files still held the parent branch's entry, heading and all. The branch silently started out
claiming another change's work as its own.

One comparison replaces both tests: the branch each file **declares**, measured against the branch you
are on. `Get-BranchFileDeclaredBranch` already returned it and was already used correctly one line
further down, and its heading regex reads either file — so the trunk's reset state means write, a
rerun on this branch means keep, and a foreign owner means write and say whose file was replaced.

Where that write would be unrecoverable, it is refused instead. Replacing a committed entry costs
nothing — git holds it on the branch it belongs to — but `git checkout -b` also carries **uncommitted**
edits into the new branch, and there they exist in exactly one place. A dirty foreign file is therefore
kept and named out loud, which still repairs what was reported: the failure was the silence and the
wrong name, not the keeping.

Reported from a consumer as inbound
[#615](https://github.com/DaveKJohn/claude-code-specialists/issues/615), verified against `main` at
`569e656` before the repair. Two regression scenarios were added to
`scripts/tests/new-branch.tests.ps1` and measured against the pre-fix script: **6 of the 12 new asserts
fail on it**, and all 110 pass after.

### Significance

#### Tier 0

The stacked-branch flow is uncommon here — `main` always carries `branch/`, so branching off the trunk
is the normal move and the defect needs a stack to fire. What this buys is the removal of a failure
that reports success: if it does fire here, the first reader who could notice is whoever reads
`CHANGELOG.md` after the fold, by which point the wrong entry has been copied twice.

**Score:** 2

Is there a tier above this one?

#### Tier 1

A whole failure shape leaves the workflow scripts: a gate whose message states the opposite of what
happened. The scaffold gate downstream cannot catch it either — it sees a fully written entry and
passes, because the entry *is* fully written, just for a different change. The repair also writes down
the overwrite-versus-refuse distinction (committed work is recoverable, uncommitted work is not) in a
place the next destructive path can reuse.

**Score:** 3

Is there a tier above this one?

#### Tier 2

This is a consumer's report from a real migration, on a script consumers receive through a plugin
update rather than by choosing to. Their stacked branch is not an exotic move — it is what you do when
the trunk does not carry `branch/` yet, which is every repo mid-adoption. Before this, that branch
started out with somebody else's entry and nothing said so.

**Score:** 4

### Pull Request

Plugins: workflow-davekjohn

[PR #617](https://github.com/DaveKJohn/claude-code-specialists/pull/617) · merged 2026-08-12

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

