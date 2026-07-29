### An entry body must not use H2 — the release notes reserve that level for categories · Fix · 2026-07-29

Caught while inspecting v2.13.2 before pushing, which is exactly what `-NoPush` exists for. PR #242's
entry body used `##` sub-headings. `cut-release.ps1` puts `## Features` / `## Fixes` / `## Documentation`
/ `## Maintenance` above the entries it groups, so those two climbed out of their category and rendered as
siblings of it:

```
## Fixes
### #242 · The round-trip is honest and idempotent · Fix · 2026-07-29
## On the tests, because one of them was worthless at first    <- reads as a release category
## Filed separately                                            <- reads as a release category
```

Demoted to `####` in both generated artifacts — `releases/development/2.x/2.13.2.md` and
`specialists/CHANGELOG.md`. The root `CHANGELOG.md` needed nothing: the release had already lifted the
entry out of `## Pull Requests`.

**Why this got through, and it is a familiar shape.** The entry file reads perfectly well on its own, and
so does the `## Pull Requests` section it is folded into — there the entry sits under an `##` itself, so a
body `##` looks level-appropriate. The defect only exists once `cut-release` lifts that body into a
context with categories above it. Same blind spot as
[#234](https://github.com/DaveKJohn/davekjohns-workshop/issues/234): the artifact a reader finally sees is
assembled *after* every gate that could have judged it — there by the fold, here by the release.

Recorded in [Rendall #06's lens](.claude/plugins/claude-specialists/specialists/05-06-extension.md) beside
the entry format, with the reason it is invisible until release time and the instruction that follows
from it: **inspect the generated notes before pushing.**

The release itself was correct in substance — version, tag, lockstep, notes content — so it was pushed as
cut rather than unwound. Undoing a local release commit means `git reset --hard`, which needs Dave's
explicit permission, and a heading level does not justify asking for it when the normal branch + PR flow
fixes it in minutes.
