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

