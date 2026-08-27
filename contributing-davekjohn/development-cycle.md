## Development cycle: `fix/check-wait-zero-date-overflow-v1` · 20260827-151247

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

Root cause is `ConvertTo-CheckTimestamp` accepting `0001-01-01T00:00:00Z` as a real time; guard BOTH
shapes (string and `[datetime]`) and range-check before the `[int]` cast at both sites in
`Get-CheckWaitReport`. Closes #977.

#### The inbound verification, all six checks

Inbound #977 was picked up under the `triage-inbound` rule, and every half of it was held against the
tree before anything was built:

- **Subject** -- exists. `ConvertTo-CheckTimestamp`, `Get-CheckWaitReport` and `Format-CheckDuration`
  are all in `scripts/lib/pr-issues-lib.ps1`, quoted accurately.
- **Symptom** -- **reproduced**, which the report itself could not do ("I could not re-trigger the race
  on demand"). Feeding one unfinished check into the live function threw
  `Cannot convert value "-63923421840" to type "System.Int32"` -- the same error, the same magnitude.
  The race is not needed: the payload shape alone is sufficient.
- **Reasoning** -- stands, with one correction. The zero date does arrive as a non-`$null` value that
  the `continue` guard misses. But the report attributes that to 5.1's `ConvertFrom-Json` handing back
  a `[datetime]`, and on this machine it hands back a **`String`** -- measured, for the zero date and a
  real one alike. The string then parses to `MinValue` by the other branch, so the outcome is the same
  and the diagnosis holds on a mechanism that is not the one named.
- **Repair** -- named a real mechanism and **would not have fixed it**. Guarding only the
  `$Value -is [datetime]` branch, as proposed, leaves the string branch open -- i.e. the branch the
  crash actually came through here. The guard therefore moved to where both branches meet.
- **Size** -- the report's three doors recount to two that matter. Once the zero date is unreadable, no
  `MinValue` can enter `$finished`, so neither arithmetic site can see one; the range check is there for
  the *class* (a readable-but-absurd stamp from the same untrusted field), not for #977's own input.
  `Format-CheckDuration`'s `[int]` parameter is a **third door left standing on purpose** -- see TEST.
- **Repo** -- ours. The symptom was measured in a consumer, and the code is the source's: the root copy
  and the plugin mirror were byte-identical before the change.

### CREATE

- [x] `ConvertTo-CheckTimestamp`: normalise both shapes onto one variable, then reject year 1 -- the
      year rather than an equality test on `[datetime]::MinValue`, because a `MinValue` of Kind
      `Unspecified` sent through `ToUniversalTime` clamps back to the floor where the machine's offset
      is positive and shifts UP off it where it is negative. An equality test would hold in Amsterdam
      and miss in New York.
- [x] New `ConvertTo-CheckSeconds`: round, range-check, cast last. One helper rather than the same three
      lines twice, because the reversed order was written at both arithmetic sites and the unreachable
      guard was copied along with it.
- [x] `Get-CheckWaitReport`: both `$ran` and `$excess` go through the helper; the dead
      `if ($ran -lt 0) { $ran = -1 }` is gone with the cast that made it unreachable.
- [x] Lib header: "its two helpers" -> "its three helpers".
- [x] `build-shared-scripts.ps1` -- the plugin mirror regenerated, not hand-edited.

### TEST

- [x] 14 asserts added to `scripts/tests/pr-issues.tests.ps1`, in their own `#977` section. Suite green:
      **239** asserts, up from 225.
- [x] The crash payload is asserted for the RIGHT line and not merely a surviving one: an unfinished
      check takes no part in the ordering, so `'lint-en-tests' finished last` is what the run now
      prints, and `claude-review` appears nowhere in it.
- [x] Both timestamp shapes asserted separately -- the string form is the one the proposed repair would
      have missed, so a suite that only pinned the `[datetime]` form would have gone green over it.
- [x] The class asserted at both arithmetic sites, including the excess site, which is only reachable
      when a non-required check governs.
- [x] `ConvertTo-CheckSeconds` asserted directly, so the round-check-cast ORDER is pinned rather than
      inferred from the lines it produces.
- [~] `Format-CheckDuration`'s `[int]$Seconds` parameter left alone. #977 calls it "a third door onto the
      same failure", and after the two guards above no caller can reach it: the only producers of a
      `Seconds` value from untrusted input are the two sites now returning `-1`, and `-WaitedSeconds`
      comes from ship-pr's own clock. Widening a signature nothing can reach is the pre-emptive fix this
      repo declines -- named here rather than built. The report's stated reason for it does not stand
      either: that docstring promises `''` for a **negative** input, which is representable, and says
      nothing about out-of-range.
- [x] Lint gate: 0 errors over 28 checks, `[script-ascii]` and `[shared-script]` included -- the two the
      new comment blocks and the regenerated mirror could have broken.

### DEPLOY: `fix/check-wait-zero-date-overflow-v1`

`ship-pr` no longer dies between the merge decision and the merge when a check registers while the CI
wait is returning. `gh pr checks --json` serialises a check that has not finished yet as the zero time
`0001-01-01T00:00:00Z` -- not as null, not as an empty string -- and `ConvertTo-CheckTimestamp` accepted
it as a real timestamp, so the caller's own "unreadable, skip this record" guard never fired and the
`[int]` cast in the DarkGray *which check governed the wait* line overflowed on 63.9 billion seconds. A
reporting line took the run down after it had printed `CI green.`, leaving the PR unmerged and the entry
unfolded with every check green -- the half-state the step's own comment calls "the state nothing
reports". The zero time is now unreadable in both shapes gh can send it in, so an unfinished check drops
out of the ordering it never belonged in, and the seconds arithmetic rounds and range-checks before it
casts, at both sites, so no timestamp from that payload can throw there again.

**Score:** 3

#### What makes this deploy extra special

Every consumer runs this code from their plugin cache, and the failure window is not rare: the CI wait
is the one place in `ship-pr` that is guaranteed to be racing GitHub, so any check that registers while
`--watch` is returning is in it. It cost a real run in `BWJ-ecommerce/xoxowildhearts` (PR #68), which is
where #977 was filed from -- and the recovery reads as a fluke rather than a fix, because re-running a
few minutes later merges cleanly once the check has a real `completedAt`. The consumer-visible half is
therefore not the crash but the trust: a ship that stops after `CI green.` no longer leaves anyone
guessing whether the merge happened.

**Score:** 4

#### Pull Request

A not-yet-finished check's zero timestamp no longer kills ship-pr after CI is green
