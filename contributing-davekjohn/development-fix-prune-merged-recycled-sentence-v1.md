## Development: `fix/prune-merged-recycled-sentence-v1` · 20260903-141714

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

Issue #1296. `prune-merged.ps1`'s `Get-MergedProof` returns `'recycled'` whenever the branch
name is in the merged-PR map (`Test-MergedPrNameKnown`, a bare `ContainsKey`) while the tip is
not one that map merged (`Test-RefMergedByPr` false). The two kept-branch sentences it prints
(the local pass and the `-IncludeRemote` pass) then assert **the name was recycled** as the
cause -- and the remote one additionally asserts **so this head is live work**. Both are false
for a branch that simply took a commit after its own PR merged (and the local one is also false
for an unreadable tip, which the docstring already admits). The fix is wording only: state what
was measured, offer the causes without picking one. Token `'recycled'` stays (renaming it is a
bigger change than the sentence, per the issue).

### CREATE

- [x] `scripts/task/prune-merged.ps1`: reword the two kept sentences (local + remote pass) to
      name the measurement, not a cause; align the `Get-MergedProof` docstring and the two inline
      comments that carry the same "belonged to somebody else's work" overclaim.
- [x] `plugins/workflows/contributing-davekjohn/skills/prune-merged/SKILL.md`: update the quoted
      sentence to match.
- [x] Regenerate the plugin mirror (`scripts/sync/build-shared-scripts.ps1`).

### TEST

- [x] `scripts/tests/prune-merged.tests.ps1`: two assertions match `'the name was recycled'`
      (cases o and q) -- repoint them at a stable substring of the new wording.
- [x] `scripts/lint/check-plugin-integrity.ps1` + all suites green (via `open-pr.ps1`).

### DEPLOY: `fix/prune-merged-recycled-sentence-v1`

`prune-merged`'s kept-branch reason no longer claims a recycled name it never checked for. When a
branch is kept because its name is in the merged set but its tip is not, the message now names
what was measured -- "a merged PR used this name, but not this commit" -- and offers a recycled
name or a post-merge commit as the possible causes, instead of asserting the first and (in the
remote pass) calling the head "live work". Wording only; the refusal to delete is unchanged.

**Score:** 3

#### What makes this deploy extra special

A consumer running `prune-merged -IncludeRemote` gets a kept-head reason that is actionable
instead of one that sends them hunting for a recycled name that may not exist.

**Score:** 2

#### Pull Request

prune-merged names what it measured instead of asserting a recycled name

