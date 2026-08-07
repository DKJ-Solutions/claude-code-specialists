# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it three
named sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the impact table, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — the impact table
under *Who is this for*. That is what orders this list: furthest reach first, and within a tier the most
consequential change first. It also decides what may be released: **a release needs at least one tier-1
entry**, **a minor needs a tier-2 one**, and a **major** recaps ten minors. So a changelog holding nothing
but tier 0 is a changelog with no release in it yet.

---

## `feat/branch-file-form` changelog

### Branch description

The branch files take the form Dave designed

### Branch ID

20260807-000213

### Branch type

feat

### What does the change on this branch bring to main?

The two files a branch works in now carry the form Dave designed, and `branch/templates/` holds it as the
spec rather than as a copy: the generator reproduces both files **byte for byte**, so they were never
edited to match the code. The entry became the branch's own dossier -- the heading names the branch, and
six sections carry the description, a creation timestamp, the type, what the change brings to `main`, the
Significance sub-sections and a `Pull Request` section the fold fills from the merge.

Every field is now a heading with a guidance comment above an empty space, which retired the last visible
`TODO:`. So the scaffold gate stopped matching prose and started **measuring**: it refuses an entry whose
description, body or any tier's reason is empty once the comments are stripped -- strictly more than the
strings caught, because it also catches a placeholder deleted rather than answered. Every older shape is
still read: the retired section headings, the plain `Score:`, the one-line routing questions and the
`Tier: N` line.

Three defects surfaced while wiring it, each found by a check rather than by a report. The fold never
called the comment stripper written for it, so every guidance block would have folded into `CHANGELOG.md`
verbatim. The step gate read the three example marks out of its own guidance comment, reporting four open
steps on a fresh branch -- three of which no one could resolve, since they return with the next scaffold.
And `Resolve-EntryType` took the first line of its section, which is now the hint, so every new entry
declared its type to be `<!-- options for type are: feat, fix or docs-->`.

### Significance

#### Tier 0

Filling either branch file is now a form with the guidance beside each box, and the three defects above
would each have reached `main` silently.

**Score:** 4

#### Tier 1

Every branch in this project starts from these two files, so the shape is the first thing anyone working
here meets -- and the gates that read it decide what a release can be cut from.

**Score:** 3

#### Tier 2

The scaffolder and the gates are plugin-carried, so a consumer's next `new-branch` writes this form
whether or not they went looking for it. Nothing they already have breaks -- every older shape is still
read, deliberately -- but the file they open on their next branch looks different.

**Score:** 4

### Pull Request

Plugins: specialists

