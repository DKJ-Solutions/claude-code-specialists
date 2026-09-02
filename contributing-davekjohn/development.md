## Development: `docs/ruleset-bypass-dropped-by-transfer-v1` · 20260902-204414

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

#### Four present-tense claims went untrue on September 2, 2026, and none of them announced it

The transfer into `DKJ-Solutions` carried `main-ci-gate` across intact and dropped its bypass list
(#1244). Four documents describe that list, or a route that runs on it, in the present tense.

#### The reach was measured rather than assumed

`grep -rn "bypass" --include=*.md` over the tree, minus the archived release notes: eleven hits, four
of them claims about this ruleset. The other seven are about gates in general and are untouched.

### CREATE

- [x] `05-15-extension.md` -- the bypass-list claim, plus the measured chain reaction and the generalisable half
- [x] `05-15-extension.md` -- the three pre-transfer readings behind "the App is NOT in the bypass list", dated rather than deleted; the method is the keeper
- [x] `.claude/rules/language-layers.md` -- "bypass actors are all unchanged", bounded to the rename it was measured against
- [x] `05-06-extension.md` -- the release route's "its push to `main` bypasses the required check", which is currently impossible
- [~] Promote the lesson to Sylvester's portable manual -- dropped: repo settings are not in that manual's stated scope, and the neighbouring generalisable half ("when an API hides a field, check whether a sibling representation leaks its shape") already lives in this lens. Following the section's own convention rather than inventing scope.

### TEST

- [x] `check-plugin-integrity.ps1` + all suites via `open-pr`
- [x] The four claims re-read against the live API: `bypass_actors: null`, `current_user_can_bypass: never`, `updated_at 2026-09-02T17:41:27`
- [~] An automated check that a doc claim about repo settings still matches the API -- dropped, and it is a real gap: the tree cannot see repo settings, which `language-layers.md` already names ("it is exhaustive over the tree, and the tree is not the whole product"). Naming the gap is the fix available here.

### DEPLOY: `docs/ruleset-bypass-dropped-by-transfer-v1`

Four documents stop claiming a bypass list that no longer exists. The org transfer carried the
`main-ci-gate` ruleset across intact and dropped only its bypass actors, so a ruleset that reports
`active` reads as a clean bill of health while the one array all three direct-on-`main` exceptions run
on is empty. The system-administration lens said the list "keeps the direct fold/release commits
possible", the release lens said the cut's push "bypasses the required check", the language rule said a
field-by-field re-check found the bypass actors unchanged, and the three readings behind "the App is
NOT in the bypass list" no longer reproduce. Each is now corrected or dated, with the measured
consequence written down beside it: a blocked fold leaves a live branch document on the trunk, and
because that path is fixed by design every subsequent PR then conflicts on it -- where the intuitive
resolution destroys another branch's unfolded changelog entry.

**Score:** 3

#### What makes this deploy extra special

N/A -- all four documents are repo-owned. The lenses and `.claude/rules/` do not travel to a consumer,
and the portable manuals are deliberately untouched: repo settings are not in their scope.

**Score:** N/A

#### Pull Request

Correct the ruleset bypass claims the org transfer made untrue
