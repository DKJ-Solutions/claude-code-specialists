## Development: `fix/settings-proposal-pasteable-v1` · 20260830-103709

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

Repair inbound #1124: the settings proposal cannot be pasted in one move, because a whole-file paste
of `.claude/settings.suggested.jsonc` deletes the `enabledPlugins` and `extraKnownMarketplaces` the
destination already holds -- and nothing warns about it. That reproduces #1076's empty surface in the
one act reserved for the human.

#### What the verification found before any code moved

All six inbound checks stand -- symptom, reason, repair, size, subject, repo. One premise of the
report needed correcting, and it changed the design: the bootstrap does **not** read
`.claude/settings.json` to work out which plugins are enabled. It reads the whole settings chain
through `Get-EnabledPlugins` (user `~/.claude/settings.json`, then the repo's `settings.json`, then
`settings.local.json`), so "the file it already read" is not one file and may not be the destination
at all. The merged proposal is therefore built from the repo's own `.claude/settings.json` alone,
which is what makes "replace that file with this one" provably lossless whatever the chain holds.

#### The shape

- `.claude/settings.proposed.json` -- strict JSON, the repo's own `settings.json` key for key, plus
  the two `permissions` halves merged in. The `hooks` stub is omitted, because its path is a
  placeholder nothing creates and the page already offers dropping the key as a legitimate outcome.
- An unparseable `settings.json` writes **no** merged file: composing one from a file that could not
  be read is the same data loss by another route.
- The annotated `.jsonc` stays, and gains the warning it never had -- that the destination is not
  empty, and which keys must survive.


#### What the review caught, which the working version did not

Five findings on the finished branch, all verified against the tree and all repaired here. Two were
this feature's own failure mode arriving through its formatting step — a file written, announced as
*"ready to replace settings.json"*, and broken:

- **The un-escape was not backslash-aware.** `'\u([0-9a-fA-F]{4})'` matches the *second* backslash of
  an escaped pair, so a consumer whose hook command names `C:\uadded\check.ps1` had `\uadde` folded
  into one character and shipped an invalid escape. Measured: the merged file no longer parses. It now
  counts the run of backslashes — an even run means every one of them is itself escaped, so the `u`
  after it is literal text. Same reasoning that made the indenter a scanner rather than a regex, one
  line earlier.
- **`"allow": null` shipped as `[null, ...]`.** The key exists, so a `Contains` test says yes and
  `@($null)` is an array holding one `$null`. Null and absent are the same statement here, so both now
  take the empty path — and a rule list holding anything that is not a string is refused rather than
  merged, which is the same one-level-down blind spot as the unroll trap above it.
- **The merged file inherited what `settings.json` was hiding.** It is a copy of that file, so a repo
  that gitignores `.claude/settings.json` — usually for an `env` block with a token in it — got an
  untracked, *un-ignored* second copy dropped into the tree by an adoption step, because the ignore
  rule names the old path. The run now says so, in the one combination where the two files disagree.
- **The delete reminder was measured for one file and attached to two.** `git check-ignore` now runs
  per file, and the sentence claims a definite answer only where the two readings agree.
- A stray article in `plugins/ADOPTION.md`, left by the rewrite.

