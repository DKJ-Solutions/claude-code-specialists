# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections. The `##` heading is the change's own — `` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `### What makes this PR extra special` for the second audience, and `### Pull Request`.
The tier numbers live in the parser rather than in any heading. That second heading said `deploy` rather
than `PR` for one day, August 23 to 24, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was. Entries written before August 23, 2026
carry that first answer under a `###` question of its own with the second nested at `####` beneath it;
entries before August 16 carry the longer set of headings that shape replaced, and every earlier shape is
read exactly as it always was. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier, each closing with its score. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## DEPLOY: `feat/measure-the-always-on-document-path-v1` · 20260824-171032

**The always-on document path can now be measured by running something instead of by typing `wc -c`.**
`scripts/maintenance/measure-always-on.ps1` walks `CLAUDE.md` and everything it `@`-imports, and reports
each document and each section by bytes, share and estimated tokens.

That figure had been hand-produced four times (July 28, August 14, August 15 and August 24, 2026), and the
performance lens records the cost of that three separate times in its own words: *a measurement in a
document that nothing regenerates goes stale silently*. It did, in the most expensive way available — the
conversion factor was inherited unexamined at 3.70 through three re-measurements and was ~19% too
generous, so every token figure derived from it was under-stated while looking precise. The factor now
lives in `scripts/lib/measure-context-lib.ps1` with its calibration attached, where it cannot be inherited
by copying a table.

Four properties are enforced rather than remembered, each one a rule this repo already had:

- **Bytes are labelled a measurement and tokens an estimate, in the output itself.** `do not estimate from
  file sizes` governs the subject the `count_tokens` API prices; it does not price documents, so here an
  estimate is the only answer available and the honest move is to say so every time. The plugin listings
  stay `measure-skill`'s and the report says so instead of absorbing them.
- **The copy that LOADS is the copy reported.** The orchestrator persona is imported from the marketplace
  clone, so the report names it and prints the tree counterpart beside it — today 16,585 B loaded against
  21,860 B in the tree, i.e. 5,275 B of queued cost arriving at the next plugin update.
- **The sections must sum to the file or no table is printed**, because a plausible wrong share is worse
  than a refusal.
- **A dead `@`-import is reported rather than skipped.** It costs a session the whole document and nothing
  errors; no gate covers that class yet, which is now filed as #874.

It reaches **no verdict** about what should move, deliberately. That is the outcome of #861, where a skill
that would have judged an instruction document block by block was argued down and the verdict accepted: the
judgement is one already-written sentence, while a portable skill would have put always-on cost into three
consumer repos that do not share this repo's condition. The boundary that came out of it — `portable-first`
applies to rules, not to tooling that carries a per-session cost — is recorded in the performance lens.

Also on this branch, both found on its own route: `scripts/README.md` was missing a row for
`maintenance/measure-skill.ps1` in the table whose own preamble says everything unlisted is "a lib, a
generator or a test", and its `maintenance/` description ("one-off repairs run by hand") covered neither
measurement script.

**Score:** 3

### What makes this PR extra special

N/A — what this PR itself deployed reaches no consumer: the script landed repo-local, registered in no
mirror and carrying no skill page.

