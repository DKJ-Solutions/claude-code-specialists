## fix/1772-plugin-versions-noop-action

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

[#1772](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1772) reports that
`plugin-versions.ps1` classifies an install whose sha is an ancestor of clone HEAD as `behind` and
prescribes `claude plugin update`, and that in the sub-case where the two **version strings match** and
only the commit differs, that command is a measured no-op. Both halves stand: the verdict was set
per-case and the action unconditionally, one block below it.

#### The decision the issue left open, and how it was taken

The issue names two candidate repairs -- prescribe `uninstall` + `install`, or report the state and
prescribe nothing -- and calls it a decision rather than a repair. Taken as **report, prescribe
nothing**, on two grounds:

- The gap is unreleased work by construction: the clone tracks the source's trunk and an install sits
  on the last release. An `uninstall` + `install` would cross the boundary, but it would put a consumer
  on code no release has shipped, which is not what a staleness report should nudge anybody towards.
- It is also unmeasured. The issue infers it from how `update` arbitrates; this branch has not tested
  it, and this repo's own rule is that a proposed repair naming a mechanism nobody verified is worse
  than the defect, because it then carries a citation.

#### What the fix also has to reach, and it is the half the issue does not name

`-Brief` maps `behind` to `[ERROR]`, and `connector-sessioncheck` forwards those lines into a session's
context at every start. So the no-op was not only a wrong line in a report a person runs: it was the
loudest marker this tool has, fired at every session start of every checkout sitting between two
releases, prescribing a command that reports success and changes nothing.

### CREATE

- [x] `scripts/task/plugin-versions.ps1`: split the sha-ancestor branch three ways instead of setting
      one action for all of it -- versions differ (`behind`, update command), versions equal
      (`unreleased`, no command), one side has no version (`behind`, and the line says the release
      boundary cannot be read from here).
- [x] Give `unreleased` its own summary bucket in both views, and `[INFO]` rather than `[ERROR]` in
      `-Brief`, by the rule #1591 already wrote for a stale clone.
- [x] Two wrong statements repaired in passing, both inside the block being rewritten: the old
      "same version string" wording fired whenever the *install* had a version, so it claimed the two
      strings agreed when it was the clone's `plugin.json` that had none; and the default view's
      "none confirmed up to date and none confirmed behind" sentence fired whenever nothing was behind,
      including runs that had confirmed several up to date. It is now pinned to the all-undetermined
      case, which keeps its missing-clone hint.
- [x] `plugins/dkj-policy/scripts/task/plugin-versions.ps1` rebuilt via
      `scripts/sync/build-shared-scripts.ps1` -- the mirror is byte-identical by lint.
- [x] `plugins/dkj-policy/skills/plugin-versions/SKILL.md`: the sample output, the verdict table and
      the marker-split section all documented the old behaviour verbatim, including a table row saying
      the update command "fires even when the two `version` strings are equal".

### TEST

- [x] `scripts/tests/plugin-versions.tests.ps1`: scenario 2 rewritten as the regression guard (never
      `behind`, never an update command), new 2b (ancestor *and* a version bump -> genuinely behind) and
      2c (no clone version -> the honest wording), scenario 17 repointed at 2b's shape so `-Brief`
      still has a `behind` row to prove, new 17b (`unreleased` -> `[INFO]`, never `[ERROR]`, no command
      into a session start), and the every-code mix in 22 grown to six rows.
- [x] `Add-CloneCommit` gained an optional `-Version`, which is what makes the two ancestor cases
      buildable at all; every existing call site keeps its old behaviour.
- [x] 139 pass, 0 fail. `connectors.tests.ps1` (179) and `connector-sessioncheck.tests.ps1` (47) both
      still green -- both assert on this script's output, and the #1772 scope note flagged one of them.
- [x] Run for real in this checkout: the two plugins #1772 measured now report their own verdict with
      no command, and the summary reads `6 plugin(s): 4 up to date, 2 on the released version, with
      unreleased commits in the clone -- nothing to update` where it used to read `2 of 6 plugin(s)
      behind -- run the update command shown for each`.
- [x] Full lint + suite gate, via `open-pr.ps1`.

### DEPLOY: fix/1772-plugin-versions-noop-action

`plugin-versions` no longer tells a checkout that is simply sitting between two releases that it is
behind, and no longer hands it a command that cannot act. An install whose recorded commit is an
ancestor of the marketplace clone's HEAD **while both sides carry the same version string** is now
reported as what it is -- the released version, with unreleased commits in the clone -- in its own
summary bucket, with no command at all. `claude plugin update` arbitrates on the version string, so
across that boundary it reports *"already at the latest version"* and moves nothing; measured on
`dkj-policy` and `dkj-policy-bwj` at `4.33.0` on both sides, September 10, 2026
([#1772](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1772)).

The half that reaches furthest is `-Brief`, which `connector-sessioncheck` forwards into a session's
context at every start: that verdict was an `[ERROR]` carrying the no-op, so the loudest marker this
tool has fired at every session start of every checkout in the most ordinary state one can be in. It is
`[INFO]` now, by the same rule #1591 wrote for a stale clone -- an `[ERROR]` is for the verdict a reader
closes with a command here and now, and this one has no command.

Nothing was prescribed in its place, deliberately. An `uninstall` + `install` would cross a same-version
boundary, but it would put a consumer on code no release has shipped, and this branch has not measured
that it works -- so the report says the gap closes at the next release cut and stops there. Two wrong
statements inside the same block went with it: the *"same version string"* claim that fired when it was
the clone's `plugin.json` that had no version, and the *"none confirmed up to date"* summary sentence
that fired on runs which had confirmed several.

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo publishes a plugin rather than a subscribed service, so no subscriber sees this. The
reader who does is a consumer developer running `dkj-policy`, and that is the score above.

**Score:** N/A

#### Pull Request

plugin-versions no longer prescribes a no-op update for the same-version-newer-commit case
