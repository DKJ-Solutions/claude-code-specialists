## Development: `fix/register-proposal-lists-every-enabled-plugin-v1` · 20260829-150516

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

`bootstrap.ps1` builds its paste-ready connector manifest from `$registerInventory`, and that map is
filled **only** while walking each plugin's `agents/` directory. A plugin that ships skills, scripts
and hooks and no agents never enters it, so it cannot reach the proposal -- and the workflow plugin
is exactly that shape. A consumer who pastes the block verbatim registers a manifest missing that
row (inbound #1084).

#### Why that is wrong rather than merely terse

`check-connectors.ps1` reports **per plugin** from that list, so a repo registered off this proposal
drops out of the version view for the workflow plugin specifically -- and the
`[ERROR] machine record is on vX, source on vY` line that exists to catch a stale consumer cannot
fire for it. Silently: an absent row is indistinguishable from a plugin that is not enabled there.
Every manifest already in `connectors/` lists the workflow plugin, so the proposal disagrees with
the register it is a proposal for.

The `[notice]` that explains the omission scrolls past hundreds of lines earlier and is worded as a
skipped **directory**, not as a consequence for the manifest -- so rewording it is the second half
of the repair rather than a mitigation that already exists.

### CREATE

- [x] `bootstrap.ps1`: build the proposal from the ENABLED plugin list rather than from the lens
      inventory, giving a plugin with no lenses an empty `"extensions": []` -- a true statement, and
      the shape the register's readers already handle
- [x] Reword the `agents directory ... not found -- skipped` notice to name what it means for the
      manifest, since that is the consequence a reader is actually deciding on
- [x] `bootstrap-drift.tests.ps1`: assert the workflow plugin reaches the proposal with an empty
      extensions array, and that the agent-bearing plugin still carries its ids

### TEST

`bootstrap-drift.tests.ps1`: 148 asserts green, 8 of them new. The workflow-enabled fixture is the
exact shape that produced the report, so the row assertion lives there rather than in a fixture
written for it -- and it asserts the agent-bearing plugin still carries its ids, because "every
plugin gets a row" could be satisfied by flattening the inventory.

**One new fixture, for a defect this branch would otherwise have introduced.** Widening the row set
to "every enabled plugin" also admits a plugin from a **foreign** marketplace, which the old
accident excluded for the wrong reason -- `Get-PluginAgentsDir` only ever looked beside this
plugin's own root. Measured on this machine, whose chain enables `figma@claude-plugins-official`:
the unscoped version put a `figma` row in the manifest, and `check-connectors` reads a name its
marketplace does not declare as **retired**, reporting *"this consumer has not migrated to the
current names yet"* about a plugin that was never this family's. So the rows are scoped to this
marketplace, read off this script's own plugin id, and the new fixture pins it.

Full gate: `check-plugin-integrity.ps1` 0 errors, all suites green. Eyeballed the printed manifest
for both shapes.

### DEPLOY: `fix/register-proposal-lists-every-enabled-plugin-v1`

`specialists-init`'s paste-ready connector manifest now carries a row for **every enabled plugin of
this marketplace**, not only the ones that ship an `agents/` directory. It was built from the lens
inventory, which is filled only while walking that directory, so a plugin shipping skills, scripts
and hooks and no agents could not reach the block -- and the workflow plugin is exactly that shape.
A plugin with no lenses gets `"extensions": []`, which is a true statement about it and the shape
the register's readers already handle.

The `[notice]` that explained the omission was worded as a missing **directory**, hundreds of lines
above the block it affected; it now names the consequence for the manifest, and distinguishes a
plugin of this family from one of another marketplace -- which are the two reasons a plugin can be
skipped and have opposite answers.

**Score:** 3

#### What makes this deploy extra special

The register is the maintainer's only view of which consumer sits on which version, and this failure
was the quiet kind: a row that is simply absent looks exactly like a plugin the consumer never
enabled, so the `[ERROR] machine record is on vX, source on vY` line that exists to catch a stale
consumer could not fire for the workflow plugin at all. The cost landed on the maintainer rather
than on the consumer, which is why nobody downstream would ever have reported it.

**Score:** 2

#### Pull Request

the bootstrap's connector-register proposal lists every enabled plugin, not only the ones with agents

