## fix/1734-guard-live-theme-uses-command-guard-lib

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
### PLAN

#### What #1734 asked for, and what had to be checked before it could be done

#1669 extracted the false-positive machinery out of `guard-live-theme.ps1` into
`command-guard-lib.ps1` and deliberately left that hook carrying its own copy, because refactoring a
guard over a revenue-serving live theme in the same branch as a brand-new hook would have doubled the
review surface of both. #1734 is that scoping decision coming due.

**It was not routable when it was picked up.** #1669's own PR (#1733) was still open, so
`scripts/lib/command-guard-lib.ps1` did not exist on the trunk and the duplication the issue describes
existed only on that branch. #1733 was landed first -- and its merge base predated #1698's
`dkj-teams` -> `dkj-subagents` rename, so six of the files it added still named the retired plugins in
prose and in two `agent_type` fixtures. Corrected on that branch before it shipped.

- [x] Verify the subject exists on the trunk -- it did not; land #1733 first
- [x] Read `Get-GuardSegments` against what `guard-live-theme.ps1` actually does today

### CREATE

- [x] Dot-source `command-guard-lib.ps1` from the hook, `$PSScriptRoot`-relative
- [x] Delete the hook's own `Remove-HeredocBodies`, `Remove-HereStringBodies`, `Get-LeadingCommand`,
      `$INTERPRETERS`, the `$executesText` computation and the segment split
- [x] Drop the now-dead text-tool exemption out of the matching loop -- the lib applies it
- [x] Register the second mirror: `command-guard-lib-shopify`, on `native-capture-lib-shopify`'s
      precedent, and update #1669's "NO SECOND MIRROR YET" banner, which this branch falsifies
- [x] Regenerate the mirror with `build-shared-scripts.ps1`

#### Four things the plan did not foresee

1. **`$scan` had nowhere to come from.** The two marker tests read the command with heredoc and
   here-string bodies stripped out -- a marker written INSIDE a body is documentation, not
   authorisation -- and `Get-GuardSegments` returns segments, not that text. Rebuilt in the hook from
   the lib's own two primitives rather than re-implemented, and rather than widened into the lib's
   return: its other caller has no markers and no use for it.
2. **A missing lib is not the same question here as next door.** `guard-working-copy.ps1` exits 0 and
   says the guard is off. Copying that would silently disarm a live-theme guard on a half-updated
   install, so this hook degrades to matching the whole payload instead, and says so on stderr. That is
   the direction this file's own unparseable-payload fallback already takes.
3. **The wrapper change is real and costs exactly one refusal.** Measured old-against-new rather than
   argued: `perl -c '...'` now blocks where it used to pass, because `perl` is both a `$TEXT_TOOLS`
   entry and an interpreter and the lib expands a wrapper before any exemption. It is a false positive
   -- `perl -c` is a syntax check -- and it is pinned rather than exempted.
4. **`perl -e` is unchanged.** The residual limit this hook's header already states survives the swap,
   which is the counter-case that keeps point 3 honest.

### TEST

- [x] `guard-live-theme.tests.ps1` -- all 102 existing cases green with no edits, which is the
      measurement #1734 made a precondition
- [x] Group 8 added: the four wrapper cases and the four degraded-install cases -- 110 total
- [x] `command-guard-lib`, `working-copy-guard-lib`, `guard-working-copy`, `shared-scripts` suites
- [x] `check-plugin-integrity.ps1` and the full suite run

#### The one behaviour that changed, measured

Seven commands through the trunk's guard and this branch's, side by side:

| command | before | after |
|---|---|---|
| `shopify theme publish --theme 1` | blocked | blocked |
| `bash -c "shopify theme publish --theme 1"` | blocked | blocked |
| `pwsh -Command "shopify theme publish --theme 1"` | blocked | blocked |
| `echo "shopify theme publish" > notes.txt` | allowed | allowed |
| `git commit -m "never run shopify theme publish"` | allowed | allowed |
| `perl -e 'system(qq{shopify theme publish --theme 1})'` | allowed | allowed |
| `perl -c 'shopify theme publish --theme 1'` | allowed | **blocked** |

One row moved, and it is the false positive named above.

### DEPLOY: fix/1734-guard-live-theme-uses-command-guard-lib

`guard-live-theme.ps1` dot-sources `command-guard-lib.ps1` instead of carrying its own copy of the
heredoc stripping, the here-string stripping, the leading-command reader and the segment split. #1669
extracted that machinery out of this very hook so a second guard could reuse it, and then left the
original copy standing -- two copies of one behaviour, free to drift, with the copy that drifts being
whichever nobody looks at. The lib is mirrored into `dkj-subagents-shopify` as its own registry entry
(`command-guard-lib-shopify`) rather than reached for across plugin trees, because the two plugins are
separately versioned and a Shopify consumer may run this team without the workflow plugin.

All 102 existing cases pass unedited. Eight new ones pin what the swap changed: the wrapper expansion,
its one new false positive (`perl -c`), and a broken install degrading towards checking rather than
switching the guard off.

**Score:** 3

#### What makes this deploy extra special

A consumer running this plugin sees the same guard it had, with two differences worth knowing. A
`perl -c "..."` command containing a theme publish, delete or live push is now refused where it used
to pass -- a false positive, since `perl -c` only syntax-checks, and the price of the wrapper handling
becoming explicit. And an install missing `command-guard-lib.ps1` no longer behaves unpredictably: the
guard keeps blocking, matching the whole command without the authoring exemptions, and says on stderr
which file to reinstall. `perl -e` is unchanged.

**Score:** 2

#### Pull Request

guard-live-theme dot-sources the shared command-guard machinery instead of carrying its own copy
