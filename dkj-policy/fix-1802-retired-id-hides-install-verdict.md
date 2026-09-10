## fix/1802-retired-id-hides-install-verdict

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

Verified #1802 first: the comparison it proposes already exists in three readers (plugin-versions.ps1:315, check-connectors check 4, tidy-machine lane 11), and the machine-wide walk it implies was declined by Dave on the same day (tidy-machine docstring). The real defect is that a retired plugin id 'continue's past the whole plugin block, so check 4's install-record verdict -- the only thing that can say 'this checkout loads none of it' -- never runs for exactly the two consumers #1802 reports as worst. Next: answer the record question on the retired path too, and promote plugin-versions' one actionable indeterminate verdict.

#### What #1802 asked for, and what it turned out to need

The report proposed a check comparing a repo's `enabledPlugins` keys against the install records for
that `projectPath`, calling it *"the one comparison nothing currently makes"*. Three readers already
make it: `plugin-versions.ps1`'s `enabled declaratively only` verdict, `check-connectors.ps1` check 4
(which even carries the consequence in prose), and `tidy-machine.ps1` lane 11 for the retired-name half
(#1773, landed the same day #1802 was filed). The wider shape the report implies -- a sweep of every
checkout the machine knows -- is declined by name in `tidy-machine.ps1`'s own docstring, on Dave's
answer of that same day.

What stood is narrower and worse: in `check-connectors.ps1` a **retired** plugin id hit `continue` and
skipped the whole plugin block, check 4 among it. So for a consumer enabling nothing but retired ids --
both of #1802's worst cases -- the one check with a vantage point on *"this checkout loads nothing"*
never ran, and the register reported them as *"correct as it stands"*.

### CREATE

- [x] `check-connectors.ps1`: ask the install-record question on the `'retired'` path too, before the
      `continue`. It needs no plugin source folder, unlike the two checks that genuinely cannot run
      there. `[INFO]` for a walked connector, promoted to the non-counting `[NOT-INSTALLED-HERE]` for
      the session's own repo -- the same scoping and the same marker check 4 uses.
- [x] `check-connectors.ps1`: the retired `[INFO]` no longer claims *"nothing below is checked for it"*,
      and names what is skipped by what it needs.
- [x] `plugin-versions.ps1`: give the `enabled declaratively only` verdict its own row code, so `-Brief`
      can call it `[ERROR]` -- it is the one indeterminate verdict that hands over a command, which is
      that mode's own stated test for an error. Every other indeterminate row stays `[INFO]`, the
      path-less-record branch included.
- [x] `plugin-versions.ps1`: the `[SUMMARY]` gains a disjoint `N enabled but not installed here` part;
      the default view is deliberately unchanged, since `$unknown` still carries both codes.
- [x] Mirror `plugin-versions.ps1` into `plugins/dkj-policy/scripts/task/` via `build-shared-scripts.ps1`
      (`check-connectors.ps1` is source-only and is not plugin-carried).
- [x] Record the measurement in Sylvester's lens -- the mechanism worth keeping is that a `continue`
      skipping a whole block silences every check in it, including one whose subject does not depend on
      the reason for skipping.

### TEST

- [x] Both readers run clean against this repo's real register and administration, and the BWJ
      consumers correctly produce **no** new finding -- they hold records for their retired
      `dkj-team-*` ids, which is the false positive that would have mattered most.
- [x] `connectors.tests.ps1`: the new line fires on retired + enabled + no record, and does not fire
      when a record is present, when the id is not enabled there, or under `-SkipVersions`.
- [x] `plugin-versions.tests.ps1`: `-Brief` reports the new code as `[ERROR]` with its own summary
      part; the path-less branch stays `[INFO]`; the default view and cases 5 and 19 are unchanged;
      case 22's "a mix of every code" covers the new code too.
- [x] The full gate: `check-plugin-integrity.ps1` plus every suite.

### DEPLOY: fix/1802-retired-id-hides-install-verdict

A retired plugin name no longer hides the one thing the connector check can say that nothing else can:
that a consumer's checkout is loading none of a plugin its own settings enable. Until now a retired id
skipped that check along with the two that genuinely cannot run without a plugin source folder, so the
consumers worst affected -- the ones enabling nothing but retired names -- were the ones the register
reported as fine. The install-record question is now asked on that path too, and it hands over the
migration rather than `claude plugin install`, which cannot repair an id the catalogue no longer
declares. Alongside it, `plugin-versions.ps1` stops filing "enabled here, installed nowhere" under the
same quiet marker as a stale cache: it is the only undetermined verdict that closes with a command, so
in `-Brief` it is now an `[ERROR]`.

**Score:** 3

#### What makes this deploy extra special

A consumer whose plugin is enabled but not installed for that checkout loads none of it -- no skills,
no subagents, no hooks -- and cannot report that itself, because the hook that would is inside the
plugin that is not loading. That state now reaches the session start as an `[ERROR]` instead of an
`[INFO]`, and a consumer still on retired plugin names is told that re-installing under the old id
cannot work and that the migration is the way out. Consumers already in good standing see no new
noise: the finding requires a missing record, and a present one keeps it silent.

**Score:** 3

#### Pull Request

A retired plugin id no longer hides that a consumer loads nothing

