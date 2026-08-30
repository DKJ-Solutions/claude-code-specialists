## Development: `fix/record-shape-count-enable-provenance-v1` · 20260830-132840

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN

Issue #1138 is the half of inbound #1130 that was deliberately left unrepaired: the `[RECORD-SHAPE]`
roll-up still counted every enabled plugin, so one enabled MACHINE-WIDE and never installed from this
root reached the headline a reader meets first. It was blocked on one fact -- does
`claude plugin install --scope project` ALWAYS write the enable into the repo's own settings? -- which
#1130 could not measure, because measuring it mutates the live register that its own test run asserts
the stability of.

#### Why the gate #1095 withdrew does not apply

That one read `scope == 'user'`, and #323 measured that the demotion writes exactly that scope -- so it
would have restored the silence #314/#315/#323 exist to end. Enable provenance is a different field and
the demotion does not touch it, so the objection does not transfer. It was unmeasured, not disproved.

### CREATE

- [x] Measure it, in a throwaway `CLAUDE_CONFIG_DIR` so the live register is never touched. Six shapes
      against Claude Code 2.1.251, all yes -- and the sixth stronger than a yes: with an unparseable
      `.claude/settings.json` the install FAILS and writes no register record, so the settings write is a
      precondition of the record rather than a side effect of it. Live register + user settings verified
      byte-identical before and after.
- [x] `Get-SettingsChainPaths`: a `RepoOwned` flag per layer, so no caller has to match a label -- a
      label is prose, printed in the messages, and could be reworded without anything noticing that a
      predicate elsewhere had quietly stopped matching.
- [x] `Get-EnabledPlugins`: return `RepoEnabledIds`, the subset of `Ids` whose DECIDING layer is one of
      the repo's own. Both repo layers count, not `settings.json` alone -- see DEPLOY.
- [x] `check-roster-sync`: the roll-up counts `$countedShapes`; the arms keep walking `$recordShapes`.
- [x] Un-nest the detail loop, which sat INSIDE the roll-up's `if`. Invisible while the two always fired
      together; gating the count turned that nesting into a silencer, which is the one outcome this
      change must not produce. Caught by the new test, not by reading.
- [x] Replace the comment that said the predicate was deliberately unchanged -- it now says the opposite
      of what the code does -- and the synopsis paragraph above it.
- [x] Mirror to the plugin (`build-shared-scripts.ps1`): 3 mirrors updated.

### TEST

- [x] `check-report-lib.tests.ps1`: `RepoOwned` on all three chain layers, and four `RepoEnabledIds`
      cases -- both repo layers count, a user-only enable does not, an id enabled in BOTH decides in the
      repo's (the failure direction that would be a false silence), and the set is always a subset of
      `Ids`.
- [x] `roster-sync.tests.ps1`: 11l-2, a machine-wide enable is not counted but STILL gets its detail
      line -- exactly one marked line reaches a session. 11l-3, the discriminator: two plugins, same
      wrong shape, differing only in where the enable comes from; the count, the denominator and the id
      list each name one of the two, while both arms fire. Without 11l-3 a predicate that simply stopped
      counting everything would pass.
- [x] Full gate: `check-plugin-integrity.ps1` 0 errors, all suites green.

### DEPLOY: `fix/record-shape-count-enable-provenance-v1`

The `[RECORD-SHAPE]` roll-up now counts only the plugins this repo's own settings enable. A plugin
enabled machine-wide and never installed from this root no longer reaches the headline -- a reader met a
count there for a state their repo did not create and could not fix from inside itself.

**The count and the headline moved; nothing else did.** Every shape still gets its detail line, with its
remedy, and those lines are what the session hook forwards. The detail loop turned out to be nested
inside the roll-up's branch, so it had to be lifted out first -- otherwise this change would have taken
the remedy away along with the headline.

**It rests on a measurement, which is what #1138 was waiting for**, taken against Claude Code 2.1.251 in
a throwaway `CLAUDE_CONFIG_DIR` so the live register was never touched. Six shapes -- a bare repo, an
enable already in the user layer, one already in `settings.local.json`, an explicit `false`, a repair
re-install after a hand-edit, and an unparseable settings file. All six write the enable into the repo's
own settings, and the sixth answers more than was asked: when it CANNOT write it, the install fails and
leaves no register record at all. So a record for this path with no repo-owned enable is not a state the
CLI can produce, and suppressing the count for one costs no coverage.

**It reads BOTH repo layers, not `settings.json` alone**, which is where it departs from what the issue
proposed. The install writes `settings.json`, but a person may afterwards move an enable into
`settings.local.json` -- ordinary, since that is the uncommitted personal layer and Claude Code honours
it at higher precedence. Gating on `settings.json` alone would go silent on a legitimately
project-installed plugin whose enable merely moved one file sideways: the exact class of silence this
marker exists to end.

**Score:** 2

#### What makes this deploy extra special

N/A. The marker and its remedy are unchanged for anyone reading a session; what moved is a count in a
non-counting roll-up, which no subscriber of a service sees.

**Score:** N/A

#### Pull Request

The [RECORD-SHAPE] count no longer counts a plugin this repo never enabled
