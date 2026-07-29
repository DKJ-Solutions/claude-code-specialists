# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #245 · The release notes parser skips fenced code blocks · Fix · 2026-07-29

Caught by `-NoPush` while cutting v2.13.3, which reported **3 entries from 2 PRs**. The cause: PR #243's
entry body quoted a broken heading structure inside a fenced block — including a `### #242 ...` line — and
`Get-PullRequestEntries` split on it. The generated notes came out with a phantom `#242` entry, `## Fixes`
twice, and the fence torn open so the quoted `##` lines rendered as real headings. Precisely the defect
#243 had just fixed, reproduced by the generator itself.

Two fence-blind tests in one loop, and a third above it:

- `^###\s` started a new entry, inside a fence or not.
- `^---$` was skipped **anywhere**, so a YAML frontmatter example in a quoted block would lose everything
  after its separator.
- The intro/entries boundary scan had the same blindness, which would put that boundary inside a code
  block.

All three now consult **`Get-FencedLineFlags`**, a new pure helper returning one flag per line. It reports
the fence markers themselves as fenced, so a caller that skips fenced lines keeps the markers with their
content instead of stripping them and leaving the body rendered as prose. An unclosed fence leaves the tail
flagged — the safe direction, since it stops the parser inventing structure out of code.

**Fourth instance of one defect class in a single day:** a matcher satisfied by a *mention* rather than a
use. The roster check counted an `@`-import path as a roster row (#227); the lint gate read a marker quoted
in changelog prose as a real enumeration (#235); the teardown read a docstring explaining placeholders as a
placeholder (#242); and this read quoted markdown as structure. Worth noting the shape it took here: the
pre-check written to hunt for stray `##` headings *also* lacked fence awareness and produced a false
positive on the same file — which is how the real bug surfaced.

Also fixed while binding it: a `Mandatory [string[]]` parameter rejects an empty string outright
(`ParameterArgumentValidationError`), and a changelog section can legitimately be a single empty line.

**16 new assertions, verified to fail without the fix** — the flag helper in isolation (including the
unclosed-fence and empty-line cases) and the parser against a sample that quotes both a heading and a
separator inside a fence, asserting two entries rather than three, the quote *kept* in the body, and the
fence intact.

The v2.13.3 release commit that exposed this was local and unpushed; Dave gave explicit permission to undo
it with `git reset --hard`, so nothing broken shipped and the release is re-cut on top of this fix.

[PR #245](https://github.com/DaveKJohn/davekjohns-workshop/pull/245)

---

### #244 · The round-trip verification protocol lives with the skill, and does not trust git · Docs · 2026-07-29

Addresses item 2 of [#241](https://github.com/DaveKJohn/davekjohns-workshop/issues/241). The first real
round-trip test was verified with `git status` / `git diff`, and that method was **partly blind**: the
consumer ignores `.claude/*`, so `settings.suggested.jsonc` never appeared in `git status` and
`git checkout .` did not clean it up. Since `.claude/` holds most of what the bootstrap writes, git can
miss the bulk of a teardown's effect.

The protocol now lives in the teardown's own `SKILL.md`, where an operator actually looks, rather than in
a prompt that exists once and is then lost:

- **Take a filesystem inventory per stage** — lens count, import count, both script scaffolds, the
  settings proposal — instead of trusting `git diff --stat`.
- **Run the cycle twice.** One pass cannot distinguish "does not accumulate" from "accumulates once", and
  accumulation is exactly what the first round found (1 → 2 → 3, with every hook reporting "in sync").
- **Count lone LFs in `CLAUDE.md`.** The other defect no gate saw.
- **Declare your own empty-lens convention** with `-EmptyLensPattern`, or the report keeps files it cannot
  recognise.

**The sharper warning is recorded with it:** in a repo that ignores `.claude/`, git cannot *restore* a
wrongly deleted lens either. So establish whether `.claude/` is tracked **before** running with `-Apply`,
not after. That is a materially different safety story from the one the skill was written under, and it
was only visible because the test ran somewhere real.

Item 1 of #241 (the teardown noting its own unmeasurability) and item 3 (whether the proposal file should
live outside `.claude/` at all) stay open there.

Plugins: specialists

[PR #244](https://github.com/DaveKJohn/davekjohns-workshop/pull/244)

---

### #243 · An entry body must not use H2 — the release notes reserve that level for categories · Fix · 2026-07-29

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

Plugins: specialists

[PR #243](https://github.com/DaveKJohn/davekjohns-workshop/pull/243)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.13.2] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.2.md](releases/development/2.x/2.13.2.md) for the full release notes.

---

### [v2.13.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.1.md](releases/development/2.x/2.13.1.md) for the full release notes.

---

### [v2.13.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.13.0.md](releases/development/2.x/2.13.0.md) for the full release notes.

---

### [v2.12.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.12.0.md](releases/development/2.x/2.12.0.md) for the full release notes.

---

### [v2.11.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.11.0.md](releases/development/2.x/2.11.0.md) for the full release notes.

---

### [v2.10.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.10.0.md](releases/development/2.x/2.10.0.md) for the full release notes.

---

### [v2.9.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.9.0.md](releases/development/2.x/2.9.0.md) for the full release notes.

---

### [v2.8.0] - 2026-07-27 — Minor

See [releases/development/2.x/2.8.0.md](releases/development/2.x/2.8.0.md) for the full release notes.

---

### [v2.7.3] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.3.md](releases/development/2.x/2.7.3.md) for the full release notes.

---

### [v2.7.2] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.2.md](releases/development/2.x/2.7.2.md) for the full release notes.

---

### [v2.7.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.1.md](releases/development/2.x/2.7.1.md) for the full release notes.

---

### [v2.7.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.7.0.md](releases/development/2.x/2.7.0.md) for the full release notes.

---

### [v2.6.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.6.1.md](releases/development/2.x/2.6.1.md) for the full release notes.

---

### [v2.6.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.6.0.md](releases/development/2.x/2.6.0.md) for the full release notes.

---

### [v2.5.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.5.0.md](releases/development/2.x/2.5.0.md) for the full release notes.

---

### [v2.4.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.4.1.md](releases/development/2.x/2.4.1.md) for the full release notes.

---

### [v2.4.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.4.0.md](releases/development/2.x/2.4.0.md) for the full release notes.

---

### [v2.3.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.3.0.md](releases/development/2.x/2.3.0.md) for the full release notes.

---

### [v2.2.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.2.1.md](releases/development/2.x/2.2.1.md) for the full release notes.

---

### [v2.2.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.2.0.md](releases/development/2.x/2.2.0.md) for the full release notes.

---

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
