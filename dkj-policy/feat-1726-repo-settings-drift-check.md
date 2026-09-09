## feat/1726-repo-settings-drift-check

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Declared expectation in scripts/repo-config.ps1 (Get-ExpectedRepoSettings), comparator scripts/lint/check-repo-settings.ps1, advisory daily workflow .github/workflows/repo-settings.yml. Dave chose the CI-leg-only shape over a SessionStart hook (issue #1726 menu, Sept 9 2026).

#### What the verification changed about the assignment

#1726 is written as a question, and it argues for doing nothing: this repo's no-pre-emptive-fixes rule,
plus *"one occurrence is not a rate."* That premise is the first thing that got checked, and it did not
survive the tree -- there are **three** GitHub-side drifts in eight days, and two had mechanical
consequences rather than only costing a session the wrong sentence:

| drift | detected by | damage |
|---|---|---|
| `bypass_actors` emptied by the org transfer, Sept 2-3 (#1244) | a failing push, a day later | all three direct-on-`main` exceptions dead; folds blocked; branch documents accumulating on the trunk |
| `merge_queue` added Sept 6 (#1499), gone by Sept 9 (#1720) | a measurement nobody scheduled | always-on prose wrong for a stretch nobody can date |
| `allow_auto_merge` live `true` against four records saying `false` | **the first run of the check built here** | latent stale-but-green auto-merge, invisible to ship-pr's 3b guard |

Two more things the verification settled before any code was written. The issue's third proposed home --
a `-Verify` mode on `adopt-merge-queue.ps1` -- is **structurally dead**: that script refuses in the
source repo (`Test-IsWorkflowSourceRepo`, `scripts/task/adopt-merge-queue.ps1:148`), which is where all
three drifts happened. And the field the third drift sits on is a **repo-object flag**, not a ruleset
rule, which is what settled the scope: the declaration covers the whole recorded settings surface
rather than the rule list #1726's title names.

#### What is deliberately NOT in this branch

- **Repairing `allow_auto_merge`.** It is a repo-settings change and therefore Dave's, and it is a
  distinct subject from the missing detector -- filed as
  [#1730](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1730) with both ways out and the
  one-line verification. This branch declares `false` because that is what the tree records; the check
  therefore reports the drift on arrival, which is the intended state until #1730 is decided.
- **A portable mirror.** `shared-scripts-lib.ps1`'s registry is not extended and the check stays
  repo-local. A consumer's answer to this class is their own ruleset with their own values; #1726 asked
  about this repo, and the values already sit behind a seam if it ever does travel.
- **Making the check required.** Self-referential (a check on the ruleset, enforced by that ruleset) and
  it would block every merge on a switch only Dave can flip.

### CREATE

- [x] `Get-ExpectedRepoSettings` in `scripts/repo-config.ps1` -- seven declared facts, each carrying
      `Recorded` (the date the tree's statement was last measured), `Where` (the document stating it) and
      `Why`. Those three are what make a red run actionable rather than merely true.
- [x] `scripts/lint/check-repo-settings.ps1` -- reads `rules/branches/main` and the repo object (no admin
      needed) plus the rulesets detail for `bypass_actors` (admin only), and reports three verdicts:
      match, drift, and **not read**. The third is the point: collapsing it into "match" would make the
      check silent about the one field whose emptying was #1244.
- [x] `.github/workflows/repo-settings.yml` -- daily at 06:30 UTC plus `workflow_dispatch`,
      `contents: read`, no standing credential, not in `main-ci-gate`.
- [x] The variable-collision trap recorded in the portable manual
      (`plugins/dkj-teams/dkj-team-alpha/manuals/05-15-manual.md`) -- it is PowerShell's behaviour, not this
      repo's, so it belongs in the source rather than in a lens. Heading count and the one inbound anchor
      in `.claude/rules/language-layers.md` updated with it.
- [x] Sylvester's lens: the new runner under what he owns, and a line on the ruleset bullet that states
      this gap in prose, saying what the detector does and does not change about those dated blocks.

### TEST

- [x] `scripts/tests/repo-settings-gate.tests.ps1` -- 46 asserts, no live `gh`. Every case feeds the
      three payloads from fixture files, because a suite that let a real read through would go red for
      exactly the reason the check exists to report.
- [x] The suite found two defects before the gates did. An empty live list collapsed to `$null` through
      `Sort-Object`, so the **emptied bypass list -- the #1244 state itself -- printed as `(none)` and
      read as "unset"** rather than as "present and empty"; the comparison had been failing correctly all
      along, so only an assert on the report could have caught it. And `New-Payload` rejected an empty
      `-Json`, which is one of the states under test.
- [x] Verified against the live repo: six declared facts match, one drift reported -- `allow_auto_merge`,
      i.e. #1730, found by the check rather than by a person.
- [x] Lint gate + all suites green.
- [x] Reviewed in parallel by Victor (code), Edith (copy) and Sebastian (security). Nine findings, all
      nine acted on; the four that changed behaviour are worth naming because each was a defect an
      assert would not have found on its own:
      - **`Read-Payload` hand-rolled what `Invoke-NativeCapture` exists to centralise** (Victor). The
        EAP guard was the visible half; the one that mattered was **`-Utf8`** -- 5.1 decodes a native
        child's stdout with the *console* code page, and this output is parsed, so the same `gh api`
        returned different strings on cp65001 and cp850. Inbound #821's class, in a brand-new script.
        Now the same two flags `adopt-merge-queue.ps1` passes against this very endpoint.
      - **`ruleset.required_checks` duplicated `Get-RequiredCheckContexts`** (Victor), minus its
        case-insensitive compare on `type`. Reusing it means this check cannot disagree with the gate
        it describes; `Read-Payload` keeps the raw JSON so the lib can be called at all.
      - **A JSON `null` on a declared boolean silently passed as a match** (Victor). `[bool]$null` is
        `$false`, so a field GitHub never answered compared equal to a declared `false` and printed as
        `[OK] ... = (none)`. Not reachable against the real API, which is exactly why it needed the
        assert rather than the discovery.
      - **A total blackout was green** (Sebastian). If the CI token cannot read those endpoints, every
        field reports not-read and the run exits 0 -- a detector reporting success. His advice was to
        confirm the token empirically on the first run; `-RequireRead` was preferred because that
        covers only the day somebody looks, while the flag holds on every run after it. It stays silent
        on a *partial* read, which is the expected CI state.
      Also: `persist-credentials: false` (Sebastian), and three prose corrections from Edith -- a
      "fifth entry" that should have been fourth, `Where` described as naming a line it does not, and
      a cross-reference to "the two runners above" that pointed at the two bullets which do *not* state
      that reasoning. Sebastian confirmed the unpinned `actions/checkout@v5` is **correct** here rather
      than a gap: this repo pins by SHA where a job's token can *do* something, and `unfolded-entry.yml`
      -- the same `contents: read` class -- is deliberately unpinned too.
- [x] The suite's own strongest assert was the weakest thing in it (Victor): "every declared Field is
      one the check knows how to read" compared against a **hardcoded copy** of `Get-LiveValue`'s
      switch, so it could pass while the script reported `UNKNOWN FIELD` at runtime. It now puts every
      declared Field through the real script, plus a sentinel proving the probe can still fail.
- [~] No assert on the scheduled trigger actually firing. It needs a cron GitHub controls, so the suite
      asserts the workflow's *shape* -- schedule present, dispatch present, `contents: read`, no
      `secrets.`, `-RequireRead` passed, and that it runs this check. Named here rather than papered over.

### DEPLOY: feat/1726-repo-settings-drift-check

A daily CI leg now reports when GitHub-side repo settings drift from what this tree declares -- the
class behind #1720, where `main-ci-gate` gained and lost a `merge_queue` rule with nothing in the repo
recording either event. `Get-ExpectedRepoSettings` in [`../scripts/repo-config.ps1`](../scripts/repo-config.ps1)
declares seven load-bearing facts (the trunk's rules, its required check, `strict`, `allow_auto_merge`,
`allow_update_branch`, visibility, the bypass actor types), each with the document that states it and
the date it was last measured; `scripts/lint/check-repo-settings.ps1` compares them and names which
document to repair when the drift turns out to be deliberate.

Built rather than written down because #1726's own premise -- *"one occurrence is not a rate"* -- turned
out to be wrong: three drifts in eight days, two of them mechanical. The emptied bypass list killed
every fold for a day (#1244) and was found by a failing push; `allow_auto_merge` was found live `true`
against four records saying `false` by this check's first run, and is filed as #1730.

Scheduled rather than a SessionStart hook, on Dave's call: a hook reaches a drift sooner and costs a
`gh api` round trip at every session start, but only a scheduled run leaves a **dated** record -- which
is exactly what #1720 says is missing, since "September 9 is when it was measured, not when it
happened". Advisory and not in `main-ci-gate`, and it writes nothing to GitHub: repo settings stay
Dave's surface. One field, `bypass_actors`, is admin-only and reports as **not read** in CI rather than
as green, because reporting the #1244 field as passing would be the worst possible silence.

**Score:** 3

#### What makes this deploy extra special

N/A -- this is a maintenance-repo detector over this repo's own GitHub settings. Nothing ships to a
consumer: the check is deliberately not mirrored into the plugin, and the one portable half is a
PowerShell trap added to the system-administration manual.

**Score:** N/A

#### Pull Request

A scheduled runner that reports GitHub-side repo settings drifting from what the tree declares
