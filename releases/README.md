# `releases/` — what a cut produced

This directory holds the documents a release **generated**. Nothing in it is written or edited by
hand, and nothing in it depends on a plugin being installed: these are the artefacts, and they stay
readable on their own.

| directory | one file per version | written for |
|---|---|---|
| [`development/`](development/) | `<X>.x/<X.Y.Z>.md` — the complete, raw note: every change the release carried | this repo's own developers |
| [`github/`](github/) | `<X>.x/<X.Y.Z>.md` — the body of that version's GitHub Release | whoever opens the release on GitHub |

**Each file is a published record.** It was true at the moment it was cut, and going stale afterwards
is the record working rather than a defect — so links may be repointed when a target moves, and prose
is not rewritten. The one line that may be corrected is one that was *false when it was written*; the
rule and how to mark such a correction are in
[`RELEASES-portable.md`](../plugins/workflows/workflow-davekjohn/RELEASES-portable.md#once-it-has-landed-it-is-a-published-record--and-that-protects-only-what-was-true).

**Older notes are in the language they were written in.** The repo switched to English on July 20,
2026 and history is not rewritten, so the earliest notes here are Dutch — one of the deliberate
exceptions in [`language-layers.md`](../.claude/rules/language-layers.md).

## What is not on this page

This page describes the two directories beside it and stops there. Three things live elsewhere on
purpose, so that neither page repeats the other:

- **Which releases exist** — the dated list of every version cut, with what each was worth — is the
  living index in
  [`workflow-davekjohn/releases/README.md`](../workflow-davekjohn/releases/README.md#the-release-list).
  The cut writes its own row into it.
- **The hand-written note per release**, the one document with a named section per reader, is in
  [`workflow-davekjohn/releases/audience/`](../workflow-davekjohn/releases/audience/). The generated
  notes here are its raw material, not its replacement.
- **How a release is cut** travels with the workflow plugin as
  [`RELEASES-portable.md`](../plugins/workflows/workflow-davekjohn/RELEASES-portable.md), which states
  what it covers rather than being summarised here twice; this repo's answers to it are on the page
  linked above.

That is the layering this repo uses throughout: the root page holds what is true regardless, and the
`workflow-davekjohn` layer adds what the workflow brings. Where the two disagree, the workflow page
wins — the same rule [`CONTRIBUTING.md`](../CONTRIBUTING.md) and [`CLAUDE.md`](../CLAUDE.md) state.
