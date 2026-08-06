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
it. Editing one by hand is an error the gate reports; change the format and the templates follow.

## The entry template

`new-branch` already writes this shape into `branch-changelog.md`, so on a fresh branch you are filling
in a form rather than starting from a blank page. It is here as well for the moment you want to see the
whole thing at once, or paste it back after cutting it about:

```markdown
## <the title, and nothing else>

### What does this change do?

<what the change does, for whoever reads CHANGELOG.md later>

### Significance

#### Tier 0

<why it matters to this repo's own developers>

Score: <1-5>

Is this change also relevant to colleagues and employers? Then continue to Tier 1.
If not, stop here and move on to the next section.

### Type of change

Feat
```

**Work down the tiers, and stop where the answer is no.** Tier 0 can always be filled in — every change
matters to the people who maintain this repo, if only a little. Each section ends by asking whether there
is a next one:

| section | who notices | add it when |
|---|---|---|
| `#### Tier 0` | this repo's own developers | always |
| `#### Tier 1` | colleagues and employers | the change gives the project something, not just the code |
| `#### Tier 2` | the people who consume this product | a consumer would notice |

Each section carries **why it matters at that reach**, then **`Score: N`** — 1 to 5 against the rubric
`new-branch` prints when it writes the file. The tier decides which release documents the entry appears
in; the score decides where in each of them it sits.

**Four things about this shape, each of which someone has got wrong before:**

- **The heading is the title alone.** No PR number, no type, no date. It is the line every reader of the
  changelog and of all three release documents scans, so it says what changed and nothing more. The PR
  number and the merge date are added by the fold, on the entry's closing line — neither exists yet, and
  a date written now would be the branch's birth date rather than its landing date.
- **Nothing may use `##` or `###` inside the body.** A `##` becomes a *separate change* the moment the
  fold pastes this into `CHANGELOG.md` — one that declares no impact, so it reads as tier 0 — and a
  `###` collides with the three named sections, truncating whichever one it lands in. Use `####` or
  bold. The lint gate checks this. Inside `### Significance` the `####` level is structural, so there it
  is `Tier 0`, `Tier 1` or `Tier 2` and nothing else.
- **The three `###` sections are exact.** They are what the parsers look for; a misspelling means the
  entry silently loses that declaration and the gates read nothing.
- **The score is scaffolded empty**, and that is a question rather than a default. Tier 0 is a harmless
  final answer about *reach*, but any number written into `Score:` for you would be a guess at a
  ranking — and this repo has measured what a guessed ranking costs. The release cut refuses a release
  whose tier-1-or-higher entries have not answered.

A worked example, as it looks just before the PR:

```markdown
## The dead-link scan reaches the payload layers it never read

### What does this change do?

Agent defs, `agent-shared/`, `.github/` and `.claude/rules/` matched no rule in the scan set — 40 files,
and a real dead link had been sitting in one of them, seen by nothing.

### Significance

#### Tier 0

Four more rules in the scan set; nothing changes in how anyone works.

Score: 2

Is this change also relevant to colleagues and employers? Then continue to Tier 1.
If not, stop here and move on to the next section.

#### Tier 1

A dead link in the largest body of prose this repo ships is now caught before it merges.

Score: 3

Is this change also relevant to the people who consume this product? Then continue to Tier 2.
If not, stop here and move on to the next section.

### Type of change

Fix
```

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
recognises an entry by its heading level, and an entry heading is an `##`. So the trunk's own empty file
can never be folded as if it were a change, and folding twice is impossible rather than merely unlikely.

## Rules

1. **The entry holds the entry block and nothing around it** — no title, no branch line, no preamble.
   That is what makes it pasteable into `CHANGELOG.md` in one go, which is its whole reason for
   existing. The branch name lives in `branch-progress.md`, which has room for it.
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
4. **A step still carrying the scaffold's own placeholder is refused, ticked or not.** Ticking the
   scaffolded first step without replacing it reports a plan as finished that was never written.
5. **Fill in the Significance sections before the PR.** How far the change reaches decides which release
   documents the entry appears in; what it weighs there decides where in each of them it sits — see
   [`CONTRIBUTING.md`](../CONTRIBUTING.md).
6. **Never edit `CHANGELOG.md` from a branch.** Every branch would be editing the same region of the
   same file; that is the merge conflict this directory exists to avoid.

## What happens at the merge

[`scripts/release/fold-changelog-entry.ps1`](../scripts/release/fold-changelog-entry.ps1), run on `main`
right after the merge:

1. inserts the entry into `CHANGELOG.md` at its ranked position (furthest reach first, highest
   significance first within a tier), with the PR link and merge date appended as its closing line;
2. **resets both files** to the empty state you see on the trunk;
3. commits exactly those three paths.

The branch name it needs for the PR lookup comes from `branch-progress.md`'s own branch line — the file
name no longer carries it, which is why that line is in the document rather than only in the
scaffolder's head.

## Working from more than one machine

Park a branch with [`scripts/task/park-branch.ps1`](../scripts/task/park-branch.ps1), or create it with
`new-branch.ps1 -Park`: both commit **both** files and push, with no PR. The step list is the half that
says what was still in flight, so parking the entry without it defeats the point.

Before picking a parked branch back up, measure its plan against `main`. A plan that reads as current is
not evidence that it is — see the `park` skill for what to check and why.
