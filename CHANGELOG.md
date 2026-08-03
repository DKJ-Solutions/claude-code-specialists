# Changelog

The history of the claude-code-specialists marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #423 · Make a dead persona-body import loud instead of silent · Feat · 2026-08-03

`check-roster-sync.ps1` now resolves every `@`-import in the roster/seam file and reports an
**`[ERROR]`** for any that does not exist — so the one file in this system whose absence nothing
reported finally has a guard.

**Why this was the worst possible silence.** The roster is repo-local, so it always loads. The
orchestrator's *body* is the only part that comes from outside it, through a single `@`-import. If
that path is wrong the session still starts, the roster still renders, the persona table is still
intact — and the orchestrator runs with no ritual, no delegation discipline, and no
"nothing happens anonymously" rule. Claude Code reports nothing: an unresolvable import fails
silently. It has already happened once, on August 3, 2026, when the marketplace rename broke that
import in every consumer at the same moment; the only available signal was somebody noticing that the
orchestrator sounded generic, and the repair was by hand, per repo.

The check runs **before** the existing strip of `@`-lines from the roster text (#227) — the same line,
read for two different reasons, and previously silent when wrong in both.

Deliberately narrow about what counts as an import: the whole line must be an `@` followed by a path
ending in `.md`, and fenced blocks are skipped. The roster's own prose says a specialist can be
invoked as `@specialists:<name>`, and a fenced block may quote an example import; reporting either
would train the reader to ignore the check. It stays an `[ERROR]` even when the cause is "the plugin
is not installed on this machine" — that is not a false positive, it is precisely the state in which
this session's orchestrator has no body — so the finding names the plausible causes instead.

Two things followed from getting the message right:

- **`Format-SafePathToken`**, a path-shaped sibling of `Format-SafeToken` in the shared report lib.
  The id-shaped sanitizer strips `~`, `\` and `:`, which turns `C:\Users\...` into `CUsers...` and
  drops the `~` that says where a home-relative path starts. A finding whose whole job is to name the
  missing path must print one the reader can look up — `Format-SafeToken`'s own docstring says as
  much. It still strips control characters (the line-forging risk these hooks are sanitized against)
  **and square brackets**, because the hooks decide what to surface by matching markers like
  `[ERROR]`, so a bracket in a path would be *counted*, not merely look odd.
- **The `roster-sessioncheck` headline** now reads "a specialist is missing from the roster/lenses, or
  an @-import in the roster does not resolve". Until now that branch had one possible cause; this
  finding is its opposite — every specialist present and correct, while the body is not loading at
  all — and a reader taking the old headline at face value would search a roster that has nothing
  wrong with it.

Scope, as decided: only point 1 of the issue. The clone-versus-install-cache question (point 2) and
the hardcoded names (point 3) stay open, on the issue's own reasoning that the missing guard is worth
more than the path choice, because a guard turns any future recurrence — including one nobody has
thought of — from silent into loud.

---

**A separate repair that had to travel with it, because it blocked the gate.** Running the test suites
for the above surfaced two failures in suites this branch does not otherwise touch, and they turned
out to be one defect with two halves — both of them tests failing on their own formatting:

1. **The child wraps its own `Write-Error` output** at its own width, so its stderr arrives as two
   lines split *anywhere*, including on a space. Removing the newline then glues the words
   (`token` + `'final'` → `token'final'`) and a phrase assert fails — the mirror image of the mid-word
   case the existing normalization was written for. `new-branch.tests.ps1` had predicted exactly this
   in a comment ("if that case ever bites, the fix is to strip ALL whitespace from both the text and
   the pattern"), left it unmeasured, and it bit at console width 198. The prediction was right, and is
   now implemented and pinned in both directions.
2. **The parent then interleaves error-record decoration into the sentence.** Under `2>&1` each stderr
   line becomes its own `NativeCommandError`, and the second record's header, `CategoryInfo` and
   `FullyQualifiedErrorId` were rendered *between* the two halves: the captured text read
   `...the token 'fina` + ~300 characters of decoration + `l'.`. No whitespace normalization can
   survive that — the phrase is not reformatted, it has other content inserted into it. Both suites now
   capture the child's stderr as **plain text** through a redirect file, so nothing but what the child
   actually wrote is ever matched.

Worth stating, because a natural assumption is wrong here: `Invoke-NativeCapture` does not help. It
solves the *terminating* half of the stderr problem (`EAP=Stop` promoting a stderr line to a fatal
error) and leaves the *rendering* half untouched, because it still uses `2>&1`.

Plugins: specialists

[PR #423](https://github.com/DaveKJohn/claude-code-specialists/pull/423)

---

### #422 · Mirror ship-pr, verify-resolved-issues and fix-mojibake into the plugin · Feat · 2026-08-03

Three scripts that consumers could not reach are now mirrored into the plugin, closing the two
largest remaining gaps in the consumer flow. `cut-release.ps1` stays workshop-only, and now for a
reason that survives reading it: lockstep across a marketplace's plugins is meaningless in a
consumer.

**`ship-pr.ps1` (#411) — merge + fold was hand work in every consumer.** It was excluded as
workshop-local because "merge policy and the CI check name are repo-specific", and only half of that
held up. The check name never entered the logic at all — step 3 watches whatever checks the PR has
and reads the exit code, so the name only ever appeared in a progress message, which is now generic.
Merge policy *is* real (this workshop merges; the repo that filed the issue squashes), so it moved
into the seam as the optional `Get-PrMergeMethod`, validated against `merge`/`squash`/`rebase` before
it can reach `gh` at the moment the script is about to write to `main`. Note that the issue predicted
no new contract function would be needed — that is the one part of it that did not survive reading
both files, and building on it would have shipped one repo's merge policy to the other.

**And mirroring it surfaced a defect worth more than the mirror.** Step 5 folded the changelog and
then ran its own `git add -A` + commit + push. `git add -A` stages the *whole tree*, so anything else
modified or already staged rode along into a commit landing directly on `main` under one of the two
named exceptions to "never commit directly". `CLAUDE.md` has stated since August 2, 2026 that the
fold commit "names its paths, so nothing else in the tree can ride along" — true of
`fold-changelog-entry.ps1`, false of this orchestrator, which is the more commonly used of the two
routes. The fold, its commit and its push are now all delegated to that script (`-Push` implies
`-Commit`), so the promise holds on both paths and the exception stays the size it was granted at.

**`verify-resolved-issues.ps1` travels with it** — it *is* ship-pr's step 6, and a consumer whose
ship-pr called a file outside the mirror would fail at the last step of a sequence that has already
merged.

**`fix-mojibake.ps1` (#413) — three repos had each written their own copy.** The part that made it
unusable elsewhere was its default file set: it walked `plugins/**` and `releases/**`, neither of
which exists in a consumer, so the `Test-Path` filter quietly reduced the default to whatever root
docs happened to be there. A gate that examines almost nothing while reporting "clean" is worse than
no gate — the same argument that replaced its lookup table with the inverse round trip. The set is
now repo-owned (`Get-MojibakePaths`, optional), and the tool's own fallback is every `*.md` in the
repo root: the changelog, the root docs, **and any unfolded entry file** — a case the old hardcoded
list never covered, though an entry file is the freshest, most non-ASCII-carrying file in any repo
using this flow.

**One real bug found while moving that list.** PowerShell silently ignores `-Include` when the path
is given as `-LiteralPath`, so
`Get-ChildItem -LiteralPath $pluginRoot -Recurse -File -Include 'CHANGELOG.md','RELEASE.md'`
returned *every* file under `plugins/` while the comment above it named two file names. Nothing was
broken — the extra files were clean, and the tool leaves anything that is not mojibake alone — but
the code and its own description disagreed, and that description is what the lint gate quotes to the
reader as its coverage. Now `-Filter '*.md'`, and the gate's coverage line says what is actually
walked. The same quirk sits in `teardown.ps1:736`, where its `-Include` list is broad enough that
ignoring it yields a superset; filed separately rather than repaired in passing.

Contract: `Get-PrMergeMethod` and `Get-MojibakePaths` declared OPTIONAL, `Get-RepoName` now
attributed to `ship-pr` and `verify-resolved-issues` as well, and the "workshop-only" paragraph
rewritten to cover `cut-release.ps1` alone.

Tests: `fix-mojibake.tests.ps1` gains three scenarios that exercise the default set for the first
time (every other scenario names its file explicitly and so never reached that code) — the fallback,
a configured set that replaces rather than extends it, and a broken `repo-config.ps1` degrading to
the fallback with a warning; `repo-config.tests.ps1` pins both new knobs against the real repo tree;
`script-contract.tests.ps1` covers the two new records and the widened `Get-RepoName` attribution.

Plugins: specialists

[PR #422](https://github.com/DaveKJohn/claude-code-specialists/pull/422)

---

### #420 · Repo-configurable stub wording for a changelog entry · Feat · 2026-08-03

The shared `new-changelog-entry.ps1` wrote four hardcoded English strings into every entry file it
created: the title placeholder, the body heading, the fallback body, and the changelog type an
unknown branch prefix falls back to. They are now read from four **optional** functions in the
consumer's own `scripts/repo-config.ps1` — `Get-EntryTitlePlaceholder`, `Get-EntryBodyHeading`,
`Get-EntryBodyPlaceholder` and `Get-EntryFallbackType` — each `Get-Command`-guarded and falling back
to exactly the text it used to hardcode, so a consumer that defines none of them sees no change at
all. Same pattern as `Get-ChangelogHeading` (#178) and `Get-LiveStage` (#177).

**Why it matters more than four strings.** The file this script writes is repo-owned, so its
language is too. A Dutch-language consumer therefore kept a private copy of the whole script at the
*same relative path*, purely to change these four values — and then got two entry formats for one
branch, depending on which entry point ran: the repo's own flow called the local copy, the
`new-branch` skill called the shared one. That is precisely the duplication the skill exists to
prevent. Dropping the copy fixed the duplication and cost them English stubs in a Dutch changelog;
this gives the wording back without the copy.

Three details worth knowing:

- **`-Title` now defaults to an empty sentinel** in both `new-changelog-entry.ps1` and
  `new-branch.ps1`, not to the literal `TODO: title`. A param default is bound before `repo-config`
  can be read, so the default has to mean "the caller named no title" and be resolved afterwards.
  Keeping the literal would have put a copy of the placeholder in two scripts while the value it
  stands for lived in a third.
- **`repo-config.ps1` itself stays optional for this script**, unlike `open-pr`/`fold`, which
  pre-flight on it: `Test-Path` plus a `try`/`catch` that degrades to a warning. It is the lightest
  script in the set and every string it reads has a working fallback — a syntax error in someone's
  edit costs a warning, not a branch without an entry file. Measured, not assumed: the new fixture
  feeds it an unparseable `repo-config.ps1` and the entry is still written.
- All four are declared **OPTIONAL** in `check-script-contract.ps1`, so a consumer gets an `[INFO]`
  naming the default instead of discovering the wording one branch at a time. This is the clearest
  case yet for declaring an optional: nothing crashes without them, so that `[INFO]` is the only
  signal that will ever exist.

Tests: `new-branch.tests.ps1` gains a scenario proving a configured wording really reaches the entry
file (all four knobs at once, via an unknown prefix and no `-Title`/`-Intent`) and one proving a
broken `repo-config.ps1` degrades to a warning; `repo-config.tests.ps1` pins the four workshop values
against the shared defaults and asserts the fallback type is a type this repo's branch table actually
produces; `script-contract.tests.ps1` covers the four new records end to end.

Plugins: specialists

[PR #420](https://github.com/DaveKJohn/claude-code-specialists/pull/420)

---

### #419 · Repair the stale marketplace name in generated intros · Fix · 2026-08-03

Found while verifying the post-restart state after the rename series (#403–#406) closed: the rename
swept `davekjohns-workshop` out of 59 files, and all four **per-plugin `CHANGELOG.md` files still
opened by naming it** — in a sentence describing the present mechanism, in the most consumer-facing
file each plugin has.

**The reason, verified in the code rather than inferred from the symptom.** `Add-PluginChangelogSection`
emits the intro only when the file does not exist yet (`if (-not $Existing)`), so every later release
appends *below* it and never revisits it. Editing the template reaches future plugins and no current
one — the template had in fact already been corrected, and the correction could not arrive. Every
existing gate looked past it for a defensible reason: checks 11 and 12 exclude per-plugin CHANGELOGs as
history, and they are right about the entries. **The intro is the one part of those files that is not
history**, and no rule covered it.

**Repaired as a class, not as four strings:**

- **`Build-PluginChangelogIntro` extracted** as the single source of that header, with the marketplace
  name a **parameter** rather than a literal — a copy of the name is exactly what went stale. Its
  authority is `name` in `.claude-plugin/marketplace.json`, read through the new pure
  `Get-MarketplaceName`, which throws on a missing *or blank* name instead of yielding a plausible
  `()` in a published file.
- **Check 17 in the lint gate** holds every `plugins/<plugin>/CHANGELOG.md` intro against that
  function, deriving the expected text from the same manifest field `cut-release.ps1` writes — so the
  two agree by construction instead of by upkeep. There is deliberately **no expected value written
  down in the gate**: a literal there would be another copy of the string whose copies are the bug.
  Compared whitespace-normalized, so it judges content and never becomes a wrapping police over a file
  no human should be rewrapping. Everything below the first `## vX.Y.Z` heading is left alone — that
  half *is* history.
- **The six stale statements themselves**: the four plugin intros, `CHANGELOG.md`'s own opening line,
  and the handbook's outlier note in `.claude/specialists/README.md`, which additionally still called
  the plugins "the first product family" — the framing the
  [one-product rule](README.md#one-product-one-repository) retired the same day.

**Five test scenarios (33–37), and one of them is the design rather than a bug guard.** #37 renames the
marketplace in the fixture manifest and *nothing else*, and the same file must flip from failing to
passing: without that case the check could carry a hardcoded copy of the name and all four other
scenarios would still pass — precisely the shape of the defect it exists to catch. #36 locks in that a
CHANGELOG with no version heading is *reported* rather than silently skipped, since a check that quietly
asserts nothing is the failure mode this gate is here to prevent. #35's own first failure is recorded in
its comment: the fixture retyped the em-dash title as a plain hyphen, making a content difference
masquerade as the layout difference the case was meant to prove.

**The general rule, written into `release-lib.ps1` for the next template added there:** ask whether the
string is rewritten on every release. A section, a reference line, a fully regenerated card all reach
their file again and self-heal; anything written once needs a gate rather than a good intention. The
library's own header claimed "only FUTURE output from these templates changed" — true of every template
in it except this one, and that single exception cost four consumer-facing files.

**Also closed a smaller drift found on the way:** the gate's `.SYNOPSIS` indexed checks 1–12 while the
script ran 17. Checks 13–16 (entry-heading, encoding, unbound output samples, measured figures) were
documented at their definitions but absent from the index a reader consults first, so all five are now
listed rather than only the new one.

**Deliberately not done, and it is a decision rather than an omission.** "Workshop" survives as internal
shorthand for this repo in 278 places across 58 files — including the parameter name
`-WorkshopPathOverride` (a live contract between `connector-sessioncheck.ps1` and
`check-connectors.ps1`, mirrored into the plugin) and the test helper `New-StubWorkshop`. Retiring the
*word* is a vocabulary migration needing a chosen replacement term; retiring the stale *statements* is a
defect repair. Only the second is in this branch. Dave's call, August 3, 2026.

Plugins: specialists, specialists-ecomm, specialists-lifehub, specialists-shopify

[PR #419](https://github.com/DaveKJohn/claude-code-specialists/pull/419)

---

### #418 · Flatten the plugin directory layer into plugins/ and give the repo one landing page · Feat · 2026-08-03

Steps 3 and 4 of the repository rename (#405 + #406), in one movement because they rewrite the same
page. `claude-code-plugins/claude-specialists/` existed to hold several product *families* side by
side; with one product per repository both levels were empty scaffolding, so they collapse into one:

- **`plugins/<plugin>/`** for the four plugins and `agent-shared/` (plugin source — its generator
  writes the shared blocks into plugin agent defs), **`connectors/` at the repo root** (consumer
  register read by `scripts/sync/`, deliberately not payload that travels in the plugin cache). Moved
  with `git mv`, so history follows. Every path in the repo loses 31 characters — net 27 shorter than
  before the rename began, the longer marketplace name included.
- **The three family-level documents moved to the root**: `QUICKSTART.md`, `UNINSTALL.md`, and the
  735-line family `README.md`, which **becomes** the root README (the old 151-line one contributed
  only `Consumption`, `Versioning`, `Contributing` and the repo layout). One ~800-line landing page
  whose first screen now *routes* — a "Start here" table — rather than explains.
- **The one-product-per-repository rule is recorded** in `README.md`, `CLAUDE.md`,
  `.claude-plugin/marketplace.json` and `CONTRIBUTING.md`, with the nuance that stops the wrong repair
  later: lockstep *within* this product is correct, `cut-release.ps1` needs no change, and the
  versioning problem dissolved with the reorganisation instead of needing a fix.

**Three defects a mechanical path sweep would have shipped, each caught by reading rather than by
replacing.** They are the reason this entry is longer than a move deserves:

1. **`bootstrap.ps1` derived the plugin from a named path segment**, and the new name is not unique.
   It looked up the index of `claude-code-plugins` and took two segments further to skip the family
   level; renamed to `plugins`, that segment occurs a **second** time in every real install path
   (`~/.claude/plugins/marketplaces/<mp>/plugins/<plugin>/personas`), `IndexOf` returns the first, and
   the derivation would have yielded the **marketplace** name — precisely the defect #179 fixed, back
   again through a rename. The segment lookup was already redundant: the parent walk beside it derives
   the plugin correctly in the source, clone and cache layouts alike, so it is gone rather than
   renamed.
2. **The lint gate's parse check matched `plugins` as a path segment**, which now also matches
   `.claude/plugins/` — it is anchored on the plugins root instead.
3. **`Get-TouchedPlugins` excluded the wrong sibling.** `connectors` left the plugins tree (so its
   exclusion guarded nothing) while `agent-shared` moved in (and would have been reported as a touched
   plugin on release). The exclusion follows the directory now, asserted from both sides.

**The lint gate got the root-level `*.md` glob** that #405 asked for, replacing a named list of four
root documents *plus* a glob over the family directory. That directory's glob existed because a
hardcoded list of two had gone stale the moment `UNINSTALL.md` was written beside them and no gate saw
it; moving those documents into the root would have left the named list as the only rule over exactly
the directory where that class of defect lives. It also picks up `SECURITY.md`, which no rule had ever
covered.

**Two measurements in #405 turned out low, and the repo won.** The archived release notes carry **19**
relative links into the old paths, not 8 — all repaired as link *targets* only, since a target is
machinery that has to resolve while the backtick prose around it states where a file stood at the time
and stays untouched (42 such mentions remain, deliberately). And `QUICKSTART.md` and `UNINSTALL.md`
carried relative links of their own that changed meaning **without changing text** — `../../` used to
reach the root from the family directory, and a bare `specialists/…` used to be a sibling. A path sweep
cannot see those; the dead-link gate is what found them.

Not touched, deliberately: `CHANGELOG.md` and every per-plugin `CHANGELOG.md`, the prose in
`releases/**`, and `cut-release.ps1`. Closes #405, #406 and tracking issue #407.

Plugins: specialists, specialists-ecomm, specialists-lifehub, specialists-shopify

[PR #418](https://github.com/DaveKJohn/claude-code-specialists/pull/418)

---

### #416 · A folder rename silently unlinks plugin installs · Docs · 2026-08-03

Records the lesson measured on August 3, 2026, when this repo's directory was renamed from
`davekjohns-workshop` to `claude-code-specialists`: the install record is keyed on `projectPath`, so the
rename left it naming the old folder. `.claude/settings.json` still enabled
`specialists@claude-code-specialists` correctly, nothing errored, and the session loaded no subagent,
skill or hook at all.

The cause was not new to the system — `scripts/lib/check-report-lib.ps1` has always named "a renamed or
moved repo directory" among the ways a record goes missing. It was new to the *reader*: the list a
consumer actually reads, in `QUICKSTART.md`, offered only "It moves" and "It can be taken". So the gap
closed here is a documentation gap, not a mechanism one.

It is also a gap in the rename plan, which is why it went unnoticed. Renaming the **local checkout
directory** is in none of #403–#406, and #409's four-item handoff covers the marketplace remove/re-add,
the stale user-scope entry and the restart — not a moved checkout. Matching the local folder to a
renamed repository is the obvious next move for anyone, and nothing warned that it needs a re-install.
The handoff's own instruction to *verify by the surface, not by the record* is what surfaced it.

Out of scope here, deliberately: the consumer switch-over (`smartwatchbanden` still resolves against
`davekjohns-workshop`). #409 reserves the consumer repositories for Dave by name, so that stays his
step and no file in them is touched from here.

- **`QUICKSTART.md`** — third bullet in the missing-record list ("It can be orphaned, by an ordinary
  directory rename"), the one cause that is predictable rather than surprising, with the August 3
  measurement.
- **`QUICKSTART.md`** — sharpens the neighbouring `#315` warning that "two lines for one plugin" is a
  stray duplicate. After repairing a rename, two records is the *expected* state and needs no cleaning:
  `Get-InstallRecord` skips a record whose `projectPath` no longer resolves, so it reports neither a
  duplicate nor `[RECORD-SHAPE]`. `#315`'s duplicate is two records naming the **same** path.
- **`.claude/specialists/lenses/05-15-extension.md`** — Sylvester carries the repo-side instance: the
  detection signal is a **deliberate** `check-roster-sync.ps1` run reporting `[NOT-INSTALLED-HERE]`,
  because the session-start hook that would otherwise report it ships in the plugin that did not load.
  Plus the repair pair of commands, pointing at `QUICKSTART.md` for the mechanism rather than restating
  it.
- **`CLAUDE.md`** — one pointer clause in "The repo consumes itself", which already enumerates the
  consequences of self-consumption; this is the second one.

[PR #416](https://github.com/DaveKJohn/claude-code-specialists/pull/416)

---

### #415 · Wrap-proof the captured-output asserts in the branch test suites · Fix · 2026-08-03

`new-branch.tests.ps1` failed one assert on this machine while the script under test behaved exactly as
specified, and CI was green on the same commit. The assert is
`-Name main: pointer names the main rule`, matching on `must not be 'main'`.

The cause is formatting, not behaviour. A native child's stderr captured with `2>&1` does not arrive as
plain text: PowerShell wraps each line in a `NativeCommandError`, renders it with a `powershell.exe : `
prefix, and wraps the whole record at the **host width**. So the wrap point moves with the width of the
window the suite happens to run in and with the length of the fixture's temp path — the user name and
`$PID` are both in it — and none of that is a property of `new-branch.ps1`. Measured at width 176, the
break landed **mid-word**: `... Branch name mus` + `t not be 'main'.`

Mid-word is the detail that decides the repair. Collapsing whitespace to a single space, the way
`shared-scripts.tests.ps1` does inline at line ~656, yields `name mus t not be` and still does not match.
Removing the newlines, the way that same file's `Test-OutputContains` does at line ~128, restores the
phrase. That file already held both the right answer and the weaker one, and neither had reached the two
branch suites.

- **`scripts/tests/new-branch.tests.ps1`** — a `Get-FlatOutput` helper used by all three child-capture
  points, plus a synthetic regression assert. Synthetic on purpose: the real wrap only appears at
  particular console widths, so a test that waited for it would pass here and prove nothing elsewhere.
- **`scripts/tests/park-branch.tests.ps1`** — the same helper. Its three phrase asserts (`on main`,
  `parked on origin`, `nothing new to commit`) sit in the same kind of record and were one window width
  away from the same failure.
- **Deliberately not covered, and stated rather than tested into passing:** a wrap landing exactly *on* a
  space. If the formatter drops that space, newline-removal glues the words together. Whether it drops it
  has not been measured — the observed break was mid-word — and the note in the code says what to do if it
  ever bites.

Not caused by the rename. The first reading blamed the longer repo path from `davekjohns-workshop` to
`claude-code-specialists`; that was wrong, because the fixture lives under the temp directory and carries
no repo name at all. The failure reproduces on `main` and is decided by the console width.

[PR #415](https://github.com/DaveKJohn/claude-code-specialists/pull/415)

---

### #412 · rename the marketplace to claude-code-specialists · Chore · 2026-08-03

Step 2 of the four-step rename ([#404](https://github.com/DaveKJohn/claude-code-specialists/issues/404),
tracked from [#407](https://github.com/DaveKJohn/claude-code-specialists/issues/407)). The repository was
renamed on GitHub in step 1 ([#403](https://github.com/DaveKJohn/claude-code-specialists/issues/403));
this change makes the repository's own contents agree with its new name. Marketplace name and repository
name are now identical on purpose — when they differ, you have to remember forever which marketplace
lives in which repository, and that is exactly what bites while debugging a plugin that will not load.

**Why the rename at all.** The workshop was meant to become the home for every future plugin. With one
`CHANGELOG.md`, one `vX.Y.Z` tag and a lockstep version bump, that design breaks the moment a second,
unrelated product lands: it gets bumped for work it never had, one tag covers two products, and one
changelog mixes two histories. Measurement showed there was nothing here that is *not* the specialists
product — `scripts/` is its machinery, `releases/` its notes, `CHANGELOG.md` its history, and
`claude-code-plugins/` holds only `claude-specialists/`. So this was never a split; it was a rename, and
a `git push --mirror` would have been the expensive route — it loses the issues, the pull requests, the
releases metadata, the `main` ruleset and the CI history that a rename keeps.

**What changed.** `davekjohns-workshop` → `claude-code-specialists` in 59 files, 370 replacements: the
`name` in `.claude-plugin/marketplace.json`, every `specialists*@davekjohns-workshop` plugin ID, the
repository slug, the six live hard-coded `~/.claude/plugins/marketplaces/…` import paths (including
Chris's body import, which every session loads), the self-consumption entry in `.claude/settings.json`,
and the connector registry — where `connectors/davekjohns-workshop.json` was renamed with `git mv` so
its history follows it.

**What deliberately did not change.**

- `releases/**` and every `CHANGELOG.md`, root and per-plugin. These are the historical record: a note
  that says where a file stood in version 1.7.0 is true about that moment, and rewriting it would make
  it false. The one archived cache path in `releases/development/1.x/1.7.0.md` therefore still reads
  `davekjohns-workshop`, which is correct — the language-layer rule in
  [`.claude/rules/language-layers.md`](.claude/rules/language-layers.md) already names archived release
  notes as a deliberate exception.
- `scripts/release/cut-release.ps1`. The lockstep bump across all four plugins under a single tag is
  what triggered this reorganisation, but with one repository holding one product the lockstep is
  **correct** — the four plugins are one system, and a consumer running group 1 plus group 3 needs
  matching versions. The versioning problem dissolves with the rename instead of needing a fix. Recorded
  here because the obvious next move is to "repair" a script that is not broken.

**Verified.** The ruleset survived the repository rename — `main-ci-gate` is still `active` with
`lint-en-tests` required, so the CI gate and the no-`--admin` merge work unchanged. Lint gate: 0 errors
across 26 agent defs, 26 manuals, 4 personas, 148 link-scanned files and 19 checks. Test gate: 23 of 23
suites pass.

**What this does not do, and cannot.** The machine-side re-adoption — removing the old marketplace,
adding `DaveKJohn/claude-code-specialists`, dropping the stale user-scope registration, and confirming a
fresh session loads Chris from the new path — needs a session restart, and an agent runs inside the
session it would have to restart. That is the same structural limit inbound
[#402](https://github.com/DaveKJohn/claude-code-specialists/issues/402) reports about the Quickstart
itself, met here rather than read about. Those four acts are the handoff, written out in the run-book
[#409](https://github.com/DaveKJohn/claude-code-specialists/issues/409).

Two consequences worth stating rather than discovering. Until that handoff runs, a session in this repo
loads no specialists at all: `.claude/settings.json` now asks for
`specialists@claude-code-specialists` while the machine still knows only the old marketplace and the old
install record. And the flattening of `claude-code-plugins/claude-specialists/` is still ahead
([#405](https://github.com/DaveKJohn/claude-code-specialists/issues/405)), so the import paths this
change corrected will move once more — which is why the three family-level documents move to the root in
that step rather than this one.

Closes #404.

Plugins: specialists, specialists-ecomm, specialists-lifehub, specialists-shopify

[PR #412](https://github.com/DaveKJohn/claude-code-specialists/pull/412)

---

### #400 · a reported finding's reason is verified before it is repaired · Docs · 2026-08-02

The working rule that round v13 produced, recorded rather than left in a closing message. A report
carries two things — *what* went wrong and *why* — and the second is an inference by someone
measuring from the outside. The rule is to check the code, doc or output that would have to be true
for that explanation to hold, before writing the repair.

The measured instance is inbound
[#388](https://github.com/DaveKJohn/davekjohns-workshop/issues/388). It reported that the teardown
does not count a fixture's `README.md` *"even as prose"*, and proposed deleting the sentence that
promised the count. The symptom was real: nothing about that file shows up in the output. The reason
was not. `teardown.ps1`'s prose pass scans the **root markdown** — every `*.md` at the repo root,
excluding only `CLAUDE.md` and `CHANGELOG.md` — so the file is squarely in it. It scores **0**
because the fixture README deliberately names no specialist, and the note prints only above zero. The
sentence was not untrue; it was unfindable.

Had the proposal been built as written, the change would have deleted a correct sentence, left the
next measurer with exactly the same confusion minus its explanation, and carried an issue number
vouching for it. That is what makes this worse than the untouched defect: **a wrong repair is a
defect with a citation.** The repair that did ship explains where to look instead
(`DaveKJohn/specialists-adoptietest#2`).

It sits under *General working practices* rather than in a specialist's manual, because it belongs to
whoever is holding the report — which over one evening was the systems administrator, the technical
writer and the test engineer in turn — and because that section loads unconditionally. Nobody has to
go looking for it, which is the property this lesson needs: it applies at the moment you are most
convinced you already know what to build.

[PR #400](https://github.com/DaveKJohn/davekjohns-workshop/pull/400)

---

### #399 · the release card states what it describes, not where you are · Fix · 2026-08-02

Every plugin's `RELEASE.md` card carried the line *"You are on this release."* — written at cut time,
about a reader the card has never met. Round v13 measured it false in the ordinary case (inbound
[#384](https://github.com/DaveKJohn/davekjohns-workshop/issues/384)): the payload came from `main`,
three commits past the tag whose number both the card and `plugin.json` were carrying.

What makes it more than cosmetic is *where* the reader meets it. The QUICKSTART already documents
that **the documented update path cannot deliver a tagged release**, because the source it reads is a
branch — and v13 was the first round in which a consumer ran that tag comparison and reached the right
conclusion: *I am on `main`, not on the release*. Two minutes later the card of that same release told
them the opposite. Two documents of one family contradicting each other about one measurement, with
the wrong one being the one that cannot know.

`Build-PluginReleaseCard` now writes what the card *can* know — the version its manifest carries — and
hands the "where am I" question to the check that can answer it, linked as an absolute URL because the
card is read from a plugin cache where the QUICKSTART does not ship. The fix is in the generator, so
it holds for every future release instead of being retyped; the four cards on disk were regenerated to
match, and `cut-release.ps1`'s own description, [Rendall #06's lens](.claude/specialists/lenses/05-06-extension.md)
and the QUICKSTART line pointing at the card all follow the behaviour.

The test that pinned the old sentence now pins the new one **plus its negative**: the card must not
claim the reader is on this release. A line this one is only a repair for as long as nothing puts it
back.

Plugins: specialists, specialists-ecomm, specialists-lifehub, specialists-shopify

[PR #399](https://github.com/DaveKJohn/davekjohns-workshop/pull/399)

---

### #398 · two promises the consumer path cannot keep are made conditional · Docs · 2026-08-02

Both v13 findings are the same shape: a sentence that is true of the writer's situation and not of
the reader's.

**The `#336` hash pair is reproducible, and the warning said it was not** (inbound
[#385](https://github.com/DaveKJohn/davekjohns-workshop/issues/385)). `QUICKSTART.md` printed a
before/after SHA256 pair for `install --scope project` and then told the reader the values *"are not
something to match"*. Round v13 hit both of them exactly on a second profile — 224 bytes before, 246
after, and the +22 accounted for to the byte by the two documented changes.

That is not a coincidence, it is the prescribed path: Step 1 has the reader paste the printed block
into a file that does not exist yet, so the "before" bytes *are* the block, and the CLI's serialiser
is deterministic from there. Matching the pair therefore tells a reader two useful things — the block
went in intact, and the install did what it should. The warning was taking that away. It is now
conditional: match them if you followed this path, and if you had a `settings.json` already or
formatted it yourself, only the *difference* between your two values means anything.

**The `[UNREGISTERED]` safety net does not reach the reader it was written for** (inbound
[#383](https://github.com/DaveKJohn/davekjohns-workshop/issues/383)). `specialists-init`'s closing
step promised that until the repo is registered in the workshop, its own session start says so. The
line exists — but it comes from `check-connectors.ps1`, which `connector-sessioncheck` only runs when
it finds a **verified workshop checkout on this machine**, and a plain consumer has none. The
unregistered v13 repo got `no verified workshop checkout found on this machine -- check skipped.` in
every session of the round, and nothing else.

Defensible behaviour — there is nothing to check against — but it means the net catches the reader
who needs it least. The step now says so, with the line a consumer will actually see, and names why
this is the step most easily left lying: it asks for a PR in another repo, afterwards, once the
adoption already works.

Plugins: specialists

[PR #398](https://github.com/DaveKJohn/davekjohns-workshop/pull/398)

---

### #397 · the honest leftovers list gains a row and loses a stale citation · Docs · 2026-08-02

Two v13 findings in one section, because they are the same section.

**A sixth leftover** (inbound
[#386](https://github.com/DaveKJohn/davekjohns-workshop/issues/386)). For the first-time consumer
this family documents, `.claude/settings.json` does not exist before adoption — Quickstart Step 1 has
the reader create it. After a by-the-book teardown it is still there, holding `{}` at 3 bytes. Step 3
removes the keys and says so; the file itself was named nowhere, while the list it belongs to already
covers the `CLAUDE.md` scaffold prose, which is the same category: *a file that would not exist
without the adoption*. Small and harmless — but the section is called "honestly" and is explicitly
the complete list, so one row keeps that promise. The counts in its opening line move with it.

**The `CLAUDE.md` row's evidence is now the series, not its best round** (inbound
[#392](https://github.com/DaveKJohn/davekjohns-workshop/issues/392)). It cited round v11, where two
of two fresh sessions flagged the contradiction unprompted. v12 and v13 both measured **1 of 2**, so
the citation had quietly become the optimistic end of the range rather than the reading.

What the later rounds add is *when* it surfaces: across the four sessions of v12 and v13, the ones
that spoke up had been asked to **orient**, and the ones that did not had been given a **task** — one
of the silent ones flagged `CLAUDE.md` as an untracked leftover *"that does not belong in the
fixture"* while walking past the contradiction inside it. Four observations is a pattern and not a
law, and it is written down as one.

The advice does not change, and the row stays a **to-do**: a leftover that only sometimes announces
itself is precisely the one to close by hand, so 1-in-2 is the argument for that treatment rather
than against it. Only the evidence under it moved.

[PR #397](https://github.com/DaveKJohn/davekjohns-workshop/pull/397)

---

### #396 · a round's step-table totals are counted, not typed · Feat · 2026-08-02

`#371` fixed a hand-typed figure in a round's baseline table by measuring it. The table beside it —
the step table, whose totals line is what a whole round is hung on — was still counted by hand, and
was wrong in exactly the same way (inbound
[#387](https://github.com/DaveKJohn/davekjohns-workshop/issues/387)): the v12 line read *3 wrijving,
38 groen, 2 niet gemeten* over 43 rows while its own column held **4, 39 and 3 over 46**. One short
in every category — three rows added without the totals line following — and v13's assignment then
inherited it, naming three friction rows where the column had four.

`scripts/tests/round-tally.measure.ps1` counts the column instead, and prints the tally with the same
*generated, do not retype* marker the baseline block carries. Verified against the real v13 papers:
it reproduces v13's own line exactly (0 / 1 / 43 / 2 over 46) and independently confirms the v12
figures the finding reported.

**It has no vocabulary of its own.** No hardcoded status names, no hardcoded language, no hardcoded
markers: a cell that opens with a non-ASCII text element carries that marker, and the words after it
are that marker's label, taken from the table. So the tally cannot drift from the papers by holding a
stale idea of what "green" looks like, and a round scored in any symbols, in any language, counts the
same way. The totals come out as a table — one row per round — which is what makes comparing rounds
an output rather than a memory exercise.

Two properties are load-bearing rather than incidental, and both are pinned by tests:

- **Emphasis does not hide a cell.** The papers bold exactly the rows a round turned around, so
  reading `*` as the opening character would drop the four rows v13 was *about* while looking right
  everywhere else.
- **A markerless cell is reported, never dropped.** Older columns hold bare prose (`niet gemeten`,
  `niet opgetreden`). Counting them in no category is correct; staying quiet about them would produce
  a total that looks complete and is not — the same no-silent-caps rule the teardown's audit follows.

`-OutFile` writes UTF-8 without BOM, because a Windows PowerShell 5.1 redirect re-encodes stdout in
the console codepage and would put mojibake into the very block a reader pastes from.

[PR #396](https://github.com/DaveKJohn/davekjohns-workshop/pull/396)

---

### #395 · the untouched-install note is gated on the install record · Fix · 2026-08-02

`teardown.ps1` closed every run with *"The plugin install itself is untouched: run
`claude plugin uninstall …`"* — unconditionally, while the note directly above it was already gated
on the content of `settings.json`. Round v13 reached it by the route `UNINSTALL.md` Step 4 has
offered since `v3.1.2` (re-run the audit from the cache, which survives Step 2) and read that the
install was untouched **one step after** `Successfully uninstalled`, with the advice to run the
command again (inbound [#381](https://github.com/DaveKJohn/davekjohns-workshop/issues/381)). New
behaviour reached by the #373 repair, and unmeasured until someone walked it.

The condition was lying around: it is the same `projectPath` query `UNINSTALL.md` prints twice, in
Step 2 and again in Step 4. `Get-InstallRecordState` now asks it, and the note has three readings,
because *"no record"* and *"could not look"* are different claims:

- **a record points here** — the note names the plugin **and the scope the record is actually in**,
  rather than assuming `project`. A session start can write a `local` record by itself, and an
  uninstall aimed at the wrong scope is the failure the document spends a paragraph on;
- **readable, nothing points here** — it says so, and stops advising a command the reader has
  already run. This is what the Step 4 re-run now reads like;
- **missing or unparseable records file** — reported as a gap in the reading, never as a clean
  machine, and the teardown still exits 0.

`UNINSTALL.md` Step 4 says what to expect from that re-run, so the confirmation is documented rather
than discovered. Ten assertions cover the three states plus the unparseable route into the third.

Plugins: specialists

[PR #395](https://github.com/DaveKJohn/davekjohns-workshop/pull/395)

---

### #394 · the #327 disarm claim is conditional on which key stays behind · Fix · 2026-08-02

`UNINSTALL.md` Step 3 closed with *"Walk it through to the end of Step 5 and the mechanism is
disarmed, stray key or not."* Round v13 measured the opposite (inbound
[#382](https://github.com/DaveKJohn/davekjohns-workshop/issues/382)): after a by-the-book teardown
through Step 5 — record `{}`, `known_marketplaces.json` `{}`, clone and cache gone — with **both**
keys deliberately left behind, two session starts and no commands at all put the machine back on an
install record. Session 1 re-registered the marketplace and rebuilt the clone; session 2 wrote a
full `project` record.

The disarming does not hang on reaching Step 5 but on **Step 3 removing both keys**, and the two are
not equal: with only `enabledPlugins` left the machine does stay free (measured separately), so
`extraKnownMarketplaces` is the one that matters — it is the key that can put the marketplace back,
and everything else follows from that. The closing sentence now says so, and the key's bullet in
Step 3 is marked accordingly.

The three-state table gained a fourth row and lost one condition that was too strong. Its rows 1 and
2 read as a sequence rather than as alternatives — the state row 1 leaves behind *is* what row 2
fires on, which is what makes the whole thing possible unattended. And the record in row 2 does
**not** require the unpacked cache: v13's record pointed its `installPath` into a
`cache/davekjohns-workshop/…` directory that did not exist.

Folded in from the same round: a record written by a session start is recognisable by its **key
order** (inbound [#389](https://github.com/DaveKJohn/davekjohns-workshop/issues/389)) — a real
install puts `projectPath` second, a session start puts it last. A second signal next to
`installedAt` and independent of it, readable without the hand-edit that would wipe the evidence.
Written in as confirmation rather than proof, with its CLI-version caveat attached.

[PR #394](https://github.com/DaveKJohn/davekjohns-workshop/pull/394)

---

### #380 · A round's baseline table is measured, not typed · Feat · 2026-08-02

Test round v12's [#371](https://github.com/DaveKJohn/davekjohns-workshop/issues/371), and the last
open finding of that round. Its baseline table said the fixture README had **23** lines where the file
has **22** — in the papers of the round that was verifying #360, the repair about a figure naming its
convention. Both numbers are defensible: 22 is the count of line terminators, 23 is the number of line
positions an editor gutter shows. What the table lacked was the column that says which one is meant,
and its `hoe gemeten` cell — the documented remedy for exactly this — read `alle regels`, which names
nothing.

**Why this is a script and not a fourth doc fix.** The round's own closing note asked for it: the
papers live in `DaveKJohn/specialists-adoptietest`, outside the reach of check 15 and check 16, so
there the habit had to do the work — and it did not. `scripts/tests/round-baseline.measure.ps1`
computes every figure from a checkout and prints the markdown block, so the number cannot be a typo
and the convention cannot go unnamed. **It prints both line conventions as separate rows**, each with
its rule, which is the actual fix: a consumer who measures the other one is no longer left deciding
whether they mis-cloned.

**It reproduces v12's table exactly** — 1105 bytes blob, 1127 on disk, 22 terminators, 23 positions,
15 per `Measure-Object -Line`, 3 commits, `f56a9e6` — which is independent confirmation that the
reporter of #371 was right about the one row and that the other five were sound. The size delta is no
longer a claim in prose either: the row states that the 22-byte difference is exactly the 22 CRLF
conversions, which is the reasoning the reporter used to prove the line count.

**A hole it found in itself, on its first run.** The blob rows come from the ref and the disk rows from
the working tree. The smoke test measured `main` in a checkout standing on another branch, and the
table was right only because that branch happened not to touch the file. Right by luck is the class
this whole issue is about, so the script now refuses — hard error, no table — when the file on disk
differs from the ref, and the guard compares *normalized* content on purpose: a byte comparison would
reject every Windows checkout, which is the only kind this family runs. Both directions are asserted.

**Pinned by 47 asserts in `scripts/tests/round-baseline.tests.ps1`**, which drives the real script over
the `powershell -File` hop rather than dot-running it. Three of them are the reason the suite exists:
a file *without* a closing terminator must report the same number twice (a naive `terminators + 1`
passes the 22/23 case and lies here), no row may carry an empty or one-word `how measured` cell — the
defect itself, failing in CI instead of in someone's papers — and a CRLF working tree must not trip the
mismatch guard. The CRLF fixtures drive `core.autocrlf` per repo, so the suite gives the same verdict
on a CRLF and an LF checkout.

**Two things learned while building it, both now comments in the code.** `-Path` is a comma-separated
`[string]` rather than a `[string[]]`, because `powershell -File` cannot bind an array parameter and
`-Path a,b` would arrive as the single filename `a,b` — the same trap `pr-issues-lib`'s `-Resolves`
was reshaped for. And the first shallow-clone fixture was refused by the script: setting
`core.autocrlf` *after* a checkout leaves the working tree inconsistent with the config, so git reads
the file as modified. The fixture was wrong, not the guard.

The suffix follows `fresh-consumer.measure.ps1`: a `.measure.ps1` asserts nothing and stays out of
CI's `*.tests.ps1` glob, because on a fresh clone whatever it finds *is* the baseline. Its correctness
is what CI checks.

[PR #380](https://github.com/DaveKJohn/davekjohns-workshop/pull/380)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v3.1.2] - 2026-08-02 — Patch

See [releases/development/3.x/3.1.2.md](releases/development/3.x/3.1.2.md) for the full release notes.

---

### [v3.1.1] - 2026-08-02 — Patch

See [releases/development/3.x/3.1.1.md](releases/development/3.x/3.1.1.md) for the full release notes.

---

### [v3.1.0] - 2026-08-01 — Minor

See [releases/development/3.x/3.1.0.md](releases/development/3.x/3.1.0.md) for the full release notes.

---

### [v3.0.9] - 2026-08-01 — Patch

See [releases/development/3.x/3.0.9.md](releases/development/3.x/3.0.9.md) for the full release notes.

---

### [v3.0.8] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.8.md](releases/development/3.x/3.0.8.md) for the full release notes.

---

### [v3.0.7] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.7.md](releases/development/3.x/3.0.7.md) for the full release notes.

---

### [v3.0.6] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.6.md](releases/development/3.x/3.0.6.md) for the full release notes.

---

### [v3.0.5] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.5.md](releases/development/3.x/3.0.5.md) for the full release notes.

---

### [v3.0.4] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.4.md](releases/development/3.x/3.0.4.md) for the full release notes.

---

### [v3.0.3] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.3.md](releases/development/3.x/3.0.3.md) for the full release notes.

---

### [v3.0.2] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.2.md](releases/development/3.x/3.0.2.md) for the full release notes.

---

### [v3.0.1] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.1.md](releases/development/3.x/3.0.1.md) for the full release notes.

---

### [v3.0.0] - 2026-07-30 — Major

See [releases/development/3.x/3.0.0.md](releases/development/3.x/3.0.0.md) for the full release notes.

---

### [v2.16.0] - 2026-07-30 — Minor

See [releases/development/2.x/2.16.0.md](releases/development/2.x/2.16.0.md) for the full release notes.

---

### [v2.15.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.15.1.md](releases/development/2.x/2.15.1.md) for the full release notes.

---

### [v2.15.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.15.0.md](releases/development/2.x/2.15.0.md) for the full release notes.

---

### [v2.14.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.14.1.md](releases/development/2.x/2.14.1.md) for the full release notes.

---

### [v2.14.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.14.0.md](releases/development/2.x/2.14.0.md) for the full release notes.

---

### [v2.13.3] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.3.md](releases/development/2.x/2.13.3.md) for the full release notes.

---

### [v2.13.2] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.2.md](releases/development/2.x/2.13.2.md) for the full release notes.

---

### [v2.13.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.1.md](releases/development/2.x/2.13.1.md) for the full release notes.

---

### [v2.13.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.13.0.md](releases/development/2.x/2.13.0.md) for the full release notes.

---

### [v2.12.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.12.0.md](releases/development/2.x/2.12.0.md) for the full release notes.

---

### [v2.11.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.11.0.md](releases/development/2.x/2.11.0.md) for the full release notes.

---

### [v2.10.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.10.0.md](releases/development/2.x/2.10.0.md) for the full release notes.

---

### [v2.9.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.9.0.md](releases/development/2.x/2.9.0.md) for the full release notes.

---

### [v2.8.0] - 2026-07-27 — Minor

See [releases/development/2.x/2.8.0.md](releases/development/2.x/2.8.0.md) for the full release notes.

---

### [v2.7.3] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.3.md](releases/development/2.x/2.7.3.md) for the full release notes.

---

### [v2.7.2] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.2.md](releases/development/2.x/2.7.2.md) for the full release notes.

---

### [v2.7.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.1.md](releases/development/2.x/2.7.1.md) for the full release notes.

---

### [v2.7.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.7.0.md](releases/development/2.x/2.7.0.md) for the full release notes.

---

### [v2.6.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.6.1.md](releases/development/2.x/2.6.1.md) for the full release notes.

---

### [v2.6.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.6.0.md](releases/development/2.x/2.6.0.md) for the full release notes.

---

### [v2.5.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.5.0.md](releases/development/2.x/2.5.0.md) for the full release notes.

---

### [v2.4.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.4.1.md](releases/development/2.x/2.4.1.md) for the full release notes.

---

### [v2.4.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.4.0.md](releases/development/2.x/2.4.0.md) for the full release notes.

---

### [v2.3.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.3.0.md](releases/development/2.x/2.3.0.md) for the full release notes.

---

### [v2.2.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.2.1.md](releases/development/2.x/2.2.1.md) for the full release notes.

---

### [v2.2.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.2.0.md](releases/development/2.x/2.2.0.md) for the full release notes.

---

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
