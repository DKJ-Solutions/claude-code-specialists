# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections. The `##` heading is the change's own — `` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `### What makes this deploy extra special` for the second audience, and `### Pull Request`.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](contributing-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier, each closing with its score. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## DEPLOY: `feat/rename-workflow-to-contributing-davekjohn-v1` · 20260826-111226

`workflow-davekjohn` is now `contributing-davekjohn` -- the plugin, its directory, and its root folder in the
repo -- and `workflow-default` is gone along with the "exactly one workflow" guard that only existed because
there were two. The plugin's name now says what it does: it serves one owner's contributing rules, not a
workflow among several. Its folder carries **one** page instead of two, arranged as the four steps work
actually moves through, and the folder's `CLAUDE.md` is merged into it.

**Nothing is renamed without the old name still being read.** That is this repo's own precedent rather than a
new idea: `Get-BranchFilePaths` already kept four legacy filenames readable, on the argument that a consumer
meets a rename through a plugin update rather than by choosing to, and that a half-finished branch must not be
stranded. So seven document names resolve where one is written, both folder names satisfy the isolation guard
and the script-contract check, the bootstrap recognises either plugin id, and the seam defaults prefer whichever
folder actually exists. Two of those would have failed **loudly** in an unmigrated consumer if they had been
swept: the isolation guard refuses with `exit 1`, and the contract check is forwarded by a SessionStart hook as
`[ERROR]`.

