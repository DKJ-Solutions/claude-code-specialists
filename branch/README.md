# `branch/` — the two files a branch works in

Everything a branch needs to carry lives here, split into two files with one job each:

| file | subject | who reads it | lifetime |
|---|---|---|---|
| [`branch-changelog.md`](branch-changelog.md) | what the change **does** | whoever reads `CHANGELOG.md` later | folded at the merge, then reset |
| [`branch-progress.md`](branch-progress.md) | what still **must happen** | whoever is working on the branch | reset at the merge; never folded |

Both are written by [`scripts/task/new-branch.ps1`](../scripts/task/new-branch.ps1) at the moment the
branch is created. You do not create them by hand, and you do not delete them.

A blank copy of each also sits in [`templates/`](templates/), to look at or paste from:

| template | for |
|---|---|
| [`branch_template_changelog.md`](templates/branch_template_changelog.md) | `branch-changelog.md` |
| [`branch_template_progress.md`](templates/branch_template_progress.md) | `branch-progress.md` |

**They are generated, not maintained.** A template beside a scaffolder that writes the same shape is two
sources of one format, which is the drift this repo keeps paying for — so their content comes from the
same formatters `new-branch` calls (`Get-BranchTemplates`), and the lint gate holds the files on disk to
it, byte for byte. Editing one by hand is an error the gate reports; change the format and the templates
follow.

They mark their own heading **`(template)`**, and that is not decoration. A written entry and a template
now open with the same `##`, which is the signature the fold and the lint use to tell an entry from any
other markdown — so the marker is what keeps a template from ever being read as somebody's work.

## branch-changelog

`new-branch` already writes this shape into `branch-changelog.md`, so on a fresh branch you are filling
in a form rather than starting from a blank page.

**The file it writes is bare** — the headings, the three fields it fills in itself, and nothing else. The
guidance lives in [`templates/`](templates/), where every field carries an HTML comment saying what a good
answer looks like. That is what those copies are for: the file you type in is the questions and your
answers, and the reference is one directory away.

**Three of those fields are filled in for you.** `new-branch` writes the heading, the **Branch ID** (a
timestamp taken when the branch is created) and the **Branch type** (the prefix of the branch name). The
same three appear at the top of `branch-progress.md`, with the same ID — the two files are one pair, and
they say so. What is left for you is the description, the body, and the Significance sections.

**The heading names the branch, not the change.** That is where the description went: `## `feat/x`
changelog` is what this file is, and *what changed* is the first section under it. Both branch files carry
that heading, which is also how the fold finds the branch it needs to look the PR up by.

**All three tiers are in the file, and each one is answered.** Tier 0 can always be filled in — every
change matters to the people who maintain this repo, if only a little. For the two above it, the answer may
well be *"this reaches nobody here"*, and you say so:

| section | who notices | answer it with |
|---|---|---|
| `#### Tier 0` | this repo's own developers | a score, always |
| `#### Tier 1` | colleagues and employers | a score, or `N/A` if the project gets nothing out of it |
| `#### Tier 2` | customers and users | a score, or `N/A` if no consumer would notice |

Each section carries **why it matters at that reach**, then **`**Score:** N`** — 1 to 5 against the rubric
`new-branch` prints when it writes the file. The tier decides which release documents the entry appears
in; the score decides where in each of them it sits.

**`N/A` needs its reason too**, and that is the point of answering rather than leaving a blank: *"no
consumer can observe this at all"* is information, and it survives into the record. A blank cannot say
that — it means both "reaches nobody" and "nobody has got to this yet", and the gate has to be able to tell
those apart. **The reach is the highest tier with a number**, so an `N/A` costs nothing but a sentence.

**The ladder cannot be skipped.** `N/A` at tier 1 with a score at tier 2 says a change consumers notice
gives this project's colleagues nothing; `open-pr` refuses that by name rather than asking you for a
number.

**Four things about this shape, each of which someone has got wrong before:**

- **The PR line is not yours to write.** The fold fills `### Pull Request` from the merge itself. Neither
  the number nor the date exists while you are writing, and a date written now would be the branch's birth
  date rather than its landing date.
- **Nothing may use `##` or `###` inside the body.** A `##` becomes a *separate change* the moment the
  fold pastes this into `CHANGELOG.md` — one that declares no impact, so it reads as tier 0 — and a
  `###` collides with the named sections, truncating whichever one it lands in. Use `####` or
  bold. The lint gate checks this. Inside `### Significance` the `####` level is structural, so there it
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

A worked example, as it looks just before the PR:

```markdown
## `fix/dead-link-scan` changelog

### Branch description

The dead-link scan reaches the payload layers it never read

### Branch ID

20260806-114230

### Branch type

fix

### What does the change on this branch bring to main?

Agent defs, `agent-shared/`, `.github/` and `.claude/rules/` matched no rule in the scan set — 40 files,
and a real dead link had been sitting in one of them, seen by nothing.

### Significance

#### Tier 0

Four more rules in the scan set; nothing changes in how anyone works.

**Score:** 2

#### Tier 1

A dead link in the largest body of prose this repo ships is now caught before it merges.

**Score:** 3

#### Tier 2

Nobody outside this repo can observe a lint rule.

**Score:** N/A

### Pull Request

[PR #123](https://github.com/DaveKJohn/claude-code-specialists/pull/123) · merged 2026-08-06
```

That entry reaches tier 1: the lint rule gives the project something, and tier 2 says out loud that no
consumer can see it. **`N/A` is an answer, not a gap** — which is the whole reason the tiers are all in the
file rather than added when claimed. The `### Pull Request` line is shown filled in because that is how the
fold leaves it; while you are writing, that section is empty.

## branch-progress

The step list is yours. It is never folded and never travels anywhere, so it may hold whatever helps you
pick the branch back up — notes, links, a scratch list. Two things in it are read by scripts: **the branch
name in the heading**, which is how the fold finds the PR, and **the step marks under `### Steps`**.

It opens with the same three fields the entry does — description, ID and type, with the same ID — because
the two files are one pair and say so. `new-branch` fills those in, and scaffolds one open step so the gate
below has something to refuse.

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
   because after the fold it is. The lint gate checks them from there. Links in `branch-progress.md`
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
5. **Fill in the Significance sections before the PR.** How far the change reaches decides which release
   documents the entry appears in; what it weighs there decides where in each of them it sits — see
   [`CONTRIBUTING.md`](../CONTRIBUTING.md).
6. **Never edit `CHANGELOG.md` from a branch.** Every branch would be editing the same region of the
   same file; that is the merge conflict this directory exists to avoid.

## What happens at the merge

[`scripts/release/fold-changelog-entry.ps1`](../scripts/release/fold-changelog-entry.ps1), run on `main`
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

Park a branch with [`scripts/task/park-branch.ps1`](../scripts/task/park-branch.ps1), or create it with
`new-branch.ps1 -Park`: both commit **both** files and push, with no PR. The step list is the half that
says what was still in flight, so parking the entry without it defeats the point.

Before picking a parked branch back up, measure its plan against `main`. A plan that reads as current is
not evidence that it is — see the `park` skill for what to check and why.
