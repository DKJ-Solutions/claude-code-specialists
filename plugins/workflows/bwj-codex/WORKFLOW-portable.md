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

**Why this direction does not contradict "GitHub first".** That rule is about where a ticket is *born*
and where its lifecycle is *tracked*. Priority is neither: it is the business's judgement, made in the
window the rest of BWJ looks through, and the workbench is where it has to be visible. Nothing in this
step writes to Asana.

**What it costs on the GitHub side:** the workflow's `issues:` permission is `write` rather than
`read`. That is the only write it makes outside Asana, and it touches labels and nothing else.

### 6. What still needs a person

- **Setup, once per repo:** the repo secret `ASANA_PAT`, the variable `ASANA_PROJECT_GID`, the four
  prio labels of step 5, plus copying the two `templates/` files into `.github/`. The
  [`adopt-bwj-asana`](skills/adopt-bwj-asana/SKILL.md) skill walks this.
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
- **The Asana project answer:** whether both stores mirror into one shared project or one project
  each is a BWJ decision. `Get-AsanaProjectGid` returns whatever each repo sets, so either works --
  but the two repos must make the *same* kind of choice, or this page's promise of "identical" is
  broken.

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
