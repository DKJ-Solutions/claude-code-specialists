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

The gate was **silent on this tree** when this was written, so a synthetic assert alone would not have
proved it fires (it is not silent any more -- see below). Measured by
reconstructing the defect from `origin` read-only:

| state | subjects | findings |
|---|---|---|
| `origin/fix/1682-porcelain-line-parse` as it stands (list repaired) | 1 | **0** |
| the same files with the porcelain copy line removed (the pre-repair commit) | 1 | **1** |

and the one finding names `park-cycle.tests.ps1: park-lib.ps1 dot-sources git-porcelain-lib.ps1, which
the fixture does not copy`. On the real tree: **84 suites read, 12 subjects, 0 findings.**


#### And the gate stopped being vacuous while this branch was open

When the reader was written, **no lib in `scripts/lib` dot-sourced a sibling at all** -- so the
tree-wide pass had nothing to check and only the synthetic asserts could prove the mechanism. Then the
stale-CI gate refused the first ship (`main` had gained a commit after the certificate), bringing the
branch forward merged **#1682**, and the map changed under it:

```
fanout-lib.ps1        -> git-porcelain-lib.ps1, native-capture-lib.ps1, ref-print-lib.ps1
git-porcelain-lib.ps1 -> native-capture-lib.ps1
park-lib.ps1          -> git-porcelain-lib.ps1
```

So the gate now measures a real closure, on the very dependency #1693 was filed about -- and it comes
back **0 findings over 12 subjects**, which is it **confirming that branch's repair of the five copy
lists** rather than waiting for a first subject to exist. The synthetic asserts stay: a green tree
still cannot tell a working reader from a broken one.
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
  sections. Two asserts went red on a stale answer, and it read as a closure bug. **Found in a memo I
  had written, and it survived into the shared one**: the code review then removed my walker in favour
  of `script-contract-lib.ps1`'s, whose memo had the identical path-only key -- so the same two asserts
  went red a second time, and the repair moved to the lib that owns it. See the review section below.


#### What the reviews changed, and one of them changed the design

**Victor #19 found a bug and a duplication, and the duplication is the bigger of the two.**

- **The bug.** `-ErrorAction`, `-WarningAction` and `-InformationAction` were in the switch list the
  positional walk uses to tell a switch from a value-taking parameter. They are not switches, unlike
  `-Verbose` and `-Debug`. Reproduced before repairing: `Copy-Item -ErrorAction Stop $src (Join-Path
  $dir 'scripts\lib\a-lib.ps1')` lost its destination **entirely** -- the reader returned nothing --
  because `Stop` was counted as the first positional. No suite writes that today, which is exactly why
  it needed a review to find and now has an assert to keep.
- **The duplication, which was the actual defect.** `script-contract-lib.ps1` already resolves a
  dot-source through a variable -- `Get-ScriptDotSourceTargets`, with `Get-AstPathHints` doing the
  variable half -- and its own docstring says why it exists: *"so '. $configPath' resolves through its
  assignment, which is how three of the four dot-source shapes in this tree are written"*. I had built
  a second AST walker beside it, in the same week as a sibling issue titled *"the git porcelain line
  parse is a second literal"*. That is the same mistake with a citation attached. So the reader now
  **delegates** and keeps only the shape conversion (absolute path to bare leaf), which is the whole
  difference between the two questions. It also gained two shapes the hand-rolled version never had:
  a dot-source built from the repo root, and the `& { . $args[0] }` idiom.

  **And delegating forced a repair in the shared lib, which is the part worth knowing.** That walker's
  memo was keyed on `"$Path|$RepoRoot"` with no file identity -- correct for its only caller so far, a
  SessionStart check reading files nothing rewrites, and wrong the moment a caller rewrites one. This
  suite does exactly that, deliberately, to make one fixture lib mean something different between
  sections. On the path-only key two asserts went red on a stale answer, reading as a bug in the walk.
  The key now carries the last-write ticks and the length, which costs one stat (~0.13 ms) against a
  re-parse of thousands of lines and turns a memo that is only correct while every caller remembers not
  to rewrite a file -- the enforced-by-memory shape -- into one that is correct by construction.
  `script-contract-lib.ps1` is in the shared registry, so that repair travels to consumers.

**Nolan #25 answered the cost question and produced two more cuts.** His headline is that none of this
was ever visible on the gate: the recorded suite durations run to 237s and nine suites already sit above
100s, so an 8s suite is 15-30x smaller than what sets a shard's critical path. Taken anyway, because
both cuts are correct and free:

- **Skip the parse of a suite whose text has no `Copy-Item` in it.** Only 18 of 84 files contain the
  string, so 66 were being parsed to prove they have none: 725 ms to 275-281 ms for the subject scan.
- **Read each subject's copy list once.** `Get-FixtureDepReport` computed it to decide whether a suite
  is a subject and then `Get-FixtureDepFinding` re-parsed the same file to compute it again: 447 ms
  against 257 ms over the twelve real subjects.

He also corrected an attribution I had written into the lib: the memo supplied ~97% of the first
round's saving and the typed-`FindAll` split ~3%, where my comment implied comparable weight.

