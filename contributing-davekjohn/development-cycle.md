## Development cycle: `fix/pr-title-carries-branch-prefix-v1` · 20260826-173057

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### Where this came from

Inbound issue [#936](https://github.com/DaveKJohn/claude-code-specialists/issues/936), picked up while
PR [#935](https://github.com/DaveKJohn/claude-code-specialists/pull/935) was shipping. The report is this
repo's own, filed an hour earlier, so the pickup verified all five of the things a report can be wrong
about before any of this was written -- the symptom (still true: `Get-PrTitle` strips nothing and PR #934's
doubled title is in the record), the reason (verified in the docstring, which states the premise that
expired), the proposed repair (both directions it names exist as described), the subject (`Get-PrTitle` is
where the report says it is), and the size (one function, one call site, one suite -- the report claims no
count).

### CREATE

- [x] `Get-PrTitlePrefixFinding` added to `scripts/lib/pr-body-lib.ps1`, bounded to the branch's own
      prefix and normalising by calling `Get-PrTitle` with no prefix rather than repeating its rules
- [x] `Get-PrTitle`'s "NO PREFIX IS STRIPPED" paragraph rewritten -- it invited whoever met the case to
      come back to it, and the premise it rested on ("a defect that has never happened") had expired
- [x] the title gate added to `scripts/release/open-pr.ps1`, beside the link gate, with the gate list in
      its `.DESCRIPTION` and the `-Force` parameter's own text extended to name it
- [x] the plugin mirrors regenerated with `scripts/sync/build-shared-scripts.ps1`
- [~] no change to `new-branch.ps1`, which is where the prefix enters. Refusing there as well would catch
      it earlier, but the entry can be hand-edited afterwards, so the gate at the PR is the one that
      cannot be walked around -- and a second refusal for one mistake is a redesign the report did not ask
      for
- [~] no change to `.github/workflows/branch-entry.yml`. The CI gate exists because the local gates are
      escapable by not running the scripts, but the composed title is not in the document it reads: the
      doubling only exists once `open-pr` puts the branch type in front. There is nothing there for CI to
      hold

### TEST

- [x] 12 new asserts for `Get-PrTitlePrefixFinding` in `scripts/tests/pr-body.tests.ps1` -- the branch's
      own prefix in four shapes, the three titles a `^\w+:` stripper would have mangled, the two
      normalisation shapes, and the three no-finding cases
- [x] one assert pinning that `Get-PrTitle` **still** doubles, so nobody "fixes" the composer later and
      leaves the entry -- the copy `CHANGELOG.md` keeps -- quietly wrong
- [x] `scripts/lint/check-plugin-integrity.ps1`: 0 errors, all 28 checks
- [x] the test gate: all 52 suites green in 59s

#### One measurement worth not repeating

Running the suites by hand in a loop over `$LASTEXITCODE` reported `sync-rules.tests.ps1` as failing while
its own output said `OK: all 61 asserts passed`. The suite sets no exit code at all, so the variable still
held `-1` from something earlier in the run. `Invoke-TestSuiteGate` in `scripts/lib/native-capture-lib.ps1`
is the reader that gets this right, and it is what `open-pr` and CI both use. An ad-hoc runner is not the
gate.

### DEPLOY: `fix/pr-title-carries-branch-prefix-v1`

`open-pr.ps1` now refuses a branch whose changelog entry gives its title a type prefix the script is about
to add itself ([#936](https://github.com/DaveKJohn/claude-code-specialists/issues/936)). The type comes off
the branch name and is composed in front of the entry's words, so a title typed as `fix: the fallback
drops ...` on a `fix/` branch becomes `fix: fix: the fallback drops ...`. That is not hypothetical: PR
[#934](https://github.com/DaveKJohn/claude-code-specialists/pull/934) opened under exactly that title
earlier the same day, and nothing refused it -- `open-pr` prints the composed title as a `DarkGray`
progress line and carries on, so it was caught by eye in `ship-pr`'s output and repaired by hand with
`gh pr edit --title`.

**`Get-PrTitle` still strips nothing, and that is the repair rather than the absence of one.** The doubled
line is not only what the PR is called: the same words are the folded entry's `#### Pull Request` section,
so they travel verbatim into `CHANGELOG.md` and on into the release documents. Stripping in the composer
would have corrected the copy a reviewer sees for a day and kept the copy that lasts. The refusal sends the
author back to the entry, which is the single edit that fixes both -- the same doctrine the link gate states
one block above, where a fold-time rewrite was declined for the same reason.

**The guard is bounded to the branch's own prefix**, which is what makes it safe to refuse on.
`Get-PrTitlePrefixFinding` matches `<this branch's type>:` and never `^\w+:` -- the fear of a stripper that
mangles a legitimate title like `sync-roster: the ignore list is empty` is precisely why the guard was left
out when `Get-PrTitle` was written, and its docstring asked to be revisited if the case ever arrived. It
did, so the paragraph now records what happened and where the guard went instead of predicting that it
never would.

**Score:** 2

#### What makes this deploy extra special

Both changed files are shared scripts, so every consumer receives this gate through the next plugin update
rather than by choosing to -- and the gate refuses at the last step of a branch, which is the worst place to
meet a surprise. Two decisions are there for that reader specifically.

It is `-Force`-able, unlike the link and impact gates and like the scaffold gate it most resembles: this
refuses text somebody actually wrote, and a consumer whose branch table names a prefix that could
legitimately open a sentence should get a warning rather than a branch it cannot ship. And the finding is
bounded to that consumer's *own* prefix, read from their table, so a repo whose types are `style/` or
`liquid/` is held to its own convention and not to this one.

**Score:** 2

#### Pull Request

the entry's title is refused when it already carries the branch's own type prefix

Plugins: contributing-davekjohn
