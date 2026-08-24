# `development-cycle.md` — the portable half

Everything a branch needs to carry lives in **one file**: `workflow-davekjohn/development-cycle.md`,
inside the workflow's own root folder, where everything portable gathers. It has two halves with two
different readers, and they are sections of one document rather than two files:

| half | subject | who reads it | lifetime |
|---|---|---|---|
| `## PLAN` · `## CREATE` · `## TEST` | what still **must happen** | whoever is working on the branch | removed at the merge; never folded |
| ``## DEPLOY: `<branch>` `` | what the change **does** | whoever reads `CHANGELOG.md` later | folded at the merge, then removed with the rest |

It is written by the shared
[`scripts/task/new-branch.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/task/new-branch.ps1)
at the moment the branch is created. You do not create it by hand, and you do not delete it.

**How to read this page.** It travels with the plugin, so two conventions keep it true in every tree it
lands in — the same two `RELEASES-portable.md` states for itself. *This repo* always names the **source
repo** the page was written in
([claude-code-specialists](https://github.com/DaveKJohn/claude-code-specialists)) — its measurements travel
as the evidence behind the rules, never as your repo's own record. And links into the source's script tree
are **absolute** on purpose; the file every adopting repo has of its own is named in code rather than
linked, because the copy that matters is yours.

**There is no template beside it, and there is nothing missing.** Until August 23, 2026 the two files this
replaces were scaffolded **bare** — headings and nothing else — with a reference copy under
`branch/templates/` carrying an HTML comment over every field saying what a good answer looks like. Inbound
[#810](https://github.com/DaveKJohn/claude-code-specialists/issues/810) is what that arrangement cost: an
author met the guidance in the neighbouring file or not at all, and wrote two pages of prose under a heading
whose own hint said the short answer was the normal one. **The guidance is in the document now**, and the
fold strips HTML comments on the way to `CHANGELOG.md` — so leaving a block standing is not a defect, and
nobody has to remember to delete one.

**Which makes this page the reference.** The document exists only while a branch is open — `new-branch`
creates it, the fold removes it at the merge — so on the trunk there is no copy to open and read. Until
August 23, 2026 there was: the file was rewritten to an empty state and that copy was what you looked at to
see the whole form at once. It is this page that carries that now, and the swap is deliberate rather than a
loss. A file scaffolded into your repo is written once and never again, so it cannot be improved after you
adopt it; this page reaches you with every plugin update.

## The heading

```markdown
# Development cycle: `feat/thing-v1` · 20260823-101500
```

The **title comes first, then a colon, then the branch** (Dave, August 23, 2026). Both this heading and the
DEPLOY heading below follow that shape; they read `` # `feat/thing` cycle `` until then, branch first and
title trailing. What the flip buys is the scanned line: both are met at a glance in a diff, a search result
or `CHANGELOG.md`, and leading with the title means the two announce themselves in the same place every
time while the branch reads as the subject rather than as a label.

The suffix is the **creation stamp** — the moment this branch began, in the document that begins and ends
with it.

**The branch name in the heading is machine-read.** It is how the fold finds the PR to look up, and how
`new-branch` decides whether this document is already somebody's: any name other than the trunk's is a
branch's work and is not written over. A heading naming the **trunk** is the empty state and may be
overwritten — that state is no longer produced, since the fold removes the document rather than emptying
it, but a repo updating from an older plugin has one on its trunk until its next fold clears it, so it is
still recognised. Every shape the heading has ever had is read; only today's is written.

### The version suffix

A branch name ends in **`-v<N>`**, and a second development cycle on the same subject keeps the name and
bumps the number — `feat/thing-v1`, then `feat/thing-v2`. `new-branch` **completes** a name that has none
by appending `-v1`; give it an explicit `-vN` and it is left exactly as typed.

**It appends `-v1` and nothing else — it does not look for the lowest free number**, and that restraint is
the design rather than a shortcut. `new-branch` is idempotent: running it again on the same subject
*resumes* that branch, which is what makes it safe to reach for twice and what the `-Park` flow needs. A
version scan would turn every rerun into a new branch — measured on the first draft, where the second run
landed on `-v2` and the assert that HEAD had not moved failed. **So a bump is a decision you state by
typing `-v2`**, which is also exactly how the rule was given.

**Why a completion and not a refusal in the name validator.** Two reasons. `branch-info.ps1` is
**repo-owned** and does not travel, so enforcing there states the rule to one repo while `new-branch` is
the shared script every consumer runs. And a hard refusal breaks every branch in flight: they have no
suffix right now, and they meet this convention through a plugin update rather than by choosing to.

**The completion runs after the name is validated**, not before — otherwise `-Name main` becomes
`main-v1` and every hard reject waves it through. Measured on the first draft, by the scaffolder's own
suite.

**It is the same rule `final` was already refused for.** A branch named for being the last word on
something is a prediction, and the prediction is wrong often enough that the next round has to be called
`final-2`. A number makes no claim about being the last one.

## The step list: PLAN, CREATE, TEST

The plan is yours. It is never folded and never travels, so it may hold whatever helps you pick the branch
back up — notes, links, a scratch list. What scripts read out of it is the **step marks**, wherever they
stand.

`new-branch` scaffolds **one open step**, so the gate below has something to refuse.

### The four phases, and why one of them takes no steps

The document is scaffolded with **PLAN**, **CREATE** and **TEST** as headings, and **DEPLOY** is the fourth
phase — written by the formatter that owns what goes in it, because that section *is* the changelog entry.
So a branch moves through a recognisable arc instead of an ad-hoc list. The gate reads step marks only, so a
heading of any level is invisible to it and the arc is drawn on top of the mechanism without touching it.
**A phase with nothing under it is not a finding**: a branch that had nothing to test says so by leaving
that heading bare, exactly as a branch with no step list at all is permitted.

**But an empty phase is a statement, and on a branch whose work *was* judgement that statement is
false.** Verifying a report, choosing between two designs, establishing that a claim still holds —
none of it produces an artefact until the writing starts, so the arc offers it no home and the path of
least resistance is to record only the writing, which is the least interesting half. **Those are PLAN
steps**, written like any other: `- [x] Verify the claim still stands: <what you read, and what it
said>`. A branch whose PLAN is empty because nobody wrote the plan down reads exactly like one that
arrived needing no plan, and no gate can tell those apart — which is why this is a convention for
whoever is writing rather than a check on them.

**And TEST answers with a reason rather than with nothing.** Where no automated test was added, `- [~]`
is what says so: *no suite, and here is why* — the existing gates already cover it, the surface does not
lend itself to one, the change is prose. Leaving the heading bare stays permitted and stays no finding;
it is simply the weaker of the two answers wherever there **was** a reason, and the reason is the half a
later reader can use. Raised in the source repo as
[#846](https://github.com/DaveKJohn/claude-code-specialists/issues/846), on a branch whose defining work
was deciding two open questions and verifying seven reported claims against the tree, and whose PLAN and
TEST were both empty.

**TEST is where the branch verifies ITSELF, and that is the phase's whole job.** Give Claude a check it
can run — a suite, a gate, a build, a rendered result to compare — and the session changes character: it
becomes one you can walk away from instead of one you have to watch. The development cycle names *when* and
*where* that happens, because a check with no place in the arc gets run when someone remembers to. **A
branch reaches DEPLOY once it has verified itself here**, and TEST is the phase that says what was run and
what came back.

**So `- [~]` means "no SUITE", never "no verification".** Those are two different sentences and only the
first one is ever true of a finished branch. A dropped step still names the check that *was* run and what
it reported — *"no suite: the lint gate and 36 existing suites cover this, all green"* — because that is
what a later reader, and any evaluator judging whether this branch is done, can actually use. A TEST phase
whose content is only *"nothing to test"* is an assertion, not a verification; nothing was checked, and the
document says so in a way that reads as though something had been.

**Two shapes are honest and neither is a suite.** Running the gates and reporting the outcome is a
verification. So is a check the phase cannot make automatic — a rendered page compared by eye, an output
read against what it should say — as long as the phase records that it was run and what it showed. What is
*not* a verification is a prediction: a step ticked because the change looks correct. That is the failure
[rule 3](#rules) already names from the other side, met here at the phase that exists to prevent it.

**Where the cycle is driven by a goal condition, this is the half the evaluator can see.** An evaluator
judges from what the session has surfaced, so a check whose result lands in the transcript is what lets the
condition resolve at all — and a TEST phase that only claims to be done leaves it nothing to read.

**DEPLOY takes no steps of its own** (Dave, August 14, 2026,
[#655](https://github.com/DaveKJohn/claude-code-specialists/issues/655)). It is not a step, it is the
**result** — the part that travels, folding into `CHANGELOG.md` at the merge while the rest of the document
goes with it. A checkbox under it could only be a lie.

That also explains a rule which otherwise looks arbitrary: a step written for *after* the merge is refused.
Post-merge is DEPLOY's territory, and DEPLOY is a description rather than a checklist. A DEPLOY checkbox
could only be unresolvable — the list must be clear before `open-pr` will push — or ticked before it
happened.

**A checkbox inside the DEPLOY section is prose, not a step**, and no gate reads it as one. The step gate
splits the document at the DEPLOY heading and counts only above it, which it has to: an entry legitimately
describes work in that shape, and this page's own rules below show all three marks.

The phase names come from the wording seam, so a repo can rename them; supplying an empty list switches
them off and restores the plain step list.

## The DEPLOY section — the changelog entry

```markdown
## DEPLOY: `feat/thing-v1` · <the merge stamp the fold writes>
```

`new-branch` already writes this shape, so on a fresh branch you are filling in a form rather than starting
from a blank page. **What it fills in for you** is the heading — which names the branch, so the type is
already there in its prefix — and the PR title you gave it at `-Title`. What is left for you is the reason
and the score under each tier the file carries.

**The merge stamp is on this heading** (Dave, August 23, 2026), where it sat on the `Pull Request` section
heading for four days. It is the date the change *landed*, and this is the line that says *what* landed.
Neither the number nor the date exists while you are writing; the fold writes both.

**A relative link in this section resolves from the REPO ROOT, not from this directory.** The fold copies
this text verbatim into `CHANGELOG.md` at the root, one directory up — so the link has to be written for
where it *lands*, which means it looks wrong in the file you are editing and only becomes right after it
moves:

```markdown
See [the lib](scripts/lib/release-lib.ps1).       <- correct: resolves at the destination
See [the lib](../scripts/lib/release-lib.ps1).    <- resolves HERE, dead once it lands
```

The instinct produces the second form, and until August 21, 2026 nothing said otherwise: a consumer merged
two `../../scripts/...` links that landed at the root pointing outside the repo, with every gate green
(inbound [#806](https://github.com/DaveKJohn/claude-code-specialists/issues/806)). `open-pr`'s **link gate**
refuses it now and prints the root-relative form, so the correction is one edit rather than a guess.
**Write the whole document that way**, plan included: the head carries no links in the scaffold, and one
rule for one file is the only version anybody can apply while writing.

**The PR title is the first line of the `Pull Request` section** (Dave, August 7, 2026;
[#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506)). `open-pr` composes the PR title
as `<branch type>: <that line>` rather than taking one on the command line, so the sentence is written
once — at `new-branch -Title` — and what the PR is called, what `CHANGELOG.md` says and what the release
documents carry are the same words by construction. Write it **without** a `feat:`/`fix:`/`docs:` prefix:
the branch name already states the type and `open-pr` puts it in front.

**It used to be a section of its own, and both homes are still read.** `Get-EntryPrTitle` owns that answer:
a section headed `Branch title` — `Branch description` before it — wins wherever one is present, and
otherwise the title is the `Pull Request` section's first line, skipping the `Plugins:` line and the
`[PR #N]` footer that the fold appends underneath it. So `CHANGELOG.md`, every release document and any
branch still in flight under the older shape fold unharmed. **Ask the seams rather than this page** for
which sections exist today: `Get-EntryWrittenSectionKeys` is what a writer emits,
`Get-EntrySectionHeadings` gives each one's heading text, and `Get-EntrySectionRetiredNames` the names that
are recognised but must never be written again. Recognise both, write one.

### The two tiers

**Two tiers are asked about: tier 0, and the one audience tier this repo has.** Tier 0 can always be filled
in — every change matters to the people who maintain this repo, if only a little. For the audience tier the
answer may well be *"this reaches nobody here"*, and you say so:

| block | who notices | answer it with |
|---|---|---|
| the DEPLOY section's own opening text | this repo's own developers — **tier 0** | a score, always |
| `### What makes this deploy extra special` | a subscriber of the service — **this repo's audience, tier 2** | a score, or `N/A` if no subscriber would notice |

**Tier 0 has no heading of its own**, and the DEPLOY heading is its section (Dave, August 23, 2026). It was
`#### Tier 0`, then a `###` question of its own; the question went away when the entry became a section of
this document, because the heading above it already asks it. The audience tier's heading moved **up** a
level in the same change — it is the entry's first inner heading now, at the same level as `Pull Request`.

**Neither heading names a tier, and that is deliberate** (Dave, August 19, 2026). An author filling one in
is answering a question rather than classifying a reader, and the second heading **resolves** to whichever
audience tier the repo has stated, so the form stops naming a number that is only right for repos answering
2. The tiers still exist exactly as before; they live in the parser instead of in the prose. **A repo that
has stated no audience tier keeps the older shape**, a `#### Tier N` sub-section per tier the model has with
tier 0 among them, because a heading with no tier to resolve to would read as tier 0 and empty its release
documents.

**Which of the two audience tiers you get is a repo-level fact, not a per-entry choice** (Dave, August 12,
2026). Tier 1 (management and the employer/commissioner) and tier 2 (the subscriber of a service) are two
kinds of reader rather than two rungs, and a repo has exactly one: it is stated once in
`Get-ReleaseAudienceTier`, and the scaffolder writes only that one. This repo answers **2**, being a service
rather than a product. A repo that has stated nothing is asked about both, exactly as before the knob
existed — and a tier this repo no longer asks about is still *read* wherever an older entry carries one, so
none of the 97 entries written under the cumulative model stops folding.

Each section carries **why it matters at that reach**, then **`**Score:** N`** — 1 to 5 against the rubric
`new-branch` prints when it writes the file. The tier decides which release documents the entry appears
in; the score decides where in each of them it sits.

**`N/A` needs its reason too**, and that is the point of answering rather than leaving a blank: *"no
consumer can observe this at all"* is information, and it survives into the record. A blank cannot say
that — it means both "reaches nobody" and "nobody has got to this yet", and the gate has to be able to tell
those apart. **The reach is the highest tier with a number**, so an `N/A` costs nothing but a sentence.

**The ladder is gone, and with it the second reading it forced.** Until August 12, 2026 a scored tier 2
*owed* a tier-1 section, and `open-pr` refused an `N/A` there by name. Measured before removing it: of this
repo's 89 tier-1 sections, **81 existed only because a tier-2 section sat above them** — the same reach
argued twice, in a second register, for a reader who here is the same person. What remains enforced is that
every tier the file *does* carry has a reason, `N/A` ones included, and that the audience tier a repo asks
about is answered before a PR opens.

### Four things about this shape, each of which someone has got wrong before

- **The PR line is not yours to write.** The fold fills `### Pull Request` from the merge itself.
- **Nothing may use `##` inside the section, and `###` only for its named headings.** A `##` becomes a
  *separate change* the moment the fold pastes this into `CHANGELOG.md` — one that declares no impact, so it
  reads as tier 0. A `###` collides with the named headings, truncating whichever one it lands in. Use
  `####` or bold. Your lint gate checks this where you have one — the source repo's does, reading the DEPLOY
  section out of the document rather than the whole file.
- **The `###` headings are exact.** They are what the parsers look for; a misspelling means the entry
  silently loses that declaration and the gates read nothing.
- **The score is scaffolded empty**, and that is a question rather than a default. Tier 0 is a harmless
  final answer about *reach*, but any number written into `**Score:**` for you would be a guess at a
  ranking — and this repo has measured what a guessed ranking costs. The release cut refuses a release
  whose tier-1-or-higher entries have not answered.

**And an empty field is refused, which is what replaced the `TODO:` lines.** The form writes no visible
placeholder anywhere, so `open-pr` measures instead of matching: it names the description, the body and
any tier whose reason is still blank. That catches the untouched entry the placeholders used to catch
*and* the one whose placeholder was deleted rather than answered.

## Why one file and not two

Two files used to do these two jobs, and before them one file did both badly. The one-file version was
scaffolded with a bold *to do / where I left off* heading **and** folded verbatim into `CHANGELOG.md`, so
"replace this whole block before the PR" had to be a written instruction rather than something the format
made obvious. It did not always happen: three of v3.2.0's twenty-one entries shipped with that heading and a
status appended behind it, into the release notes *and* into the per-plugin `CHANGELOG.md` files that travel
to consumers.

**Splitting them fixed that, and the split then cost something of its own** (Dave, August 23, 2026). The two
jobs genuinely are different — one asks what the change does, the other what is left — but putting them in
two documents meant the plan a branch is working through and the claim it will make were never on one
screen. An author who has just ticked the last box is now looking at the paragraph they have to write next.

**What made the merge safe is that the confusion the split removed is structural now.** The entry is a
*named section* with the branch in its heading, not the whole file: the fold takes that section, the step
gate counts only above it, and the scaffold gate reads only inside it. Nothing has to be "replaced before
the PR", because nothing is doing two jobs at once.

**There is also no `Where I left off` any more** (Dave, August 23, 2026). It asked the author to write down
what the step list already says: an unticked box *is* where you left off, and a second account of it beside
the list is one that can disagree with the list. A parking note still has a place — `new-branch -Park
-Intent` writes it at the top of the document, above the phases — because that is the one thing the marks
genuinely cannot carry: what you decided and have not written down anywhere yet.

## Why the name is fixed

`development-cycle.md` is the same on every branch, which looks like it should collide the moment two
branches exist. It cannot: **git already tracks this file per branch**, so each branch carries its own
version of the same path and a checkout swaps them. The per-branch filename this replaced was solving a
problem version control had already solved, and it cost a repo root that filled up with other people's
in-flight work.

**`<branchname>-changelog.md` was weighed and declined** (Dave, August 6, 2026), so this is a decision
rather than an oversight. Two things speak against it today, and a third that has since expired is kept below:

1. **It reinstates the derived filename, which was a trap.** The system this replaced had a written rule
   forbidding a `-v2` suffix, because the fold looked the entry up by the exact branch name and a suffix
   broke the match *and* the cleanup that followed it. Today the fold reads the branch from the document's
   own heading — a fact stated in the document instead of guessed from a filename. The version suffix is
   now the *convention* rather than the thing that breaks it.
2. **It solves a collision that does not happen**, per the paragraph above.

**The third argument has since expired, and it is left here rather than quietly dropped**, because it was
the decisive one at the time. It ran: unique names would make the reset state impossible, since the warning
on the trunk exists only because the file exists there — no file, no reference, no warning, and nothing
standing between the fold and a file it must not treat as a change. On August 23, 2026 (Dave) the document
became branch-lifetime and the trunk stopped carrying a copy at all, so that is now simply what happens.
The decision still stands on the two arguments above; a reader meeting it should know it stands on two
rather than three.

**The one real case for unique names, kept here on purpose:** if you take `main` in during the window
between another branch's merge and its fold, that branch's entry is briefly on `main` and conflicts with
yours. The conflict is visible and the resolution is trivial — keep yours; theirs will be folded from
`main` — and the window is small because the fold runs straight after the merge. **Deliberately not
pre-empted.** If it ever actually bites, the cheap repair is a merge strategy for the file in
`.gitattributes`, not renaming the mechanism.

## On the trunk there is no file at all

**The document exists for the lifetime of a branch and no longer** (Dave, August 23, 2026). `new-branch`
creates it, the fold removes it at the merge, and between branches your workflow folder holds its pages and
its directories and nothing else. So if you open that folder on the trunk and the document is not there,
that is the trunk in its normal state rather than something somebody deleted.

Until that day it was rewritten to a **reset state** instead: the same document, with the trunk's name in
its heading, a warning under it saying not to write here until a branch exists, no scaffolded step, and
placeholder text where the two stamps go. It was retired because an empty placeholder is a permanent
resident of the one folder a repo reads to learn the convention, and because this page is the better home
for what that copy was really for — seeing the whole form at once.

**A repo updating from an older plugin still has one**, written by its last fold under the old behaviour.
Nothing has to be done about it: the next fold removes it. Everything below that describes recognising a
trunk-declaring document is about exactly that case.

**How such a document is told from a written one is the branch NAME, not the heading level**, and that
changed with the merge. The two files it replaces each opened with an `#` while empty and the entry with an
`##` once written, so one look at the first line answered it. One document cannot use that test: its `#` is
its title in both states, and the `##` below it is a section of it. So the test is the name — the trunk's
while the document is empty, yours once it is not. It used to be what made folding twice impossible; the
fold removes the file now, so a second run simply finds nothing.

## The file is written under you, once per cycle

`new-branch` writes it when the branch is created. That is an **out-of-band write event**, and it is the
only one of its kind in a repo: no other file is written alternately by a script and by whoever is editing
it. It was two until August 23, 2026 — the fold used to rewrite the file after the merge, and now removes
it, so there is nothing left to re-read at that end of the cycle.

So **read it again whenever a script has just touched it**, before your next edit. An editor that tracks
what it last read refuses the write otherwise — *"file has been modified since read"* — and the refusal
lands on the **first** write after the script, which in practice means the second and later branches of one
sitting rather than the first. Nothing is lost and nothing is broken: one read re-syncs it and the write
goes through. Measured over three full cycles in a single session: two refused writes, three stale notices,
nothing clobbered. What it costs, if you are not expecting it, is a line that reads as a failing tool.

Both scripts say so where they print that path, which is the half that reaches whoever ran them; this page
is the half that reaches whoever did not. **The guard itself is not a defect and is not something a repo can
or should switch off** — it is what stops an edit silently overwriting an out-of-band change nobody saw, and
this is exactly the file where out-of-band changes are routine.

## Rules

1. **The DEPLOY section holds the entry block and nothing around it** — no preamble, no warning. That is
   what makes it pasteable into `CHANGELOG.md` in one go, which is its whole reason for existing. It opens
   with the branch, and that is what lands in the changelog.
2. **Links are written root-relative**, as if the file were already in the repo root — because after the
   fold its DEPLOY section is. Your lint gate, where you have one, checks them from there.
3. **Every step is resolved before the PR.** `open-pr.ps1` and `ship-pr.ps1` both refuse while anything
   is unresolved. Three marks:

   ```text
   - [ ] not done yet          -> blocks the PR and the merge
   - [x] done
   - [~] dropped -- <why it turned out not to be needed>
   ```

   `- [~]` exists because a plan legitimately grows items that stop making sense. Without it a gate
   teaches people to tick boxes for work they did not do, and then reports success — worse than no gate.
   A dropped step keeps its line and its reason, which is the half worth reading later. **There is no
   `-Force` for this gate**; the dropped mark already is the way past a step that should not be done.
   The three marks are *shown* in the document's own guidance, and the gate does not read them there — it
   strips comments before it counts, exactly as it already ignores them inside a fence. Without that, every
   freshly scaffolded branch would report four open steps: its own, plus the three the form uses to explain
   itself.
4. **A step still carrying the scaffold's own placeholder is refused, ticked or not.** Ticking the
   scaffolded first step without replacing it reports a plan as finished that was never written. The trunk
   copy shows the phases **empty** — a reference whose first line is somebody else's TODO gets copied in —
   but the file a branch actually gets carries one open step, so the gate has something to refuse (Dave,
   August 6, 2026).
5. **Work that happens after the merge is not a step.** Opening the PR, waiting for CI, merging, folding,
   publishing a GitHub Release, taking a measurement that only exists once the run is over — none of it
   belongs under a phase heading. It is what the DEPLOY section *describes*, in prose, once it has happened.

   **Neither mark fits it, and that is the whole argument.** The gate above runs *before* the push, so at
   the moment it reads the list the step cannot be done. `- [x]` reports work that has not happened;
   `- [~]` says the step turned out not to be needed, when it is needed and simply comes later. The only
   way to satisfy the gate is rule 3's own named failure — ticking a box to get past it, after which the
   run reports success.

   **Measured across the 105 branches that have carried a step list** (August 13, 2026): **17** wrote a
   post-merge step. **4** left it open, where it blocked the PR. **14** ticked it in advance — provably in
   advance, because the fold clears this file at the merge, so a ticked PR step can only have been
   written before the push existed. And one branch is in both counts:
   `docs/check-20-and-inbound-catch-up` hit the gate on `- [ ] Lint + tests green, then PR + merge + fold`
   and the next commit changed nothing but that box to `- [x]`. Two other branches reached the right answer
   on their own and dropped the step with the reason on the line, which is what this rule generalises.

   **No gate enforces this, deliberately.** A check would have to recognise a post-merge step by its
   wording, and `open-pr`, `merge` and `fold` are also the subjects of perfectly ordinary steps — *"`open-pr.ps1`:
   recognise the new placeholder alongside the two legacy ones"* is real work on a branch. Separating the two
   needs an exclusion list, which is the shape this repo has been bitten by often enough to stop reaching
   for it (see the declined checks in the source repo's
   [`CLAUDE.md`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/CLAUDE.md#claude-code-specialistss-safety-implementation)).
   The convention is cheap to follow and the failure is self-correcting: write it as a step and the gate
   stops you.
6. **Fill in every tier the DEPLOY section carries before the PR.** How far the change reaches decides which
   release documents the entry appears in; what it weighs there decides where in each of them it sits — see
   [the contribution cycle](CONTRIBUTING-portable.md#significance--two-questions-in-one-section).
7. **Never edit `CHANGELOG.md` from a branch.** Every branch would be editing the same region of the
   same file; that is the merge conflict this document exists to avoid.

## What happens at the merge

[`scripts/release/fold-changelog-entry.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/release/fold-changelog-entry.ps1),
run on `main` right after the merge:

1. **splits the document at the DEPLOY heading** and takes that section — the plan above it never travels;
2. **strips any HTML comments** — the guidance is the form rather than the answer;
3. inserts the entry at the **top** of `CHANGELOG.md`'s list — that document is newest-first — with the
   PR link written into `### Pull Request` and the merge moment stamped on the DEPLOY heading;
4. **removes the document** — one deletion, which clears the plan along
   with the entry because they are sections of the same file, and leaves the trunk without a copy;
5. commits exactly those two paths.

The branch name it needs for the PR lookup comes from the document's own heading — the file name does not
carry it, which is why the branch is named in the document rather than only in the scaffolder's head.

**What lands in `CHANGELOG.md` is that section as it stands** — the DEPLOY heading and everything under it,
answers and all. That is a deliberate choice by Dave (August 6, 2026), taken over the alternative he was
offered: a fold that reads the dossier and emits a slimmer block. He declined it, and the reason holds up —
a fold that rewrote the entry would be a *second* definition of the entry format living inside the fold,
which is the drift this repo has already paid for in the fence readers, the scaffold wording and the tier
sections. One shape, written once, read everywhere.

## Working from more than one machine

Park a branch with
[`scripts/task/park-branch.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/task/park-branch.ps1),
or create it with `new-branch.ps1 -Park`: both push with no PR, and both take the whole document — the plan
is the half that says what was still in flight, so parking the description without it defeats the point.
That used to require naming two files; it is one path now.

**They differ in what else comes along, and the commit says so** (#507): `-Park` commits *only* that file,
leaving anything you had staged for your own next commit exactly where it was, while `park-branch` commits
*everything* outstanding. The subjects read `park: <branch> (the branch files only)` and
`park: <branch> (all outstanding work)`. They were the same sentence until August 7, 2026, which meant that
afterwards nothing told you which half of your work had reached origin.

Before picking a parked branch back up, measure its plan against `main`. A plan that reads as current is
not evidence that it is — see the `park` skill for what to check and why.
