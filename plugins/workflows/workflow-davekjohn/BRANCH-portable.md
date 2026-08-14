# The `branch/` files — the portable half

Everything a branch needs to carry lives in its repo's `workflow-davekjohn/branch/` directory — inside
the workflow's own root folder, where everything portable gathers — split into two files with one
job each:

| file | subject | who reads it | lifetime |
|---|---|---|---|
| `branch-changelog.md` | what the change **does** | whoever reads `CHANGELOG.md` later | folded at the merge, then reset |
| `branch-progress.md` | what still **must happen** | whoever is working on the branch | reset at the merge; never folded |

Both are written by the shared
[`scripts/task/new-branch.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/task/new-branch.ps1)
at the moment the
branch is created. You do not create them by hand, and you do not delete them.

**How to read this page.** It travels with the plugin, so two conventions keep it true in every tree it
lands in — the same two `RELEASES-portable.md` states for itself. *This repo* always names the **source
repo** the page was written in
([claude-code-specialists](https://github.com/DaveKJohn/claude-code-specialists)) — its measurements travel
as the evidence behind the rules, never as your repo's own record. And links into the source's script tree
are **absolute** on purpose; files every adopting repo has of its own (the two branch files, the templates
under `workflow-davekjohn/branch/templates/`) are named in code rather than linked, because the copy that matters is yours.

A blank copy of each file also sits in your own `workflow-davekjohn/branch/templates/`, to look at or paste from:

| template | for |
|---|---|
| `workflow-davekjohn/branch/templates/branch_template_changelog.md` | `branch-changelog.md` |
| `workflow-davekjohn/branch/templates/branch_template_progress.md` | `branch-progress.md` |

**They are generated, not maintained.** A template beside a scaffolder that writes the same shape is two
sources of one format, which is the drift this repo keeps paying for — so their content comes from the
same formatters `new-branch` calls (`Get-BranchTemplates`), and the lint gate holds the files on disk to
it, byte for byte. Editing one by hand is an error the gate reports; change the format and the templates
follow.

**`new-branch` writes them, and refreshes one that has drifted.** That matters most away from the source
repo: a consuming repo has no lint of its own, so the scaffolder is the only thing keeping their reference
current — and since the working files became bare, that reference is the only place the guidance exists at
all. Rewriting a drifted copy is what carries a format change into a consumer's reference through the same
plugin update that carries it into their scripts.

They mark their own heading **`(template)`**, and that is not decoration. A written entry and a template
now open with the same `##`, which is the signature the fold and the lint use to tell an entry from any
other markdown — so the marker is what keeps a template from ever being read as somebody's work.

## branch-changelog

`new-branch` already writes this shape into `branch-changelog.md`, so on a fresh branch you are filling
in a form rather than starting from a blank page.

**The file it writes is bare** — the headings, the three fields it fills in itself, and nothing else. The
guidance lives in your `workflow-davekjohn/branch/templates/`, where every field carries an HTML comment saying what a good
answer looks like. That is what those copies are for: the file you type in is the questions and your
answers, and the reference is one directory away.

**Three of those fields are filled in for you.** `new-branch` writes the heading, the **Branch ID** (a
timestamp taken when the branch is created) and the **Branch type** (the prefix of the branch name). What
is left for you is the description, the body, and the Significance sections.

They live in **this file only**. They briefly sat at the top of `branch-progress.md` as well, so the pair
would say whose it is — that was removed, because the same information in two places is free to disagree
and here it would be visible on every branch. The step list identifies itself by its heading, which is the
one thing any script reads out of it besides the step marks.

**The heading names the branch, not the change.** That is where the description went: `## `feat/x`
changelog` is what this file is, and *what changed* is the first section under it. Both branch files carry
that heading, which is also how the fold finds the branch it needs to look the PR up by.

**That first section is `Branch title`, and it is also the PR title** (Dave, August 7, 2026;
[#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506)). `open-pr` composes the PR title
as `<branch type>: <this section>` rather than taking one on the command line, so the sentence is written
once — at `new-branch -Title` — and what the PR is called, what `CHANGELOG.md` says and what the release
documents carry are the same words by construction. Write it **without** a `feat:`/`fix:`/`docs:` prefix:
the branch name already states the type and `open-pr` puts it in front. The section was called
`Branch description` for a day; that name is still read, so a branch created under it folds unharmed.

**Two sections are in the file: tier 0, and the one audience tier this repo has.** Tier 0 can always be
filled in — every change matters to the people who maintain this repo, if only a little. For the audience
tier the answer may well be *"this reaches nobody here"*, and you say so:

| section | who notices | answer it with |
|---|---|---|
| `#### Tier 0` | this repo's own developers | a score, always |
| `#### Tier 2` | a subscriber of the service — **this repo's audience** | a score, or `N/A` if no subscriber would notice |

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

**Four things about this shape, each of which someone has got wrong before:**

- **The PR line is not yours to write.** The fold fills `### Pull Request` from the merge itself. Neither
  the number nor the date exists while you are writing, and a date written now would be the branch's birth
  date rather than its landing date.
- **Nothing may use `##` or `###` inside the body.** A `##` becomes a *separate change* the moment the
  fold pastes this into `CHANGELOG.md` — one that declares no impact, so it reads as tier 0 — and a
  `###` collides with the named sections, truncating whichever one it lands in. Use `####` or
  bold. Your lint gate checks this where you have one — the source repo's does. Inside
  `### Significance` the `####` level is structural, so there it
  is `Tier 0`, `Tier 1` or `Tier 2` and nothing else.
- **The `###` section headings are exact.** They are what the parsers look for; a misspelling means the
  entry silently loses that declaration and the gates read nothing.
- **The score is scaffolded empty**, and that is a question rather than a default. Tier 0 is a harmless
  final answer about *reach*, but any number written into `**Score:**` for you would be a guess at a
  ranking — and this repo has measured what a guessed ranking costs. The release cut refuses a release
  whose tier-1-or-higher entries have not answered.

**And an empty field is refused, which is what replaced the `TODO:` lines.** The form writes no visible
placeholder anywhere, so `open-pr` measures instead of matching: it names the description, the body and
any tier whose reason is still blank. That catches the untouched entry the placeholders used to catch
*and* the one whose placeholder was deleted rather than answered.

**The shape itself is in your `workflow-davekjohn/branch/templates/branch_template_changelog.md`** —
field by field, with the guidance for each — so it is deliberately not repeated here. Open that file when
you want to see the whole form at once.

## branch-progress

The step list is yours. It is never folded and never travels anywhere, so it may hold whatever helps you
pick the branch back up — notes, links, a scratch list. Two things in it are read by scripts: **the branch
name in the heading**, which is how the fold finds the PR, and **the step marks under `### Steps`**.

It carries **nothing but that** — no description, no ID, no type. Those are the entry's, and repeating them
here would be one fact in two files. `new-branch` scaffolds one open step, so the gate below has something
to refuse; the shape is in
your `workflow-davekjohn/branch/templates/branch_template_progress.md`.

## Why two files and not one

One file used to do both jobs. It was scaffolded with a bold *to do / where I left off* heading **and**
folded verbatim into `CHANGELOG.md`, which meant "replace this whole block before the PR" had to be a
written instruction rather than something the format made obvious. It did not always happen: three of
v3.2.0's twenty-one entries shipped with that heading and a status appended behind it, into the release
notes *and* into the per-plugin `CHANGELOG.md` files that travel to consumers.

Two files make it obvious. The entry asks what the change does. The step list asks what is left.

## Why the names are fixed

`branch-changelog.md` and `branch-progress.md` are the same on every branch, which looks like it should
collide the moment two branches exist. It cannot: **git already tracks these files per branch**, so each
branch carries its own version of the same path and a checkout swaps them. The per-branch filename this
replaced was solving a problem version control had already solved, and it cost a repo root that filled
up with other people's in-flight work.

**`<branchname>-changelog.md` was weighed and declined** (Dave, August 6, 2026), so this is a decision
rather than an oversight. Three things speak against it, and the first is decisive:

1. **The reset state would be impossible.** The warning you see on the trunk exists because the files
   exist there. Unique names mean nothing is on `main` at all — no template, no warning, and no `#`
   heading standing between the fold and a file it must not treat as a change. That was a requirement,
   not a nicety.
2. **It reinstates the derived filename, which was a trap.** The system this replaced had a written rule
   forbidding a `-v2` suffix, because the fold looked the entry up by the exact branch name and a suffix
   broke the match *and* the cleanup that followed it. Today the fold reads the branch from this
   directory's own branch line — a fact stated in the document instead of guessed from a filename.
3. **It solves a collision that does not happen**, per the paragraph above.

**The one real case for unique names, kept here on purpose:** if you take `main` in during the window
between another branch's merge and its fold, that branch's entry is briefly on `main` and conflicts with
yours. The conflict is visible and the resolution is trivial — keep yours; theirs will be folded from
`main` — and the window is small because the fold runs straight after the merge. **Deliberately not
pre-empted.** If it ever actually bites, the cheap repair is a merge strategy for `branch/**` in
`.gitattributes`, not renaming the mechanism.

## The reset state, and the warning on the trunk

On `main` both files sit in an empty **reset state** — a short explanation, and a warning under the
branch line saying not to write here until a branch exists. That is what you are looking at if you open
them on the trunk: the empty state, not a lost entry.

The reset state opens with an `#` (an H1), and that is load-bearing rather than cosmetic. The fold
recognises an entry by its heading level, and a written entry heading is an `##`. So the trunk's own empty
file can never be folded as if it were a change, and folding twice is impossible rather than merely
unlikely. **Both files follow that rule** — H1 while empty, H2 once a branch owns them — so the pair looks
the same in both states.

One consequence, handled where it lands: `branch-progress.md` now carries the same `##` a changelog entry
does, so the lint's entry check excludes it **by path**. It is not an entry, and the path is what says so
— its `### Steps` heading is only how that shows.

## Rules

1. **The entry holds the entry block and nothing around it** — no preamble, no warning. That is what
   makes it pasteable into `CHANGELOG.md` in one go, which is its whole reason for existing. Since the
   dossier form the block opens with the branch, and that is what lands in the changelog.
2. **Links in the entry are written root-relative**, as if the file were already in the repo root —
   because after the fold it is. Your lint gate, where you have one, checks them from there. Links in `branch-progress.md`
   follow the ordinary nested convention (`../scripts/...`): that file never travels.
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
   The three marks are *shown* in the template's Steps guidance, and the gate does not read them there — it
   strips comments before it counts, exactly as it already ignored them inside a fence. Without that, a
   branch created from the template by hand would report four open steps: its own, plus the three the form
   uses to explain itself.
4. **A step still carrying the scaffold's own placeholder is refused, ticked or not.** Ticking the
   scaffolded first step without replacing it reports a plan as finished that was never written. The
   template shows the Steps section **empty** — an example whose first line is somebody else's TODO gets
   copied in — but the file a branch actually gets carries one open step, so the gate has something to
   refuse (Dave, August 6, 2026).
5. **Work that happens after the merge is not a step.** Opening the PR, waiting for CI, merging, folding,
   publishing a GitHub Release, taking a measurement that only exists once the run is over — none of it
   belongs under `### Steps`. Put it in **`### Where I left off`**, which is exactly what that section is
   for.

   **Neither mark fits it, and that is the whole argument.** The gate above runs *before* the push, so at
   the moment it reads the list the step cannot be done. `- [x]` reports work that has not happened;
   `- [~]` says the step turned out not to be needed, when it is needed and simply comes later. The only
   way to satisfy the gate is rule 3's own named failure — ticking a box to get past it, after which the
   run reports success.

   **Measured across the 105 branches that have carried a step list** (August 13, 2026): **17** wrote a
   post-merge step. **4** left it open, where it blocked the PR. **14** ticked it in advance — provably in
   advance, because the fold *resets* this file at the merge, so a ticked PR step can only have been
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
6. **Fill in the Significance sections before the PR.** How far the change reaches decides which release
   documents the entry appears in; what it weighs there decides where in each of them it sits — see
   [the contribution cycle](CONTRIBUTING-portable.md#significance--two-questions-in-one-section).
7. **Never edit `CHANGELOG.md` from a branch.** Every branch would be editing the same region of the
   same file; that is the merge conflict this directory exists to avoid.

## What happens at the merge

[`scripts/release/fold-changelog-entry.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/release/fold-changelog-entry.ps1),
run on `main`
right after the merge:

1. **strips any HTML comments** — the scaffolder writes none, but a branch created before that, or one
   pasted from a template, carries them, and they are the form rather than the answer;
2. inserts the entry into `CHANGELOG.md` at its ranked position (furthest reach first, highest
   significance first within a tier), with the PR link and merge date written into `### Pull Request`;
3. **resets both files** to the empty state you see on the trunk;
4. commits exactly those three paths.

The branch name it needs for the PR lookup comes from the branch files' own heading — the file name no
longer carries it, which is why the branch is named in the document rather than only in the scaffolder's
head.

**What lands in `CHANGELOG.md` is this file as it stands** — the branch heading, the description, the ID,
the type, the body and the Significance sections. That is a deliberate choice by Dave (August 6, 2026),
taken over the alternative he was offered: a fold that reads the dossier and emits a slimmer block. He
declined it, and the reason holds up — a fold that rewrote the entry would be a *second* definition of the
entry format living inside the fold, which is the drift this repo has already paid for in the fence
readers, the scaffold wording and the tier sections. One shape, written once, read everywhere.

## Working from more than one machine

Park a branch with
[`scripts/task/park-branch.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/task/park-branch.ps1),
or create it with
`new-branch.ps1 -Park`: both push with no PR, and both take **both** files rather than the entry alone —
the step list is the half that says what was still in flight, so parking the description without the plan
defeats the point.

**They differ in what else comes along, and the commit now says so** (#507): `-Park` commits *only* those
two files, leaving anything you had staged for your own next commit exactly where it was, while
`park-branch` commits *everything* outstanding. The subjects read `park: <branch> (the branch files only)`
and `park: <branch> (all outstanding work)`. They were the same sentence until August 7, 2026, which meant
that afterwards nothing told you which half of your work had reached origin.

Before picking a parked branch back up, measure its plan against `main`. A plan that reads as current is
not evidence that it is — see the `park` skill for what to check and why.