**Two rules Dave stated mid-branch are now written down and shipped**, after he caught both by eye in this
branch's own document: `development-cycle.md` has four `##` headings and never a fifth, and nothing
branch-specific sits above `## PLAN`. Neither is enforced by anything -- measured, not assumed -- so both went
into the portable page and into the scaffolder's preamble, where every future branch document in every repo
will carry them. The gate question is [#898](https://github.com/DaveKJohn/claude-code-specialists/issues/898)
and [#899](https://github.com/DaveKJohn/claude-code-specialists/issues/899).

**A record's prose and its links were treated differently, deliberately.** Renaming twice made 61 links in
published release notes dead. Measured before deciding: of 29 occurrences of the old plugin path in history, 22
were link targets and 7 were prose in backticks. The link targets followed the move -- which the folder's own
doctrine explicitly permits -- and every prose mention stayed exactly as written. The same split applied to the
`skill-cost.json` baseline: its 13 keys are addresses and moved, its values and their `Version` fields are the
measurement and did not.

**Score:** 5

### What makes this deploy extra special

**Every consumer of this marketplace has to act, and nothing will tell them so.** Their
`.claude/settings.json` names `workflow-davekjohn@claude-code-specialists`, which resolves to nothing at their
next `claude plugin marketplace update` -- and the hook that would have had an opinion about their workflow
keys is the one this change retired. That breakage is accepted rather than avoided: Dave answered decision B
with *"I accept the breakage. I'm the only consumer so it's something I can fix easily myself."*

What softens it is that **only the install line is urgent.** Everything a consumer already has on disk keeps
working: their `workflow-davekjohn/` folder is still read, their branch documents still resolve, their seams
still pass the isolation guard, and their `CLAUDE.md` in that folder is untouched because the scaffold never
overwrites. So the migration is `claude plugin install contributing-davekjohn@claude-code-specialists --scope
project` plus one settings line, and the folder rename can wait for a quiet moment. This repo consumes itself,
so it is the first consumer to need exactly that -- `check-connectors.ps1` already says so.

**And a `workflow-default` install, if anybody has one, simply stops resolving.** No consumer in the register
had it enabled -- re-verified across all four connector records -- so the measured population of that breakage
is zero.

**Score:** 4

### Pull Request

Rename workflow-davekjohn to contributing-davekjohn, and remove workflow-default

Plugins: contributing-davekjohn, team-alpha, team-shopify

[PR #905](https://github.com/DaveKJohn/claude-code-specialists/pull/905)

---

## DEPLOY: `feat/the-cycle-document-has-a-shape-gate-v1` · 20260826-105312

`check-branch-entry.ps1` now reads the SHAPE of `development-cycle.md`, not only its step marks. Two rules
that were enforced by Dave reading the file, on a document a session writes, with nothing in between:

- **Four `##` headings, never a fifth** ([#898](https://github.com/DaveKJohn/claude-code-specialists/issues/898)).
  Anything else is a `###` under one of the four.
- **Nothing but guidance above the first `##`** ([#899](https://github.com/DaveKJohn/claude-code-specialists/issues/899)).
  That region is identical in every branch document in every repo.

Both were broken on the same document within one afternoon, and #899's had been broken by **two sessions
in a row in the same position** -- which is what makes it a shape the document invites rather than a slip.
The harm is worth naming, because "wrong place" understates it: the stray paragraph sat flush under the
guidance with no heading between them, so it *read* as guidance. A reader who finds one branch's status
inside a generic block learns to distrust the whole block, including the rules that do apply everywhere.

**The two rules are scoped differently, and that asymmetry is the design.** The heading count runs only in
the repo that maintains this workflow, behind `Test-IsWorkflowSourceRepo`: heading-blindness is a stated
feature of this gate precisely so a repo that adopted the document may keep headings of its own, and a
check refusing those would refuse correct files elsewhere. The preamble rule holds everywhere, because it
reads the shape and not the text -- guidance is blockquoted whatever language it has been translated into,
so it survives the case a byte comparison against the scaffolder could not (inbound #562 is the consumer
who translated that block).

Neither check re-derives where the entry begins: both read `Split-DevelopmentCycle`, the one splitter three
readers already share, and both are fence-aware, because a document explaining this format quotes its own
headings.

**One correction the tests forced, kept here because it is the useful part.** The first draft reported
"every heading past the fourth" -- which named `## DEPLOY` as the extra the moment the stray sat *above*
`## PLAN`, which is exactly where both measured instances sat. A count cannot say which heading does not
belong. The phases are now read by name from `Get-BranchFileWording`, the same source the scaffolder writes
them from, so a repo that renames a phase is judged by its own names.

**Score:** 3

### What makes this deploy extra special

N/A. One of the two rules reaches a consumer -- the preamble check, which refuses only content that would
misread as generic guidance in their own document -- and the heading rule deliberately does not. The
portable page states which is which, so an adopter can see the boundary rather than infer it. Nothing they
have written today starts failing.

**Score:** N/A

### Pull Request

the branch-entry gate holds development-cycle.md to its four phases and its generic preamble

Plugins: workflow-davekjohn

[PR #904](https://github.com/DaveKJohn/claude-code-specialists/pull/904)

---

## DEPLOY: `fix/the-guard-covers-every-entry-point-v1` · 20260826-102307

`scripts/maintenance/measure-always-on.ps1` now carries the source-repo guard, and
[`scripts/README.md`](scripts/README.md) states the rule instead of counting it.

**The gap, and why nothing saw it.** The guard refuses a shared script that is running from a released
copy inside the repo that maintains it -- the mechanism behind
[#897](https://github.com/DaveKJohn/claude-code-specialists/issues/897)'s subject. `measure-always-on.ps1`
joined the shared registry on August 25 without it, while `scripts/README.md` claimed every shared entry
point but two carried it. Both named exceptions are sound: they are invoked from the plugin by a
SessionStart hook, so refusing there would fail every session start here. This one is no hook -- its own
skill page prints `${CLAUDE_PLUGIN_ROOT}/scripts/maintenance/measure-always-on.ps1` and then says to run
the local copy instead, which is precisely what the guard exists to enforce rather than request.

It was invisible because **the guard's suite tested whether the guard decides correctly and never whether
it is called.** That half is now asserted off the registry, so the next entry point is held to the rule on
the day it is registered rather than on the day somebody re-counts. Two supporting asserts keep the assert
itself honest: the entry-point set must be non-empty, and an exemption must name a file that exists and is
registered -- a licence cannot outlive what it excuses.

**A stale measurement tool is the worst place for this gap**, which is why it is repaired rather than
exempted. A stale copy of a measuring script does not fail; it reports. That file's own docstring is the
record of what a plausible wrong number costs here: the chars-per-token factor was inherited unexamined
through three hand measurements and was ~19% too generous, so every derived figure was under-stated while
looking precise.

**The page stops counting, and that is the durable half.** Its two tallies were both wrong, and re-typing
them would have been wrong again twice over: the registry holds **43** pairs today and **42** the moment
#886 removes `workflow-default`, because `check-report-lib` is deliberately registered to two other
plugins as well. So the counts are gone -- the registry is named as the authority, and the entry-point
claim is a rule with two named exceptions held by a test. Same resolution the root `CLAUDE.md` reached
about counting a name inside the document that carries it.

**Score:** 3

### What makes this deploy extra special

N/A. A consumer receives the mirrored `measure-always-on.ps1` with the guard in it, and the guard is a
no-op for them by construction -- it refuses only where the repo being operated on holds its own copy of
the running script, which a consumer never does. The README and the test are source-side. No consumer
behaviour changes.

**Score:** N/A

### Pull Request

every shared entry point carries the source-repo guard, and scripts/README.md stops counting

Plugins: workflow-davekjohn

[PR #902](https://github.com/DaveKJohn/claude-code-specialists/pull/902)

---

## DEPLOY: `feat/gate-validates-import-targets-v1` · 20260826-093433

The lint gate now resolves every `@`-import target it can see, and refuses a dead one whose target is
in the tree. Check 4 has validated `[text](target)` links since the beginning; an `@`-import is a
different syntax and matched none of it, so no gate in this repo had ever resolved one --
[issue #874](https://github.com/DaveKJohn/claude-code-specialists/issues/874).

**Why this class is not just another dead link.** A dead link costs a reader one click. A dead import
costs the **session the whole document**: Claude Code drops one it cannot resolve without erroring, so
nothing fails and the instructions simply are not there. This repo's always-on path is assembled out of
exactly three imports, and two of them are not repo-relative -- so the layer that vanishes is the one
carrying the safety rules or the roster, and the only symptom is a session behaving as if it had never
read them.

Check 28 reuses the parser in `scripts/lib/measure-context-lib.ps1` rather than restating the three
resolution rules, so the gate and `scripts/maintenance/measure-always-on.ps1` cannot drift on what an
import means or where it resolves from. Two discriminators keep it honest, both measured before it was
written: a fenced `@(...)` is PowerShell, and a target containing whitespace is prose -- seven and one of
the twelve column-0 `@` lines in the tree respectively. A target outside the repo is counted and named,
never refused, because a `~/`-relative import points into the plugin marketplace clone and CI is a
machine without one.

**Born green**, this repo's standing bar for a new check: 294 files scanned, 2 resolving in-tree imports,
1 outside the repo, 1 line read as prose, 0 findings and 0 exemptions.

**Score:** 3

### What makes this deploy extra special

N/A. The check itself lives in `scripts/lint/`, which is this repo's own gate and does not travel to a
consumer. What does travel is the plugin mirror of `measure-always-on.ps1`, and only its wording changed
there -- the sentence saying no gate covers this class was true when it was written and is not any more.
No consumer behaviour changes.

**Score:** N/A

### Pull Request

the lint gate validates every '@'-import target

Plugins: workflow-davekjohn

[PR #901](https://github.com/DaveKJohn/claude-code-specialists/pull/901)

---

## DEPLOY: `fix/the-deploy-section-is-locked-at-the-pr-v1` · 20260825-234507

The DEPLOY section is now **one text in all four places it lands** -- the branch's own
`development-cycle.md`, the PR body, `CHANGELOG.md`, and the developer release notes -- and it is **fixed
at the moment the PR opens**. `ship-pr` refuses to merge when the document has since diverged from what
the PR published, and the branch-entry check in CI refuses the same thing for a PR merged from the GitHub
UI. Neither has a `-Force`, like the step-list gate beside them. What that closes is a window that used to
shut invisibly: an edit made after the review landed in the changelog and from there in the release notes
having been seen by nobody, and because the fold *removes* the document at the merge, the place a reviewer
would compare the two was the one place it no longer existed.

Two changes had to happen for that to be checkable at all, and both are reversals recorded rather than
quietly made. The heading says **`What makes this deploy extra special`** again -- `deploy` was written
August 23, `PR` replaced it August 24 ([#865](https://github.com/DaveKJohn/claude-code-specialists/issues/865)),
and #884 puts it back, because two of the section's four readers are not looking at a PR and the two that
come last are the ones a release is read from. And `Get-PrDescription` now carries the `## DEPLOY:` heading
**verbatim**, promoting nothing, which reverses the August 9, 2026 heading promotion **on today's shape
only**: while body and document were two renderings of one section, a comparison would have had to
reproduce the transform to make sense of them. The legacy `What does the change...` path keeps promoting,
because there the H2 genuinely stays behind, and consumers have such branches in flight.

**Score:** 3

### What makes this deploy extra special

A consumer meets three things at their next plugin update. Their PR bodies start carrying the
`## DEPLOY:` heading and the section's own levels, instead of a level-shifted copy with the heading
dropped -- so a PR body and the changelog entry it becomes now read as the same document. Their scaffolder
writes `deploy` rather than `PR`, and every wording it has ever written is still **read**, so branches in
flight fold unharmed. And a merge is refused where it used to go through: edit the DEPLOY section after
opening the PR and `ship-pr` stops, naming the first line the PR body does not have, with two ways out --
put it back, or republish deliberately with `open-pr.ps1 -RefreshBody` so the change is reviewable where
the review happens.

The one action a consumer may have to take is a permission line: reading a PR body needs
`pull-requests: read` on the branch-entry workflow, on top of the `contents: read` it has today. Without
it the lock reports that it could not read the body and merges anyway -- deliberately, because `gh`
failing says something about the token rather than about the section -- so nothing breaks, it simply does
not fire.

**Score:** 4

### Pull Request

The DEPLOY section is locked once the PR opens, and says deploy everywhere

Plugins: workflow-davekjohn

[PR #895](https://github.com/DaveKJohn/claude-code-specialists/pull/895)

---

## DEPLOY: `docs/development-portable-rename-v1` · 20260825-222427

Renamed `DEVELOPMENT-CYCLE-portable.md` to `DEVELOPMENT-portable.md` and repointed every reference
to it repo-wide, so the manual's name no longer contradicts the working file it describes
(`development-cycle.md`, not `development-cycle-cycle`).

**Score:** 1 — cosmetic naming cleanup; no behavior, script contract, or consumer-facing change.

### What makes this PR extra special

N/A — an internal doc rename, nothing a subscriber of the service would ever see.

**Score:** N/A

### Pull Request

Rename DEVELOPMENT-CYCLE-portable.md to DEVELOPMENT-portable.md and update every reference

Plugins: workflow-davekjohn

[PR #893](https://github.com/DaveKJohn/claude-code-specialists/pull/893)

---

## DEPLOY: `feat/isolate-workflow-from-consumer-root-v1` · 20260825-204036

Nothing changes for this repo's own release runs today — the computed defaults exempt the source repo
outright, so `CHANGELOG.md` and `releases/` keep resolving to the exact root paths they always did. What
a developer here meets is the plumbing underneath: the two duplicate `Get-SeamValue` copies collapse into
one shared `seam-lib.ps1`, which also carries the four isolate-by-default seams and the new
`Assert-WorkflowIsolatedSeamPath` provenance preflight, backed by its own dedicated suite
(`seam-lib.tests.ps1`, 8 asserts) among the eleven suites this branch touched. Noticed the next time
somebody works in a release script, not before.

**Score:** 2

### What makes this PR extra special

A consumer no longer risks the plugin reaching into their repo root: the changelog, the three release-note
roots (`releases/development/`, `releases/github/`, `releases/internal/`) and the release-history index
all default inside `workflow-davekjohn/` now, and the provenance preflight refuses outright if a
consumer's own explicit override still resolves outside that folder. This closes a hazard that was
measured rather than theoretical — the root `*.md` sweep could misread a consumer's own permanent doc as a
stray, unfolded changelog entry, and two portable pages (`TICKETWORK-portable.md`,
`CONTRIBUTING-portable.md`) carried hand-written workarounds telling consumers how to dodge it; both are
gone now because the sweep itself no longer needs them — it reads content, not a name list. An
already-adopted consumer does have to notice this on their next fold or cut: entries land in
`workflow-davekjohn/CHANGELOG.md` rather than their root file from here on, and a pending entry already
sitting in their old root `CHANGELOG.md` is not picked up automatically — the re-adoption migration note
this branch added documents exactly that. The same split reaches `releases/README.md`: an already-adopted
consumer's release history moves to `workflow-davekjohn/releases/history.md` from here on (named
`history.md`, not `README.md`, because that folder already uses `README.md` for its own hand-written
seam-answers page) — old rows stay at the root file, new rows land in the folder, the same accepted-cost
duplication as the changelog rather than a silent redirect.

**Score:** 5

### Pull Request

Isolate the workflow from the consumer's repo root

Plugins: workflow-davekjohn

[PR #890](https://github.com/DaveKJohn/claude-code-specialists/pull/890)

---

## DEPLOY: `fix/remove-prompt-inbox-v1` · 20260825-155219

Removed the prompt-inbox mechanism entirely (issue #882, Dave): the `workflow-davekjohn/prompts/`
folder, the `prompt` skill, its two scripts (`prompt-inbox.ps1` + `prompt-inbox-lib.ps1`, root and
plugin mirror), the `prompt-sessioncheck` SessionStart hook, and every doc that named any of it — the
plugin's own README and scripts README, this repo's `workflow-davekjohn/CLAUDE.md` and
`workflow-davekjohn/README.md`, the root README's two skill-list spans, `SPECIALISTS.md`,
`connectors/README.md`, and a stale cost baseline. No replacement: Dave now hands assignments over as
GitHub issues instead.

Tier 1 — this repo's own contributors notice one fewer skill and, once merged, one fewer SessionStart
hook line; nothing in how a branch, PR or release works changes.

**Score:** 3

### What makes this PR extra special

N/A — nothing here reaches a service subscriber; the prompt inbox was a workflow-authoring convenience
inside this repo and its consumers, never anything an end user of a published product could see.

**Score:** N/A

### Pull Request

Remove the prompt inbox from workflow-davekjohn

Plugins: workflow-davekjohn

[PR #889](https://github.com/DaveKJohn/claude-code-specialists/pull/889)

---

## DEPLOY: `fix/release-notes-at-the-changelogs-own-level-v1` · 20260825-125958

**The generated developer release notes now render at `CHANGELOG.md`'s own heading levels.** Entries sit at
`##` and their sections at `###`, exactly where the fold wrote them, so an entry copied out of the record
into a hand-written note pastes at the level it was written at instead of needing a manual shift.
`Build-ReleaseNotes` no longer opens each tier group with `## Tier <n> - <audience>` — measured at `v4.19.0`
in [#881](https://github.com/DaveKJohn/claude-code-specialists/issues/881), that wrapper put all 35 entries
at `###` where their source had them at `##`, a pure one-level shift of every heading in the file. The tier
still decides the order (highest first, ranked inside a tier); it no longer prints a heading to say so,
because where a change reached is a claim about attribution and this document is the record of what changed.
Each entry states its own reach, so nothing is lost with the heading.

**The heading was machine-read, and that is the half the report did not see.** `new-internal-note.ps1`
filtered tier 0 out of the internal note by walking those `## Tier <n>` headings, with a documented
fallback — no tier headings means take everything — that would have carried all 11 tier-0 entries of a
release into the one document tier 0 exists to stay out of: no error, plausible output, a document written
for colleagues listing repo-internal housekeeping. `releases/development/4.x/4.8.0.md` had recorded this
dependency in so many words when it left the wording alone. The filter now reads each entry's **own**
declaration through `Resolve-EntryImpact` — the same reader `Get-PullRequestEntriesByTier` groups on, so
the two cannot disagree — and keeps the container heading as the fallback, because it is the only tier
information an archived note carries whose entries pre-date the declaration entirely, and this script takes
a version: it can be run against any release ever cut.

**`v4.19.0`'s own notes were regenerated rather than edited.** The 35 entries were read back out of
`CHANGELOG.md` at `9983299`, the commit before the cut, and re-rendered by the new generator; the
normalised diff against the published file is exactly the two tier headings gone plus one `---` at the
seam, and the heading profile now matches the pre-cut changelog's 35/70/7 line for line.
`Get-ReleaseTierHeading` and the `Heading` field are kept and documented as unrendered, for the reason
v4.8.0 already gave for this same heading: they are the single source of that wording, every note ever cut
carries it, and removing a published field of that contract is a decision of its own.

**Score:** 2

### What makes this PR extra special

A consumer's cut writes this document too, so the level correction and the repaired tier filter both
arrive with the plugin — including the failure the filter prevents, which a consumer would have met as
repo-internal entries appearing in the note they hand to colleagues. `RELEASES-portable.md` states the new
shape, so the page describing the document and the generator writing it agree.

**Score:** 3

### Pull Request

Developer release notes render at CHANGELOG.md's own heading levels

Plugins: workflow-davekjohn

[PR #883](https://github.com/DaveKJohn/claude-code-specialists/pull/883)

---

