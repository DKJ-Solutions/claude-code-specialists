# Changelog

Everything merged since the last release sits under **`## [Unreleased]`**, **newest first**: **one `###` per
change**, and under it two named `####` sections. The `###` heading is the change's own —
`` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `#### What makes this deploy extra special` for the second audience, and `#### Pull Request`.
Every level here moved one deeper on August 26, 2026, when the pending section above them was introduced and
the development cycle beside them shifted to match; entries written before that day carry the whole set one
level shallower and are read exactly as they always were.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
[`releases/history.md`](releases/history.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`contributing-davekjohn/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## [Unreleased]

### DEPLOY: `fix/check-wait-zero-date-overflow-v1` · 20260827-154618

`ship-pr` no longer dies between the merge decision and the merge when a check registers while the CI
wait is returning. `gh pr checks --json` serialises a check that has not finished yet as the zero time
`0001-01-01T00:00:00Z` -- not as null, not as an empty string -- and `ConvertTo-CheckTimestamp` accepted
it as a real timestamp, so the caller's own "unreadable, skip this record" guard never fired and the
`[int]` cast in the DarkGray *which check governed the wait* line overflowed on 63.9 billion seconds. A
reporting line took the run down after it had printed `CI green.`, leaving the PR unmerged and the entry
unfolded with every check green -- the half-state the step's own comment calls "the state nothing
reports". The zero time is now unreadable in both shapes gh can send it in, so an unfinished check drops
out of the ordering it never belonged in, and the seconds arithmetic rounds and range-checks before it
casts, at both sites, so no timestamp from that payload can throw there again.

**Score:** 3

#### What makes this deploy extra special

Every consumer runs this code from their plugin cache, and the failure window is not rare: the CI wait
is the one place in `ship-pr` that is guaranteed to be racing GitHub, so any check that registers while
`--watch` is returning is in it. It cost a real run in `BWJ-ecommerce/xoxowildhearts` (PR #68), which is
where #977 was filed from -- and the recovery reads as a fluke rather than a fix, because re-running a
few minutes later merges cleanly once the check has a real `completedAt`. The consumer-visible half is
therefore not the crash but the trust: a ship that stops after `CI green.` no longer leaves anyone
guessing whether the merge happened.

**Score:** 4

#### Pull Request

A not-yet-finished check's zero timestamp no longer kills ship-pr after CI is green

Plugins: contributing-davekjohn

[PR #986](https://github.com/DaveKJohn/claude-code-specialists/pull/986)

---

### DEPLOY: `fix/remove-lock-and-handover-v1` · 20260827-153226

Removed the `/lock` and `/handover` skills, and with them the one reporter both wrapped
(`scripts/task/session-status.ps1`, its plugin mirror and its 636-line suite) --
[#957](https://github.com/DaveKJohn/claude-code-specialists/issues/957), Dave: the branch's own
development cycle has taken over the job of recording where the work stands, so a gitignored lock file
records nothing the tree does not already say. Full removal was his call when the alternative
(re-homing the reporter under `/park`) was put to him.

The removal is not free-standing, and three gates said so: `[skill-param]` refuses a shared-scripts
registry entry naming a `SKILL.md` that does not exist, `[skill-list]` holds both marked spans in
`README.md` to the real skill set, and the dead-link scan catches the pages that linked the two skills.
So the registry entry, the two seam registrations naming the reporter as a reader, `.gitignore`'s
`.claude/handover.md` line, both cost baselines and every live claim about the script went with it.

**Two consequences, both accepted rather than papered over.** The park note keeps its writer and loses
its automatic printer: `git log -1 --pretty=%B origin/<branch>` is now the only way to read it, and every
doc and comment that promised the printout says so instead. And two pins that needed *a* reader, not that
particular one, were re-pointed at `build-release-notes-page.ps1` -- which reads the same note-root seam,
verified in the code rather than assumed.

**What deliberately stayed** is the history: `CHANGELOG.md`, the release notes, and the dated measurements
that merely record where a lesson was learned. A past-tense measurement does not become false when its
subject is deleted. Two portable lessons the deleted script *did* carry -- the `2>$null`-makes-`catch`-
unreachable trap and no-`return`-at-script-scope -- were kept and reframed, because neither is about the
file they were measured in.

Net always-on cost: the two skills were 380 tokens per session; Chris's lens grew by ~100 taking in the
briefing mode whose portable home was the `/handover` page, so every session is roughly 280 tokens lighter.

**Score:** 4

#### What makes this deploy extra special

N/A -- nothing here reaches a service subscriber. `/lock` and `/handover` were a session-management
convenience for whoever authors work in this repo and its consumers, never anything an end user of a
published product could see.

**Score:** N/A

#### Pull Request

Remove the /lock and /handover skills and their session-status reporter

Plugins: contributing-davekjohn

[PR #984](https://github.com/DaveKJohn/claude-code-specialists/pull/984)

---

### DEPLOY: `feat/workflow-folder-holds-the-repo-documents-v1` · 20260827-150731

Every document the contribution cycle produces or governs now lives in `contributing-davekjohn/`.
`CHANGELOG.md` and the release list moved in -- the list as `history.md`, because that folder's
`releases/README.md` is its seam-answers page -- and the root `CONTRIBUTING.md` was folded into the
folder's own contributing page rather than moved beside it. The tooling followed through the seams that
already existed for exactly this: `Get-ChangelogPath`, `Get-ReleaseHistoryPath` and
`Get-ReleaseInternalNotesRoot` are now stated in `scripts/repo-config.ps1`, so this repo stopped being the
one repo answering them differently from every consumer. Nothing about a consumer changed -- those
defaults have pointed into the workflow folder since #885.

Three records were amended rather than silently flipped, because each one argued for the root and the
argument has to stay legible: the August 19, 2026 answer at `Get-ReleaseHistoryPath` (its premise, "a
folder a teardown removes", expired when #885 made that folder permanent), the August 14, 2026 layering
note the root contributing page carried, and the two contract records a consumer reads.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing published changes. The plugins, their skills and every seam DEFAULT are untouched; what
moved is where this one repo keeps its own documents. The one consumer-visible edit is a paragraph in
`RELEASES-portable.md` that had described the source's layout as if it were a rule, which it never was.

**Score:** N/A

#### Pull Request

the workflow folder holds the changelog, the contributing page and the release history

Plugins: contributing-davekjohn, team-alpha

[PR #980](https://github.com/DaveKJohn/claude-code-specialists/pull/980)

---

### DEPLOY: `docs/inbound-sixth-pattern-mirror-in-the-reporters-tree-v1` · 20260827-142712

Triaging an inbound item now checks six things instead of five, and the sixth is **which tree the symptom
is in**. Every earlier check holds the report against the tree you are standing in and quietly assumes
the defect is there too; a reporter measuring from another repo can be right about the symptom, the
reason, the line number and the 404, and wrong about whose file it is. The rule half lands in Chris's
always-on body -- resolve the path in your own tree before accepting the attribution, and where it
resolves to nothing the finding has neither collapsed nor been repaired -- and the measurement lands in
the `triage-inbound` skill.

The instance is [#954](https://github.com/DaveKJohn/claude-code-specialists/issues/954), closed
August 27, 2026. It reported two dead `plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md`
blob URLs above the horizontal rule in `releases/README.md`, verified 404 against the new path's 200.
Every fact was true, and none of it was here: the tree returns **zero** live hits for that path, and that
page has no horizontal rule at all. `94476de6` (August 13, inbound #646) moved the mirrored process half
out of the file and into `RELEASES-portable.md`, taking both URLs with it; `8797f7a5` (August 26, #886)
corrected the path in its new home. The links are in the reporter's
`contributing-davekjohn/releases/README.md` -- a different path than the report names, whose own
`releases/README.md` returns 404 -- at lines 196 and 289, above the rule at 336.

**What made it invisible is the report's own justification**, which is the half worth distrusting: *"the
content above the rule is a verbatim mirror of the source's page, so a local fix would just restart
drift."* Sound reasoning from an identity the two trees had stopped sharing thirteen days earlier, ended
by the very change that ended the mirroring. Being identical is a mirror's whole design, so its content
can never tell you which side you are reading -- date it instead. Line 482 of their copy still describes
`RELEASES-portable.md` as a proposal, which pins the mirror to before #646 landed. And a mirror retired
upstream makes the proposed fix the wrong fix: repointing two URLs preserves a ~4,000-word hand-maintained
copy of a process half that no longer exists, which is the exact cost #646 was filed to end.

For somebody maintaining this repo the gain is one grep at intake and a closure that tells a reporter
something they could not have worked out themselves. It is a 2 rather than higher because the check was
already run in the triage that produced it -- what lands is the written form, and it is noticed on the next
inbound rather than today.

**Score:** 2

#### What makes this deploy extra special

Chris's body is loaded in every session of every repo that enables `team-alpha`, so this arrives on a
plugin update whether or not anyone asked for it -- which is the reason its size was measured rather than
estimated. The first draft cost **1,528 B**; what ships is **1,143 B**, about 285 tokens per session, and
the trim took out the generic restatement rather than the tell.

The check reaches a consumer in the direction they actually meet it. They do not receive inbound from
consumers of their own, but they do receive reports -- from a session, a teammate, their own earlier
notes -- about content they mirror from here, and the whole family of `*-portable.md` pages plus the
above-the-rule half of the workflow folder's pages is mirrored content by design. #954 is what that looks
like from the other side: a careful reporter, correct measurements, and an attribution built on a sharing
relationship that had already been dissolved upstream. The paragraph that helps them most is the one
saying a stale mirror can be dated from inside itself.

**Score:** 2

#### Pull Request

the triage skill carries a sixth inbound pattern: the symptom is real and it is in the reporter's tree

Plugins: team-alpha

[PR #979](https://github.com/DaveKJohn/claude-code-specialists/pull/979)

---

### DEPLOY: `fix/park-names-what-backs-the-ticks-v1` · 20260827-132350

Every automatic park commit now says what is behind the plan it publishes. `park-cycle` measures three
figures before it commits -- how many of the document's steps are resolved, how many files are committed on
the branch besides that document, how many are uncommitted in the working copy the park came from -- and
writes them into the commit body as a `Backing:` line. Where the plan reads as **finished** with nothing
behind it, an alarm paragraph says so in as many words and names the wrong move. `session-status` prints the
note back under every parked branch, so `/lock` and `/handover` surface it without a checkout, and says
plainly where there is none.

The state it exists for was measured here on August 27, 2026
([#960](https://github.com/DaveKJohn/claude-code-specialists/issues/960)).
`feat/adopt-act-on-this-skills-v1` sat on origin with three `park:` commits, eight resolved CREATE steps
naming edits to three agent defs, three manuals and two lenses -- and a diff against `main` consisting of
the cycle document alone, 161 insertions, one file. The edits were uncommitted in the other device's working
copy, which no reader of origin can see. `#900` publishes the plan so a second device can read it, and on
that branch it delivered the plan and inverted its purpose: from origin, *ticked and committed* and *ticked
and uncommitted somewhere else* are the same document, and the more complete the ticks, the more convincing
the wrong reading. A session picking it up in good faith either rebuilds eight changes that already exist,
or opens a PR that merges 161 lines the fold then deletes.

Four bounds decide the shape, and each of them was the alternative. **It is a note, never a gate** -- a park
that refused because it disliked the plan would be worse than the misleading document, because then the plan
would not reach the other machine at all. **Counts, never filenames** -- the uncommitted figure describes
work nobody asked to publish, and listing those paths would defeat bound 1 (one document, never
`git add -A`) one layer along. **The alarm fires on the finished shape only**: any resolved step with nothing
committed would fire on nearly every early park, because a planning step ticked before a line of code exists
is the ordinary case, and an alarm that fires on almost every park is one nobody reads by the time it
matters. **And the measurement lives on the machine that holds the invisible work**, taken at the moment it
becomes invisible -- nowhere else can take it, since from origin those files do not exist. That is also why
the reader only echoes the line: a local recount would report 0 for a branch whose commit says 12, and the
wrong number would be the confident one.

The branch also repaired a defect it exposed rather than filing it, because it is one resolution in the block
being edited: `session-status` was **listing the trunk as a parked branch**. It read the trunk from
`refs/remotes/origin/HEAD` alone -- a ref a locally-initialised repo does not have -- and fell back to the
literal `main`, so any repo whose trunk is named otherwise saw its own trunk in the one block that exists to
show work that is *not* on the trunk. The suite's negative assert had been passing on a newline-removal
artefact, with `master` and the next section's `Open` running together into one word so `\b` never matched.
The trunk now comes from `git ls-remote --symref`, which asks the remote rather than a local ref and needs no
seam, in the same call the branch list comes from.

For somebody maintaining this repo the gain is that a parked branch can no longer lie about itself, and the
cost is a handful of lines in a commit body nobody has to read. It is a 3 rather than higher because it
changes no chain and blocks nothing -- but the state it describes has already cost one triage here, and the
next reader of that branch would have paid for it in rebuilt work.

**Score:** 3

#### What makes this deploy extra special

The same mechanism through a plugin update, and for a consumer the exposure is larger rather than equal: the
two-device split this was measured on is the ordinary shape of working from a laptop and a desktop, and
`park-cycle` runs on their Stop hook exactly as it does here. What arrives is `park-cycle.ps1`,
`session-status.ps1` and both libs behind them, so nothing has to be configured -- `Get-GitParkBacking`,
`Format-GitParkBacking` and `Get-GitParkBackingMarker` are available to any other script of theirs that has
to judge whether a plan has work behind it, and `Get-BranchProgressTally` answers "how does this step list
stand" for any caller that until now had only the gate's yes-or-no.

The trunk repair reaches them harder than it reaches this repo, which is the part worth reading twice. This
repo's trunk is `main` and its checkout was cloned, so `refs/remotes/origin/HEAD` exists and the defect never
fired here. A consumer who ran `git init` and added a remote afterwards has no such ref, and one whose trunk
is `master` -- or any name that is not `main` -- has been seeing their own trunk reported as a parked branch
every time they ran `/lock` or `/handover`. That is the single most misleading line the block can print: it
sends a reader looking for work on the one branch where the work has already landed.

The `park` skill's pick-up section gains its second trap beside the one it already carried. The first asks
whether a parked plan has been **overtaken** -- measured August 4, 2026, a plan superseded 1h43m after it was
parked. This one asks whether it was ever **carried out**. The two are independent and both are one command;
a plan can pass either and fail the other, and the skill now says so with the command that answers each.

**Score:** 3

#### Pull Request

The park commit names what is behind the ticks

Plugins: contributing-davekjohn

[PR #976](https://github.com/DaveKJohn/claude-code-specialists/pull/976)

---

### DEPLOY: `fix/entry-link-gate-follows-changelog-v1` · 20260827-131311

`open-pr`'s link gate resolves the entry's relative links from the directory the fold actually writes into,
read through `Get-ChangelogPath` exactly as `fold-changelog-entry` reads it, instead of from the repo root.
The sentence the branch document states about that base is composed from the same value rather than typed, so
the file an author is writing in and the gate that refuses them cannot disagree.

Nothing about this repo's own behaviour changes, and that is worth saying plainly: it publishes a marketplace,
so its changelog is the root file, the base resolves to `''`, and every existing assert holds word for word.
What changes here is the plumbing -- two new functions, a parameter on three call paths, and eleven asserts.

The base was hard-coded to the root by [#806](https://github.com/DaveKJohn/claude-code-specialists/issues/806)'s
repair, which was correct when written: every repo's changelog was at the root. [#914](https://github.com/DaveKJohn/claude-code-specialists/issues/914)
moved the destination and left the gate measuring from the old one -- the shape this repo has now paid for
twice in one area, and the second instance is the one that reached a consumer.

**The report named three sites and there are eight.** Recounted before scoping, per the inbound rule: the two
comment blocks that stated the root as a fact, the visible guidance block, `DEVELOPMENT-portable.md`, the
`open-pr` skill page, this repo's own `CONTRIBUTING.md` and its own lint. Two of those eight are deliberately
left alone -- both correct as written, and both correct for the same reason, which is that this repo genuinely
does fold into its root. Naming them is the point: a sweep that "fixed" them would have made this repo's own
answers page state a base its fold does not use.

**Two things the work found that the report could not.** The suggestion was a substring of the resolved path,
which answers only a target underneath the base -- so an isolated destination with a target beside it produced
a finding and no repair. And a root-relative link at a folder destination was refused with nothing suggested,
which is exactly the author who did as the old guidance told them. Both were found by probing the function
rather than by reading it, which is why the probe is in the branch's TEST list and not only in its plan.

**Score:** 2

#### What makes this deploy extra special

A consumer on the shipped defaults gets a link gate that stops being wrong about their repo. Since 4.20.0
their `CHANGELOG.md` sits in `contributing-davekjohn/` -- the same directory as `development-cycle.md` -- and
until now the gate refused the link form that is correct after the fold and demanded the form that is dead,
with no `-Force` to get past it. The document they were handed told them to write the dead one, in bold, in a
blockquote at the top of the file. Met in `BWJ-ecommerce/xoxowildhearts`, whose own doc lint measures from the
folder: its two gates disagreed, so its entries avoided relative markdown links altogether.

Three things arrive together, which is why this is worth more than a gate fix. The **refusal** now names the
two directories it actually compared, rather than the repo root and a `branch/` path that stopped existing
when the entry became a section of the cycle document -- on the shipped defaults it named two paths, neither
of them in play. The **suggestion** names the form that destination needs, and tries the root as a second base
so the author who followed the old wording is told what to write rather than only that they are wrong. And
the **guidance** in every newly created cycle document states that repo's own base, so the instruction and the
gate come from one value.

Nothing has to be configured, nothing has to be migrated, and an entry already written keeps folding: a repo
that repoints `Get-ChangelogPath` back to the root gets #806's behaviour unchanged, because there the root
genuinely is where the text lands.

**Score:** 4

#### Pull Request

The entry's link gate resolves from where the entry lands, not from the repo root

Plugins: contributing-davekjohn

[PR #975](https://github.com/DaveKJohn/claude-code-specialists/pull/975)

---

### DEPLOY: `fix/ship-gates-read-pr-commit-v1` · 20260827-123549

`ship-pr`'s two gates before the merge -- the step-list gate and the DEPLOY lock -- now read the branch's
own commit, `refs/heads/<branch>`, instead of the file on disk. They read the checkout until now, on a
reasoning the script stated out loud: *"HEAD is still on the branch at this point -- step 5 is what moves to
main."* That is true of a foreground run and false of the shape this script invites, because it waits on CI.

The reason it needed doing is measured twice, and the second instance is what turned a written-down trap
into a defect. On August 20, 2026 two sessions shared one checkout. On August 27, 2026 it needed no second
session at all: one session backgrounded the ship and started the next piece of work while `lint-en-tests`
ran for 10m57s, and the gate refused PR #969 over `- [ ] TODO: the first step of this branch` -- the verbatim
scaffold TODO of a branch created *during* the wait, while PR #969's own document had no open step at all.
Both refusals were safe, and that is what made them easy to leave alone. **The same assumption fails the
other way in silence**: the shipping PR carries an unresolved step, the checkout has since moved to a branch
whose steps are all ticked, and the gate passes on somebody else's document and merges. A gate with no
`-Force`, satisfied by a file the PR does not contain, reports the requirement as met while nothing checked
it -- and the DEPLOY lock is the worse half of the pair, because the section it guards is what step 5 folds
verbatim into `CHANGELOG.md`.

Two things this deliberately does not do. **It does not refuse when `HEAD` has moved**, which was the other
shape on the table: the report itself names a backgrounded ship beside the next piece of work as the ordinary
shape of that window, so that guard would break the ordinary case in order to protect it -- and nothing
downstream needs the checkout to have stayed put, because step 5 checks out the trunk and folds from there
whichever branch it was standing on. **And it does not touch `open-pr`'s copy of the gate**, whose window is
the moment between reading and pushing rather than eleven minutes of CI; where an uncommitted tick gets past
it, the merge gate now catches it, which is the layering working rather than a hole.

For somebody maintaining this repo the gain is a merge gate that cannot be answered by the wrong file, plus
one behaviour worth knowing at the keyboard: a step ticked in the editor and never committed no longer gets
past it. Both messages have always said *"commit, and re-run"*, so the gate has caught up with what it asks.
It is a 3 rather than higher because it changes no chain and blocks nothing that was landing before -- but the
confusing half has now fired twice in eight days, and the silent half is on the merge path.

**Score:** 3

#### What makes this deploy extra special

The same repair, through a plugin update, and the exposure is identical: `ship-pr` waits on their CI too, and
a consumer with a long-running required check has the same eleven-minute window in which a session can start
the next branch. What arrives is `ship-pr.ps1` plus both libs it reads the commit through, so nothing has to
be configured -- and `Get-GitFileTextAtRef` is available to any other script of theirs that has to judge a
commit rather than a checkout.

The `ship-pr` skill page changes its claim rather than gaining a note: its section used to be titled *"The
step-list gate reads the WORKING TREE, and one thing breaks that"* and told the reader to compare
`git rev-parse --abbrev-ref HEAD` against the PR's head ref by hand when a refusal named a step they did not
recognise. That advice is now obsolete, and a page that keeps it would send someone hunting a mismatch the
script no longer has. The portable contributing page names the second read at the merge in the same movement.

A 3 there for the same reason as above, and no higher: nothing they have written stops working, and no
migration is asked of them.

**Score:** 3

#### Pull Request

The merge gates read the shipping branch's own commit, not the working tree

Plugins: contributing-davekjohn, team-alpha

[PR #973](https://github.com/DaveKJohn/claude-code-specialists/pull/973)

---

### DEPLOY: `fix/seam-isolation-legacy-root-v1` · 20260827-121838

`Assert-WorkflowIsolatedSeamPath` could not tell a typo from a layout, and treated both as a typo. It
refuses with `exit 1` and had no opt-out, so a consumer that had been folding into a root `CHANGELOG.md`
since before the workflow folder existed was hard-blocked at the fold — after the merge had already
landed. It now accepts two answers instead of one: the folder, and the seam's **own** pre-isolation
target, looked up per seam by `Get-PreIsolationSeamPath`.

Per seam is the load-bearing half. `CHANGELOG.md` is a legal answer for `Get-ChangelogPath` and stays
refused for `Get-ReleaseGithubNotesRoot`, and `README.md` — the case the guard exists for, and the one its
own docstring names — is still refused for all five.

For this repo the reach is nil, and that is worth stating plainly rather than dressing up: a source repo
(`marketplace.json` present) is exempt from this assert outright and always was, so nothing here behaves
differently. What lands here is a lib, a suite that grew from 25 asserts to 37, and the record of why the
shape #956 proposed first was declined.

**Score:** 1

#### What makes this deploy extra special

**A blocker that is gone, and the reader has to act to collect it.** Two consumers answer this seam at
their repo root, independently: `smartwatchbanden` (14 pending entries, set in its own 4.20.0 adoption
commit) and `xoxowildhearts` (24). For them the fold and the cut were refused outright, and the
work-arounds were real ones — `xoxowildhearts` folded by hand under its documented fold exception, and
moved its `CHANGELOG.md` into the workflow folder purely to get past this guard. Both can be dropped
now, and the moved file can move back.

They notice this the moment they merge anything, without being told, because the failure they were
meeting was total. The one thing they have to do is stop working around it.

It reaches every other consumer as nothing at all: a repo already inside the folder passes the assert
exactly as before, and a repo with a genuine typo is refused exactly as before, now with a message that
names the answer it wanted.

**Score:** 5

#### Pull Request

A consumer's pre-isolation root answer stays a valid seam target

Plugins: contributing-davekjohn

[PR #971](https://github.com/DaveKJohn/claude-code-specialists/pull/971)

---

### DEPLOY: `fix/review-quota-names-itself-v1` · 20260827-115413

A red `claude-review` now says why it is red where a reader actually lands -- in the run's annotation
list and on its summary page -- instead of only in the body of a diagnostic step's log. #913 put the
reason in that log; this puts it in front of the person reading the PR.

The reason it needed doing is that the log was not enough, measured rather than supposed. #966 was
filed against a run whose log already read `api_error_status: 429` with
`result: You've hit your session limit`, and concluded the cause was an expired OAuth token and the
repair a rotated secret. Neither is true: the token authenticates, the account behind it is out of
session quota, and there is nothing to rotate. The line a reader meets first was the action's own
`Claude result reported subtype success with is_error:true`, which names nothing at all.

Two things this deliberately does not do. **The check stays red on a 429** -- that means the PR got no
review, which is exactly what #966 wanted not to be silent, and a green check would hide it better
than an unreadable red one. **Quota consumption is untouched**: `CLAUDE_CODE_OAUTH_TOKEN` is a
subscription credential, so the session window it draws on is the same one interactive use draws on,
and a morning of heavy local work starves the review of every PR opened in that window. Whether the
review earns its share of that window is a decision about what the dependency is worth, not a defect,
and the workflow now states the mechanism so the next reader does not have to rediscover it.

For somebody maintaining this repo the gain is one specific hour back: the next time this goes red,
the summary page says `out of quota -- the review did not run` and nobody re-derives the credential
hypothesis. It is a 3 rather than higher because it changes no gate, blocks no merge, and is noticed
only on a failing run -- but this has now failed on four runs across two days, so that is not rare.

**Score:** 3

#### What makes this deploy extra special

Nothing reaches that reader. `.github/workflows/` is this repo's own CI and ships in no plugin, so a
consumer sees none of it -- not the workflow, not the diagnostic, not the annotation.

**Score:** N/A

#### Pull Request

The 429 review failure names its own reason where a reader sees it

[PR #968](https://github.com/DaveKJohn/claude-code-specialists/pull/968)

---

### DEPLOY: `feat/adopt-act-on-this-skills-v1` · 20260827-110818

Two built-in skills that look like a pair are split along the line that actually separates them:
`code-review` **reports**, `simplify` **applies**. The reporting skill was wired into two reviewers with
its flags unmentioned, and the applying skill was mentioned nowhere in the repo at all — so this closes
both halves at once. Victor #19 and Edith #17 are now told that `--fix` and `--comment` sit outside their
boundary rather than inside their tooling; Cody #13 gains `simplify` as the author's tidy pass before the
handover; and Chris's routing plus Sylvester's lens name Sylvester the author who runs it here, because
in this repo the code is `scripts/**`.

For somebody maintaining this repo that is two concrete answers where there were none: a review never
reaches for either flag, and "tidy this up" routes to the author rather than to the reviewer. Nothing
already written stops working, which is what keeps this at 3 — it is noticed the moment somebody runs a
review or finishes a script, not before.

**Score:** 3

#### What makes this deploy extra special

A consuming repo receives the portable half through the next release, and only one third of it is
observable there: **Cody hands over tidied code where he previously handed over untidied code.** The other
two thirds prevent a failure rather than deliver a feature, and the rubric asks for that failure to be
named — a reviewer who reaches for `code-review --fix` has silently applied his own findings, which is the
exact act his boundary forbids, and one who reaches for `--comment` has written on a PR that belongs to
the git role. Neither had anything telling them so.

Sylvester's half deliberately does not travel. His shipped scope is the harness; `scripts/**` is this
repo's own extension to it, so naming him the script author in the portable layer would have claimed that
authorship in consumers that never granted it.

**Score:** 2

#### Pull Request

Adopt the two 'Act on this' built-in skills into the specialists chain

Plugins: team-alpha

[PR #964](https://github.com/DaveKJohn/claude-code-specialists/pull/964)

---

### DEPLOY: `fix/fold-legacy-entry-level-v1` · 20260827-104841

The fold brought a legacy entry to the current heading level by rewriting its first line, and it found that
line with a range derived from today's level -- `#{level,level+1}`, which has read as H3-or-H4 since the
entry level moved to 3 on August 26, 2026. H4 is a level no entry has ever opened with, and H2 -- what
every entry written in the flat window (August 5-26, 2026) carries -- fell outside it, so such an entry
folded unpromoted and landed as a sibling of `## [Unreleased]` rather than a child of it. Widening the
range would have made it worse: a flat-window entry has H3 sections under its H2 heading, so lifting the
heading alone leaves entry and sections at one level and `Split-EntryBlocks` reads one entry as four.

It now calls `Set-EntryHeadingLevel`, which measures the block's own level and shifts every non-fenced
heading by that delta -- the repair the release renderers got on August 5, 2026 for the identical reason.
That function moved down from `scripts/lib/release-lib.ps1` into
`scripts/lib/entry-scaffold-lib.ps1`, where the entry format is defined and the fold can reach it, because
the fold's dependencies were narrowed to the small libs on purpose. Its inline level walk became
`Get-EntryBlockHeadingLevel`, so the shift and the fold's report of it read the level once.

Filed as inbound [#953](https://github.com/DaveKJohn/claude-code-specialists/issues/953), measured in a
consumer. Both halves are now regression-tested against a fixture in the shape a consumer actually
carries -- the suite had none, because the one legacy fixture it did have was itself rewritten to derive
from today's level and models a block with no sections to move.

For the maintainers of this repo, the same defect class ends in two places at once: one re-leveller in the
system instead of two answers to one question, and a test fixture that no longer masks the bug it exists
to catch. The fold is this repo's own release machinery, and an entry that stops being an entry boundary is
the failure shape this repo keeps paying for -- the cut leaves it out of every release document after the
entry file has already been deleted.

**Score:** 4

#### What makes this deploy extra special

A consumer who folds a pending entry written before their v4.20.0 update meets this on their next merge:
the entry lands as a stray sibling of `## [Unreleased]` and has to be repaired by hand, which is exactly
what happened in `djcylow-react`. Nothing to migrate and nothing to act on -- the repair arrives with the
plugin -- but it is noticed the moment they touch a fold with a legacy entry pending.

**Score:** 3

#### Pull Request

The fold re-levels a legacy entry whole, so its sections move with its heading

Plugins: contributing-davekjohn

[PR #961](https://github.com/DaveKJohn/claude-code-specialists/pull/961)

---

