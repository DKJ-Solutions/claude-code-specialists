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

## `fix/consumer-templates` changelog

### Branch description

A consumer repo gets the branch templates too

### Branch ID

20260807-132519

### Branch type

fix

### What does the change on this branch bring to main?

`new-changelog-entry.ps1` writes `branch/templates/` into the repo it runs in, and rewrites a copy that has
drifted from the current format.

**This repairs a regression that shipped in v3.7.0**, found by red-teaming a documentation proposal rather
than by anyone reporting it. Until now **nothing created those templates anywhere**: they exist in this repo
because they were written by hand, and the check that holds them to `Get-BranchTemplates` is repo-owned --
`plugins/specialists/scripts/lint/` does not exist, so no consumer has ever had it. When the working files
became bare in v3.7.0, this repo's guidance moved to `branch/templates/` and a consumer's simply went away:
their scaffolder stopped writing it and they had nowhere to read it. Their only remaining description of the
form was the skill page.

The measurement was one question asked of the code instead of assumed -- *does "see the templates" resolve
in a consumer repo?* -- and the answer was no.

**Refreshed rather than only created**, which is the half that keeps working. A copy written once is correct
on the day the branch directory appears and stale from the next release on; rewriting a drifted one carries
a format change into a consumer's reference through the same plugin update that carries it into their
scripts. That follows the rule the templates already carry: generated, not maintained.

Pinned by tests in a fixture that **is** a consumer -- shared scripts only, no lint, no hand-written
templates -- so the case that broke is the case under test.

### Significance

#### Tier 0

Nothing changes here: this repo already had the templates, and the writer now rewrites them to the same
bytes the lint already demanded.

**Score:** 1

#### Tier 1

A shipped regression is closed within hours of shipping, and it was caught by an adversarial review of a
proposal rather than by a consumer hitting it. Worth knowing as evidence that the review step earns its
place.

**Score:** 3

#### Tier 2

A consuming repo gets the guidance back, on its next branch and without doing anything. Since v3.7.0 their
branch files have been bare with no reference to read; this restores it and keeps it current from now on.

**Score:** 4

### Pull Request

Plugins: specialists

