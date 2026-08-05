### The merge date is added by the fold, at the bottom, instead of scaffolded into the heading · Feat

Tier: 2

**This entry's own heading is the specimen: it carries no date.** The scaffolder used to write one, and
it ran when the *branch* was created — so what it recorded was the branch's birth date, not the landing
date. A branch opened on Monday and merged on Thursday was filed as Monday's work, silently, in the one
document whose whole subject is when things happened. Dave, August 5, 2026.

**The date is now the fold's, and it goes at the bottom** — his second call, and the better one. The
heading was mixing two kinds of fact: the author knows the title and the type, while the PR number and
the merge date do not exist until the merge. That second kind already had a home at the end of the entry,
on the `[PR #NN](url)` line. So the two facts the fold owns now sit together:

```text
### #NNN · Short strong title · Feat

…the description…

[PR #NNN](https://github.com/DaveKJohn/claude-code-specialists/pull/NNN) · merged 2026-08-05
```

**It reads the PR's own `mergedAt`, not the clock**, and that distinction is not theoretical here. The
fold usually runs seconds after the merge, but this repo has measured it not doing so: unfolded entry
files were once found sitting in the repo root the morning *after* their merge — the silent half-state
that put `git status` into Chris's stand-verification rule. A clock reading would have dated those a day
late with nothing in the output to say so. `mergedAt` costs nothing: the fold already makes exactly one
`gh pr list` call, and gh returns whatever fields are asked for in one roundtrip.

**The dangerous half of this change was not the date at all.** `Format-CategorizedEntries` read each
entry's branch type as the **second-to-last** middot field of its heading — correct only because a date
happened to follow the type. Removing the date would have made that read return the type's neighbour, and
every entry in every release document would have landed in the `Other` catch-all: no error, no empty
output, one meaningless heading where the categories used to be. Found by reading the code before
touching it, not by a failing test. Both heading parses are now **content-based** rather than positional
— the type is recognised by matching the known branch types, the date by its shape — so the same code
path reads a dated heading and a dateless one. That is also why nothing had to be migrated: this repo's
entire history keeps parsing.

**`Convert-EntryHeadingToTitle` needed the same treatment and taught the sharper lesson.** The first
implementation walked in from the end eating anything that looked administrative, and a newly written
assert caught it on `### #12 · Fix · Fix` — an entry whose title *is* a type name. It ate both fields and
gave up. The tail has a grammar (at most one date, and before it at most one type), so it is matched
rather than walked; two types in a row cannot both be the type, which the grammar states and a greedy
loop cannot. `Other` is deliberately not treated as a type: it is the catch-all label this repo prints,
never a value a branch table produces.

**The closing line became `Format-EntryFoldFooter` in the entry-format lib, and the reason is testability
rather than tidiness.** The fold drives a live remote, so its own suite deliberately runs without a PR —
which would have left the only path this line has untested. Extracting the pure part is the same move,
for the same reason, as `Get-ExistingPrRecord` in `pr-issues-lib.ps1`. Its five asserts cover the normal
case, the PR timestamp beating the fallback, a fold that runs a day late, a PR with no timestamp yet, and
an unparseable one degrading instead of throwing — because a completed fold must not read as failed over
a cosmetic line.

**Four asserts in the branch suite got stricter rather than looser.** They pinned `· Feat ·` — a trailing
middot that only existed because a date followed. They now compare the whole heading line, which proves
both that the type is there and that nothing follows it; the malicious-title scenario in particular gains
from that, since a prefix match would have passed even if a broken argv boundary had appended something.
Plus one new assert stating the point outright: the scaffold writes no date.

**One cost, stated rather than smoothed over.** `CHANGELOG.md` can no longer be scanned for dates from the
headings alone — you read an entry's last line. That is acceptable because the tier sections only ever
hold what is pending since the last release, a window of days in which the dates sit close together. The
release notes, where the history actually lives, keep the line per entry.
