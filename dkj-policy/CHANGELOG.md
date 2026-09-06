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

