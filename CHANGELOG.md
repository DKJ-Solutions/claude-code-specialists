# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`workflow-davekjohn/releases/README.md`](workflow-davekjohn/releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `docs/v4-11-0-release-note` changelog

### Branch title

The v4.11.0 release note

### Branch ID

20260815-153845

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this afternoon: the consumer section rewritten from
the cut's draft against the seven writing tests, and the two organisational sections no script can
generate.

**The migration item leads for a second release running, and the wording changed rather than being
copied.** A consumer updating from 4.8.0 or earlier straight to *4.11.0* is no more carried past
v4.9.0's two actions than one updating to 4.10.0 was, so the item stands -- but it now says so in those
terms and points at both intervening notes, because the reader arriving here has a longer gap to cross
than the reader of the previous note did. Test 3 orders by urgency rather than by which release a change
belongs to.

**The prompt inbox is written as what the reader can do, and the adoption command was verified against
the tree before it was printed.** `adopt-workflow-folder` is what places `workflow-davekjohn/prompts/`
(`scripts/task/adopt-workflow-folder.ps1`) and `/prompt` is a real skill in the plugin's `skills/`
directory -- both checked rather than inferred, which is the #566 rule applied to a document written to
be acted on. The untracked inbox is given as *what you are part-way through writing is yours*, not as a
`.gitignore` decision.

**The token calibration reaches a consumer as a specialist that behaves differently**, not as a
corrected figure. The 19% and the ~41,800 are this repo's numbers and stay in the lens; what a consumer
gets is Nolan naming which copy he read and how his conversion factor was arrived at. The miss is quoted
once, as the reason the rules exist, because a rule with its failure attached is the half a reader can
use.

**The release-craft move is offered as a method, because the saving demonstrably does not travel.** A
consumer's `CLAUDE.md` is their own file and nothing here edits it -- so the section says that first,
then gives the three transferable parts (separate decision from evidence, measure the block before
cutting it, move the prose verbatim). The 87% figure sits in *what it is worth* rather than in the
consumer section: it is a fact about how the split was decided here, which is test 2's line exactly.

**One entry got no heading of its own, for the second release running and for the same reason.** The
v4.10.0 timing total scored tier 2 at 2 with its author's reason ending *"nothing they do changes"*, and
its content is an internal cost measurement. It survives as one clause -- that the v4.10.0 notes ask
nothing of the reader -- under the migration item.

**`What was still open` names five items, and the first is again this document.** The end-to-end total
cannot exist while the words are being written; the merge that re-runs the tests the PR already proved
is named for the **fifth** release running; the two degraded specialists are unchanged from v4.10.0
while the organisation set is not -- it was published at 4.10.0 on 2026-08-15T10:56:22Z, so it is one
release behind rather than unpublished; and the priced options from the token measurement are
recorded as not exhausted, with the next cut owing its own measurement rather than inheriting this one's
momentum.

**Step 0a's first pass is a subtotal of 5m 25s to the pushed tag**, against `v4.10.0`'s 5m 12s,
`v4.9.0`'s 5m 36s and `v4.8.0`'s 5m 02s -- the fourth consecutive head inside a thirty-five second band,
which is the 218s test gate being the floor. About 40 seconds of it blocked a person: reading the
assembled notes before the push, and naming the release.

### Significance

#### Tier 0

The release procedure's own record of what this cut cost, written while the head still exists -- that
half is unrecoverable afterwards, which is why step 0a splits into two passes at all. It also hands the
next person the legs to add and says where they go.

**Score:** 3

#### Tier 2

This is the only document in the release that tells a consumer whether they must act, and for anyone
updating from 4.8.0 or earlier the answer is still yes -- a required migration they would otherwise meet
as a session-start `[ERROR]` with nothing in this release explaining it. For everyone else it is the
plain statement that nothing is asked of them, plus the one thing they can newly do: write an assignment
in an editor rather than into a terminal.

**Score:** 4

### Pull Request

