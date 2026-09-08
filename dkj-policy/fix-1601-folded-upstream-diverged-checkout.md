## fix/1601-folded-upstream-diverged-checkout

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

#### The state issue #1601 named

`check-unfolded-entry.ps1` asks, of every leftover development document on the trunk, whether its
fold has ALREADY landed on origin -- so a checkout that is merely BEHIND is told to pull rather than
accused of a skipped fold (#1585). Since #1585 it answered that with `git cat-file -e
<ref>:<document>`: the fold REMOVES the document and ADDS the entry in one commit, so absence upstream
is the fold's signature. Absence has other causes, which #1585 fenced off with a gap gate -- ask only
when `Get-TrunkGap -NoFetch` reports a non-zero gap.

**A gap is not a direction.** `HEAD..origin/<trunk>` is non-zero in a DIVERGED state too, and there a
document committed locally and never pushed is also absent on origin. The report then reads `[WARN]
... ALREADY been folded`, exit 0, with `git pull --ff-only` as the remedy -- a pull that cannot
fast-forward, about a fold that is still owed.

#### Verified before it was repaired, because the issue said it never had been

#1601 states it as inferred from the code, not measured. Reproduced on a fixture one commit ahead and
one behind before anything was changed: `[WARN] 1 development document(s) here have ALREADY been
folded on refs/remotes/origin/main -- this checkout is 1 commit(s) behind`, exit 0.

#### The repair, which is the one the issue named

A lib function beside `Get-UnfoldedTrunkEntry` answering "is this branch already folded on `<ref>`",
read off `CHANGELOG.md` at that ref through the existing folded-heading definition, with the check
calling it instead of `git cat-file -e`. Building the heading match inside the check would have put a
second definition of "what a folded entry looks like in the changelog" beside
`Get-FoldedEntryForBranch` -- the drift `Get-UnfoldedTrunkEntry` exists to prevent for the sibling
question, and the reason #1585 named this state instead of guarding it.

### CREATE

- [x] `Test-BranchFoldedOnRef` in `scripts/lib/entry-scaffold-lib.ps1`, beside `Get-UnfoldedTrunkEntry`
      -- `git show <ref>:<changelog>` through `Get-FoldedEntryForBranch`, returning `$true` / `$false` /
      `$null` for a question it could not ask
- [x] `check-unfolded-entry.ps1` classifies with it instead of `git cat-file -e`, and the gap gate goes
      -- the entry's presence has one cause whichever way the checkout drifted, so the gate was
      sufficient and never necessary. `Get-TrunkGap` is still run: a reader who is behind is still told
      so, and it names the ref the changelog is read at
- [x] the `Get-ChangelogPath` seam is read (guarded `seam-lib.ps1` + `Get-SeamValue`), so a repo that
      folds somewhere other than `<workflow folder>/CHANGELOG.md` is asked about its own file
- [x] both report arms stop implying a gap they no longer measure -- the `[WARN]` headline states the
      behind-count only when there is one, and where there is none it names what is actually true (the
      fold would refuse the document as a duplicate, inbound #1082) rather than prescribing a pull
- [x] the plugin mirror rebuilt (`scripts/sync/build-shared-scripts.ps1`)

### TEST

- [x] the pre-repair reproduction re-run against the repair: `[ERROR]`, exit 1, the fold named
- [x] `Push-UpstreamFold` in `scripts/tests/unfolded-entry-gate.tests.ps1` now models a WHOLE fold
      commit -- it wrote only the deletion, which was half of one. That was enough while the check
      asked whether the document was gone; it is not enough now that the check asks whether the entry
      is there. The heading comes from `Format-BranchFileHeadingLine`, the formatter the fold itself
      uses, never a literal in the suite
- [x] every tree gets a `CHANGELOG.md`, so a stranded document is reported because the entry is absent
      rather than because the file is
- [x] a DIVERGED fixture (`Push-UpstreamUnrelated` + a local-only commit): ahead 1, behind 1, `[ERROR]`
      exit 1, and never `ALREADY been folded`
- [x] six direct cases on `Test-BranchFoldedOnRef` -- `$true`, `$false`, and `$null` for each of the
      three questions it cannot ask, plus a prefix of the folded branch not answering for it
- [x] `unfolded-entry-gate.tests.ps1`: 28 asserts, all passing
- [x] `check-plugin-integrity.ps1`: 0 errors; the full suite gate green

### DEPLOY: fix/1601-folded-upstream-diverged-checkout

`check-unfolded-entry.ps1` told a checkout that is both ahead of and behind `origin/<trunk>` that its
unfolded entry had already been folded upstream, and sent it at a `git pull --ff-only` that cannot
fast-forward. The fold was still owed. It now asks whether the branch's entry is present in
`CHANGELOG.md` on the remote-tracking ref -- the other half of the same fold commit -- through
`Test-BranchFoldedOnRef`, a new function in `entry-scaffold-lib.ps1` that reads the changelog at that
ref via the existing `Get-FoldedEntryForBranch` rather than defining a second idea of what a folded
entry looks like. The entry's presence has exactly one cause whichever way a checkout has drifted, so
the gap gate #1585 needed is gone: it was sufficient, never necessary. Nothing changes in CI or for a
checkout that is merely behind.

**Score:** 2

#### What makes this deploy extra special

The repair is the one #1601 itself named, down to the function's place in the tree -- and the reason
#1585 named the state instead of guarding it (a second definition of a folded entry) is what shaped
it: the match stays in the lib, beside the definition it must not disagree with.

The fixture is the part worth reading. `Push-UpstreamFold` had written only the deletion half of the
fold commit, which was invisible while the check asked about that same half; the moment the check
asked the other question, the suite could no longer answer it. A fixture that models half a commit
proves nothing about the other half, and this one had been passing for exactly as long as the check
was looking the same way it was.

**Score:** 1

#### Pull Request

Read the entry on the ref, not the absent document, in check-unfolded-entry
