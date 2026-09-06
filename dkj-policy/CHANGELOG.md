# Changelog

Everything merged since the last release sits under **`## [Unreleased]`**, **newest first**: **one `###` per
change**, and under it two named `####` sections. The `###` heading is the change's own —
`` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `#### What makes this deploy extra special` for the second audience, and `#### Pull Request`.
Every level here moved one deeper on August 26, 2026, when the pending section above them was introduced and
the development cycle beside them shifted to match; entries written before that day carry the whole set one
level shallower and are read exactly as they always were.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
[`releases/history.md`](releases/history.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`dkj-policy/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

**The line directly under `## [Unreleased]` is a tally, and nobody types it.** It says how many entries are
waiting for the next release and how they split by tier — including how many reach the audience this repo
publishes to, which is the number that says whether there is a release here or only a patch. It is
**derived from the entries below it every time it is written**, by the fold that adds one and the cut that
removes them all, so it holds no state of its own and a hand-edited count is simply corrected on the next
fold. It ends with an HTML comment that marks it as machine-written; that marker is what the next run
replaces, so anything else written in this space is left alone.

---

## [Unreleased]

**8 entries pending** -- 4 at tier 0, 4 at tier 2. Tier 2 is this repo's audience: 4 of 8 reach it. <!-- pending-tally -->

### DEPLOY: fix/1518-consumer-unreleased-heading · 20260906-202744

A repo adopting this workflow now gets a `CHANGELOG.md` with `## [Unreleased]` in it. Until today
`adopt-workflow-folder.ps1` scaffolded the intro and stopped, so an adopting repo's entries sat directly
under the prose — the flat shape this workflow left behind on August 26, 2026 — while
`DEVELOPMENT-portable.md`, which travels to every consumer, tells them to grep `[Unreleased]` for what a
behaviour used to be. That grep matched nothing in their tree.

Nothing was broken and nothing is repaired in that sense: the fold inserts at the first entry heading or,
where there is none, at the end of the content, and the cut writes the head back whatever is in it, so
both shapes fold and cut correctly and no gate had anything to say. What was wrong is that one shape was
documented and a different one shipped.

The heading is composed from `Get-ChangelogUnreleasedHeading` rather than typed — a repo that translated
the label or repointed the entry level gets its own — and it is written **last**, because the first fold
into an entry-less document appends at the end of the content and anything below the heading would
collect its entries above it.

**An adoption older than today keeps the flat shape**, and that is left alone deliberately: the
scaffolder is strictly additive and never revisits a repo it has scaffolded. The tally's third anchor
exists for exactly those repos and is untouched; what changed there is the sentence justifying it, which
described the scaffolder's present tense.

**Score:** 3

#### What makes this deploy extra special

N/A. The audience here is this repo's own developers and the consumers of `dkj-policy`, which is tier 0
and tier 1 — nobody subscribes to a service that changes. A consumer maintainer adopting the workflow
today gets a changelog that matches the page they are told to read, which is worth a 3 there; it is
invisible to anyone else.

**Score:** N/A

#### Pull Request

The scaffolded consumer changelog carries the pending heading

Plugins: dkj-policy

[PR #1533](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1533)

---

### DEPLOY: fix/1530-test-capture-decoration · 20260906-201920

`verify-pushed-merges.tests.ps1` failed one assert on a tree byte-identical to `origin/main` while CI on
`main` was green, and `open-pr.ps1` has no per-suite valve -- so on the affected checkout every branch
was pushed with the whole test gate off, or not at all. The suite is repaired, and the cause was neither
the fixture nor the script under test.

Both suites captured their child with `& powershell ... 2>&1 | Out-String`. Under `2>&1` the parent
re-renders the child's **first** stderr line as its own `NativeCommandError` and stamps the record
decoration -- `At <path>:<line>`, the source echo, `CategoryInfo`, `FullyQualifiedErrorId` -- *into* that
line at the cut. `Assert-Says` strips all whitespace, which repairs a **wrap**; it cannot repair
**insertion**, and the docstring claiming otherwise is corrected here. The parent renders
`<powershell.exe> : <full script path> : <message>` and cuts the whole of it at the console width, so the
verdict is decided by the checkout's path length and the terminal width -- neither of which is a property
of the code. Measured: green at this repo's 108-character script path, red at 45, same commit and same
machine; the failing window at width 120 is 29 to 51 characters.

Both suites now capture through `Invoke-NativeCapture -Utf8`, which starts the child with `Start-Process`
and redirected streams, so the parent's formatter never touches the child's stderr. Each gained one assert
that `NativeCommandError` is **absent** from the captured text: it can only appear there if a parent
rendered the stderr as an error record, so its absence pins **which capture ran** at every width and path
length -- where the phrase-only assert that was already there fails only where the cut happens to land
inside its phrase, which is how this stayed green on CI.

`verify-resolved-issues.tests.ps1` is changed without a failing assert to point at, deliberately: it is
where the broken capture was copied from, and "it passes here today" is a fact about one checkout rather
than a property of the file. The same reasoning put the lesson in Tycho's lens -- it existed only as a
comment inside `shared-scripts.tests.ps1`, repaired in August 2026, and the suite written after that
repair still copied the old capture from its sibling.

**Score:** 4

#### What makes this deploy extra special

N/A. Both files are this repo's own test suites; neither is mirrored into a plugin, and no shipped script
changes. A consumer sees nothing.

**Score:** N/A

#### Pull Request

Test capture: a parent's error-record decoration splits asserted phrases

[PR #1534](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1534)

---

### DEPLOY: fix/1524-connector-localcheckout · 20260906-200252

A connector manifest's `localCheckout` may now name several candidate relative paths, and both BWJ
manifests record the two layouts that were actually measured. The check takes the first candidate
present on the machine running it and, where none resolves, names all of them in the `[SKIP]`.

This closes a defect whose cost was invisible by construction. A checkout path that does not resolve is
not reported as wrong -- it is reported as `[SKIP] checkout ... not present on this machine`, which
asserts an absence, exits 0, and suppresses everything that connector would have said. On the machine
[#1524](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1524) was measured from, one
such skip covered four `[INFO]` lines and a drift check reading 26 missing agent-defs. The list exists
rather than one corrected string because the two machines holding those checkouts place them
differently, so any single value is false on one of them -- which would have moved the false skip
instead of removing it.

**Score:** 3

#### What makes this deploy extra special

N/A -- the connector register is this repo's own bookkeeping about its consumers. It changes nothing a
subscriber of a service could notice.

**Score:** N/A

#### Pull Request

connectors: localCheckout accepts per-machine candidate paths, and both BWJ manifests record the real ones

[PR #1531](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1531)

---

### DEPLOY: docs/1517-unreleased-label-not-a-seam · 20260906-194830

The comment over `$script:ChangelogUnreleasedLabel` said the `[Unreleased]` label was a seam a consumer
may translate. It never was: `Get-ChangelogUnreleasedLabel` returns the bare constant, with no
`Get-Command` probe, no `-OverrideCommand`, and no line in the script contract. It now says what the code
does -- a single constant, deliberately not repo-owned -- and gives the reason: nothing migrates the
document the pattern is pointed at, so an override would move writer and reader together, off the
`## [Unreleased]` already committed in every changelog, and take the fold's insertion point with it.

The hazard was the next repair rather than today's behaviour. Writer and reader agree because both derive
from the same constant, so nothing is failing; but a maintainer trusting the comment would most cheaply
have added the override to `Get-ChangelogUnreleasedPattern` -- the reader's half of a seam with no writer's
half -- and the pattern would then have stopped matching the heading, silently.

**Score:** 2

#### What makes this deploy extra special

N/A. A comment in a shared script: nobody outside this repo's maintainers reads it, and no behaviour
changes for a consumer. The mirror copy is updated in the same commit, so the plugin ships the corrected
text at the next release.

**Score:** N/A

#### Pull Request

The pending heading's label is a constant, not a seam

Plugins: dkj-policy

[PR #1529](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1529)

---

### DEPLOY: fix/1525-register-dkj-team-alpha · 20260906-193300

The register of the repo that **owns** the connector check was itself unchecked: its core-team block
had been skipped since the `dkj-team-alpha` rename, so the 19 lenses, the enablement and the machine
version were verified by nothing. Worse, the check reported that state as *"correct as it stands"*.
Both are gone -- the block is read again, and the entry says what this repo actually has.

**Score:** 3

#### What makes this deploy extra special

The same class closed for a third time, and this time inside the commit that declared it closed:
`#1465` wrote *"The class was never emptied, only its instance was"* while repairing one of the two
stale ids in this file and leaving the other. The note now records the rule that would have caught
it -- check a rename against every id in the manifest, not against the one the report names.

**Score:** 2

#### Pull Request

register this repo's own core team under dkj-team-alpha@

[PR #1528](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1528)

---

### DEPLOY: fix/1522-adopt-bwj-scope-and-board · 20260906-191058

`adopt-dkj-policy-bwj` refuses a checkout that is not one of the two BWJ store repos, in a new step 0
ahead of anything it writes. The constraint had lived only in the skill's frontmatter `description:` --
a grep for the two store slugs over the whole skill directory returned exactly one hit, that line -- so
none of the seven steps ever established which repo the session was standing in. Step 1's existing
"stop and diff" guard does not cover it, and reads as though it does: that guard protects a repo which
has *already* adopted, while a first run in the wrong repo finds no file at either target, so it passes
cleanly and the copy proceeds. Measured here on September 6, 2026 -- the skill was invoked in this
source repo, which is where its own templates are copied *from*, so every file step 1 wants is already
in reach and nothing about running the steps in order says otherwise. A person stopped it; the skill did
not. Left alone, step 1 would have placed an Asana mirror workflow -- `issues: write`, a daily cron, and
a project GID this repo does not own -- on the public tracker that receives every consumer's inbound
reports. The step is numbered 0 so steps 1-7 keep their numbers and every cross-reference still
resolves, and it ships with no override flag, there being no legitimate third adoption target.

**Score:** 3

#### What makes this deploy extra special

The same page stops telling both stores to use one shared Asana board. It did not merely permit that
answer, it argued for it, and the two constraints it cited are what made the argument persuasive: both
are true, and both are satisfied by a per-store board exactly as well as by a shared one, so they argue
for a *real* board rather than a *provisional* one -- never for one board rather than two. Measured over
the workspace on September 6, 2026: there are two GitHub boards, one per store. Both bullets are kept
verbatim and only the conclusion changes -- each store repo answers `Get-AsanaProjectGid` with a board
of its own, and the value is never copied between them. What a copied value costs is nothing visible,
which is the reason this is worth a release note: the create call succeeds, the fields write, the
sections still move a card, and the only symptom is colleagues on one store finding the other store's
tickets sitting on theirs. **A store that adopted under the old wording should check which board its
GID actually names.** Same page, wording only: `Github Type` is a multi-select and takes an array of
option GIDs, not a plain select -- `report-issue` already sent the array, so no behaviour moves.

**Score:** 4

#### Pull Request

adopt-dkj-policy-bwj establishes the target repo before it writes, and stops prescribing one shared board

Plugins: dkj-policy-bwj

[PR #1527](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1527)

---

### DEPLOY: feat/1515-pending-entry-count · 20260906-151510

`CHANGELOG.md` could not say how much was waiting for the next release without somebody counting the
entries by hand. It now carries one machine-written line directly under `## [Unreleased]`: how many
entries are pending, how they split by tier, and how many of them reach the audience tier the repo
publishes to -- which is the number that decides whether there is a release here at all or only a
patch. The fold rewrites it after every merge and the release cut rewrites it on the emptied
document.

It holds no state. The line is recounted from the entries in the document about to be written, using
the same reader the cut uses and the same disjoint highest-tier grouping, so the tally cannot
disagree with what the release is about to do -- and an entry edited in or out by hand is corrected
by the next fold rather than left to rot. It deliberately does not name the bump the pending work
earns: that rule lives in `Test-ReleaseBumpEarned`, in a lib the fold does not load, and a second
copy of a release gate's arithmetic inside the document that gate reads is the shape this repo keeps
getting bitten by.

**Score:** 3

#### What makes this deploy extra special

Every consuming repo gets this through the plugin, and gets it without doing anything: no heading to
add, no configuration to answer. The tally anchors on the pending heading where a repo has one and on
the first entry where it does not -- which is the shape `adopt-workflow-folder.ps1` scaffolds, so the
repos most likely to have been missed are the ones explicitly covered. Every word of the line is
overridable through `Get-ChangelogPendingSummaryOverrides`, so a changelog kept in another language
stays in it, and the count reads correctly whether a repo answered tier 1 or tier 2 as its audience.

The one thing a consumer could lose is a note of their own in that space, and that is what the line's
trailing HTML comment prevents: only a line carrying that marker is ever replaced, and a marker
quoted in their intro -- in a fence or in inline backticks -- is read as a quotation rather than as
the line itself. That second guard is the one a fence check cannot give, and the intro is exactly
where somebody will write it.

**Score:** 3

#### Pull Request

Count the pending entries under [Unreleased] in the changelog

Plugins: dkj-policy

[PR #1519](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1519)

---

### DEPLOY: feat/1516-consumer-merge-queue · 20260906-150722

The merge queue became this workflow's policy for every repo that runs it, and the only thing that
travelled was the half `ship-pr` already carried. `adopt-merge-queue.ps1` is the rest: Part 3 of
`adopt-dkj-policy`, it reads a repo's trunk rules and its workflow files, reports whether that repo
would survive a queue, places the two CI runners a queue takes away from the shipping session -- the
fold (#1493) and the resolves verification (#1511) -- and prints the ruleset command **without running
it**. `verify-pushed-merges.ps1`, which the second of those runners calls, was registered as a shared
mirror in the same movement; it had none, so the runner would have pointed at a path no consumer has.
And `ship-pr`'s enqueue arm now checks for a fold runner before promising one.

**Score:** 3

#### What makes this deploy extra special

**The order is the feature, and getting it wrong is an outage rather than a gap.** A merge queue is
not a setting you switch on and then tidy up after: without a `merge_group` trigger on the workflow
carrying your required check, that check never runs for a queue entry, never reports, and **every merge
fails**. So the command reports the prerequisite first, the runners second, and the switch last -- and
it refuses to pull the switch at all. A ruleset changes what every contributor's merge does,
immediately, for everybody; that is the repo owner's act, and reading a ruleset needs a token that can
read while writing one needs a token that can administer the repo.

**Everything it guards against fails silently, which is why the report has two vocabularies.** A `[gap]`
on a trunk with no queue is a to-do and exits 0 -- your merges are fine today. The identical gap with a
queue **active** exits 1, because entries are already being stranded on your trunk or your merges are
about to stop. Collapsing those two is how an honest report earns being ignored.

**And a plugin install writes nothing into a repo**, which is the fact the whole feature turns on.
Neither runner is plugin payload, so before this a consumer who flipped the setting got: an outage, or a
trunk quietly collecting unfolded changelog entries, with `ship-pr` printing *"fold-on-merge.yml folds
the entry off that push"* at the exact moment nothing was going to.

**Score:** 4

#### Pull Request

The merge-queue policy travels with dkj-policy

Plugins: dkj-policy

[PR #1520](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1520)

---

