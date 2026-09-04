## feat/1389-retired-doc-name-check

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

#### What this closes, and why the shape is already decided

[#1389](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1389): a renamed convention
reaches a consumer through nothing. The branch document was renamed twice on September 3, 2026 --
`development.md` -> `development-<slug>.md` ([#1255](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1255))
-> `<slug>.md` ([#1335](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1335)) -- and
both BWJ consumers still restate the retired single `development.md` in their own always-on documents.
No gate reads a consumer's `CLAUDE.md`; `check-script-contract.ps1` covers functions, not conventions.

**The design question is not open.** The prose-contract framework
([#1380](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1380)) was measured and
declined at 12.5% precision, and that decline recorded the alternative that IS proportionate, in
[Sylvester's lens](../.claude/specialists/lenses/05-15-extension.md):

> one [grep] for the literal string `development.md` outside the changelog and history paths

This branch builds that one grep, and only that one. The supremacy-declaration grep the same paragraph
names is the other half and is not this branch's subject.

#### Three things the decline requires of it, so it is not the declined check wearing a new name

1. **Literal, not fuzzy.** The subject is an exact filename, so the test is a string comparison with a
   mechanical answer -- the same distinction that separates this repo's accepted link check (17
   findings, 17 real) from its declined stale-path check (124 findings, none real).
2. **The source-repo guard.** This repo's own pages narrate the rename history correctly
   (`CLAUDE.md`, the release lens), so without the guard the source reads as consumer drift.
   Plugin-shipped payload is excluded for the mirror-image reason: Chris's persona is `@`-imported from
   the marketplace clone by all three repos, so it is one file, not three findings.
3. **No hand-maintained list.** The retired names come from `Get-BranchFilePaths`, the one table that
   already grows by one row per rename -- the same call `Resolve-BranchFilePath` gets, and the reason
   the fold's bound is named by its resolver rather than spelled out.

#### The document set is the #1380 corpus, not the tree

The always-on closure (`Get-AlwaysOnDocuments` from `CLAUDE.md`) plus the workflow folder's own
consumer pages. `CHANGELOG.md` and `releases/` are OUT: archived entries correctly name the retired
file, and a check without that exclusion is born red on its own past -- which this repo already names
as a smell in itself. Stated as an inclusion list rather than an exclusion list, so it cannot go stale
against a folder that grows.

### CREATE

- [x] `Get-RetiredBranchDocNames` in `scripts/lib/entry-scaffold-lib.ps1`: the literal prose tokens for
      every retired name of the branch document and the retired folder, derived from
      `Get-BranchFilePaths` so the next rename adds nothing by hand.
- [x] `Get-RetiredDocNameMention` in the same lib: the one definition of "a consumer document restates a
      retired name" -- the document set, the source-repo skip, the external exclusion, and the scan.
- [x] `scripts/lint/check-retired-doc-name.ps1`: the check, adding no rule of its own, on
      `check-unfolded-entry.ps1`'s shape (dual-context root, optional `repo-config.ps1`, `-RootOverride`).
- [x] `plugins/workflows/contributing-davekjohn/hooks/retired-doc-name-sessioncheck.ps1` + its
      `hooks.json` entry: soft, `[ERROR]`-only, always exit 0, matcher `startup|resume|clear|compact`.
- [x] Register the pair in `scripts/lib/shared-scripts-lib.ps1` and rebuild the mirror with
      `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] `scripts/tests/retired-doc-name-gate.tests.ps1`: fixture consumers for a clean tree, each measured
      instance's shape, the changelog exclusion, the source-repo skip, the external exclusion, and the
      hook's exit-0 contract.
- [x] Add the check to the no-guard list in `scripts/tests/source-repo-guard.tests.ps1`, with its reason.
- [x] The full local gate: `check-plugin-integrity.ps1` + every suite.
- [x] Measure what the sixth SessionStart hook costs, and record the figure rather than assume it.

### DEPLOY: feat/1389-retired-doc-name-check

A renamed convention now reaches a consumer through something. This workflow's branch document has been
renamed seven times, twice inside one day, and the tooling around it was deliberately built rename-proof
-- every reader goes through `Resolve-BranchFilePath`, and the fold's bound is named by that resolver
rather than spelled out. The prose describing the convention to consumers was not: no gate reads a
consumer's `CLAUDE.md`, and `check-script-contract.ps1` covers *functions*, so a renamed file convention
sat outside it by construction. Measured -- both live consumers were still stating the retired single
`development.md` as current, one day and six days after the rename, and no mechanism existed by which
either could have found out.

`check-retired-doc-name.ps1` closes it, driven by a new `retired-doc-name-sessioncheck` SessionStart
hook, which is the whole delivery -- there is no CI half, because in the one repo whose CI this repo
controls the check skips itself. It greps the always-on document closure plus the workflow folder's own
permanent pages for every name the branch document has been renamed *away from*, and names the document,
the line and the retired name.

**The design question was not open, and staying inside its bounds is the point.** The prose-contract
framework was measured at 12.5% precision and declined the same day; that decline recorded two narrow
literal greps as the proportionate alternative, and this is the first of them, held to the three
constraints the decline imposed. The names are **derived** from `Get-BranchFileLegacyNames`, so the next
rename adds this token by the same row it always adds. The corpus is an **inclusion** list with the
changelog and `releases/` out, because a folded entry correctly names the file of its own day and a check
that read it would be born red on its own past. And it **skips the publishing repo**, on the source-repo
guard's own condition 2, for the reason that measurement found the hard way: this repo narrates the
rename history on purpose, so without the skip the source reads as consumer drift. One gap is stated
rather than left to be rediscovered -- `development-<branch>.md` is a shape, not a literal, and matching
a shape is the step toward fuzzy the decline rules out.

Along the way the hook enumerations were retired instead of extended. Four documents named the
SessionStart set by hand as "two" or "three"; each had already gone stale twice inside two days, and this
change would have made all four wronger. They now point at each plugin's `hooks/hooks.json`, the one
place that cannot go stale.

**Score:** 3

#### What makes this deploy extra special

This is the only thing that will ever tell a consuming repo that a shared convention moved under its own
documentation. The failure it ends is silent by construction: a restatement is correct on the day it is
written and becomes a lie on the day the plugin's answer changes, and until now the plugin had no way of
saying so -- noticing required reading a repo the source never reads. Measured at 365 ms through the
hook, which makes it the cheapest of the session checks rather than a sixth tax, and it never blocks
anything.

`CONTRIBUTING-portable.md` gains the paragraph that tells you what the hook means when it fires and what
the repair is, beside the corollary it enforces: a consumer document may point at a shared law, answer a
seam the law names, or say nothing.

**Score:** 3

#### Pull Request

A consumer-side check for retired branch-document names
