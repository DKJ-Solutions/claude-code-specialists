## docs/1774-settings-reflow

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

#### The finding, verified before anything was written

[#1774](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1774) reports that plugin
administration rewrites the tracked `.claude/settings.json` and strips the blank lines grouping
`permissions.allow`. The grouping is still there -- three blank lines, at lines 40, 53 and 58 of an
82-line file, separating the git / gh / scripts / release blocks -- so nothing has repaired it and the
report stands. The cause is the CLI's own settings writer, not this repo's code, which is why the issue
frames the repair as a decision about the file rather than a fix to a script.

#### The decision, and it is the reporter's own lean

Three options were offered: accept and document, drop the blank lines, or gate a whitespace-only diff.
**Accept and document**, for the two reasons the issue already gives and one it does not:

- Dropping the grouping pays for round-trip stability with the readability four labelled blocks in a
  60-entry allowlist exist for.
- A gate refusing a whitespace-only diff on one file is the same shape as the control-character rule
  this lens already records as measured and declined -- a rule written for one careless afternoon.
- And the third: the behaviour belongs to a tool this repo does not own, so the only durable answer is a
  reader who knows it. Neither of the other two options changes the CLI.

#### Where it goes, which is NOT only where the issue suggested

The issue proposes Sylvester's lens. Half of it belongs there and half does not: this repo's own rule is
that **the shared source is the default destination for a lesson learned here, and the lens is the
exception** for what a consumer would genuinely have to differ on
([the specialists handbook](../.claude/specialists/README.md)). The mechanism -- a JSON round trip
losing formatting, on any tracked settings file, in any repo doing plugin administration -- is not
this repo's to differ on, and a lens-only record would leave every consuming repo without it.

### CREATE

- [x] The portable half in
      [Sylvester's manual](../plugins/dkj-subagents/dkj-subagents-alpha/manuals/05-15-manual.md), among
      his hard rules and beside the two that already govern settings files: what the round trip loses,
      the `git checkout -- <file>` remedy and why re-serialising the captured content is the wrong one,
      the `git add -A` that commits the reflow silently past every check, and the reason neither a gate
      nor a flattened file is the answer.
- [x] The local half in [Sylvester's lens](../.claude/specialists/lenses/05-15-extension.md), directly
      after the `claude plugin marketplace remove` bullet -- its nearest sibling, the other case of a
      plugin command rewriting a `settings.json` nobody asked it to touch. It carries the measurement
      (nine commands, September 10, 2026, `enabledPlugins` byte-identical), why this repo meets it
      routinely (it consumes its own marketplace with all six plugins enabled; #1698 alone took nine
      commands), what the trunk rule adds to the cost, and the declined check.

### TEST

- [x] Lint gate: 0 errors -- which covers the two new relative links and the manual's frontmatter, and
      the anchor `#sylvesters-hard-rules` the lens now points at exists.
- [x] Full lint + suite gate, via `open-pr.ps1`.
- [~] No script changed, so there is nothing to add to a suite. Dropped rather than left open: this is
      the honest answer for a documentation branch, and ticking a test box for prose would be worse.

### DEPLOY: docs/1774-settings-reflow

Every `claude plugin install`/`uninstall --scope project` rewrites the tracked `.claude/settings.json`
and strips the blank lines that group its 60-entry `permissions.allow` into git / gh / scripts /
release blocks -- measured over nine such commands with `enabledPlugins` byte-identical before and
after. It is the CLI's own settings writer doing a JSON round trip, so there is nothing in this repo to
repair; what there was, was a session meeting an unexplained diff with no warning and having to work out
from it that the tool and not the work had caused it.

So it is written down twice, split the way this repo's own rule splits a lesson. The **portable** half
is in Sylvester's manual, because the mechanism belongs to any repo whose settings file is tracked and
that does plugin administration at all: what the round trip loses, that `git checkout -- <file>` is the
remedy and re-serialising the captured content is not, and that a `git add -A` in the same sitting
commits the reflow silently -- valid JSON, functionally identical, past every check there is. The
**local** half is in his lens, beside the `claude plugin marketplace remove` bullet it is the sibling
of: the measurement, why this repo meets it routinely rather than once (it consumes its own marketplace
with all six plugins enabled), and what the never-commit-on-`main` rule adds to the cost of a stray
diff.

Both halves say why the two mechanical repairs were declined. Dropping the grouping would pay for
round-trip stability with the readability the blocks exist for; a gate refusing a whitespace-only diff
on one file is the shape this lens already records as measured and declined for the control-character
rule. Neither would change the CLI, which is the only thing that could actually stop it.

**Score:** 2

#### What makes this deploy extra special

N/A -- this repo publishes a plugin rather than a subscribed service. The reader who gains something is
a consumer developer, who now receives the portable half with the next release instead of nothing at
all, and that is the score above.

**Score:** N/A

#### Pull Request

plugin administration reflows the tracked settings.json -- recorded where it is met
