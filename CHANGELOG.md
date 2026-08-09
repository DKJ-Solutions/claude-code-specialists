# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `docs/the-release-body-names-the-action` changelog

### Branch title

The release body points at the instructions a consumer must follow

### Branch ID

20260809-125038

### Branch type

docs

### What does the change on this branch bring to main?

A lead-in block at the top of the `v3.10.0` internal summary, because that document is the **body** of
the published GitHub Release and this is the first release where the body has to send its reader
somewhere else to act.

**Why the internal note is the body at all**, since it reads like the wrong choice for a public page:
it is the only tier written for whoever is *deciding* rather than for whoever is *affected*, and a
release page is read by both. The procedure settles it and also names the consequence — where the
release requires the reader to act, the instructions live in the attached notes for users rather than
on the page, *"so say so in the body when that applies"*.

**It has never applied before.** Neither `v3.8.0` nor `v3.9.0`'s internal note carries such a pointer,
and that is correct rather than an omission: the clause is conditional, and no earlier release in this
repo stopped an existing installation from resolving. `v3.10.0` renames every plugin, so every consumer
must act before anything works again — which makes a body that leads with what the organisation gained,
and never mentions that the reader has something to do, precisely the wrong first screen.

Checked both previous notes before writing this rather than assuming a house pattern existed to copy.

### Significance

#### Tier 0

One block in one document. What it protects is the moment the release goes public, which is the one
moment none of the gates in this repo can reach.

**Score:** 2

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Barely, and honestly: it is a precedent more than a change. The conditional clause in the release
procedure now has its first worked instance, so the next person to cut a breaking release has something
to copy instead of a rule to interpret.

**Score:** 2

#### Tier 2

Is this next one still relevant for a consumer of the product?

Yes. The release page is where most people meet a release, and without this the first screen of
`v3.10.0` describes what the project gained while their installation has silently stopped resolving.
The block puts the action on that first screen and says where the steps are.

**Score:** 4

### Pull Request

