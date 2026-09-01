## Development: `docs/sync-seam-grep-dialect-scripts-v1` · 20260901-214202

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

#### The found set is fixed

Issue #1206 names three sites and says so in as many words: treat them as the found set. Its own
sweep confirmed which `--grep` mentions are correct -- the historical account of #801 and #819 in
`sync-rules.ps1`, `sync-main.ps1`, `sync-rules.tests.ps1` and the archived release notes -- and this
branch leaves every one of them alone. Verified again here before editing.

The wording follows PR #1207 (issue #1205, the prose layer of the same mislabel), which is open on
`docs/sync-seam-grep-dialect-v1`. Different files, no overlap.

### CREATE

- [x] `scripts/lib/sync-rules.ps1` -- the `.SYNOPSIS` of `Get-SyncDefaultReferencePattern` names the
      subject match and the .NET dialect, so it no longer contradicts line 90 of its own docstring
- [x] `scripts/task/sync-main.ps1` -- the seam list in the header does the same, so it no longer
      contradicts line 30 of the same header
- [x] `scripts/task/adopt-shopify-floor.ps1` -- the comment block the script WRITES into a consumer's
      `scripts/repo-config.ps1`, reflowed at its existing column
- [x] All three copied to their `plugins/teams/team-shopify/` mirrors, which were byte-identical
      before and are byte-identical after

### TEST

- [x] `check-plugin-integrity.ps1` green, drift lint included
- [x] All suites green
- [x] The rendered comment block re-read as a consumer sees it, and the whole tree swept for a
      remaining `--grep` mislabel: only the correct historical mentions are left

### DEPLOY: `docs/sync-seam-grep-dialect-scripts-v1`

Three script sites called `Get-ShopifySyncReferencePattern` *"the `--grep` pattern"*. The lookup it
feeds has not used `--grep` since inbound #819 -- the pattern is matched against the commit
**subject** read as its own field, which makes it a .NET regex rather than git's own POSIX basic one.
All three now say that, and each is applied twice because every one of the files is mirrored into
`plugins/teams/team-shopify/`.

Two of the three were contradicting a statement in their own file: `sync-rules.ps1` said `--grep` in
the `.SYNOPSIS` of `Get-SyncDefaultReferencePattern` and the opposite twenty-three lines below it,
and `sync-main.ps1` said it in the seam list of its header and the opposite a hundred lines above.
A reader who got as far as the long note was corrected; one who read only the summary line was not.

The third has the longest reach and is not documentation about the seam at all -- it is the comment
`adopt-shopify-floor.ps1` stamps into a consumer's own `scripts/repo-config.ps1`, at the moment they
sit down to answer the seam, and it is the only one of the three visible without opening this repo.

The label decides which dialect a consumer writes their pattern in, and a pattern valid in one and
not the other fails as a floor that is silently too recent -- the failure the surrounding docstrings
spend the most words on. Issue #1206; the prose layer of the same mislabel is #1205 / PR #1207.

**Score:** 2

#### What makes this deploy extra special

A consumer answering `Get-ShopifySyncReferencePattern` reads the right regex dialect in the comment
their own config file carries. Nothing they have already answered changes meaning, and no behaviour
moves -- what changes is that the instruction beside the question is no longer wrong about the
engine it is judged in.

**Score:** 2

#### Pull Request

the three script sites name the subject match and its regex dialect instead of `--grep`

