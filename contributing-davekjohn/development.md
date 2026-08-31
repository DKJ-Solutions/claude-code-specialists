## Development: `feat/workflow-bwj-plugin-v1` · 20260831-163808

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

- [x] Verified the workflow-plugin conventions against `plugins/workflows/README.md` and
  `plugins/workflows/contributing-davekjohn/README.md`: a workflow lives in `plugins/workflows/`,
  carries no `agents/`/`manuals/`, and `workflow-*` keeps lint check 23's directory teeth on.
- [x] Verified `cut-release.ps1` derives its plugin set from `marketplace.json` via
  `scripts/lib/plugin-tree-lib.ps1`, so a new plugin at the lockstep version joins the bump with no
  script change.
- [x] Verified `Get-SharedScriptPairs` (`scripts/lib/shared-scripts-lib.ps1`) is a hand-maintained
  registry, every entry `contributing-davekjohn` -- an unregistered plugin script is not held to the
  mirror, so `workflow-bwj` can be self-contained.
- [x] Verified both marketplace-wide skill-enumeration spans in `README.md` (check 10) list every
  skill by backticked name -- the two new skills must be added to both.
- [x] Design approved by Dave: name `workflow-bwj`, additive add-on to `contributing-davekjohn`
  (ticket-work layer only), close->resolve via GitHub Actions + a daily reconciliation sweep.

#### Decisions this branch does not make

- One shared Asana project for both stores vs. one per store -- deferred to consumer adoption;
  `Get-AsanaProjectGid` returns whatever each repo sets.
- Connector registration in `connectors/smartwatchbanden.json` / `xoxowildhearts.json` -- deferred
  until each consumer's own `.claude/settings.json` PR merges; tracked as a follow-up issue.

### CREATE

- [x] `plugins/workflows/workflow-bwj/.claude-plugin/plugin.json` -- manifest at version 4.27.0.
- [x] `plugins/workflows/workflow-bwj/README.md` -- plugin-level README with a `skills:plugin` span.
- [x] `plugins/workflows/workflow-bwj/WORKFLOW-portable.md` -- the rule in prose.
- [x] `plugins/workflows/workflow-bwj/skills/report-issue/SKILL.md` -- the create side.
- [x] `plugins/workflows/workflow-bwj/skills/adopt-bwj-asana/SKILL.md` -- one-time consumer setup.
- [x] `plugins/workflows/workflow-bwj/templates/asana-mirror.yml` + `asana-mirror.ps1` -- the CI
  mechanism to copy into a consumer's `.github/`.
- [x] `.claude-plugin/marketplace.json` -- add the `workflow-bwj` entry; top-line description eased
  off "exactly one workflow".
- [x] `README.md` -- both skill-enumeration spans, the plugin table row, and the two-workflows prose.
- [x] `plugins/workflows/README.md` -- the table row and the coexistence prose.
- [x] `plugins/workflows/contributing-davekjohn/README.md` + `CONTRIBUTING-portable.md` -- the
  cross-references from the base workflow's side.
- [x] `scripts/tests/workflow-bwj.tests.ps1` -- plugin/skill/template + asana-mirror helper coverage.
  No fixture count needed adjusting (`check-plugin-integrity` derives its plugin set at runtime).

### TEST

- [x] `check-plugin-integrity.ps1` run locally -- 0 errors; `[skill-list]` now checks 24 canonical
  skills and `[plugin-kind]` checks 6 plugins, both green.
- [x] `scripts/tests/workflow-bwj.tests.ps1` run -- 30 asserts pass: `closed` -> `completed:true`,
  `reopened` -> `completed:false`, `Get-IssueRefFromNotes` parses `owner/repo#n` for the reconcile
  sweep, and a non-numeric `asana-task` marker is rejected before any request URL is built.
- [~] Full `scripts/tests/*.tests.ps1` -- not hand-run as an outcome here (see
  [#1060](https://github.com/DaveKJohn/claude-code-specialists/issues/1060)): `open-pr` and CI's
  `lint-en-tests` run the whole gate under their own power before the push, and this branch adds a
  new suite plus a runtime-derived plugin set, so nothing existing is bypassed.

### DEPLOY: `feat/workflow-bwj-plugin-v1`

A new opt-in workflow plugin, [`workflow-bwj`](../plugins/workflows/workflow-bwj/README.md), lands in
[`plugins/workflows/`](../plugins/workflows/README.md) beside `contributing-davekjohn`. It packages
one rule for BWJ's two Shopify store repos (`smartwatchbanden` and `xoxowildhearts`) so they cannot
drift on it: a discovered issue is filed on **GitHub first** (source of truth, the `team-alpha`
filing bar unchanged), then mirrored to **Asana** as a colleague-facing variant on a fixed
plain-language skeleton, cross-linked both ways with a machine-readable
`<!-- asana-task: <gid> -->` marker on the issue. Closing the GitHub issue **resolves the Asana task
automatically** via `templates/asana-mirror.yml` + `asana-mirror.ps1`, a GitHub Actions workflow each
repo copies into its own `.github/` (reopen un-resolves; a daily sweep repairs missed events). Two
skills: `report-issue` (the create side, over `gh` + the Asana MCP) and `adopt-bwj-asana` (one-time
consumer setup). No specialists, no hooks.

It is an **additive** workflow -- it extends only the ticket-work step and decides nothing about
branch naming, the pre-PR bar, or releases -- so it is the first deliberate answer to the
"second workflow" note left after
[#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886). `marketplace.json`, both
skill-enumeration spans and the plugin table in [`README.md`](../README.md), the workflows README and
`contributing-davekjohn`'s own README + `CONTRIBUTING-portable.md` are updated to record that reading.
`requires` `team-alpha` and `contributing-davekjohn`.

**Not in this branch, by design:** connector registration in
[`connectors/`](../connectors/README.md) (waits for each consumer's own settings PR to merge) and the
consumer-side adoption (their repos, their PRs). The one-vs-two Asana projects question is
`Get-AsanaProjectGid`'s to answer per repo.

**Score:** 2 -- a new shared, opt-in capability. It reaches the two BWJ store repos as one
drift-proof ticket procedure with automatic Asana resolution, noticed the first time a maintainer
there files an issue after adopting it; nothing changes in any repo until that adoption PR and its
`ASANA_PAT` secret land. In this source repo it is one more marketplace plugin.

#### What makes this deploy extra special

**Score:** N/A -- workflow tooling for two internal store repos; it never reaches a store's
customer, and it is not enabled anywhere on merge.

#### Pull Request

Add the workflow-bwj plugin: shared Asana-ticket handling for the two BWJ Shopify stores

