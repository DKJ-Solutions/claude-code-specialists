## Development cycle: `fix/entry-link-gate-follows-changelog-v1` · 20260827-122840

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
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

### PLAN

#### The finding, verified against the tree

Inbound [#967](https://github.com/DaveKJohn/claude-code-specialists/issues/967) stands in full, and every
mechanism it names exists:

- `scripts/lib/seam-lib.ps1:44` -- `Get-DefaultChangelogPath` returns `<workflow folder>/CHANGELOG.md` for
  every repo that is not the workflow's source, so a consumer's changelog sits in the SAME directory as
  `contributing-davekjohn/development-cycle.md`.
- `scripts/release/open-pr.ps1:708` -- the link gate calls `Get-EntryLinkFindings ... -RepoRoot $repoRoot`.
- `scripts/lib/entry-scaffold-lib.ps1:4261` -- that function resolves every target against `$RepoRoot` and
  has no parameter for the destination; `-EntryDirRel` shapes only the suggestion.

So on the shipped defaults the gate refuses the link form that will be correct after the fold and demands the
one that will be dead. Not `-Force`-able, by design.

#### The size, recounted -- the report named three sites, there are eight

The report said the count "may be larger than the three above", and it is. Every place that states or
enforces the base:

| site | what it does |
|---|---|
| `Get-EntryLinkFindings` | resolves the targets -- the gate itself |
| `open-pr.ps1`'s link gate | calls it, and its refusal text names "the repo root" and `contributing-davekjohn/branch/` -- the second stale on its own account |
| `StepsGuidance` | the VISIBLE blockquote every branch document carries: "resolve FROM THE REPO ROOT" |
| the comment blocks at `entry-scaffold-lib.ps1:1174` and `:4172` | state the root as a fact rather than as a seam |
| `DEVELOPMENT-portable.md:290,498` | the portable form, shipped to consumers |
| `skills/open-pr/SKILL.md:209,218` | the skill page's own account of the gate |
| `contributing-davekjohn/CONTRIBUTING.md:128` | this repo's answers page |
| `scripts/lint/check-plugin-integrity.ps1:747` | this repo's OWN lint, `$entryRelsForLinks` -> `$dir = $RepoRoot` |

The last one is deliberately NOT changed: this repo publishes plugins, so its changelog IS the root file and
that base is the correct answer here. Changing it would be a change with no measurement behind it.

#### The design

The base follows the destination instead of assuming it: `Split-Path (Get-ChangelogPath) -Parent`, read
through the established `Get-SeamValue` idiom that `cut-release`, `fold-changelog-entry`,
`adopt-workflow-folder` and `session-status` already use. Read in the SCRIPT and passed in, not in the lib --
same as those four. That keeps #806's repair intact for this repo and for any consumer that repoints the seam
back to the root: the default follows the fold's destination instead of assuming one.

### CREATE

- [x] `Get-EntryLinkFindings`: a `-DestDirRel` parameter (default `''` = the root, today's behaviour) as the
      resolution base, and the suggestion expressed from that base rather than always root-relative
- [x] `Get-PathRelativeToDirectory`, which the line above turned out to need. The suggestion was a substring
      of the resolved path, and that answers only a target sitting UNDER the base -- an isolated destination
      has a second case, a target beside it, where a substring silently produced no suggestion at all
- [x] Two candidate bases for that suggestion, not one: the document's own directory, then the repo root.
      Found by probing rather than reasoned about -- a root-relative link at a folder destination was refused
      with no repair named, which is precisely the author who followed the old guidance
- [x] `open-pr.ps1`: dot-source `seam-lib.ps1`, resolve the changelog seam, pass the destination directory,
      and compose the refusal message from it instead of naming the root and a stale `branch/` path
- [x] `StepsGuidance`: the link sentence becomes a per-repo token, resolved the way `{0}` already is, so the
      document a branch is handed states the base that actually applies there
- [x] `Format-DevelopmentCycle` + `new-branch.ps1`: the destination threaded through, seam read in the script
- [x] The two comment blocks restated as the rule (the destination) rather than as the root
- [x] `DEVELOPMENT-portable.md` and the `open-pr` skill page follow
- [~] This repo's `contributing-davekjohn/CONTRIBUTING.md`: dropped, and the reason is the answer rather than
      the effort. Its sentence is phrased as THIS repo's answer and names its reason -- "because the DEPLOY
      section lands at the repo root" -- which is still true here, since a repo with a
      `.claude-plugin/marketplace.json` keeps its root changelog. An answers page stating a correct answer
      needs no repair, and rewriting it would have made this diff overlap PR #969, which edits that file
- [~] `scripts/lint/check-plugin-integrity.ps1`: dropped for the same reason one level down. Its
      `$entryRelsForLinks` branch resolves the entry's links from `$RepoRoot`, which is where this repo's
      changelog is -- so it is correct as written, it is not mirrored to consumers, and changing it would be
      a change with no measurement behind it
- [x] `shared-scripts-lib.ps1`: the seam-lib registry entry names its two new readers, so the list of who
      would break without it stays current
- [x] `scripts/sync/build-shared-scripts.ps1`: mirror into the plugin

### TEST

- [x] `entry-scaffold.tests.ps1`: the reversal asserted as a pair -- one link, one tree, two destinations --
      plus the suggestion's form at each, the typo case at both, `Get-PathRelativeToDirectory`'s three shapes
      and its cross-drive answer, and `Format-EntryLinkGuidance`'s three sentences with the override contract
- [x] The round-trip fixture now asserts the CONSUMER answer, which is what it always was: it has no
      `.claude-plugin/marketplace.json`, so its computed changelog default is inside the workflow folder. The
      assert read `FROM THE REPO ROOT` and passed, because it only ever asked whether SOME base was named
- [x] A built tree rather than the live checkout for the new asserts. The first draft used `CONTRIBUTING.md`,
      which exists at BOTH bases here, so the root case reported nothing and read as a broken repair
- [x] The full gate green: `check-plugin-integrity.ps1` (0 errors) + every suite

### DEPLOY: `fix/entry-link-gate-follows-changelog-v1`

`open-pr`'s link gate resolves the entry's relative links from the directory the fold actually writes into,
read through `Get-ChangelogPath` exactly as `fold-changelog-entry` reads it, instead of from the repo root.
The sentence the branch document states about that base is composed from the same value rather than typed, so
the file an author is writing in and the gate that refuses them cannot disagree.

Nothing about this repo's own behaviour changes, and that is worth saying plainly: it publishes a marketplace,
so its changelog is the root file, the base resolves to `''`, and every existing assert holds word for word.
What changes here is the plumbing -- two new functions, a parameter on three call paths, and eleven asserts.

The base was hard-coded to the root by [#806](https://github.com/DaveKJohn/claude-code-specialists/issues/806)'s
repair, which was correct when written: every repo's changelog was at the root. [#914](https://github.com/DaveKJohn/claude-code-specialists/issues/914)
moved the destination and left the gate measuring from the old one -- the shape this repo has now paid for
twice in one area, and the second instance is the one that reached a consumer.

**The report named three sites and there are eight.** Recounted before scoping, per the inbound rule: the two
comment blocks that stated the root as a fact, the visible guidance block, `DEVELOPMENT-portable.md`, the
`open-pr` skill page, this repo's own `CONTRIBUTING.md` and its own lint. Two of those eight are deliberately
left alone -- both correct as written, and both correct for the same reason, which is that this repo genuinely
does fold into its root. Naming them is the point: a sweep that "fixed" them would have made this repo's own
answers page state a base its fold does not use.

**Two things the work found that the report could not.** The suggestion was a substring of the resolved path,
which answers only a target underneath the base -- so an isolated destination with a target beside it produced
a finding and no repair. And a root-relative link at a folder destination was refused with nothing suggested,
which is exactly the author who did as the old guidance told them. Both were found by probing the function
rather than by reading it, which is why the probe is in the branch's TEST list and not only in its plan.

**Score:** 2

#### What makes this deploy extra special

A consumer on the shipped defaults gets a link gate that stops being wrong about their repo. Since 4.20.0
their `CHANGELOG.md` sits in `contributing-davekjohn/` -- the same directory as `development-cycle.md` -- and
until now the gate refused the link form that is correct after the fold and demanded the form that is dead,
with no `-Force` to get past it. The document they were handed told them to write the dead one, in bold, in a
blockquote at the top of the file. Met in `BWJ-ecommerce/xoxowildhearts`, whose own doc lint measures from the
folder: its two gates disagreed, so its entries avoided relative markdown links altogether.

Three things arrive together, which is why this is worth more than a gate fix. The **refusal** now names the
two directories it actually compared, rather than the repo root and a `branch/` path that stopped existing
when the entry became a section of the cycle document -- on the shipped defaults it named two paths, neither
of them in play. The **suggestion** names the form that destination needs, and tries the root as a second base
so the author who followed the old wording is told what to write rather than only that they are wrong. And
the **guidance** in every newly created cycle document states that repo's own base, so the instruction and the
gate come from one value.

Nothing has to be configured, nothing has to be migrated, and an entry already written keeps folding: a repo
that repoints `Get-ChangelogPath` back to the root gets #806's behaviour unchanged, because there the root
genuinely is where the text lands.

**Score:** 4

#### Pull Request

The entry's link gate resolves from where the entry lands, not from the repo root

