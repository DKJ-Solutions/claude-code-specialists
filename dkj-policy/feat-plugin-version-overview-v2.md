## feat/plugin-version-overview-v2

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

A second pre-PR review round on `plugin-versions`, run in parallel with the round that shipped as
PR #1599 -- landing the defects that round did not reach. The two rounds never saw each other; the
collision itself is filed as #1600 and is not retold here.

### CREATE

- [x] Fix the wrong-answer bug: where the install sha exists in the marketplace clone but is not an
  ancestor of HEAD, the verdict now consults `Compare-Version` before concluding the install is ahead,
  exactly like its `-not $existsInClone` sibling branch already did. Reachable after a history rewrite
  in the clone (the old object survives as a loose commit but is unreachable from HEAD); the wrong
  verdict told a consumer to run `claude plugin marketplace update` where `claude plugin update` was
  correct.
- [x] Fix four smaller defects in the same script: a stray blank rendered where an install record
  carried no version; `HEAD` printed for a non-git `.gcs-sha` fetch that has none; the missing-sha
  line blaming the install record even when it was the clone side that lacked a head; and two
  culture-aware `Sort-Object` calls in `check-report-lib.ps1` brought onto the ordinal sort this
  project's invariant requires (one of the two also redundant).
- [x] Harden `Get-ValidatedSha`: a recorded sha is shape-checked (`^[0-9a-f]{7,40}$`) before it reaches
  `git rev-parse` / `merge-base`; a malformed value degrades to the version comparison instead of
  reaching git.
- [x] Add coverage for the gap that let the wrong-answer bug ship: a `New-DivergedClone` fixture
  leaves an old commit resolvable but unreachable, pinning both directions of the tiebreaker plus the
  malformed-sha case (scenarios 12-14) and the asymmetric-gap regression carried over from the
  colleague's round (15-16). A scoped-assertion helper (`Assert-HasBetween` / `Assert-LacksBetween`)
  stops a wrong per-plugin line being satisfied by the footer's correct text sitting beside it -- the
  reason the `HEAD`/`sha` defect went unnoticed in the first place.
- [x] Cut the `plugin-versions` skill's always-on frontmatter description by one sentence that only
  restated, at less depth, what the body already carries -- roughly 50 of its ~230 tokens per session
  for every consumer with `dkj-policy` enabled.
- [x] Bring "device" back onto this repo's established "machine"/"checkout" wording in `INSTALL.md`
  and `dkj-policy/README.md`, and add a line to the skill page telling a consumer to redact the
  absolute, home-derived paths the script prints before pasting its output into a public issue.

### TEST

- [x] `scripts/tests/plugin-versions.tests.ps1`: 91 pass / 0 fail across all 16 scenarios, including
  the new 12-16 pinning the tiebreaker in both directions, the malformed sha, and both asymmetric-gap
  regressions.
- [x] Root copy and the `dkj-policy` plugin mirror of both touched scripts confirmed byte-identical
  (the shared-scripts drift check this repo runs before a push).
- [x] `check-plugin-integrity.ps1`: 0 errors.
- [x] `grep -c "history rewrite?" ` against `main` returns 0 -- confirmed the trunk still carries the
  bug this branch fixes, i.e. this branch is not redundant with PR #1599.

### DEPLOY: feat/plugin-version-overview-v2

A second pre-PR review pass on `plugin-versions.ps1` repairs the one defect its first pass shipped
with the trunk still carrying: where an install's recorded commit is reachable in the marketplace
clone but not an ancestor of its HEAD -- the state a history rewrite in the clone leaves behind -- the
verdict skipped the version-string tiebreaker its own sibling branch already used, and concluded
unconditionally that the install was ahead. The consequence was a wrong instruction:
`claude plugin marketplace update` printed where `claude plugin update` was the one that would have
closed the gap. Alongside it: four smaller output defects in the same script (a stray blank, a
wrongly-printed `HEAD`, a missing-sha line blaming the wrong side, and two culture-aware sorts brought
onto this project's ordinal-sort invariant), input sanitising on the sha before it reaches `git`, the
test coverage that closes the gap which let the original bug ship unnoticed, a token cut to the
skill's always-on frontmatter, and two small wording fixes.

**Score:** 3

#### What makes this deploy extra special

A consumer of the `dkj-policy` workflow whose marketplace clone has been through a history rewrite
stops being told to run the wrong command. Every consumer with `dkj-policy` enabled also pays a
slightly cheaper always-on cost for this skill, and reads clearer wording on its page. Bounded
reach: the wrong-instruction bug only fires on a clone that has actually been rebased or force-pushed
since the install was recorded, which is not the common case.

**Score:** 2

#### Pull Request

Second pre-PR review pass on plugin-versions

