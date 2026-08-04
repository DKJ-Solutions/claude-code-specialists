# Changelog

The history of the claude-code-specialists marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #443 · The safety-critical ship-pr sequence gets the page it was already being sent to · Feat · 2026-08-04

**Check 18 declared this gap two days ago; this closes it, and the count turned out to be one smaller
than the note said.** The parameter gate's coverage line named four mirrored scripts documenting nothing,
of which three were called real gaps: `ship-pr`, `fix-mojibake` and `verify-resolved-issues`. Reading the
registry rather than the summary shows the third was never a gap of its own — its registration already
said so in as many words: *"No skill of its own, and that is right: it IS ship-pr's step 6 ... It
therefore inherits ship-pr's gap above."* So one page closes two entries, and `fix-mojibake` is the only
one left.

**The route existed before the page did.** The `cut-release` skill has been sending readers to "the normal
`new-branch` → `ship-pr` route" while no page described the second half of it — a consumer following that
sentence arrived nowhere. This is also the sequence the registry itself classifies safety-critical, on the
grounds that it merges to the main branch and then commits directly to it, which is the one procedure where
arriving nowhere is worst.

**What the page carries beyond the invocation**, because a consumer has only the mirror and this text:
all eight parameters plus the three of `verify-resolved-issues`; that **when** it may run is governance and
not script logic; why step 3 polls the *text* before it watches (`gh pr checks` prints "no checks reported"
and exits **0**, indistinguishable from "all passed", so a bare `--watch` walks the merge into a `BLOCKED`
wall); why the merge method is validated rather than passed through; why there is no `--admin`; and why the
fast-forward names `origin/main` explicitly instead of using a bare `git pull --ff-only`.

