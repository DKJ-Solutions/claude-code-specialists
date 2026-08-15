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

