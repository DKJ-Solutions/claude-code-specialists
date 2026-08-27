## Development cycle: `fix/register-follows-the-four-migrated-consumers-v1` · 20260827-203709

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
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Measured against the four consumers' live .claude/settings.json: all four have migrated and the register has not. Three still name workflow-davekjohn@, life-hub still names specialists@ and specialists-lifehub@, and life-hub's enabled contributing-davekjohn@ is not registered at all. Data only -- the id-vs-marketplace comparison the issue asks for already exists and is deliberately an INFO.

### CREATE

- [x] `connectors/djcylow-react.json`, `smartwatchbanden.json`, `xoxowildhearts.json`:
      `workflow-davekjohn@` -> `contributing-davekjohn@`.
- [x] `connectors/life-hub.json`: `specialists@` -> `team-alpha@` and `specialists-lifehub@` ->
      `team-lifehub@` (retired in the August 3 reorg, so this record was 24 days behind), plus the
      `contributing-davekjohn@` block it was missing entirely.
- [x] Each manifest's `notes` gained a dated catch-up paragraph naming what was measured and how.
- [x] The historical sentences naming the old id are **left standing**. They are dated measurements,
      some down to the commit, and rewriting one to match today's names is the defect #952 was made of.
      Append-only, the same discipline the placeholder list was just given.
- [~] The id-vs-`marketplace.json` comparison the issue asks for -- **not built**, see TEST.
- [~] A suite asserting no manifest names a retired id -- **not built**: a consumer who has genuinely
      not migrated must be recordable, so such a test would assert against the register's own doctrine.

#### One thing outside this repo, done and reported rather than asked about

`../life-hub` on this machine was **427 commits behind** with no `.claude/settings.json` and zero lens
files. Fast-forwarded to `origin/main` (`3ca0738` -> `a9aad93`) -- clean tree, no stash, no unpushed
commits, one branch, so a non-destructive FF. That is why it matters here rather than being a footnote:
the check reads the LOCAL checkout, and a clone that exists but is 427 commits stale gives confident
wrong answers where an absent one would honestly `[SKIP]`.

### TEST

`check-connectors.ps1`, before and after -- and the middle column is the one worth reading, because it
is the state this branch briefly created:

| run | result |
|---|---|
| before (retired ids) | `0 error(s)` -- and life-hub's three plugin blocks **skipped entirely** |
| after the rename, stale local clone | **5 `[ERROR]`** -- both plugins "NOT enabled", 24 extensions "missing" |
| after the rename, clone fast-forwarded | `Summary: 0 error(s), 3 info signal(s).` exit 0 |

- [x] All five JSON manifests parse (`ConvertFrom-Json`).
- [x] `check-connectors.ps1`: 0 errors, exit 0. The three remaining lines are `[INFO]` about install
      records on this machine, which the session hook does not surface.
- [x] No suite pins the real register data -- the four consumer names appear in test files only in
      comments -- so nothing else moves.
- [x] Full gate: `check-plugin-integrity.ps1` plus every suite.

#### What the verification changed about the issue -- three corrections

**The size was wrong, and it changes the work.** The issue states the honest count of known-wrong
manifests is **one** and warns explicitly against "scoping the repair to the grep rather than to the
subject". Measured against each consumer's live `.claude/settings.json` through the GitHub API: **all
four** have migrated. Three still named `workflow-davekjohn@`; life-hub named two ids retired 24 days
earlier and did not name its enabled workflow plugin at all. So the sweep the issue warned against is
the correct scope here -- not because a grep matched four files, but because four consumers were
measured. The issue's caution was right in method and wrong in result.

**The stated reason does not survive.** The issue says "nothing compares a manifest's plugin ids against
`.claude-plugin/marketplace.json`" and names that as the gap worth closing. `Get-PluginDir` in
`check-connectors.ps1` does exactly that comparison and has since a few branches before August 9, 2026.
It reports an unpublished id as `[INFO] retired` rather than an error, and that is a **documented
decision** taken that day after this very check produced four false `[ERROR]` lines against life-hub and
smartwatchbanden -- with `connectors/README.md` and `connectors.tests.ps1` both pinning the behaviour,
the latter using `specialists@` as its fixture. Building the proposed check would contradict an asserted
decision and re-open the false-alarm class. So the repair is the data, and only the data.

**And the register unmasked a stale clone.** While the ids were retired, `check-connectors` skipped
life-hub's blocks at the lookup, which meant the local checkout was never read -- so 427 commits of
staleness sat there invisibly, hidden by the same wrong id. Correcting the register is what exposed it.
That is worth recording as a shape: a record that is wrong in a way the tooling tolerates also switches
off every check downstream of it.

### DEPLOY: `fix/register-follows-the-four-migrated-consumers-v1`

The consumer register catches up with reality. `connectors/*.json` records what each consumer HAS, and
per `connectors/README.md` a renamed plugin id is written here only **after** that consumer has
migrated. All four had, and the register had not: `djcylow-react`, `smartwatchbanden` and
`xoxowildhearts` still named `workflow-davekjohn@` after
[#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886) retired it, and `life-hub` still
named `specialists@` and `specialists-lifehub@`, retired in the August 3 reorg -- while its enabled
`contributing-davekjohn@` was not registered at all. Every field was measured against the consumer's own
live `.claude/settings.json` through the GitHub API rather than taken from the report.

Why a stale id is not cosmetic: `check-connectors.ps1` loops over the plugins a manifest lists and, on
an id the marketplace no longer declares, reports `[INFO]` and **skips that plugin's whole block**. So a
registered-but-unresolvable id switches off the version check, the enabled check and the extension
check for that plugin -- the same blind spot `xoxowildhearts.json`'s notes documented on August 21,
which had been measured as emptied and was re-opened five days later by a different route: not an
unregistered plugin this time, but a registered one under a name that no longer resolves.

Nothing new was built, and the TEST section says why in full: the id-vs-marketplace comparison the issue
asks for already exists, and its `[INFO]`-rather-than-`[ERROR]` treatment is a documented decision with
a test pinning it. Correcting the register also exposed a local `../life-hub` checkout 427 commits
behind, which the wrong id had been hiding for 24 days -- fast-forwarded, and the check is green.

For this repo the durable half is the shape rather than the four files: a register entry that is wrong
in a way the tooling deliberately tolerates silently disables every check downstream of it. The
`[INFO]` is right and stays; what has to stay current is the data.

Closes [#978](https://github.com/DaveKJohn/claude-code-specialists/issues/978).

**Score:** 3

#### What makes this deploy extra special

N/A. `connectors/` is this repo's own consumer register -- not plugin payload, and deliberately kept out
of the plugin cache. No consumer receives it or is changed by it.

**Score:** N/A

#### Pull Request

The connector register catches up with four consumers that have all migrated