**One correction landed on the way, and it is the kind only a reader finds.**
`verify-resolved-issues.ps1`'s header said *"Deliberately workshop-local (like ship-pr.ps1 and
cut-release.ps1): NOT mirrored into the plugin."* It has been mirrored since it started travelling with
`ship-pr`, so that sentence sat **in the mirror, denying the mirror existed** — and it was wrong three
times over, because both scripts it cited as fellow cases had been shared too (`ship-pr` by #411,
`cut-release` by #417). A claim that names its own supporting evidence and gets all of it wrong is worth
more than a silent fix. **No gate could have caught it:** the drift lint compares the two copies against
each other, and a wrong sentence present in both is not drift. Verified against the registry and the
mirror directory rather than taken from the sentence itself.

**`-Resolves` gets the space it needs rather than a table row.** It is a string and not an `[int[]]`
because across `powershell -File` a comma list is cast to one number via the thousands separator —
`-Resolves 332,340` silently becomes issue `332340`. That is the one parameter here whose *type* is
load-bearing, and a consumer reading only the mirror would have no way to know.

**No new test, stated rather than skipped.** The `shared-scripts` suite already asserts that every non-lib
entry declares a `Skill` and that a non-empty one names a skill that exists — it went from 183 to 185
asserts on the two new declarations without a line being written. That is the registry-beside-the-
registration design doing what it was built for. The orchestrator's own test gap (it drives live `git`/`gh`)
is unchanged and now stated on the page as well.

Plugins: specialists

[PR #443](https://github.com/DaveKJohn/claude-code-specialists/pull/443)

---

### #442 · A shared script's parameters must appear in the skill that documents it · Feat · 2026-08-04

**Check 18 closes a class that was found by accident and then measured.** A consumer has exactly two
things: the plugin mirror of a script, and the skill that describes it. So a parameter the skill never names
does not exist for them — escape valves included. The accidental find was `fold-changelog`, which told every
consumer to commit the fold **by hand** for two days after the script gained `-Commit`/`-Push`, because that
improvement had been written into this repo's lens. One regex over the other four shared entry points found
three more.

**The gate then found a fourth that the regex had missed, which is the argument for how it reads them.**
Parameters come from the **PowerShell parser**, not a pattern match: the regex used for the initial
measurement skipped `[Parameter(Mandatory = $true)][string]$Bump` and reported three gaps where there were
four. `-Bump` is how you say what kind of release you are cutting. A gate built on that regex would have
shipped with exactly the blind spot it exists to close.

**Four repairs, and the largest was a clarity defect rather than a missing flag.** `cut-release`'s
`-Bump`, `-NoPush` and `-SkipLint` were absent because the skill never documented *cutting* at all — it
opened at "tag the release commit and push the tag", which is what the script prints when you pass
`-NoPush`. So the page silently documented only the `-NoPush` path without saying that was what it was,
while the script commits, tags **and** pushes by itself. It now starts with the invocation, states both
escape valves and why `-NoPush` matters (it is the only moment a human sees the assembled artifact before it
is public), and keeps the manual push as what it always was: the `-NoPush` follow-up.
`new-internal-note`'s `-RepoRoot` and `-Force` were the fourth.

**Two design decisions, both taken from what the registry already does.** The skill mapping and the
per-parameter exemptions are declared **in the registry beside the registration** — the reasoning `LibOnly`
already carries, that a second hand-written list is one a newly shared script falls out of silently. And an
entry point may declare `Skill = ''`, which is a *declaration* rather than an omission: the check reports
those in its coverage line by name instead of failing over them, because writing a missing skill is separate
work and blocking every unrelated PR until someone does it would get the gate bypassed.

**That coverage line is where this change surfaces a bigger gap than the one it fixes.** Four mirrored
scripts document nothing: `check-script-contract` legitimately (it runs from a hook; there is no procedure
to write down), but **`ship-pr`, `fix-mojibake` and `verify-resolved-issues` are real gaps**. `ship-pr` is
the sequence the registry itself calls safety-critical — it merges to `main` and then commits directly to
`main` — and the `cut-release` skill already sends the reader to "the normal `new-branch` → `ship-pr`
route", which is a route no page describes. `fix-mojibake` was mirrored precisely because three repos had
each written their own copy, i.e. three people needed it and none had a page. Named in the registry and in
the coverage output so the gap is visible rather than absent.

**Tests: 140 asserts in the integrity suite (up 6) and 183 in the shared-scripts suite.** Both directions
of the check, the coverage count as evidence that a parameter was really examined, and two guards that came
out of getting it wrong: a registered script **absent from the tree** must be skipped rather than reported
as a missing skill (check 8 owns that finding, and the first version of check 18 fired on every scenario in
the suite because of it), and the "declares no skill" case must be asserted against a script that **exists**
— asserting it on `ship-pr` failed, since the fixture has no `ship-pr.ps1` and the skip fires first. The
registry side asserts that every non-lib entry *declares* a Skill, that a lib declares none, that every
named skill exists, and that an exemption names a parameter the script actually has.

**A correction to yesterday's own record, made in `CHANGELOG.md` rather than left standing.** The `v3.3.0`
entry claimed the release push's ruleset bypass "was not written down anywhere before now". It was:
Sylvester's lens has carried the `main-ci-gate` ruleset, its bypass list, which account holds which right,
and the caveat that the Write bypass is only safe without external collaborators, since July 15, 2026. The
rule this repo already has for it — check whether the docs answer it before reporting a finding as new —
applied and was not followed.

Plugins: specialists

[PR #442](https://github.com/DaveKJohn/claude-code-specialists/pull/442)

---

### #441 · The release craft moves from the lens into the shared source · Docs · 2026-08-04

**Rendall's lens went from 26,219 to 21,584 bytes (−18%), and the two skills that should have been
carrying that knowledge gained it.** Green light from Dave to finish what the previous change only
established as a rule. Net 156 lines added against 97 removed — the source gained more than the lens lost,
because a rule that was implicit in a local paragraph has to be stated plainly for a reader who has none of
the surrounding context.

**The strongest justification for the whole exercise was found while doing it: the portable skill carried a
stale instruction.** `fold-changelog` told every consumer *"Then commit the result directly on main"* — by
hand. The script has been able to do that itself since August 2, 2026 via `-Commit`/`-Push`, and those
flags appeared **nowhere** in the skill; they existed only in this repo's lens. So consumers were being
told to do by hand what the shared script already did, for two days, because the improvement was written
where only this repo could read it. That is precisely the failure mode the source-first rule exists to
prevent, caught in the act.

**What moved into [`fold-changelog`](plugins/specialists/skills/fold-changelog/SKILL.md).** The entry-file
mechanism it never explained: *why* a branch never edits `CHANGELOG.md` directly (every branch would touch
the same section, and a conflict there is pure noise since the entries never disagree), the filename rule
and why a `-v2` suffix silently breaks the auto-delete, the entry format and which parts only the fold can
add, and **the `##`-in-a-body trap** — a body's `##` climbs out of its category, and it bites only once the
release cut lifts the body into the notes, past every gate that could have judged it. Plus the two things
that go wrong in practice: `gh pr merge --delete-branch` can leave the local checkout **on the merged
branch**, so check rather than trust the flag; and always fold with `-Branch` when two machines are in
play, or you fold an entry the other machine is still folding.

**What moved into [`cut-release`](plugins/specialists/skills/cut-release/SKILL.md).** The marketplace-cache
gate, as a per-command table rather than one rule — because the tidy generalisation was tested and broke:
`install` does **not** refresh the cached clone (two independent releases) while `update` **does** and
advances the clone during its own run. With the reason it must be said out loud at all: a stale cache is
invisible by construction, reporting success with a plausible version number, and an install's success line
names no version whatsoever. Also `-SummaryFile` and the milestone rule that a `major` bump must state
plainly when it breaks nothing.

**What stayed, and why it is not laziness.** The lens keeps lockstep across four plugins, the per-plugin
`CHANGELOG.md` and `RELEASE.md` cards, "only at Dave's explicit request", which bumps get a Release, the
`3.x` grouping, and the direct-on-`main` exception the fold commit runs under — that last one being exactly
what the path-scoped commit exists to keep honest, which is a governance fact about *this* repo rather than
a property of the script. Every migrated block leaves a citation naming where it was measured here:
`v2.13.2` for the `##` trap, July 16 and PRs #46/#47 for the two git lessons, `v3.0.2`/`v3.0.4`/`v3.0.5`
for the cache measurements, and the 2.x seam for the "a major that breaks nothing" case.

**One measurement worth keeping about the shape of the result.** The migrated text is longer in the source
than it was in the lens, and that is not padding: a lens paragraph can lean on the reader already knowing
the repo, while a portable one must state the mechanism from scratch. Expect the same ratio on the next
migration rather than reading the growth as duplication.

Plugins: specialists

[PR #441](https://github.com/DaveKJohn/claude-code-specialists/pull/441)

---

### #440 · In the source repo the source is the default destination, not the lens · Docs · 2026-08-04

**Dave's correction, August 4, 2026: this repo *is* the source, so a lesson learned here belongs in the
shared source unless it genuinely only applies here.** The lens is for what a *consumer* would have to
differ on — not the convenient place to write something down because it is the file already open. The
consequence of getting it wrong is one-directional and silent: a portable rule written into the lens
reaches nobody downstream, and looks identical while you are typing it.

**The measurement that shows how far this had drifted.** Rendall #06's portable persona is **1,700
bytes**; his repo lens had grown to **26,914** — sixteen times larger, and holding the release craft
itself rather than anything specific to this repo. Derek #05 sits at 5,835 against 23,995, Chris #01 at
7,943 against 14,469. The lens was winning everywhere.

**The layer test was measured rather than invented, and it changed the plan.** The first assumption was
that portable documents cannot carry repo-specific evidence at all. Held against the plugin's own files
that is true of **personas and manuals** — zero issue numbers, versions, repo names or person names across
all 18 — and false of **skills**, which carry 103 such references, including a character limit attributed
to the consumer repo it was hit in. So the convention the repo has actually been holding is three-layered:
the craft goes to a persona or manual stripped of every number, a *procedure whose reason rests on a
measurement* goes to the **skill** with the measurement included, and only what is true solely here stays
in the lens. Had the first assumption been acted on, today's lessons would have been abstracted into
toothless one-liners to fit a rule the repo does not have.

**Applied to the four lessons recorded in lenses earlier today.** Three were already in the right place:
the release-body rule, the attachment-name collision and the snapshot heading had all gone into the
`cut-release` skill with their measurements, and the snapshot rule into the script's own skeleton hint.
The fourth had not: **the parked-branch lesson now lives in the `park` skill**, which described parking
in full and picking a branch back up not at all. A consumer meets that gap exactly as this repo did.

**The two lens blocks that duplicated the source are reduced to their local half** — the rule and the
mechanism read from the skill, the lens keeps the citation naming where it was measured. Net: 90 lines
added, 33 removed, and the portable side gained everything the lens side lost.

**Recorded in the two places someone looks:** the practical test and the three-layer table in the
[Specialists handbook](.claude/specialists/README.md), where the source-vs-lens model is already
explained, and the rule itself in [`CLAUDE.md`](CLAUDE.md)'s repo slot beside "changes to shared agent
defs land here first" — which stated the same instinct about agent defs and had never been generalised.

**Deliberately not done, and it is a decision rather than an omission.** Rendall's remaining ~26 KB is not
migrated here. Most of it is portable — the entry-file mechanism and why a branch never edits
`CHANGELOG.md` directly, the entry format and the `##`-climbing-out-of-its-category trap, the
branch→merge→fold lifecycle with the multi-machine lesson, the two update-cache gates with their measured
`install`-versus-`update` distinction, and `-SummaryFile` — and each block needs its portable half
separated from its local half by hand before it can travel. That is several PRs of careful work in
documents that reach every consumer, so it is proposed rather than started. What stays local is already
clear: lockstep across four plugins, the per-plugin CHANGELOG and RELEASE.md cards, "only at Dave's
explicit request", which bumps get a Release, and the `3.x` grouping.

Plugins: specialists

[PR #440](https://github.com/DaveKJohn/claude-code-specialists/pull/440)

---

### #439 · The internal note's open section is a snapshot, because it is published · Fix · 2026-08-04

**Three instances in one day is a structural problem, not three editing mistakes.** Making the internal
note the GitHub Release body turned it from an archive document into published output — and its third
heading, *"What is still open"*, is written in the present tense about a moment that passes. All three
went stale within hours of being written:

1. A line saying the user-facing notes still needed an editorial pass — they were edited hours later.
2. A line pointing at "the notes **attached to** that release" — that release had no Release, so no
   attachment.
3. A line stating the previous release had no public page — published minutes before it got one, by the
   same session.

None were wrong when written. That is the whole point: a present-tense claim in an immutable document has a
shelf life measured in hours, and correcting each one as it surfaces is a treadmill.

**So the heading changed rather than the lines.** It now reads **"What was still open at this release"** —
past tense, naming the release. That makes the section a snapshot by construction, so the same sentences
stay true indefinitely. The skeleton hint says so explicitly and carries the measurement, because a writer
who does not know the document gets published will reach for the present tense every time.

**The default changed, not this repo's override.** The wording lives in `new-internal-note.ps1`'s defaults
and is overridable per repo through `Get-InternalNoteWording` — so this reaches every consumer, and a repo
that has translated the headings keeps its own. The script is mirrored, so both copies moved and were
verified byte-identical.

**Two existing notes were brought in line**, since both are now published Release bodies: `v3.2.0` (heading
only — its content was still accurate) and `v3.3.0` (heading plus the stale line about the previous
release, which now says it had none *at the moment this was written* and has one now).

**Tests: 54 asserts, up 2, and one of them is a negative on purpose.** The old present-tense heading must
**not** appear — it is the natural thing to type back in, and a positive assert alone would not notice.
The second checks the skeleton hint still tells the writer to write a snapshot. One thing learned while
writing them: `Test-Line` in that suite is a **whole-line** matcher (`(?m)^…\r?$`, built that way because
the skeleton is CRLF), so a mid-line substring assert must not use it — the first version of the hint
assert failed for that reason and not because of the code it was testing.

**The half that no rule can carry** is stated in the release manager's lens: re-read the *previous*
release's note whenever something it called open closes. The development notes and the highlights need no
such pass — they are written once and left alone. This tier is the only one that acquired a reason to be
revisited, and it acquired it yesterday.

Plugins: specialists

[PR #439](https://github.com/DaveKJohn/claude-code-specialists/pull/439)

---

### #438 · Two release attachments cannot share a filename, and the checklist did not say so · Fix · 2026-08-04

**Found by walking the checklist rather than by reading it, on the first Release published under the new
body rule.** Step 5 said `gh release upload vX.Y.Z <development-notes> [<highlights>]` — and all three
release tiers name their file `<X.Y.Z>.md`. An asset's name is its **basename**, so the first upload
succeeded and the second returned `HTTP 404` on `…assets?label=…&name=3.3.0.md`. Every consumer following
that line with two attachments would have hit it.

**`gh`'s `file#label` syntax looks like the fix and is not.** It sets the asset's *label* and leaves `name`
as the basename — visible in the failing request above, which carried the label and the colliding name
together. The repair is to copy each attachment to a distinct filename and upload the copies
(`vX.Y.Z-development-notes.md`, `vX.Y.Z-notes-for-users.md`). Worth doing on its own merits: a reader who
downloads `3.3.0.md` cannot tell which of the three tiers they received.

Recorded in all three places someone meets this — the `cut-release` skill's step 5, the release manager's
lens, and `releases/README.md` — with the measurement rather than as advice, since the failing URL is what
makes the cause unambiguous.

**And a second defect the same publication exposed, of the class predicted a day earlier.** `v3.3.0`'s
internal note said the migration steps for the marketplace rename are "in the user-facing notes **attached
to** that release" — but `v3.2.0` has no GitHub Release, so there is no attachment to point at. The
highlights carried the same claim. Both now point at something that is true whether or not that release is
ever published: the note names the previous release's notes and the project's adoption guide, and the
highlights link the file directly.

That is exactly why the internal tier stopped being an archive document when it became the Release body
(PR #436): a claim about *where a reader can find something* is now a claim made in public, and it can be
false for a reason that has nothing to do with the release it appears in. The published body is corrected
in place once this merges.

Plugins: specialists

[PR #438](https://github.com/DaveKJohn/claude-code-specialists/pull/438)

---

### #437 · The written notes for v3.3.0: the internal summary and the highlights · Docs · 2026-08-04

**The first release cut under the rule it is itself about**, so both written documents exist before the
Release is published rather than after. `v3.3.0` collects eight entries — two `Feat`, five `Docs`, one
`Chore` — that are almost entirely about the release process: its third tier, its third gate, and the shape
of its public page.

**The marker put both consumer-facing items below itself, which is now two for two.** The generated draft
placed the two `Feat` entries above the "remove before publishing" line and the other six under it. Both
items a consumer actually has to *act* on were in the bottom half:

- **A PR is refused while its entry still carries the scaffolder's wording** (`Feat`, so this one was
  above the line — but its consequence is behavioural, not a feature, and it is written as such).
- **The highlights tier no longer produces a print-ready `.html`** — a `Chore` branch that *removes output
  a consumer was receiving*. In a repo with the tier enabled, the next cut produces markdown alone. That
  is the second release running in which the branch prefix pointed the wrong way, so the warning in the
  release manager's lens now rests on two independent instances rather than one.

**The internal note is the release body, so this one was written to be read rather than filed.** Held to the
tier's constraints — one page, no file names, no code, nothing that means nothing outside the team — and to
the rule added yesterday: where a release needs action, say so and point at the attachment. Its opening
states that this release needs none, and that anyone still on the old marketplace name is looking at the
*previous* release's change, which no error message will ever mention.

**What the release is worth, once translated out of eight technical titles.** The work becomes visible
without anyone summarising it afterwards, because the page is produced as part of finishing the release
rather than as a favour later — and the small releases, which used to be skipped entirely, are exactly
where the quiet improvements live. Unfinished text can no longer reach a customer, which is a repair and
not a precaution: three descriptions in the previous release kept a scaffolded heading and travelled all
the way into the files that ship in the plugin cache. And editing the user-facing version is a known
quantity now — the first one went from roughly eleven hundred lines to a hundred and fifty — so the next is
an hour of editing rather than an open-ended question.

**Two verification notes from the cut itself, both recorded because they are cheap now and expensive later.**
The em-dash defect did **not** reproduce: every carried-over heading in the `## Releases` block kept its
em-dash inline. That is the third independent observation that it does not occur against the real
changelog, which strengthens the case that the cause is not where the isolated repro suggests. And the push
reported `Bypassed rule violations -- required status check "lint-en-tests" is expected`: the release
commit reaches `main` through a **ruleset bypass on the account**, not through an exception in the ruleset
itself. The gates did run, locally, before the commit — but they did not run as CI.

**Correction, made the same day:** this entry originally added that the distinction "was not written down
anywhere before now". That was wrong, and it is corrected here rather than left standing.
[Sylvester #15](.claude/specialists/lenses/05-15-extension.md) has documented it since July 15, 2026 —
the `main-ci-gate` ruleset, its bypass list (Repository admin plus the Write role, "Always allow"), which
account holds which right, and the standing caveat that the Write bypass is only safe while there are no
external collaborators. The lesson is the one this repo already has a rule for: check whether the repo
already answers it before reporting a finding as new.

**For the record, the scaffolded heading this all concerns**, quoted inside a fence so this entry is not
accused of carrying it — which is exactly the exclusion the gate was built with:

```
**To do / where I left off:** done -- lint gate green, all suites green.
```

[PR #437](https://github.com/DaveKJohn/claude-code-specialists/pull/437)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v3.3.0] - 2026-08-04 — Minor

See [releases/development/3.x/3.3.0.md](releases/development/3.x/3.3.0.md) for the full release notes.

---

### [v3.2.0] - 2026-08-03 — Minor

See [releases/development/3.x/3.2.0.md](releases/development/3.x/3.2.0.md) for the full release notes.

---

### [v3.1.2] - 2026-08-02 — Patch

See [releases/development/3.x/3.1.2.md](releases/development/3.x/3.1.2.md) for the full release notes.

---

### [v3.1.1] - 2026-08-02 — Patch

See [releases/development/3.x/3.1.1.md](releases/development/3.x/3.1.1.md) for the full release notes.

---

### [v3.1.0] - 2026-08-01 — Minor

See [releases/development/3.x/3.1.0.md](releases/development/3.x/3.1.0.md) for the full release notes.

---

### [v3.0.9] - 2026-08-01 — Patch

See [releases/development/3.x/3.0.9.md](releases/development/3.x/3.0.9.md) for the full release notes.

---

### [v3.0.8] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.8.md](releases/development/3.x/3.0.8.md) for the full release notes.

---

### [v3.0.7] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.7.md](releases/development/3.x/3.0.7.md) for the full release notes.

---

### [v3.0.6] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.6.md](releases/development/3.x/3.0.6.md) for the full release notes.

---

### [v3.0.5] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.5.md](releases/development/3.x/3.0.5.md) for the full release notes.

---

### [v3.0.4] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.4.md](releases/development/3.x/3.0.4.md) for the full release notes.

---

### [v3.0.3] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.3.md](releases/development/3.x/3.0.3.md) for the full release notes.

---

### [v3.0.2] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.2.md](releases/development/3.x/3.0.2.md) for the full release notes.

---

### [v3.0.1] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.1.md](releases/development/3.x/3.0.1.md) for the full release notes.

---

### [v3.0.0] - 2026-07-30 — Major

See [releases/development/3.x/3.0.0.md](releases/development/3.x/3.0.0.md) for the full release notes.

---

### [v2.16.0] - 2026-07-30 — Minor

See [releases/development/2.x/2.16.0.md](releases/development/2.x/2.16.0.md) for the full release notes.

---

### [v2.15.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.15.1.md](releases/development/2.x/2.15.1.md) for the full release notes.

---

### [v2.15.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.15.0.md](releases/development/2.x/2.15.0.md) for the full release notes.

---

### [v2.14.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.14.1.md](releases/development/2.x/2.14.1.md) for the full release notes.

---

### [v2.14.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.14.0.md](releases/development/2.x/2.14.0.md) for the full release notes.

---

### [v2.13.3] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.3.md](releases/development/2.x/2.13.3.md) for the full release notes.

---

### [v2.13.2] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.2.md](releases/development/2.x/2.13.2.md) for the full release notes.

---

### [v2.13.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.1.md](releases/development/2.x/2.13.1.md) for the full release notes.

---

### [v2.13.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.13.0.md](releases/development/2.x/2.13.0.md) for the full release notes.

---

### [v2.12.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.12.0.md](releases/development/2.x/2.12.0.md) for the full release notes.

---

### [v2.11.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.11.0.md](releases/development/2.x/2.11.0.md) for the full release notes.

---

### [v2.10.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.10.0.md](releases/development/2.x/2.10.0.md) for the full release notes.

---

### [v2.9.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.9.0.md](releases/development/2.x/2.9.0.md) for the full release notes.

---

### [v2.8.0] - 2026-07-27 — Minor

See [releases/development/2.x/2.8.0.md](releases/development/2.x/2.8.0.md) for the full release notes.

---

### [v2.7.3] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.3.md](releases/development/2.x/2.7.3.md) for the full release notes.

---

### [v2.7.2] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.2.md](releases/development/2.x/2.7.2.md) for the full release notes.

---

### [v2.7.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.1.md](releases/development/2.x/2.7.1.md) for the full release notes.

---

### [v2.7.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.7.0.md](releases/development/2.x/2.7.0.md) for the full release notes.

---

### [v2.6.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.6.1.md](releases/development/2.x/2.6.1.md) for the full release notes.

---

### [v2.6.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.6.0.md](releases/development/2.x/2.6.0.md) for the full release notes.

---

### [v2.5.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.5.0.md](releases/development/2.x/2.5.0.md) for the full release notes.

---

### [v2.4.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.4.1.md](releases/development/2.x/2.4.1.md) for the full release notes.

---

### [v2.4.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.4.0.md](releases/development/2.x/2.4.0.md) for the full release notes.

---

### [v2.3.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.3.0.md](releases/development/2.x/2.3.0.md) for the full release notes.

---

### [v2.2.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.2.1.md](releases/development/2.x/2.2.1.md) for the full release notes.

---

### [v2.2.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.2.0.md](releases/development/2.x/2.2.0.md) for the full release notes.

---

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
