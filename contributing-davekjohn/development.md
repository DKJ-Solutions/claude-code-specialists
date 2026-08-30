## Development: `fix/manifest-unescape-not-backslash-aware-v1` · 20260830-115041

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

Issue [#1131](https://github.com/DaveKJohn/claude-code-specialists/issues/1131): `Write-ManifestJson`
in `scripts/release/publish-to-business.ps1` still carries the un-escape expression that was repaired
in `specialists-init/bootstrap.ps1` on inbound #1124. The issue leaves one question open -- whether
the expression is worth promoting to a shared helper -- which this branch has to answer rather than
inherit.

- [x] Verify the symptom still stands: `grep` finds the old expression at `publish-to-business.ps1:296`
      and the repaired one at `bootstrap.ps1:1311`. Both confirmed.
- [x] Verify the reason on 5.1 before repairing it, not just the symptom. Reproduced: with the old
      expression `"C:\\uadded\\check.ps1"` no longer parses; with the counted-run expression it
      round-trips. The issue's diagnosis and its suggested repair both hold verbatim.
- [x] Correct one thing the issue infers rather than measures: it says *"the file is still written"*,
      which is true of the temp tree and reads as a corrupt publication. `Assert-MarketplaceIntegrity`
      runs seven lines later (line 618 -> 625) and parses that same manifest, so the real cost is a
      hard stop naming *"marketplace.json is not valid JSON"* about a file the script itself just
      wrote. The repair is unchanged; the reason recorded beside it is not.
- [x] Answer the open question: **no shared helper.** Reasoning in CREATE.

### CREATE

- [x] Replace the expression in `Write-ManifestJson` with the backslash-counting form, identical to the
      one on the bootstrap.
- [x] Record why the two copies stay two copies, in the docstring where the next reader meets it.
      `bootstrap.ps1` ships inside the plugin payload and must run standalone in a consumer's tree --
      it dot-sources even `check-report-lib.ps1` only *if present*, on the stated ground that a missing
      lib must never stop the script that sets a repo up. The only fallback available for a missing
      JSON-escape lib is "write the escapes through": a degraded mode with **no visible symptom**,
      which is worse than carrying ten lines twice. The mirror machinery would have supported it
      (`Get-SharedScriptPairs` already carries nine `LibOnly` pairs) -- the obstacle is the bootstrap's
      deliberate absence of hard dependencies, not the absence of a mechanism.

### TEST

- [x] Extend the existing filter fixture in `publish-to-business.tests.ps1` rather than adding a new
      one: one kept plugin's description now carries `C:\uadded\check.ps1`. A description, not a
      source, because it exercises the same code path without needing a directory of that name -- and
      a description quoting a Windows path is the likelier of the two shapes anyway.
- [x] Assert it, and check the assert actually bites by reverting the expression and re-running. It
      did **not** on the first attempt: the regression's symptom is a *refusal*, so nothing is
      published and the checkout the test reads still holds the previous, unfiltered publication --
      against which a round-trip assert passes while the defect is present. Added an assert on the
      run's own output; it is the one that fires. The round-trip assert is kept beside it because the
      exit code names nothing about escaping.
- [x] Suite green: 61 asserts. With the old expression restored: 6 fail, including the new one by name.
- [x] Both touched files re-checked for non-ASCII by code point, not by eye -- this branch's subject is
      an escape-mangling repair, and `.claude/rules/language-layers.md` names exactly that trap.

### DEPLOY: `fix/manifest-unescape-not-backslash-aware-v1`

The published marketplace manifest's un-escape now counts the run of backslashes in front of a `\u`
sequence, so a manifest field holding a Windows path no longer has that path folded into an invalid
escape. Before this, a filtered publish whose manifest carried such a path stopped with
*"marketplace.json is not valid JSON"* -- about a file `publish-to-business.ps1` had just written
itself, from a source manifest that was fine. The expression is now identical to the one
`specialists-init/bootstrap.ps1` has carried since inbound #1124, and the docstring says why the two
stay separate copies rather than one shared lib: the bootstrap must run standalone in a consumer's
tree, and the only fallback for a missing JSON-escape lib is a degraded mode with no visible symptom.

**Score:** 2

#### What makes this deploy extra special

N/A -- this is release tooling for publishing a marketplace subset to a business repo. No consumer of
the plugins runs it, and nothing about what they install changes.

**Score:** N/A

#### Pull Request

the published manifest's un-escape counts the backslashes in front of it

