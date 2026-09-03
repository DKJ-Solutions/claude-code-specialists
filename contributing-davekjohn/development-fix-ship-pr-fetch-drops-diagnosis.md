## Development: `fix/ship-pr-fetch-drops-diagnosis` · 20260903-180131

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

Drop -DiscardStderr from step 3b's git fetch, print git's captured output on the failure path, and replace the retired credential reason with a pointer to native-capture-lib.ps1's measured seam (issue #1334).

#### The verification, before anything was repaired

Issue #1334 reports its own branch's defect, so all six pickup checks were run against the tree rather
than against the report. The symptom stands on today's `main` (`scripts/release/ship-pr.ps1`, the
`git fetch origin main` in step 3b). The reason stands too: `scripts/lib/native-capture-lib.ps1` carries
the #1313/#1330 measurement verbatim -- `-DiscardStderr IS NOT A CREDENTIAL GUARD` -- and
`new-branch.ps1`'s corrected comment names ship-pr's fetch as the precedent it must not become. The
proposed repair names mechanisms that exist, the size is one call site, and the repo is this one.

**The local checkout was 40 commits behind `origin/main` at pickup**, which is why this was checked after
a fast-forward: on the stale tree the seam comment the report quotes did not exist yet, and the report
would have read as describing something that was never written.

### CREATE

- [x] Drop `-DiscardStderr` from step 3b's `git fetch origin main`
- [x] Print git's captured output on the failure path, above the refusal
- [x] Replace the retired credential comment with a pointer to `native-capture-lib.ps1`'s seam
- [x] Leave the `git log` three lines below untouched -- its flag rests on an independent reason (its
      output is parsed)
- [x] Re-run `build-shared-scripts.ps1` so the plugin mirror follows the source

### TEST

- [x] Four asserts added to `scripts/tests/pr-issues.tests.ps1`, in the step 3b block: the fetch call
      asserted WHOLE as one literal (so re-adding the flag anywhere in it fails), the failure path's
      print, the seam pointer, and -- guarding the other direction -- that the parsed `git log` KEEPS its
      flag
- [x] `pr-issues.tests.ps1` green: 610 asserts

### DEPLOY: `fix/ship-pr-fetch-drops-diagnosis`

`ship-pr.ps1`'s stale-CI check (step 3b) no longer swallows git's own words when its
`git fetch origin main` fails. The flag that dropped them was added on a credential argument that
#1330 had measured as false 23 minutes earlier -- git anonymizes the URL itself through
`transport_anonymize_url`, so `user:token@host` prints as a bare `https://host/o/r.git` -- making this
the fourth call site #1313 warned would copy that retired reasoning. An operator whose fetch fails now
gets the auth error, the host and git's reason above the refusal, instead of `'git fetch origin main'
failed` and nothing else. The comment now points at `native-capture-lib.ps1`'s seam, where the
measurement lives, so the next reader meets it rather than the retired rule. The `git log` three lines
below keeps its `-DiscardStderr` on its own independent reason: that output is parsed, and a stray line
becomes a fake SHA.

**Score:** 2

#### What makes this deploy extra special

`ship-pr.ps1` is a mirrored shared script, so a consumer runs this exact file. The change is invisible
until their fetch fails -- and at that moment it is the difference between a diagnosable failure and a
retry in the dark.

**Score:** 2

#### Pull Request

ship-pr's stale-CI fetch keeps git's own diagnosis

