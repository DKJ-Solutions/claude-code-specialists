## `docs/readme-consistency-sweep` changelog

### Branch title

Four README claims corrected against the tree they describe

### Branch ID

20260809-175657

### Branch type

docs

### What does the change on this branch bring to main?

Four documents each carried a claim that the tree contradicts. None of them is caught by a gate, and
three were produced by a move that updated the mechanism and left the sentence describing it.

**The shared-scripts page listed a third of its own subject and called the list complete.** It says the
Status table "mirrors the full registry … so this is the **complete** shared set"; it had **9** rows
against the registry's **23** pairs, missing `ship-pr`, `cut-release`, `adopt-config`,
`new-internal-note`, `verify-resolved-issues`, `fix-mojibake` and five libs. Measured rather than
counted by eye, and the measurement turned up something the page had no room for at all: **the shared
set spans three plugins.** `check-roster-sync` mirrors into `team-alpha` and `check-report-lib` into all
three, because a script travels to whichever plugin owns the surface that calls it — so a page written
as if this folder were the whole set could not have been completed without that distinction. The table
now names the 20 pairs that land here, with the other three accounted for above it.

Two more defects in the same file: its **title named `specialists/scripts/`**, a path that has not
existed since the plugin reorganisation, and its opening line called this folder "the **single source of
truth**" five lines above the paragraph explaining that the root copy is canonical and this one is a
mirror. A reader looking for where to make a change was told both answers.

**`connectors/README.md` carried a sentence with no subject** — *"In the repos that do carry it — …
locates the workshop checkout and runs the connectors check there"* — left behind when the August 8 move
inserted an explanation between a subject and its verb, and duplicating the sentence ten lines above it.
Its list of the plugins' named hook/skill exceptions also still counted two; there are six.

**The specialists handbook had lost a specialist.** Bianca #02 appears in `SPECIALISTS.md`'s roster, ships
a persona and has a lens on disk, and was in none of the handbook's three inventories. Rebecca #07 was
missing from the subagent-lens enumeration while present in the index two paragraphs down. And the
closing note said five specialists "has no repo lens (yet)" — all nineteen lenses exist as `VUL-IN`
scaffolds, which `SPECIALISTS.md` calls "the intended state, not a backlog item". The index is now
complete and marks which lenses are scaffolds, so the two documents agree.

**The root README named three personas in one cell and four in two other places.** Four persona
templates ship.

### Significance

#### Tier 0

The shared-scripts page is where a maintainer looks to answer "is this script shared, and does it have a
skill" — and for eleven of the twenty-three pairs the page's answer was silence indistinguishable from
"no". The handbook's missing specialist has the same shape: nothing errors, the roster simply gets
consulted and comes back short.

**Score:** 3

#### Tier 1

Anyone reading this project's own documentation to understand what it ships was reading an inventory a
third the size of the real one.

**Score:** 2

#### Tier 2

The shared-scripts page ships inside the plugin, so it is the page a consumer of `workflow-davekjohn`
actually has — they get no root `scripts/` to compare it against. The corrected table is the first
statement they receive of what the plugin gives them, and the three-plugin split explains why two of the
scripts they run are not in this folder at all.

**Score:** 3

### Pull Request

