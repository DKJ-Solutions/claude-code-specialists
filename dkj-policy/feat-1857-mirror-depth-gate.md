## feat/1857-mirror-depth-gate

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

A shared script exists twice at different depths; the drift lint proves the two copies identical as TEXT, and nothing proves identical BEHAVIOUR where a path resolves off $PSScriptRoot across the plugin-root boundary. Measured: 3 of 34 entry points do that, and none has a suite that runs its mirror.

#### What the report got right, and the one thing it did not

Issue #1857 states that no suite ever EXECUTES a plugin-mirror copy. That is false as written:
`scripts/tests/git-identity-gate.tests.ps1` runs the mirror of `check-git-identity.ps1` from its own
directory, and its comment states this issue's own argument verbatim, four weeks earlier. Verified
before any of the work below was started.

What survives the correction is sharper than the report. That one suite covers a script that resolves
nothing above its own `scripts\` folder -- so it proves a dot-source, not a depth. The scripts that
DO cross the plugin-root boundary had no mirror execution at all.

### CREATE

- [x] `Get-DepthSensitiveResolutions` in `scripts/lib/shared-scripts-lib.ps1` -- via the AST, so a
      wrapped Join-Path is read like a single-line one, and covering both forms: a literal with two or
      more leading `..` segments, and a nested `Split-Path -Parent` chain that contains no `..` at all.
- [x] `MirrorRun` / `MirrorRunExempt` on the registry, beside `LibOnly`, `Skill` and `MeasureArgs`, and
      declared on the three pairs that have an answer.
- [x] Check 39 in `scripts/lint/check-plugin-integrity.ps1`, plus its entry in the file's own check
      list (check 37 holds the two together).

#### The gate found a third crossing on CI, which the branch could not see

The local measurement was two. `adopt-workflow-folder`'s PR-template reference -- the resolution #1857
was actually filed about -- merged to `main` while this branch was being built, and check 39 reported it
on its FIRST CI run, because CI tests the branch merged with the trunk. The branch was then rebased onto
it, the pair declared, and `adopt-workflow-folder.tests.ps1` given the mirror run it lacked.

Worth keeping for two reasons. A count taken from a branch base is a snapshot, and this one went stale
inside a day. And a gate whose subject is "what nobody has thought about yet" is only measured honestly
against the trunk -- the local run said the tree was clean and was right about the tree it could see.

### TEST

- [x] `scripts/tests/config-blueprint.tests.ps1` -- runs the adopt-config MIRROR against a fresh
      consumer fixture. Verified non-vacuous: `Get-RepoPluginRoots` returns 0 roots for both fallback
      routes from the mirror, so the pass can only mean candidate 1 resolved.
- [x] `scripts/tests/policy-drift-report.tests.ps1` -- runs the mirror on the same fixture the root
      copy was just measured on, and holds its answer to that answer.
- [x] `scripts/tests/shared-scripts.tests.ps1` -- eight unit asserts on the detector (both forms, the
      one-hop and non-leading `..` non-subjects, the wrapped statement, a missing file), plus the
      declarations held against the tree.
- [x] `scripts/tests/check-plugin-integrity-docs.tests.ps1` -- six gate scenarios, both directions.
- [x] `scripts/tests/adopt-workflow-folder.tests.ps1` -- runs the MIRROR of the third crossing, the one
      the gate found on CI. It can only resolve candidate 1: candidate 2 from the mirror would be
      `plugins/dkj-policy/plugins/dkj-policy/templates/`, which does not exist. And the assert is on the
      template LANDING rather than on exit 0, because an unresolved reference places nothing and only
      warns -- a silent miss every other assert in that suite stays green over.
- [x] Full gate green: 0 error(s), `[mirror-depth] checked 78 -- 2 crossing, 3 with a declared suite`.
- [x] Lesson recorded in `.claude/specialists/lenses/05-15-extension.md`, beside the other
      measurements behind these checks.

### DEPLOY: feat/1857-mirror-depth-gate

A shared workflow script exists twice -- the workshop source and the plugin mirror a consumer runs --
and check 8 holds the two byte-identical. That proves they are the same TEXT and says nothing about
behaviour, and the equality is what hides the gap: the two copies sit at different depths, so a
`$PSScriptRoot` resolution ascending two levels lands on the repo root from one and the plugin root
from the other. Identical characters, different folder, nothing to diff.

Check 39 refuses such a resolution while it is UNDECLARED: the pair must name the suite that runs its
mirror, and that suite must exist and name the mirror, so a declaration cannot be fiction. Whether the
run asserts anything stays the suite's job -- the same line check 18 draws between this gate and a
skill page. One hop is deliberately not a subject, because `..\lib\...` is the same folder relative to
the file in both copies; flagging it would bury the crossings under the thirty-odd that cannot differ.

All three crossings were already correct. What was missing was the proof: they had been verified by
hand, and the copy that fires in every released install is the one no suite executed. All three now do.

**Score:** 3

#### What makes this deploy extra special

Nothing here reaches a subscriber: it is a gate over this repo's own shared-script mechanics, and a
consumer sees no behaviour change at all. What it protects is theirs, though -- the mirror is the copy
they run, and it was the copy nothing exercised.

**Score:** N/A

#### Pull Request

Gate the depth-sensitive resolutions in mirrored shared scripts
