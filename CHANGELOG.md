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

## `docs/handover-spent-not-broken` deployment

### What does the change on this branch deploy to main?

One boundary added to the `/handover` skill, on the step that was being read one clause too far.

Step 3 tells a pickup to say a lock-vs-repo disagreement out loud, because that is how a requester learns
their lock was stale. It does not say what to do next, and the gap was filled with the obvious-looking
answer: *so it needs repairing*. Measured here on August 20, 2026 — a session asked whether anything
important was still open, swept the tree correctly, and then put "the lock is stale, three of its items
are done" at the **top** of the answer as the item that most needed action. Nothing was wrong. A `/lock`
is written once, read once, and waits to be overwritten; being out of date is its resting state.

So step 3 gains its own second half — **a spent lock is spent, not broken** — with the instruction that
naming the change *is* the whole of it: do not offer to clear it, do not propose re-locking it, and do
not carry it into a list of what is still open. The requester's own correction is kept as the sentence
that settles it. The *deliberately does not do* list gains the matching clause on the bullet that already
explains why the command never deletes the lock: it does not hand that job back to the requester either.

Nothing about the mechanism changes, and no script is touched. It is the reading of one step, in the one
place a reader of it actually looks.

**Score:** 2

#### What makes this change extra special

It is the fourth measured failure mode of the same document, and the first that runs the *other* way. The
three already written up are all under-trust of the repo: a briefing arriving truncated, one whose
reasoning had expired, one that transcribed a cause that did not exist. This one is over-trust of the
*lock's tidiness* — a session treating a working mechanism as a defect because nobody had written down
that its end state looks like neglect.

That direction matters more than it sounds for a command whose whole purpose is to hand a session its
bearings. A pickup that reports phantom work spends the requester's attention on the one thing that never
needed it, and does so in the first paragraph, where it displaces whatever was genuinely open.

**Score:** 3

### Pull Request · 20260820-114124

A spent lock is the resting state

Plugins: workflow-davekjohn

