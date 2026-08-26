## Development cycle: `feat/plugin-scoped-skill-span-v1` · 20260826-205050

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Build check 29: an opt-in `skills:plugin` span that resolves the containing plugin from the file's own
path and reads each row's link target instead of its backticks. Then place the span around the workflow
plugin's 16-row skill table.

Written without the literal marker on purpose. The first gate run of the new check fired on this very
paragraph -- an unpaired BEGIN is a hard error, exactly as it is in check 10 -- which is the check
proving itself on its own branch document. A fenced block is the supported way to show the bare marker
text; inline prose is not, and this paragraph does not need it.

### CREATE

- [x] Check 29 (`[skill-list-plugin]`) in `scripts/lint/check-plugin-integrity.ps1`: the opt-in
      `skills:plugin` span, scoped via `Get-PluginNameForPath` and claimed by link target.
- [x] Both symmetric sweeps repaired: a nested BEGIN inside an already-open span is now a hard error in
      check 29 **and** in check 10, which had been silent on it since the day it shipped.
- [x] The span placed around the workflow plugin's 16-row skill table, and the note above it rewritten
      -- it promised the table was unguarded and pointed at #920 as unbuilt.
- [x] The marker documented in `README.md`, beside the `skills:all` convention it is the sibling of.
- [x] The third instance of the prose-marker trap recorded in Tessa's lens, where the first two live.
- [x] Docstring entries added for check 29 **and** for check 28, which shipped without its line in that
      list.

### TEST

- [x] Eleven scenarios for check 29 in `scripts/tests/check-plugin-integrity-links.tests.ps1`, plus
      scenario 14b for check 10's half of the repair. The scope assertion manufactures a third skill in
      a second plugin, because without it the fixture's two canonical sets coincide and the assertion
      is vacuous.
- [x] `scripts/lint/check-plugin-integrity.ps1` green: 1 span, 16 claims, 16 canonical, 0 findings.
- [x] Every suite in `scripts/tests/` green, as CI runs them.

### DEPLOY: `feat/plugin-scoped-skill-span-v1`

A plugin README that enumerates its own skills can now be machine-checked. Check 29 reads an opt-in
`skills:plugin` span, resolves the plugin from the **document's own path** rather than from anything
written in the marker, and counts a claim only where a link resolves to that plugin's
`skills/<one>/SKILL.md`. Check 10 could serve neither half: its canonical set is the whole marketplace,
so a span in one plugin's README reports every other plugin's skills as missing, and its *wrap tightly*
rule -- every backtick inside the span is a claimed name -- is unmeetable in a two-column table whose
second column is prose. The workflow plugin's table carries the first span, and the count that had
drifted three times (nine/twelve, thirteen/fourteen, fourteen/sixteen) is now held by a gate rather than
by *count when you add one*.

**Score:** 3

#### What makes this deploy extra special

**The check caught its own author twice, and the second catch was the valuable one.** The first run
fired on this branch document, where the marker had been typed into the PLAN paragraph -- an unpaired
BEGIN, refused loudly, exactly as check 10 refuses it. The second was worse and quieter: the same
marker named in prose *above* the real span in the plugin README paired with that span's END, swallowed
the real BEGIN in between, and reported **green**. Right verdict, wrong reason, nothing said so.

That exposed an asymmetry both checks had carried from the start. A duplicate END pasted inside an open
span was reported from day one; its mirror, a **nested BEGIN**, was never visited by the walk at all --
it jumps from a span's opener straight past its END -- so the span simply paired across it. Repaired in
both checks in this movement, not just in the new one, and pinned by a scenario each. Check 10's is
born green across the whole scan set.

**Nothing about the rule is generic, and that is deliberate.** Measured over all four plugins before
proposing it: `contributing-davekjohn` ships 16 and lists 16; `team-alpha` ships 4 and lists 0;
`team-shopify` ships 4 and lists 0; `team-ecomm` ships 0. A rule that simply required every plugin
README to enumerate its skills would be born with 8 findings on two documents that never claimed to
enumerate anything -- an exemption list on day one, which is the shape this repo has scar tissue from.
An explicit sentinel fires on exactly the one table that means it, and a document with no span passes
in silence.

**Score:** 2

#### Pull Request

a plugin-scoped skill span, so a plugin README's own table is machine-checked

