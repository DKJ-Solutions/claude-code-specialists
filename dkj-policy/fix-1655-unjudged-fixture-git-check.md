## fix/1655-unjudged-fixture-git-check

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

#### The measurement had to come before the check, and #1655 said so

The issue deliberately did not add the check, on the ground that the honest version of it needs a
measurement nobody had taken: this tree has a real false-positive class -- a git call that is a
QUESTION rather than a mutation -- and a rule that cannot tell the two apart is not worth having.
So the first step was a throwaway matcher run over two trees, and the check was only written once
the numbers said the classes separate cheaply.

- [x] Write a candidate matcher and run it over the tree as it stands -- expected 0 per the issue,
      measured **27 findings in 4 files**, so the #1635 sweep did not finish
- [x] Run the same matcher over the pre-sweep tree (`130dd259~1`) -- **182 findings in 18 files**
- [x] Classify every finding in both sets by hand: **0 probe false positives** in either
- [x] Measure the boundary the check does NOT take -- widening to a bare statement pipeline yields
      20 findings here, **20/20 value-returning questions**, which settles the "discarded" rule

### CREATE

- [x] Convert the 27 remaining call sites onto `scripts/lib/fixture-git-lib.ps1`, so the check is
      born green with no exemption list: `find-specialist-mentions.tests.ps1` (6),
      `shared-scripts.tests.ps1` (11), `source-repo-guard.tests.ps1` (9),
      `fresh-consumer.measure.ps1` (1)
- [x] Add check 35 (`[fixture-git]`) to `scripts/lint/check-plugin-integrity.ps1`, sharing the parse
      and the walk with checks 31 and 33 through `Get-PsScriptCommandAsts`
- [x] Close the loop in `fixture-git-lib.ps1`'s own docstring, which said nothing enforced it
- [x] Record the measurement in the system-administration lens, beside the other checks' own
- [x] Record the PowerShell comma-precedence trap in the portable manual -- it bit inside this work,
      and it is the source's layer rather than the lens's

### TEST

- [x] 15 new asserts in `check-plugin-integrity-docs.tests.ps1` (scenarios 76-84), pinning the
      boundary and not only the finding: the question, the converted form, the second invocation
      spelling, all three discard forms and their parenthesised variants, the AST-based clearing
      condition, the bare pipeline, and the scope
- [x] Probe the check's own stated boundary rather than trusting it -- which found the `[void]` gap
      the measurement could not, this tree holding only two of the three discard spellings
- [x] Code review found the same class one level deeper: only the `[void]` arm climbed out of
      `(...)`, so `$null = (& git ...)` and `(& git ...) | Out-Null` were both skipped. The unwrap is
      now shared by all three arms
- [x] And the clearing condition moved off line text onto the AST -- a `$LASTEXITCODE` sitting in a
      single-quoted string or a comment would otherwise clear a genuine miss, leaving nothing to notice
- [x] The three converted SUITES green on their own -- `find-specialist-mentions` (31 asserts),
      `shared-scripts` (608), `source-repo-guard` (46) -- plus `fixture-git-lib.tests.ps1` (15),
      which covers the lib they were converted onto. The fourth converted file,
      `fresh-consumer.measure.ps1`, is a measurement and asserts nothing by design, so it is checked
      by parse and by resolving its new dot-source rather than by a count
- [x] Cost review: check 35 itself is free on a gate run (11.21s vs 11.26s without it, 3 runs each --
      it rides the existing `Get-PsScriptCommandAsts` cache). The scenarios were not: written one
      rewrite-and-reinvoke per shape they cost 12 child gate runs, taking the docs suite from 54.5s to
      63.7s. Batched by expected verdict -- everything that must fire in one run, everything that must
      stay silent in the next -- that is 3 invocations and 57.3s, **+2.8s instead of +9.2s**, same asserts
- [x] The full lint gate green -- `[fixture-git] checked 85 -- 0 finding(s)`
- [x] The full test gate green -- all 81 suites in 211s

### DEPLOY: fix/1655-unjudged-fixture-git-check

A test suite can no longer reintroduce the fixture-git idiom that #1635 swept out. Check 35
(`[fixture-git]`) walks `scripts/tests/` for a git command whose output is discarded and whose exit
code is judged on neither the same statement nor the next -- the idiom that made a git which FAILED
indistinguishable from one that worked, so every assert below it read a repo that was never built and
blamed the script under test.

The sweep it enforces turned out to be unfinished, which is the finding rather than a side note. The
matcher read **27 unjudged calls still standing in four files** -- `find-specialist-mentions`,
`shared-scripts`, `source-repo-guard` and `fresh-consumer.measure`, whose spellings (`git ... 2>&1 |
Out-Null` with no `&`, and `& $git @(...)` over a scriptblock) the earlier search never reached. All
27 are converted here, so the check is born green with **zero exemptions**. Over the pre-sweep tree it
reads 182 findings in 18 files: the house style, measured.

What makes the check possible at all is that a git QUESTION reads its exit code **immediately** --
`rev-parse --verify --quiet` on a ref expected to be absent answers with exit 1 and is judged on the
next line. So a call is cleared when `$LASTEXITCODE` appears in the same statement or the next one, no
verb is special-cased, and no file is exempt: **zero probe false positives over both trees**. The
subject is deliberately a *discarded* result rather than every unjudged call -- widening to a bare
statement pipeline yields 20 findings here and all 20 are value-returning questions. All three ways to
discard are covered (`| Out-Null`, `$null =`, a `[void]` cast), each after one shared unwrap of any
`(...)` so a pair of brackets is not an escape hatch, and the clearing condition reads the AST rather
than the line text. None of those three came from the measurement -- this tree holds only the plainest
spelling of each -- but from probing the check's own stated boundary and from the review that followed.

**Score:** 3

#### What makes this deploy extra special

Nothing here reaches a consumer's own repo: the check reads `scripts/tests/`, which is workshop-only
and mirrored into no plugin. One portable page does change -- the system-administration manual gains
a tenth PowerShell trap (`@($i, $i + 1)` is `@($i, $i) + 1`, the comma binding tighter than the
addition), which travels to every consumer at the next release and is worth having: it produced nine
false findings inside the very pass that was deciding whether this check's false-positive rate was
acceptable.

**Score:** 1

#### Pull Request

A lint check for the unjudged fixture-git idiom, and the four suites the #1635 sweep missed