**The reason this section originally gave is withdrawn, and the withdrawal belongs here rather than in a
later entry.** It said the repo-local placement was "the point rather than an omission", because consumers
do not have this repo's condition. That argument was #861's, and #861 was about a **skill** — a new
always-on description, paid by every session in every consumer whether it fires or not. Mirroring
deterministic code under a description that already exists is a different act and costs a consumer nothing
per session, which is what the entry for
[#875](https://github.com/DaveKJohn/claude-code-specialists/issues/875) does — pending in this same
changelog, so a reader meets both in one document. Correcting it here rather than superseding it there is
the whole point: the claim has not shipped, and a release note carrying both would have contradicted itself
in the same breath.

**Score:** N/A

### Pull Request

The always-on document path is measured by a script instead of by hand

[PR #876](https://github.com/DaveKJohn/claude-code-specialists/pull/876)

---

## DEPLOY: `docs/entry-shape-examples-follow-the-merged-document-v1` · 20260824-153800

**The pages that teach the entry format now teach the one the scaffolder writes.** On August 23, 2026 the
branch entry became the DEPLOY section of `workflow-davekjohn/development-cycle.md` — the heading became
`` ## DEPLOY: `<branch>` ``, tier 0's answer lost its own heading and moved directly under it, and the
audience tier's sub-heading rose to `###`. The code, the two portable documents and `CHANGELOG.md`'s intro
followed. Six documents did not, and each one presented the retired shape as current:
the `new-branch`, `fold-changelog`, `open-pr` and `cut-release` skill pages, the release lens
`.claude/specialists/lenses/05-06-extension.md`, and `CONTRIBUTING-portable.md`. Nine example blocks and the
prose around them now match a rendered scaffold rather than a shape retired a day earlier. From
[#870](https://github.com/DaveKJohn/claude-code-specialists/issues/870).

**The shape was taken from the code, not from the report, and that is what caught the third fact.**
[#865](https://github.com/DaveKJohn/claude-code-specialists/issues/865) had retexted the audience heading
to `What makes this PR extra special` between the issue being written and being picked up, so a repair
scoped to the issue's own bullets would have corrected the nesting and kept the retired wording — a
citation on a wrong answer. `Format-EntryBlock` was rendered directly and the newest folded entry in
`CHANGELOG.md` read alongside it; both agree, and every example here is now that output.

**Two of the report's measurements did not survive the recount, and one of them widened the job.** The
issue said all five documents showed `` ## `feat/x` deployment ``; two did. It said two of three facts were
wrong; all three were, the third in two independent ways. And it named `CONTRIBUTING-portable.md` among the
documents that *followed* the change — it had not. That sixth document stayed hidden through two
line-based sweeps because the phrase wraps across a line break, so the full-string grep could not match it;
a multiline re-sweep is what surfaced it, and is what now backs the claim that nothing instructional is
left. `fold-changelog/SKILL.md` also carried an unreported fourth fact, the merge stamp still on
`### Pull Request` where it moved to the DEPLOY heading in the same movement — that page stated the new
placement forty lines below the example contradicting it.

**Nothing changed at runtime, and the reason is the standing rule.** Every retired wording is still read —
`Get-EntrySectionBody`, `Get-EntryTierHigherRetiredHeadings` and `Get-EntryTierSubLevelRange` recognise all
of them — so an entry written from a stale example still folds, and no entry in flight or already in
`CHANGELOG.md` is affected. No script and no test changed. `CHANGELOG.md`'s folded entries and the published
release documents keep the shape that was current at their version: they are the record, not instruction.

**Score:** 3

### What makes this PR extra special

Four of the six repaired documents are plugin payload — the `new-branch`, `fold-changelog`, `open-pr` and
`cut-release` skill pages — and `CONTRIBUTING-portable.md` is a fifth. These are what a consumer reads to
learn the entry format, and until now they described a shape their own `new-branch` had stopped writing, in
nine separate examples. A consumer following them wrote an entry that still folded, so nothing failed
loudly; what they got was a document that did not match the file in front of them, with no way to tell
which was right. The correction arrives with the next release and needs no action: no consumer file is
rewritten, and every retired wording stays readable.

**Score:** 3

### Pull Request

The entry-shape examples follow the merged development-cycle document

Plugins: workflow-davekjohn

[PR #872](https://github.com/DaveKJohn/claude-code-specialists/pull/872)

---

## DEPLOY: `feat/the-pr-starts-with-its-answer-v1` · 20260824-150017

**A PR body now opens with the answer instead of with a question the document stopped asking.** The PR
template's `# What does the change on this branch deploy to main?` is gone, and the audience tier's
heading reads `What makes this PR extra special`. Both come from
[#865](https://github.com/DaveKJohn/claude-code-specialists/issues/865), and both are the same
correction: on August 23 the entry became the DEPLOY section of `workflow-davekjohn/development-cycle.md`
and tier 0's answer lost its heading — the text sits straight under `## DEPLOY:` — so the template was
the last place in the system still asking a question nothing else asked.

**The header was load-bearing, and that is the whole change.** `-RefreshBody` replaced the description
under the template's first heading; a template with none would have degraded to its warning branch on
every run — the switch silently lost, reported as *"the description was left as it is"*, which reads like
a decision. `Update-PrBodySection` therefore learned the **leading section**: an empty `-Heading` starts
at the top of the body, writes no heading line back, and takes its boundary from `-StopAtHeading` alone,
since nothing is shallower than no heading. That is the mirror image of inbound #598, where nothing was
shallower than an H1.

**And `open-pr` stopped reading "the first heading" at all — it reads where the PLACEHOLDER sits.**
Headings above it are the description's, headings below it are the form's boundaries, and a placeholder
that comes first means the leading section. That was always the real rule; it was simply never the one
being read, and under a heading-less template the old shortcut is wrong in the direction that costs
something: in a template of `<placeholder>` + `## Checklist` it would have named the checklist as the
description and overwritten it on every refresh.

**No legacy heading was added anywhere, and that was measured rather than assumed.** A PR opened under
the retired H1 keeps it in its published body, above the first form heading — so the leading section
covers it and it is replaced along with everything else. Lint check 24's contract lost its second half
for the same reason: a heading-less template is now the shape `open-pr` expects, so a gate refusing one
would refuse the template this repo ships.

**The rename uses the mechanism already there — recognise every wording, write one.**
`What makes this deploy extra special` joins the retired list after **one day**, the shortest life any of
the four has had, which changes nothing: a single day is enough for a branch to be in flight, and
`CHANGELOG.md` was still holding entries written under it. Every wording is still read, so nothing
pending stops folding. The suite that guarded this asserted only `[0]` of that list, so it had been
measuring exactly one member while the list grew; it loops now.

**Named because the issue does not name it:** this heading also lands in `CHANGELOG.md` and in the
release documents, where nobody is looking at a PR. Dave asked for this wording explicitly and the
reasoning is recorded beside the constant, so the next person to reopen the question learns it was not
overlooked.

**Score:** 3

### What makes this PR extra special

A consumer's own `.github/pull_request_template.md` is **their** file and nothing here rewrites it, so
nothing breaks on the update and there is no migration. What arrives is a choice: the shipped reference
under `${CLAUDE_PLUGIN_ROOT}/templates/` is now one line, so a consumer who diffs against it can drop
their own header and get a PR body that leads with the answer. Two things arrive whether or not they do —
`new-branch` writes the new audience-tier heading, and their gate stops requiring a template heading. A
template that keeps its heading behaves exactly as before, and one that keeps its own sections is still
bounded by them; what is new is that a heading below the placeholder is now read as the form's rather
than as the description's, which is a repair for anyone whose template had two headings above it.

**Score:** 3

### Pull Request

A PR body starts with its answer, and its second section names the PR

Plugins: workflow-davekjohn

[PR #871](https://github.com/DaveKJohn/claude-code-specialists/pull/871)

---

## DEPLOY: `fix/deploy-is-written-once-test-is-green-v1` · 20260824-140733

The development cycle's own **Rules** said one thing about when the DEPLOY section is written: *"Fill in
every tier the DEPLOY section carries **before the PR**."* That is an upper bound with no lower one, so the
whole entry could legitimately be composed on day one — and an entry written while steps above it are still
open states an **intention**, not a result. Nothing holds it against what landed: the step gate splits the
document at that heading and counts only above it, so what folds into `CHANGELOG.md` is whatever was
written before the work was finished, however the work then turned out.

Rule 6 gains its lower bound — *once TEST is resolved, and before the PR* — and the arc section gains the
reason, beside the sentence that already said a branch *reaches* DEPLOY once it has verified itself. Those
two words are the whole confusion: reaching that phase and writing its section are not the same act, and
only the second one survives a suite that turns something up. The measured instance is the branch that
merged an hour before this one (PR #868): PLAN 6/6 and CREATE 4/4 ticked, **TEST three steps open** — and
those three written as results rather than as checks — with DEPLOY complete and both tiers scored.

**One field is deliberately excepted, and checking that saved the rule from being wrong.** `-Title` writes
into the DEPLOY section at creation (`scripts/task/new-branch.ps1`, `$description = $Title`), because
`open-pr` composes the PR title from it rather than taking one on the command line — typed once, so it
cannot disagree with itself. A blanket *"write DEPLOY last"* would have contradicted the tooling on the
day it shipped. What waits for TEST is the entry's prose and its tier scores, which are claims about what
the change *did*.

**And no gate enforces it, on purpose.** The gates run once, at the push, and at that moment a finished
branch legitimately has a full DEPLOY and a resolved TEST — "too early" is an ordering in time, visible
only in the commit history. So this lands where the failure is: rule 6, the arc, and the guidance
blockquote every branch document carries, which is the one text that reaches a writer at the moment of
writing.

**Score:** 3

### What makes this deploy extra special

The guidance block is scaffolded into **every** development cycle document the workflow creates, so a
consuming repo does not have to read the portable page to meet the rule — it arrives in the file they are
already writing in, the first time they open a branch after the update. And this branch is its own first
test: TEST was resolved and only then was this section written.

**Score:** 3

### Pull Request

DEPLOY is written once TEST is resolved, not before

Plugins: workflow-davekjohn

[PR #869](https://github.com/DaveKJohn/claude-code-specialists/pull/869)

---

## DEPLOY: `feat/filing-a-finding-needs-no-permission-v1` · 20260824-134524

The shared block every specialist carries already said a finding becomes an issue rather than a question
at the end of the turn. It did not say that **asking permission to file is the same failure** — and that
gap is not theoretical: this branch exists because a session closed out with *"say the word and I'll file
it"*, which reads as courtesy and leaves the owner holding exactly the decision filing exists to remove.

The block now names the offer form outright, and adds the half nothing in the tree stated: **the question
to answer before filing is not "may I?" but "does it still stand?"** The permission question feels like
diligence and displaces the check that matters, so a finding that has never been held against the tree
arrives pre-approved. The measured instance is the one that produced this branch — the finding was that
`open-pr` writes a PR body with no closing reference, and it was false three times over: `-Resolves` and
`-NoResolves` both exist, the gate reads the branch's own document and blocks only where it names an open
issue, and the reason it stayed silent was that the author never cited the number. Approval would have
filed a defect nobody has. The block therefore also says what to do when a finding collapses: withdraw it
with its reason, rather than file a weakened version to justify having raised it.

**Score:** 4

### What makes this deploy extra special

It reaches **30 agent defs and personas across all four teams** through the shared-block generator, so
every specialist a consumer runs gets it at once rather than the orchestrator alone. And it closes a gap
in a guardrail rather than adding a preference: the rule it extends was already there and already
escapable through the one phrasing that sounds like good manners.

**Score:** 3

### Pull Request

Filing a finding needs no permission, and verifying it is the step that does

Plugins: team-alpha, team-ecomm, team-lifehub, team-shopify

[PR #868](https://github.com/DaveKJohn/claude-code-specialists/pull/868)

---

## DEPLOY: `feat/chris-owns-the-phase-transitions-v1` · 20260824-124101

The orchestrator's fixed ritual and the development cycle described the same work and never referred to
each other: the persona named no phase, and the cycle left its actor open as *"whoever is working on the
branch"*. Each was complete on its own terms, which is why the gap survived — a reader met six steps with
no phases in one plugin and four phases with no owner in the other, and had to invent the join.

Chris's persona now carries `## Where a workflow ships a phase model`: a table binding PLAN to steps 1–2,
CREATE to steps 3 and 5, and DEPLOY to step 6, with **TEST named as deliberately not his** and step 4
(Guard) mapped onto no phase because it is what runs at every boundary between them. The section is
conditional — a repo with no method reads it as inert — and it fixes the dependency direction in prose:
a phase model may know which specialists it routes through, the specialists must never require one to
exist. That is the direction the tree already had (`workflow-davekjohn` requires `team-alpha`, never the
reverse), written down where the next editor will meet it.

**Score:** 3

### What makes this deploy extra special

Every consumer running a team gets an orchestrator who knows what a phase model is without being made to
depend on one, and the section that says so is the first place either plugin admits the other exists in
prose rather than in a script. It follows the `workflow-sessioncheck` precedent — the workflow-aware piece
lives in the core team — instead of opening a second pattern beside it.

**Score:** 3

### Pull Request

Chris owns the phase transitions where a phase model is installed

Plugins: team-alpha

[PR #866](https://github.com/DaveKJohn/claude-code-specialists/pull/866)

---

## DEPLOY: `fix/a-lane-can-run-its-own-gates-v1` · 20260824-115314

A lane exists so a branch can be built while another one ships -- and until now it could be built in but
not **checked** in. The source-repo guard resolves the repo from `CLAUDE_PROJECT_DIR`, which still names
the primary checkout, so every lane path read as a released snapshot and every gate run from a lane was
refused. Worse, it was refused in the wrong words: the lint gate has its sub-script's exit code and no
finding to attribute it to, so it reported *"the mojibake gate could not complete"* -- an encoding problem
in a tree that had none. So a lane-built branch was verified for the first time by CI, after the push,
which is the wait lanes exist to remove.

The guard now accepts a script inside a **worktree of the same repository**, compared on
`git rev-parse --git-common-dir`: a linked worktree shares one `.git` with the primary, while a separate
clone answers with its own -- so the plugin cache mirror this guard exists for is still refused, and that
pair is asserted together on a real repo. Check 25 quotes the child's first line and names a refusal when
it is one, and `worktree-lane.ps1` now says in its closing output that the gates run there.

**Score:** 4

### What makes this deploy extra special

Every consumer that opens a lane gets the same repair, and it removes a trap rather than adding a feature:
the previous behaviour did not just refuse, it reported the wrong subject, which is the shape that costs a
reader an afternoon. Nothing about the guard's reach is widened -- a released copy is refused exactly as
before, proved by an assert that runs against a real clone rather than a fixture.

**Score:** 3

### Pull Request

A lane can run this repo's own gates

Plugins: team-shopify, workflow-davekjohn

[PR #864](https://github.com/DaveKJohn/claude-code-specialists/pull/864)

---

## DEPLOY: `feat/close-out-has-three-shapes-v1` · 20260824-111818

Step 6 told Chris to summarise *what else might be possible*, and that clause is what produced replies
ending in "what is still open" and "what I deliberately left alone" -- so the requester could not tell
whether the assignment was finished. A close-out is now **one of three shapes**: **done**, and the session
can be closed; **one decision put as a menu**, so the work continues in the same turn; or **a blocker
already parked**, reported as a state that is handled -- the issue filed with its number, the branch
parked. Everything that would otherwise wait becomes an issue at the moment it is found, and the close-out
names what it filed rather than asking about it. This is the output half of the rule #847 landed the day
before: that one says a finding becomes an issue instead of a question, and a turn could obey it and still
close with three paragraphs of open points, which is the pair that made the complaint. **Chris only, not
the shared block**: a subagent's final text is a return value to its caller, not a reply to the requester.

**Score:** 4

### What makes this deploy extra special

It changes how every consumer's sessions END -- the moment a person decides whether they can close the
window -- and it removes work from them rather than adding any: an unanswered list becomes a filed issue
with a number. Costs stated rather than left to be found: this persona loads in every session, and the
step grew by **1,691 bytes**, about +10% of the file and roughly +420 tokens per session. That is the
trade, and it is a small one against a reply whose ending had to be interpreted.

**Score:** 4

### Pull Request

A close-out is done, a decision, or a parked blocker -- never a list of what waits on you

Plugins: team-alpha

[PR #862](https://github.com/DaveKJohn/claude-code-specialists/pull/862)

---

## DEPLOY: `docs/test-phase-is-the-verification-v1` · 20260824-110245

The page said what TEST *may* leave out; it did not say what the phase is *for*. It does now: TEST is where
a branch verifies itself, and a branch reaches DEPLOY once it has -- with the check named and its outcome
recorded, because a check with no place in the arc gets run when somebody remembers to. The sharpening that
does the work is separating two sentences that were reading as one: `- [~]` means **no suite**, never **no
verification**. A dropped step still names what was run and what came back, so a TEST phase whose whole
content is *"nothing to test"* is recognisable as an assertion rather than a verification. Two shapes are
honest and neither is a suite -- running the gates and reporting the outcome, and a check the phase cannot
automate as long as it records that it ran. One is not: a step ticked because the change looks correct,
which is the failure rule 3 already names from the other side.

**Score:** 4

### What makes this deploy extra special

This is the difference between a session somebody watches and one they can walk away from, and it reaches
every consumer of the workflow through a plugin update. It adds no gate and forbids nothing that was
allowed: a bare TEST heading is still permitted and still no finding. What changes is that the phase now
states its own purpose, so the weaker answer is recognisable as the weaker answer.

**Score:** 3

### Pull Request

The TEST phase is where the branch is verified, and it names the check that was run

Plugins: workflow-davekjohn

[PR #860](https://github.com/DaveKJohn/claude-code-specialists/pull/860)

---

## DEPLOY: `docs/plan-phase-explore-then-goal-v1` · 20260824-104821

The PLAN phase now says how it is entered and how the cycle is driven to its end. Exploration happens in
**plan mode**, where Claude reads and proposes but cannot edit, and the sequence is spelled out because
getting it wrong stalls step one on its own scaffold: `new-branch` writes a file, so the plan has to be
approved before the branch exists. Then the cycle is driven by a `/goal` condition rather than by prompting
it forward turn by turn -- written so this document's own gates prove it, because the evaluator runs no
commands and reads no files. The three endings are separated on purpose: **Met** continues into DEPLOY,
**Impossible** parks the branch and turns the blocker into its own issue, and a **stall** means nothing
about the work at all -- the goal is still set and the harness is waiting for a prompt. Reading a stall as
a blocker would park a branch over a loop that simply went quiet. The phases hold unchanged without any of
it: `/goal` is part of the hooks system and is unavailable in an untrusted folder.

**Score:** 4

### What makes this deploy extra special

Every consumer of this workflow gets a documented answer to "how do I actually run a cycle", which the page
did not carry: it described the form and left the driving to whoever was at the keyboard. It reaches them
through a plugin update, and it deliberately adds no requirement -- a repo without hooks available runs the
same cycle it ran yesterday.

**Score:** 3

### Pull Request

The PLAN phase explores before it plans, and a goal condition drives the cycle

Plugins: workflow-davekjohn

[PR #859](https://github.com/DaveKJohn/claude-code-specialists/pull/859)

---

## DEPLOY: `fix/pr-body-keeps-the-deploy-opening-v1` · 20260824-103401

Since the development cycle became one document, every PR body has silently lost the entry's opening text
-- the substance a reviewer decides on. `Get-PrDescription` looks for a `What` heading, the merged format
has none (its body sits directly under `## DEPLOY:`), so the caller fell back to `Get-EntryDescription`,
whose "the first `### ` line is the entry heading" rule was written when the heading really was an H3.
Under the merged format that first `###` is a section inside the body, so the fallback returned the tail
from there: measured at 0 chars from one function and ~24% of the entry from the other, in a body that had
a heading, a filled-in significance section and a green CI. `Get-PrDescription` now recognises the DEPLOY
heading itself, through the same matcher the fold and both gates use, and a `What` section still wins
where an author wrote one. **The fold was never affected** -- `CHANGELOG.md` received every entry complete
-- so nothing is lost in the record; what is restored is the review moment.

**Score:** 4

### What makes this deploy extra special

This was reported by a consumer, on the first PR they opened under the merged format, and it reaches every
other consumer the same way it reached them: through a plugin update, with no action on their side. Their
report is also the reason it was found at all -- the failure is silent and the body looks complete, so the
gates could not have caught it. Two things go back to them with the close: the repair sits one function
further along than the report proposed, and the repro snippet names a `Resolve-PluginScript` that exists
nowhere in the tree, so it would not run as written.

**Score:** 4

### Pull Request

The PR body carries the entry's opening text again

Plugins: workflow-davekjohn

[PR #858](https://github.com/DaveKJohn/claude-code-specialists/pull/858)

---

## DEPLOY: `docs/verification-is-a-plan-step-v1` · 20260824-101405

A branch whose real work is judgement -- verifying a report, choosing between two designs, establishing
that a claim still holds -- produces no artefact until the writing starts, so the phase arc offered it no
home and the path of least resistance was to record only the writing. The portable page now says those
are PLAN steps and shows the shape, and says that where no automated test was added `- [~]` answers with
the reason rather than leaving TEST blank. Both stay conventions: a bare heading is still permitted and
still no finding, because no gate can tell a branch that had nothing to plan from one that never wrote
its plan down. What changes is that the weaker of the two answers is now named as such.

**Score:** 3

### What makes this deploy extra special

Every consumer of this workflow scaffolds the same document, and this reaches them the way all guidance
on that page does -- through a plugin update rather than through a file written once at adoption. It
costs them nothing at scaffold time: the page is the reference, not the template.

**Score:** 2

### Pull Request

Verifying and deciding are PLAN steps, and TEST answers with a reason

Plugins: workflow-davekjohn

[PR #856](https://github.com/DaveKJohn/claude-code-specialists/pull/856)

---

## DEPLOY: `docs/cache-follows-refresh-not-push-v1` · 20260824-095933

`CLAUDE.md` promised that a session here sees the **last pushed** version of the plugins. It does not: a
session reads the local marketplace clone, and that clone advances on `claude plugin marketplace update`
rather than on a push. Measured on August 23, 2026, after four PRs had merged and pushed, the clone still
stood on the previous day's commit while `/plugin` reported nothing to do and `check-connectors.ps1`
reported `[OK] machine record is on the source version` -- both compare version strings, and between two
releases the version is unchanged by definition, so a clone any number of commits behind `main` is
indistinguishable from a current one. The sentence now names the refresh and says that no version check
can tell you otherwise between releases. **Detection is deliberately left alone**, with the reasoning in
the lens: comparing commits would report a gap on every consumer between cuts, where following the
releases is the intended contract.

**Score:** 3

### What makes this deploy extra special

N/A -- both halves are about how this repo consumes its own plugin. A consumer's clone following the
releases is the intended contract for them, and nothing in their workflow changes.

**Score:** N/A

### Pull Request

The plugin cache follows a marketplace refresh, not a push

[PR #852](https://github.com/DaveKJohn/claude-code-specialists/pull/852)

---

## DEPLOY: `feat/ship-pr-names-the-governing-check-v1` · 20260824-094425

`ship-pr` waits for every check a PR has, and used to say nothing about which one had held it up -- so the
only way to learn it was the Actions page, afterwards. That invisibility is how two observations, both out
of the tail, became a policy question about whether to wait on non-required checks at all. Measured over
n=100 paired runs the non-required check governs 23% of the time at a median cost of 0s, so the wait is
unchanged and the run now reports it: which check finished last, its own duration, whether the repo's
ruleset requires it, and how much later it finished than the last required check. It still names no check
of its own -- the ordering comes from the payload and 'required' from `gh pr checks --required` -- so it
says nothing about a consumer's CI that it cannot read there. Best-effort by design: an unreadable payload
costs one line of detail and can never turn a green run red.

**Score:** 3

### What makes this deploy extra special

Every consumer running `ship-pr` gets the same line, and for them it is worth more than it is here: they
have never had a figure for what their own merge wait is made of, and this is the one that produces it
without asking them to measure anything. It is also what has to exist before the bigger question --
whether to merge on the required check alone -- can be asked honestly, since that trade was declined
precisely because nobody could say yet whether the long reviews are the large diffs.

**Score:** 3

### Pull Request

ship-pr says which check governed the merge wait, and for how long

Plugins: workflow-davekjohn

[PR #850](https://github.com/DaveKJohn/claude-code-specialists/pull/850)

---

## DEPLOY: `docs/merge-wait-23-percent-n100-v1` · 20260824-092122

A measurement published in v4.18.0's release note said the tally was **two to one** for the non-required
check governing `ship-pr`'s merge wait. Over the population -- n=100 paired pull-request runs -- it is
**23 of 100**, and the median cost of that wait is **0s**. Both paragraphs now carry the population figure
and name the n=3 that produced the error, so a reader sees the sample size rather than only the corrected
number. The same claim was also sitting in a changelog entry that has not been cut yet; left alone it
would have reached the next release's documents as current, so it is marked superseded there too. The
copy attached to the GitHub Release is deliberately not swapped.

**Score:** 3

### What makes this deploy extra special

N/A -- the corrected figure is this repo's own CI timing. Nothing a subscriber of a service does changes
because of it.

**Score:** N/A

### Pull Request

The merge-wait figure is corrected to 23% over n=100

[PR #848](https://github.com/DaveKJohn/claude-code-specialists/pull/848)

---

## DEPLOY: `feat/open-questions-become-issues-v1` · 20260823-233212

A session that finds a bug, a stale doc or a decision that is not its own used to end by handing that
list back, so the owner had to answer everything before they could close a finished session and clear its
context. Every specialist now files those findings as issues in the repo being worked in and finishes the
assignment instead, naming what it parked. The rule reaches all 30 carriers, the four personas included,
which is the half that matters here: they are the ones who close a session out.

**Score:** 4

### What makes this deploy extra special

This changes what every consumer's specialists do at the end of a turn, in the direction the owner asked
for: fewer interruptions, nothing lost. It is deliberately gated on there being a repository and a
reachable tracker -- in a chat session with no checkout there is nothing to file to, and the rule says to
check that rather than assume it, and never to report an issue as filed where it could not be. It also
carries a bar, because a specialist that opens an issue per stray thought is worse than one that mentions
it in a sentence: search first, one subject each, say what was measured and what was inferred, and never
file instead of asking when the question genuinely blocks.

**Score:** 4

### Pull Request

Every specialist files the loose ends as issues instead of handing them back

Plugins: team-alpha, team-ecomm, team-lifehub, team-shopify

[PR #847](https://github.com/DaveKJohn/claude-code-specialists/pull/847)

---

## DEPLOY: `docs/trim-branch-doc-steps-guidance-v1` · 20260823-220025

Every branch document here was born carrying 40 lines of guidance the author had already read -- half the
file -- restating rules that live in three other places. It is a blockquote of 17 visible lines now, the
DEPLOY section carries no comment at all, and a fresh document is 35 lines instead of 87. The part that
matters for this repo is the DEPLOY section being spotless: it is the text that travels verbatim into
`CHANGELOG.md`, and every entry written from here on is read out of that file.

**Score:** 3

### What makes this deploy extra special

A consumer meets this on their next plugin update, on every branch they open, and it changes what the
document in front of them looks like -- so they notice without being told. Two things were deliberately
kept rather than swept: the rules with a silent failure mode (text below the Score line is discarded; a
relative link in the entry resolves from the repo root, which inbound #806 measured as a consumer merging
two dead links with every gate green) and the per-repo sentence naming who their audience tier is, which in
a tier-1 repo is the only line that names their reader anywhere.

**Score:** 3

### Pull Request

The branch document stops restating the rules it already links

Plugins: workflow-davekjohn

[PR #844](https://github.com/DaveKJohn/claude-code-specialists/pull/844)

---

## DEPLOY: `docs/verify-a-constraint-before-obeying-it-v1` · 20260823-214823

Twice in one session this repo's own tooling was treated as forbidden when it was not: a skill carrying
`disable-model-invocation` was read as a permission gate, and a branch sat waiting on a merge while
`worktree-lane.ps1` existed to build alongside it. Both are the same mistake -- a constraint assumed rather
than read -- and the rule that dissolves the first one was already written, in `new-branch/SKILL.md`, which
a session reads only by invoking that skill. The rule now sits in the shared block every specialist
carries, generalised past skills to any inferred limit.

**Score:** 4

### What makes this deploy extra special

Every consumer's specialists carry this block, and the flag it names is on 17 skills across the two
workflows -- so the reading that declines usable tooling is available in every repo that installs them, not
just here. The general form matters more than the example: a refusal arrives phrased as authority, while a
capability nobody looked for announces nothing at all, and only one of those two failures is visible
afterwards.

**Score:** 4

### Pull Request

A refusal is not policy: verify a constraint against the repo before it becomes a decision

Plugins: team-alpha, team-ecomm, team-lifehub, team-shopify

[PR #843](https://github.com/DaveKJohn/claude-code-specialists/pull/843)

---

## DEPLOY: `docs/exit-code-read-through-a-pipeline-v1` · 20260823-205818

Trap 6 landed here yesterday and was mis-read twice inside the same session that wrote it -- both times
by reading `$?` after piping a PowerShell run through `tail`, which reports the pipe's last command and
not the run. The second time it argued that a correct remedy was broken, which is the expensive shape:
the mis-read does not merely hide a failure, it manufactures one. Anyone here who judges a gate, a suite
or a probe from a shell is who repeats it, which in this repo is every chain run.

**Score:** 3

### What makes this deploy extra special

A consumer's system-administration specialist gets trap 6 through the plugin, so without this they
inherit the half about an exit code that lies and not the half about reading it through a pipe. It is a
clause rather than a new trap, though, landing in a bullet they may already have read -- a smaller thing
than either trap that shipped yesterday.

**Score:** 2

### Pull Request

The exit code you read is not the exit code you meant: trap 6 generalised to whoever is checking

Plugins: team-alpha

[PR #842](https://github.com/DaveKJohn/claude-code-specialists/pull/842)

---

## DEPLOY: `docs/powershell-trap-six-and-sed-escape-v1` · 20260823-203210

Both traps were measured here, in this repo's own tooling, during the PR #840 chain run: a background
probe of `Invoke-TestSuiteGate` that reported `GATE OK = ` and exit 0 against every suite in the repo
while the call inside had failed to resolve, and a `sed` substitution meant to write two dash escapes
into a `scripts/lib/` regex that instead wrote a wrong-but-ASCII literal past the very check (`[script-ascii]`)
that same run built to catch this class in the source. Anyone here who probes a gate as a background
command, or reaches for a non-PowerShell tool to repair a `.ps1` file, is exactly who repeats this.

**Score:** 4

### What makes this deploy extra special

This reaches every consumer's system-administration specialist: the portable manual travels through
the plugin cache, and the trap section is the one place that craft lives. Two of the seven traps are the
difference between believing a gate ran and knowing it did not, which is worth more than the ordinary
addition to a list. It stops short of a 4, though: a reader only meets either trap when they next write
their own probe or reach for a non-PowerShell substitution on a `.ps1` file — nothing about how they work
changes before that moment, and for most sessions that moment is not this week.

**Score:** 3

### Pull Request

A sixth PowerShell trap, and a seventh one step out in the repair tooling: the sed escape that mangles the ASCII repair

Plugins: team-alpha

[PR #841](https://github.com/DaveKJohn/claude-code-specialists/pull/841)

---

## DEPLOY: `feat/script-layer-ascii-gate-v1` · 20260823-184655

The rule that the script layer is ASCII now has a gate. `[script-ascii]` — check 27 in
[`check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1) — holds every `.ps1` in the tree
to it and reports the file, the line, the code point, and the `[char]0x..` form to write instead.
[`.claude/rules/language-layers.md`](.claude/rules/language-layers.md) has required that since
August 19, 2026, after a middot typed literally into `scripts/lib/entry-scaffold-lib.ps1` came out of
every generated changelog template as two wrong characters. Nothing enforced it, and the reason it
needed its own check rather than an extension of the mojibake one is where the two look: `[mojibake]`
walks markdown, so it sees the mangled character **downstream**, in the generated document, after it has
been copied into somebody's entry. This one sees the literal upstream, in the source that will emit it.

A BOM is deliberately **not** a finding. On a `.ps1` a BOM is what makes Windows PowerShell 5.1 read the
file correctly, so accusing it would push an author toward the very defect; check 26 owns the documents
where a BOM does break something, and it reads bytes precisely because this check reads text.

**Measuring the set found a second defect, in a check nobody was looking at.** The `.ps1` set check 5
parses held **151** of this repo's 158 tracked scripts, and the seven absentees were every
`plugins/<kind>/<plugin>/hooks/*.ps1` — so a parse error in a SessionStart hook, the five that speak at
every session start here among them, was not seen by the PR gate at all. A hook that does not parse does
not announce itself: the harness reports it and the session simply continues without whatever the hook
was there to say. The set is one cached definition now, read by both checks and widened to those hooks,
which repairs check 5 in the same edit — and the alternative, letting each check decide for itself what
the set is, is the second-definition drift this gate exists to catch elsewhere.

The check is **born green**, which cost one repair rather than an exemption list: the two literal en/em
dashes in `scripts/lib/pr-issues-lib.ps1`'s regexes — the only non-ASCII characters in all 158 files —
are composed from `[char]` code points now. `.claude/rules/language-layers.md` had named those two lines
as deliberately unrepaired under the no-pre-emptive-fixes rule, and that is not being overruled: the rule
says a risk that has not bitten is written down rather than built against, this one had bitten in the
middot, and what it forbade was sweeping the lines along with an *unrelated* change. The change that
enforces the rule they break is the related one. Repairing them also exposed a live test gap —
[`pr-issues.tests.ps1`](scripts/tests/pr-issues.tests.ps1) asserted the ASCII hyphen range and neither
typographic dash, so a composition producing the wrong two characters would have passed every existing
assert. It asserts both now.

**Score:** 3

### What makes this deploy extra special

Almost nothing, and the honest reason is where the gate lives. `check-plugin-integrity.ps1` is repo-owned
— a consumer names their own through `Get-LintScript` — so this check does not travel, and a consumer's
own script layer is not held to the ASCII rule by it. What does reach them is the shared mirror
`pr-issues-lib.ps1`, whose dash class is composed rather than typed: identical behaviour, now covered by
two dash asserts it did not have, so nothing to run and nothing to migrate. Worth one line rather than
none because the *failure* is theirs too — a literal typographic character in any `.ps1` they write is
decoded by Windows PowerShell 5.1 as two CP1252 characters, silently, and reaches whatever that script
emits.

**Score:** 1

### Pull Request

A lint check holds the script layer to ASCII

Plugins: workflow-davekjohn

[PR #840](https://github.com/DaveKJohn/claude-code-specialists/pull/840)

---

## DEPLOY: `docs/probe-and-recency-lessons-v1` · 20260823-175516

Two rules learned while making the development cycle branch-lifetime, written into the layer that travels.

Sylvester's manual gains a fifth PowerShell trap: **a failed `Set-Location` does not stop the block that
follows it.** It writes a non-terminating error, execution continues in the directory you were already
standing in, and every later command succeeds against the wrong tree while its output reads exactly as it
would have been right. Measured here, expensively: a probe whose fixture path contained `$PID` — a value
that differs between processes — ran a fold against this repository instead of its fixture, deleting a
tracked file and committing. The remedy is that a throwaway probe fails closed, and it generalises past
`cd`: a probe pointed at the wrong target is indistinguishable from one that worked, so what has to be
verified first is the aim rather than the result.

The shared `repo-way-of-working` block, carried by 30 agent defs and personas across all four teams, gains
a second bullet: **how recently something was decided is not an argument against changing it.** Its
existing bullet already ends on "proposing a different way of working is something you do when you are
asked for it"; this is what to do when the owner does ask. Argue from mechanism, read whether the original
reasoning still holds, name the part that has expired — and do not treat an owner changing their mind as
something to be talked out of.

**Score:** 2

### What makes this deploy extra special

Every consumer's agents get the second rule, since it ships in a block all four teams carry. It changes
how a specialist argues rather than what any script does, so nothing to run and nothing to migrate — but a
consumer who has noticed their specialists pushing back on reversals will find that stops.

**Score:** 2

### Pull Request

Two lessons: a probe that fails closed, and the age of a decision

Plugins: team-alpha, team-ecomm, team-lifehub, team-shopify

[PR #839](https://github.com/DaveKJohn/claude-code-specialists/pull/839)

---

## DEPLOY: `feat/cycle-file-branch-lifetime-v1` · 20260823-165431

The branch's own document now exists only while a branch is open. `new-branch` creates it, the fold
**removes** it instead of rewriting it to an empty state, and between branches the trunk carries no copy at
all — so `workflow-davekjohn/` holds its three pages and its two directories and nothing else. What the
empty copy was really for, letting a reader see the whole form at once, moves to
`plugins/workflows/workflow-davekjohn/DEVELOPMENT-CYCLE-portable.md`, which reaches a consumer with every
plugin update rather than being scaffolded once and frozen.

Three things follow. `adopt-workflow-folder` places one file fewer, so a consumer is no longer handed a
document their own first fold deletes. `Format-DevelopmentCycleReset` is retired — an alias with no writer
left — while the state it produced is still recognised, because a branch cut before today is carrying one.
And `check-plugin-integrity`'s `[branch-template]` check is inverted: it held the trunk copy to the
formatter byte-for-byte, and now asserts that no document declaring the trunk survives a fold anywhere in
the tree, which also catches the leftover a consumer updating from an older plugin has until their next
fold clears it.

`Resolve-BranchFilePath` deliberately keeps its declared-branch test rather than reverting to the plain
existence test that is now available again. Every branch cut before this change is carrying the trunk's old
empty copy beside its real work, here and in every consumer, and existence alone would hand each of them
the empty document. That simplification is available on the day those branches are gone, and not before.

**Score:** 3

### What makes this deploy extra special

A consumer's fold changes behaviour without them choosing it, and their trunk loses a file that has been
there since they adopted the folder. Nothing breaks and no migration is needed — the stale empty copy their
last fold wrote is removed by their next one — but the folder they read to learn the convention looks
different the first time they open it after the update, which is worth knowing before it surprises them.

**Score:** 3

### Pull Request

The development cycle exists only while a branch is open

Plugins: workflow-davekjohn

[PR #838](https://github.com/DaveKJohn/claude-code-specialists/pull/838)

---

## DEPLOY: `docs/development-cycle-answers-v1` · 20260823-150916

`workflow-davekjohn/CONTRIBUTING.md` now states what this repo's answers make of the development cycle,
which nothing did. The merge that retired `branch/README.md` claimed its answers had moved into this
folder's two pages; only the **file rules** actually arrived, in `CLAUDE.md`. The **seam answers** — the
ones that decide what a contributor here sees in the document — went nowhere, and the seam table did not
even list `Get-ReleaseAudienceTier`, the single most consequential answer for the entry's shape.

The new section says three things a reader cannot derive from the portable half: that the audience tier
is `2`, so the entry asks two questions and both sit at the section level while a repo answering nothing
gets the `#### Tier N` fallback instead; that `new-branch` completes a `-v1` and a bump is typed rather
than guessed; and that the lint holds the document's shape here in three ways a consumer's repo cannot,
which is also why the guidance lives inside the document rather than beside it.

**And the split-entry rule was refusing this repo's own changelog.** Tier 0 lost its heading in that
merge, so an entry's first named section is now `What makes this deploy extra special` — and the gate,
which asks whether an entry starts at its first section, read the freshly folded entry as one that had
been cut in two by a stray heading. That is the **fourth** time a change to the entry's headings has made
correct entries read as split, and the first that was a level move rather than a rename: the three
repairs already recorded above that check all key on names. Found by running the lint on `main` straight
after the fold, which is the only moment it could have been seen.

**Score:** 3

### What makes this deploy extra special

Nothing here reaches a subscriber of the service. The repaired page is this repo's own answer sheet, and
the lint that was refusing its changelog runs nowhere else — the plugin ships no `scripts/lint/`. The one
part that does travel, the entry's heading shape, was already correct in the payload; what was wrong was
this repo's gate reading it.

**Score:** N/A

### Pull Request

The development cycle's repo answers land in CONTRIBUTING.md

[PR #837](https://github.com/DaveKJohn/claude-code-specialists/pull/837)

---

## DEPLOY: `feat/development-cycle-v1` · 20260823-145052

A branch carries one document again. `workflow-davekjohn/branch/` is gone, and everything a branch needs
is `workflow-davekjohn/development-cycle.md`: `## PLAN` / `## CREATE` / `## TEST` carry the steps, and the
fourth phase, `` ## DEPLOY: `<branch>` ``, **is** the changelog entry that folds into `CHANGELOG.md` at the
merge.

**The split was right about the problem and wrong about the shape.** One file used to do both jobs and
shipped three of v3.2.0's twenty-one entries with a to-do heading still in them; two files fixed that and
meant the plan a branch is working through and the claim it will make were never on one screen. What makes
the merge safe is that the separation is now **structural** rather than a written instruction: the entry is
a named section with the branch in its heading, so
[`Split-DevelopmentCycle`](scripts/lib/entry-scaffold-lib.ps1) is the one place that finds the boundary —
the fold takes that section, the step gate counts only above it, and the scaffold gate reads only inside
it. Nothing does two jobs at once, so nothing has to be replaced before the PR.

Three things came along because the merge forced them, and each is the kind of change that fails silently
if it is got wrong:

- **The reset test is the branch NAME, not the heading level.** Two files could open with an `#` while
  empty and an `##` once written; one document cannot, because its `#` is its title in both states. So
  `Test-BranchChangelogIsFilled` reads the name — the trunk's means nothing pending — which is also what
  makes folding twice impossible.
- **`Resolve-BranchFilePath` resolves on content, not existence.** Every rename before this one could use
  `Test-Path`, because the new name did not exist until something wrote it. This one lands on the trunk in
  its reset state, so every branch in flight *has* the new file, empty, beside the pair holding its real
  work. Resolving on existence would have handed those branches an empty document and called their entry
  missing — the stranded half-finished branch the dual-read exists to prevent.
- **The tier sub-heading level depends on the shape being written.** In the named shape tier 0 has no
  heading and the audience tier is the entry's first inner heading, at `###`. In the numbered shape the
  tiers are sub-sections *of* the entry's opening question and must stay at `####`. Measured: a fixture
  stating no audience tier went from four scaffold findings to five, the fifth being the opening question
  its own tiers had just orphaned. So a repo that has stated no audience tier gets the document it had
  yesterday, byte for byte.

**And the guidance came back into the file, which is what let `branch/templates/` go.** Inbound
[#810](https://github.com/DaveKJohn/claude-code-specialists/issues/810) measured what the bare working file
cost — an author met the form in the neighbouring file or not at all — and the fold already stripped HTML
comments, so nothing had to be built for it. The reference and the file you write in are the same page now,
and the copy on the trunk is what the lint holds to the formatter.

**Score:** 5

### What makes this deploy extra special

Anyone running this workflow works in one file instead of two, and the difference lands the first time
they open a branch: the plan they are working through and the paragraph they have to write are on one
screen. The reference copy beside it is gone and nothing is poorer for it — the guidance is in the document,
which is where inbound #810 said it should have been.

Two changes are visible without being asked for. A branch name now ends in `-v1`, completed by
`new-branch` rather than demanded, so a second cycle on the same subject is a deliberately typed `-v2`
instead of a name arguing about whether it is final. And a branch already open keeps working: the resolver
reads whichever file names your branch, so a plugin update mid-branch strands nothing and there is no
migration to run.

**Score:** 4

### Pull Request

The branch folder becomes one development cycle

Plugins: team-shopify, workflow-davekjohn

[PR #836](https://github.com/DaveKJohn/claude-code-specialists/pull/836)

---

## `docs/release-notes-on-main` deployment

### What does the change on this branch deploy to main?

A release cut now runs in one place from end to end. The hand-written release documents — the
audience note the cut drafts, and the internal note where a repo still runs the two-document flow —
are committed straight onto `main` in the commit after the tag, instead of travelling a branch + PR.
That makes a **third** named direct-on-`main` exception beside the fold commit and the release
commit, and the three read as one procedure: fold the changelog, bump the version, write the release
notes.

It is bounded the way the other two are, because that is the only thing that keeps an exception safe:
the hand-written documents of a cut that was actually asked for, named in the commit, and nothing
else in the tree. Outside a cut there is nothing for it to be part of.

This reverses the August 4, 2026 answer, which sent those documents through the reviewed route. The
argument that answer rested on — an exception is only safe while it stays the size it was granted at
— is not overturned; it is why the new bound is spelled out rather than assumed. What changed is the
judgement about which size is right: running one procedure across two routes left the trunk carrying
a tagged release whose own notes were still in review.

**Score:** 4

#### What makes this change extra special

Anyone running this workflow gets a shorter, single-track release. What used to be a cut, a branch, a
PR, a CI wait and a merge is now a cut and a second commit — and the step-zero timing instruction
loses two of the legs it could not measure. Nothing already published changes, and the tag still
holds the draft exactly as before, so there is no action to take: the next cut simply commits where
it used to open a PR.

**Score:** 3

### Pull Request · 20260823-105514

The written release notes land directly on main

Plugins: workflow-davekjohn

[PR #835](https://github.com/DaveKJohn/claude-code-specialists/pull/835)

---

## `feat/worktree-lane` deployment

### What does the change on this branch deploy to main?

A new shared script, `worktree-lane.ps1`, opens a branch in its own git worktree -- a "lane" -- so one
branch can be **built** while another one **ships**, and hands the lane's branch back to the primary
checkout when it is ready. It is the answer to a measured cost: `ship-pr.ps1` blocks on
`gh pr checks --watch`, whose median is **8m 01s** over the 65 most recent blocking CI runs, and at 73
merged PRs in seven days that is **9h 45m per week** in which the session that opened the PR can do
nothing else. Lanes convert that from blocking to non-blocking without touching a gate and without
proving any less.

The direction matters and is the opposite of the obvious one: **the worktree is where you build, the
primary checkout is where you ship.** Shipping from a worktree cannot work -- git refuses one branch in
two worktrees, and that refusal lands *after* the merge, in the one gap where the PR is merged, the entry
is unfolded, and every gate stays green until a release trips over it.

`new-branch.ps1` gains a `-RepoRoot` parameter, on the precedent `fold-changelog-entry.ps1` has carried
since #101, so a lane's branch and both of its branch-dossier files come into being inside the lane
rather than in the primary. A new 35-assert suite covers both ends, including the guarantee that opening
a lane never moves the primary's HEAD -- the one property whose failure would break the thing the script
exists to protect.

**Score:** 4

#### What makes this change extra special

Three of the findings in it came from running the thing rather than from reading it, and two of them
contradicted the plan they were testing. The first design pointed `CLAUDE_PROJECT_DIR` at the lane, which
the source-repo guard refused -- correctly, because that variable answers *which repo the session is on*
and not *which tree this call writes to*; that is what produced the `-RepoRoot` parameter instead of a
workaround. The first hand-back then failed with `Permission denied`, because on Windows the process's own
working directory holds the lane open, and standing in the lane is the normal case rather than an edge
one. And the message that failure printed -- "nothing was changed" -- turned out to be **false**: git had
already emptied the tree and deregistered the worktree, so `git worktree remove` is not atomic and the
script now asks git what it thinks instead of inferring from an exit code.

The alternative repair is recorded as declined rather than unconsidered: a one-line change to
`ship-pr.ps1` would remove the two commands a hand-back costs, and was measured as saving nothing in
wall-clock while changing the single line that produces the state nothing reports.

**Score:** 3

### Pull Request · 20260823-100851

A branch can be built in its own worktree while another ships

Plugins: workflow-davekjohn

[PR #834](https://github.com/DaveKJohn/claude-code-specialists/pull/834)

---

## `docs/lens-inbound-to-skill` deployment

### What does the change on this branch deploy to main?

Chris's repo lens stops carrying the evidence for its own rule in every session. The five inbound
failure-pattern case studies — #469 repaired inside the morning it was filed, #456's expired
reasoning, #566's `Resolve-PluginScript` that never existed, #660's `pair-cli` that named nothing,
and the four of 22 own reports whose counts were wrong — move verbatim into a new
`.claude/skills/triage-inbound/` skill. The rule stays always-loaded; the measurements are now one
invocation away, read when an inbound item is actually being triaged.

Measured rather than projected, because the projection was wrong: the lens drops 25,689 B -> 18,056 B
(-7,633 B, ~1,908 est. tokens) and the skill costs 126 est. tokens back as a resident description, so
the net is **~1,782 est. tokens per session** -- 10% of the 18.6k always-loaded chain. The first estimate
said ~2,255, counting the 94 removed lines but not the 15-line bullet that replaced them. Corrected here
rather than repaired to, which is what this repo asks of a recount that changes the number.

This follows the convention `CLAUDE.md` already records — skills carry the evidence behind a
procedure, personas and manuals carry no repo-specific detail — so it is that rule being applied to
the one always-loaded file that had not yet been, rather than a new idea about where things go.

**Score:** 3

#### What makes this change extra special

N/A — the change is entirely repo-local under `.claude/`. No plugin payload moves, so no consuming
repo and no subscriber of the specialists system receives anything from it.

**Score:** N/A

### Pull Request · 20260822-133906

Move the inbound-triage evidence out of the always-loaded lens into a skill

[PR #833](https://github.com/DaveKJohn/claude-code-specialists/pull/833)

---

## `feat/measure-skill` deployment

### What does the change on this branch deploy to main?

A new `measure-skill` skill in `workflow-davekjohn`, which prices what a skill costs and times the
script behind it. Two passes: **cost** (always-on and on-invoke tokens per skill, ranked, with the
delta against a committed baseline) and **speed** (wall-clock of the script a skill drives, `n` runs,
min/median/max, machine state stated).

It drives `claude plugin details` -- the `count_tokens` API -- rather than estimating from file sizes,
so the figure it reports is the authoritative one and not a second, disagreeing estimate. It checks no
correctness: frontmatter, dead links and parameter coverage stay `check-plugin-integrity.ps1`'s, and
duplicating one of its 26 checks here would put two verdicts on one subject. It is not a gate and the
page says why: `lint-en-tests` already blocks every merge for a median of 7m 23s, and a skill's cost
changes on the scale of releases rather than commits.

**Why now, measured rather than assumed.** 24 skills across four plugins had never been measured on
cost, speed or effect. Seven skill descriptions cost ~1,245 tokens at `v2.10.0`; 18 across the two
plugins enabled here cost **~3,650** at `v4.17.0` -- nearly 3x, never re-measured in between. And the
first run found something no estimate would have: `workflow-davekjohn`'s **entire** always-on cost is
its 14 skill descriptions, within rounding. The committed baseline is what makes the next growth
visible instead of discovered.

**Pass 2 will not run a script that has no declared read-only mode, and that is the whole safety
model.** Timing the script behind `cut-release` by invoking it would cut a release. So a script is
timed only where its own registration carries a `MeasureArgs` key naming a harmless invocation --
declared beside the registration rather than in a list inside the measuring script, because a second
hand-written list is one a newly shared script falls out of silently. Two scripts qualify today;
everything else is reported as not measured, by name, with the reason. A test pins `cut-release` as
never declarable.

**Pass 3 -- whether a skill actually earns its tokens -- is designed and deliberately not built.**
`claude plugin eval` already carries the engine, including a `--ablation with-without` arm that scores
the same cases with the plugin removed. The four flags this repo would need are recorded on the skill
page so the first person to wire it up does not rediscover them, `--no-publish` among them: the report
otherwise goes to claude.ai, which is not a side effect a measurement gets to have.

Three defects were found by running it rather than by reading it, and each is written up where it
happened: figures formatted on a Dutch machine rendered 13,700 as `13.700` (a factor of a thousand to
an English reader, and the mirror image of the parse trap the tolerance guards); `-UpdateBaseline`
reduced an 18-skill baseline to 4 and reported success, because a scoped run replaced the file instead
of merging into it; and an `if` expression returning `@()` unrolled to `$null`, so "declared safe with
no arguments" read as "not declared" and was silently skipped.

**Score:** 3

#### What makes this change extra special

A consumer gains a skill that answers "what is this plugin costing my sessions, and which skills carry
it?" -- and pass 1 works there, since it needs nothing but the `claude` CLI. Pass 2 needs the
shared-scripts registry and reports `[SKIP]` with the reason where there is none, so the boundary is
stated rather than met as a failure. Nothing existing changes behaviour: one skill and one script are
added, and the only edit to a shared file is an optional registry key that is absent everywhere it was
not declared.

**Score:** 3

### Pull Request · 20260822-122834

Measure a skill's token cost and speed

Plugins: workflow-davekjohn

[PR #832](https://github.com/DaveKJohn/claude-code-specialists/pull/832)

---

## `docs/redeploy-verify-past-the-cache` deployment

### What does the change on this branch deploy to main?

The redeploy verification step gains the failure mode it did not have: **a fetch seconds after a good deploy
can be a cached 200 with the old body**, which is indistinguishable from the silent-inactive-version failure
the step was written to catch.

**Measured on the `v4.18.0` redeploy, August 21, 2026, doing exactly what the skill says.** `npx wrangler
deploy` reported success and printed a version id. The first fetch of the worker URL answered **HTTP 200
with 265,415 bytes** -- against the 352,146 just built -- carrying none of the new release's rows and none
of the new template's `Version X.Y` labels, so it was not merely the previous release's page but a build
from before the template's second pass. A second request with `Cache-Control: no-cache` and a throwaway
query string returned **352,146 bytes, byte-identical to the built file**, and three subsequent plain
fetches agreed. Nothing had been wrong with the deploy at any point.

**Why this is worth writing down rather than shrugging at.** The paragraph above it tells a reader to
verify against the served bytes precisely because a deploy can report success while the live page stays
old -- so the observation *"200, old body"* already has a documented meaning, and it is the wrong one here.
A reader following the page in good faith concludes the documented failure has just happened. The cheap
next step is a second deploy; the expensive one is `-InitToken`, on the theory that the route is wrong,
which is the one action the skill spends a whole section warning never to take casually, because a new
token 404s every link already sent. So an unqualified check pointed at the most destructive available
remedy.

Both halves of the fix, because they reach different moments:

- **[the `release-notes-page` skill](plugins/workflows/workflow-davekjohn/skills/release-notes-page/SKILL.md)**
  gains the measurement and the ordering rule: fetch, and if the bytes are stale fetch again cache-busted
  *before* believing it, comparing against the built file with `cmp` rather than by eye -- a size that
  merely looks plausible is how a half-updated page passes.
- **the build script's own closing advice**, in both mirrors, since that is the line somebody actually reads
  at the moment they deploy rather than the page they read once. It now says to fetch twice and why. Held
  byte-identical by the shared-script drift lint, and ASCII, per the script layer's rule.

**What is deliberately NOT done.** No retry or cache-busting logic is added to any script: the script does
not deploy and does not fetch, and giving it either would make it the thing that verifies its own
publication. And no claim is made about *which* cache answered -- edge, intermediary or local -- because
one observation cannot tell them apart and the remedy is the same either way.

**Score:** 3

#### What makes this change extra special

Every consumer who hosts this page meets this on their first redeploy, and the skill had walked them into
reading a success as the one failure it documents. The asymmetry is what makes it worth a 3 rather than a 1:
the false negative is cheap to disprove -- one more request -- while the action it invites is the single
irreversible one in this whole surface, since a regenerated path token silently breaks every link already
sent to management or a commissioner. A check that points at that remedy on a false reading is worse than
no check.

The transferable half is the sentence rather than the mechanism: **a stale read and a failed publish are
indistinguishable from one request**, so any instruction to "verify against what the URL serves" owes its
reader a second read. That generalises past this worker to anything fronted by a cache, which is most
things somebody is told to go and look at.

**Score:** 3

### Pull Request · 20260822-003327

The redeploy check says to fetch twice, because the first fetch can be a cached miss

Plugins: workflow-davekjohn

[PR #830](https://github.com/DaveKJohn/claude-code-specialists/pull/830)

---

## `docs/v4-18-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.18.0 release
document froze at **43m 55s** because three of its legs were still running on the file it was written into --
its own local gates, its CI and merge, and the publish. Those legs now have clock readings, so the total goes
in: **63m 33s** end to end, 19:09:35 to the Release published at 20:13:08, with the note's local gates and
push **4m 37s**, its CI and merge **14m 19s**, and the fold plus publish **42s**.

**Two of this release's readings invert what the previous six supported, and both are stated as mechanisms
rather than as numbers.**

- **The head is 58% of the release** -- 36m 37s of 63m 33s to the tag being pushed -- against 18% at v4.17.0
  and 21% to 32% across v4.12.0 through v4.16.0. Every earlier reading said most of a release happens after
  the version number exists. The reason this one says the opposite is that **a blocked cut moves work into the
  head**: the cut refused on a red test gate, and the 31m 50s of diagnosing and shipping that unrelated repair
  all fell before the tag, because nothing downstream could start until it merged. So the head/tail split
  measures where the obstacles were rather than where the effort inherently is.
- **The unmeasurable share is 31%**, against 65% at v4.17.0, 66% at v4.4.0 and 70% at v4.16.0. Same cause
  read from the other end: the tail a document cannot time about itself is roughly constant per release, so it
  looks small here only because the head was abnormally large.

**And the total is nearly double the previous longest for a reason that is not its size.** 24m 34s for
v4.15.0's thirteen entries, 25m 29s for v4.16.0's four, 32m 19s for v4.17.0's nine, 63m 33s for this one's
fifteen. The spread has never tracked the entry count and still does not. What made this release expensive is
that it needed **two** pull requests where a release normally needs one -- a repair before the cut, then the
note -- and therefore two full CI cycles. CI is the largest single cost in here at **23m 12s**, or **37%** of
the release.

**The first pass's reading about which check governs the merge is CORRECTED here rather than confirmed**, which
is the part of this branch worth more than the total. That pass had one data point -- the repair's pull request,
where the required `lint-en-tests` took 8m 37s against `claude-review`'s 3m 02s -- and concluded the ordering
had reversed from v4.17.0. This note's own pull request says the opposite: `claude-review` **14m 05s** against
`lint-en-tests`'s **9m 58s**. Across three readings that made the tally **two to one** for the non-required
check governing the wait, so the direction of the evidence looked like v4.17.0's after all, and the even split
the first pass implied was an artefact of measuring once. The unstable quantity turns out to be
`claude-review`'s own duration -- 3m 02s and 14m 05s on two pull requests forty minutes apart -- rather than the
ordering, which is a different question from the one that was being asked. **That tally is itself superseded**:
over n=100 the non-required check governs the wait **23%** of the time, not 67%, and the correction landed on
`docs/merge-wait-23-percent-n100-v1`
([#831](https://github.com/DaveKJohn/claude-code-specialists/issues/831)).

The note's open section also gains the standing line that the attachment carries the frozen subtotal only and
is deliberately not swapped -- extended this time to say that the same second pass corrected a reading, so a
reader holding the attachment knows there are two reasons to prefer the page.

**Score:** 2

#### What makes this change extra special

It puts a fourth consecutive end-to-end measurement beside the first three, and this one is the first that
**breaks** the pattern the other three built rather than adding to it. A reader who saw only the four totals
would conclude that releases are getting slower as they get bigger; the measurement says the opposite, and
names the mechanism -- one blocked cut, two CI cycles instead of one.

For a consumer running this workflow the transferable part is a diagnostic they can apply without any of these
numbers: **when a release runs long, check whether it shipped one pull request or two before assuming the work
grew.** A release that had to repair something before it could cut pays for a whole extra CI cycle, and that
cost lands in the head, where the earlier readings had taught everyone not to look.

The correction is worth its own line for the same reason the first pass was: a timing is a count, and this one
was taken once. Publishing an even split off a single pull request and then finding the opposite on the next
one is precisely the recount discipline the house rules ask for, applied to a figure written an hour earlier by
the same hand.

**Score:** 2

### Pull Request · 20260821-223214

The v4.18.0 release note gains its end-to-end total

[PR #829](https://github.com/DaveKJohn/claude-code-specialists/pull/829)

---

## `docs/v4-18-0-release-note` deployment

### What does the change on this branch deploy to main?

The hand-written release document for v4.18.0. The cut drafts it from the tier-2 entries in the words their
authors wrote for a diff reviewer and commits it inside the tagged release commit; this is the rewrite for
somebody deciding whether to update, held against the seven tests in the `cut-release` skill. **1,100 draft
lines became 304**, which is the largest reduction this document has had to make -- v3.2.0's was 1,098 to 153,
but that draft still carried every category, and this one is fifteen tier-2 entries with nothing to discard.

**The ordering decision is the whole of the editorial work here, and it is a merge rather than a sort.** Four
of the fifteen entries are repairs to the same script -- the `team-shopify` pre-task sync -- filed and fixed
separately, scored 5, 5, 4 and 4. For a reader they are not four items: they are one script, one update, and
one dry run. So they open the page as a single section with the four repairs listed inside it, ordered by which
bites first, and the section says plainly that it is the one item in the release with a deadline. Presenting
them as four sections would have been faithful to the entry set and wrong for the reader, who would have had
to work out that all four resolve to the same command.

The remaining eleven are ordered by whether they carry an action, and the two that change what a consumer's own
tooling **refuses** are placed above the ones that only add a capability -- a cut that stops working and a push
that stops working are the two things somebody meets without asking for them. Three carry no action at all and
say so under their own heading rather than leaving it to be inferred (test 4).

Every mechanism the page tells a reader to invoke was read in the tree rather than carried over from an entry
body: `sync-main.ps1`'s `-DryRun` and the retired `-SkipPull`, `push-preview.ps1`'s four-step resolution,
`cut-release.ps1`'s `-Type`, `prune-merged.ps1`'s two proofs, and `Get-ShopifyPreviewUrls` being optional while
`Get-ShopifyLiveThemeId` is recommended here and required for the sync. That check is why the preview section
states the asymmetry between the two seams instead of repeating the sync's requirement.

Both organisational sections are written. *What it is worth* leads on the signature the four sync repairs share
-- no error, no warning, a green run -- and on the zero-false-positive/ten-of-eleven measurement that chose a
redesign over a fifth flag. *What was still open* is a snapshot with every figure read at its source: the
publication target at `84e6316` with all four team plugins at 4.16.0, now two releases behind, and all four
registered consumers one release behind as of this cut, read from `check-connectors.ps1` rather than from a
document.

**Score:** 2

#### What makes this change extra special

It is the one document a consumer reads to decide whether to update, and it reaches every one of them as an
attachment on this release's GitHub Release.

The item that earns the top of the page is the one where doing nothing is invisible until it has already
happened. Both Shopify consumers are running a sync measured to revert merged work, and one of them carries a
temporary hook routing its own sessions away from the shipped skill -- a workaround whose stated removal
condition is this release. The page gives them the three commands in the order that makes the dry run useful,
names what the sync now refuses to do at all, and says which flag is gone, so converging onto it does not read
as handing a script more authority than it has.

This page also carries the first timing pass, and this release's reading is unusual enough to be worth the
line: **73%** of the run went on a red test gate that had nothing to do with the release. That is the number a
later reader would otherwise have to reconstruct, and it is the kind that only exists if somebody starts the
clock before the first command.

**Score:** 3

### Pull Request · 20260821-221226

The v4.18.0 release note

[PR #828](https://github.com/DaveKJohn/claude-code-specialists/pull/828)

---

