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

## The entry template

`new-branch` already writes this shape into `branch-changelog.md`, so on a fresh branch you are filling
in a form rather than starting from a blank page. Every field is a **heading with an HTML comment under
it** saying what a good answer looks like; you write underneath. The comments are stripped by the fold, so
leaving them standing costs the changelog nothing and there is nothing to tidy before the PR:

```markdown
## `<prefix>/<short-name>` changelog

### Branch description
<!-- Short description of branch-->

### Branch ID
<!--unique ID for branch like a timestamp of the moment this branch is created-->

### Branch type
<!-- options for type are: feat, fix or docs-->

### What does the change on this branch bring to main?
<!-- what the change DOES, for whoever reads CHANGELOG.md later -->

### Significance

#### Tier 0

<!-- why it matters to this repo's own developers -->

**Score:**

### Pull Request
<!-- filled in by the fold, from the merge itself -->
```

**Three of those fields are filled in for you.** `new-branch` writes the heading, the **Branch ID** (a
timestamp taken when the branch is created) and the **Branch type** (the prefix of the branch name). The
same three appear at the top of `branch-progress.md`, with the same ID — the two files are one pair, and
they say so. What is left for you is the description, the body, and the Significance sections.

**The heading names the branch, not the change.** That is where the description went: `## `feat/x`
changelog` is what this file is, and *what changed* is the first section under it. Both branch files carry
that heading, which is also how the fold finds the branch it needs to look the PR up by.

**Work down the tiers, and stop where the answer is no.** Tier 0 can always be filled in — every change
matters to the people who maintain this repo, if only a little. Each section ends by asking whether there
is a next one:

| section | who notices | add it when |
|---|---|---|
| `#### Tier 0` | this repo's own developers | always |
| `#### Tier 1` | colleagues and employers | the change gives the project something, not just the code |
| `#### Tier 2` | the people who consume this product | a consumer would notice |

Each section carries **why it matters at that reach**, then **`**Score:** N`** — 1 to 5 against the rubric
`new-branch` prints when it writes the file. The tier decides which release documents the entry appears
in; the score decides where in each of them it sits.

Tier 1 and Tier 2 are in the template **commented out**, each behind its own `<!-- UNCOMMENT … -->` line.
Delete the first line to bring Tier 1 into the document; Tier 2 has a marker of its own, so it stays
commented until you delete that one too. The tiers come out one at a time, in order, with nothing else to
edit.

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

### Pull Request

<!-- the fold writes this line -->
```

The guidance comments are gone from that example because it is shown **as the fold leaves it** — comments
stripped, the PR line written in. What you edit still has them.

That entry stops at tier 1: nobody outside this repo notices a lint rule, so there is no `#### Tier 2`
and its absence *is* the answer. That is why this replaced a table — a missing row read as an omission,
a missing section reads as a decision.

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
   The three marks are *shown* in the Steps guidance comment, and the gate does not read them there — it
   strips comments before it counts, exactly as it already ignored them inside a fence. Otherwise a fresh
   branch would report four open steps: its own, plus the three the form uses to explain itself.
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

1. **strips the guidance comments** — they are the form, not the answer, and this is what makes them safe
   to leave standing while you write;
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
