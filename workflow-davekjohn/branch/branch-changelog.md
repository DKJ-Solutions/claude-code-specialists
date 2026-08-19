## Branch `fix/readme-stale-pointers` changelog - 20260819-104741

### What does the change on this branch bring to main?

#### Tier 0

`README.md` sent a reader to the wrong page twice, and both claims were falsified by the README's own
other sentences rather than by anything outside it.

**Its `## Contributing` section said the branch/entry-file/PR/merge/fold workflow and the release cut
are described in [`CONTRIBUTING.md`](CONTRIBUTING.md).** Since August 14, 2026 that page is
deliberately the *standard workflow* — three rules, no entry, no fold, no cut — and it points at
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md) for exactly the mechanics
the README promised it held. A reader following that link found the pointer, not the content. The
Start-here table carried the same defect in four words: *"the branch / PR / fold workflow"*.

**The same section said the roster and the routing are in [`CLAUDE.md`](CLAUDE.md).** They are not,
and the README says so itself in two other places: its repo-layout list describes
`.claude/specialists/SPECIALISTS.md` as *"the inclusion carrying the body import, the lens import and
the roster"*, and its seam section states that `CLAUDE.md` carries that one import *"and nothing
more"*. Measured: **0** roster or routing tables in `CLAUDE.md`. The contradiction predates today but
sharpened this morning, when the two remaining orchestrator paragraphs above the seam line were
deleted.

Both now name the layer that actually holds the material, and the contributing section states the
standard-versus-layer split in the same shape the two pages themselves use.

**Nothing else in the README changed, after an audit that expected to find more.** Measured against
the law it already states — *"does this describe a craft, or a way of working?"* — the page does not
push this repo's answers on anyone: **0** mentions of `lint-en-tests`, **0** of the `feat/`/`fix/`/
`docs/` prefixes, and all 18 uses of *portable* in the plugin sense the page itself defines at its own
test question. Its figures are covered by checks 15 and 16, which name `README.md` in the
consumer-facing set. The one thing that was wrong was where it sent people.

**One measurement nearly went the other way, and the method is the point.** A grep for the fold
mechanics in `CONTRIBUTING.md` returned three hits, which reads as *"the content is there after
all"*. Two were the letters `fold` inside the word **folder** — the same substring trap as `Dave`
inside `DaveKJohn` the branch before — and the third was the sentence delegating those mechanics
elsewhere. A count is the search's answer, not the subject's.

**Score:** 2

#### Higher than tier 0?

N/A — `README.md` is this repo's own landing page and is not plugin payload. A consumer receives
nothing from this branch.

**Score:** N/A

### Pull Request

The README's contributing pointers name the wrong two pages
