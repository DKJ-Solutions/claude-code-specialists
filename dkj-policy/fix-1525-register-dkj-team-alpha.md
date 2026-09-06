## fix/1525-register-dkj-team-alpha

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

`connectors/claude-code-specialists.json` -- this repo's record of **itself** -- still named the
retired id `team-alpha@claude-code-specialists` on line 7. The marketplace declares `dkj-team-alpha`
and `.claude/settings.json` at `HEAD` enables `dkj-team-alpha@claude-code-specialists`, so this
consumer had already migrated and its own register had not.

That cost two things, both measured before the repair:

1. `check-connectors.ps1` **skipped the whole plugin block**, so nothing under it was checked --
   not enabled-in-settings, not the 19 extensions, not the machine version.
2. The `[INFO]` it printed instead said *"this consumer has not migrated to the current names yet"*
   and *"Correct as it stands"*. Both are the opposite of the truth in the same checkout the script
   was reading. That doctrine is written for a consumer that has **not** moved; here it read as
   absolution for one that had.

This is the other half of the file `#1465` repaired: commit `011a32ef` changed the workflow plugin's
id on line 15 and left the core team's on line 7 standing, one block above it.

#### What this branch does NOT change

The check itself. The `[INFO]` deliberately stays an `[INFO]` -- making it an error re-opens the four
false alarms of August 9, 2026 -- so a consumer catching up **is** the repair. The five other
manifests naming retired ids are left standing for the same unchanged reason: those consumers have
not migrated.

### CREATE

- [x] `connectors/claude-code-specialists.json`: line 7 `team-alpha@` -> `dkj-team-alpha@`.
- [x] The 19 extensions **re-read rather than carried over**, because the skipped block had never
      verified them: `dkj-team-alpha` owns exactly 19 ids (15 in `agents/`, 4 in `personas/`) and
      `.claude/specialists/lenses/` holds a lens for each. The array is unchanged and is now the
      measured answer.
- [x] A dated `CAUGHT UP 2026-09-06 (#1525)` note appended in the register's existing style, carrying
      the three measurements (marketplace, settings, `installed_plugins.json`) and the lesson: a
      rename is checked against **every** id in a manifest, not against the id the report named.

### TEST

- [x] `check-connectors.ps1` before the repair: `1 info signal(s)`, block skipped.
- [x] `check-connectors.ps1` after: `[OK] plugin is enabled in .claude/settings.json`,
      `[OK] all 19 registered extensions present`, `[OK] machine record is on the source version
      (v4.31.0)`, and `0 error(s), 0 info signal(s)` -- the three checks that had never run.
- [x] The file parses as JSON (`ConvertFrom-Json`) after the note was appended.
- [x] Lint gate + all suites via `open-pr.ps1`.

### DEPLOY: fix/1525-register-dkj-team-alpha

The register of the repo that **owns** the connector check was itself unchecked: its core-team block
had been skipped since the `dkj-team-alpha` rename, so the 19 lenses, the enablement and the machine
version were verified by nothing. Worse, the check reported that state as *"correct as it stands"*.
Both are gone -- the block is read again, and the entry says what this repo actually has.

**Score:** 3

#### What makes this deploy extra special

The same class closed for a third time, and this time inside the commit that declared it closed:
`#1465` wrote *"The class was never emptied, only its instance was"* while repairing one of the two
stale ids in this file and leaving the other. The note now records the rule that would have caught
it -- check a rename against every id in the manifest, not against the one the report names.

**Score:** 2

#### Pull Request

register this repo's own core team under dkj-team-alpha@
