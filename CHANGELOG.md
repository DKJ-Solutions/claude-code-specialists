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

## `docs/release-notes-on-main` deployment

### What does the change on this branch deploy to main?

A release cut now runs in one place from end to end. The hand-written release documents — the
audience note the cut drafts, and the internal note where a repo still runs the two-document flow —
are committed straight onto `main` in the commit after the tag, instead of travelling a branch + PR.
That makes a **third** named direct-on-`main` exception beside the fold commit and the release
commit, and the three read as one procedure: fold the changelog, bump the version, write the release
notes.

It is bounded the way the other two are, because that is the only thing that keeps an exception safe:
the hand-written documents of a cut that was actually asked for, named in the commit, and nothing
else in the tree. Outside a cut there is nothing for it to be part of.

This reverses the August 4, 2026 answer, which sent those documents through the reviewed route. The
argument that answer rested on — an exception is only safe while it stays the size it was granted at
— is not overturned; it is why the new bound is spelled out rather than assumed. What changed is the
judgement about which size is right: running one procedure across two routes left the trunk carrying
a tagged release whose own notes were still in review.

**Score:** 4

#### What makes this change extra special

Anyone running this workflow gets a shorter, single-track release. What used to be a cut, a branch, a
PR, a CI wait and a merge is now a cut and a second commit — and the step-zero timing instruction
loses two of the legs it could not measure. Nothing already published changes, and the tag still
holds the draft exactly as before, so there is no action to take: the next cut simply commits where
it used to open a PR.

**Score:** 3

### Pull Request · 20260823-105514

The written release notes land directly on main

Plugins: workflow-davekjohn

