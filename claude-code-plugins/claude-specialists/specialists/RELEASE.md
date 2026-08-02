# Release v3.1.1

**Date:** 2026-08-02  
**Type:** Patch

The v11 follow-up: the gates see what they claim to see

You are on this release.

## Features

### #369 · The fold can commit itself, within the scope the exception allows · Feat · 2026-08-02

`fold-changelog-entry.ps1` folded the entry and removed it, and then stopped — the commit around it was
typed by hand every time, four times in the session that prompted this. That is the house's own
"noticed once, automated the second time" trigger, and it is also the step where a mistake is least
visible: the fold itself is proved by the lint gate, while the commit is retyped from memory.

`-Commit` now makes that commit and `-Push` (which implies it) pushes. **Both are opt-in and the default
is unchanged**, deliberately: this commit lands directly on `main` under one of the two named exceptions
to "never commit directly", so it has to be asked for — the same reasoning that makes `teardown.ps1`
require `-Apply`.

**The scope limit is now enforced by git rather than intended by the operator.** The commit names
`CHANGELOG.md` and the folded entry files as its pathspec, so anything else modified — or already
staged, which a plain `git commit` would sweep in — cannot land in it. That property is exactly what the
direct-on-`main` exception was granted for, and it is covered by a test that stages an unrelated file
before the fold runs and asserts it stays out.

`-Push` is separate from `-Commit` for a reason of the same family: a fold commit sitting unpushed on
`main` looks folded locally and unfolded to everybody else, which is the silent half-state this repo
keeps rediscovering the expensive way.

**One bug found by the tests before it reached anyone.** Naming an untracked path makes `git commit`
fail on the pathspec — and by then the fold has already deleted the entry file, so the run would end
with the changelog updated, the entry gone, and nothing committed. The normal flow never reaches it,
because the entry arrives on `main` with the merge and is therefore tracked; it would have waited for
the first person to fold an entry they had never committed. The commit now takes its entry paths from
the git index and says out loud which files it left out.

[PR #369](https://github.com/DaveKJohn/davekjohns-workshop/pull/369)

## Fixes

### #368 · The mojibake gate peels by the inverse operation, not by a table of known sequences · Fix · 2026-08-02

Found while measuring the surface for a different gate: `check-plugin-integrity.ps1` reported
`[mojibake] ... No findings` over files that held **517 doubly-encoded runs** — 315 em dashes, 43
arrows, 10 ellipses, 4 en dashes. Three of the four damaged files sat inside the check's own stated
scope, and the damage had ridden into `v3.1.0`: the root `CHANGELOG.md`, the specialists
`CHANGELOG.md`, its **consumer-facing** `RELEASE.md` card, and the 3.1.0 release notes.

**Why the gate could not see it.** `fix-mojibake.ps1` worked off a hand-written table of known
sequences, and the gate is deliberately nothing more than that tool run as a child process — one source
for "what does damage look like". The table carries the single-layer form of these four characters and
exactly one outer-layer peel rule, added when double encoding first bit. Damage double-encoded in any
*other* character matches no rule at all, so the fixpoint loop exits on its first pass with nothing
found. Shared source, shared blindness: the property that keeps repair and detection in step also kept
them wrong together.

**The repair is the method, not four more rows.** Mojibake is one specific operation — UTF-8 bytes
decoded as Windows-1252 — so its inverse is equally specific. Each run of non-ASCII text is now
re-encoded to Windows-1252 and decoded as UTF-8, repeatedly, for as long as the result gets shorter.
That repairs any character rather than the seventeen somebody wrote down. Both encoders are **strict**:
with the default fallbacks an unrepresentable character silently becomes `?` and invalid bytes become
`U+FFFD`, which would turn a repair tool into a corruption tool; strict, the round trip simply fails on
text that was never mojibake, and failure means leave it alone. Verified before adoption rather than
assumed — a correct em dash, arrow, middot, e-acute, a two-character run of u-diaeresis and an emoji all
survive untouched, while the eight-character double-encoded em dash peels to three characters and then
to `—`. The table stays as a net under the round trip for runs it cannot reach.

**Two reporting repairs alongside it.** The archived notes under `releases/` were outside the tool's
path list and held the largest single concentration of damage (474 sequences in `3.1.0.md`); they are in
scope now, because "history is not rewritten" protects what a note *said*, not a mis-decode nobody wrote.
And the coverage line said `checked 1` — the number of tool invocations, which is true of every possible
scope and therefore evidence of none. It now reports the file count the tool states (186) and names
`releases/` in its scope.

All 517 sequences repaired, confirmed by a detector written independently of the tool rather than by the
tool's own verdict.

[PR #368](https://github.com/DaveKJohn/davekjohns-workshop/pull/368)

---

### #365 · The kept count matches its markers, and the hook stub cannot be copied by accident · Fix · 2026-08-02

Two findings from test round v11, both in the reporting layer rather than in what the scripts do.

**`specialists-teardown` summarised itself as `0 kept` while printing two `[KEEP]` lines** (inbound
#356). The scaffold-prose loop added in #331 printed its own marker straight to the host and never
touched the `$kept` tally, so a run on the fresh-consumer row — a repo with no `CLAUDE.md` before
adoption — printed two `[KEEP]` markers, a `[note]` saying "2 line(s)", and a summary contradicting
both. The figure a reader skims to was the one that said nothing was left behind, which is precisely
the failure #331 was filed about, occurring inside the repair for it. Every `[KEEP]` marker now goes
through one `Add-Kept` door, so the markers and the number cannot drift apart — the same "one list,
one number" lesson #275 established for the remove side, applied to the half it did not reach. The
kept items carry which remedy applies to them and the summary groups by it: the `-EmptyLensPattern`
escape hatch is true of a file whose shape the script did not recognise and false of a prose line in
a governance file, so one blanket paragraph over both would have to be wrong for one of them.

**`settings.suggested.jsonc` invited copying a hook that points at nothing** (inbound #363). The
bootstrap proposes a `Stop` hook running `scripts/maintenance/lint-changed-hook.ps1`, a file it does
not create and nothing else ships. The proposal file did already say twice that its hooks are a stub
— so the gap was not the missing warning the issue reports, but where that warning is not: the
console's step 3 says "copy desired parts" with no exception named, and that console line is the
instruction a reader acts on. The path is now visibly a placeholder (`<your-check>.ps1`) rather than
a plausible-looking real one, and step 3 states which block is ready to use and which is not. Same
step also gave the file a trailing newline, which it never had — the `#337.2` warning names
`CLAUDE.md` for that and does not cover this file, so nothing pointed at it.

Regression covered on the v11 fixture itself, in both preview and apply mode, as the invariant
(every printed marker is counted) rather than against a literal count — a hardcoded expectation
could pass while both sides carried the same error, which is the failure the test exists to catch.

[PR #365](https://github.com/DaveKJohn/davekjohns-workshop/pull/365)

---

Full workshop notes: [releases/development/3.x/3.1.1.md](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/releases/development/3.x/3.1.1.md)
Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)
