## fix/1465-register-dkj-policy-id

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

Issue #1465: `connectors/claude-code-specialists.json` still registered the workflow plugin under
`contributing-davekjohn@`, an id retired by the #1437 rename (commit `17149edb`) -- while this repo,
as a consumer, had already migrated. `check-connectors` therefore printed an `[INFO]` whose factual
claim ("this consumer has not migrated to the current names yet") was the opposite of the truth, and
then **skipped the whole plugin block**, so nothing about the workflow plugin was version-checked in
the register of the repo that owns the check.

#### The verification, before the repair

The report was held against the tree first rather than taken at its word -- the six-way pickup check:

- **Symptom** -- reproduced verbatim on `main` at `f8ac7598`: one `[INFO]`, block skipped.
- **Reason** -- `.claude/settings.json` enables `dkj-policy@claude-code-specialists`, and
  `installed_plugins.json` holds a project-scope record for **this** checkout under that id
  (`4.30.0`, commit `ba889a81`) and **none** under the retired one. So the register was
  behind the consumer, which is exactly the "CAUGHT UP" moment the register's own doctrine describes.
- **Repair** -- the empty `extensions` array is the measured answer and not an unfilled one:
  `plugins/workflows/dkj-policy/` ships no `agents/`.
- **Size** -- only this repo's entry is out of step. The other five manifests naming
  `contributing-davekjohn@` are correct per doctrine and are left standing.
- **Subject** and **repo** -- both this repo's own file.

#### One adjacent stale count, fixed inside the assignment rather than filed

The `notes` field's opening sentence said the workflow plugin ships "two session hooks"; it ships
five SessionStart hooks and one Stop hook. It sits in the field being rewritten anyway, so it is
corrected here rather than left standing as a known-false sentence -- and it is corrected by
**dropping** the count, not by restating it. That is the rule `SPECIALISTS.md` already reached: the
same count went stale twice inside two days there, which is why that page stopped listing the set at
all, and each plugin's own `hooks/hooks.json` is the one place that cannot go stale.

### CREATE

- [x] Repoint `connectors/claude-code-specialists.json` from `contributing-davekjohn@` to
      `dkj-policy@claude-code-specialists`, keeping the empty `extensions` array.
- [x] Append a dated `CAUGHT UP 2026-09-05 (#1465)` paragraph to `notes` in the house style --
      what was measured, where, and what the retired name cost -- without rewriting any older dated
      measurement (#952).
- [x] Drop the stale hook count from the opening sentence of `notes` without replacing it with a
      new number.

### TEST

- [x] `check-connectors.ps1` before: one `[INFO]`, plugin block skipped.
      After: `[OK] plugin is enabled in .claude/settings.json`, `[OK] all 0 registered extensions
      present`, `[OK] machine record is on the source version (v4.30.0)` -- the blind spot is closed.
- [x] The manifest parses as JSON (`ConvertFrom-Json`).
- [x] Lint gate + all suites, via `open-pr.ps1`.

### DEPLOY: fix/1465-register-dkj-policy-id

`connectors/claude-code-specialists.json` now registers the workflow plugin under its current id,
`dkj-policy@claude-code-specialists`. It had held `contributing-davekjohn@` since the #1437 rename
while this repo -- as a consumer of its own product -- had already migrated, so `check-connectors`
stated the opposite of the truth and skipped the whole plugin block: for this repo's own entry the
workflow plugin was not version-checked at all. Three `[OK]` lines now stand where one skipped
`[INFO]` did. The `[INFO]` itself is deliberately unchanged, because a consumer catching up is the
repair and making it an error re-opens the four false alarms of August 9, 2026 -- and the five other
manifests still naming the retired id are correct as they stand, since the register records what a
consumer HAS. This is the same blind spot `connectors/xoxowildhearts.json` recorded for the #886
rename, re-opened by #1437 through the identical route: the class was never emptied, only its
instance was. The `notes` field also loses a stale count -- it claimed two session hooks where the
plugin ships five, beside a Stop hook -- dropped rather than renumbered, for the reason
`SPECIALISTS.md` gives for no longer listing that set anywhere.

**Score:** 3

#### What makes this deploy extra special

N/A -- `connectors/` is workshop administration and deliberately does not travel with the plugin
caches, so nothing a consumer installs or reads changes here.

**Score:** N/A

#### Pull Request

Register this repo's own workflow plugin under dkj-policy@, so check-connectors stops skipping the block
