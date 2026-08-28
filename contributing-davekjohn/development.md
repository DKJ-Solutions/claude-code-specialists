## Development: `fix/entry-links-die-at-the-cut-v1` · 20260828-232120

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

Inbound [#1047](https://github.com/DaveKJohn/claude-code-specialists/issues/1047): no relative markdown
link in an entry can satisfy both the PR gate and the release cut once a repo's changelog is isolated.

The report offers two repairs as alternatives. Verified against the tree: they are not alternatives, and
one of them is not a repair at all.

- **Teaching the gate to accept root-relative is not available.** The fold copies the entry text
  *verbatim* into `CHANGELOG.md`, so that file's directory *is* the base. Accepting root-relative would
  accept links that are dead in the changelog itself — the first and most-read destination. The gate is
  right; the cut carries the stale assumption.
- **And rebasing the prefix alone is not enough.** `Convert-RootRelativeLinks` exempted `../`, which is
  now the ordinary form for any target outside the workflow folder — and the form the gate itself hands
  the author, since `Get-PathRelativeToDirectory` emits it. So the cut skipped precisely the links the
  gate had dictated. Measured: `../scripts/lint/check-plugin-integrity.ps1` already sits in
  `CHANGELOG.md` and would have died at the next cut regardless of the base.

### CREATE

- [x] `Convert-RootRelativeLinks` → `Convert-EntryRelativeLinks`: base is the changelog's directory,
      and `../` is rewritten. Renamed because the old name asserted the base that stopped being true.
- [x] `Get-EntryLinkPrefix` added, so the two `cut-release.ps1` call sites derive the offset through one
      owner instead of counting to the repo root separately and identically wrongly.
- [x] `Get-RelativeLinkPath -To` accepts an empty destination — the repo root, which is what a consumer
      that never moved its changelog answers.
- [x] Both `cut-release.ps1` derivations repointed; the plugin mirror rebuilt via `build-shared-scripts.ps1`.

### TEST

- [x] `release-lib.tests.ps1`: `../` rewriting, the empty prefix, and five `Get-EntryLinkPrefix` cases —
      including the byte-for-byte identity with the retired depth count for a root changelog.
- [x] `cut-release-guardrail.tests.ps1`: both call sites pinned on the shared helper by name, plus a
      negative assert that neither rebuilds the repo-root depth.
- [x] End-to-end probe on the three link forms actually pending in `CHANGELOG.md`: all three dead before,
      all three resolving after.
- [x] Full lint + test gate green.

### DEPLOY: `fix/entry-links-die-at-the-cut-v1`

Since the changelog moved into `contributing-davekjohn/`, no relative markdown link in an entry could
survive both hops it has to make. `open-pr`'s link gate judges a link from the changelog's own directory —
correctly, because the fold copies the entry text there verbatim — while the release cut rebased it as
though it had been written against the repo root, one directory too far. The form the gate demanded landed
in the tagged release record pointing at a root `CONTRIBUTING.md` this repo does not have; the form that
survived the cut was refused before the PR could open. The measured workaround was to write no relative
links at all.

The cut now measures from the changelog. `Convert-RootRelativeLinks` is `Convert-EntryRelativeLinks` —
renamed because its old name asserted the base that had stopped being true — and both `cut-release.ps1`
derivations ask one shared `Get-EntryLinkPrefix` instead of counting their own segments back to the root.

And `../` is rewritten now, which is the half the report did not see. It was exempt from the day the
rewriter existed, on the reasoning that a link already climbing out of a directory had been aimed by hand.
With an isolated changelog that stopped being the exception: `../` is the ordinary form for every target
outside the workflow folder, and the one `Get-PathRelativeToDirectory` hands the author when the gate
refuses something. The cut was silently skipping exactly the links the gate had just dictated.

A repo whose changelog is still at the root gets the retired answer byte for byte, which is asserted rather
than argued — so nothing changes for a consumer that never moved it.

**Score:** 4

#### What makes this deploy extra special

Every consumer running an isolated changelog is in this: their entries either carry links that die in the
release record, or — the measured outcome — carry no relative links at all, because that is the only way
past both gates. Nothing errors when a link dies; a reader finds it inside a tagged, immutable document.
The repair arrives with the plugin update and needs no change on their side.

**Score:** 4

#### Pull Request

The cut rebases entry links from the changelog's directory, and ../ links with them

