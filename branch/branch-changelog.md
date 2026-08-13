## `fix/cut-release-note-dir-seam` changelog

### Branch title

the release note's directory is created from its own path, not a hardcoded root

### Branch ID

20260813-083414

### Branch type

fix

### What does the change on this branch bring to main?

`cut-release.ps1` created the hand-written note's directory from a hardcoded `releases\notes\` while
writing the note itself to the path the `Get-ReleaseNoteRoot` seam names. It now derives that directory
from the note's own path, exactly as the GitHub Release body's has been derived from its own path since
the two roots came apart.

**It was not cosmetic — it would have hard-failed the first cut into a fresh major.** `Write-Utf8NoBom`
is a bare `File.WriteAllText` and creates no directories, so the line made `releases/notes/<X>.x/` while
the write below it went to `releases/audience/<X>.x/`. It worked only because `releases/audience/4.x/`
already existed from `4.0.0`–`4.6.0`. At the first cut into `5.x` the wrong directory would be created,
the write would throw `DirectoryNotFoundException`, and the cut would die **mid-run on `main`** — after
the development notes, the Release body and the `releases/README.md` row, before the version bump and
the commit. A half-written trunk, under a direct-commit exception.

**This was the same seam escaping for the third time, in a third spelling, and that is the transferable
half.** The two asserts written to guard it match the fully-qualified `releases/notes`; the overview row's
escape ([#633](https://github.com/DaveKJohn/claude-code-specialists/pull/633)) was the bare `notes/`; this
one was invisible to both because PowerShell accepts a **backslash** in a path literal. So the assert was
**widened** rather than joined by a third — it matches the separator as a character class,
`releases[\\/]notes` — and it was verified **red against the old line** before being trusted: the narrow
rule saw 1 occurrence and passed, the widened rule saw 2 with the second carrying no `-Default`. A matcher
that knows one spelling while the code uses another reads as thorough and sees nothing.

The seam's own `-Default 'releases/notes'` is untouched, and so are `new-internal-note.ps1`'s
`releases/internal/` and lint check 25's `releases\consumer` root: those describe a *consumer's*
two-document archive, not this repo's.

**One part of this change leaves no trace in the diff.** The stray `releases/notes/4.x/` the bug had been
creating at every cut since the rename is deleted, but git tracks no empty directory — so it appeared in
no commit, in no `git status` and in front of no gate, and it disappears the same way. It was found by
looking at a filesystem. `releases/` now holds the three reader-named roots and nothing else.

Plugins: workflow-davekjohn

### Significance

#### Tier 0

The next major cut does not die halfway through, on the trunk, with the release artefacts written and the
version bump not. That is the failure this prevents; it had not happened yet only because no major had
been cut since the rename. The widened assert is worth as much again — it is the third instance of one
matcher-blindness pattern, and it now reads the separator as a class instead of waiting for a fourth
spelling.

**Score:** 3

#### Tier 2

A consumer running the workflow plugin gets the same repair: the note's directory follows their
`Get-ReleaseNoteRoot` answer instead of a path built behind the seam's back. They notice nothing today,
and they would have noticed everything at their first cut into a new major.

**Score:** 3

### Pull Request

