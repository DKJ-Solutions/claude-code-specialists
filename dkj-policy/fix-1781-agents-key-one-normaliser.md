## fix/1781-agents-key-one-normaliser

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

#### Where this branch stands

The finding was verified against the tree before any of it was built, and one thing had moved: the
second of the two copies was not on the trunk when #1781 was picked up. `Get-DeclaredAgentCount` lived
only on `fix/1771-plugin-details-agent-count`, whose PR #1788 was still open, so a branch cut here would
have touched `scripts/lib/measure-skill-lib.ps1` and conflicted with it -- and a conflicting PR in this
repo gets no check suite at all, so it could never have merged. This branch was cut after #1788 landed,
which is why both copies are real here.

### CREATE

- [x] `Get-ManifestAgentEntries` added to [`../scripts/lib/plugin-tree-lib.ps1`](../scripts/lib/plugin-tree-lib.ps1) --
      pure, takes the parsed manifest, returns an array. Absent key, explicit `null`, empty array and an
      unparseable manifest (`$null`) all come back as an empty set; a bare string comes back as ONE entry.
- [x] Check 38 `[agents-key]` in [`../scripts/lint/check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1)
      reads through it instead of its own `-is [string]` expression.
- [x] `Get-DeclaredAgentCount` in [`../scripts/lib/measure-skill-lib.ps1`](../scripts/lib/measure-skill-lib.ps1)
      counts what that function returns. It dot-sources `plugin-tree-lib.ps1`, which is safe in a consumer
      because both libs are registered `LibOnly` under the SAME plugin (`dkj-policy`) and land in the same
      mirror directory -- checked in the registry rather than assumed.
- [x] Both plugin mirrors rebuilt with `scripts/sync/build-shared-scripts.ps1` -- the drift lint caught
      them, which is the gate doing its job.

### TEST

- [x] `release-lib.tests.ps1` -- 15 new asserts over `Get-ManifestAgentEntries`: every form the installer
      accepts, the three ways *"declares none"* arrives, and the entries a caller must be able to REFUSE
      (an empty string and a number are handed back, never filtered, or the gate would silently pass the
      manifest whose plugin the installer then refuses to install).
- [x] One of them runs under `Set-StrictMode -Version Latest`, because that is the mode check 38's own
      script sets and the only thing that actually proves the property probe. The happy-path assert proves
      nothing about the keyless case.
- [x] The structural half, asserted on source text after `git-porcelain-lib.tests.ps1`'s shape (#1682):
      both callers name the shared function, neither still carries its own reading, and the normaliser
      holds exactly one such reading -- so a third caller cannot quietly reintroduce the pattern.
- [x] `measure-skill.tests.ps1` -- 92 pass, 0 fail, unchanged. Its existing `Get-DeclaredAgentCount`
      asserts (bare string is 1, keyless is 0, unparseable is not `Found`) now run through the shared
      reading and still hold, which is the evidence that this refactor changed no behaviour.
- [x] `check-plugin-integrity-docs.tests.ps1` -- green, check 38's own scenario included.
- [x] The full gate -- `0 error(s)`; `[agents-key]` reads 6 plugins and all 26 entries, 0 findings.

### DEPLOY: fix/1781-agents-key-one-normaliser

The manifest's `agents` key has one reader. It is `string|string[]`, a bare string being one entry, and
two scripts each carried their own reading of it: check 38 `[agents-key]` in `check-plugin-integrity.ps1`,
normalising to a list in order to validate each element, and `Get-DeclaredAgentCount` in
`measure-skill-lib.ps1`, normalising to a count. Both now call `Get-ManifestAgentEntries` in
`plugin-tree-lib.ps1` -- the lib built to end exactly this, one layer up, when five separate copies each
encoded their own idea of where a plugin lives.

Nothing behaves differently today, and the point is that it cannot start to. The two copies agreed and
both were asserted, so what was unguarded was that they could not DISAGREE: if the installer ever accepts
a third form, one copy learns it and the other does not, and the failure is silent in opposite directions
-- the gate passes a manifest it should refuse, or `measure-skill` reports an agent count that is not the
plugin's. The guard against the copies returning is structural rather than a convention: the suite asserts
on source text that neither caller carries its own reading and that the normaliser holds exactly one.

**Score:** 1

#### What makes this deploy extra special

Both libs travel in the `dkj-policy` mirror, so a consumer receives the refactor -- but no behaviour
changes for them: every existing assert holds unmodified. Nothing to notice.

**Score:** N/A

#### Pull Request

One reading of the manifest 'agents' key, shared by check 38 and measure-skill-lib