[PR #543](https://github.com/DaveKJohn/claude-code-specialists/pull/543) · merged 2026-08-09

---

## `docs/v3-10-0-release-documents` changelog

### Branch title

The v3.10.0 release documents

### Branch ID

20260809-122825

### Branch type

docs

### What does the change on this branch bring to main?

The two documents `cut-release.ps1` deliberately does not write, for the release tagged earlier today:
the **internal summary** and the **consumer-facing highlights**. They arrive via a branch and a PR
because the release commit is already tagged, and neither is one of the two changes allowed to land
directly on the trunk.

**The highlights went from 593 lines to 92, and the cutting was most of the work.** The generated draft
is the tier-2 entries copied verbatim — still in the words their authors wrote for a reviewer of this
repo, complete with branch names, scores, and the internal reasoning behind each decision. A consumer
needs none of that. What survives is what they must do, what is new, and what was repaired, in that
order: the document opens on the reinstall rather than on the feature, because a reader scanning ten
lines has to learn that their install is about to stop resolving.

**It also carries forward the trap that a mechanical rename hides.** A consumer who never enabled the
old workflow plugin gets every team back and, silently, no workflow — nothing about their session
announces it, because enabling none is a legitimate state the new session check is deliberately quiet
about. That is stated as a property of the mechanism rather than by naming which repos it applies to;
who is in that position is this project's register, not the reader's business.

**The internal summary answers a different question and is written to it.** Not what changed, but what
the organisation gets: the naming was costing a decision on every addition to this product, the
reinstall is a one-off cost that gets more expensive with every consumer added rather than less, and
the largest reduction in dependence on a developer is the one easiest to miss — five scripts that each
kept their own answer to "which plugins exist and where do their folders sit" now read one, which is
why the directory move in this same release needed no production script change at all.

Its "what was still open" section is written as a **snapshot**, per the skeleton's own warning, and
records four things: the three connected repos had not migrated, a second checkout on another machine
was still on the old ids, the pre-seam lens caveat is documented rather than repaired, and this release
is `3.10.0` rather than `4.0.0` — the rule that a major recaps ten minors met a line that had nine, the
rule won, and the next release can be the major without overruling anything.

### Significance

#### Tier 0

The release is only finished once these two exist; until then the history page points at a note that is
a skeleton. Nothing else in the repo changes.

**Score:** 2

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Yes — the internal summary is written for exactly this reader, and it is the only document in the set
that answers what the release was worth rather than what it contained.

**Score:** 3

#### Tier 2

Is this next one still relevant for a consumer of the product?

Yes, and more than usual for a release-documents branch. Every existing install stops resolving with
this release, so the highlights are not a summary anybody may skip — they are where a consumer finds
out they have to act, and the one place that warns them a straight id swap can leave them without a
workflow.

**Score:** 4

### Pull Request

[PR #542](https://github.com/DaveKJohn/claude-code-specialists/pull/542) · merged 2026-08-09

---

## `docs/plugins-directory-readme` changelog

### Branch title

A README in plugins/ explaining the teams-versus-workflows split

### Branch ID

20260809-152615

### Branch type

docs

### What does the change on this branch bring to main?

`plugins/` gets its own README, completing the set the two subdirectories received a moment earlier:
it puts a team and a workflow side by side in one table — what each answers, what it ships, whether it
stacks, how it is named, and what enabling none of either kind costs — and then hands the reader the
test question that decides which kind a new plugin is: does this describe a *craft*, or a *way of
working*. It also names the two rules that guard the split and where each is checked (lint check 23
for the naming and placement, the core team's `workflow-sessioncheck` for the at-most-one count), and
what else lives in the directory without being a plugin: `agent-shared/`, `INSTALL.md`, `UNINSTALL.md`.

The page states the distinction; it does not restate the plugin table, which stays in the root README
as the single answer to "which plugins exist and who is each one for". The 9%/47% measurement that
forced the split is cited with its date rather than re-argued, so the page carries the reasoning
without becoming a second version of it. The root README's repo-layout bullet and both subdirectory
READMEs now link up to it.

### Significance

#### Tier 0

The split was explained only in the root README, roughly two hundred lines below the layout bullet
that names the directories. A developer in `plugins/` deciding whether a new plugin is a team or a
workflow now has the test question in the directory they are standing in.

**Score:** 2

#### Tier 1

Same, plus the part that is easy to get wrong once and never notice: the page says out loud that the
naming is load-bearing rather than cosmetic, because the session check counts workflows by their
prefix alone.

**Score:** 2

#### Tier 2

A consumer deciding what to enable browses this directory, and the choice they have to make — as many
teams as they like, but at most one workflow — is exactly what the page leads with. Until now the
first thing `plugins/` showed them was two folder names and two procedures.

**Score:** 3

### Pull Request

[PR #547](https://github.com/DaveKJohn/claude-code-specialists/pull/547) · merged 2026-08-09

---

## `docs/plugin-folder-readmes` changelog

### Branch title

A README in plugins/teams/ and plugins/workflows/

### Branch ID

20260809-150446

### Branch type

docs

### What does the change on this branch bring to main?

The two directories the plugins are split across each get their own README, so opening one no longer
means reading a list of folder names and guessing what binds them. Each page states what belongs in
that directory, the one rule that governs it, and what a folder inside it holds — for the teams: they
stack, and the `team-*` name plus its directory is held by lint check 23; for the workflows: at most
one may be enabled, why that check lives in the core team rather than in these plugins, and what
`workflow-davekjohn` expects from a repo's own seam. The root README's repo-layout bullet now names
both directories and links them, so the pages are reachable from the landing page rather than only by
browsing.

Both pages deliberately stop short of restating the plugin table. They name the folders and point at
the root README for the "who it's for" column, because a second copy of that table would be free to
disagree with the first and nobody reads both pages in one sitting — the failure this repo has already
paid for with the per-plugin `CHANGELOG.md` and `RELEASE.md` files.

### Significance

#### Tier 0

The split between teams and workflows was documented only in the root README, so a developer working
inside `plugins/` had to leave the directory to find out what governed it. Now the rule sits next to
what it governs. Small: they already knew the rule.

**Score:** 2

#### Tier 1

Same gain, plus one that outlasts it: the two naming rules that are load-bearing rather than cosmetic
— the `workflow-` prefix the session check counts by, and the directory each prefix implies — are now
stated where somebody adding a plugin is already looking.

**Score:** 2

#### Tier 2

A consumer receives the marketplace source as a clone of the whole repository, so these two
directories are what they browse when deciding which plugins to enable. Until now `plugins/teams/`
showed four unexplained folders and `plugins/workflows/` two, with the explanation a level up in a
1,000-line README. It is noticed the moment they open either directory.

**Score:** 3

### Pull Request

[PR #546](https://github.com/DaveKJohn/claude-code-specialists/pull/546) · merged 2026-08-09

---

## `fix/pr-body-heading-levels` changelog

### Branch title

The PR body headings start at H1

### Branch ID

20260809-131332

### Branch type

fix

### What does the change on this branch bring to main?

A PR body is now a document in its own right rather than a fragment of one. The entry's levels are
shifted up by one at the single point where the copy is made:

| in the entry and `CHANGELOG.md` | in a PR body |
|---|---|
| `## ` + the branch name | *(the PR title, not part of the body)* |
| `### What does the change on this branch bring to main?` | `# What does the change on this branch bring to main?` |
| `### Significance` | `## Significance` |
| `#### Tier 0` | `### Tier 0` |

**Why the levels differed in the first place, so nobody "corrects" them back.** In `CHANGELOG.md` an
entry is one `##` block among many, so its sections are `###` and its tiers `####`. That is right
there and wrong in a PR, where the entry is the whole document and its title is printed above the body
by GitHub. Carrying the levels across unchanged produced a body that opened at H2 with sub-sub-headings
at H4 — the typography of an excerpt. `CHANGELOG.md` and the release documents are untouched.

**One thing this could not be done without, and it is not cosmetic.** `-RefreshBody` replaces the
description by scanning forward to the next heading **at its level or shallower**. Promote the
description to H1 and leave `## Resolved issues` where it was, and that block is no longer a sibling of
the description but a child of it — so the next refresh deletes it along with the text it replaces,
GitHub closes nothing at the merge, and [the #341–#343 failure](https://github.com/DaveKJohn/claude-code-specialists/pull/343)
walks back in through the door built to stop it. `New-ResolvesBlock` therefore takes a level, and
`Add-ResolvesBlock` **derives** it from the body it is appending to rather than making a caller
remember: this repo's template is H1, a consumer's is still H2, and a hand-written `-Body` is whatever
its author wrote. Reading the answer off the text is the only form that is right for all three.

**A second thing that would have failed silently.** `-RefreshBody` located its target with `^##\s+\S`
— two hashes exactly, from a time when every template started at H2. Against an H1 template that
pattern finds nothing and the feature degrades to its warning branch on every run, reported as *"the
description was left as it is"*, which reads like a decision rather than a miss. It matches any level
now, and the suite asserts that from the script's own source.

**Back-compat, as always in this corner:** the fallback list of headings a PR may already be open under
gains the H2 form of the current wording — live for a single day, which is long enough for open PRs to
carry it. A consumer's template is untouched, keeps its levels, and keeps getting an H2 resolves block.
Promotion is fence-aware and floored at H1: a heading quoted inside a fence is sample text, and an entry
explaining this format would otherwise have its own example rewritten to say something else.

### Significance

#### Tier 0

Third and last pass over the PR body in one day, and the one that makes it read as a document. What it
also closes is two silent failures that the level change would have introduced on its own: a
`-RefreshBody` that eats the closing keywords, and a `-RefreshBody` that quietly stops working at all.

**Score:** 3

#### Tier 1

A reviewer opens a PR and sees a title, a question, and the answer — with Significance and its tiers
nested underneath rather than hanging at the same visual depth as the prose around them.

**Score:** 2

#### Tier 2

Consumers keep their own template and their own levels; the derivation exists so that stays true
without anyone configuring it. What reaches them is the repair of the two failure modes above, which
would otherwise bite the first consumer to promote a heading in their own template.

**Score:** 2

### Pull Request

Plugins: workflow-davekjohn

[PR #544](https://github.com/DaveKJohn/claude-code-specialists/pull/544) · merged 2026-08-09

---

## `fix/pr-body-starts-at-the-answer` changelog

### Branch title

The PR body starts at what the change brings

### Branch ID

20260809-122742

### Branch type

fix

### What does the change on this branch bring to main?

A PR body now opens with the sentence that describes the change. Yesterday's cut removed the form
around the entry; this removes the entry's own front matter, which the page around the body was
already saying.

**What a reviewer met before the first substantive line**, measured on
[PR #540](https://github.com/DaveKJohn/claude-code-specialists/pull/540):

| line | why it added nothing |
|---|---|
| the **Branch title** | it **is** the PR title — `open-pr` composes `fix: <this>` from the same section and GitHub prints it above the body |
| `### Branch ID` | a creation timestamp; there is nothing a reviewer can do with it |
| `### Branch type` | the PR's **label**, and the prefix of the title one line up |

And at the bottom, an empty `### Pull Request`: the **fold** fills that section, from the merge — so in
a PR body it is a heading with nothing under it, every time, by construction.

The template's heading is therefore the entry's own question, which is what it should have been
yesterday. The reason it was not is that the wrapper sat *above* the whole dossier, so using the
question there would have printed it twice, four lines apart. Dropping the front matter is what makes
the obvious heading correct:

```markdown
## What does the change on this branch bring to main?
<!-- Filled from branch/branch-changelog.md. Opening a PR by hand? Paste that file's body here. -->
```

**`### Significance` stays, and that is a judgement rather than an oversight.** It is not front matter:
it is the author saying how far the change reaches and what it is worth to each audience, which is the
thing a reviewer is deciding about.

**`CHANGELOG.md` is untouched.** The fold still receives the dossier verbatim — branch line, ID, type
and all — which is what was chosen on August 6, 2026 and what the release documents inherit. The two
readers now differ because their readers do: a record wants provenance, a review wants the argument.

**The back-compat half is one line and it is the whole story.** `Get-PrDescription` returns `''` when
the entry has no `What does the change...` section, and `open-pr` then falls back to
`Get-EntryDescription` — today's behaviour, verbatim. A pre-dossier entry kept its description straight
under the heading, and every consumer with a branch in flight has one; they receive this script through
a plugin update rather than by choosing to. The retired section name is read too, for the same reason,
and `-RefreshBody` gained `## Changelog entry` in its fallback list so the PRs opened under yesterday's
heading stay refreshable.

**Fence-aware, and not hypothetically:** this entry quotes those headings inside a fence. A reader that
cut at the first `### Pull Request` it saw would end the description mid-entry and return something
plausible rather than failing — the worst shape, and the one this format's other readers were already
built against.

### Significance

#### Tier 0

Every PR opened here starts at the argument instead of at three restatements and a timestamp. Small per
PR, and it lands on every single one — the same reasoning as yesterday's cut, applied to what that cut
left standing.

**Score:** 3

#### Tier 1

A reviewer's first screen is now the change rather than provenance. What it prevents is the habit that
follows from a body with a preamble: scrolling past the top of it by default, which is how the
Significance sections would have stopped being read.

**Score:** 2

#### Tier 2

Consumers get the trimming through a plugin update, and their pre-dossier entries are explicitly
unaffected — the fallback keeps those PRs exactly as they were. What is worth naming is the failure it
prevents for them: a consumer who adopts the dossier form does not have to discover for themselves that
the PR body repeats its first three fields.

**Score:** 1

### Pull Request

Plugins: workflow-davekjohn

[PR #541](https://github.com/DaveKJohn/claude-code-specialists/pull/541) · merged 2026-08-09

---

## `fix/an-unmigrated-consumer-is-not-a-defect` changelog

### Branch title

A consumer registered under a retired plugin id is reported as unmigrated, not invalid

### Branch ID

20260809-132431

### Branch type

fix

### What does the change on this branch bring to main?

The connector check reported four `[ERROR]` lines against `life-hub` and `smartwatchbanden` for holding
`specialists@…` and `specialists-shopify@…` — ids that are correct for those repos, recorded on
purpose, and which `connectors/README.md` had been updated one branch earlier to say are kept
deliberately until each consumer migrates. **The check and the doctrine contradicted each other, and
the doctrine was right:** this register records what a consumer *has*.

**Three ways to miss had collapsed into one verdict.** `Get-PluginDir` returned a bare `$null` and the
caller called every case *"invalid or unknown plugin field"*. That was survivable while the lookup was
a directory probe, because the only way to miss was a name nobody publishes. Resolving through the
marketplace added a second way, and it is not a fault at all — a plugin renamed upstream leaves every
consumer holding the old id until they reinstall. The reasons are separated now:

| status | what it means | verdict |
|---|---|---|
| `malformed` | the id is not a slug at all | `[ERROR]` — a register file defect |
| `retired` | a well-formed name the marketplace no longer declares | `[INFO]` — they have not migrated |
| `no-source` | declared, but the folder is missing here | `[ERROR]` — a defect in this checkout |

An `[INFO]` is the right level rather than a softer error: the session hook surfaces only `[ERROR]`, so
this shows on a deliberate run and does not interrupt anyone's session start over the state of somebody
else's repo — the same rule the register's other administrative markers already follow.

**How it got here is the part worth keeping, because no single step was wrong.** One branch made the
check ask the marketplace instead of joining a path. A later one removed the old names from that
marketplace. A third wrote down the doctrine the check had by then been contradicting for two branches.
Each was reviewed on its own; what no review caught was the interaction between them.

The lesson is sharper than "review interactions", which nobody can act on. It is that **a document
describing a mechanism is not evidence about that mechanism.** The doctrine paragraph was written from
the design, published, and passed every gate — while the thing it described was reporting the opposite.
Nothing measured the two against each other until the check was run for an unrelated reason. That
paragraph now carries the episode, so the next person to write a rule about a check has a reason to run
it first.

### Significance

#### Tier 0

The connector check is red at every deliberate run until this lands, on four lines that are correct.
A gate that cries wolf about a correct state is one people learn to skip.

**Score:** 3

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Yes, and it is the reason the check exists at all: it is the only thing that reports on the connected
repos, and it had started reporting a normal, expected phase of a migration as a defect — precisely
during the migration it was meant to help track.

**Score:** 3

#### Tier 2

Is this next one still relevant for a consumer of the product?

No. The register and its check live in this repo and read consumers from the outside; nothing about a
consumer's own sessions changes, and no consumer runs this script. What changes is what *we* see when
we look at them.

**Score:** N/A

### Pull Request

[PR #545](https://github.com/DaveKJohn/claude-code-specialists/pull/545) · merged 2026-08-09

---

