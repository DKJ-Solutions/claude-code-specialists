## feat/1605-sessioncheck-version-cache

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

Cache the plugin-versions -Brief verdict for the life of a session, keyed on the harness's own session_id from the SessionStart stdin payload; the matcher stays startup|resume|clear|compact.

### CREATE

- [ ] `scripts/lib/session-cache-lib.ps1`: the bounded read of a SessionStart hook's own stdin payload, the session-id shape check, and a per-session verdict cache under temp (read, write, reap)
- [ ] `connector-sessioncheck.ps1`: the #1591 fallback asks that cache before it spawns the engine, and stores what it measured -- the matcher stays `startup|resume|clear|compact`
- [ ] `shared-scripts-lib.ps1`: register the lib as a `dkj-policy` LibOnly pair and generate the mirror, so a consumer's hook does not dot-source a file its payload lacks
- [ ] the hook's docstring: the paragraph that says the cache was "filed as #1605 rather than built here" now describes what it does, and what invalidates it

### TEST

- [ ] `scripts/tests/session-cache-lib.tests.ps1`: the shape check, the age bound, a corrupt entry, the reap, and the key
- [ ] `connector-sessioncheck.tests.ps1`: a second firing under the same session id spawns the engine ZERO times and prints the identical line; a different id re-measures; no payload means no cache
- [ ] the lint gate and every suite green (`check-plugin-integrity.ps1` + `scripts/tests/*.tests.ps1`)

### DEPLOY: feat/1605-sessioncheck-version-cache

**Score:**

#### What makes this deploy extra special

**Score:**

#### Pull Request

connector-sessioncheck measures the version verdict once per session instead of on every compaction

