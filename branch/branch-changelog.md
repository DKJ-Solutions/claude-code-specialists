## `feat/releases-audience-root` changelog

### Branch title

The release side adopts one audience per repo, and releases/notes becomes releases/audience

### Branch ID

20260812-144745

### Branch type

feat

### What does the change on this branch bring to main?

The release side catches up with the entry side. Chunk 2 changed what an entry is *asked* and deliberately
left `CLAUDE.md`, `releases/README.md`, the `cut-release` skill and the release manager's lens describing a
cumulative ladder the code had stopped enforcing; this closes that gap and completes inbound
[#620](https://github.com/DaveKJohn/claude-code-specialists/issues/620). Tier 1 and tier 2 are now written
everywhere as two **kinds** of audience — management and the employer/commissioner, versus the subscriber of
a service — of which a repo has exactly one, fixed in `Get-ReleaseAudienceTier` before any entry is written.
The `cut-release` skill documents that seam for the first time, which matters because after chunk 2 it was
the one knob a consumer could meet without a page explaining it.

**`releases/notes/` became `releases/audience/`**, finishing a rule this repo set two days earlier and then
missed in the sibling it was renaming alongside: every root under `releases/` names its **reader** —
`development/` the developers, `github/` the Release page, `audience/` whoever the repo publishes to.
`notes/` named the *form*, which is exactly the fault `highlights/` was renamed for. `consumer/` and
`internal/` stay put as frozen archives.

**A gate would have gone blind on that rename, and the repair is the part worth keeping.** Lint check 25
named `releases\notes` as a **literal** while the root it was checking is a seam. On the day the seam moved
it would have found no live tree, held the archive alone, and printed a coverage count that still looked
healthy — a gate going quiet with nothing erroring. It reads `Get-ReleaseNoteRoot` now, walks the pre-rename
root alongside it so a repo mid-migration loses neither half, and has a fixture whose root is deliberately
**not** the default, because a test that agrees with the default cannot detect this class of bug at all.
`session-status.ps1` states the same lesson two files over about the reader-versus-writer half of this very
seam; a gate was simply the third reader nobody had counted.

**The contract record for that root flipped from `copy` to `decide`, and the trigger was its own reasoning
expiring.** Its `AdoptWhy` justified copying on the grounds that the source's answer *was* the default — true
when written, false the moment this repo renamed. Copying it now would write `releases/audience` into a
consumer whose documents sit in `releases/notes/`, and that miss reports as "no release note was found",
which reads as a repo that has never cut one. **The shared default stays `releases/notes`** in every script,
for the same reason: an unstated seam has to keep meaning what it meant yesterday.

### Significance

#### Tier 0

The constitution stops contradicting the code — the one-branch gap chunk 2 opened on purpose, and the kind
that gets read as the rule by whoever meets it next. On top of that, a gate that was one rename away from
silently checking nothing is now keyed on the seam and covered by a fixture that can actually fail.

**Score:** 4

#### Tier 2

The audience seam gets the page it was missing: a consumer meeting `Get-ReleaseAudienceTier` in their
contract report can now read what the two kinds of audience are, which one their repo is, and that answering
nothing leaves them exactly where they were. The note-root record also stops handing them this repo's
directory as though it were a convention — it asks instead, which is the difference between a knob that
adapts to their tree and one that renames it under them.

**Score:** 4

### Pull Request

