## The fold guards the trailing newline before it inserts

### What does this change do?

`fold-changelog-entry.ps1` normalises `CHANGELOG.md`'s tail — exactly one blank line at the end, whatever it
ended with — before it measures anything in the document. One line, and it replaces the `TrimEnd()` that used
to sit in the *nothing-pending* branch only.

**The defect it closes loses a merged entry, silently.** `Get-ImpactInsertOffset` returns the slice's
**length** for the lowest-ranked entry — the common case, since tier 0 sinks to the bottom of the list — so
the insert lands at the very end of the content. On a document ending in `---` with nothing after it, that
produces `---## <title>` on one line. `^## ` stops matching, so `Split-Changelog` never sees the entry, the
cut leaves it out of every release document, and the entry **file** has already been deleted by then. The
markdown stays well-formed, the fold reports success, and one merged change is gone.

**The condition turned up in a working tree, and the record holds no trace of it — which is the point.** The
branch behind [PR #486](https://github.com/DaveKJohn/claude-code-specialists/pull/486) was handed over with
`CHANGELOG.md`'s final newline stripped by an editor, and it was repaired in the pre-commit diff review. So
the commit, the PR and the fold that followed all ran on a well-formed document: `git log` shows nothing,
no gate ever met it, and there is no PR review comment to point at. That is the honest shape of this — the
**condition** is ordinary editing and has happened once, the **loss** is what the guard prevents, and what
proves the loss follows from the condition is the test below rather than an incident.

Behind it, the two insertion paths had drifted apart: the one that runs when nothing is pending ensured the
line break and explained at length why it had to, while the one that runs on every other fold assumed it.

**The regression test asserts the defect shape rather than the repair.** It seeds a tier-1 entry so the new
tier-0 one sinks past it to the end of the list — two equal-ranked entries would exercise the
insert-*before*-a-heading path and never reach the end at all — strips the trailing newline, and then counts
entry headings. Verified in both directions: with the guard removed the appended entry is invisible to
`^## ` and three of the assertions fail. The other two are **labelled as invariants**, because they pass
either way — the fold succeeds on both sides of the bug, so an exit code cannot see it, and an assertion
that cannot fail must not be read as coverage. A second case holds the normalisation to being one, capping
an accumulated run of blank lines rather than pushing it up the document, which is the same accumulation
`Split-Changelog` already strips from the head.

The plugin mirror is regenerated, so consumers get the guard with the next release.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 2 | the shared fold script travels to every consumer; theirs could swallow an entry the same way, and nothing in the run would say so |
| 1 | 3 | a merged change can no longer vanish from the release documents while the fold reports success — and the condition it needs turned up once already, in ordinary editing on the preceding branch |

### Type of change

Fix
