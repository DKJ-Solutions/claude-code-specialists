# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections answering what a reader arrives with — what the change deploys to `main`, and the PR.
The first holds the change's two audiences, the second of them under `#### What makes this change extra
special`; the tier numbers live in the parser rather than in any heading. Entries written before
August 16, 2026 carry the longer set of headings that shape replaced, and every earlier shape is read
exactly as it always was. Every release ever cut is listed in
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

## `docs/ship-pr-reads-the-worktree` deployment

### What does the change on this branch deploy to main?

The `ship-pr` skill page names the assumption its step-list gate rests on, and the one thing that breaks
it. The gate opens `branch-cycle.md` **on disk**, which the script's own comment states is correct
"because that is where HEAD still is at this point" -- and that is an assumption rather than a check:
nothing compares the branch you are standing on against the branch whose PR is being merged.

Measured today in this repo. Two sessions were working in one checkout; one had `ship-pr` waiting on CI,
the other created a branch and moved `HEAD`. When CI went green the gate read the *other* branch's freshly
scaffolded step list and refused the merge over a step belonging to nobody's work on that PR, while the
PR's own list was complete and committed. Nothing was damaged and re-running from the right branch picked
up where it left off -- but the same assumption fails the other way too, letting an unfinished list
through when the tree stands on a finished branch, and that direction is silent.

**A guard is deliberately not built.** Refusing when `HEAD` and the PR's head ref differ is one
comparison, but it is a change on the merge path and one benign instance is not the evidence for making
it. What the trap needed was to be recognisable, which is a paragraph. The page also states the wider
rule none of these scripts could see: they assume one working tree per session, `/lock` is a note rather
than a claim on a checkout, and two things that really do run at once want a second clone or a worktree.

**Score:** 2

#### What makes this change extra special

Whoever hits this reads a refusal that names a step they never wrote, on a PR whose own step list is
finished -- and every instinct then points at the step list rather than at `git rev-parse`. The
consumer-facing cost is a run that looks broken and is not, on the command that merges; the page now
answers it in one line.

**Score:** 2

### Pull Request · 20260820-183049

ship-pr names the assumption its step-list gate rests on, and what breaks it

Plugins: workflow-davekjohn

[PR #797](https://github.com/DaveKJohn/claude-code-specialists/pull/797)

---

## `feat/branch-entry-gate` deployment

### What does the change on this branch deploy to main?

The branch-entry convention gains a gate that ships instead of being written per repo:
`scripts/lint/check-branch-entry.ps1`, plus the six lines of CI workflow that call it --
`.github/workflows/branch-entry.yml` here, and the same file placed in a consumer by
`adopt-workflow-folder`. One seam comes with it, `Get-EntryGateExemptPrefixes`, defaulting to `sync`.

**It adds no rule of its own**, which is the whole design. It calls the same two functions `open-pr`
calls -- `Test-BranchChangelogIsFilled` and `Get-EntryScaffoldFindings` -- so there is one definition of
"written" in the system rather than a second one in every consumer's CI. That makes it *simpler* than the
hand-written gates it replaces, not more complex.

Three things this branch measured rather than accepted, all of which changed the design:

- **Both hand-written gates are stricter than the convention.** Each refuses a merge over a missing
  significance score, justified by "tier 0 can never legitimately stay empty" -- while
  `entry-scaffold-lib.ps1` reads TIER 0 OWES NOTHING and Dave placed that refusal at the release cut on
  August 5, 2026, so an author who has not settled a score is not blocked from merging. The shipped gate
  reports it and names the cut. That is the load-bearing test in the suite.
- **A PowerShell gate cannot be a job in `ci.yml`**: that workflow also runs on `push: main`, where the
  entry sits in its reset state by design after every fold, so the trunk would be red after every merge.
  Its own workflow file, `pull_request` only.
- **The consumer workflow pins `main`, not a tag.** The entry's path has moved twice; a pinned gate does
  not fail loudly, it refuses branches that *do* carry an entry at the current path.

Two halves of the report are deliberately not built, both with a measurement: the second job of the
consumer's file (`preview-answered`) is repo-specific -- no PR template this marketplace ships has a
Preview section -- and making the check *required* is a branch-protection setting, which is Dave's rather
than a scaffolder's.

**Score:** 3

#### What makes this change extra special

A convention that enforces nothing rots quietly, and this one had the machinery to enforce itself sitting
right there: the plugin ships every reader of the format and shipped nothing that checked it. The two
gates that existed are both local, so a branch pushed by hand or a PR opened in the GitHub UI met neither
-- which is why both consumers wrote their own, from scratch, against a document whose signature they had
to reverse-engineer. Both got it wrong in the same direction, and neither could verify their YAML before
it shipped: one recorded having no parser on the machine at all.

For a consumer this is the difference between owning a gate and running one. The source now runs the same
file on its own PRs, so it is exercised here rather than being unverified in every repo that has it.

**Score:** 4

### Pull Request · 20260820-180958

The branch-entry convention gains a shipped gate, out of the libs the plugin already owns

Plugins: workflow-davekjohn

[PR #796](https://github.com/DaveKJohn/claude-code-specialists/pull/796)

---

## `docs/shopify-line-endings` deployment

### What does the change on this branch deploy to main?

`team-shopify` says what happens to line endings, which until now it did not mention anywhere: a
`grep -rniE "crlf|line ending|autocrlf"` over the whole plugin returned nothing. Steven's manual gains
the fact and the trap, since it is a property of the CLI rather than of any one store; Sandra's hard
rules gain the reading instruction, at the moment she reads a pull; the plugin README gains a section
before the two adoption sections, because a reader hits this on their first pull; and both the
`sync-main` skill page and `adopt-shopify-floor`'s closing output point at it.

Two things, and the second is why this is worth more than a footnote. **Read the drift after a
`git add -A`, never off the raw `git status`** -- the CLI writes each file with the line endings live
holds, live holds both, so a pull reports files as modified with zero changed lines. And **do not pin
`eol=lf`**, which is the obvious fix and makes the noise permanent: the same files then come back after
every pull forever, converting the one signal that spots a third party's in-flight edit into standing
noise. What `.gitattributes` should carry instead is stated, and why this plugin deliberately does not
place that file: the measurement says the working procedure is where the problem is handled, and
`* text=auto` dropped into a repo whose index already holds CRLF renormalises the whole tree on the
next `add` -- a bad surprise to arrive by scaffold.

The three measurements were verified in the reporting consumer's own tree rather than copied from the
report, and one of the report's figures had already moved: it says "over 712 tracked files", the tree
now says 740. The count that matters -- 37 files, zero changed lines -- holds, so the text carries that
and drops the total.

**Score:** 2

#### What makes this change extra special

The whole safety model of this team rests on one human judgement, made by reading `git status` after a
pull: is this diff mine, or a third party's in-flight edit? That judgement is the only thing between a
push and somebody else's unsaved work -- and the raw output of that command is unreadable, 37 times out
of 37. A verification step that cries wolf every time is the step nobody reads on the day it is right.

Both existing Shopify consumers discovered this independently, and one discovered it *twice*: it filed
`eol=lf` as an improvement, then inverted its own conclusion on re-measuring, because the proposed
remedy would have broken the safety check it was meant to help. That whole loop is what the next
consumer inherits, and none of it is about their store.

**Score:** 4

### Pull Request · 20260820-170602

team-shopify names the CLI's line-ending churn, and the fix that makes it permanently worse

Plugins: team-shopify

[PR #794](https://github.com/DaveKJohn/claude-code-specialists/pull/794)

---

## `feat/shopify-theme-delete-marker` deployment

### What does the change on this branch deploy to main?

`team-shopify`'s live-theme guard gains a third seam, `Get-ShopifyThemeDeleteMarker`, and rule 2 -- a
theme delete -- stops being absolute **for repos that ask**. Requested by a consumer
(`xoxowildhearts`) whose preview themes are created and thrown away by the same workflow: clearing a
spent one was a keystroke somebody had to be present for, and the guard offered no path at all.

**The design decision is the default, and it is the opposite of the push marker's.** `$MARKER` falls
back to a permissive suffix, because both existing consumers already write one and rule 3 has to keep
working unconfigured. `$DELETE_MARKER` falls back to **empty**, which means the capability is off:
nobody writes a delete marker today, because until now no marker could authorise a delete at all. A
default here would hand every consumer a new capability on their next plugin update, silently. An
unstated seam has to mean unchanged, and unchanged for a delete is *always denied*.

**Three bounds, each with its own counter-case in the suite:**

1. **The live theme is refused even with the marker**, and that check runs *before* the authorisation
   path so no marker can reach past it. Shopify will not delete a published theme either -- this is the
   belt to that braces, and it is the one outcome nothing else in the file could undo.
2. **A delete without the marker still blocks.** Answering the seam does not open deletes generally.
3. **One marker may not do two jobs.** Answer both seams with the same string and the delete capability
   stays **off** rather than being granted. A push marker gets written as a matter of routine -- it is in
   the consumer's own step list -- so accepting it here would turn every documented live push into a
   standing authorisation to delete. That is the opposite of a marker authorising one command visibly.

**Why a marker rather than "allow anything that is not live", which was the simpler option offered and
declined.** A real Shopify estate is not the live theme plus this week's preview. Measured on the
requesting store while this was being scoped: **nineteen themes, one of them a current preview** -- the
rest dated backups, two named `DO NOT DELETE`, and five `feat/*` themes from a previous agency. Nothing
in a command distinguishes a spent preview from any of those, so being non-live is not enough to make a
deletion deliberate.

**17 new cases, 85/85 in the suite**, covering every branch of the new condition: seam unanswered (twice
-- including that there is no generic default spelling, unlike the push marker), answered and authorised,
answered and unauthorised, wrong marker, case-insensitivity, the live theme with and without the marker,
the same-string collision in both directions, both markers staying in their own lanes, publish still
absolute, and the heredoc exemption plus its counter-case for the new branch.

Documented where a consumer actually looks: the guard's own header, the `team-shopify` README (a named
section, since this is a capability rather than a narrowing), and a pointer in the seam block
`adopt-shopify-floor` appends -- which is the path by which a consumer learns what is configurable at
all.

**Score:** 4

#### What makes this change extra special

**Consumers must opt in, and doing nothing is a complete answer.** A Shopify consumer who takes this
update and never touches their `repo-config.ps1` sees no behaviour change whatsoever: a theme delete is
refused exactly as before, and no marker they could write would pass it. Nothing to migrate, nothing to
re-check.

For a consumer who *does* want it, it is one function and one marker on the command -- the same shape as
the live-push authorisation they already run, so there is no second mechanism to learn. The README
section names the three bounds, because the one that will surprise somebody is the collision rule: reuse
the push marker's string and the capability silently stays off. It fails safe, and the report says so.

**Score:** 3

### Pull Request · 20260820-164448

an authorised preview-theme delete, opt-in per repo

Plugins: team-shopify

[PR #795](https://github.com/DaveKJohn/claude-code-specialists/pull/795)

---

## `fix/workflow-folder-history-split` deployment

### What does the change on this branch deploy to main?

`adopt-workflow-folder` stops contradicting itself inside one command's output. It scaffolded
`workflow-davekjohn/releases/README.md` with a `## Release history` heading, a table, and a `VUL-IN`
promising that the cut would insert its rows there -- and then, in the same run, told the reader to
leave `Get-ReleaseHistoryPath` at its repo-root default. Two statements that cannot both be true. The
scaffolded page now states this repo's release ANSWERS and names where the list actually lives, read
through the seam rather than hardcoded, so a repo that has repointed it is not sent to a file that is
not theirs.

Four places carried the claim and all four are repaired: the script header, the folder README's own
table row, the folder `CLAUDE.md`'s rules list, and the page itself. The test that asserted the table
header now asserts its absence, which makes it the regression guard on the contradiction.

**The report's proposed second half is deliberately not built, and the recount is why.** It asked for
the root history file to be scaffolded too, "so the cut is not the thing that creates an unannounced
one" -- but the cut creates nothing: with the file missing it warns `<path> is missing -- row not added`
and cuts anyway. And a scaffolded file with a table but no `<major>.x` heading would read as DONE to
`cut-release`, filing the row while silently disabling the guardrail that refuses a `v2` row under a
`1.x` heading, because that check skips when it finds no section. That is the same hole-with-a-comment
`adopt-shopify-floor` refuses to write. So the closing advice now prints the exact shape the reader
owes, the warning they get if they forget, and why the command will not write it for them.

**Score:** 2

#### What makes this change extra special

It is silent until the first cut, and the first cut is the worst possible moment to discover it. A
consumer who follows the advice ends up hand-maintaining a table nothing will ever write to, and the
consumer who reported it resolved it by doing exactly what the closing advice says not to -- which then
became nine lines of retracted reasoning in their own `repo-config.ps1`. Every consumer that adopts the
folder walks into the same fork.

**Score:** 3

### Pull Request · 20260820-160530

The workflow folder stops scaffolding a release history it tells you not to point the cut at

Plugins: workflow-davekjohn

[PR #793](https://github.com/DaveKJohn/claude-code-specialists/pull/793)

---

## `feat/shopify-pre-task-sync` deployment

### What does the change on this branch deploy to main?

`team-shopify` gains the pre-task sync: `sync-main`, a shipped script that mirrors the live theme into
the trunk without letting live overwrite what the trunk has done since, with the exclusion rule beside
it as its own tested lib. Two suites, 32 asserts: `sync-rules.tests.ps1` drives the two queries directly
against fixture repositories -- including the case a deletion is also a touch, which is the one the first
hand-written implementation got wrong -- and `sync-main.tests.ps1` drives the script's refusals, which
are the safety surface. Both mirrors are registered pairs, so the drift lint holds them to the source.

Four seam answers arrive with it, all read through `Get-Command` so the plugin depends on **neither**
workflow plugin: the store, the reference pattern, the branch prefix, and whether it merges.
`adopt-shopify-floor` writes them into the block it already appends and takes `-StoreDomain` so the sync
is runnable in the same move as the guard being armed.

Two things the branch found rather than built. The report named three seam-worthy divergences between the
two consumers' implementations; **the branch name is not one of them** -- both write `sync/live-<date>`.
It is a seam for a different reason, which the docs now give: it has to line up with whatever the
consumer's CI and PR guardrails exempt. And `-SkipPull` contradicted itself in both implementations --
it promises to run the rule over what is already in the working tree, while the clean-tree check refuses
a dirty tree, so with the switch there could never be anything there. It now warns and proceeds on that
path, loudly, naming what it is about to read as third-party drift.

**Score:** 3

#### What makes this change extra special

This is the script a Shopify consumer cannot afford to get wrong, and until now every consumer wrote it
themselves. Both of the two that exist did, and the first version destroyed work in both -- one of them
recording the same wholesale procedure reverting merged work three times in one week. A live theme has no
locking and no merge, so the obvious implementation of "mirror live" is the one that eats unpushed work,
and nothing warned about it. The exposed party was the next consumer, who has no sibling repo to copy
from.

It also states the interaction nobody had written down: the moment a repo adopts this marketplace's
changelog model, "merged into the trunk but not live yet" becomes a **designed** state, so every entry in
`CHANGELOG.md` names work the naive sync would have reverted. Adopting one half of the marketplace makes
the other half more dangerous, and that sentence now exists in Sandra's manual and in the skill page.

**Score:** 5

### Pull Request · 20260820-154757

The Shopify floor gains the pre-task sync, with the exclusion rule as a tested lib

Plugins: team-shopify

[PR #792](https://github.com/DaveKJohn/claude-code-specialists/pull/792)

---

## `docs/adoption-page-sequence` deployment

### What does the change on this branch deploy to main?

The adoption route stops being three steps and a wrong sentence. `plugins/ADOPTION.md` gains a step
naming the `adopt-*` skill of every plugin that owns repo state -- `adopt-config` and
`adopt-workflow-folder` from `workflow-davekjohn`, `adopt-shopify-floor` from `team-shopify` -- with the
rule that outlives the table (run the adopt skill of every plugin you enabled; your own slash list is
the enumeration) and the note that each is additive and a dry run until `-Apply`. It sits before the
half-day lens step deliberately, because it is minutes and it clears the session checks that would
otherwise sit red throughout. The same page's only description of a workflow-slot *transition* said
"Nothing has to be undone first", which the check shipping beside it falsifies; it now names the one act
that must happen in the same edit and the `[ERROR]` that arrives one session start later, after the
wrong state has been committed.

Two inbound issues, and a subject one document larger than either of them reported: `INSTALL.md`'s
quickstart carries its own copy of the adoption steps, so it gained the adopt step too and its lens step
became Step 5. The step counts follow across `specialists-init`'s cross-reference and four references in
`README.md` -- the count discipline this family has already repaired twice.

**Score:** 2

#### What makes this change extra special

A consumer adopting this family reads exactly these two pages, and until now both stopped short of the
finish line: `specialists-init` was the last named command, while a real install is that skill plus one
adopt step per enabled plugin. The reporting consumer spent a second day on follow-up rounds, each one
triggered by a session-check `[ERROR]` naming something neither page mentioned -- all of it discoverable
up front. And whoever switches the workflow slot was being told, by the only bullet describing the
switch, to leave the outgoing workflow enabled: a guaranteed wrong first attempt, committed and pushed
before the check that catches it ever runs. Neither can be bridged in a consumer's own lens, because the
audience is a repo that has not adopted yet.

**Score:** 4

### Pull Request · 20260820-151434

The adoption page names the adopt skill of every enabled plugin, and the one thing a workflow switch must undo

Plugins: team-alpha

[PR #791](https://github.com/DaveKJohn/claude-code-specialists/pull/791)

---

## `docs/v4-16-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.16.0 release
document froze at a subtotal of **7m 36s** because four of its legs were still running on the file it was
written into — writing the page itself, its local gates, its CI and merge, and the fold. Those legs now have
timestamps, so the total goes in: **25m 29s** of working time, with writing the page **5m 45s**, the local
gates and push **2m 57s**, CI and the merge **9m 07s**, and the fold **4s**.

**The reading that needed a decision rather than a subtraction is the 58m 53s between the published Release
and the start of the page.** That is the requester deciding to ask for the document, not the procedure
running. Folded into the total it would report **1h 24m 22s** for work that took twenty-five minutes, and
every comparison with another release would break. So it is stated beside the total rather than inside it,
and the wall-clock span is given once so the number is not lost.

Two readings the first pass could not produce. The head came to **26%** of the working total, a fifth reading
for the claim that most of a release happens after the version number exists (`v4.15.0` 21%, `v4.12.0` 24%,
`v4.13.0` 30%, `v4.14.0` 32%). And the two heaviest legs are **58%** between them, of which only the writing
is a person's time.

**Score:** 2

#### What makes this change extra special

It puts a second consecutive end-to-end measurement beside the first, and the pair is what makes the
fixed-cost claim concrete: **24m 34s** for v4.15.0's thirteen entries against **25m 29s** for v4.16.0's four.
A release costs what it costs per *event*, not per change — which is an argument for cutting when there is
something to ship rather than for batching until there is a lot.

The separated requester gap is the part a consumer running this workflow will meet first. A release
interrupted halfway is the normal case, not the exception, and a timing section that cannot tell waiting
apart from working produces a number nobody can use twice. The rule this instance sets is to exclude the
wait, name it, and give the wall clock once.

**Score:** 2

### Pull Request · 20260820-140950

The v4.16.0 release note gains its end-to-end total

[PR #790](https://github.com/DaveKJohn/claude-code-specialists/pull/790)

---

## `docs/v4-16-0-release-note` deployment

### What does the change on this branch deploy to main?

The hand-written release document for v4.16.0. The cut drafts it from the tier-2 entries in the words their
authors wrote for a diff reviewer and commits it inside the tagged release commit; this is the rewrite for
somebody deciding whether to update, held against the seven tests in the `cut-release` skill.

All four of this release's entries reach tier 2, and only one of them carries an action — so the page opens
with it and the other three say **no action needed** rather than leaving it to be inferred. The action item
is `team-shopify`'s new `adopt-shopify-floor` command, written with the dry-run call and the `-Apply` call
both shown, because the skill's own default is a dry run and a reader who copies one line should copy the
safe one. The `-LiveThemeId` paragraph states what happens in **both** directions — given, the guard's third
rule fires; omitted, the block lands commented out and the session check keeps reporting — since the whole
finding underneath that entry is that the omitted case must stay noisy.

Both organisation sections are written. *What it is worth* leads on the install path closing a gap that was
the default on install, on the two consumers who independently derived the same theme-check config, and on
the report that was right about the symptom and the cause and wrong about the lever. *What was still open* is
a snapshot rather than a claim about the present, and every figure in it was read at its source rather than
carried forward: the organisation's publication target at `9ea8dcf` with all four team plugins at 4.13.0,
read from their own `plugin.json` files, and the two Dutch settings layers confirmed English by reading the
repository settings and the label.

**Two things are recorded against this release rather than smoothed over.** The GitHub Release was published
in the same motion as the cut, one step ahead of the checklist, so its `notes-for-users` attachment is the
generated draft — the exact outcome step 5's ordering exists to prevent, and which the checklist names as the
first wrong idea that suggests itself. And step 0a's baseline was never noted, so the timing legs are
reconstructed from file and commit timestamps and are stated as the weaker evidence they are.

**Score:** 2

#### What makes this change extra special

It is the one document a consumer reads to decide whether to update, and it reaches every one of them as an
attachment on this release's GitHub Release.

The item that earns the top of the page is the one where doing nothing has a cost that does not announce
itself twice. A consumer who refreshed to v4.15.0 met a standing `[ERROR]` and a guard whose live-push rule
could not fire; this page gives them the command that closes it, says which rules were protecting them the
whole time so it cannot read as "you were unprotected", and tells the two consumers who wrote their own guard
that they are now running two of them.

The page is also the first in this series to carry a process failure of its own release in the section meant
for it, rather than in a chat message. Publishing early and skipping the baseline are both small, and both
are exactly the kind of thing a release record is for: the checklist already argued against publishing early
in advance, which makes this a measured instance of its own warning rather than a new lesson.

**Score:** 3

### Pull Request · 20260820-135458

The v4.16.0 release note

[PR #783](https://github.com/DaveKJohn/claude-code-specialists/pull/783)

---

