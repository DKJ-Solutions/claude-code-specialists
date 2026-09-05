## fix/1479-wrangler-toml-silent-write

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

Issue #1479: `build-release-notes-page.ps1 -Worker` writes a fresh `wrangler.toml` and reports it in
green as a routine event, in a repo whose seam names a live worker. The file sits in the same
gitignored `page/` directory as the path token and is lost by the same mechanisms -- so an absent one
is as likely to mean "the directory was rebuilt from nothing" as "first run here", and the fresh file
carries none of what a consumer had edited in (an account id, a custom domain, a route).

#### What the report got right, and the one thing it got wrong

The symptom, the reason and the shape of the repair all stand. The proposed **condition** does not:
the report asks for the note "where the file is being written **and** `$config.WorkerName` is
non-empty", but `-Worker` has already thrown on an empty worker name well above this line, so that
condition is true at every reach. Reaching the write **is** the evidence it was reaching for, and the
note therefore goes in unconditionally -- with a comment saying why there is no second condition, so
nobody adds one back as a tightening.

### CREATE

- [x] `scripts/release/build-release-notes-page.ps1`: the absent-file branch reports what a fresh
      write means, in yellow, same shape as the `-InitToken` note -- it names the configured worker,
      names what a lost file would have carried, and says a first-ever deploy looks identical from
      there, which is why it is a note and not a refusal.
- [x] The comment above the write, and the `WHAT IT WRITES` paragraph in the header, record why the
      absent branch is the one that reports and why it carries no second condition.
- [x] `plugins/dkj-policy/skills/release-notes-page/SKILL.md`: the consumer-facing page says the
      same, beside the paragraph that already covers the token's gitignore hazard.
- [x] Mirror rebuilt via `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] `scripts/tests/release-notes-page.tests.ps1`: four asserts -- the write reports it, it names
      what a lost file carried, the refused run says nothing, and a run that FOUND the file says
      nothing either (so the note belongs to the write, not to every run).
- [x] `scripts/tests/release-notes-page.tests.ps1`: 162 passed, 0 failed.
- [x] Lint + all suites green.

### DEPLOY: fix/1479-wrangler-toml-silent-write

`build-release-notes-page.ps1 -Worker` no longer writes a fresh `wrangler.toml` in silence. That file
shares the gitignored page directory with the path token and is lost by the same mechanisms, so an
absent one is as likely to mean the directory was rebuilt from nothing as it is to mean a first run --
and the generated replacement carries none of what a consumer had edited in (an account id, a custom
domain, a route). The write now says so, in the same reported-not-refused shape as the `-InitToken`
note, because a first-ever deploy looks identical from there. The one run that finds the file already
present stays silent, so the note belongs to the write rather than to every build.

The condition the report proposed -- gate the note on a non-empty `Get-ReleasePageWorkerName` -- is
deliberately not there: `-Worker` already refuses an empty worker name above this line, so reaching the
write is itself that evidence, and the comment says so to stop the no-op being added back as a
tightening.

**Score:** 3

#### What makes this deploy extra special

N/A -- the reader of a release note is not the person running `-Worker` in their own checkout; this
reaches whoever hosts the page, which is a maintainer.

**Score:** N/A

#### Pull Request

Report the fresh wrangler.toml write instead of passing it off as routine
