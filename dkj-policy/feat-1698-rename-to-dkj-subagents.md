## feat/1698-rename-to-dkj-subagents

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

#### What this branch is

Phase 1 of the vocabulary plan in #1697, filed and deferred as #1698 and picked up on
September 9, 2026. The team side of the marketplace takes the vendor's own word for what those
plugins ship: `plugins/dkj-teams/` becomes `plugins/dkj-subagents/`, the four `dkj-team-*` plugins
become `dkj-subagents-*`, each team's `agents/` payload directory becomes `subagents/`, and
`agent-shared/` becomes `subagent-shared/`. Nothing else is renamed -- `dkj-policy` and
`dkj-policy-bwj` are untouched, and `skills/` is deliberately left alone.

#### The two premises, verified before any file moved

- **`"agents"` in `plugin.json` REPLACES the default directory**, and its value must start with
  `./`. Verified against the plugin reference rather than assumed, because the whole `agents/` ->
  `subagents/` half of this rename rests on it. Each team manifest now carries
  `"agents": "./subagents/"`.
- **`skills` can never replace its default** -- the format always scans `skills/` in addition to
  any custom path -- so the rename deliberately stops short of it. #1698 said so; it now has a
  citation.

#### What the previous round decided, and is followed here

The #1437 rename commit (`17149edb`) states this tree's answer to a rename, and this branch obeys it
rather than re-deciding it:

- **Readers GREW an entry rather than being substituted.** Every reader that resolves the payload
  directory by name now reads `subagents/` and `agents/`, new first, so a consumer whose plugin cache
  holds a pre-rename version keeps resolving. The lint's `[plugin-kind]` check keeps `dkj-team-*` as
  an accepted retired shape, held to no location, exactly as it already did for bare `team-*`.
- **Dated measurements keep the name they were written with (#952).** `connectors/`, the folded
  entries in `CHANGELOG.md` and the archived release notes under `dkj-policy/releases/**` are NOT
  swept; only the archive's LINK TARGETS are repointed.

### CREATE

- [x] Move the directories with `git mv`: `plugins/dkj-teams/` -> `plugins/dkj-subagents/`, the four
      team folders, each team's `agents/` -> `subagents/`, `agent-shared/` -> `subagent-shared/`, and
      `scripts/lib/agent-shared-lib.ps1` + `scripts/tests/agent-shared.tests.ps1` with them.
- [x] Sweep the three names across every tracked text file except `dkj-policy/releases/**`.
- [x] Add `"agents": "./subagents/"` to the four team manifests.
- [x] Teach every reader of the payload directory both leaf names, new first: one shared pair of
      helpers (`Get-SubagentDirName` / `Get-SubagentDirPath`) in `check-report-lib.ps1`, used by
      `Resolve-PluginDir` and `check-roster-sync.ps1`, plus the same both-leaves rule in
      `bootstrap.ps1`, `sync-roster.ps1`, `teardown.ps1`, `check-connectors.ps1`,
      `check-consumer-drift.ps1` and `find-specialist-mentions.ps1`.
- [x] Point the lint at `subagents/` where it reads THIS tree (which only ever has the new shape),
      and keep `dkj-team-*` accepted by name in check 23.
- [x] Regenerate the three derived artefacts: the shared agent-def blocks, the plugin script mirrors
      and the config blueprint.
- [x] Restore what must not be swept: `connectors/**` and `CHANGELOG.md` reverted; only the link
      targets under `dkj-policy/releases/**` repointed.
- [x] Write `INSTALL.md`'s third migration section, with the uninstall/install sequence and the three
      things inside a consumer's repo that the id swap does not fix.
- [x] Repair the prose the sweep made historically false, in `README.md` and `CLAUDE.md`.
- [x] Review round on the diff -- Victor #19 on the ~60 lines of new behaviour, Edith #17 on the prose.
      Both found real defects and both are repaired: a test that still filtered on the old leaf and so
      gathered zero agent defs against the live tree (3 failing assertions, which made the "all green"
      claim in this document false when it was written); two weakened fixture paths; INSTALL.md and this
      document's own DEPLOY section claiming an uninstall does not rewrite `enabledPlugins`, which
      INSTALL.md's own measured paragraph contradicts -- it does, so the list is TWO things and not three;
      two dated sentences swept to a name that did not exist on their date; and `connectors/README.md`'s
      FORMAT EXAMPLE, which is illustrative rather than a consumer's record and therefore does travel with
      a rename, as the previous round's own commit shows.
- [x] Cover the new behaviour: Tycho #18 added the `Get-SubagentDirName` / `Get-SubagentDirPath` cases
      (new shape, old shape, both, neither, and a FILE named `subagents`) plus a `Resolve-PluginDir` scan
      over a version shipping the new leaf. Nothing exercised the preferred shape before this.
- [x] Lint gate and every test suite green.

### TEST

`check-plugin-integrity.ps1`: 0 errors, with every coverage count intact -- 26 agent defs, 30 shared
blocks, 165 plugin links across 6 plugin roots, 346 link-scan files. A coverage count that had
collapsed to 0 is the failure mode this rename could most easily have caused silently, which is why
the counts are read rather than only the verdict.

All test suites green.

### DEPLOY: feat/1698-rename-to-dkj-subagents

The four team plugins are renamed from `dkj-team-*` to `dkj-subagents-*`, their directory from
`plugins/dkj-teams/` to `plugins/dkj-subagents/`, each team's payload directory from `agents/` to
`subagents/` (declared by a new `"agents": "./subagents/"` key in each manifest), and
`agent-shared/` to `subagent-shared/`. *Team* is this family's own word for a group of specialists;
*subagent* is Claude Code's word for what those plugins actually ship, so the four now say what is in
the box in the vocabulary of the thing that opens it. Every reader of that payload directory reads
both leaf names, new first, so a machine holding a pre-rename version in its plugin cache keeps
resolving, and the lint keeps `dkj-team-*` as an accepted retired shape. `dkj-policy` and
`dkj-policy-bwj` are unchanged, and `skills/` is deliberately not renamed -- the plugin format always
scans the default `skills/` directory in addition to any custom one, so a custom skills directory can
only add, never move.

**Score:** 3

#### What makes this deploy extra special

**A plugin rename is not a `claude plugin update`.** Every consumer must uninstall the four
`dkj-team-*` ids and install the `dkj-subagents-*` ones -- which rewrites their `enabledPlugins` for
them, as this page already documents -- and then fix the two things the CLI leaves behind: the
`@`-import in their `SPECIALISTS.md`, which carries the full marketplace path and both halves of it
moved, and their `connectors/` register if they keep one, where an unresolvable id makes
`check-connectors.ps1` skip that plugin's whole drift check silently. `INSTALL.md` carries the command
sequence and both, as its third migration section.

**Score:** 5

#### Pull Request

Rename the team side of the marketplace to dkj-subagents
