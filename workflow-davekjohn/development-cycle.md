# Development cycle: `feat/gate-validates-import-targets-v1` · 20260826-085857

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

## PLAN

**Issue [#874](https://github.com/DaveKJohn/claude-code-specialists/issues/874): no gate resolves an
`@`-import target, so a dead always-on import fails silently.** Verified against the tree at `a8331dd`
before scoping, on all five inbound checks:

| check | verdict at `a8331dd` |
| --- | --- |
| subject | stands -- `scripts/lint/check-plugin-integrity.ps1`, its `[link]` check and `scripts/maintenance/measure-always-on.ps1` all exist under those names |
| symptom | stands -- no check in the gate resolves an import; `$linkRegex` matches `[text](target)` and an `@`-line matches none of it |
| reasoning | stands -- the always-on path is assembled entirely out of three imports, two of them not repo-relative |
| proposed repair | **better than proposed** -- the three resolution rules are already implemented and tested in `scripts/lib/measure-context-lib.ps1` (`Get-ImportLinePath`, `Resolve-ImportPath`, `Test-IsFenceLine`), so the check reuses them instead of restating them |
| size | **the report undercounts, and in the useful direction** -- it names 4 imports; a `^@` sweep of every `.md` in the tree returns **12** lines. 8 are noise the check has to survive: 7 PowerShell `@(...)` expressions inside fences, and 1 line of prose |

**The measurement that shapes the check.** Running the lib's own parser over every `.md` in the tree,
with fence tracking on:

| | count |
| --- | --- |
| non-fenced column-0 `@` lines | 4 |
| path-shaped targets (no whitespace) | 3 -- and all three resolve |
| in-tree | 2 (`CLAUDE.md` -> `SPECIALISTS.md`, `SPECIALISTS.md` -> `lenses/01-01-extension.md`) |
| outside the repo | 1 (`SPECIALISTS.md` -> the marketplace clone, `~/`-relative) |
| prose, not a path | 1 -- `releases/development/1.x/1.16.0.md:80`, a paragraph that wraps onto `@-imported here (...)` |

So the check is **born green**, which is this repo's standing bar for a new gate check (checks 26 and
27 both cleared it), and it needs exactly the two discriminators the issue said to settle first.

### The two settled questions

1. **An import outside the repo is not an error.** `SPECIALISTS.md`'s persona import is `~/`-relative
   and points into the plugin marketplace clone. CI is a machine with no such clone, so an error there
   would fail every PR for a correct file. It is counted and named in the coverage line instead.
2. **A target containing whitespace is prose, not an import.** The lib's `Get-ImportLinePath` takes the
   rest of the line as the path, which is right for the always-on walk (it never meets prose) and wrong
   for a scan set that includes archived release notes. One line in the tree needs this, and it is in a
   file the language rule already exempts from repair -- so the discriminator, not an exemption list.

**Deliberately NOT built: the mirror-image risk, which has not bitten.** A wrapped paragraph beginning
`@` at column 0 inside an always-on document *would* be read by Claude Code as an import, and the
document after it would be lost. No instance exists -- the only one in the tree sits in an archived
release note nothing loads -- and this repo's rule is that a risk which has not bitten is written down
rather than built against. It is written into the check's own comment.

## CREATE

- [x] Add check 28 `[import]` to `scripts/lint/check-plugin-integrity.ps1`, reusing `measure-context-lib.ps1` rather than restating the three resolution rules
- [x] Dot-source `measure-context-lib.ps1` at the gate's import block, and add it to BOTH test fixtures the block's own warning names (`check-plugin-integrity-fixture.ps1`, `workflow-exclusivity.tests.ps1`) -- a lib they do not copy kills the script at that line and every check after it silently never runs
- [x] Write the coverage line so an empty scan announces itself, per issue #221
- [x] Point `measure-always-on.ps1`'s docstring and its runtime warning at the check now that "the verdict belongs to the lint gate, which does not yet cover the class (issue #874)" has stopped being true -- and say what the gate still does NOT reach, since a `~/`-relative target stays this script's alone. Mirrored to the plugin copy, held byte-identical by check 8
- [x] Name the class in [the system-administration lens](.claude/specialists/lenses/05-15-extension.md), where the gate's checks are described -- the lens is where a reader learns why a check has the shape it has

## TEST

- [x] A fixture scenario per class: a resolving in-tree import (pass), a dead in-tree import (error), an import outside the repo (no error), a fenced `@(...)` expression (no error), and a prose line starting with `@` (no error). Seven scenarios, thirteen asserts, in `check-plugin-integrity-links.tests.ps1` beside check 4 -- its sibling on the same scan set
- [x] One assert compares check 28's coverage count against check 4's, so the two sets cannot silently drift apart. Not in the plan; added because the resolution rule is only half of what a later refactor can break
- [x] `check-plugin-integrity.ps1` green on the real tree -- **born green, re-measured rather than asserted**: `[import] checked 294`, 2 resolving in-tree, 1 outside the repo, 1 read as prose, 0 findings
- [x] The full suite green (`scripts/tests/*.tests.ps1`), the same set CI runs -- 53 suites, 0 failing, 482s

## DEPLOY: `feat/gate-validates-import-targets-v1`

The lint gate now resolves every `@`-import target it can see, and refuses a dead one whose target is
in the tree. Check 4 has validated `[text](target)` links since the beginning; an `@`-import is a
different syntax and matched none of it, so no gate in this repo had ever resolved one --
[issue #874](https://github.com/DaveKJohn/claude-code-specialists/issues/874).

**Why this class is not just another dead link.** A dead link costs a reader one click. A dead import
costs the **session the whole document**: Claude Code drops one it cannot resolve without erroring, so
nothing fails and the instructions simply are not there. This repo's always-on path is assembled out of
exactly three imports, and two of them are not repo-relative -- so the layer that vanishes is the one
carrying the safety rules or the roster, and the only symptom is a session behaving as if it had never
read them.

Check 28 reuses the parser in `scripts/lib/measure-context-lib.ps1` rather than restating the three
resolution rules, so the gate and `scripts/maintenance/measure-always-on.ps1` cannot drift on what an
import means or where it resolves from. Two discriminators keep it honest, both measured before it was
written: a fenced `@(...)` is PowerShell, and a target containing whitespace is prose -- seven and one of
the twelve column-0 `@` lines in the tree respectively. A target outside the repo is counted and named,
never refused, because a `~/`-relative import points into the plugin marketplace clone and CI is a
machine without one.

**Born green**, this repo's standing bar for a new check: 294 files scanned, 2 resolving in-tree imports,
1 outside the repo, 1 line read as prose, 0 findings and 0 exemptions.

**Score:** 3

### What makes this deploy extra special

N/A. The check itself lives in `scripts/lint/`, which is this repo's own gate and does not travel to a
consumer. What does travel is the plugin mirror of `measure-always-on.ps1`, and only its wording changed
there -- the sentence saying no gate covers this class was true when it was written and is not any more.
No consumer behaviour changes.

**Score:** N/A

### Pull Request

the lint gate validates every '@'-import target
