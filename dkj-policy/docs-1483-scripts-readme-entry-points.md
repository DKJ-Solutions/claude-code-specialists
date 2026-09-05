## docs/1483-scripts-readme-entry-points

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

Add the 10 missing entry-point rows to scripts/README.md's table, each with a description and the Skill answer taken from the registry rather than derived by hand, and widen the hook-invoked paragraph to cover park-cycle.ps1 (a Stop hook that acts, where the paragraph currently names only read-only SessionStart checks). Closes #1483.

#### What the re-measurement changed about the plan

Two of #1483's own judgement calls did not survive reading the code, and the rows follow the tree
rather than the report:

- **`release/verify-resolved-issues.ps1` is NOT dot-sourced.** `ship-pr.ps1:1726` starts it as its own
  process (`& powershell ... -File ...`), so the report's reason for possibly leaving it out — that it
  is a lib reached by another script — does not hold. It gets a table row.
- **`release/publish-to-business.ps1` is in no registry**, being repo-local rather than shared. #1483
  flagged that case as unmeasured. Its documenting page is the `cut-release` skill, Block 3.
- **The registry function is `Get-SharedScriptPairs`, with a mandatory `-RepoRoot`.** #1483 named
  `Get-SharedScripts`, which does not exist.

### CREATE

- [x] Re-measure the 11 missing filenames against the current trunk — same 11, unchanged.
- [x] Ask `Get-SharedScriptPairs` for each one's `Skill` rather than deriving it by hand; 10 of 11
      answered, `publish-to-business` resolved from the `cut-release` skill instead.
- [x] Add 10 rows to `scripts/README.md`'s table, placed in lifecycle order around the existing rows
      (pure insertions — no existing row moved).
- [x] Widen the paragraph below the table from four hook-invoked scripts to five, splitting it into
      the four read-only SessionStart checks and `task/park-cycle.ps1`, which the `cycle-autopark`
      **Stop** hook runs and which *acts* rather than reports.
- [x] Repair the table's intro sentence, which claimed everything unlisted is "a lib, a generator or a
      test" — the hook-invoked five are none of those, so the sentence contradicted the paragraph
      directly beneath it.
- [x] Point the sibling page's *"tracked separately"* claim at a real issue (#1486), filed after
      measuring that table at **21 rows short** of its own registry.

### TEST

- [x] `Get-SharedScriptPairs` consulted for every Skill cell, so no cell is hand-derived.
- [x] Every added path checked to exist on disk before it was linked.
- [x] The lint gate (dead links, manifests, frontmatter) and all suites via `open-pr.ps1`.

### DEPLOY: docs/1483-scripts-readme-entry-points

`scripts/README.md`'s entry-point table was **10 rows short** and carried no warning that it might be,
so a reader took it as the complete set of what a person or a specialist invokes here. Absent from it
were `claim-issue`, `worktree-lane`, `prune-merged`, `adopt-workflow-folder`, `adopt-shopify-floor`,
`check-policy-drift`, `push-preview`, `sync-main`, `verify-resolved-issues` and `publish-to-business`
— several of them with a skill page of their own, and one of them the step the workflow says runs
before anything else. Each Skill cell was answered by `Get-SharedScriptPairs` rather than derived by
hand, which is the shape the page's own sibling names as the one that goes stale.

The paragraph under the table said **four** scripts are reached by a hook and described them all as
read-only SessionStart checks. `task/park-cycle.ps1` is a fifth, and it is the one that writes: the
`cycle-autopark` Stop hook runs it to push the branch's development document to origin. It is now
named there as the automatic half of parking, opposite `task/park-branch.ps1` in the table as the half
a person invokes — which is why it is not a table row. The table's intro sentence was repaired in the
same pass: it claimed everything unlisted is a lib, a generator or a test, which the paragraph
immediately below it contradicted.

**Score:** 3

#### What makes this deploy extra special

The sibling page in the plugin — the one a consumer receives — said its own missing rows were "tracked
separately" with nothing behind the claim. Measured against the registry it is **21 rows short**, so
the sentence now names [#1486](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1486)
and the count. A consumer reading that page gets a number and a thread instead of a promise; the 21
rows themselves are that issue's work, not this branch's.

**Score:** 1

#### Pull Request

scripts/README.md's entry-point table names every script a person invokes