**Wall-clock, three runs each, end to end:** 11.0-13.2s for the first working version, 8.2-8.7s after
the first round, **2.51-2.54s** as it stands. The report itself is 1,737 ms of that.

**Two more slips of my own, both from the same escaping trap.** A `\t` in a `sed` replacement became a
literal tab and broke a measurement script, after `[\\/]` had already reached a file as `[\/]` earlier
on this branch. Both are recorded beside the code that avoids them, because the pattern is the same one
`.claude/rules/language-layers.md` already warns about for `sed` and `\u`.

**One thing Nolan flagged that is NOT repaired here, and is not a defect.** This suite is one of
nineteen with no entry in `scripts/tests/suite-durations.json`, so the shard packer charges it the
maximum recorded value until `record-suite-durations.ps1` next runs against a CI run that includes it.
That is the documented fallback for any new suite, self-correcting, and shared with eighteen others --
not something this branch introduced or should fix.
### CREATE

- [x] Measure the subject before building: 12 suites, not 5; the five named counts all correct
- [x] Measure the real dependency shape -- a variable, not a literal -- against `origin`'s copy of the
      #1682 branch, read-only
- [x] `scripts/lib/fixture-dep-lib.ps1`: the `-Destination` reader (named and positional), the closure
      walk, and the repo-owned seam exemption -- the half of the question nothing else in the tree asks
- [x] Bind the copy reader to `-Destination` -- the first of the two false findings
- [x] The one-entry `branch-info.ps1` exemption -- the second, with the rule for a second entry stated
      and `repo-config.ps1` deliberately left out of it as a rule with nothing under it
- [x] Prove the gate fires on the reconstructed pre-repair state and is silent on the repair
- [x] **Delete the second AST walker** and delegate the dot-source half to
      `script-contract-lib.ps1`'s `Get-ScriptDotSourceTargets` -- the duplication the code review found,
      which is the defect this branch's own sibling issue is about
- [x] Repair that shared walker's memo key, which delegating exposed: path-only, so a caller that
      rewrites a file is served a stale answer. It now carries the last-write ticks and the length, and
      the mirror is rebuilt because that lib travels
- [x] Remove `-ErrorAction`/`-WarningAction`/`-InformationAction` from the switch list -- they take a
      value, and with them there a `Copy-Item -ErrorAction Stop $src $dst` lost its destination entirely

### TEST

- [x] `scripts/tests/fixture-lib-deps.tests.ps1` -- 23 asserts: both dot-source shapes, a docstring
      example not counting, a named-but-not-dot-sourced `.ps1` not counting, source-vs-destination,
      the positional form, a switch between the positionals, the closure in one pass, a complete list
      staying silent, an absent dependency not being a finding, a cycle terminating, the seam
      exemption and its narrowness, the memo key, an unparseable file throwing, and the tree-wide gate
- [x] Both figures asserted at the gate (suites read AND subjects), so a silent pass cannot be a
      reader that found nothing to read
- [x] `scripts/tests/script-contract.tests.ps1` -- two asserts on the SHARED walker's memo key, from
      that lib's own side: whoever edits that memo next reads that file, and an assert two libs away is
      one nobody finds (295 pass, 0 fail)
- [x] The lint gate (`check-plugin-integrity.ps1`) -- 0 errors
- [x] Wall-clock measured and reduced across two rounds: 11.0-13.2s to 8.2-8.7s to **2.51-2.54s**, by
      delegating to the shared walker (one memo instead of two engines), skipping the parse of a suite
      whose text has no `Copy-Item` at all, and reading each subject copy list once rather than twice
- [x] Code review (Victor #19) and cost review (Nolan #25) on the diff -- one bug, one duplication
      that changed the design, and two further cost cuts

### DEPLOY: feat/1693-fixture-lib-dep-check

A test suite that builds its fixture by hand-listing the libs it copies can no longer go stale against
what those libs dot-source. The dot-source is guarded on purpose -- a consumer whose plugin mirror
predates a lib must not crash on load -- and in a fixture that same guard turns *"nobody listed this
dependency"* into *"the function is undefined"*, which in one case surfaced as an empty return value
rather than an error: ten asserts red in one suite while three others exercising the same lib stayed
green, each one assert away from the same failure. The new suite reads what each lib actually
dot-sources, including through the variable this tree does it with, and holds every fixture's copy list
against the whole dependency closure.

It had nothing to check when it was written -- no lib dot-sourced a sibling -- so it was proven against
the one real instance rather than against an invented one: reconstructed read-only from the branch that
introduced the first lib-to-lib dependency, the pre-repair state yields exactly one finding naming the
right pair, and the repaired state yields none. **That branch has since merged**, so the gate now
measures a live closure through `park-lib` and `fanout-lib` and comes back clean over twelve subjects --
confirming its repair of the five copy lists rather than waiting for a first subject to exist. The two
false findings a naive version produced are what shaped it: the destination is the subject rather than
any path in the command, and a repo-owned seam the caller supplies is not a debt a fixture owes.

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