[PR #782](https://github.com/DaveKJohn/claude-code-specialists/pull/782)

---

## `feat/shopify-floor-adoption` deployment

### What does the change on this branch deploy to main?

The install path the `team-shopify` floor shipped without. v4.15.0 gave the plugin a `PreToolUse` guard on
the live theme, and it started working on its own — for two of its three rules. The third needs the
consumer to name the live theme, no install step owned that answer, and an install writes nothing into a
repo, so every refreshed consumer met a standing `[ERROR]` at session start and a guard with a documented
hole in it. Three inbound reports came back within nine hours of the cut, and this branch answers all
three.

**The new `adopt-shopify-floor` skill** places the floor: the Shopify seam block appended to
`scripts/repo-config.ps1`, a starter `.theme-check.yml`, and `.github/workflows/theme-check.yml`. Additive
and dry-run by default like its two `adopt-` siblings, refused in a repo that publishes plugins, and it
takes `-LiveThemeId` so the guard is armed in the same move. It travels in `team-shopify` rather than in
`specialists-init`, because the core team must not learn the seams of an add-on it does not depend on.

**The starter config is measured, not designed.** Both existing Shopify consumers wrote one independently
before the floor shipped, and both arrived at the same two checks over `extends: nothing` — Liquid that
does not parse, JSON that does not parse — with the same false-positive exemption for `.liquid` files
carrying no HTML. Neither turned the recommended set on: it reports 1504 offenses across 171 files on one
of those themes and roughly 58k on the other, and a gate that is red on arrival gets bypassed on day one.
So the floor ships green on arrival (Dave, August 20, 2026, choosing that over assuming a clean theme),
and the CI workflow runs at `--fail-level error`, which is not a loosening but exactly the two checks the
config declares.

**Inbound #776's proposed repair would have made things worse, and that is the finding underneath this
branch.** It asked for the seam block to be written with a `VUL-IN` marker. The session check reads a
non-empty answer as *answered*, so a stub returning `VUL-IN` would have silenced the report while leaving
the id half exactly as inert as before — a hole with a comment on it, the failure this plugin's own README
is built around. So the block lands **commented out** unless an id is supplied, and both the guard and the
session check now read a **non-numeric** answer as unanswered. The observation was right, the remedy was
not.

**Inbound #777** gets the two halves it was missing: a *Converging off a hand-written guard* section in the
README, and a second finding in the floor session check — a `PreToolUse` command in the consumer's own
settings naming this guard is, by construction, a second one, and two guards then block every command
twice. Its third item is closed as already answered rather than built: the README has stated which marker
spellings the guard accepts since `056a097`, the same commit that shipped the guard.

Twelve new asserts in `guard-live-theme.tests.ps1` (69, from 51) and a new 36-assert
`adopt-shopify-floor.tests.ps1`.

**Score:** 4

#### What makes this change extra special

A guard that reads as protection while one of its rules cannot fire is the worst state of the three
available, and it was the **default on install** for every Shopify consumer. This closes it in the only
place it could be closed — the install path — rather than asking each consumer to notice it alone.

The part worth keeping is the shape of the mistake it avoided. All three reports were correct about the
symptom; one was correct about the cause and wrong about the cure, in a way that reads as obviously right:
*scaffold the function with a placeholder, like every other seam*. Every other seam has a documented
fallback, and this one has none — a placeholder there does not prompt an answer, it cancels the question.
The counter-case is now asserted from both sides, on the guard and on the check, because an exemption
without one is a hole with a comment on it.

And the second-guard finding is what a system owes a consumer who did the right thing: `xoxowildhearts`
built the guard, reported it, offered it upstream, and was rewarded with two hooks doing one job — with no
version bump to prompt anyone to look, because the refresh happened inside `4.14.0`. The check now says so
once per session, and the README says what to delete and what to keep.

**Score:** 4

### Pull Request · 20260820-104329

The Shopify floor gains its install path

Plugins: team-shopify

[PR #781](https://github.com/DaveKJohn/claude-code-specialists/pull/781)

---

## `docs/v4-15-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.15.0 release
document froze at a subtotal of **5m 12s** because three of its legs were still running on the file it was
written into — its own CI gate, its merge, and the publish. Those legs now have timestamps, so the total goes
in: **24m 34s** end to end, with writing the page **9m 37s**, CI and the merge **8m 22s**, the fold **5s** and
the publish **1m 18s**.

Two readings are added that the first pass could not produce. The head came to **21%** of the release, the
lowest of the four that have been timed (`v4.12.0` 24%, `v4.13.0` 30%, `v4.14.0` 32%) — a fourth reading for
the claim that most of a release happens after the document describing it is frozen. And the two tail legs are
split by whether they blocked a person: writing the page and waiting for CI are **73%** of the release between
them, but only the writing is a person's time, which is what makes the fixed-cost-per-event argument concrete
rather than rhetorical.

**Score:** 2

#### What makes this change extra special

A consumer running this workflow writes the same two passes, so the worked example is the instruction: the
paragraph they see is what a frozen subtotal looks like, and this edit is what closes it. The release note is
the one document that reaches every consumer as an attachment, and it now carries its own cost in the unit the
question is asked in — minutes — rather than in a proxy.

**Score:** 2

### Pull Request · 20260820-093743

The v4.15.0 release note gains its end-to-end total

[PR #780](https://github.com/DaveKJohn/claude-code-specialists/pull/780)

---

## `docs/v4-15-0-release-note` deployment

### What does the change on this branch deploy to main?

The hand-written release document for v4.15.0. The cut drafts it from the tier-2 entries in the words their
authors wrote for a diff reviewer, and commits it inside the tagged release commit; this is the rewrite for
somebody deciding whether to update, held against the seven tests in the `cut-release` skill.

Twelve of the release's thirteen entries reach tier 2, so the page is long by subject rather than by
indulgence. It is ordered by urgency rather than by branch: the three items carrying an action open the page
— seeding `Get-ShopifyLiveThemeId` for the live-theme guard, the three `team-shopify` subagents that named
one consumer's store, and deleting the retired `Get-ChangelogHeading` from an already-scaffolded
`repo-config.ps1` — and every remaining item says **no action needed** rather than leaving it to be inferred.

Both organisation sections are written: *what it is worth* leads on the guard, on why a permission deny list
structurally cannot do that job, and on the four separate changes that were all one defect — a shipped
document naming something that does not exist. *What was still open* is a snapshot rather than a claim about
the present, and it records the two guard reports that arrived before the cut and are not answered by it.

The timing is the first of the two passes step 0a asks for: **5m 12s** from clock start to the tag being
pushed, with the legs measured from timestamps. The total lands in its own small edit once the publish has
happened, because this document cannot time its own publication.

**Score:** 2

#### What makes this change extra special

It is the one document a consumer reads to decide whether to update, and it reaches every one of them as an
attachment on this release's GitHub Release.

Three items on the page carry an action and each says exactly what it is; the rest say plainly that there is
none. The first of the three is the one that earns the ordering: a consumer running `team-shopify` receives a
guard that reads as protection while its live-push rule is inert until they answer one seam — so the page
opens with the visible symptom (a standing `[ERROR]` at session start), states which rules do still hold so
it cannot read as "unprotected", and tells the two consumers who wrote their own guard that they are now
running two.

The page also carries the correction to a figure v4.14.0's own note left unexplained: the test gate read
**151s** here and **888s** earlier the same morning on the same commits, and the cause is that the earlier
reading was taken while the machine ran a full branch review. A count taken under load measures the load.

**Score:** 4

### Pull Request · 20260820-092020

The v4.15.0 release note

[PR #779](https://github.com/DaveKJohn/claude-code-specialists/pull/779)

---

