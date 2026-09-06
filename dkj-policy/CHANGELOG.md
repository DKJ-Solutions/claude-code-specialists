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

**3 entries pending** -- 0 at tier 0, 3 at tier 2. Tier 2 is this repo's audience: 3 of 3 reach it. <!-- pending-tally -->

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

