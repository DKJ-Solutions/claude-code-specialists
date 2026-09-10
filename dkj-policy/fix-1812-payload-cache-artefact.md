## fix/1812-payload-cache-artefact

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

#### What #1812 asked for, and in which order

The issue is explicit that the measurement comes first: *"The resolution order -- record -> cache payload,
versus clone read directly -- was NOT measured. That is the measurement this issue asks for, before either
the prose or a new lane is written."* So: measure, then repair the prose the measurement contradicts, then
decide whether a lane is warranted and build it if so.

- [x] Measure the resolution order on a live machine, and record what was run
- [x] Measure what actually MOVES a payload -- the half #1810 cannot be designed without
- [x] Answer the issue's two open questions: does `uninstall` reap a tree, and does anything reap one
- [x] Repair every place in the tree that states the mechanism wrongly
- [x] Decide on the lane, and build it if the measurement warrants one

### CREATE

- [x] `Get-PayloadTreeVerdict` in `scripts/lib/tidy-lib.ps1` -- the pure classifier
- [x] Lane 12 in `scripts/maintenance/tidy-machine.ps1`, report-only, no command handed over
- [x] `CLAUDE.md`: the repo slot's account of what a session loads
- [x] `.claude/specialists/lenses/05-15-extension.md`: the measurement in full, under the #845 bullet
      whose closing paragraph named this exact untested case
- [x] `.claude/specialists/lenses/06-25-extension.md`: the load-path bullet -- right about the clone,
      wrong about what moves it
- [x] `plugins/dkj-policy/README.md` and `INSTALL.md`: the consumer-facing half
- [x] `scripts/maintenance/measure-skill.ps1`: `claude plugin details` prices the payload, not the clone
- [x] The skill page and the plugin mirror

#### What was deliberately NOT done

- [~] A reaper, behind a flag or otherwise -- dropped. Lane 10 already settled this shape for the scratch
      root (#1659, #1668), no plugin-cache verb exists to delegate to, and a tree can be leased by a live
      session. The lane reports and hands over nothing to run.
- [~] A detector for the enabled-without-a-record case -- dropped, and not because it is unwanted: it is
      #1802's own suggested repair and belongs with `plugin-versions`, which already reads both files.
      This branch measured it from the other end (a checkout enabling three plugins loaded none of them)
      and left the repair where it was filed.

### TEST

- [x] `scripts/tests/tidy-lib.tests.ps1` -- section 9 drives the classifier over states no machine here
      has been in, and section 10 pins lane 12 to the pure verdict and to the no-delete promise
- [x] `check-plugin-integrity.ps1`: 0 errors
- [x] Every suite under `scripts/tests/`
- [x] `tidy-machine.ps1 -MachineOnly -DryRun` against the real machine: 30 trees, 22.2 MB, 11 left alone

### DEPLOY: fix/1812-payload-cache-artefact

**A session loads neither this tree nor the marketplace clone.** It loads an extracted copy under
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version-or-sha>/`, named by the `installPath` of the
install record for that checkout. Measured September 10, 2026 (Claude Code 2.1.267): the running process
writes a lease at `<installPath>/.in_use/<pid>` and holds it for the life of the session, and the clone
holds none. Two accounts of this stood in the tree, each half of one mechanism -- `CLAUDE.md` and two
lenses said the clone is what a session reads, #1802 said a dead consumer survives because its cache
survives. Both are now stated as what they are: **plugin components load from the payload, and a document
named by an absolute `@`-import loads from the clone**, which is why a refresh visibly moved #845's
`@`-imported persona while leaving every hook and skill on the same bytes.

**And the conclusion that bullet rested on does not survive the measurement.** A
`claude plugin marketplace update` advanced the clone 104 commits and left every payload byte-identical,
with `installed_plugins.json` unchanged to the byte; `update --scope project` then answered *"already at
the latest version"* and `install --scope project` *"already installed"*, neither extracting anything,
with the clone's copy of that same version carrying a skill the installed payload did not. Both verbs
decide on the **version string**, so content that lands without a bump is unreachable by the documented
pair -- not stale by hours, but until the next cut. That is the arithmetic #1810 was missing, and it is
the load-bearing half: the unit that reaches a session is a release, pulled per checkout, per machine.

**Lane 12 of `tidy-machine.ps1` reports the artefact nothing was reading.** The harness marks a tree no
record points at with `.orphaned_at` and stamps `.last_inuse_sweep`, but marking is not reaping: 30 of 41
trees on the machine measured carried that mark, 22.2 MB of 32.6 MB, the oldest six days old and every one
still on disk -- and `claude plugin uninstall` was measured to remove the record and leave the payload,
so lane 11's handover grows that pile. The lane groups by plugin id, never counts a tree a live process
still holds a lease on, and hands over **no command at all**: there is no plugin-cache verb, and a
recursive delete under a user's home is the primitive #1659 exists to prevent.

**Score:** 3

#### What makes this deploy extra special

N/A -- how a plugin reaches a session is machine administration for the people who run these repos; no
subscriber of any service reaches it.

**Score:** N/A

#### Pull Request

The extracted payload cache is what a session loads
