### The release docs go portable-first, with the repo-unique half in a named slot · Docs · 2026-08-04

**Both pages under `releases/` now follow the same model `CLAUDE.md` already used: portable content first,
everything repo-specific in one named slot at the end** (Dave, August 4, 2026). The reason is mirroring —
these two pages describe a workflow that is shared with every consumer, while being written as if only this
repo would ever read them, so a second repo could not take the explanation without editing the whole file.

- **`# Release history — claude-code-specialists` → `# Releases - history`**, with the version tables moved
  under a single `## claude-code-specialists`. The tables are the one part of that page that can *never* be
  copied — a release history is unique to the repo that cut it by definition — so it is the natural content
  for the slot.
- **`# Release notes — claude-code-specialists` → `# Releases - process`.** The title is the symmetric form
  rather than something Dave specified; the slot below it collects what was scattered through the page: the
  seam values in force here (`3.x` per major, `Get-ReleaseHistoryMode` at `'latest'`, hence
  `## Latest Release`), the `davekjohns-workshop` rename, the markdown-only decision, the "every release
  gets a Release" rule with its two consequences, and the four measured instances that had been standing in
  for the portable rules they illustrate.

**The neutral half no longer names the owner or asserts a seam value as a fact.** "Releases are cut only at
Dave's explicit request" became "on the repo owner's explicit request"; `<X>.x` became `<dir>`, pointing at
`Get-ReleaseNotesGrouping`; the changelog heading is described by its seam rather than as `## Latest
Release`, which is only true while this repo's mode is `'latest'`.

**Two structural rules had to be written down, because the restructure could have broken a release
silently.** `cut-release.ps1` finds the **first** release table in the history file and inserts the new row
directly after it, and the guardrail against a misfiled major reads the **last `### <n>.x` heading before
that table**. So the repo slot must stay last in the file with the current major's table first inside it,
and the `### <n>.x` shape must stay recognisable. Both are now stated in the page itself, next to the
tables they protect. Verified rather than assumed: `Get-OverviewTargetMajor` still answers `3`, and the
inserter's first match is still the `3.x` header at line 29, with a new row landing above `3.4.0`.

**One risk was introduced and then removed rather than left standing.** The first draft of the intro quoted
the table header verbatim while explaining the inserter — and the inserter matches that exact line. It could
not have fired (the regex also requires the `|---|` separator row directly beneath, which prose does not
have), but a document explaining a pattern should not be one edit away from triggering it. The header is now
described instead of quoted, with a note saying why. This is the same care that strips code spans before the
PR gate reads closing keywords.

**And it surfaced a stale error message, repaired here because this branch is what makes it wrong.** On a
new major, `cut-release.ps1` told you to *"Add the section first — directly under `## Overview`"*. That
heading had not existed since the overview moved out of `releases/README.md` into its own history page, and
naming any fixed heading is wrong on principle now: the history file is repo-owned via
`Get-ReleaseHistoryPath`, so a consumer's may be structured differently. The message now positions the new
section **relative to the `### <n>.x` heading it actually found** — the one shape the script does depend on.