[PR #692](https://github.com/DaveKJohn/claude-code-specialists/pull/692) · merged 2026-08-15

---

## `feat/gate-evidence-not-a-flag` changelog

### Branch title

The gate records what it proved, so the merge stops re-proving it

### Branch ID

20260816-093210

### Branch type

feat

### What does the change on this branch bring to main?

`open-pr.ps1` now records what its gates proved and against which exact working state, and skips a
gate only while that state is unchanged. `ship-pr.ps1` calls `open-pr.ps1`, so a branch opened in one
step and shipped in a later one used to run the full lint and test gate a second time on a commit
nothing had touched.

**Measured before it was built, and the figure in circulation was wrong.** Across 293 merged pull
requests the gap between the gating CI run going green and the merge landing is sharply bimodal: 205
land within 60s (median 14s), 83 land at a median of 263s, with a void between 60s and 180s and an
interior peak at 240-300s. A void followed by an interior peak is a fixed-cost operation; human delay
produces a monotonic tail with no interior peak. The one confound that could fake it was ruled out --
zero of the 83 have a `push`-event CI run on the same sha, so none of the gap is time spent waiting on
a second CI run. **So the excess is 249s on 28.3% of merges**, not the "3m 27s, 3m 18s, about three
minutes, 4m 02s and 4m 18s across five consecutive releases" the last two release notes carried. That
series conflates the whole merge-with-fold leg with the gate re-run inside it; only `v4.9.0` separates
the two, at *"3m 27s of the 3m 53s merge leg"*. The release-document pull requests are where it lands
reliably -- #692, #693 and #694 paid 819s between them for `v4.11.0` -- because that procedure opens
the note's pull request in one step and ships it in another, so it can never be a one-motion ship.

**The workaround was the actual defect.** Every one of the nine pull requests shipped on August 15 used
`ship-pr.ps1 -SkipLint -SkipTests`, deliberately, because the identical commit had passed both gates
minutes earlier. That is correct exactly while the commit is unchanged and dangerous the moment it is
not, and nothing checked which. The flag was doing the design's job without the design's safety, so the
repair makes the unchanged case provably not need it rather than making the flag more comfortable.

**The evidence is the content, not the clock and not a promise.** A passing gate is recorded against a
fingerprint of what it actually judged -- `HEAD`, plus the content hash of every dirty and untracked
file. `HEAD` plus `git status --porcelain` would have been the obvious shortcut and is wrong: porcelain
reports *that* a file is modified and never what it was modified *to*, so a file edited, gated and
edited again presents a byte-identical status line over different content. Each gate records
separately, `-SkipLint`/`-SkipTests` record nothing (a skipped gate proves nothing about the tree), and
every failure path -- no record, malformed record, no git, a clock that moved backwards -- refuses,
because a false refusal costs one gate run while a false skip costs an ungated merge. A four-hour age
bound covers the environment drifting underneath a tree that has not moved.

The record lives in the git directory: guaranteed present, local, per-worktree and never committable,
which is four properties a tracked file plus a `.gitignore` entry would each have to be given in every
consumer. **CI is untouched** -- a fresh checkout has no record, so `lint-en-tests` always runs the gate
for real, and a suite pins that it never learns to consult one.

New shared lib `scripts/lib/gate-lib.ps1`, mirrored to `workflow-davekjohn`; `gate-lib.tests.ps1` adds
46 asserts, including the edit-gate-edit sequence that a porcelain-only fingerprint would wave through.

### Significance

#### Tier 0

Removes a redundant four-minute gate run from roughly a quarter of all merges, and retires a habit --
shipping with both gates disabled by hand -- that was safe only by the practitioner remembering why.
The release procedure, where it lands most reliably, gets ten to fourteen minutes back per cut.

**Score:** 4

#### Tier 2

Consumers receive the same change through `open-pr.ps1` and the new lib in the `workflow-davekjohn`
mirror: their merge path stops re-proving commits nothing has touched, with no flag to remember and no
configuration to answer.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #728](https://github.com/DaveKJohn/claude-code-specialists/pull/728) · merged 2026-08-16

---

## `docs/a-findings-size-is-measured-too` changelog

### Branch title

A report's size is measured before its repair is scoped

### Branch ID

20260816-001143

### Branch type

docs

### What does the change on this branch bring to main?

**Chris's intake gains a fourth thing to check, and it is the one this repo just failed three times.**
His body already holds three: a report's symptom, its reason, and the repair it proposes each get held
against the tree, and each fails independently. The fourth is the finding's **size** — and unlike the
other three it is not about correctness at all. A report is usually right about *what* is wrong and
still wrong about *how much*, because the count it carries is whatever the reporter's search matched,
which is a proxy for the subject rather than the subject.

Scope to the proxy and one of two things follows: the repair leaves most of the problem standing while
looking finished, or it runs a mechanical fix across a subject far larger than anyone meant. So the
subject gets measured in its own terms before the work is scoped, the two numbers are compared, and a
large disagreement is filed as a finding rather than quietly absorbed — the decision to widen a job
belongs to whoever owns it. Where the recount changes the conclusion, the report is corrected out loud:
a corrected finding is worth more than a satisfied one.

**The evidence is this repo's own, which is why it is worth having.** A team-wide review on August 15,
2026 filed 22 issues; **three were mis-measured**, all three found only because the repair began with a
recount, and all three the reviewing team's own work rather than a consumer's:

- `#697` counted **32** uses of a retired name; the subject was **342** occurrences of the word. The
  remaining 310 went back as `#720` with the measurement, rather than being swept along unasked.
- `#700` claimed one identical sentence in **20** agent defs; exactly **3** are identical. The proposed
  shared block would have fed 17 role-specific tails to the next generator run for deletion.
- `#701` reported a claim falsified by **5** dated references; the claim names four categories and
  dates are not among them, so the real count is **2**. Repairing to the report would have stripped two
  correct measurements out of a manual.

**Three in twenty-two, with the reporter and the repairer an hour apart on the same team.** That is the
argument for recounting a report even when it is your own — and especially then, because a report you
wrote yourself carries no friction to slow you down.

The rule goes to Chris's portable body, stated timelessly; the three instances go to his repo lens,
where the issue numbers and the date belong.

### Significance

#### Tier 0

Intake is where the whole chain starts, so a check added there is paid back on every report. This one
would have caught three defects tonight before any work was scoped on them.

**Score:** 3

#### Tier 2

Chris's persona ships, so every repo running the specialists gets the fourth check. It is the most
portable kind of lesson there is — it is about reading a report, and every repo reads reports.

**Score:** 3

### Pull Request

Plugins: team-alpha

[PR #727](https://github.com/DaveKJohn/claude-code-specialists/pull/727) · merged 2026-08-16

---

## `feat/quieter-signals-and-a-derived-pin` changelog

### Branch title

The connector check reports per consumer, three exact pins become floors, and a cut names its own refresh

### Branch ID

20260815-231737

### Branch type

feat

### What does the change on this branch bring to main?

Three signals from the review of August 15, 2026 that were each costing something small on every run.

**The connector session check reported per plugin, so one consumer behind on four plugins printed the
same sentence four times.** Measured at a session start that day: six `[ERROR]` lines, 1,511
characters — **81% of everything the five session hooks printed together**, and paid again on every
compaction, because this hook's matcher includes `compact`. The lines now fold per consumer: on the
real signal set, four lines of 733 characters became one of 311, a **58%** cut.

**What is deliberately not lost is attribution.** Inbound #203 was filed precisely because two
consumers on the same outdated version produced two identical, unattributable lines, and the repair
then was to name the connector on every line. This groups rather than summarises — every plugin name
still appears, moved beside its consumer — so "which plugins, in which repo" is still answerable. The
fold is conservative by construction: marker, consumer **and** message must match, so two different
problems can never read as one, and anything that does not parse as the per-plugin shape passes
through untouched, which is what keeps the drift check's own lines whole. Seven asserts pin exactly
that, including one that a differing message is never folded in.

**Three exact counts in `script-contract.tests.ps1` became floors.** The record-count literal had been
hand-edited **21 times** — 6, 7, 8, 12, 14, 19, 22, 25, 27, 29 — because it tracks a registry that
grows with ordinary feature work. A test that must be "fixed" on nearly every change teaches people to
write the assertion to match the code, which is the opposite of what an assertion is for.

**The issue asked for the number to be *derived*, and that was measured and declined**: the count is
already parsed from the registry, so deriving it further would compare the source against itself and
stop catching the one thing the pin genuinely buys — a record silently disappearing. A floor keeps
that (a removal still drops below it) and costs nothing when one is added. The gap is stated rather
than hidden: adding and removing in the same change can net out above the floor. That is narrow, and
it is the price of removing 21 edits.

**A cut now tells a repo that runs what it releases that its own install is behind.** The loop had a
missing return edge: a release commits straight to the trunk, so no PR and no CI follow, the plugin
cache keeps its old version, and the only thing that notices is a later session's connector check —
as an `[ERROR]` that reads like a fault rather than the ordinary consequence of having just cut. On
August 15 this repo sat on v4.9.0 against a v4.11.0 source with six rows red, and a hook that release
had *added* could not fire, because the cache predated it. The reminder prints the two commands, and
prints **only** when this repo enables a plugin from the marketplace it declares — a repo releasing a
product it does not itself run gets nothing. It reminds rather than acts: a plugin update rewrites
what every future session loads, which is not something a release script should do while your
attention is on the tag.

### Significance

#### Tier 0

The hook cost is paid at every session start and every compaction, by everyone. The pins were a tax on
almost every contract change. The cut reminder closes a loop that left this repo silently behind
itself twice in one day.

**Score:** 3

#### Tier 2

Two of the three ship. A consumer's session start gets materially shorter when they are behind on
several plugins at once — which is the normal case after a release, since the bump is in lockstep —
and their `cut-release` gains the same reminder under the same condition. Scored 3: it is the first of
these three that a consumer notices without being told.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #724](https://github.com/DaveKJohn/claude-code-specialists/pull/724) · merged 2026-08-15

---

## `fix/shared-block-coverage` changelog

### Branch title

The conversation-history rule reaches every agent def from its one source

### Branch ID

20260815-215238

### Branch type

fix

### What does the change on this branch bring to main?

**The `no-conversation-history` rule had one source and eleven hand-typed copies.** Measured before
the repair: `team-alpha` carried the sentinel in **15 of 15** agent defs, while `team-ecomm` (0/3),
`team-lifehub` (0/5) and `team-shopify` (0/3) carried the same rule typed by hand — already in **three
different wordings**, which is what makes this a fix rather than a tidy-up:

- *"You are **not given** the conversation history; work **only with** …"* (three `team-lifehub` defs)
- *"You **do not receive** … work **only with** …"* (one)
- *"You **do not receive** … work **with** …"* (all six `team-ecomm` and `team-shopify` defs)

Coverage is now **26 of 26**, and no hand-typed variant remains. This needed no new machinery: the
generator already walked those directories — the same eleven files carry other shared blocks — so the
mechanism had simply never been pointed at this rule in three of the four plugins.

**Why the repair was more than wrapping a sentinel.** In eight of the eleven, the rule shared a bullet
with a role-specific sentence about the final message. Wrapping the merged bullet would have pulled
that role text inside a generated region, where the next generator run would delete it. Each was split
instead: the shared block on its own, the role-specific sentence kept as its own bullet, unchanged in
substance. One further detail was preserved rather than lost — `03-08`'s rule named *which period,
which account* as the context most often missing, which is real knowledge about that specialist's work
and now sits beside the block instead of inside it.

**The proof that the eleven are byte-identical to the source is the generator's own report**:
`build-agent-defs.ps1` ran after the edits and reported **0 files updated**. Had any of the eleven
differed from `agent-shared/no-conversation-history.md` by a character, it would have rewritten it.

**Reach.** `team-shopify` and `team-ecomm` are both enabled in `BWJ-ecommerce/smartwatchbanden`, so
nine of the eleven were live in a consumer.

### Significance

#### Tier 0

The next sharpening of this rule now reaches every specialist instead of 15 of 26. Before, the three
other plugins would have silently kept whichever paraphrase they were written with, and nothing
compares those against anything.

**Score:** 3

#### Tier 2

A consumer running `team-shopify` or `team-ecomm` was getting a behavioural rule that had drifted from
the one the core team runs on — subtly, in the direction of "work **with** what is in your assignment"
rather than "**only with**". Scored 3: nothing was broken, but a boundary rule that says something
slightly different in one plugin than another is the kind of drift that is invisible until it matters.

**Score:** 3

### Pull Request

Plugins: team-ecomm, team-lifehub, team-shopify

[PR #721](https://github.com/DaveKJohn/claude-code-specialists/pull/721) · merged 2026-08-15

---

## `docs/source-repo-naming` changelog

### Branch title

The source repo is called the source repo, and .gitignore speaks English

### Branch ID

20260815-213525

### Branch type

docs

### What does the change on this branch bring to main?

**The retired *workshop* framing was still being used as a live name for this repo, in 32 places
across 20 files** — most of them shipped skill pages, which reach every consumer by plugin update.
The framing was retired on August 3, 2026 in favour of one product per repository, and every other
mention of it is deliberately past-tense. These were not: `new-branch/SKILL.md` called it "the
workshop repo" on line 13 and "the source repo" on line 25, twelve lines apart. A first-time consumer
reads that as two repositories, one of which they cannot find.

All 32 now read "the source repo", the term those same documents already used correctly. One sentence
was reworded rather than substituted: *"The source of this script lives in the source repo"* says
source twice for no gain, so it is now *"This script is maintained in the source repo."* The three
references to the literal old repo name `davekjohns-workshop` were checked and deliberately left
alone — they are the historical record of the rename and are correct as past tense.

**`.gitignore` was half Dutch.** Its four section comments were, while the long explanatory blocks
below them — the PowerShell cache, the release-notes page and its token — had been English all along.
`.claude/rules/language-layers.md` calls its own list of layers "meant to be exhaustive" and says an
undercount is a gap to close on discovery rather than a quiet exception, with `ci.yml` as the
precedent. This is the second time that clause has had to be honoured, so the file now says so, and
`.gitignore` joins its `paths:` list — otherwise the next reader has to re-derive that it was ever in
scope.

**What that same note now also records, because it is the more useful half:** this rule is exhaustive
over the *tree*, and the tree is not the whole product. Two layers of this repo speak Dutch where no
path-scoped rule can ever reach them — the public GitHub repo description and the `inbound` label
description, both in repo settings. Those are filed separately and wait on Dave, being outward-facing
configuration.

### Significance

#### Tier 0

Removes a naming collision that this repo's own documents created and then had to explain around.
Nothing behaves differently; the payoff is that the term now means one thing.

**Score:** 2

#### Tier 2

This is the one that travels. Skill pages are the most consumer-visible layer the plugin ships, and
half of them named a repository that has not existed since August 3. A consumer following those
instructions had to work out for themselves that "the workshop repo" and "the source repo" were the
same place. Scored 3 rather than higher because it misled rather than blocked: everything still worked
once the reader made the leap.

**Score:** 3

### Pull Request

Plugins: team-alpha, workflow-davekjohn

[PR #719](https://github.com/DaveKJohn/claude-code-specialists/pull/719) · merged 2026-08-15

---

## `docs/false-claims-sweep` changelog

### Branch title

Four documents corrected where they described something the tree does not do

### Branch ID

20260815-210707

### Branch type

docs

### What does the change on this branch bring to main?

Four documents each stated something a reader could check and find untrue. All four came out of the
team-wide review of August 15, 2026, and each was verified against the tree before it was touched.

**`SECURITY.md` told a researcher there is no hosted service.** Since `ddf5574` there is one: a
Cloudflare Worker serving the audience release notes at `/notes/<token>`, with no login and that
unguessable path as its only lock. The sentence sat under **Out of scope**, so the one document whose
whole job is to draw that line was excluding a real surface. The page is now named in scope with its
token as the stated boundary, and the out-of-scope half says what remains true and why — an outage
costs a reader nothing they cannot get from this repo, so availability reports stay out while
anything touching the token does not.

**Rendall's lens cited check 19 for a mechanism the lint implements as check 20** — and the comment
above that check exists precisely to prevent this: *"two checks answering to one number is how a
finding gets discussed as the wrong one."* Check 19 is a different check (a named consumer-facing
document that is not there). One word, and it was the document that most needed to be right about it.

**Ravi's lens listed a finished job as open.** Extending the shared-block mechanism to the persona
templates shipped on August 8, 2026 — the generator walks `personas/` alongside `agents/`. Worse, the
generator's own comment cites that list as the place the widening was foreseen, so a reader following
the citation landed on the plan rather than on the answer. The item is now recorded as closed rather
than deleted, so that citation still resolves to something.

**Bianca was described as invocable and is not.** She ships as a persona with no agent def, so
`@team-alpha:<name>` does not reach her, and Chris's routing table and every chain mention her zero
times. The handbook grouped her with five specialists that genuinely are subagents. The list is now
split by how each is actually reached, and the persona-lens note states plainly that she has a lens
and no caller. Deliberately not repaired by inventing a routing row: this repo does no intake
interviews, and a trigger invented to make a sentence true would be a way-of-working change nobody
asked for.

### Significance

#### Tier 0

Four corrections in documents this repo reads while working. The lens fixes matter most here: a
specialist who opens their own lens to find out what is on their plate is the reader being misled,
and both wrong lines were about their own craft.

**Score:** 3

#### Tier 2

`SECURITY.md` is the one that reaches outward. It is what an external researcher reads before
deciding whether to report something, and it was telling them a live surface was out of scope. Nobody
is known to have been turned away by it, which is exactly why it is a 3 rather than higher — the cost
is a report not filed, and an unfiled report is invisible by construction.

**Score:** 3

### Pull Request

[PR #718](https://github.com/DaveKJohn/claude-code-specialists/pull/718) · merged 2026-08-15

---

## `feat/release-notes-page` changelog

### Branch title

Host the audience release notes as a generated page on a Cloudflare Worker

### Branch ID

20260815-190736

### Branch type

feat

### What does the change on this branch bring to main?

**The hand-written release note is the one document written for somebody outside the development work,
and it lives as markdown in a repository.** That is the right home for it and the wrong place to read
it: the reader has to find a directory, pick a version out of a filename, and read raw markdown in a
code host. `build-release-notes-page.ps1` builds those documents into one page -- a picker per release,
prev/next, keyboard arrows, a deep link per version, light and dark -- and with `-Worker` into a
Cloudflare Worker that serves it at `/notes/<32 hex>`.

**Ported from smartwatchbanden, where two pages exist and only one is on Cloudflare.** That repo keeps
a generated archive of every document *and* a hand-edited management edition; the edited one earns its
keep there because its notes are per-PR records that need summarising. Here the note is already written
for that reader, so this page is **generated and never edited** -- summarising it a second time would
be a second thing to keep true.

**Two of that consumer's design decisions were re-measured before being copied, and both were dropped.**
Their script hand-writes a JSON serializer because `ConvertTo-Json` "does not return within five
minutes"; on this repo's 21 notes (187,039 characters) it returns in **47 ms** on exactly the nested
shape this builds. And it hand-escapes the angle brackets, which PowerShell 5.1 already does. So a
hundred lines of serializer are left out -- and the escaping is **asserted** rather than trusted,
because that failure is silent: an unescaped closing script tag ends the page's data block early and
the page renders empty with nothing erroring.

**One of their decisions was copied verbatim, with the reason.** The live marker is matched with
`-cmatch`. PowerShell compares case-insensitively by default, so every release whose *title* contains
the word "live" marks itself; two of their forty did, and their page pointed at three live versions.
There is a test for it here.

**The path token is an input and is never invented.** A token generated on the fly does not mean "a new
path" -- it means every link already sent now 404s, while the build and the deploy both report success.
Missing is an error with a recovery instruction; `-InitToken` is the separate, explicit way to make the
first one, and it refuses to replace one.

**It publishes nothing.** `npx wrangler deploy` is a deliberate, separate step, because publishing is
outward-facing under the safety rules. The script names the command and adds the warning that cost that
consumer a silent failure: verify a redeploy against the **bytes the URL serves**, never against the
deploy command's own output -- once wrangler has deployed a worker, an API-side upload only creates
inactive versions, with no error, while the live page stays the old one.

**Portable, not local.** Both files travel to consumers via the shared-scripts registry, with the
[`release-notes-page`](plugins/workflows/workflow-davekjohn/skills/release-notes-page/SKILL.md) skill as
their page and two optional seams -- `Get-ReleasePageTitle` and `Get-ReleasePageWorkerName` -- both
`decide`, both with working fallbacks, so a repo that answers neither still gets a page and simply hosts
it nowhere. The template is the first registry entry whose source is not a script; it is registered
`LibOnly` because what that flag really declares is "this file never resolves a repo root of its own",
which a template satisfies more completely than a lib does.

**Whether the token belongs in git is the consumer's answer, not the plugin's, and it splits on one
fact.** Private repo: commit it, because a tracked token survives a lost machine. Public repo -- this
one: keep it out, and accept that nothing in git then remembers the URL.

**Three stale counts were repaired on the way**, all of the same class the repo already guards for
elsewhere: the plugin README listed nine skills under the heading "The nine skills" while the directory
held twelve, and `scripts/README.md` named twenty-three mirrored scripts and thirteen guarded entry
points against twenty-eight and sixteen. The skill table is now complete rather than partial -- a
partial list of an enumerable set is worse than none, because a reader who finds four of their skills
missing cannot tell which document is wrong.

**Verified by running it, not by reading it.** All 21 notes rendered under node with a DOM stub (0
problems) plus 14 targeted cases, which found two real bugs before they shipped: a code-span sentinel
that also matched ordinary numbers in prose, and a link regex looking for an HTML entity the escaper
never writes. The worker was exercised the same way -- loaded in node, asserting 200 on the token route
and with a trailing slash, 404 everywhere else, the noindex header, and the full page served. 48 asserts
in `release-notes-page.tests.ps1`, all against the generated page rather than the script's internals,
which is how that consumer found their live-marker bug in the first place.

### Significance

#### Tier 0

This repo gets a reading copy of its own release notes, and three stale counts in the always-read docs
are corrected. Nothing about how work moves through the repo changes.

**Score:** 3

#### Tier 2

A consumer gains a way to put the note they already write in front of the reader it is written for,
without building it themselves -- one command, two optional seams, and no configuration at all for the
page half. It asks nothing of anybody: a repo that ignores it is unaffected, and hosting is a separate,
explicit decision with its trade-off written down rather than defaulted.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #695](https://github.com/DaveKJohn/claude-code-specialists/pull/695) · merged 2026-08-15

---

## `docs/two-decisions-recorded` changelog

### Branch title

Deliberate restatement and the surviving role word are written down as decisions

### Branch ID

20260815-235703

### Branch type

docs

### What does the change on this branch bring to main?

Two findings from the review of August 15, 2026 that turned out to be **decisions rather than defects**.
Neither file changes behaviour; both stop the same finding being re-filed every time somebody sweeps.

**"Workshop" survives as a role word, and the README now says so.** The retirement of August 3 killed
the *framing* — this repo as the workshop for every future product — and the review found the *name*
still alive in 32 places, which shipped as a correction. What it also found, and undercounted at first,
is **310 further uses of "workshop" as a role word**: `workshop root`, `workshop-side`, "covered from
the workshop by check-connectors". Those are not the retired framing. They describe what this side of
the marketplace does, which is still exactly what it does. Sweeping them is a prose-sensitive rewrite
across 61 files of shipped plugin content, and it buys consistency at the price of worse sentences. So
the distinction is recorded where a reader already goes to understand the retirement, with the three
`davekjohns-workshop` references named as the historical record they are.

**Restating a rule for a different reader is legitimate — but only when it is marked.** The review
reported the "chore is a contradiction" rule as duplication across three documents plus a code comment,
and it was right that nothing said otherwise. It is deliberate: four readers arrive at four different
doors, and the rule is the kind people work around when it is not in front of them — a `chore/` branch
looks reasonable until you know why it cannot exist. The general form is now a rule in Tessa's manual,
with its honest limit attached (restate the *rule*, keep any *measurement* in one place), and the two
measured instances are named in her lens.

**One of the two is recorded as the weaker case rather than defended.** The "81 of 89" figure sits in
two shipped portable documents, and it is a *number*, not a rule — so a re-measurement has to be applied
twice, which is the exact failure the new rule says to avoid. It stays because both documents serve a
reader who needs the figure at a different moment, and the lens now says what to do if that stops being
practical: keep it in one and point at it from the other.

### Significance

#### Tier 0

A sweep that keeps finding the same three things and re-deriving the same answer costs a pickup every
time. Both are now written where the next reader looks, including the one that is a compromise.

**Score:** 2

#### Tier 2

Tessa's manual ships, so the restatement rule travels to every repo that works this way — and it is a
rule about documentation debt that most repos have and few name.

**Score:** 2

### Pull Request

Plugins: team-alpha

[PR #726](https://github.com/DaveKJohn/claude-code-specialists/pull/726) · merged 2026-08-16

---

## `feat/cut-release-driven-by-a-suite` changelog

### Branch title

The release script is driven end to end against a throwaway repo

### Branch ID

20260815-234006

### Branch type

feat

### What does the change on this branch bring to main?

**`cut-release.ps1` is now driven end to end by a suite, against a throwaway repo.** It is the
highest-blast-radius script here: it bumps every `plugin.json` in lockstep, empties `CHANGELOG.md` down
to its intro, writes the notes, rewrites the history table, commits **directly on the trunk** and tags.
Because it runs under the narrow exception to "never directly on `main`", no PR and no CI stand between
a defect and the tag — CI first sees that commit when it is already pushed and tagged. Its only
dedicated coverage was an allowlist drift guard plus asserts on its own source text.

`scripts/tests/cut-release-drive.tests.ps1` runs the real script in a child process with
`CLAUDE_PROJECT_DIR` pointed at a fresh `git init` fixture that has **no remote**, and every run passes
`-NoPush`. Seventeen asserts across three cases:

- **the happy path** — both fixture plugins land on the same patch version (lockstep is the property a
  consumer depends on, so it is asserted rather than assumed), the intro survives while the pending
  entry is gone, the development note appears at the grouped path *carrying the entry the changelog
  lost*, the history table gains its row, the tag exists and points at the commit the cut just made,
  and the tree is clean afterwards — which is how "everything written was committed" gets proven rather
  than hoped;
- **a bump the entries have not earned** — a tier-0-only changelog asked for a minor: refused, nothing
  written, no tag, so the gate demonstrably runs before the first write;
- **a new major with no section yet** — refused, tree untouched. That is the case `CLAUDE.md` documents
  as needing two hand edits on the trunk before a cut will run, and it now cannot quietly become a
  silent success.

**The fixture found its own bug first, which is the argument for this suite in miniature.** Its first
draft wrote the history table with a `| Release |` header and no `### The release list` heading. The cut
did not fail — it wrote no row and refused no major, silently. Exactly the shape a script that runs
unattended on the trunk produces when its input is a little off, and exactly what nothing here could see
before. The fixture now copies the real page's shape, and the reason is written beside it.

**The asymmetry that made this issue sharp is also gone.** `ship-pr.ps1` names its own test gap twice in
its docstring; `cut-release.ps1` named it zero times, so the absence read as coverage. It now carries a
`.NOTES` block stating both halves: what the driven suite proves, and what stays uncovered on purpose —
the push (a suite must not be able to reach a remote) and the hand-written documents, which are prose a
person writes.

Every git call in the new suite goes through the repo's own `Invoke-NativeCapture`. That is not
decoration: under `EAP=Stop`, `git add` writing its ordinary CRLF warning is promoted to a terminating
error, which is the pitfall that broke cutting `v1.12.0` (#107). It cost this suite one red run to
re-learn, and the reason is now recorded at the top of the file.

### Significance

#### Tier 0

The one script that can put a wrong version, a truncated changelog or a misplaced tag on the trunk with
nothing downstream to catch it now has a suite that drives it. Three refusal and success paths are
pinned, including the two that must leave the tree untouched.

**Score:** 4

#### Tier 2

`cut-release.ps1` ships, so a consumer cutting their own release gains the same proven behaviour and the
same honest coverage statement in its docstring. Scored 2: nothing they do changes, but the script they
run is now held to what it claims.

**Score:** 2

### Pull Request

Plugins: workflow-davekjohn

[PR #725](https://github.com/DaveKJohn/claude-code-specialists/pull/725) · merged 2026-08-15

---

## `docs/doctrine-layer-and-evidence` changelog

### Branch title

The layer table measures itself again, and the always-on path sheds its evidence

### Branch ID

20260815-230038

### Branch type

docs

### What does the change on this branch bring to main?

Three findings from the team-wide review of August 15, 2026, all about the documents that describe how
this repo documents itself.

**The layer table that carries the source-vs-lens doctrine was measuring nothing.** It read *"14
manuals, 4 personas and 9 skills"* and *"103 references across the 9 skills"*; the tree holds **15, 4
and 4** — a manual was added, and the August 8 workflow split moved nine of `team-alpha`'s skills into
`workflow-davekjohn`. `CLAUDE.md` points at this table as the evidence for the whole doctrine, so a
reader who checked found three wrong numbers and no way to tell whether the doctrine was wrong with
them. Re-measured: **250** references across the 4 skills (137 issue numbers, 93 repo names, 15
versions, 5 person names), and the table now states the **date and the method**, so the next reader
re-runs it in one command instead of trusting it.

**And the table's own claim was false — but by less than was reported, which changed the repair.** The
claim is specific: *"zero issue numbers, versions, repo names or person names"*. Dates are not in that
list, so Nolan's two dated measurements — reported as violations — are not violations at all; his
manual carries no forbidden category. What did violate it was **two person names**, both "Dave", in
Tessa's manual and Rendall's persona. Repaired by making the claim true rather than softening it: the
substance stays portable, the attribution moves to the lens. Rendall's needed no new home — `CLAUDE.md`
already records that decision and points back at his body. Tessa's had none, so her lens now carries
it, which is her own *"nothing silently drops"* rule applied to her own manual. The one `vX.Y.Z` a
regex still finds is Rendall's *"How he sounds"* line, an invented example of speech; the table says so
rather than pretending the count is zero.

**`CLAUDE.md` shed 9,440 B of evidence it was making every session pay for.** The lint-gate bullet
carried 102 lines of measurement history — the entry-format count and its four candidate rules, the
stale-path check declined at 124 findings all false, the PR template measured over 60 PRs, the two
repairs it took to reach `CHANGELOG.md`'s intro. None of it is a rule a reader needs before starting
work; all of it is *why* the rule is what it is. It moved **verbatim** to Sylvester's lens, beside his
existing description of those same checks, leaving the operative statement and a pointer. `CLAUDE.md`
goes from **36,967 B to 28,298 B — 23% smaller**, and this is the same split performed for the release
craft the day before, applied to the block that was sitting directly above it.

**A writing convention, because the review found a crack no gate can cover.** This repo argues from
measurement, and holds two kinds of number that read identically: ones a reader can recompute from the
tree, and snapshots of something outside it — which version a consumer runs, what an organisation has
installed. Only the first kind can be gated. The second already cost a published falsehood: `v4.11.0`'s
note told readers colleagues were *two* releases behind when they were one, *"false at the moment it
was typed"*, and the copy on the GitHub Release still carries it. The rule now sits in Tessa's manual —
a re-derivable figure states its method, an outside claim states that it was true when written and is
not verified since — with the instance and two named at-risk figures in her lens.

### Significance

#### Tier 0

Every session pays for `CLAUDE.md` before doing anything, and it is now 23% lighter with no operative
rule lost. The layer table is the evidence a reader checks before accepting where a rule belongs; it
now reproduces.

**Score:** 4

#### Tier 2

The manual and persona edits ship. A consumer reading Tessa's manual gets a new writing rule that
travels, and two portable documents stop carrying an attribution that belonged in a lens. Scored 2
because nothing a consumer does changes — it is the documents around them that got more honest.

**Score:** 2

### Pull Request

Plugins: team-alpha

[PR #723](https://github.com/DaveKJohn/claude-code-specialists/pull/723) · merged 2026-08-15

---

## `docs/v4-11-0-note-correction` changelog

### Branch title

the v4.11.0 note's false publication line, and the rule that lets it be corrected

### Branch ID

20260815-162419

### Branch type

docs

### What does the change on this branch bring to main?

`v4.11.0`'s published note told its readers that colleagues installing internally were **two** releases
behind. They were one. Read at the target rather than inferred -- `BWJ-ecommerce/claude-plugins-bwj`,
commit `07a1eb9`, 2026-08-15T10:56:22Z -- the organisation is on the four team plugins at 4.10.0. The
clause is corrected, and the page carries a `## Correction to this page` section naming the date, the
original wording, and the fact that the copy attached to the GitHub Release still contains the error and
is deliberately not replaced. `CHANGELOG.md`'s pending intro carried the same wrong characterisation and
is fixed outright, being nothing's published record yet.

**The clause was false at the moment it was typed, and that is what makes this more than a typo.** It was
carried forward from `v4.10.0`'s note, where *"has not been published"* was true at the merge and was
overtaken an hour later when the publication ran. The count was updated; the target was never re-read.
**A stale line copied forward becomes a false line** -- and every release that reuses the previous note's
*what was still open* block runs that risk, which is now the standing habit.

So the rule that governs both goes in writing, because the published-record convention will otherwise be
quoted as a reason to freeze an error. It protects a line that was **true when it was published**; a
snapshot going stale afterwards is the record working. It has never covered a line that was **false when
it was written** -- correcting one restores the record, freezing it preserves a mistake. The portable
statement, with how to mark a correction and why the attached asset stays frozen, lands in
`RELEASES-portable.md`, so it travels to every repo that cuts releases this way. This repo's
`workflow-davekjohn/CLAUDE.md` points at it and keeps the part only this repo can supply: the two adjacent
notes that demonstrate one case each. `4.10.0.md` is **left untouched on purpose** -- it is the stale
twin, and the contrast is the teaching case.

No check was built for it. "A prose claim about an external repo's state must be verified" is not
something a regex holds, and this repo has already priced that shape twice. What is buildable is the
habit: verify the target, not the previous note.

### Significance

#### Tier 0

A defect in a published document is corrected, and a convention that would have been quoted wrongly the
first time anyone met it is settled in one pass -- with two adjacent documents demonstrating opposite
treatments, which is the cheapest worked example this repo will get. It also names the mechanism that
produced the error, so the next release's carried-forward items get verified instead of recounted.

**Score:** 3

#### Tier 2

A page a reader may already have opened no longer states something untrue, and the correction says
plainly that the downloadable attachment still does. The portable half gains the rule itself, so a repo
running releases this way learns when a published note may be corrected and when it must be left alone --
useful the first time they face the question, invisible until then.

**Score:** 2

### Pull Request

Plugins: workflow-davekjohn

[PR #694](https://github.com/DaveKJohn/claude-code-specialists/pull/694) · merged 2026-08-15

---

## `docs/v4-11-0-timing-total` changelog

### Branch title

The v4.11.0 release note gains its end-to-end total

### Branch ID

20260815-155745

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.11.0`'s note was frozen at a **5m 25s** head; the five remaining legs -- writing the
document (2m 55s), its own gates (4m 02s), CI (7m 40s), the merge with the fold (4m 18s) and the publish
(28s) -- are added, giving a **total of 25m 07s** from clock start to a published Release with its
attachments.

**The tail is 19m 42s, and this is the FIFTH consecutive release to land inside a seventy-second band**
-- 19m 26s, 18m 47s, 19m 55s, 19m 50s, 19m 42s -- while the head over the same span moved from 15m 31s
to about five minutes and stayed there. Four measurements made the tail look stable; the fifth is what
makes it a **property of the procedure** rather than a run of coincidences, and the document says so in
those terms. It gives both series rather than the tail's percentage, for the reason the previous note
already established: the tail is fixed legs and barely moves, so a rising *share* is the head having
been fixed, not the tail getting worse.

**The blocked-a-person figure fell from 4m 05s to about 3m 35s, and that is not reported as an
improvement.** The head's two intake moments were the same 40 seconds; what changed is that writing the
document took 2m 55s against 3m 24s -- one document rather than two registers, on a release whose
consumer selection was clearer. It is inside the noise of a single measurement and is given as the leg it
came from rather than as a trend, because two points are not a series.

**The duplicated merge leg is measured a fifth time and is unchanged**: `ship-pr` re-runs the suites the
pull request already proved, inside a 4m 18s merge leg here, against roughly 3m 27s, 3m 18s, three
minutes and 4m 02s at the four releases before. Five consistent measurements make it the largest single
saving left in the procedure and the best-evidenced one; it stays named in *what was still open* rather
than being acted on here, which is the fifth release running that this sentence has been true.

**The attached copy stays frozen**, and the note now says so in place of the bullet that promised this
edit -- the rule `v4.7.0` set: an attachment is what was published at the moment of publication, and
silently replacing it is the opposite of the record the document is for. The bullet it replaces would
otherwise have become false the moment this merged, which is the failure mode of writing a promise into
a published record instead of a condition.

### Significance

#### Tier 0

The release procedure's own cost, complete for the fifth release running, in the unit the question was
asked in. What it buys here specifically is the fifth point on the tail series -- the one that turns a
stable-looking figure into a measured property, and therefore turns "the merge re-runs the suites" from
a recurring observation into the best-evidenced saving this procedure has.

**Score:** 3

#### Tier 2

A consumer reading this release's note gets the whole cost rather than the fifth of it that was visible
when the document was frozen, and is told plainly that the attached copy is the frozen one. Nothing they
do changes.

**Score:** 2

### Pull Request

[PR #693](https://github.com/DaveKJohn/claude-code-specialists/pull/693) · merged 2026-08-15

---

## `fix/bypassed-helpers-and-stale-register` changelog

### Branch title

Two shared helpers stop being bypassed, and the consumer register catches up

### Branch ID

20260815-220937

### Branch type

fix

### What does the change on this branch bring to main?

**Checks 15 and 16 were reading fences with their own pattern instead of the one function written to
own that.** `Test-FenceDelimiterLine` exists so fence syntax lives in one place — its own docstring
says so, and describes the syntax as *"three-plus backticks, optionally indented"*, which its pattern
honours by allowing leading whitespace before the backticks. Checks 4 and 10 call it. Checks 15 and 16
matched the backticks anchored at column 0 instead, with no allowance for indentation, so an indented
fence was invisible to both.

**Not hypothetical, and not yet firing.** The documents those two checks scan already contain indented
fences: `INSTALL.md:554`, `UNINSTALL.md:267` and `:468`. None of those blocks happens to hold a
measured figure today, so nothing misfires — but the day one does, check 16's in-fence flag never
toggles for it and a figure inside a code sample gets judged as prose, which check 16's own comment
says is check 15's territory and would be a double report. Both now call the shared function, and
check 15's language-tag extraction strips leading whitespace too, since it was reading the same line.

**`connectors/djcylow-react.json` made three statements about that consumer and all three were
false.** It named plugin id `specialists@claude-code-specialists`, retired in the August 3 reorg; it
said only that one plugin was enabled; and it said the consumer's `.claude/settings.json` carried no
`extraKnownMarketplaces` block. Read live from the GitHub API on the day of this change, that file
enables **team-alpha and workflow-davekjohn** and does carry the block.

**Why it had rotted unseen is the part worth keeping.** That checkout is not on this machine, so
`check-connectors.ps1` reports `[SKIP]` for it and nothing in routine tooling ever compares the record
against reality. `connectors/README.md` already names this as structural, and the register's own
doctrine — it records what a consumer *has*, so it changes when they do — is only true if somebody
looks. The note now says that out loud, so the next reader knows the record is unverified rather than
verified-and-quiet.

**Deliberately not done here: `#707`**, the second `Get-JsonField`. Victor found no live misbehaviour;
the risk is a future caller relying on a `-Default` the second copy does not have. That is a risk that
has not bitten, which this repo's standing rule says to name and leave — and every available repair
either dot-sources 1,274 lines of report machinery into a publishing script or changes the default
across eighteen call sites. The reasoning is on the issue rather than in a commit.

### Significance

#### Tier 0

The fence repair removes a bug that is real and dormant: today it produces nothing, tomorrow it
produces a false finding in a gate people trust. The register repair restores a record that three
separate statements had drifted away from.

**Score:** 3

#### Tier 2

Neither reaches a consumer directly — the lint gate is this repo's, and the register is this repo's
view of others. Scored 1 rather than N/A because the register being wrong is exactly what makes a
consumer's problem invisible from here, which is the one way this does eventually cost them.

**Score:** 1

### Pull Request

[PR #722](https://github.com/DaveKJohn/claude-code-specialists/pull/722) · merged 2026-08-15

---