[PR #503](https://github.com/DaveKJohn/claude-code-specialists/pull/503) · merged 2026-08-07

---

## `feat/pr-title-is-derived` changelog

### Branch title

The PR title is derived: the type from the branch, the words from the entry

### Branch ID

20260807-185602

### Branch type

feat

### What does the change on this branch bring to main?

The PR title is no longer typed. `open-pr.ps1` composes it as `<branch type>: <the entry's title section>`
-- the type off the branch prefix, the words out of `branch/branch-changelog.md` -- so the sentence is
written **once**, at `new-branch -Title`. The entry's first section is renamed to match what it actually is:
`### Branch title`, not `Branch description`.

Two issues, one change, because they are the same defect from two sides:

- **[#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506)** -- the same sentence was typed
  twice, once into the entry at creation and once into `open-pr -Title` at the end, with nothing holding
  the two together. One of them is what `CHANGELOG.md` and the release documents carry; the other is what
  the PR is called; and which one a reader met depended on where they were standing.
- **[#505](https://github.com/DaveKJohn/claude-code-specialists/issues/505)** -- Derek's manual has always
  said the PR title mirrors the branch type. Measured August 7, 2026: the last **five** merged PRs
  (#499-#503) all lacked it, while every commit and every merge line in the graph carried its type. Same
  shape as `chore/` and the `final` rule -- a rule that lives in a document, is never measured, and is
  therefore silently broken. Composing the title fixes it by construction rather than adding a third check
  on the second answer.

**`-Title` is accepted and ignored, not removed**, and warns once, naming the title the entry actually
gives. Every branch in flight -- here and in every consumer -- passes one right now, and consumers receive
these scripts through a plugin update rather than by choosing to; a removed parameter turns all of those
into "A parameter cannot be found" at the end of a finished branch. An **override** was the alternative and
Dave declined it in the issue: an override is a second source of the title, which is the thing being removed.

**A PR is never created nameless.** The emptiness gate already refuses an entry with no title, but `-Force`
waves that gate through, so the create path checks again and names the entry rather than letting `gh`
complain about a flag.

**And a pre-split entry still opens a PR.** Such an entry has no title section at all -- its title WAS the
heading -- so the words fall back to that heading with its administrative fields dropped, via
`Convert-EntryHeadingToTitle`, the same rule the highlights document already uses. The fallback keys on the
section being ABSENT rather than empty: an entry that has the section and left it blank is an author who
has not written the title yet, and falling back there would hide that behind a plausible-looking PR.

**Two readers were quietly wrong, and the rename is what exposed them.** Both asked a per-section question
of the flattened list of every retired heading -- sound only while every retired name happened to belong to
a section no other document carried:

- the significance stripper would have accepted an entry's empty **title** heading as the significance
  block's and deleted it;
- the entry-versus-step-list discriminator would have read the step lists of early August -- which carry
  `Branch description` -- as **entries** again, the exact confusion the two-file split was made to remove.

Both ask their own section now. Nothing is lost by the narrowing: an entry old enough to carry
`Type of change` carries two other retired entry-only headings as well.

**The lint needed the same repair one section to the left.** Its split-entry rule knew the retired names of
`What` but not of the opening section, so the moment that section was renamed all six pending entries were
reported as SPLIT -- two dozen false accusations is how a check gets switched off rather than heeded, which
this repo has now measured three times. A rename is not a one-line change while any reader knows only the
new name.

**One fixture was proving the legacy path against a legacy format that never existed.** It carried
`### Title - Feat - 2026-07-21`; that hyphen shape appears **zero** times across `releases/`, where every
entry uses middots. Harmless while nothing parsed the heading -- and the PR title now does, so the fixture
would have asserted the wrong title. Corrected to the shape the record actually uses.

### Significance

#### Tier 0

Two facts that had to agree by hand now agree by construction, and the one that was never checked -- the
type prefix -- cannot be omitted at all. The rename also cost two silent reader bugs their hiding place.

**Score:** 4

#### Tier 1

The PR list becomes readable by type at a glance, as the commit graph already was. Nobody has to remember a
convention that five consecutive PRs forgot.

**Score:** 3

#### Tier 2

`open-pr`, `ship-pr`, `new-branch` and the entry format are all plugin-carried, so a consumer's PR titles
start composing themselves and their entries gain a renamed first section -- read under both names, so
nothing they have in flight breaks. Their `-Title` calls keep working and say so.

**Score:** 3

### Pull Request

Plugins: specialists

[PR #515](https://github.com/DaveKJohn/claude-code-specialists/pull/515) · merged 2026-08-07

---

## `fix/release-runs-the-suites` changelog

### Branch description

The release passes the same test gate every PR does

### Branch ID

20260807-171359

### Branch type

fix

### What does the change on this branch bring to main?

`cut-release.ps1` runs all the test suites before it writes anything, with `-SkipTests` as the escape
valve. Until now it ran the **lint alone**, which made the release commit the least-checked commit in the
whole workflow:

| | lint | the 26 suites | CI |
|---|---|---|---|
| every ordinary PR | yes | yes | yes, and blocking |
| the release | yes | **no** | yes, but after the fact |

That is the commit which bumps four plugin versions in lockstep, rewrites four `RELEASE.md` cards,
regenerates the per-plugin changelogs and empties `CHANGELOG.md`. A red suite could be committed, tagged
and pushed, with CI reporting it only once the tag was already on it.

**The gate is shared, not copied.** `open-pr` has run the suites since PR #54's lesson, and the obvious
repair was to paste its fifteen lines into the cut. That is the duplication this repo spent the day
removing in six other places -- two copies of one rule, free to drift, and the one that drifts is whichever
nobody looked at. The loop moved into `Invoke-TestSuiteGate` and both callers use it. Its home
(`native-capture-lib.ps1`) is an imperfect fit and the header says so: both callers already load it and
running child processes is what it does, weighed against the cost of a new shared file -- a registry entry,
a mirror and a contract row for one function.

**What this still cannot see, stated so nobody reads more into it.** The suites run against the tree
*before* the cut, so a defect the cut itself introduces -- a malformed `RELEASE.md` card, a broken
generated note -- is invisible to them. CI on the `main` push catches that afterwards. The two are
complementary and neither replaces the other.

**A correction that came with the measurement.** The original issue claimed CI does not run on the release
at all, reading `Bypassed rule violations` as proof. It does run, and the v3.7.0 run was green -- what was
bypassed is the *ruleset* that would have held the push back, not the workflow. The real gap was narrower
than first reported, and the issue now says so rather than being quietly rewritten.

### Significance

#### Tier 0

The one commit that cannot be un-pushed cheaply is now checked as thoroughly as a documentation typo, and
before it is written rather than after.

**Score:** 4

#### Tier 1

A release is the moment the project speaks to everyone at once. Cutting one on a red suite would be found
by whoever reads the notes, not by whoever cut them.

**Score:** 3

#### Tier 2

`cut-release` is plugin-carried, so a consumer's releases gain the same gate and the same `-SkipTests`
escape valve. Their cut takes longer by exactly the time their own suites take.

**Score:** 3

### Pull Request

Plugins: specialists

[PR #514](https://github.com/DaveKJohn/claude-code-specialists/pull/514) · merged 2026-08-07

---

## `docs/v3-7-0-release-documents` changelog

### Branch description

The v3.7.0 release documents

### Branch ID

20260807-123726

### Branch type

docs

### What does the change on this branch bring to main?

The two hand-written documents of `v3.7.0`: the internal summary and the customer-facing highlights. The
cut generates a draft of each and names them as deliberately unwritten; this is that writing, shipped the
way every other change is, because the release commit is already tagged and neither document is one of
the two direct-on-`main` exceptions.

Both drafts arrived carrying **branch administration** -- branch names as the subject of a bullet, internal
IDs, the branch type -- which the dossier form put there and which means nothing to either reader. Edited
out by hand here. Worth recording rather than only fixing: it is avoidable work at every release, and the
generators could strip it the way they already strip the significance scores.

### Significance

#### Tier 0

Nothing changes in how anyone works here; two documents that did not exist now do.

**Score:** 1

#### Tier 1

The internal summary is the one document that says what the organisation got out of the release, and it is
also the body of the published GitHub Release -- so it is the version of this release most people outside
the work will ever read.

**Score:** 3

#### Tier 2

The highlights are written for the people who consume this product, and they are what a consumer meets
when they update. Rewritten from the draft so they describe the new branch-file form rather than quoting
the branches it arrived on.

**Score:** 3

### Pull Request

[PR #502](https://github.com/DaveKJohn/claude-code-specialists/pull/502) · merged 2026-08-07

---

## `docs/ship-pr-is-the-whole-chain` changelog

### Branch description

ship-pr is the whole chain, and the merge subject has one format

### Branch ID

20260807-163845

### Branch type

docs

### What does the change on this branch bring to main?

Two repairs, both of defects introduced or exposed on August 7, 2026, and both found because Dave asked a
plain question: *is thirteen minutes normal for opening a PR?*

**`ship-pr` is the whole chain, and the lens no longer points away from it.** Its step 1 *is* `open-pr` --
gate, push, open -- after which it waits for CI, merges and folds. One command, one gate run. Running
`open-pr` first and then `ship-pr` therefore puts the lint and all 26 suites through **twice**, about 13
minutes each, on top of the ~11 CI spends on the same commit. Measured: seven PRs that day, roughly **91
minutes** spent on a check that had already passed.

That was a way of working rather than a design flaw -- but the documentation led into it. Derek's
"Merging to main" showed a bare `gh pr merge` and never named `ship-pr` at all. It now names it first, and
demotes the by-hand sequence to the fallback it always was. The `open-pr` step says when to reach for it
alone: when you are deliberately stopping at the PR.

**And the merge subject has one format again.** `ship-pr` began writing `merge: PR #NN <branch>` that
afternoon while Derek's lens had prescribed `merge: <branch> (#NN)` since `ba7081e` -- because the lens was
not read before the shape was chosen. Two formats for one line is precisely the defect the same day's work
removed in five other places, reintroduced by the change that removed it. The older one wins: it matches
the fold commit beside it field for field.

```text
merge: feat/x (#504)
chore: fold changelog entry feat/x (#504)
```

Both are now written down beside each other, in the script and in the lens, with the note that this was
invented twice -- so the next person choosing a shape reads that before choosing.

### Significance

#### Tier 0

Roughly 13 minutes back on every PR that goes all the way through, and the graph keeps one shape for its
merge lines instead of two.

**Score:** 4

#### Tier 1

The documentation pointed at the expensive route, which is why the expensive route was taken seven times
in a day. That is worth more than the minutes: a lens that describes a slower path than the one the
scripts implement will be followed.

**Score:** 3

#### Tier 2

`ship-pr` and its skill page are plugin-carried, so a consumer's merge commits change shape once -- and
the same two-step trap is documented away for them too.

**Score:** 2

### Pull Request

Plugins: specialists

[PR #513](https://github.com/DaveKJohn/claude-code-specialists/pull/513) · merged 2026-08-07

---

## `feat/bump-follows-the-tiers` changelog

### Branch description

The bump follows the tiers, and so does the audience of each note

### Branch ID

20260807-153354

### Branch type

feat

### What does the change on this branch bring to main?

The release bump is now read straight off the highest tier pending:

| highest tier pending | bump | documents |
|---|---|---|
| `0` | patch | the development notes |
| `1` | minor | + the internal note |
| `2` | minor | + the highlights, for consumers |

**Two rows changed, and both loosen the ladder by one step.** A release made entirely of tier-0 work used
to be **refused outright** -- the gate's reason was that such a release "has nobody to announce it to".
Dave's answer is that announcing nothing is precisely what a patch is for: the version moves, the record
is written, and no announcement is owed. And a **minor** used to demand a tier-2 entry, so tier-1 work
earned only a patch.

**The second was weighed rather than waved through.** It means a release can bump the minor with nothing
in it for a consumer, which is the opposite of what a minor usually promises. It was put to Dave that way
and chosen knowingly: the version here speaks to *all* stakeholders, colleagues included, not to consumers
alone.

**What keeps that honest is that the documents follow the TIER, not the bump.** A tier-1-only minor writes
the internal note and no highlights, so nobody outside is handed a document about work they cannot see.
That needed no change -- the highlights condition already required a tier-2 entry alongside the bump type.
What changed is its standing: it was belt-and-braces while a minor demanded tier 2, and is now the only
thing holding that line.

**A defect went in and came straight back out, caught by the suite.** The new refusal was written for
`minor` alone, which would have let a **major** through on tier-0-only work -- a bigger claim than the one
being refused beside it. Eight asserts failed the moment the rule changed, exactly the ones that encoded
it, and that was one of them.

### Significance

#### Tier 0

Two release outcomes that used to be impossible are now ordinary, so a maintenance week no longer sits
unreleasable waiting for something notable to land.

**Score:** 3

#### Tier 1

This is the rule that decides which release documents get written at all, and therefore what a colleague
ever hears about. Tier-1 work now earns a version of its own instead of riding along as a patch.

**Score:** 4

#### Tier 2

A consumer's version number will move for releases that contain nothing for them -- that is the deliberate
cost of the looser rule. What protects them is unchanged: they still receive a highlights document only
when a tier-2 entry exists, so the version moves without a document that has nothing to say.

**Score:** 2

### Pull Request

Plugins: specialists

[PR #511](https://github.com/DaveKJohn/claude-code-specialists/pull/511) · merged 2026-08-07

---

## `feat/one-script-per-concept` changelog

### Branch description

new-branch is one script instead of two

### Branch ID

20260807-140842

### Branch type

feat

### What does the change on this branch bring to main?

`new-changelog-entry.ps1` is gone; `new-branch.ps1` does the whole job. Creating a branch and writing the
files it works in were one concept split across two scripts, and the second one's name had stopped being
true twice over: the `branch/` split gave it a step list to write, and the templates repair gave it two
more files. It described **one of four outputs**, and no document told anyone to run it -- it had no skill
of its own and nothing but `new-branch` ever called it.

**What the split was actually buying, since it was not nothing.** The inner script used `exit` as control
flow, and running it as a child process is what kept those exits from killing the caller. Each was answered
rather than deleted:

- the missing-`branch-info.ps1` pre-flight was **already** in the outer script -- a duplicate, now gone;
- the trunk refusal **moved up, in front of the checkout**, so it refuses before touching `HEAD` instead of
  after. It looks like dead code (`Test-BranchName` rejects `main`) and is not: that check only knows the
  literal `main` while the trunk is configurable, so a consumer whose trunk is `master` still reaches it.
  Deleting it as unreachable would have broken exactly that consumer;
- *"the files already exist"* was an `exit 0` the caller read as success and carried on from. It is a
  **skip** now, which is what it always meant -- as an inline `exit` it would have ended the run and a
  `-Park` would silently not have happened.

The injection-safe environment-variable handoff went with the process boundary: `-Title` and `-Intent` are
ordinary parameters again, because there is no argv to requote across. The test that guarded that handoff's
precedence went with it, and the half of it worth keeping was already asserted elsewhere on a nastier
payload.

**The 93-assert `new-branch` suite is what made this safe**, and it is why the merge was worth attempting
at all: it runs the real script end to end, so a behaviour that survived the splice is one those asserts
saw.

**Two more things the branch workflow says out loud now, both about the same thing: making every line of
the history state its own type.**

**`chore/` is refused as a branch prefix.** There are three -- `feat`, `fix`, `docs` -- because chore is
the name for work that lands *directly on the trunk* under one of the named exceptions, so a chore branch
is a contradiction. The commit log agrees emphatically: 15 of the last 30 first-parent commits are
`chore:` and every one is a direct commit. **The rule always held and was never enforced**: measured on
the day it was written down, `chore/` had been used 12 times, and Dave's answer on seeing that count was
that all twelve were wrong at the time too. `Chore` stays a recognised changelog **type** -- entries
already carry it, and it is still the fallback for an unknown prefix. Refused in `Test-BranchName` rather
than merely dropped from the table: that file is repo-owned and does not travel, so this states our rule
without touching a consumer who runs chore/ branches of their own.

**The merge commit is named `merge: PR #NN <branch>`.** GitHub's default,
`Merge pull request #NN from Owner/branch`, was the one line in the graph with no type in front of it
while everything around it had one -- so scanning the history meant reading two shapes. It now pairs with
the fold commit that follows it. Checked before changing: nothing parses that subject.

### Significance

#### Tier 0

One script fewer to keep in step, one name that no longer lies, and a duplicated pre-flight removed. The
trunk refusal also got strictly better -- it now fires before `HEAD` moves.

**Score:** 3

#### Tier 1

Every line in the git graph now starts with its type -- `feat:`, `fix:`, `docs:`, `chore:`, `merge:`,
`release:` -- so the history reads as one shape instead of two. That is what a colleague scanning back
through a week of work actually uses. It also closes a rule that had been silently unenforced twelve
times, and records why the release stays off a PR, in Dave's own words.

**Score:** 3

#### Tier 2

A shared script disappears from the plugin. Nothing documented ever told a consumer to call
`new-changelog-entry.ps1` -- it had no skill page, and `new-branch` is what every document names -- so
following the documented path is unaffected. Anyone who wired their own tooling to it directly must point
that at `new-branch.ps1`.

**Score:** 2

### Pull Request

Plugins: specialists, specialists-shopify

[PR #504](https://github.com/DaveKJohn/claude-code-specialists/pull/504) · merged 2026-08-07

---