The first three carry regression tests. **A sixth finding was filed rather than fixed**:
[#1131](https://github.com/DaveKJohn/claude-code-specialists/issues/1131) — `publish-to-business.ps1`
carries the same un-escape expression, still not backslash-aware. It is outside this branch's subject,
and leaving the two copies disagreeing without a number is what would have been wrong.

### CREATE

- [x] `Get-SettingsArtifactNames` in `scripts/lib/check-report-lib.ps1`: one source for both artifact names, so the bootstrap that writes them and the teardown that removes them cannot drift
- [x] `bootstrap.ps1`: write `.claude/settings.proposed.json` (merge, strict JSON, hooks omitted), refuse to write it on an unparseable destination, and announce it by full path
- [x] `bootstrap.ps1`: the `.jsonc` header names the keys the destination already holds
- [x] `bootstrap.ps1`: next-step 3 becomes one paste rather than a hand-merge
- [x] `teardown.ps1`: remove the second artifact too
- [x] regenerate the plugin mirrors of `check-report-lib.ps1` (`build-shared-scripts.ps1`)

### TEST

- [x] `bootstrap-drift.tests.ps1`: the merged file is written, is strict JSON, preserves `enabledPlugins`/`extraKnownMarketplaces`, merges both permission halves, carries no `hooks` stub, and is skipped with a notice on an unparseable destination
- [x] `teardown.tests.ps1`: `-Apply` removes the merged proposal as well
- [x] docs follow the behaviour: `specialists-init/SKILL.md`, `specialists-teardown/SKILL.md`, `README.md`, `plugins/ADOPTION.md`, `UNINSTALL.md`
- [x] lint gate + all suites green -- `check-plugin-integrity.ps1` 0 errors, all 49 suites pass

### DEPLOY: `fix/settings-proposal-pasteable-v1`

`specialists-init` now writes a **second** settings artifact beside the annotated one:
`.claude/settings.proposed.json`, the merged end result. It is the consuming repo's own
`.claude/settings.json` key for key with both `permissions` halves folded in — strict JSON, no
comments to strip, and no hooks stub. Adopting the proposal becomes *replace one file with the other*
instead of a hand-merge the reader has to invent. `specialists-teardown` removes it alongside the
`.jsonc`, both names coming from one new `Get-SettingsArtifactNames` so the writer and the remover
cannot drift apart.

The annotated `.jsonc` stays, and gains the warning it never had: **it must not be pasted whole**,
because the destination is not empty. `.claude/settings.json` already holds `enabledPlugins` and
`extraKnownMarketplaces` — the two keys that got the adoption this far — and the proposal contains
neither, so overwriting the file with it deletes both. The result is a settings file that parses
perfectly and loads nothing at all: no skills, no subagents, no SessionStart hooks, and no message of
any kind. That is [#1076](https://github.com/DaveKJohn/claude-code-specialists/issues/1076)'s
zero-surface state (3 → 0 hooks, 6 → 0 skills, 15 → 0 subagents across one restart), reached without
ever touching an install record — and reached in the one act this family reserves for the human, since
a session may not widen a permissions file.

Two of that file's three copy traps were already papered over with warnings (the comments, #1097; the
hooks stub, #363) and the third was warned about nowhere. It is the third that costs the adoption, and
it is the one no amount of further warning text closes: the instruction was *"copy what fits"*, which
is a merge, and the fix is to do the merge.

**The merged file is not written when the destination cannot be read whole** — it does not parse, it
parses to something other than an object, its `permissions` key is not an object, or `permissions.allow`
/ `permissions.deny` is not a list of rules. The run says which shape it found, and the next-steps fall
back to the hand-merge *naming the two keys that must survive it*. Composing a merge from a file that
could not be fully read would drop part of it while wearing the label "safe to paste", which is the
reported defect arriving through its own fix.

Two smaller guarantees fall out of the same principle. The JSON is re-indented by a **scanner** and its
`\uXXXX` un-escape **counts the run of backslashes**, so a hook command naming a Windows path survives
byte for byte instead of shipping an invalid escape. And where `.claude/settings.json` is gitignored
while the merged copy beside it is not, the run says so: the copy holds every key that file held, and
the ignore rule that was hiding them names the old path.

The permission rules are now declared once as data and rendered into both files, so the proposal that
explains a rule and the file that carries it cannot disagree.

**Score:** 4

#### What makes this deploy extra special

A consumer adopting the specialists follows this step exactly once per repo, by hand, and until now it
could silently switch off everything they had just installed — with a valid settings file and no error
to read. From this release the same step is a single file replacement, and the file that must not be
pasted says so and names what it would destroy.

**Score:** 4

#### Pull Request

the settings proposal ships a pasteable merged file, and the proposal itself names the keys that must survive
