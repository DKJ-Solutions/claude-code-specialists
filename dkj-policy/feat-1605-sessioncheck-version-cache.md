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

- [x] `scripts/lib/session-cache-lib.ps1`: the bounded read of a SessionStart hook's own stdin payload, the session-id shape check, and a per-session verdict cache under temp (read, write, reap)
- [x] `connector-sessioncheck.ps1`: the #1591 fallback asks that cache before it spawns the engine, and stores what it measured -- the matcher stays `startup|resume|clear|compact`
- [x] `shared-scripts-lib.ps1`: register the lib as a `dkj-policy` LibOnly pair and generate the mirror, so a consumer's hook does not dot-source a file its payload lacks
- [x] the hook's docstring: the paragraph that says the cache was "filed as #1605 rather than built here" now describes what it does, and what invalidates it

### TEST

- [x] `scripts/tests/session-cache-lib.tests.ps1`: the shape check, the age bound, a corrupt entry, the reap, and the key
- [x] `connector-sessioncheck.tests.ps1`: a second firing under the same session id spawns the engine ZERO times and prints the identical line; a different id re-measures; no payload means no cache
- [x] the lint gate and every suite green (`check-plugin-integrity.ps1` + `scripts/tests/*.tests.ps1`)
- [x] the review round on the diff: Victor (code), Sebastian (security), Edith (copy) -- five findings taken, one filed as #1659

### DEPLOY: feat/1605-sessioncheck-version-cache

A session start on a machine with no source checkout stops paying for its version verdict twice.
`connector-sessioncheck`'s consumer fallback ran `plugin-versions.ps1 -Brief` -- two nested
powershell bring-ups plus git in the marketplace clone -- at every firing of the
`startup|resume|clear|compact` matcher, so a session with four compactions measured five times for an
answer that had not changed. The matcher stays exactly as it is; narrowing it is what makes the whole
report go silent after the first `/compact`. Instead the engine's output is now held for the life of
the session, keyed on the `session_id` the harness writes to the hook's stdin: a compaction keeps
that id and replays, a startup and a `/clear` bring a new one and re-measure, so nothing has to read
the payload's `source` field or decide which kinds of firing may trust a cache. Measured over five
measure-then-replay pairs against a synthetic five-plugin consumer fixture: a median of 1,288 ms
against 439 ms, about 850 ms back per compaction.

What a replay guarantees is a **bound, not an invariant**, and that is the one place this branch
disagrees with the issue that asked for it. #1605 argued the cached answer cannot go stale within a
session, citing the hook's own "restart the session" line -- but that line is about a hook's *code*
being pinned, while the verdict is about two ordinary mutable files, and a sibling terminal running
`claude plugin update` moves them with no restart involved. So a replay is bounded by age at one hour
rather than the four this started with, the reasoning is written into the lib's header instead of the
citation that does not carry it, and the direction a reader acts on self-heals: acting on "you are
behind" means an update, after which this hook says to restart -- which is a new id and a bypass.

Everything about it fails towards measuring. No session id, an unwritable temp directory, a corrupt
entry, a plugin payload predating the lib: each falls back to the spawn this branch exists to avoid,
which is exactly what the hook did before. The suite counts engine spawns on disk rather than
inferring them from wall-clock, so "the second firing spawns nothing" is a measurement.

**Score:** 3

#### What makes this deploy extra special

N/A. This repo is not a service anyone subscribes to; the reader here is a developer maintaining it,
and what they get is already scored above. The saving lands in every consuming repo through a
release, but a consumer of this product is a developer too.

**Score:** N/A

#### Pull Request

connector-sessioncheck measures the version verdict once per session instead of on every compaction