[PR #835](https://github.com/DaveKJohn/claude-code-specialists/pull/835)

---

## `feat/worktree-lane` deployment

### What does the change on this branch deploy to main?

A new shared script, `worktree-lane.ps1`, opens a branch in its own git worktree -- a "lane" -- so one
branch can be **built** while another one **ships**, and hands the lane's branch back to the primary
checkout when it is ready. It is the answer to a measured cost: `ship-pr.ps1` blocks on
`gh pr checks --watch`, whose median is **8m 01s** over the 65 most recent blocking CI runs, and at 73
merged PRs in seven days that is **9h 45m per week** in which the session that opened the PR can do
nothing else. Lanes convert that from blocking to non-blocking without touching a gate and without
proving any less.

The direction matters and is the opposite of the obvious one: **the worktree is where you build, the
primary checkout is where you ship.** Shipping from a worktree cannot work -- git refuses one branch in
two worktrees, and that refusal lands *after* the merge, in the one gap where the PR is merged, the entry
is unfolded, and every gate stays green until a release trips over it.

`new-branch.ps1` gains a `-RepoRoot` parameter, on the precedent `fold-changelog-entry.ps1` has carried
since #101, so a lane's branch and both of its branch-dossier files come into being inside the lane
rather than in the primary. A new 35-assert suite covers both ends, including the guarantee that opening
a lane never moves the primary's HEAD -- the one property whose failure would break the thing the script
exists to protect.

**Score:** 4

#### What makes this change extra special

Three of the findings in it came from running the thing rather than from reading it, and two of them
contradicted the plan they were testing. The first design pointed `CLAUDE_PROJECT_DIR` at the lane, which
the source-repo guard refused -- correctly, because that variable answers *which repo the session is on*
and not *which tree this call writes to*; that is what produced the `-RepoRoot` parameter instead of a
workaround. The first hand-back then failed with `Permission denied`, because on Windows the process's own
working directory holds the lane open, and standing in the lane is the normal case rather than an edge
one. And the message that failure printed -- "nothing was changed" -- turned out to be **false**: git had
already emptied the tree and deregistered the worktree, so `git worktree remove` is not atomic and the
script now asks git what it thinks instead of inferring from an exit code.

The alternative repair is recorded as declined rather than unconsidered: a one-line change to
`ship-pr.ps1` would remove the two commands a hand-back costs, and was measured as saving nothing in
wall-clock while changing the single line that produces the state nothing reports.

**Score:** 3

### Pull Request · 20260823-100851

A branch can be built in its own worktree while another ships

Plugins: workflow-davekjohn

[PR #834](https://github.com/DaveKJohn/claude-code-specialists/pull/834)

---

## `docs/lens-inbound-to-skill` deployment

### What does the change on this branch deploy to main?

Chris's repo lens stops carrying the evidence for its own rule in every session. The five inbound
failure-pattern case studies — #469 repaired inside the morning it was filed, #456's expired
reasoning, #566's `Resolve-PluginScript` that never existed, #660's `pair-cli` that named nothing,
and the four of 22 own reports whose counts were wrong — move verbatim into a new
`.claude/skills/triage-inbound/` skill. The rule stays always-loaded; the measurements are now one
invocation away, read when an inbound item is actually being triaged.

Measured rather than projected, because the projection was wrong: the lens drops 25,689 B -> 18,056 B
(-7,633 B, ~1,908 est. tokens) and the skill costs 126 est. tokens back as a resident description, so
the net is **~1,782 est. tokens per session** -- 10% of the 18.6k always-loaded chain. The first estimate
said ~2,255, counting the 94 removed lines but not the 15-line bullet that replaced them. Corrected here
rather than repaired to, which is what this repo asks of a recount that changes the number.

This follows the convention `CLAUDE.md` already records — skills carry the evidence behind a
procedure, personas and manuals carry no repo-specific detail — so it is that rule being applied to
the one always-loaded file that had not yet been, rather than a new idea about where things go.

**Score:** 3

#### What makes this change extra special

N/A — the change is entirely repo-local under `.claude/`. No plugin payload moves, so no consuming
repo and no subscriber of the specialists system receives anything from it.

**Score:** N/A

### Pull Request · 20260822-133906

Move the inbound-triage evidence out of the always-loaded lens into a skill

[PR #833](https://github.com/DaveKJohn/claude-code-specialists/pull/833)

---

## `feat/measure-skill` deployment

### What does the change on this branch deploy to main?

A new `measure-skill` skill in `workflow-davekjohn`, which prices what a skill costs and times the
script behind it. Two passes: **cost** (always-on and on-invoke tokens per skill, ranked, with the
delta against a committed baseline) and **speed** (wall-clock of the script a skill drives, `n` runs,
min/median/max, machine state stated).

It drives `claude plugin details` -- the `count_tokens` API -- rather than estimating from file sizes,
so the figure it reports is the authoritative one and not a second, disagreeing estimate. It checks no
correctness: frontmatter, dead links and parameter coverage stay `check-plugin-integrity.ps1`'s, and
duplicating one of its 26 checks here would put two verdicts on one subject. It is not a gate and the
page says why: `lint-en-tests` already blocks every merge for a median of 7m 23s, and a skill's cost
changes on the scale of releases rather than commits.

**Why now, measured rather than assumed.** 24 skills across four plugins had never been measured on
cost, speed or effect. Seven skill descriptions cost ~1,245 tokens at `v2.10.0`; 18 across the two
plugins enabled here cost **~3,650** at `v4.17.0` -- nearly 3x, never re-measured in between. And the
first run found something no estimate would have: `workflow-davekjohn`'s **entire** always-on cost is
its 14 skill descriptions, within rounding. The committed baseline is what makes the next growth
visible instead of discovered.

**Pass 2 will not run a script that has no declared read-only mode, and that is the whole safety
model.** Timing the script behind `cut-release` by invoking it would cut a release. So a script is
timed only where its own registration carries a `MeasureArgs` key naming a harmless invocation --
declared beside the registration rather than in a list inside the measuring script, because a second
hand-written list is one a newly shared script falls out of silently. Two scripts qualify today;
everything else is reported as not measured, by name, with the reason. A test pins `cut-release` as
never declarable.

**Pass 3 -- whether a skill actually earns its tokens -- is designed and deliberately not built.**
`claude plugin eval` already carries the engine, including a `--ablation with-without` arm that scores
the same cases with the plugin removed. The four flags this repo would need are recorded on the skill
page so the first person to wire it up does not rediscover them, `--no-publish` among them: the report
otherwise goes to claude.ai, which is not a side effect a measurement gets to have.

Three defects were found by running it rather than by reading it, and each is written up where it
happened: figures formatted on a Dutch machine rendered 13,700 as `13.700` (a factor of a thousand to
an English reader, and the mirror image of the parse trap the tolerance guards); `-UpdateBaseline`
reduced an 18-skill baseline to 4 and reported success, because a scoped run replaced the file instead
of merging into it; and an `if` expression returning `@()` unrolled to `$null`, so "declared safe with
no arguments" read as "not declared" and was silently skipped.

**Score:** 3

#### What makes this change extra special

A consumer gains a skill that answers "what is this plugin costing my sessions, and which skills carry
it?" -- and pass 1 works there, since it needs nothing but the `claude` CLI. Pass 2 needs the
shared-scripts registry and reports `[SKIP]` with the reason where there is none, so the boundary is
stated rather than met as a failure. Nothing existing changes behaviour: one skill and one script are
added, and the only edit to a shared file is an optional registry key that is absent everywhere it was
not declared.

**Score:** 3

### Pull Request · 20260822-122834

Measure a skill's token cost and speed

Plugins: workflow-davekjohn

[PR #832](https://github.com/DaveKJohn/claude-code-specialists/pull/832)

---

## `docs/redeploy-verify-past-the-cache` deployment

### What does the change on this branch deploy to main?

The redeploy verification step gains the failure mode it did not have: **a fetch seconds after a good deploy
can be a cached 200 with the old body**, which is indistinguishable from the silent-inactive-version failure
the step was written to catch.

**Measured on the `v4.18.0` redeploy, August 21, 2026, doing exactly what the skill says.** `npx wrangler
deploy` reported success and printed a version id. The first fetch of the worker URL answered **HTTP 200
with 265,415 bytes** -- against the 352,146 just built -- carrying none of the new release's rows and none
of the new template's `Version X.Y` labels, so it was not merely the previous release's page but a build
from before the template's second pass. A second request with `Cache-Control: no-cache` and a throwaway
query string returned **352,146 bytes, byte-identical to the built file**, and three subsequent plain
fetches agreed. Nothing had been wrong with the deploy at any point.

**Why this is worth writing down rather than shrugging at.** The paragraph above it tells a reader to
verify against the served bytes precisely because a deploy can report success while the live page stays
old -- so the observation *"200, old body"* already has a documented meaning, and it is the wrong one here.
A reader following the page in good faith concludes the documented failure has just happened. The cheap
next step is a second deploy; the expensive one is `-InitToken`, on the theory that the route is wrong,
which is the one action the skill spends a whole section warning never to take casually, because a new
token 404s every link already sent. So an unqualified check pointed at the most destructive available
remedy.

Both halves of the fix, because they reach different moments:

- **[the `release-notes-page` skill](plugins/workflows/workflow-davekjohn/skills/release-notes-page/SKILL.md)**
  gains the measurement and the ordering rule: fetch, and if the bytes are stale fetch again cache-busted
  *before* believing it, comparing against the built file with `cmp` rather than by eye -- a size that
  merely looks plausible is how a half-updated page passes.
- **the build script's own closing advice**, in both mirrors, since that is the line somebody actually reads
  at the moment they deploy rather than the page they read once. It now says to fetch twice and why. Held
  byte-identical by the shared-script drift lint, and ASCII, per the script layer's rule.

**What is deliberately NOT done.** No retry or cache-busting logic is added to any script: the script does
not deploy and does not fetch, and giving it either would make it the thing that verifies its own
publication. And no claim is made about *which* cache answered -- edge, intermediary or local -- because
one observation cannot tell them apart and the remedy is the same either way.

**Score:** 3

#### What makes this change extra special

Every consumer who hosts this page meets this on their first redeploy, and the skill had walked them into
reading a success as the one failure it documents. The asymmetry is what makes it worth a 3 rather than a 1:
the false negative is cheap to disprove -- one more request -- while the action it invites is the single
irreversible one in this whole surface, since a regenerated path token silently breaks every link already
sent to management or a commissioner. A check that points at that remedy on a false reading is worse than
no check.

The transferable half is the sentence rather than the mechanism: **a stale read and a failed publish are
indistinguishable from one request**, so any instruction to "verify against what the URL serves" owes its
reader a second read. That generalises past this worker to anything fronted by a cache, which is most
things somebody is told to go and look at.

**Score:** 3

### Pull Request · 20260822-003327

The redeploy check says to fetch twice, because the first fetch can be a cached miss

Plugins: workflow-davekjohn

[PR #830](https://github.com/DaveKJohn/claude-code-specialists/pull/830)

---

## `docs/v4-18-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.18.0 release
document froze at **43m 55s** because three of its legs were still running on the file it was written into --
its own local gates, its CI and merge, and the publish. Those legs now have clock readings, so the total goes
in: **63m 33s** end to end, 19:09:35 to the Release published at 20:13:08, with the note's local gates and
push **4m 37s**, its CI and merge **14m 19s**, and the fold plus publish **42s**.

**Two of this release's readings invert what the previous six supported, and both are stated as mechanisms
rather than as numbers.**

- **The head is 58% of the release** -- 36m 37s of 63m 33s to the tag being pushed -- against 18% at v4.17.0
  and 21% to 32% across v4.12.0 through v4.16.0. Every earlier reading said most of a release happens after
  the version number exists. The reason this one says the opposite is that **a blocked cut moves work into the
  head**: the cut refused on a red test gate, and the 31m 50s of diagnosing and shipping that unrelated repair
  all fell before the tag, because nothing downstream could start until it merged. So the head/tail split
  measures where the obstacles were rather than where the effort inherently is.
- **The unmeasurable share is 31%**, against 65% at v4.17.0, 66% at v4.4.0 and 70% at v4.16.0. Same cause
  read from the other end: the tail a document cannot time about itself is roughly constant per release, so it
  looks small here only because the head was abnormally large.

**And the total is nearly double the previous longest for a reason that is not its size.** 24m 34s for
v4.15.0's thirteen entries, 25m 29s for v4.16.0's four, 32m 19s for v4.17.0's nine, 63m 33s for this one's
fifteen. The spread has never tracked the entry count and still does not. What made this release expensive is
that it needed **two** pull requests where a release normally needs one -- a repair before the cut, then the
note -- and therefore two full CI cycles. CI is the largest single cost in here at **23m 12s**, or **37%** of
the release.

**The first pass's reading about which check governs the merge is CORRECTED here rather than confirmed**, which
is the part of this branch worth more than the total. That pass had one data point -- the repair's pull request,
where the required `lint-en-tests` took 8m 37s against `claude-review`'s 3m 02s -- and concluded the ordering
had reversed from v4.17.0. This note's own pull request says the opposite: `claude-review` **14m 05s** against
`lint-en-tests`'s **9m 58s**. Across three readings the tally is **two to one** for the non-required check
governing the wait, so the direction of the evidence is the same as v4.17.0's after all, and the even split the
first pass implied was an artefact of measuring once. The unstable quantity turns out to be `claude-review`'s
own duration -- 3m 02s and 14m 05s on two pull requests forty minutes apart -- rather than the ordering, which
is a different question from the one that was being asked. Still named and not repaired: a check whose runtime
varies fourfold is the thing to understand before changing what a merge waits on.

The note's open section also gains the standing line that the attachment carries the frozen subtotal only and
is deliberately not swapped -- extended this time to say that the same second pass corrected a reading, so a
reader holding the attachment knows there are two reasons to prefer the page.

**Score:** 2

#### What makes this change extra special

It puts a fourth consecutive end-to-end measurement beside the first three, and this one is the first that
**breaks** the pattern the other three built rather than adding to it. A reader who saw only the four totals
would conclude that releases are getting slower as they get bigger; the measurement says the opposite, and
names the mechanism -- one blocked cut, two CI cycles instead of one.

For a consumer running this workflow the transferable part is a diagnostic they can apply without any of these
numbers: **when a release runs long, check whether it shipped one pull request or two before assuming the work
grew.** A release that had to repair something before it could cut pays for a whole extra CI cycle, and that
cost lands in the head, where the earlier readings had taught everyone not to look.

The correction is worth its own line for the same reason the first pass was: a timing is a count, and this one
was taken once. Publishing an even split off a single pull request and then finding the opposite on the next
one is precisely the recount discipline the house rules ask for, applied to a figure written an hour earlier by
the same hand.

**Score:** 2

### Pull Request · 20260821-223214

The v4.18.0 release note gains its end-to-end total

[PR #829](https://github.com/DaveKJohn/claude-code-specialists/pull/829)

---

## `docs/v4-18-0-release-note` deployment

### What does the change on this branch deploy to main?

The hand-written release document for v4.18.0. The cut drafts it from the tier-2 entries in the words their
authors wrote for a diff reviewer and commits it inside the tagged release commit; this is the rewrite for
somebody deciding whether to update, held against the seven tests in the `cut-release` skill. **1,100 draft
lines became 304**, which is the largest reduction this document has had to make -- v3.2.0's was 1,098 to 153,
but that draft still carried every category, and this one is fifteen tier-2 entries with nothing to discard.

**The ordering decision is the whole of the editorial work here, and it is a merge rather than a sort.** Four
of the fifteen entries are repairs to the same script -- the `team-shopify` pre-task sync -- filed and fixed
separately, scored 5, 5, 4 and 4. For a reader they are not four items: they are one script, one update, and
one dry run. So they open the page as a single section with the four repairs listed inside it, ordered by which
bites first, and the section says plainly that it is the one item in the release with a deadline. Presenting
them as four sections would have been faithful to the entry set and wrong for the reader, who would have had
to work out that all four resolve to the same command.

The remaining eleven are ordered by whether they carry an action, and the two that change what a consumer's own
tooling **refuses** are placed above the ones that only add a capability -- a cut that stops working and a push
that stops working are the two things somebody meets without asking for them. Three carry no action at all and
say so under their own heading rather than leaving it to be inferred (test 4).

Every mechanism the page tells a reader to invoke was read in the tree rather than carried over from an entry
body: `sync-main.ps1`'s `-DryRun` and the retired `-SkipPull`, `push-preview.ps1`'s four-step resolution,
`cut-release.ps1`'s `-Type`, `prune-merged.ps1`'s two proofs, and `Get-ShopifyPreviewUrls` being optional while
`Get-ShopifyLiveThemeId` is recommended here and required for the sync. That check is why the preview section
states the asymmetry between the two seams instead of repeating the sync's requirement.

Both organisational sections are written. *What it is worth* leads on the signature the four sync repairs share
-- no error, no warning, a green run -- and on the zero-false-positive/ten-of-eleven measurement that chose a
redesign over a fifth flag. *What was still open* is a snapshot with every figure read at its source: the
publication target at `84e6316` with all four team plugins at 4.16.0, now two releases behind, and all four
registered consumers one release behind as of this cut, read from `check-connectors.ps1` rather than from a
document.

**Score:** 2

#### What makes this change extra special

It is the one document a consumer reads to decide whether to update, and it reaches every one of them as an
attachment on this release's GitHub Release.

The item that earns the top of the page is the one where doing nothing is invisible until it has already
happened. Both Shopify consumers are running a sync measured to revert merged work, and one of them carries a
temporary hook routing its own sessions away from the shipped skill -- a workaround whose stated removal
condition is this release. The page gives them the three commands in the order that makes the dry run useful,
names what the sync now refuses to do at all, and says which flag is gone, so converging onto it does not read
as handing a script more authority than it has.

This page also carries the first timing pass, and this release's reading is unusual enough to be worth the
line: **73%** of the run went on a red test gate that had nothing to do with the release. That is the number a
later reader would otherwise have to reconstruct, and it is the kind that only exists if somebody starts the
clock before the first command.

**Score:** 3

### Pull Request · 20260821-221226

The v4.18.0 release note

[PR #828](https://github.com/DaveKJohn/claude-code-specialists/pull/828)

---

