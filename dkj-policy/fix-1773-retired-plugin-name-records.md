## fix/1773-retired-plugin-name-records

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

#### The finding, verified in the code before anything was changed

[#1773](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1773) stands exactly as
written. `tidy-machine.ps1` lane 8 builds its probe purely from each record's `projectPath` and hands
that to `Get-OrphanInstallRecords`, whose own docstring says the record is keyed on a folder path -- so
a record whose **plugin name** is gone while its checkout is alive is not an orphan by that test, and
the lane's title says as much itself. Lane 7 (`check-claude-home.ps1`) looks for fixture records only.
Nothing measured the class.

#### The caveat the issue raised for whoever took it, and it is load-bearing

*"A record can legitimately name a plugin from a DIFFERENT marketplace this checkout also uses, so the
test has to be scoped per marketplace rather than against one manifest."* Correct, and it decides where
the authority comes from: **each marketplace's own clone under `~/.claude`**, not this repo's
`marketplace.json`. The question is machine-wide, and the clone is the only per-marketplace manifest a
consumer has.

#### A second defect, found in the same function while extending it

`Get-OrphanInstallRecords` returned `Plugin = [string]$r.Plugin`, and no producer writes a `Plugin`
field: `Get-InstallRecord` projects `Id`/`Scope`/`Version`/`GitCommitSha`/`InstallPath`/`ProjectPath`/
`InstalledAt`/`LastUpdated`. So under lane 8 that read resolved to `$null` on every real record and the
finding printed with the plugin name missing -- ` -> C:\gone`. The suite stayed green because its own
fixture hand-wrote a `Plugin` field and no assert ever read the value back. Repaired here rather than
filed: it is the same function, and copying the idiom into the new one would have reproduced it.

### CREATE

- [x] `scripts/lib/tidy-lib.ps1`: `Get-RetiredNameInstallRecords`, pure and report-only like its
      sibling -- per-marketplace scoping, ordinal case-sensitive name comparison (the position
      `Get-PluginRootByName` already takes), and silence for every state it cannot decide: a
      marketplace it has no live list for, an empty list, a checkout that is gone or unprobed, a
      path-less record, an id that is not exactly `<plugin>@<marketplace>`.
- [x] `Get-OrphanInstallRecords` returns `Id` instead of the `Plugin` field nothing writes, and lane 8
      prints it through `Format-SuspectToken`.
- [x] `scripts/maintenance/tidy-machine.ps1`: lane 11. It reads each named marketplace's clone through
      `Get-RepoPluginRoots` -- guarded, because that function throws on a manifest it cannot parse and
      an authority this run could not read is not evidence that a plugin is gone -- and says at the end
      how many marketplaces it did not examine.
- [x] `Write-PluginHandover`, beside the existing ref and path handovers. An install id is not a ref:
      `@` is in neither shared paste allowlist, so handing the whole id to `Get-PasteableRef` would
      refuse every legitimate id there is. Each half is judged on the ref axis and the `@` is the
      helper's own literal, which widens nothing in a pattern two other guards depend on.
- [x] The printed `--scope` is the **record's own**, never a fixed `project`: an uninstall at
      `--scope project` refuses a record sitting at `local` (inbound #315), and a session start alone
      creates local records (inbound #314). An unrecognised scope prints no flag and says so.
- [x] Numbered **11**, not slotted in beside lane 8. Lane numbers are quoted in this repo's changelog,
      in the skill page and in a sibling suite; renumbering to make two related lanes adjacent would
      have invalidated all of it silently. The two lanes cross-reference each other in prose instead.
- [x] Lane counts corrected in every live place that states them -- the script header, both the
      `-CheckoutOnly` and `-MachineOnly` parameter docs, the registry comment in
      `shared-scripts-lib.ps1`, the suite docstring, the skill page (frontmatter, title, table and its
      `-MachineOnly` row) and the two README tables. The `CHANGELOG.md` entry saying *"ten lanes"* is
      history and is left exactly as written.
- [x] Mirrors rebuilt via `scripts/sync/build-shared-scripts.ps1`; `plugin-tree-lib.ps1` is already
      carried by the plugin, so the new dot-source resolves in a consumer.

### TEST

- [x] `scripts/tests/tidy-lib.tests.ps1` section 6b: the retired name reported with both halves and the
      record's scope, a live name not reported, the per-marketplace case the issue flagged, an unknown
      and an empty marketplace both silent, a gone/unprobed/path-less record left to its own lane, the
      case-sensitivity position, five unsplittable ids, and the empty input.
- [x] Section 6's fixture repointed at the field its producer actually writes, with the id asserted --
      the assert whose absence hid the `Plugin` defect.
- [x] 65 pass, 0 fail. Lint gate: 0 errors.
- [x] Run for real on this machine: lane 11 finds **seven** dead records -- the `dkj-team-alpha`,
      `dkj-team-ecomm`, `dkj-team-shopify` and `dkj-team-lifehub` records the two BWJ store checkouts
      still hold after #1698 -- each with its uninstall and, because they belong to another checkout,
      the line saying it has to be run there. That is the class #1773 measured, in a state the reporter
      deliberately left standing.
- [x] Full lint + suite gate, via `open-pr.ps1`.

### DEPLOY: fix/1773-retired-plugin-name-records

`tidy-machine` gained an eleventh lane, and it closes the half of a defect lane 8 could never see: an
install record naming a **plugin the marketplace no longer lists**, for a checkout that is still there.
Lane 8 probes the record's `projectPath`, so a rename -- a deliberate act this workflow performs, twice
in two days in #1697 and #1698 -- silently turned every existing record into dead weight that no lane
reported. Measured on the machine this landed from: seven such records, under two retired naming
generations. The lane names each one, hands over the uninstall, and says which checkout it has to be run
from, because an uninstall is keyed on the directory it runs in.

Three decisions inside it are worth naming. The authority is **each marketplace's own clone** under
`~/.claude`, per marketplace, which is the caveat #1773 raised: a name alive in one marketplace says
nothing about a record naming another, and a clone this run could not parse produces silence rather than
a verdict. The printed `--scope` is the **record's own** and never a fixed `project`, because an
uninstall at `project` refuses a record sitting at `local` (inbound #315) and a session start alone is
enough to create one. And the lane is numbered 11 rather than slotted in beside its sibling: lane
numbers are cited in the changelog, the skill page and a sibling suite, so adjacency would have cost
more than it bought.

Lane 8 also stopped printing findings with the plugin name missing. It read a `Plugin` field on the
install record, which nothing writes -- the projection carries `Id` -- so every finding it has ever made
named a path and no plugin. Its own fixture hand-wrote that field and no assert read the value back,
which is exactly why the suite was green; the id is asserted now.

**Score:** 3

#### What makes this deploy extra special

N/A -- this repo publishes a plugin rather than a subscribed service, so no subscriber sees a
maintenance lane. The reader who does is a consumer developer running `dkj-policy`, and that is the
score above.

**Score:** N/A

#### Pull Request

tidy-machine reports install records under a retired plugin name
