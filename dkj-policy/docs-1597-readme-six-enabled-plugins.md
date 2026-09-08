## docs/1597-readme-six-enabled-plugins

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

Resolves [#1597](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1597). The folder
index's "Updating the plugins" section still described this repo as enabling `dkj-team-alpha` and
`dkj-policy`, and printed an update command for those two only — while `.claude/settings.json` has
enabled all six since
[#1573](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1573). A reader following the
block would have left four plugins on their old commit, with nothing reporting it.

Verified before editing: `.claude/settings.json` on `main` names all six; the two-plugin wording is
pre-existing on the trunk rather than introduced by any in-flight branch.

### CREATE

- [x] `dkj-policy/README.md`: the enabling sentence now says **every plugin in the marketplace**, six
      since #1573, instead of naming two.
- [x] `dkj-policy/README.md`: the fenced block gains one `claude plugin update … --scope project` line
      per enabled plugin, in `.claude/settings.json`'s own order, and its lead-in says the refresh runs
      once and the update once per enabled plugin.
- [x] `dkj-policy/README.md`: one paragraph after the block names the failure mode — a plugin left off
      the list stays on its old commit with no error and no verdict — and points at
      `.claude/settings.json` as the enabled set and `plugin-versions` for which ones need the command.
- [~] No other doc corrected: the only remaining two-plugin statements (`INSTALL.md`) describe a
      *consumer's* default adoption, not this repo's own enabled set, so they are correct as written.

### TEST

- [x] `check-plugin-integrity.ps1` — the printed-command check holds each new `claude plugin update`
      line to `--scope project` plus the marketplace refresh above it.
- [x] All script test suites, as CI runs them.

### DEPLOY: docs/1597-readme-six-enabled-plugins

The `dkj-policy/` folder index no longer describes this repo as enabling two plugins. Its "Updating the
plugins" section states that `.claude/settings.json` enables every plugin in the marketplace and prints
an update command for each of the six, so an update round in another checkout of this repo no longer
leaves four plugins silently behind.

**Score:** 3

#### What makes this deploy extra special

N/A — an internal maintenance document of this repo. No consumer reads it, and nothing about the
plugins they install changes.

**Score:** N/A

#### Pull Request

Name all six enabled plugins in the dkj-policy folder index

