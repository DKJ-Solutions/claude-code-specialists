## `feat/workflow-default` changelog

### Branch title

A default workflow for a repo that has chosen none

### Branch ID

20260809-095739

### Branch type

feat

### What does the change on this branch bring to main?

A sixth plugin, `workflow-default`, and it is the one a consuming repo keeps enabled until it
deliberately picks another. It carries no method: where `workflow-davekjohn` is one particular
branch-and-entry model named after its author, this is the deliberate **absence** of one, packaged so
that absence is an enabled plugin rather than a gap nobody filled in.

**It had to be more than a marker to be worth shipping.** The core team already tells every specialist
to read the repo's own way of working first — that rule is expanded verbatim into every agent def from
`agent-shared/repo-way-of-working.md`. A plugin that only repeated it would be a second copy of a
sentence that already reaches everyone. So it ships one skill, **`discover-workflow`**, which does that
reading once and records the answer: branch names, commit-subject style, how work reaches the trunk,
merge shape, what gates a change, whether the repo wrote its process down, whether it addresses its
agents directly, and what it already automates.

**`SILENT` is an answer, and that is the half the skill exists for.** Every question has three possible
outcomes — an observation with the evidence it came from, `SILENT`, or nothing at all — and the third
is impossible by construction. A discovery that reported only findings would quietly turn each gap into
an invitation to fill it with a habit from elsewhere, which is exactly what the shared rule forbids.

**One design decision was forced by measurement rather than argument.** The first version also mined
commit subjects for branch prefixes, on the reasoning that a repo which deletes branches after merging
keeps the names nowhere else. Run against this repo, it reported `plugins/`, `releases/`, `branch/` and
`templates/` as branch conventions — every one a directory path quoted in a commit message. A `word/`
token in prose is a path as often as a branch, and no sharpening of the pattern separates them, because
they are the same shape. So refs are evidence and prose is not: a repo whose branches are all deleted
answers `SILENT` here, which is the correct answer for a skill built not to guess.

**Two behaviours settled by Dave** (August 9, 2026). The document lands **inside the seam**, at
`.claude/specialists/repo-workflow.md`, so `specialists-teardown` removes it with everything else and
adoption stays reversible without a second rule — one footprint rather than two. And it **never
overwrites**: a second run reports what changed and leaves the file exactly as it is, the same rule
`specialists-init` follows, because a person may have corrected or extended it and no script can tell
an improvement from staleness.

`INSTALL.md`'s default settings block now enables `team-alpha` **and** `workflow-default`, which is what
makes this the default rather than merely the recommendation.

### Significance

#### Tier 0

A new plugin to keep in step — its manifest, the marketplace, the two `skills:all` enumerations in the
README, and the lint fixture's own plugin list, which throws loudly rather than dropping a pair when it
falls behind. That loudness is deliberate and it cost a dozen unrelated scenarios the first time.

**Score:** 2

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Yes. "Which workflow is this repo on?" becomes a question with an answer for every repo rather than only
for the ones that adopted DaveKJohn's. And `discover-workflow` gives a specialist landing in an
unfamiliar repo one document to read instead of eight places to re-derive from every session.

**Score:** 3

#### Tier 2

Is this next one still relevant for a consumer of the product?

Yes, and it changes what adoption means for them. Until now a consumer either took one particular way of
working or got nothing where a workflow should be; there is now a plugin that says, in the product's own
terms, that their repo's conventions are the ones that count. The skill is the concrete part: it reads
what they already have and, just as importantly, tells them which questions their repo has never
answered.

**Score:** 4

### Pull Request
