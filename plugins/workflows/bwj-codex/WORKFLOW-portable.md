# BWJ ticket handling -- the portable rule

**This page applies in exactly two repos: `BWJ-ecommerce/smartwatchbanden` and
`BWJ-ecommerce/xoxowildhearts`.** They are one business (BWJ) running two Shopify stores that behave
identically and differ only in brand, so they handle a discovered issue the same way. This page is
that way, written once so neither repo can drift from the other.

It is a layer on top of `contributing-davekjohn`, not a replacement for it. It extends that
workflow's **ticket-work step -- the layer before the branch** -- and changes nothing else:
branch naming, what a change owes before a PR, and what a release is are still that workflow's
answers. Read this page after
[`contributing-davekjohn`'s ticket-work section](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/contributing-davekjohn/CONTRIBUTING-portable.md#ticket-work--the-layer-before-the-branch),
which this one sharpens rather than repeats.

**How to read this page.** It travels with the plugin, so a link that walks out of this plugin's own
folder is written as an absolute URL -- an installed plugin is read from its own cache directory,
where the repo tree around it does not exist. Measurements and issue numbers on this page are the
**source repo's** (claude-code-specialists); they are the evidence behind a rule, never your repo's
own record.

---

## The rule

### 1. GitHub first -- GitHub is the source of truth

A real issue found in a BWJ store repo -- a bug, a broken customer-facing behaviour, a stale or wrong
doc, a decision that is not yours to make -- is **filed on GitHub first**, in the repo it was found
in. Full technical detail; repo and code jargon are fine, because the reader is whoever picks the
work up.

The `team-alpha` orchestrator's filing bar applies **unchanged** -- this rule adds *where the issue
is mirrored*, it does not loosen *when or whether it is filed*:

- The question to answer first is *does it still stand?*, not *may I file it?* -- read the code, the
  script or the output that would have to be true for the finding to hold, and if it collapses, say
  so instead of filing a weakened version.
- Search the tracker first, so you add to an existing thread rather than open its duplicate.
- One subject per issue.
- Say what you **measured** and what you only **inferred**.
- Filing needs no permission, and asking for it is the same failure as not filing.

#### Classify it as you file it -- three fields, all set at creation

An issue that arrives typeless and unlabelled has to be classified by hand afterwards, and afterwards
never comes. Both BWJ trackers were brought to 100% type coverage by hand on September 1, 2026 -- 135
issues across the two -- and that state holds only if every filing from here on maintains it.

| field | what it carries | how |
|---|---|---|
| **issue type** | Bug / Feature / Task | `--type Bug` -- a defect in behaviour that already exists is **Bug**, a capability the store does not have yet is **Feature**, and **Task** is everything else, which is most of it |
| **`tier-1` label** | how far the issue reaches | `--label tier-1`, and only where it reaches the audience tier. Absence is the answer for tier 0 and is not a missing field |
| **`documentation` label** | the one content distinction the type system cannot express here | `--label documentation` on a doc finding, on top of whatever type it has |

**The type is set directly, not derived from a label.** `bug` and `enhancement` were deleted from both
repos on September 1, 2026, because the type already carried them: all 28 `bug` issues held type `Bug`
and all 16 `enhancement` issues held `Feature`. Nothing was lost with them, and they are not re-added.

**`documentation` was deliberately kept** (Dave). The `BWJ-ecommerce` org has exactly three issue types
and none of them is Documentation, so its 42 doc issues sit on `Task` and `Feature`. Deleting the label
would have buried them in a 91-issue `Task` pile -- that is not *covered by the type*, that is lost. A
`Documentation` type was considered and not taken: issue types are **org-wide**, so adding one would put
it in every BWJ repo, which is a wider decision than these two.

#### The `tier-1` label -- the reach axis, carried onto issues

The label is the
[tier model](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/contributing-davekjohn/RELEASES-portable.md#the-tier-model)
applied to an issue instead of a changelog entry. Both BWJ repos answer `Get-ReleaseAudienceTier = 1`, so:

- **`tier-1` present** -- management and the commissioner notice it.
- **`tier-1` absent** -- tier 0: only this repo's developers notice.

Tier 2 does not exist in these repos, so one label carries the whole axis and
`is:open label:tier-1` is the business-facing worklist.

**The model transfers; the mechanism does not.** A changelog entry is a form with a field per reader, and
every tier is scored on it -- tier 0 included, because an unanswered field reads as an omission rather
than a decision. A label is not a field, it is a filter, and *a filter that matches everything filters
nothing*. So: **score every tier on an entry, label only the exception on an issue** (Dave, September 1,
2026, after two other shapes were tried -- `tier-0` marking the exception, which labelled 106 of 135 and
left the actionable set unmarked, and a `tier-0` floor with `tier-1` stacked on it, which is the changelog
model exactly and is where the two genuinely part company).

**The test is whether the reader notices the DEFECT, not whether the file renders to them.** This is the
mistake the file path invites, and it was made: `smartwatchbanden#455` is a Liquid block on the product
page -- inline CSS, invented hex instead of the token, five unsynchronised copies across the market
templates. It renders correctly to every shopper. The named failure is that a copy change has to be made
in four places with nothing reporting the one left behind, which only a developer can see. Tier 0, first
classified tier 1 on the wrong question (*the PDP is customer-facing, so a PDP file is tier 1*).
Re-testing all 31 tier-1 issues on the sharper question moved a second. **The inverse holds too**: a build
script no customer will ever load, whose breakage stops a release the business is waiting on, is not tier
0.

**Doubt resolves to tier 0** -- no label (Dave, September 1, 2026, on three borderline cases in the
backfill). The point of the label is a short list somebody can work, and a tier-1 issue is cheap to add
later with `gh issue edit <n> --repo <owner>/<repo> --add-label tier-1`.

### 2. Then Asana -- a translation, not a copy

Once the GitHub issue exists, mirror it to Asana in the project
`Get-AsanaProjectGid` names. The Asana task is **not** a paste of the issue body. It is written for
a BWJ colleague who does not read code and does not know the repo:

- **Plain language, outcome-framed.** What a customer or colleague actually experiences, not what the
  code does.
- **No jargon** -- no file paths, no function names, no branch names, no GitHub label vocabulary.
- **A fixed skeleton**, so every mirrored task reads the same way:

  ```text
  What is wrong:   <one or two plain sentences -- what a visitor or colleague sees>
  Where:           <which store, and which page or flow>
  How urgent:      <blocking a sale / visible but not blocking / cosmetic / not customer-facing>
  Tracked on GitHub: <issue URL>
  ```

- The task's assignee, section and due date are for the BWJ team to set in Asana. This page does not
  prescribe them.

The colleague-facing wording is Claude's to draft; a colleague may refine it in Asana afterwards
**without touching GitHub**. GitHub stays leading -- if the two ever disagree on substance, the
GitHub issue is right and the Asana task is corrected to match.

### 3. Cross-link both ways

The link is stored on both sides, and one half is machine-readable because the automation in step 4
matches on it:

- **On the GitHub issue** -- appended to the issue body:

  ```text
  Asana: <task URL>
  <!-- asana-task: <numeric task GID> -->
  ```

  The HTML-comment marker holds the bare numeric GID and nothing else, and it is what the CI workflow
  matches on **first and unconditionally**. Write it whenever you create the task yourself: it is the
  only form that cannot be misread, and an issue carrying one is never matched any other way.

- **On the Asana task** -- the `Tracked on GitHub:` line of the skeleton already carries the issue
  URL. Nothing else is required there.

### 4. Close the GitHub issue -> the Asana task gets an update

**Closing the GitHub issue is the signal that the work is BUILT, not that the ticket is DONE.** A
GitHub Actions workflow in the repo (`.github/workflows/asana-mirror.yml`, copied from this plugin's
`templates/`) carries that news across:

| GitHub event | what happens in Asana |
|---|---|
| issue **closed** | a comment on the linked task: the work is built and ready to test, with the issue URL **and the pull request that closed it** -- number, title and link. The task stays open |
| issue **closed as not planned** | the opposite comment: nothing was built, so there is nothing to test, and the reason is on the issue |
| issue **reopened** | a comment saying it is being worked on again, so hold off on testing |
| daily schedule | a reconciliation sweep in **both** directions, for events that never arrived: open tasks in the mirror project whose GitHub issue is closed, and issues closed in the last 30 days whose task has not been told yet |

**The task is never completed by any of this, and the script has no code path that can do it**
(Dave, September 1, 2026). Closing a GitHub issue is a statement by whoever built the thing; resolving
the ticket is a statement by whoever asked for it, and only that person can make it -- after they have
tested it. An automation that ticks the box takes the one decision the ticket exists to record and
replaces it with a guess, and it does so silently, so nobody can tell an accepted change from an
unverified one afterwards.

This is the shape after a measured mistake, and the mistake is worth the sentence: on
September 1, 2026 the sweep that had just learned to read imported tickets completed **six** Asana
tasks it should only have commented on -- five of them belonging to colleagues who had never been
asked whether the work was any good.

**The update names WHERE the change was made** (Dave, September 1, 2026), because that is the first
thing somebody about to test wants and the ticket is the only place they are looking. GitHub says it
as *"closed this as completed in #434"*; the update says the same, with the pull request's number,
title and URL. It comes from the GraphQL field built for that question
(`closedByPullRequestsReferences`) rather than from the timeline, where a merge commit, a manual
close and a passing cross-reference are easy to confuse. **An issue closed by hand says so**, and one
GitHub cannot be asked about still gets its update with no pull request named -- an invented
reference would be worse than a missing one.

**The de-duplication is the update's own opening sentence**, `GitHub issue <repo>#<n> is closed`, which
names the issue. Sweeps look for it and stay silent when it is already there; **an event never
de-duplicates**, because a close after a reopen is news again. A task somebody has already ticked off
is left alone by both.

**Which task an issue belongs to is answered by three matchers, tried in order** -- 'tier' is the reach
label above and means nothing here -- because a repo has two kinds of issue and only one of them was ever
written by this workflow:

1. **the marker** -- `<!-- asana-task: <gid> -->`, written in step 3 above. Authoritative.
2. **the header row** -- a `| **Asana** | ... |` row carrying a task URL. This is the shape of a
   ticket **imported from Asana**: a colleague filed it there, somebody copied it into an issue for
   analysis, and the link in its header was written for a reader rather than for a machine.
3. **a sole task URL** anywhere else in the body.

**The header-row matcher exists because of what the marker alone could not reach.** In
`BWJ-ecommerce/smartwatchbanden`,
[#388](https://github.com/BWJ-ecommerce/smartwatchbanden/issues/388) was closed on 2026-09-01 and its
Asana task stayed open; the workflow had run, and its log said why -- *"No `<!-- asana-task: ... -->`
marker ... nothing to mirror"*. Measured across that repo the same day: of 55 issues, **4** carried a
marker and **11** carried an Asana link in a header row only, **6** of those already closed. The
mirror was working exactly as written, and reached 4 of the 15 issues that carry an Asana link at all.

**More than one different task, and no marker, resolves to nothing** -- the workflow names the
candidates in its log and moves on. It never guesses which ticket an issue belongs to, and the way to
settle it is to add a marker.

### 5. The Asana prio score comes back as a GitHub label

Everything above moves GitHub -> Asana. This one step goes the other way, and it is the only one that
does. The BWJ team scores a task on the board's **`Prio-Score`** number field, 1.00 to 5.00; the
reconcile run reads that score and puts the matching label on the GitHub issue:

| Prio-Score | GitHub label |
|---|---|
| 4.00 - 5.00 | `very high` |
| 3.00 - 3.99 | `high` |
| 2.00 - 2.99 | `low` |
| 1.00 - 1.99 | `very low` |

Dave's mapping, September 2, 2026. **Four buckets and deliberately no `medium`**, and each boundary is
closed at the bottom and open at the top, so a field with two decimals can never land between two of
them.

**Exactly one prio label sits on an issue at a time.** The sweep removes the other three as it sets
one, so a ticket rescored from 2.5 to 4.2 loses `low` as it gains `very high` rather than claiming two
priorities at once. Where the issue already reads correctly nothing is written, so a daily re-run is
quiet.

**No score means no label, and that is the common case.** A task whose `Prio-Score` is empty, or whose
score falls outside 1.00-5.00, is left without a prio label rather than given a guessed one -- measured
on the board the day this shipped, 28 of its 96 open tasks carried no score at all.

**It walks GitHub, not the Asana project**, and that is what separates it from the sweeps in step 4.
Two consequences worth knowing. It reaches a ticket **imported from Asana**, whose task carries no
GitHub back-link for a project walk to follow -- the same gap the header-row matcher exists for. And it
needs **no `ASANA_PROJECT_GID`**: a repo whose project GID is still wrong or provisional gets its
labels right anyway.

**But `Prio-Score` belongs to ONE workspace, and that is the limit to know before relying on this
step.** An Asana custom field is defined in a workspace and does not cross into another -- which is why
this sweep looks the field up by *name* and never by GID. Set that against the two populations the step
reaches and they come apart. A ticket **imported from** the board *is* a task on that board, so it
scores normally. A ticket the workflow **files itself** lands in whatever `Get-AsanaProjectGid` points
at, and where that project sits in a different workspace from the board, its tasks have no `Prio-Score`
for the sweep to find -- not an empty one, none. So the paragraph above reads too generously: a wrong or
provisional project GID costs an imported ticket nothing, and costs a self-filed one every label it
could have had.

**Which gives `Get-AsanaProjectGid` an answer it did not have before.** Whichever project a repo mirrors
into, it has to sit in the workspace that defines `Prio-Score`, or step 5 is a feature only imported
tickets can use. Measured across both BWJ stores on September 2, 2026, the day after this shipped: of
the 12 open issues that resolved to a task, every one that came away with a label was an imported one
(4 of the 5 matched by header row; the fifth was unscored), and no self-filed ticket was labelled in
either repo. The workspace boundary is the reading of *why* -- inferred from the field model above
rather than measured, because in that run the same self-filed tasks were unreadable to the session's own
token, which is the separate cause described three bullets into step 7, and from outside the two cannot be
told apart. Issue
[#1213](https://github.com/DaveKJohn/claude-code-specialists/issues/1213).

**Why this direction does not contradict "GitHub first".** That rule is about where a ticket is *born*
and where its lifecycle is *tracked*. Priority is neither: it is the business's judgement, made in the
window the rest of BWJ looks through, and the workbench is where it has to be visible. Nothing in this
step writes to Asana.

**What it costs on the GitHub side:** the workflow's `issues:` permission is `write` rather than
`read`. That is the only write it makes outside Asana, and it touches labels and nothing else.

### 6. The board's sections ARE the cycle -- one card, six stages

Everything above says what is written *into* a ticket. This step says *where the ticket sits*, and it
is the one view of this workflow a BWJ colleague actually reads: the board's sections, in order, are
the steps of the contributing cycle. A card's column is the answer to *"where is my request?"*, which
until now the board could not give.

**There is exactly ONE board, and its name is the team's** (Dave, September 2, 2026, closing
[#1222](https://github.com/DaveKJohn/claude-code-specialists/issues/1222)). At BWJ that is
`Workload Overview`; `Development BWJ` was retired in the same decision, and every card of Dave's was
taken off it that day. So the *"which board, and what happens to the others"* edge that inbound
[#1217](https://github.com/DaveKJohn/claude-code-specialists/issues/1217) had to be corrected on by
hand does not arise here any more -- there is no other board to advance by mistake. The containment
that answered it is still in the mechanism, and it is what the next paragraph is about.

| stage | what a card there means | who puts it there | on what signal |
|---|---|---|---|
| **1** | new, and nobody has looked at it yet -- a colleague put it on your name | the requester | **never this workflow** |
| **2** | it is tracked on GitHub now, where the work happens | [`report-issue`](skills/report-issue/SKILL.md), as it files | the issue exists |
| **3** | somebody is building it | the session at `new-branch`; the daily sweep as a floor | a pull request that declares it closes the issue is open |
| **4** | development is finished and merged, and the issue is not closed yet | the daily sweep | that pull request is merged |
| **5** | ready to test -- the requester has the update naming what was fixed | the close event, and the daily sweep | the issue is closed **as completed** |
| **6** | the requester has tested it and says it is good | the requester | **never this workflow** |

**The two ends of the board belong to the requester, and the code says so and not only this page.**
`Test-StageIsWritable` permits stages 2 to 5 and nothing else, and a card already sitting in 6 is not
moved at all. That is the *section-move twin* of the rule in step 4: closing an issue says the work is
built, and only the person who asked for it can say it is good. A workflow that could slide a card
into `Completed` would take that judgement and replace it with a guess -- in the board's own currency
this time, but the same guess.

**A section is recognised by the NUMBER its name starts with**, and that is the whole configuration.
`3. In development` and `3. Building it` are the same stage; rename the words whenever the team
likes. It is the same split the cross-link of step 3 already uses -- a marker for the machine, prose
for the reader -- and it means no repo has to keep six section GIDs correct in a config file, which is
six more values that could go stale the way a provisional project GID did.

**And it is the containment.** A section with no leading number is on no pipeline, so a task sitting
only in such sections is never written to. That is why pointing this workflow at a workspace full of
other boards costs nothing, and it is the mechanism that made #1217's correction structural rather
than a written warning. A card on **two** numbered boards has two answers and gets neither: the
candidates are named in the log and nothing moves.

**Which board a card is on is read off the card**, not out of a variable. The script asks Asana for
the task's memberships and takes the one whose section carries a number -- so, exactly like the prio
sweep of step 5, this needs no `ASANA_PROJECT_GID` and reaches a ticket **imported from** the board
just as well as one this workflow filed.

**Every move is forward, and the reopen is the only exception.** `Get-StageFloorForIssue` derives a
**floor** from the issue's own state rather than a position, because CI can see a pull request and
cannot see a branch: a card a session advanced to 3 at `new-branch` must not be dragged back to 2 by a
sweep that knows less than the session did. An `issue reopened` event is the single backward move in
the whole script, and it is a real state change -- the card lands wherever the issue now is, which is
out of the test column and back into the one the work is actually in.

**Stage 4 is the gate, and it is stated as Dave stated it**: a card leaves 4 only once the issue is
closed. Nothing else can put a card in 5, because `closed as completed` is the only input that derives
it. An issue **closed as not planned** derives no stage at all -- nothing was built, so there is
nothing to test and the card stays where the team left it.

**For three of the four writable stages the daily sweep IS the mechanism, not a backstop.** Stages 2,
3 and 4 have no GitHub event this workflow subscribes to -- an issue is filed, a branch opens and a
pull request merges without `issues: closed` ever firing -- so unlike the reconciliation of step 4,
sweep (d) is not a safety net for a missed webhook. Only stage 5 has an event of its own, and it is
the one that matters most for the requester, which is why it is also the one that does not wait a day.

**What that costs at stage 3, said plainly:** GitHub has no reliable signal for *"a branch was
opened"* in this workflow. `linkedBranches` answers only for a branch created through GitHub's own
issue UI, and `contributing-davekjohn` branches are not, so the sweep's floor for stage 3 is *an open
pull request that declares it closes the issue* -- which in this cycle arrives when the work is nearly
done. **So the 2 -> 3 hop is a session's to make**, at `new-branch`, and the sweep is what catches it
when nobody did. A cross-reference is deliberately not read for this: a pull request that merely
mentions an issue says nothing about whether anybody is building it.

### 7. What still needs a person

- **Setup, once per repo:** the repo secret `ASANA_PAT`, the variable `ASANA_PROJECT_GID`, the four
  prio labels of step 5, plus copying the two `templates/` files into `.github/`. The
  [`adopt-bwj-asana`](skills/adopt-bwj-asana/SKILL.md) skill walks this.
- **Numbering the board's sections, once.** Step 6 reads a stage off the number a section's name
  starts with, so a board whose sections are named in prose has no stages and nothing is ever moved on
  it. That is the safe default rather than a failure -- but it is also silent, so a board that is
  meant to be a pipeline and is not numbered looks exactly like one that works.
- **The 2 -> 3 hop, at `new-branch`.** The one stage transition CI cannot see: GitHub has no signal
  for a branch that has no pull request behind it yet. A session opening a branch for a mirrored issue
  moves the card to stage 3 in the same breath; the daily sweep only catches up once the pull request
  exists, which in this cycle is late. Step 6 says why, and it is why the sweep's derivation is a
  floor -- nothing undoes the move you made by hand.
- **Scoring the ticket.** The label follows the board and nothing here decides a priority. A task
  nobody has scored carries no prio label, and putting a number on it is the team's call to make in
  Asana -- the same shape as resolving a ticket, further down this list.
- **A token that can reach the tickets.** `ASANA_PAT` is a *user* token: it can only see the
  workspaces that user is a member of. An imported ticket often lives in the requester's own Asana
  organisation rather than in the one the mirror project sits in, and a task the token cannot read is
  logged and skipped rather than failing the run -- so a sweep that reports `0 updated` with a line
  per unreadable task is telling you about the token, not about the tickets.
- **Resolving the ticket. That is the whole point of step 4**: the colleague who filed
  it ticks it off once they have tested the change, and nothing in this workflow will do it for them.
- **The Asana project answer, and step 6 has now settled it.** This used to be an open BWJ decision --
  one shared project for both stores or one each, as long as both repos made the *same* kind of
  choice. It is not open any more: the board a card is staged on is the board the team reads, there is
  exactly **one** of those (Dave, September 2, 2026), and a task this workflow files anywhere else
  lands on no pipeline and is never staged. Put together with the `Prio-Score` constraint of step 5,
  which independently requires that project to sit in the board's workspace, `Get-AsanaProjectGid`
  has one correct value per repo: **the board itself**. A **provisional** GID is the case where both
  costs land at once -- such a ticket carries no prio label and never moves a column, and neither
  failure says anything in a log.

---

## Why it is shaped this way

- **GitHub first, not Asana first**, because the people who fix the issue live in GitHub and the
  fix's lifecycle (branch, PR, merge, release) is already tracked there by `contributing-davekjohn`.
  Asana is the window the rest of BWJ looks through, not the workbench.
- **A translation, not a copy**, because a mirrored task that is just the issue body helps nobody: a
  non-technical colleague cannot act on a stack trace, and a technical reader already has the issue.
- **CI, not a session**, for the update step, because it must happen every time an issue closes
  whether or not anyone is running Claude, and because a workflow file is version-controlled and
  reviewable where an Asana-side automation rule is not.
- **A reconciliation sweep**, because a single webhook can be missed and a colleague waiting on a
  ticket nobody told them about is exactly the drift this plugin exists to prevent.
- **The prio label goes Asana -> GitHub**, against the grain of everything else here, because
  priority is the one thing the business owns and the developers consume. The board is where it is
  decided and the issue list is where it has to be read; carrying it across beats asking a developer
  to keep a second window open.
- **An update and not a tick**, because the two are different claims by different people. The build
  is finished when the person who built it says so; the request is finished when the person who made
  it says so. A tracker that lets one stand in for the other cannot afterwards tell you which of its
  closed tickets anybody actually looked at.
- **The board's sections, and not a status field**, because a section is what a colleague already
  reads. The stages could have been a custom field with six options and nothing about the mechanism
  would change -- but then the answer to *"where is my request?"* would sit one click inside a card
  instead of being the shape of the board, and a card would look identical whether it had been picked
  up or not. That is the failure inbound #1217 measured: an issue existed here while the board still
  said `New`, and the person waiting on it had no way to tell.
- **A number in the section name, and not six GIDs in a config**, because the two halves have
  different owners. The number is this workflow's and never changes; the words are the team's and
  change whenever a column reads badly. Six configured GIDs would put both halves in a file only a
  developer edits, and would go stale the first time somebody rebuilt a column -- the way a
  provisional project GID went stale and cost every prio label behind it.
- **A floor rather than a position**, because CI knows less than the person at the keyboard. A sweep
  that set the stage outright would spend every night undoing the one hop only a session can see -- a
  branch opening -- and the card would flap between two columns with nothing wrong.
