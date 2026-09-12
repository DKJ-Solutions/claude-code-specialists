## feat/1890-update-plugins

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

Issue #1890 split the buildable half off #1810: updating a checkout's own plugins is 1 + N commands
(`claude plugin marketplace update <marketplace>`, then `claude plugin update <id> --scope project`
per enabled plugin) with no `--all` and no repeatable `<plugin>` argument on the CLI. Build the
wrapper the issue's own "Shape" section describes -- refresh, update every enabled plugin, print
`plugin-versions`' receipt -- as a shared `dkj-policy` script + skill, scoped to this checkout plus
the machine-wide marketplace clone. The open question the issue leaves for Dave ("how many machines
actually work in these repos") is outside this branch's scope; nothing here depends on its answer.

### CREATE

- [x] `scripts/task/update-plugins.ps1` -- refresh, per-plugin update (`--scope project`), receipt
      via `plugin-versions.ps1` as a child process; continues past a per-call failure and exits
      non-zero if anything failed; `-DryRun` prints without executing
- [x] registered in `scripts/lib/shared-scripts-lib.ps1` and mirrored into
      `plugins/dkj-policy/scripts/task/update-plugins.ps1`
- [x] `plugins/dkj-policy/skills/update-plugins/SKILL.md`
- [x] doc rows/spans updated: root `README.md` (both `skills:all` spans),
      `plugins/dkj-policy/README.md` (`skills:plugin`), `plugins/dkj-policy/scripts/README.md`
      (`shared-scripts:mirror`)

### TEST

- [x] `scripts/tests/update-plugins.tests.ps1` -- 38 asserts, 0 failures. A `claude.cmd` shim on PATH
      stands in for the real CLI (echoes its own arg line so a scenario can tell "the CLI ran" apart
      from "-DryRun only printed the same words") and a fixture `.ps1` stands in for the
      `plugin-versions.ps1` receipt via `-ReceiptScriptOverride`. Covers: the happy path (one
      marketplace, two plugins), `-DryRun` (nothing executed, no receipt), no plugins enabled, a
      malformed id skipped alongside valid ones, every id malformed, a failing marketplace refresh
      (plugin updates still run), a failing plugin update (the other still runs), and two distinct
      marketplaces refreshed in ordinal order.
- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors (ran once before the doc-span updates,
      found the 4 missing-row/span findings named above, ran again clean).
- [x] `scripts/tests/shared-scripts.tests.ps1` -- 743 asserts, 0 failures (the new registry entry
      does not disturb the mirror/skill-parameter machinery).

### DEPLOY: feat/1890-update-plugins

A checkout's own plugins now update in one command instead of 1 + N. `update-plugins` (the shared
`dkj-policy` script + skill) refreshes the marketplace clone once, runs `claude plugin update <id>
--scope project` for every plugin this checkout enables, then prints `plugin-versions`' own receipt --
so the result is read off the same tool that would have reported the checkout as behind, rather than
trusted on the update commands' own say-so. `-DryRun` prints every command without running any of
them. Scoped on purpose to this checkout plus the machine-wide marketplace clone: every update call is
`--scope project` against the checkout the command runs from, never a walk into another repo (`claude
plugin install`/`update` rewrites the visited repo's `.claude/settings.json`, so a sweeping updater
would leave uncommitted diffs in repos nobody opened). One marketplace or one plugin failing to update
does not stop the rest -- every failure is reported and the run's own exit code is non-zero only if
something failed.

**Score:** 2 -- a convenience over typing the same commands by hand; this repo is itself a consumer of
its own `dkj-policy` plugin, and its own maintenance sessions gain the same shortcut.

#### What makes this deploy extra special

A consumer running `dkj-policy` gains a new skill the moment they update: closing the gap
`plugin-versions` (or `connector-sessioncheck`'s `-Brief` line) already reports no longer means typing
one command per enabled plugin.

**Score:** 2 -- noticed the next time they update and it takes one command instead of several; nothing
breaks and nothing is required to adopt it.

#### Pull Request

one-command plugin update per checkout

