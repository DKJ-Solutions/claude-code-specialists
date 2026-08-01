### The changelog separators are restored, and mojibake cannot pass a gate · Fix · 2026-08-01

**My own defect, caught by `-NoPush` minutes before it would have shipped.** Demoting four headings in
`CHANGELOG.md` (the previous PR) was done with `Get-Content` + `WriteAllLines`. Windows PowerShell 5.1's
`Get-Content` reads a BOM-less UTF-8 file as ANSI, so a middot (U+00B7, bytes `C2 B7`) comes back as two
characters, and writing that back as UTF-8 stores the mangled pair. **Nothing errors** — the file stays
valid UTF-8 and simply says something else. Three round trips (the demotion, then twice while proving the
new heading gate) turned 35 separators into 105 double-encoded sequences.

**It was not cosmetic, and that is the whole point.** The middot **is** the field delimiter in an entry
heading (`### #NN · title · type · date`), so `cut-release.ps1` could no longer read the entry **type**:
eleven entries landed under a catch-all category instead of `## Features` / `## Fixes` /
`## Documentation`. The release was cut locally, the generated notes were inspected, the missing categories
were the tell, and the whole thing was rolled back before any push. `-NoPush` exists for exactly this and
earned its keep.

**Third repo to meet this class** — smartwatchbanden → life-hub → here — and life-hub's own tool documents a
`v2.1.0` release that needed a manual fix for the same reason. So the repair tool is **ported** rather than
reinvented, with its two load-bearing properties intact:

- **The table repeats to a fixpoint.** Text can have been through the mangle twice; one pass peels the outer
  layer and leaves a remainder that matches no rule, which is precisely what cost life-hub that manual fix.
  Termination is guaranteed — every replacement makes the text strictly shorter.
- **The source is pure ASCII**, every non-ASCII character built from codepoints. A mojibake table written in
  literal mangled characters corrupts on the first careless edit and then silently repairs nothing. The test
  suite follows the same discipline for the same reason.

**Check 14 gates it**, consulting the repair tool's own table via `-Check` rather than restating what damage
looks like — one source, so a sequence added to the repair cannot be invisible to the gate. Scope: the root
docs plus every per-plugin `CHANGELOG.md` and `RELEASE.md`, because `cut-release.ps1` copies entry text into
those on the next release, so damage in the root propagates.

**A pre-existing gate caught my first attempt at the gate**, which is worth recording as its own small
lesson. The check originally ran the tool with a bare `2>&1`; `shared-scripts.tests.ps1`'s
native-stderr guard failed the build and named the file and line. Under `ErrorActionPreference = Stop` a
native command's stderr line becomes a terminating `NativeCommandError` before the exit code is read (the
#107 pitfall) — so the gate would have died on the tool's own output instead of reporting it. It now goes
through `Invoke-NativeCapture` like every other native call in this repo.

#### Tested

`scripts/tests/fix-mojibake.tests.ps1` is new — 20 asserts, and they pin the properties rather than the
presence: a single mangled separator repaired; **double** damage needing the fixpoint loop (the assert that
fails if the loop is ever flattened to one pass); idempotence, byte-for-byte, on a second run; correctly
encoded text left untouched, because this tool may only repair and never invent; a mangled em dash repaired
too, so the table is not middot-only; a BOM preserved and its absence preserved; `-Check` changing nothing
and exiting 1 with the marker the lint reads; and the lint's own category running on the real repo.

The damage itself was verified gone in both directions — reintroduced on purpose, gate named it with the
count and the consequence; repaired, gate silent; run again, nothing changed.

Plugins: specialists