[PR #498](https://github.com/DaveKJohn/claude-code-specialists/pull/498) · merged 2026-08-07

---

## The impact table becomes a Significance section with one sub-heading per tier

### What does this change do?

`### Who is this for` and its impact table are replaced by `### Significance`, holding one
`#### Tier N` sub-section per reach the change claims -- each with why it matters at that reach, then
its score, then a question asking whether there is a next tier:

```text
#### Tier 0

The routine version bump stops needing a developer.

Score: 4

Is this change also relevant to colleagues and employers? Then continue to Tier 1.
If not, stop here and move on to the next section.
```

**The table went because it forced a rectangle onto something that is not always rectangular.** Not
every change has a tier 1 or a tier 2. In a table that absence is a missing row, which reads as an
omission; as a section it is simply absent, which reads as an answer. The heading stopped naming an
audience for the same reason the shape changed: each sub-section names its own by its number, and what
the section carries is how much the change *weighs* for each of them.

**Every section closes by asking whether there is a next one, including one whose successor is already
below it.** An earlier draft wrote the question only under the last section, reasoning that a tier
whose successor exists has been answered. True of the author, false of every later reader: the entry is
walked again at the fold, at the cut and in the record, and a question that disappears once answered
leaves them unable to see that it was asked.

**Three shapes are read and one is written.** The sub-sections, the impact table, and the older
`Tier: N` line -- because `CHANGELOG.md` holds all three right now, every consumer's tree holds at
least one, and they reach the new parser through a plugin update rather than by choosing to. A parser
that knew only the newest shape would read every other entry as tier 0: silent, correct-looking, and
wrong in the direction that empties a release.

**The retired section heading is recognised too, and that one was measured rather than foreseen.** The
moment `Who is this for` became `Significance`, the lint reported all 24 pending entries in this repo's
own changelog as *misspelled* section headings -- its most alarming finding and its least true. Twenty-four
false accusations at once is how a check gets switched off rather than heeded, so a name-matcher now
accepts the retired names alongside the current ones.

Two defects were found by their own tests while building this, both worth naming because both fail
silently:

- **`[ref]` to a property of a `pscustomobject` writes to a copy.** The section reader collected its
  complaints through one, so every malformed section parsed, reported nothing, and fell through to the
  legacy reader as an undeclared tier 0 -- the exact failure class this parser exists to prevent, inside
  the parser. It returns the pair instead now, which cannot go wrong at all.
- **An entry whose every section is malformed has zero rows**, and falling through on that count alone
  would have discarded the complaints with it. Errors now count as "this entry used the section shape"
  just as rows do.

### Significance

#### Tier 0

Four readers of the entry format changed together -- the writer, the parser, the strippers and the lint
gate -- and the parser now recognises three shapes where it recognised two.

Score: 3

Is this change also relevant to colleagues and employers? Then continue to Tier 1.
If not, stop here and move on to the next section.

#### Tier 1

The declaration stops pretending every change reaches every audience. An entry that matters only to this
repo says so by having one section, instead of by leaving two rows visibly blank in a table that asked
for them.

Score: 3

Is this change also relevant to the people who consume this product? Then continue to Tier 2.
If not, stop here and move on to the next section.

#### Tier 2

Every consumer's entry format changes shape, and their existing entries keep working only because all
three shapes are still read and the retired heading is still recognised. Nothing they have written needs
rewriting; the next entry they write looks different.

Score: 3

### Type of change

Feat

Plugins: specialists

[PR #496](https://github.com/DaveKJohn/claude-code-specialists/pull/496) · merged 2026-08-06

---

## `docs/branch-name-rule-why` changelog

### Branch description

The branch-name rule records why it exists

### Branch ID

20260807-100032

### Branch type

docs

### What does the change on this branch bring to main?

`Test-BranchName` refuses a branch name containing `final`, and now records **why** and **what to do
instead**. The rule is Dave's — *"je weet nooit zeker of iets echt final is"* — so a name claiming to be
the last word is a prediction, and a wrong one forces the next round to be called `final-2`. The remedy is
a version suffix (`fix/template-newline-v2`), which makes no such claim.

The refusal message says so too. It used to be `"Branch name must not contain the token 'final'."` and
nothing else, so the obvious next guess was `finished` or `done` — the same claim in a different word.

The docstring also records that the **opposite** rule once existed, before anyone restores it: a `-v2`
suffix used to be forbidden, because the fold looked an entry up by the exact branch name and a suffix
broke both the match and the cleanup after it. The `branch/` split retired that — the fold reads the branch
out of the document now — so nothing rejects `-v2`, deliberately.

Attributed to Derek in that docstring until the reasoning was actually asked for, which is how a decision
ends up looking like a habit somebody picked up.

### Significance

#### Tier 0

A gate that only says "not that" gets guessed at; this one now answers the question it provokes, and the
reasoning behind a hard rule is on the page instead of in one person's head.

**Score:** 2

#### Tier 1

Anyone creating a branch here meets this refusal sooner or later, and the retired `-v2` prohibition is
exactly the kind of dead rule a later reader reinstates in good faith.

**Score:** 2

### Pull Request

[PR #500](https://github.com/DaveKJohn/claude-code-specialists/pull/500) · merged 2026-08-07

---

## `fix/template-trailing-newline` changelog

### Branch description

The progress template ends with a newline

### Branch ID

20260807-091625

### Branch type

fix

### What does the change on this branch bring to main?

`branch/templates/branch_template_progress.md` ends with a newline. It had none: an accident of the editor
the form was designed in, reproduced faithfully by `Get-BranchTemplates` while the hand-written templates
were being treated as the spec for the shape. A file without a terminator is the one whose next diff shows
a line nobody edited, and git says so on every one of them.

### Significance

#### Tier 0

One byte, and it stops every future diff of that file carrying a phantom line.

**Score:** 1

### Pull Request

Plugins: specialists

[PR #499](https://github.com/DaveKJohn/claude-code-specialists/pull/499) · merged 2026-08-07

---

## The v3.6.0 release documents: the internal note and the edited highlights

### What does this change do?

**The two hand-written documents of the v3.6.0 cut**, landing the ordinary way because the release commit
was tagged before either existed: the internal note written from its generated skeleton, and the highlights
draft rewritten for the reader it is actually for.

**The highlights went from 1,132 lines to about 110, and that is a rewrite rather than a trim.** The draft
is the seventeen tier-2 entries in the words their authors wrote for someone reviewing a diff; a consumer
is deciding whether to update. The structural decision was to promote the **three items that ask something
of the reader** — stripping the scaffold marker from filled lens titles, migrating a changelog that still
has section headings, and the moved documentation URLs — out of the body and into a numbered block at the
top, with everything else stated as "nothing else requires action". That is the tier model applied to the
document's own layout: two of those three are the release's only significance-5 rows, and burying a
required migration two thirds of the way down is the failure the ranking exists to prevent.

**The internal note names two things it deliberately did not fix**, because this tier is where an
organisation reads what a release was worth and an unstated known defect is worth less than a stated one:
the mojibake check cannot tell a quoted example from a real occurrence — it flagged the entry that
described the problem, the fifth instance of that shape here — and 7 of 326 dated headings in the published
history are a day or two out, left alone because they sit in records that already travelled. Both are
recorded as Dave's call rather than as open work anybody has taken.

**One line in the note is about this release's own near miss**, and it is phrased as a question rather than
a finding: the empty-section defect was caught by `-NoPush`, the one step where a person sees the assembled
document before it is public, and that step is optional. Whether it should stay optional was not decided
here.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 0 | - | - |

### Type of change

Docs

[PR #495](https://github.com/DaveKJohn/claude-code-specialists/pull/495) · merged 2026-08-06

---

