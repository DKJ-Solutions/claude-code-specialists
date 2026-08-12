## `feat/release-github-folder` changelog

### Branch title

The GitHub Release body moves out of the record folder into releases/github/

### Branch ID

20260812-131651

### Branch type

feat

### What does the change on this branch bring to main?

The generated GitHub Release body is written to `releases/github/<X>.x/<X.Y.Z>.md` instead of
`releases/development/<X>.x/<X.Y.Z>-github-body.md`, so each root under `releases/` states one thing:
`development/` is the record nobody publishes, `github/` is the generated document that is published. The
`-github-body` suffix went with the move, because the root says it and its sibling is `<X.Y.Z>.md` already.

Measured before moving anything: the three existing bodies are named in seven places and **not one of those
is a markdown link** — every reference is a path in inline code or in prose, so the move breaks no link. That
is the same check the `highlights/` rename made on August 10 before relocating eleven documents. The one
reference deliberately left alone is in `releases/development/4.x/4.3.0.md`: a published record describes
what the file was called on the day it was written.

The body's directory is now derived from the body's own path rather than rebuilt from the root and the
grouping. While it shared `releases/development/` the single `New-Item` for the notes covered it; with the
roots apart, a second hand-built path would be a second definition of where this file goes — and the first
cut into a fresh major is the only run that would find out, being the only one where the directory does not
exist yet.

No seam for the new root, deliberately. `Get-ReleaseNoteRoot`'s contract record already states the rule for
the neighbour: `releases/development/` "deliberately has no equivalent knob: nobody has been able to show a
repo that differs on it". A brand-new root has no legacy placement to accommodate either, so it stays
hardcoded until somebody differs — and then it is one function, not a migration.

### Significance

#### Tier 0

The one generated document a release publishes stops sitting inside the directory whose whole job is the
record nobody publishes, so "which file did we announce v4.5.0 with" is answered by a root rather than by a
suffix among 88 record files.

**Score:** 3

#### Tier 1

Anyone asked to produce what was announced at a given release opens one directory instead of picking a
suffixed file out of the record. Small, and that is genuinely all it reaches at this level: the move changes
nothing about what the announcement says.

**Score:** 2

#### Tier 2

A consumer receives the moved path through a plugin update rather than by choosing to, so their next cut
writes the body to a new root and the `cut-release` skill they follow names it — the command they paste
changes together with the script that generates it. Nothing to migrate: bodies already written stay where
they are. The skill's collision note now also states that the body carries the shared `<X.Y.Z>` basename yet
never enters the collision, being handed to `--notes-file` by path rather than uploaded.

**Score:** 3

### Pull Request

