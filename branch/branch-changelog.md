## `feat/teams-and-workflows-rename` changelog

### Branch title

The plugins are renamed to teams and workflows

### Branch ID

20260809-041233

### Branch type

feat

### What does the change on this branch bring to main?

Every plugin here is now either a **team** — who the specialists are — or a **workflow** — how work
moves through the repo they land in. The names say which:

| was | is |
|---|---|
| `specialists` | `team-alpha` |
| `specialists-lifehub` | `team-lifehub` |
| `specialists-shopify` | `team-shopify` |
| `specialists-ecomm` | `team-ecomm` |
| `specialists-workflow-davekjohn` | `workflow-davekjohn` |

**The distinction is not new; only its visibility is.** It was decided on August 8, 2026, when the
branch/release machinery moved out of the core because 47% of what the core shipped was one particular
way of working that no consumer had chosen. What did not move with it was the naming: five plugins
sharing one prefix, numbered group 1 to group 5, which is the shape of a single family with variants
rather than of two different kinds of thing.

**The numbering is gone with it, and that is the half worth arguing.** A number implies an order and a
completeness that never held: group 3 and group 4 are not steps, they are a platform and a set of
disciplines that a commercial Shopify repo enables *together*. What replaces it is a rule a reader can
apply without a table — **teams stack, workflows do not.** Enable the core team plus whichever add-on
teams fit the repo; enable exactly one workflow, because two would answer the same question
differently and the specialists would have no way to tell which answer is the repo's.

**Consumers must act, and there is no automatic path.** A renamed plugin is a different install id, so
an existing consumer uninstalls the old ids and installs the new ones. Nothing breaks quietly in the
meantime — the old ids simply stop existing in the marketplace — but nothing migrates on its own
either.

**Three things the rename quietly hollowed out, none of which turned a test red.** They are recorded
because a mechanical rename cannot see any of them, and the next one will not either:

- Two asserts in `release-lib.tests.ps1` test a **relationship between two names** — one shares a
  prefix with another, one differs only in case. Both sides were renamed correctly, and the pair was
  left comparing names that no longer share a prefix and no longer differ only in case. They kept
  passing while testing nothing.
- The ordinal-sort choice in `check-report-lib.ps1` rests on a measurement taken on a name pair where
  culture-aware and ordinal collation disagree. For the renamed pair they agree — so the next person
  to verify the claim finds no difference and concludes the sort is pointless. It is asserted on a
  synthetic pair now, with the trap written down above it.
- The bootstrap's durable-body fixture named the cache directory after one plugin and the marketplace
  clone after another. The symptom was exactly what that scenario exists to catch: the `@`-import fell
  back to the version-pinned cache path.

**One consequence named and deliberately not built for.** A consumer whose lenses still sit on the
pre-seam path `.claude/plugins/claude-specialists/<plugin>/` has that second segment named after the
plugin — so after they reinstall under the new name, the readers look under `team-alpha/` and their
lenses go unseen. It is recorded here rather than repaired because nothing has measured such a consumer:
of the four in the register, the layout is known to be the seam or unknown, never confirmed pre-seam.
The migration page is where it belongs, and it is on that branch's list. Building the fallback now would
be a repair for a consumer nobody has found.

**Two boundaries drawn deliberately.** The consumer register keeps the **old** ids for the three repos
that have not migrated, because it records what a consumer *has* — claiming a migration nobody
performed turns the register itself into a false alarm. And in `releases/**` only the link **targets**
were repointed: a historical note's claims are history, but its links have to keep resolving or the
note is unreadable.

One stale claim was repaired on the way past: the core's manifest still said it ships
`connector-sessioncheck`, which moved to the workflow plugin on August 8.

### Significance

#### Tier 0

The tree finally says what the doctrine says. Until now a maintainer had to know that `specialists-`
meant two unrelated things depending on the suffix, and the group numbering had to be looked up rather
than reasoned about.

**Score:** 3

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Yes. Deciding what a new plugin *is* used to require reading the table; it is now a question with two
answers, and the answer picks the name. It also settles a question that had no home before: whether
two of a kind may be enabled at once. For teams the answer is yes and always was; for workflows it is
no, which is stated in the manifests here and enforced in a later change.

**Score:** 3

#### Tier 2

Is this next one still relevant for a consumer of the product?

Yes, and it is why this is the only breaking change in the sequence. Every existing install carries an
id that no longer exists: `specialists@claude-code-specialists` and its four siblings. A consumer
uninstalls the old ids, installs the new ones, restarts, and re-runs `specialists-init`. The skill
names deliberately did **not** change, so only the prefix moves — `/team-alpha:specialists-init`
rather than `/specialists:specialists-init`.

**Score:** 5

### Pull Request
