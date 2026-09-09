## feat/1693-fixture-lib-dep-check

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
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

#1693 asks for a check that holds a suite's hand-listed fixture lib copies against what those libs
dot-source. Everything below the first heading was measured before anything was built, because this
repo's standard for a new gate is that it arrives measured -- and three of the four measurements
changed what got built.

#### What the measurements changed

1. **The scope in the issue is short.** It names five suites; **twelve** copy a lib into a fixture. Its
   five counts are all exactly right (8/8/8/6/2) -- the list was incomplete, not wrong.
2. **The real instance dot-sources through a VARIABLE.** On `origin/fix/1682-porcelain-line-parse`,
   `park-lib.ps1` reads

   ```powershell
   $parkPorcelainLib = Join-Path $PSScriptRoot 'git-porcelain-lib.ps1'
   if (Test-Path -LiteralPath $parkPorcelainLib -PathType Leaf) { . $parkPorcelainLib }
   ```

   so the dot-source command's own text is `. $parkPorcelainLib` and names no file at all. The first
   version of this reader matched on that text and **missed the only real instance of the class it was
   built for**. Eight libs in `scripts/lib` dot-source a sibling and every one does it through a
   variable, so this is the normal shape here rather than an edge case. The reader resolves the
   variable to its last assignment before the dot-source, file-locally.
3. **The naive check is not born green, it is born 100% false.** Reading any literal in the
   `Copy-Item` rather than its `-Destination` produced two findings on a clean tree and both were
   wrong:
   - `consumer-check-lib.tests.ps1`, whose fixture **deliberately** has no `measure-context-lib`
     sibling because it exists to prove the guarded load degrades correctly. Its destination is a flat
     directory, so binding to `-Destination` excludes it for the right reason rather than by luck.
   - `internal-note.tests.ps1`, which copies `release-lib.ps1` and four of its five siblings and is
     **right** not to copy `branch-info.ps1`: that seam is repo-owned and the caller supplies the
     consumer's own copy from its repo root, which `release-lib.ps1` says in so many words.

   This repo declines a findings-list gate on its false-positive rate -- the stale-path check, 124
   findings, all false -- so shipping without those two fixes would have been proposing exactly what
   it turns down.
4. **Both `Copy-Item` shapes are in the tree.** Most suites write `-Destination`;
   `source-repo-guard.tests.ps1` writes it positionally. A reader that handled only the named form
   silently stopped treating that suite as a subject, which is the same silent-miss class the gate
   exists to remove.

#### Proven against the real instance, both directions

The gate is **silent on this tree**, so a synthetic assert alone would not prove it fires. Measured by
reconstructing the defect from `origin` read-only:

| state | subjects | findings |
|---|---|---|
| `origin/fix/1682-porcelain-line-parse` as it stands (list repaired) | 1 | **0** |
| the same files with the porcelain copy line removed (the pre-repair commit) | 1 | **1** |

and the one finding names `park-cycle.tests.ps1: park-lib.ps1 dot-sources git-porcelain-lib.ps1, which
the fixture does not copy`. On the real tree: **84 suites read, 12 subjects, 0 findings.**

#### Where it lives, and why not where the issue proposed

The issue suggests a numbered check in `check-plugin-integrity.ps1`. It runs as a **suite** instead,
and the reason is collision rather than taste: `feat/1680-synopsis-check-list` is open and repairing
that script's `.SYNOPSIS` check list, so appending a check would have meant both branches rewriting
the same block -- and the merits were even, since that file already carries a fixture-shaped check
(`[fixture-git]`) while `scripts/tests/` already carries three tree-walking meta-suites. It runs in
the same two places either way (`open-pr.ps1`'s test gate and CI's `suites` shards). Moving it later
is a one-call change: all the reading is in the lib and `Get-FixtureDepReport` is the whole answer.

#### Two defects of my own, found by measuring rather than by review

- **The heredoc ate a backslash.** `[\\/]` reached the file as `[\/]`, so the character class matched
  only a forward slash and the first reader silently found nothing at all. Separators are normalised
  through `[char]92`/`[char]47` now, and the reason is written beside them.
- **The memo was keyed on the path.** That is correct for the gate -- one report over a tree nothing
  is writing to -- and wrong for this lib's own suite, which rewrites the same fixture names between
  sections. Two asserts went red on a stale answer, and it read as a closure bug. Keyed on path +
  last-write ticks + length now, with its own regression assert, because a cache that is only correct
  while every caller remembers not to rewrite a file is the enforced-by-memory shape.

### CREATE

- [x] Measure the subject before building: 12 suites, not 5; the five named counts all correct
- [x] Measure the real dependency shape -- a variable, not a literal -- against `origin`'s copy of the
      #1682 branch, read-only
- [x] `scripts/lib/fixture-dep-lib.ps1`: the dot-source reader (both shapes, variable resolved to its
      assignment), the `-Destination` reader (named and positional), the closure walk, and the
      repo-owned seam exemption
- [x] Bind the copy reader to `-Destination` -- the first of the two false findings
- [x] The one-entry `branch-info.ps1` exemption -- the second, with the rule for a second entry stated
      and `repo-config.ps1` deliberately left out of it as a rule with nothing under it
- [x] Prove the gate fires on the reconstructed pre-repair state and is silent on the repair

### TEST

- [x] `scripts/tests/fixture-lib-deps.tests.ps1` -- 23 asserts: both dot-source shapes, a docstring
      example not counting, a named-but-not-dot-sourced `.ps1` not counting, source-vs-destination,
      the positional form, a switch between the positionals, the closure in one pass, a complete list
      staying silent, an absent dependency not being a finding, a cycle terminating, the seam
      exemption and its narrowness, the memo key, an unparseable file throwing, and the tree-wide gate
- [x] Both figures asserted at the gate (suites read AND subjects), so a silent pass cannot be a
      reader that found nothing to read
- [x] The lint gate (`check-plugin-integrity.ps1`) -- 0 errors
- [x] Wall-clock measured and reduced: 11.0-13.2s to 8.2-8.7s, by memoising the per-lib read and
      replacing one `FindAll({ $true })` with two type-targeted walks
- [ ] Code review (Victor #19) and cost review (Nolan #25) on the diff

### DEPLOY: feat/1693-fixture-lib-dep-check

A test suite that builds its fixture by hand-listing the libs it copies can no longer go stale against
what those libs dot-source. The dot-source is guarded on purpose -- a consumer whose plugin mirror
predates a lib must not crash on load -- and in a fixture that same guard turns *"nobody listed this
dependency"* into *"the function is undefined"*, which in one case surfaced as an empty return value
rather than an error: ten asserts red in one suite while three others exercising the same lib stayed
green, each one assert away from the same failure. The new suite reads what each lib actually
dot-sources, including through the variable this tree does it with, and holds every fixture's copy list
against the whole dependency closure.

It is silent on this tree today, and it was proven against the one real instance rather than against
an invented one: reconstructed from the branch that introduced the first lib-to-lib dependency, the
pre-repair state yields exactly one finding naming the right pair, and the repaired state yields none.
The two false findings a naive version produced are what shaped it -- the destination is the subject
rather than any path in the command, and a repo-owned seam the caller supplies is not a debt a fixture
owes.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing here travels. The lib is not in the shared-script registry and the gate reads this
repo's own `scripts/tests/`, so a consumer receives no file, no new check and no new failure mode from
it. What it protects is the tree that ships their plugin: the ten red asserts it exists to catch were
in a branch repairing a shared lib, and a stale fixture there is a defect that reaches a release
looking green.

**Score:** N/A

#### Pull Request

A test fixture's lib copy list is held against what those libs dot-source
