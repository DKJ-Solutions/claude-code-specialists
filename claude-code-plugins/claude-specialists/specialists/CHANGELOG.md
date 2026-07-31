# Changelog — specialists

Consumer-facing history of this plugin: per release, the changes that touched this plugin.
Automatically appended by `cut-release.ps1` of the marketplace repo (davekjohns-workshop); the full
workshop history lives there in `CHANGELOG.md` and `releases/`.

## v3.0.4 — 2026-07-31

### Features

#### #290 · a gate for the class: printed lifecycle commands must carry their flags · Feat · 2026-07-31

The structural half of test round v5's result
([#287](https://github.com/DaveKJohn/davekjohns-workshop/issues/287) §4), and the reason that issue
exists at all. Three adoption rounds in a row found the same kind of defect and almost nothing else: a
doc place printing a command, a count or a step that no longer holds. v3 was the adoption path plus
three reporting errors; v4 was #279 + #280; v5 was **all four** of its findings — and three of the five
repairs in 3.0.3 were of that kind too. Four doc fixes close four instances, and the instances came
back every round. This adds **check 11** to
[`check-plugin-integrity.ps1`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/scripts/lint/check-plugin-integrity.ps1), so the part of that class a
gate can actually decide stops depending on someone noticing.

**The rule.** Every printed `claude plugin install` / `update` / `uninstall` must carry
`--scope project`, and `install`/`update` must have `claude plugin marketplace update` — or a link to
*Staying up to date* — within 12 lines above or 6 below. Both are things a reader **copies**, and both
fail *silently* when wrong: a scopeless install writes a machine-wide record with no `projectPath` and
reports success (#274/#279), a stale cache serves the previous version and reports success (#282/#284).

**Why this can be a generic scan where check 10 had to be opt-in.** That one (the marked all-skills
enumeration check) measured 147 hits repo-wide on a generic prose scan — including a deliberately
illustrative list that would false-positive forever — and was made sentinel-driven for exactly that
reason. The discriminator here is the **`@`-target**: `claude plugin install
specialists@davekjohns-workshop --scope project` is an instruction someone runs, while
"`claude plugin update` has the same default" is prose discussing the command, and demanding flags of
prose would be nonsense. Measured over the scan set: **11 targeted, 13 bare.** That separation is what
makes the check viable, and it is the case the test suite guards first.

**History is excluded permanently and on purpose:** `CHANGELOG.md` (root and per-plugin),
`releases/**`, every `RELEASE.md` card, and the root changelog entry files. Those record what was true
at the time and are never rewritten — the same principle the teardown's own audit already applies. The
repo proves the need: `specialists/CHANGELOG.md` prints a targeted install with no scope flag,
correctly, because that is what the release it describes actually said.

**Three implementation bugs, all three worth recording, because each one was a way for the gate to be
quietly wrong.** The first build was line-based and flagged the teardown SKILL's own
`claude plugin uninstall …` line, whose `--scope project` sits on the *next* line of the same
inline-code span — so the unit became the enclosing span. The second was quieter and therefore worse:
spans are found with a `` `…` `` pattern, and a fence delimiter opens a phantom span that pairs every
real span downstream one position out, which made the wrapped command look *flagless* rather than
raising anything; reusing check 10's `Get-FenceMaskedText` fixed it. The third came out of the code
review: both rules judged the whole span, so two commands in one span meant the second borrowed the
first one's `--scope project` and read as correct while a reader copies a scopeless line. The unit is
now this verb's own arguments, up to the next lifecycle command. All three are locked in as scenarios
21, 22 and 25 — and the second and third are the kind that fail *green*, which is the same failure mode
as the findings this whole round was about.

**And it immediately earned its place**: on first green run it found a fourth spot PR #289 had left
alone — the family README's `--scope project` blockquote printed an update command with the refresh
seven lines too far below. The doc was rewritten so the sentence that prints the command carries the
refresh, rather than widening the window to fit the doc.

**What this deliberately does not claim.** #287 frames one such gate as closing *the class*; it closes
the half that is decidable by pattern — the flags on a printed command. A stale **count** ("nineteen
lenses", "three acts") or a stale **step** in a procedure is still a human finding, and check 11 would
not have caught #283, #285 or #286 either. It also checks *presence*, not order: whether the refresh is
described before the install in reading order is a judgement about prose, and the check does not pretend
to make it. Coverage is stated out loud for the same reason — an empty scan prints *why* it is empty, so
"nothing to enforce" cannot be misread as "the docs are right".

Also updated so the gate's description stays true where it is made: `CLAUDE.md`, `CONTRIBUTING.md`, and
[Sylvester #15's lens](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/.claude/specialists/lenses/05-15-extension.md).

[PR #290](https://github.com/DaveKJohn/davekjohns-workshop/pull/290)

### Fixes

#### #289 · the install path never names the marketplace refresh · Fix · 2026-07-31

Inbound [#284](https://github.com/DaveKJohn/davekjohns-workshop/issues/284), test round v5. The #282
fix — the marketplace cache is a second update gate — landed completely on the **update** side and on
exactly one of the places that describe a first **install**: `specialists-init/SKILL.md` step 0b. The
QUICKSTART's Step 1 and the family README's Step 0 still printed an install with no
`claude plugin marketplace update` in it.

**The sharp part is where the evidence sits.** The measurement the QUICKSTART itself cites is a fresh
`install`, not an `update`: minutes after `v3.0.2` was tagged, `claude plugin install … --scope project`
produced **3.0.1** and said `✔ Successfully installed`. That sentence lives under *Staying up to date* —
a section headed "Updates reach you via **releases**", which is not where the install reader goes. So a
new consumer following the three steps literally skipped the refresh and walked into the exact fault the
page had already measured, with nothing in the output to betray it: a green install, a plausible version
number, and a session quietly missing whatever the release added.

That weighs more than a forgotten cross-reference, for a reason the two documents state about
themselves. The QUICKSTART is, per the root README, *the* canonical enable-a-plugin walkthrough and is
explicitly aimed at someone who did not build the system — the reader with no experience to fill a gap
with. And Step 0 of the family README says of itself: *"This documentation path is the only thing a new
consumer has, because until the plugin loads, the skill that would say otherwise does not exist."* Which
is precisely why the correct version in `specialists-init/SKILL.md` cannot cover for either of them.

Four places now name it:

- **QUICKSTART Step 1** — two numbered lines, refresh first, with one paragraph on why an install-time
  reader is the one who needs it, pointing at *Staying up to date* for the full mechanics rather than
  restating the measurement.
- **Family README Step 0** — "three acts in order" is now **four**. The acts being counted is what made
  a missing one expensive here, so it is an act rather than a parenthesis, plus a blockquote naming both
  the behaviour (#282) and the omission (#284).
- **`connectors/README.md`** — the version-gate line named the scope flag but not the refresh; it now
  names both. The weakest of the three, and the same asymmetry.
- **The root README's Consumption paragraph** — which #284 did not list. It printed
  `claude plugin install … --scope project` with the flag and no refresh. Found by running #284's own
  suggested verification (grep every place that prints a lifecycle command, and check what travels with
  it) instead of only the three addresses the finding named.

**Deliberately not claimed: this is a doc finding, not a second measurement of #282.** The stale-cache
state could not be produced naturally in this round — the cache on that machine had been refreshed on
July 30 when `v3.0.3` was released — and following QUICKSTART Step 1 literally, *without* the refresh,
simply produced 3.0.3. What was measured is that the step was missing in the places above.

[PR #289](https://github.com/DaveKJohn/davekjohns-workshop/pull/289)

---

#### #288 · the teardown skill's own checks report the wrong answer · Fix · 2026-07-31

Three findings from test round v5 (life-hub against 3.0.3, inbound
[#283](https://github.com/DaveKJohn/davekjohns-workshop/issues/283),
[#285](https://github.com/DaveKJohn/davekjohns-workshop/issues/285),
[#286](https://github.com/DaveKJohn/davekjohns-workshop/issues/286)), and one class: a **documented
check that silently reported the wrong answer**. Nothing was wrong with what the teardown *does* — the
round showed no accumulation, matching preview/apply totals, and a byte-identical `CLAUDE.md` after two
full cycles. What was wrong is what the skill told an operator to run, and what the run told them back.

**The pre-flight said "stop here" to a repo that ignores nothing (#283).** `git check-ignore -v
.claude/specialists/lenses/` returned a hit in life-hub — `.gitignore:19:` + TAB + the path, exit `0` —
while nothing about that path was ignored: no `claude` line anywhere in `.gitignore`, 16 files under
`.claude` tracked, no `core.excludesFile`, a default `info/exclude`, and line 19 of that file blank.
Isolated in fresh fixtures: with **CRLF line endings and at least one blank line**, git reads the blank
line as a pattern of a single `CR`, which matches every path with a trailing slash. That is the normal
state of a repo on Windows, and both real consumers are Windows repos. It is also the harder mistake to
distrust — the output looks like a real gitignore hit, filename and line number included, and the only
tell is that the **pattern field is empty**. Worse in kind than the fault it inherited: this check was
*added* in 3.0.3 to fix #280, where the old one merely alarmed a safe repo. This one hands it the
section's single stop-work verdict.

The command now reads its own output and keeps only hits whose pattern field is filled. Two
measurements decided that shape over the tempting alternative:

- **Dropping the trailing slash would trade the false positive for a false negative.** In a CRLF repo
  that genuinely ignores `node_modules/`, `git check-ignore -v node_modules` (no slash, directory absent
  from disk) exits `1` — a real ignore rule, missed.
- **The artefact never outranks a real pattern.** With a genuine rule placed *before* and *after* the
  blank line, git reported the genuine one, pattern field filled, in both orders. So filtering can only
  ever remove a false hit, never suppress a true one. Deliberately **not** claimed: *why* git prefers
  the real pattern. It was measured in both orders, not explained, and the fix does not depend on the
  mechanism.

**Two of the four prescribed round-trip measurements were measuring nothing (#285).** The import counter
used `[System.IO.File]::ReadAllLines('CLAUDE.md')` — a .NET static call with a relative path, which
resolves against `[Environment]::CurrentDirectory` and *not* against `Set-Location`. Measured from a
fresh disposable consumer: `19` lenses counted in that folder, `0` imports read out of **life-hub's**
`CLAUDE.md`, in the same block. The lone-LF counter used a `$text` the document never assigned anywhere,
and `[regex]::Matches($null, …)` does not throw — it returns zero matches. Both wrong answers are the
**green** one: a `0` reads as "the import was removed cleanly" and as "no line-ending pollution", which
are precisely the two defects the protocol exists to catch. The block now reads `CLAUDE.md` once, into
`$text`, from a path anchored to the repo root, and the lone-LF counter reuses it.

**The report counted per line while the doc counted per note (#286).** The bootstrap's note is a
two-line block, so `teardown.ps1` printed *the bootstrap's orchestrator note line* twice, byte-identical
— and `SKILL.md` frames that counter as the defective series 1 → 2 → 3. A healthy repo therefore showed
`2` to anyone counting from the report, which is the most natural source because the word is right there:
the clean run's loudest reading was the accumulation defect itself. Two identical lines also carried no
information about *which* of the two was meant. The lines now name it —
`CLAUDE.md:<n> -- the bootstrap's orchestrator note (head|tail)`, the same `file:line` format the audit
below it already uses for the same reason — and the bullet in `SKILL.md` names the head line as the unit
and says out loud that the report shows two. `Test-IsOrchestratorNoteLine` was correct and is untouched,
so the two `check-report-lib.ps1` copies stay byte-identical.

**And a gate, because none of this was visible to one.** `scripts/tests/teardown-protocol.tests.ps1`
tests the commands the *skill* prints rather than the script: it extracts the pre-flight's
`Where-Object` from `SKILL.md` and executes **that** against six real git fixtures (LF, CRLF with and
without a blank line, a genuine rule, and a genuine rule on either side of the blank line), so a
document that drifts back to the unfiltered command goes red. Whether this git version still produces
the artefact is reported rather than asserted — a future git that fixes it should not fail the suite,
but it should be visible. `teardown.tests.ps1` gained the report case for #286, asserting the two lines
are distinct and that each line number really resolves to a note line of the half it claims.

[PR #288](https://github.com/DaveKJohn/davekjohns-workshop/pull/288)

---

## v3.0.3 — 2026-07-30

### Fixes

#### #282 · the marketplace cache is a second update gate · Fix · 2026-07-30

Found by using v3.0.2 rather than by reading about it: minutes after that release was tagged and
pushed, installing the plugin in this repo produced **3.0.1** and reported `✔ Successfully installed
plugin: specialists@davekjohns-workshop (scope: project)`. The `github` marketplace source is a
**cached clone**, and it was still sitting on `96aa5a1` — the commit before PR #281 merged, let alone
before the release. `claude plugin marketplace update davekjohns-workshop` followed by a single
`claude plugin update … --scope project` then moved it `3.0.1 -> 3.0.2`.

**So the version number is one of two gates, and the docs only knew about one.** `plugin
install`/`plugin update` compare against the consumer's cached copy of the marketplace, not against
this repo — a distinction with no visible symptom, because a stale cache produces a success message
and a plausible version number. The sentence this corrects was written the same afternoon, in the
release that fixed the previous round of doc-versus-behaviour defects: *"you get changes as soon as
the workshop has cut a new version — not before."* True of the version comparison, and wrong about
what a consumer actually experiences.

Recorded in four places, each stating what was measured rather than a mechanism: the
[Quickstart](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/QUICKSTART.md#staying-up-to-date)'s *Staying up to
date* (now two commands, with the stale-install measurement as the reason), `specialists-init` step 0b
(both the install and the update block), the root README's update-gate paragraph, and
[Rendall #06's lens](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/.claude/specialists/lenses/05-06-extension.md#versioning--releases) — where it
also changes the closing act of a release: **pushing the tag is not the end.** A release cannot
refresh a consumer's cache, so the closing report has to name the command that can.

Deliberately not claimed: that the cache never refreshes on its own. `claude plugin marketplace
update` reports `Refreshing marketplace cache (timeout: 120s)`, so a mechanism exists; on what
schedule it fires unprompted was not established, and the docs say so instead of guessing. The
explicit command is in the procedure because "wait an unknown while" is not a step anyone can follow.

[PR #282](https://github.com/DaveKJohn/davekjohns-workshop/pull/282)

---

## v3.0.2 — 2026-07-30

### Fixes

#### #281 · install scope and the two verification checks (inbound #279, #280) · Fix · 2026-07-30

Adoption round v4 (life-hub, against 3.0.1) filed two doc-versus-behaviour defects. Verifying them
against this machine turned up two more of the same family, so all four are fixed together.

**1. The scope flag — `install`, `update`, and `uninstall` (inbound
[#279](https://github.com/DaveKJohn/davekjohns-workshop/issues/279)).** `specialists-init` step 0b
explained that an install is project-scoped and then gave the command **without** `--scope project`.
All three `claude plugin` verbs default to `--scope user` (verified via their own `--help`), so the
documented step produced a machine-wide record with no `projectPath` — precisely what the paragraph
above it said the step exists to create. The same default makes `claude plugin update` fail outright
on a project-scoped install with *"Plugin `specialists` is not installed at scope user"*: literally
true, easily read as "not installed at all", and the obvious response — re-running the install —
silently adds a second, machine-wide record beside the project one.

**Dave decided the open question explicitly on July 30, 2026: project scope is the intended model.**
It is what both real consumers carry, it keeps a repo pinned to the version it was tested against,
and the rest of the family's documentation is written against it. So the flag was added rather than
the justification rewritten: step 0b (install + a new update paragraph), the family README's step 0,
the root README's Consumption and update-gate paragraphs, the Quickstart's install and *Staying up to
date* sections, and the connectors README's version-gate line. `uninstall` was found to share the
default while fixing the rest, so the teardown skill and `teardown.ps1`'s closing note carry the flag
too. Prose mentions of "after a plugin update" were left alone — they name the event, not a command.

**2. `claude plugin list` is not a verification (found while checking #279).** Step 0c prescribed it
as the self-check against the silent no-install failure of #276. Measured in this repo on July 30,
2026: `davekjohns-workshop` has `enabledPlugins` set, **no install record of its own**, and no loaded
plugin — no `specialists:*` subagents, no skills, no session hooks — and the list still reported
`Status: ✔ enabled` at `Scope: project`. It enumerates records beyond the current repo, so a green
line proves nothing about *this* one. Worse, 0c's own "just check each plugin appears as `enabled` at
all" caveat steered the reader past the one signal that would expose a stray record. Step 0c and the
Quickstart now query `installed_plugins.json` for a record whose `projectPath` is this repo — a check
verified in both directions here (empty in the workshop, two `project` rows for life-hub) — and add
the in-session confirmation that the skill and hooks actually arrived. Why the list reports as it
does was not established and is deliberately not recorded as a mechanism.

**3. The teardown pre-flight reported the alarming answer for the safe repo (inbound
[#280](https://github.com/DaveKJohn/davekjohns-workshop/issues/280)).** `git ls-files .claude` lists
**committed** files only, so immediately after a bootstrap — which is exactly when the section says
to run it — it comes back empty in a repo whose `.claude/` is fully tracked, contradicting the table
two lines below it. The single command could not separate *"this repo can never protect its lenses"*
(ignored) from *"you have not committed them yet"*, and only the first is a reason to stop. The
pre-flight is now two commands: `git check-ignore -v` answers the ignore question directly and
regardless of commit state, `git ls-files` answers whether the undo has been claimed. Both were
verified in this repo. Added with it: the undo the table promises begins at the **commit**, not at
the bootstrap.

[PR #281](https://github.com/DaveKJohn/davekjohns-workshop/pull/281)

---

## v3.0.1 — 2026-07-30

### Fixes

#### #277 · three reporting inaccuracies in teardown/init (inbound #275) · Fix · 2026-07-30

Three defects measured in the v3.0.0 adoption round (two full `init` → `teardown` cycles in an
*occupied* consumer, July 30, 2026). None broke a run; all three made a report claim something other
than what happened, which is the class the previous round was about.

**1. The preview and the apply run now report the same total.** They differed by two on identical work
— `29 item(s) to remove` against `31 item(s) removed`, reproduced in both cycles — because the
directory prune (`lenses/`, then `specialists/`) sat entirely inside `if ($Apply)`: pruned, listed and
tallied on the apply run, never mentioned in the preview. A dry run is explicitly *the inventory a
reader needs in order to say yes*, so a preview that undercounts its own execution weakens exactly the
property it exists to provide. Both modes now list those directories under `[remove]` off **one code
path**: on a dry run the emptiness is *predicted* (a directory counts as empty when every file still in
it is already on the remove list), which is the same question `-Apply` answers by looking. One label
serves the printed line and the tally, so the list and the number cannot describe an item differently.

**2. The free-standing audit now excludes at line granularity, not only per file.** The 3.0.0 fix
excluded *files* the run is about to delete; the bootstrap's orchestrator note and its `@`-import(s) are
*lines* it deletes inside a `CLAUDE.md` that stays. So a dry run reported `CLAUDE.md:<n> -- name 'Chris'`
as a surviving live reference on the very run that lists that line under `[remove]`, and the audit fell
from 5 live references to 4 after `-Apply` on a consumer that changed nothing in between — over-reporting
by exactly what the run removes, in the mode where a reader is least able to tell. The predicate is
**hoisted and shared** with the section that does the removing (a predicate mirrored by hand in two
places is what produced both instances of the orphaned-note defect), and it matches on **content, not
line numbers**: after `-Apply` every number has shifted, so a number-based exclusion would skip the wrong
lines. The exclusion is stated in the scan line like the file-level one, and it counts **references
excluded rather than lines skipped** — most removed lines carry no reference at all, and counting those
would inflate a notice into a claim.

**3. `specialists-init` no longer documents fewer personas than it places.** `SKILL.md` named three
(Chris `01-01`, Derek `05-05`, Rendall `05-06`) while the bootstrap enumerates `personas/` and places
**four** — `03-02` (Bianca) was missing from the prose. Nothing miscounted: the closing line reported
`4 persona-lens(es) created` honestly and the total was right; the description was simply narrower than
the behaviour, which costs a reader a detour. The doc now says the set is read from the payload, lists
all four, and names the run's own counter as the authority — so it grows on its own when a release adds
a persona.

**Tests (all three, and each verified to fail against the old code — 7 asserts did):**
`teardown.tests.ps1` gains *"the dry run and the apply run count the same items"* (both counts read out
of the real output rather than pinned to today's lens inventory, so the next added specialist does not
break the guard) and *"the audit excludes removed CLAUDE.md LINES"* (a fixture carrying one genuinely
authored `Derek` reference, so "no hits at all" cannot pass it for the wrong reason, plus the
before/after-`-Apply` count that used to drop by one). `bootstrap-drift.tests.ps1` gains a check that
`SKILL.md` names **every** persona id the payload ships and that the run's counter matches that number.

Reported from a consumer via [issue #275](https://github.com/DaveKJohn/davekjohns-workshop/issues/275).

[PR #277](https://github.com/DaveKJohn/davekjohns-workshop/pull/277)

---

#### #276 · adoption path: the missing plugin install step (inbound #274) · Fix · 2026-07-30

**The documented adoption path did not install the plugin, and the failure was silent.** Step 0 told
a new consumer to put `extraKnownMarketplaces` + `enabledPlugins` in `.claude/settings.json`, restart,
and invoke `specialists-init`. Measured in a consumer during the v3.0.0 adoption round (July 30, 2026):
those two keys plus a restart produce **no install**. A plugin install is **project-scoped** —
`~/.claude/plugins/installed_plugins.json` keys every record by `projectPath` — so an explicit
`claude plugin install <plugin>@<marketplace>`, run per plugin from the consumer's root, is required
before `claude plugin list` reports either plugin as `enabled`.

Worse than a typo, because of *how* it fails: a consumer that follows the old path lands in a session
where the skill is absent **and** the session-start hooks are absent, and "no hooks because the plugin
is not loaded" prints exactly the same nothing as "no hooks because everything is in order". No signal
distinguishes them, and the documentation is the only thing the reader has — until the plugin loads,
the skill that would say otherwise does not exist.

Corrected in all four places a new consumer can land, each stating the **order** (enable → install
per plugin from the repo root → restart → verify) plus the one-command self-check that turns the
silent failure into a visible one (`claude plugin list` must show every plugin from `enabledPlugins`
as `enabled`), including the caveat that the list can hold several records per repo:

- `specialists/skills/specialists-init/SKILL.md` — step 0 rewritten as three named acts (0a/0b/0c);
  the frontmatter now says "installed and enabled".
- `QUICKSTART.md` — step 1 is now "enable *and* install", and carries the self-check itself.
- the family `README.md` — step 0 of *Adoption: the bootstrap path*, with the finding and why the
  failure mode is self-camouflaging.
- the root `README.md` — the *Consumption* pointer, which summarised the walkthrough without it.

**Found while fixing this, and fixed along:** the QUICKSTART still described "the two Chris
`@`-imports" in a consumer's `CLAUDE.md`. Since the seam landed that is **one** import pointing at
`.claude/specialists/SPECIALISTS.md`, which in turn imports the body and the lens — the same
doc-claims-other-than-behaviour class as the finding itself, in a file this change was already
correcting.

Reported from a consumer via [issue #274](https://github.com/DaveKJohn/davekjohns-workshop/issues/274).

[PR #276](https://github.com/DaveKJohn/davekjohns-workshop/pull/276)

---

## v3.0.0 — 2026-07-30

### Fixes

#### #273 · Four secondary findings from the life-hub round (inbound #271) · Fix · 2026-07-30

The four lower-severity findings from
[#271](https://github.com/DaveKJohn/davekjohns-workshop/issues/271), fixed together because all four sit
in the same install/uninstall path — and **three of them are defects in work shipped earlier the same day**,
which is the argument for a second pair of eyes outside this repo.

**1. The audit missed a Dutch possessive, which is a false negative in a scan built to over-report.**
`Dereks` takes no apostrophe in Dutch, so the trailing `\b` rejected it and a live reference in a
consumer's own tracked prose went unreported — in a scan whose skill documents itself as biased toward
over-reporting *precisely because a miss is the expensive failure*. The name group now accepts an optional
possessive (`Dereks`, `Derek's`, `Alex'`). **Applies to every non-English consumer, so not an edge case.**

Fixing it exposed a second, smaller lie in the same line: the hit was reported from the capture group, so a
match on `Dereks` printed `name 'Derek'` — sending a reader to search for a string that is not on that
line. It now reports the text **as it appears in the file**.

**2. The dry-run audit showed the wrong 40 lines.** The preview is explicitly the inventory a reader says
yes to, and it was filled entirely by the ~20 lens files the same run had just listed under `[remove]`:
every one mentions a specialist, they consumed the whole cap, and the hits that actually matter only became
visible after `-Apply`. Files on the removal list are now **excluded** rather than sorted last — a
reference inside a file that is going away is not a surviving reference, so listing it would be wrong and
not merely noisy. The exclusion is counted and stated, because a silent narrowing is the thing this audit
exists to prevent.

**3. `[keep]` on an occupied `repo-config.ps1` left a broken contract silently.** Keeping it is correct —
these addresses are inhabited in any repo that predates the plugin, since the scaffolds are the files that
were *extracted from* repos like these. But an existing one has no reason to define the plugin's own
contract functions, so `check-roster-sync` then calls `Get-RosterPath` on a file that does not have it and
the consumer gets `[ERROR]` lines at every session start with nothing connecting them to the bootstrap.
The `[keep]` line now names the missing functions — **only the missing ones**, since listing all four at a
repo that already has them is the noise that teaches people to skim.

**4. The per-item `[KEEP]` line claimed authorship the script cannot establish.** It printed *"filled
in"* while the summary block below it correctly hedges with *"not recognised as an unfilled scaffold"* —
the `smartwatchbanden` correction landed in the summary and not in the line above it, so one run asserted
and hedged about the same file. The line now says what the script actually knows.

**All four are asserted**, including the two that could only be caught by looking at real-world shapes: a
Dutch possessive in a consumer's prose, and an occupied scaffold that lacks the contract. The
possessive test also asserts that a line naming **no** specialist is still not a hit — a looser boundary
must not become a boundary that matches everything.

[PR #273](https://github.com/DaveKJohn/davekjohns-workshop/pull/273)

---

#### #272 · The orchestrator note was removed by its first line only (inbound #271) · Fix · 2026-07-30

Reported from `DaveKJohn/life-hub`'s first real adoption round-trip
([#271](https://github.com/DaveKJohn/davekjohns-workshop/issues/271)), two full `init` → `teardown` cycles
with a filesystem inventory after every phase. **Confirmed, and reproduced exactly.**

The note the bootstrap writes above the orchestrator import is **one sentence wrapped over two lines**: a
fixed head and a generated tail naming where the imports point. Both cleanup paths matched the **head
only** — the teardown, and the bootstrap's own `[tidy]` guard, each by re-typing that literal. So every
teardown left the tail behind, and the next bootstrap wrote a fresh two-line note above the orphan.

Reproduced on a fixture with the fix reverted, and it matches the reported table line for line:

| phase | note head | note tail | `CLAUDE.md` lines |
|---|---|---|---|
| after first init | 1 | 1 | 10 |
| after teardown 1 | **0** | **1** | 12 |
| after bootstrap 2 | **1** | **2** | 12 |
| after teardown 2 | **0** | **2** | 14 |

**The invisibility was the worse half, and the report is right that it is the same failure class as the
1 → 2 → 3 accumulation fixed after `smartwatchbanden` — moved one line down into the only line nothing
checked.** Every counter in the documented verification keyed on the head, so it read 1 / 0 / 1 / 0
throughout: exactly the healthy values. **Including the regression test written for the first version of
this bug.** The lesson already recorded above that fix — *"idempotence has to cover everything the script
WRITES, not just the line it happens to look for"* — was true of the note itself, and had to be learned
twice.

**Why it happened, which is the part that generalises.** One literal, mirrored by hand into two scripts.
That is exactly the shape `Get-SeamPaths` exists to prevent — *"the pair that must never drift apart"* —
so the note now lives beside it: `Get-OrchestratorNote` supplies the head and a tail **pattern**, and
`Test-IsOrchestratorNoteLine` is the single matcher both removers use. The tail has to be a regex rather
than a literal because it interpolates a path that differs per consumer and per layout (the seam names the
seam dir; the pre-seam form names the plugin path), and it stays anchored on the distinctive generated
clauses so the existing rule holds unchanged: **a consumer who reworded or translated the note has
authored it, and neither remover touches it.**

**The test now asserts on the tail, as the report asked — and on one thing it did not.** Alongside a
head counter and a tail counter at every step, the round-trip asserts that `CLAUDE.md` has the same
**length** as after the first bootstrap. A counter watching one line of a two-line block certifies half a
file; a length check catches a leftover **under any name**, including the next one nobody has thought of.
That is the assertion that would have caught this bug without knowing it existed. Verified against the
unfixed scripts: 6 assertions fail, and every head assertion still passes.

**Found on the way, and worth its own line:** the plugin's mirror of `check-report-lib.ps1` was stale
after the source edit, and the suite failed with *"Get-OrchestratorNote is not recognized"* — because the
skills dot-source the mirror, not the root copy. `build-shared-scripts.ps1` fixed it. The shared-script
model catching its own drift, twice today, in two different gates.

**On the report's finding 2 — the `$kept` fix being on `main` but not in a release — it is right, and the
answer is a release rather than a code change.** That is already queued as the `3.0.0` milestone, and the
policy question it raises is the sharper half: *a consumer cannot tell "fixed" from "fixed and
released."* Recorded here so the next release note says which version a fix actually lands in, rather than
the adoption docs claiming `v2.16.0+` for something `2.16.0` does not contain.

**The four secondary findings are accepted and not fixed here** — deliberately, so this branch stays the
one thing it is. Each is real: the audit's word boundary misses a Dutch possessive (`Dereks`), the dry-run
audit's 40-line cap is filled by lens files the same run is about to delete, a `[keep]` on an occupied
`repo-config.ps1` leaves `check-roster-sync` calling functions that file does not have without saying so,
and the per-item `[KEEP]` line still claims *"filled in"* where the summary correctly hedges. They are
listed on the issue and will be picked up from there.

[PR #272](https://github.com/DaveKJohn/davekjohns-workshop/pull/272)

---

#### #268 · The bootstrap report printed CLAUDE.md instead of a count · Fix · 2026-07-30

Found by **measuring** rather than reasoning, while checking a blocking report from the first real
adoption attempt (`life-hub`, July 30, 2026). The report itself turned out to be about something else
entirely — see below — but running the measurement it demanded surfaced this:

```
Done: 4 persona-lens(es) created, # life-hub-achtig  Eigen governance.  already present; ...
```

`$kept` is the persona-lens *"already present"* **counter**, declared at the top of `bootstrap.ps1`. The
note-tidy block near the end assigned an **array of `CLAUDE.md` lines** to that same name, so by the time
the summary line ran, PowerShell interpolated the consumer's whole `CLAUDE.md` where a number belonged.
Renamed to `$keptLines`; the counter is left alone.

**Why every suite stayed green, which is the part worth keeping.** That block runs *only* when the
consumer already has a `CLAUDE.md` that does not yet carry the guard import — **exactly the path a real
adoption takes**, and never the path a fixture takes: a fixture with no `CLAUDE.md` gets one written by
the bootstrap and goes down the other branch. So the bug was reachable only where no test looked, and it
corrupted the one number the round-trip protocol tells an operator to write down first.

Third instance of one lesson in this repo — after the `$pid` note in `check-roster-sync` and the
shared-counter collision behind it: **a name reused for a second purpose in the same scope breaks
somewhere else entirely, and a report line is the last place anyone looks.**

**The blocking report itself was a defect in the test, not in the plugin — and the plugin's behaviour
already was what the reporter proposed.** They found both scaffold addresses occupied in `life-hub`:
`scripts/repo-config.ps1` (55 lines) and `scripts/lib/branch-info.ps1` (88 lines, named by that repo's own
`CLAUDE.md` as its single source of truth for the branch taxonomy). Their proposal was to treat scaffolds
like lenses — neither placed nor removed once inhabited. Measured on a fixture built to match:

- **Bootstrap:** `[keep] scripts/repo-config.ps1 already exists -- not overwritten`, both files
  byte-identical afterwards.
- **Teardown `-Apply`:** `[KEEP] ... filled in; it describes this repo's branch taxonomy, which outlives
  the plugin` — both kept, both byte-identical, while the 25 items the plugin *did* write are removed and
  the audit reports `[FREE]`.

So the round trip on an occupied consumer was already correct in both directions. What was wrong were the
**expectations in the test prompt**, which read "both scaffolds present" as a success criterion after the
bootstrap and "both scaffolds gone" after the teardown — true only for a repo that never had them. Stopping
before installing was the right call, and the second half of their note ("a fixture cannot measure this by
definition") is exactly right.

**Both halves are now pinned by tests** — an *occupied consumer* scenario in `teardown.tests.ps1`: the
bootstrap keeps and reports, the teardown keeps and reports, both files byte-identical across the full
round trip, and the report line asserted to carry digits. Verified against the unfixed script: **the two
report assertions fail and the thirteen behavioural ones pass either way**, which is the proof that the
behaviour was always right and only the report was broken.

**And the protocol that misled the prompt is corrected at the source.** The round-trip section of
[`specialists-teardown`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/specialists/skills/specialists-teardown/SKILL.md#verifying-a-round-trip--and-why-git-status-is-not-enough)
now states that the two `Test-Path` lines are an **inventory, not an expectation**, with a table for the
occupied case and the instruction to read `[create]`/`[keep]` and `[remove]`/`[KEEP]` rather than the
booleans. The general form: **the plugin scaffolds precisely the files that were extracted from repos like
these** — free real estate on a fixture, inhabited in any real consumer.

**One correction to the report, for the record.** It concluded that the prompt's ~20 mid-word truncations
were *"in the source file, not in the transfer."* The source file is intact: line 64 reads
`Where-Object { $_ -match '^\s*@' }`, not the reported `Where-Obount`, and no scratchpad file contains a
single broken token. So the damage is in the channel — the same failure
[#260](https://github.com/DaveKJohn/davekjohns-workshop/pull/260) recorded on July 29, now on a different
route. Worth stating plainly because the two diagnoses lead somewhere different: a corrupt source is fixed
by rewriting it, a corrupt channel is not. The prompt's own truncation guard did its job — the session saw
the damage, stopped at step 2, and said so instead of guessing.

[PR #268](https://github.com/DaveKJohn/davekjohns-workshop/pull/268)

### Documentation

#### #266 · A seam migration can move a consumer's lenses out of git · Docs · 2026-07-30

Found while running the teardown skill's own pre-flight instruction — *"establish whether `.claude/` is
tracked **before** running with `-Apply`"* — ahead of the first real adoption test round. The instruction
existed because `git status` proved partly blind in `davekokbwj/smartwatchbanden` on July 29. Following it
turned up something that is **not** about the repo being tested.

**Measured across both real consumers, July 30, 2026:**

| repo | `.gitignore` | consequence |
|---|---|---|
| `DaveKJohn/life-hub` | no `.claude` entry at all | the whole tree is tracked — a wrongly removed lens is one `git checkout` away |
| `davekokbwj/smartwatchbanden` | `.claude/*` with `!.claude/plugins/` | tracked **only** on the pre-seam path |

That second row is correct today and **breaks silently on migration.** The exception un-ignores
`.claude/plugins/` — the *pre-seam* location. Move the lenses to `.claude/specialists/` and they match
`.claude/*` with no exception covering them, so the tree leaves version control **without a single line of
the migration looking wrong**: every gate stays green (the readers accept the seam — that is the whole
point of [#253](https://github.com/DaveKJohn/davekjohns-workshop/pull/253)), `git status` shows nothing
because they are ignored, and the teardown's undo is gone. A repo would discover it at the moment it most
needed that undo.

**So the migration is now five steps, and the new one is step 0:** add `!.claude/specialists/` and commit
it *before* moving anything. Reversed, the move lands untracked and the commit that would have captured it
has nothing to capture.

**The general form, which is the part worth keeping:** *an ignore rule written against a path is a bet that
the path will not move.* A migration is exactly when that bet is called in — and no gate in this family can
see a consumer's `.gitignore`, which is why this belongs in the operator's pre-flight rather than in a
check.

**One clearance for the upcoming test round, since that is the question the pre-flight was run for:**
`life-hub` tracks `.claude/` in full, so its round-trip has a working undo and `-Apply` is safe there. It is
`smartwatchbanden` that needs the `.gitignore` step first — and only if and when it migrates, since an
update alone leaves it on the pre-seam path, where it is tracked.

[PR #266](https://github.com/DaveKJohn/davekjohns-workshop/pull/266)

---

## v2.16.0 — 2026-07-30

### Features

#### #264 · The teardown proves standing free instead of claiming it · Feat · 2026-07-30

The last open item of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221)'s target shape,
and the one that could not be done as written.

**The item was "reword category 3 plugin-neutrally, so it stays true after an uninstall"** — turning
*"Derek opens the PR"* back into *"changes go in via a branch and a PR"*, a rule that survives the plugin
because it never needed the character. **A script must not do that.** It is the repo owner's governance
prose, and a plugin rewriting an owner's `CLAUDE.md` on its way out is precisely the damage the
three-category classification exists to prevent. Delivering the item literally would have meant building
the thing the design forbids.

**So the deliverable is the half a script legitimately can do: find them.** The teardown now closes with a
**free-standing audit** that answers the question the requirement actually poses — *after this, does the
repo stand free?* — instead of the question every other section answers, which is *what did the bootstrap
put here*.

```
-- free-standing audit: LIVE references left after this teardown --
   scanned 24 file(s) under CLAUDE.md, .claude/ and scripts/ against 19 known specialist name(s)
  [LIVE]   CLAUDE.md:3 -- name 'Derek'
  [LIVE]   CLAUDE.md:6 -- specialist id + name 'Derek'
  [LIVE]   scripts\repo-config.ps1:3 -- plugin-only contract function
```

Three kinds of hit, because they have three different answers — and the choice is **per line, not per
file**, which is why it reports lines:

| hit | answer |
|---|---|
| a **specialist id** (`05-05`) — a roster row, a routing table | usually **delete**: it only ever existed for the plugin |
| a **name** (`Derek`) — a valid rule phrased through a character | usually **reword**: keep the rule, drop the name |
| a **plugin-only contract function** (`Get-RosterPath`, `Get-RosterIgnoredIds`) | **delete the line**, keep the file |

That third one is new information rather than a restatement: `repo-config.ps1` is category 3 and is
correctly *kept* — but two of its eight contract functions exist only to serve the roster check, and "keep
this file" and "keep every line in this file" are different answers. Nothing said so before.

**Report-only, unconditional, and it runs on a dry run too.** It removes nothing, so it needs no `-Apply`,
and a preview that cannot tell you what would still be left is not the inventory a reader needs in order
to say yes. A clean repo gets `[FREE]`, which is the requirement met *verified rather than assumed*.

**The closed loop is the assertion that makes it more than a grep.** A test applies the exact reword the
audit advises and asserts the audit then reaches `[FREE]`. Without that, an audit could name references
that no reasonable edit ever clears — findings that are technically true and practically noise.

**Three boundaries, each of which would otherwise be a quiet false claim:**

- **The names come from the plugin's own payload** (an agent def's `name:`, a persona's H1), never a
  hardcoded list that rots on the next rename. But this skill ships inside **one** plugin and sees only
  that plugin's specialists — a consumer running a domain plugin has names it does not know. The **id scan
  is the general net** (a `<gg>-<ii>` token is name-independent, so it catches a specialist from any
  plugin) and the name scan is the extra pass. Stated in the skill rather than left for someone to discover.
- **Matching is case-insensitive, deliberately biased toward over-reporting.** For an audit whose purpose
  is establishing that nothing was missed, the expensive failure is the reference it did not find — not the
  one a reader dismisses in five seconds. Every hit carries `file:line`, so a false positive is cheap and a
  false negative is silent. Same direction `Test-LooksGenerated` resolves its doubt, for the same reason.
- **History is out of scope and never rewritten.** `CHANGELOG.md` and `releases/` are excluded entirely;
  other root prose is **counted, not listed** — a pointer, not a work queue, since nothing loads, resolves
  or gates on it.

**A bug in the audit's own pattern, found by running it rather than by reading it.** The first version
anchored the plugin-only-function check as `\b(Get-RosterPath|...|\$script:RosterPath|...)`. A shared
leading `\b` in front of `\$` demands a word character immediately before the dollar, so it can never match
an assignment at the start of a line — which is exactly where `$script:RosterPath = 'CLAUDE.md'` lives. The
fixture caught it immediately: line 4 (`function Get-RosterPath`) was reported, line 3 was not. Each
alternative now carries its own anchor, and the regression is asserted. **A pattern that matches some of
what it claims is worse than one that matches none — the partial hit reads as coverage.**

[PR #264](https://github.com/DaveKJohn/davekjohns-workshop/pull/264)

---

#### #263 · A gate states its coverage, not just its verdict · Feat · 2026-07-30

The last open item of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221)'s target
shape: *"consumer gates that announce when they stop applying."*

**The defect was sharper than the issue described, and the difference matters.** The family README said
the gate *silently skips* the lens category once the directory is gone. It does not skip quietly and
print nothing — it prints a **verdict with no coverage**. `check-consumer-drift`'s persona section closed
with:

```
-- Personas (portable body vs. the <g>-<id>-extension.md copy in the consumer) --
  Persona drift is INFORMATIONAL (does not affect the exit code): 0 drifted.
```

Measured today against a directory holding a `CLAUDE.md` and nothing else: that was the section's
*entire* output. Four personas exist in the source; zero were compared; the reader was told "0 drifted".
**"0 drifted of 0 compared" and "0 drifted of 4 compared" were the same sentence.** That is not a false
pass — it is a true statement that reads as a different, false one, which is harder to catch than
silence, because there is nothing missing to notice.

Worse, the asymmetry was visible in the same output the whole time: the agent-def section right above it
*does* state its coverage (*"26 missing, 0 identical, 0 drifted"*). One half of the report had the
denominator and the other half did not.

**The fix.** One shared, non-counting `Write-Coverage` in
[`scripts/lib/check-report-lib.ps1`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/scripts/lib/check-report-lib.ps1) — plugin-owned, so it travels to
every consumer with the payload — emitting `[<category>] checked N of M -- <why, when empty>`:

- **`check-consumer-drift`** — the persona section is now printed **unconditionally** (it used to be
  wrapped in `if ($personaResults.Count -gt 0)`, so it could vanish entirely), and its verdict carries
  its denominator: *"0 drifted of 0 compared"*, plus a line naming why nothing was compared. A reader
  can now tell a deliberate teardown from a bad merge or a wrong `-ConsumerPath`.
- **`check-plugin-integrity`** — a `[COVERAGE]` line closes **all ten** categories, with
  `link-scan/lenses` counted separately from the scan total precisely because it is the category a
  teardown removes.

**Applied to all ten on purpose.** A partial rollout recreates the exact asymmetry that caused this: the
agent-def section was honest and the persona section was not, and that is why nobody noticed for months.
Uniformity is the fix, not thoroughness for its own sake.

**Coverage is context, never a finding.** `[COVERAGE]` is non-counting like `[OK]`/`[SKIP]`/`[SCOPE]`: it
moves no exit code and no signal count, and a unit test asserts exactly that — a legitimately empty
category must not break its own gate, or the honesty would cost more than the silence did.

**Two things the work produced beyond the feature:**

- **The gate caught its own change.** Editing `check-report-lib.ps1` made the plugin mirror drift, and
  check 8 reported it on the first run. The shared-script model working as designed, worth stating
  because it is the kind of thing that only ever gets noticed when it fails.
- **The integrity fixture was already the perfect witness, and its own docstring said so.** That fixture
  carries no agent def, no manual, no persona and no plugin manifest — it recorded those categories as
  *"expected noise, asserted on nowhere below"*. They are asserted on now: six categories that report
  `checked 0`, two that report a real count (so the line cannot be hardcoded), and the empty lens
  category's stated reason. As a side effect three redundant recursive directory walks collapsed into
  the sets already collected.

**What this deliberately does not fix, said out loud instead of quietly scoped away.** A consumer's own
lint — whatever `Get-LintScript` points at — is the repo owner's code. The measured silent skip lives
there, and no plugin can make someone else's gate honest. The helper is available to it; adopting it is
the owner's act. Recorded in the family README as the owner's item rather than counted as closed here.

[PR #263](https://github.com/DaveKJohn/davekjohns-workshop/pull/263)

### Fixes

#### #262 · sync-roster wrote its scaffolds to the pre-seam path · Fix · 2026-07-30

The seam ([#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221)) made
`.claude/specialists/lenses/` the place a consumer's lenses live, and taught the bootstrap to resolve
that destination through `Get-LensWriteDir` — the seam for a fresh or migrated consumer, the existing
tree for one that has not migrated. **`sync-roster` never got the same treatment.** It hardcoded
`.claude/plugins/<family>/<plugin>/<group>-<id>-extension.md` in three places: the scaffold it writes,
the link in the roster row it proposes, and the path it prints for a stale header.

**What that costs a real consumer.** Run `sync-roster` after a plugin update — which is exactly what the
session hook tells you to do when the roster drifts — and a migrated repo gets its new scaffolds in the
pre-seam directory while the rest of its lenses sit in the seam. `Get-LensWriteDir`'s own docstring names
that outcome: *"splitting the surface in two, which is worse than either layout alone."* On top of that
`check-roster-sync` then reports the fresh scaffolds as off-path, and the proposed roster row a human
pastes links to a file that is not there — worse than no row, because it looks authoritative.

Both writers now resolve through the one helper, so they cannot disagree about a repo's layout.

**Why the suite stayed green through all of it, which is the more useful half of this entry.** Every one
of the six existing scenarios built its fixture consumer with a **pre-seam lens tree** — and
`Get-LensWriteDir` follows an existing tree by design. So the suite exercised the one branch where the
hardcoded literal happened to be correct, 39 asserts deep, and never the fresh or migrated cases. **A
fixture that always arrives in the same state tests one branch, however many asserts hang off it.** The
suite now builds three: fresh (no tree), migrated (lenses in the seam), and pre-seam (lenses on the old
path), plus a fourth check that the proposed roster row's link follows too. Verified by running the new
asserts against the unfixed script: **7 fail, and the pre-seam case passes both ways** — which is the
proof that the test targets the defect rather than the implementation.

`Get-LensFamily` is no longer called anywhere in this script: with the seam there is no family segment
left for it to compose.

**On the unparseable-plugin case.** The stale-header branch used to print `<plugin>` as a placeholder
segment. In the seam there is no plugin segment to placeholder, so an unknown plugin now resolves to the
seam — and deliberately does *not* pass the placeholder on to `Get-LensWriteDir`, whose candidate list
documents that the caller slug-validates any name that becomes a path segment (a `<plugin>` literal would
break that contract, and `Test-Path` on the illegal characters with it). Everywhere the id *did* parse it
is passed through, still slug-validated by `Split-PluginId`.

The `SKILL.md` line describing where scaffolds land was deliberately held back from
[#261](https://github.com/DaveKJohn/davekjohns-workshop/pull/261)'s prose sweep and lands here instead:
the doc follows the behaviour, never the other way round.

[PR #262](https://github.com/DaveKJohn/davekjohns-workshop/pull/262)

### Documentation

#### #261 · The seam migration left stale lens paths in the prose · Docs · 2026-07-30

The seam shipped its **machinery** in v2.15.0 ([#253](https://github.com/DaveKJohn/davekjohns-workshop/pull/253)
specified it, [#254](https://github.com/DaveKJohn/davekjohns-workshop/pull/254) taught the bootstrap
and the teardown to write and remove it, [#255](https://github.com/DaveKJohn/davekjohns-workshop/pull/255)
migrated this repo onto it). Its **prose** did not come along. Measured today: **120 occurrences of the
pre-seam lens path across 57 files**, in all four plugins — every agent def, every manual, `QUICKSTART.md`,
the family README, the connectors README, and the shared `agent-shared/inbound-behaviour.md` block that
is filled verbatim into 19 agent defs.

That is not cosmetic. Those texts are the instruction a specialist reads *while working in a consuming
repo*: "repo-specific additions belong in the repo lens
(`.claude/plugins/claude-specialists/<plugin>/<group>-<id>-extension.md`)". A specialist who follows it
writes a file the seam does not hold and `check-roster-sync` reports as off-path.

**Why no gate caught it.** Two independent reasons, and both are worth keeping:

1. **The paths appear in prose and in code spans, not as links.** The dead-link scan resolves link
   *targets*; it never reads a label or a backticked path. So a document may describe a layout that no
   longer exists and stay green.
2. **In this repo's own `.claude/specialists/`, the labels were wrong while the targets were right.**
   `README.md` was still titled `# .claude/plugins/claude-specialists`, its layout section still
   described `plugins/claude-specialists/specialists/`, and its whole index table used
   `specialists/<id>-extension.md` labels over `lenses/<id>-extension.md` targets. Every link resolved.
   Exactly the class [#260](https://github.com/DaveKJohn/davekjohns-workshop/pull/260) named a day
   earlier: the description and the thing described drift apart, and nothing announces it.

**History is left alone.** The per-plugin `CHANGELOG.md` files and the archived release notes keep the
pre-seam path — they record what was true then, and this repo does not rewrite history (the same
reasoning that lets those notes keep their original language). Two analytical mentions are also kept
deliberately, because the old path is their *subject* rather than their instruction: the teardown-gap
bullet in the family README (now marked settled) and the #227 lesson in
[Sylvester's lens](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/.claude/specialists/lenses/05-15-extension.md), where the citation now says which
path the bootstrap wrote at the time.

**Two things found while chasing the prose, both bigger than a path:**

- **`sync-roster` still writes to the pre-seam path** — a real defect, not a wording slip, and split off
  to its own `fix/` branch rather than buried here. Its `SKILL.md` line is therefore the one stale path
  left in this diff: the doc follows the behaviour, not the other way round.
- **`specialists-init`'s SKILL.md still carried the claim [#215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215)
  disproved** — *"what a plugin cannot do is inject always-on main-loop context"*. The family README has
  carried the correction since July 29; the skill a consumer actually reads did not. Corrected with a
  pointer to both, and stating that the switch is deliberately off — the wording was wrong regardless of
  whether Dave ever flips it.

Also reworded: "on the plugin path" as a *description of the seam*, in `QUICKSTART.md` (3),
`specialists-init/SKILL.md` (3) and the connectors README (1). The seam is not the plugin path — that
was the point of moving it, so calling it that undoes the sentence.

**One regression the sweep would have introduced, caught on the copy-edit pass.** Every agent def and
manual tells its specialist where the repo lens lives, with a fallback: *"or the legacy path
`.claude/extensions/…`"*. Before the sweep that sentence named the **pre-seam plugin path** as the
primary and the pre-plugin-path one as the fallback; a naive replacement left it naming the seam and the
oldest path while dropping the middle one — which is exactly where the two un-migrated consumers
(`life-hub`, `smartwatchbanden`) keep their lenses today. A specialist reading only the new sentence
would look in two places and miss the one holding the file. `Get-LensDirCandidates` reads all three
regardless, so no check would have failed. The parenthetical now names both fallbacks in one shape across
all 27 files: *"or, if this repo has not migrated to the seam, at its pre-seam
`.claude/plugins/<family>/<plugin>/` or `.claude/extensions/` location"*. **A mechanical replacement
inherits the old sentence's assumptions — read what the sentence claimed, not just the token you
changed.**

**Found and deliberately left alone:** `check-consumer-drift` reports `03-02-extension.md` (Bianca) as
`[DRIFTED]` — her lens carries a body copy instead of following the lens-only model. Informational, it
does not affect the exit code, and it predates this branch: she was adopted onto the roster on July 28,
2026. Recorded here so it is on the record rather than in a session.

[PR #261](https://github.com/DaveKJohn/davekjohns-workshop/pull/261)

---

## v2.15.1 — 2026-07-29

### Fixes

#### #257 · check-roster-sync calls the seam canonical · Fix · 2026-07-29

`check-roster-sync.ps1` still carried the **pre-seam path hardcoded in two places**, while the shared
source it is supposed to agree with — `Get-LensDirCandidates` / `Get-SeamPaths` in
[`check-report-lib.ps1`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/scripts/lib/check-report-lib.ps1) — had named the seam
`.claude/specialists/lenses/` canonical since [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221).
Reader and writers had drifted apart, and this repo tripped over it the moment it migrated onto the
seam itself in [#255](https://github.com/DaveKJohn/davekjohns-workshop/pull/255).

**1. Its own lenses were reported as living off-path.** `Get-CanonicalLensDir` returned only
`.claude/plugins/<family>/<plugin>/`, so all 19 seam lenses produced one `[INFO]` telling the reader to
move them — back to the layout the repo had just left. A reader who followed that advice would undo the
migration. Replaced by `Get-OnPathLensDirs`, which derives **both** currently-written locations from the
shared source: the seam (candidate 0) and the pre-seam plugin path (candidate 1, still written by
`Get-LensWriteDir` for a consumer that already has a tree there). Neither is a misalignment now, and the
finding keeps meaning exactly what #179 built it for: the marketplace-named family that only the
reader's back-compat list keeps working.

**2. A seam consumer could be declared "never bootstrapped".** The `$anyLensFile` probe behind the
`[BOOTSTRAP]` marker scanned `.claude/plugins` and `.claude/extensions` — not the seam. So for any
consumer bootstrapped since #221 the probe saw no lenses at all, and a single unfilled roster was enough
to swallow every real finding behind advice to run `specialists-init` on a repo whose whole lens tree
was already in place. The seam directory joined the scan.

Worth noting how invisible this was: the false finding was an **`[INFO]`**, which the session hook
suppresses by design — so nothing reported it, and the check's exit code stayed 0. It surfaced only
because someone ran the script deliberately and read the one line the hook filters away. The same shape
as the `[INVENTORY]` case: a rule nobody was ever prompted about.

Both are covered by regression tests in
[`scripts/tests/roster-sync.tests.ps1`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/scripts/tests/roster-sync.tests.ps1) (scenario 9c: the seam is
canonical and a migrated repo reports *completely* clean — asserting "no `[ERROR]`" would have missed
this entirely; 9d: the pre-seam path stays tolerated **silently**, so the fix cannot be "corrected" by
swapping one hardcoded path for another; plus the seam case in 5d for `[BOOTSTRAP]`). Verified the
honest way: all five new assertions fail against the unfixed script and pass against the fixed one.

[PR #257](https://github.com/DaveKJohn/davekjohns-workshop/pull/257)

---

## v2.15.0 — 2026-07-29

### Features

#### #254 · The seam: the bootstrap writes it and the teardown removes it · Feat · 2026-07-29

The writer half of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221), after the
readable half landed in #253. A **fresh** consumer now gets one directory and one line, and a teardown
takes both away.

**What the bootstrap writes for a fresh consumer.** Lenses flat in `.claude/specialists/lenses/` (no
per-plugin segment — `<group>-<id>` is unique family-wide, so several enabled plugins share one
directory, which is what makes "remove one directory" true for a multi-plugin consumer too),
`.claude/specialists/SPECIALISTS.md` carrying the body import, a lens import relative to itself, and a
`## The roster (VUL-IN)` slot, plus exactly **one** `@`-import in `CLAUDE.md`. One detail is load-bearing:
the inclusion's **title carries no marker, only the roster slot does.** Filling in the roster therefore
removes the marker, so the teardown reads the file as authored — a `(VUL-IN)` title would have survived a
filled-in roster and made the teardown delete somebody's work.

**An already-adopted consumer is untouched** and keeps both its lens tree and its two imports.
`Get-LensWriteDir` makes that call, so nothing is relocated and the surface never splits across two
paths. Once the owner migrates by hand, the writer follows automatically.

**What the teardown does.** It reads the seam's literals from `Get-SeamPaths` rather than retyping them —
the bootstrap writes them and the teardown matches them, and a drift between the two would leave a
dangling import that nothing errors on. `SPECIALISTS.md` is classified exactly like a lens: unfilled slot
heading → removed; authored → kept, with the import **still** removed, because that line is what makes
the content live. The report then says outright that nothing loads the file any more. So the orphan does
not disappear, it *shrinks*: one named file holding the roster in one piece, instead of 43 lines scattered
through six sections. That trade is the seam's actual payoff, and the report names it.

**Measured end to end** before the suites were touched: a fresh fixture bootstraps to 19 lenses in the
seam and a single import, and a teardown leaves 27 items removed, 0 kept, and nothing but the owner's own
two files.

**The suites.** The estimate was ~30 assertions across five suites; the reality was two suites.
`connectors`, `sync-roster`, `roster-sync` and `release-lib` pass **unchanged** because they build
fixtures on the pre-seam path, which readers still accept — the back-compat promise, verified by accident.
`bootstrap-drift` (87 asserts) and `teardown` (101) were updated, and the new coverage pins what B2 adds:
CLAUDE.md carries exactly one import **as a count**, nothing lands on the pre-seam path for a fresh
consumer, the body import now lives in `SPECIALISTS.md` (so the durable-body-path assertion reads the right
file instead of passing vacuously), the whole `.claude/specialists` directory is gone after `-Apply`, and an
authored inclusion is kept while its import is removed.

Two boundaries stated rather than quietly crossed. The **57 agent defs and manuals** that name the
pre-seam lens path are left alone: both layouts are read and every existing consumer's lenses really are
still there, so those texts are accurate, not stale — sweeping them is a documentation pass for after the
consumers migrate. And this repo has **not** migrated itself yet; that is the next step, by hand, and it
only becomes visible in a later session because the plugin loads from the pushed `github` source.

[PR #254](https://github.com/DaveKJohn/davekjohns-workshop/pull/254)

---

#### #253 · The seam, specified and readable · Feat · 2026-07-29

The first half of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221)'s remaining work:
the seam is **specified** in the family README and **readable** by every reader, with no behaviour change
for any existing consumer. What is deliberately not in this change is the writer flip — see the end.

**The shape.** A fresh consumer's whole specialist surface becomes one directory and one line:
`.claude/specialists/SPECIALISTS.md` (the inclusion: body import, lens import, roster slot) plus
`.claude/specialists/lenses/<group>-<id>-extension.md`, flat because `<group>-<id>` is unique
family-wide. `CLAUDE.md` carries `@.claude/specialists/SPECIALISTS.md` and nothing else, so a teardown
becomes *remove one directory and one line* instead of hand-cutting a roster woven through 6 sections.

**Four facts were verified from the reference before any of this was designed, and each could have sunk
it.** Nested imports work (*"a maximum depth of four hops"* — the seam spends two). A path in backticks
is not an import, so the docs can name the seam line safely. A project-root `CLAUDE.md` is re-read after
`/compact`, so the roster comes back with it. And it is **not a token saving**: *"imported files still
load and enter the context window at launch"* — the seam buys removability, nothing else, and claiming
otherwise would be the kind of unearned win this repo keeps catching elsewhere.

**One fragility the seam concentrates rather than removes,** now written down: the body import resolves
into the marketplace cache, outside the working directory, and such an import is gated by a one-time
approval dialog whose refusal is sticky — *"If you decline, the imports stay disabled and the dialog
doesn't appear again."* With one line instead of two, a single decline delivers nothing at all, silently.
Worth knowing before diagnosing that as a bug in this repo.

**The mechanism, in one place.** `check-report-lib.ps1` gains `Get-SeamPaths` (the literals the bootstrap
will write and the teardown must match — one source, because a drift between those two leaves a dangling
import that nothing errors on) and `Get-LensWriteDir`. `Get-LensDirCandidates` gains the seam as its most
canonical candidate ahead of the three it already walked, so **a consumer who migrates by hand works
immediately** — the roster check, the drift lint and the teardown all find lenses there today. The
mirrored plugin copy is back in step.

`Get-LensWriteDir` encodes the promise that keeps this safe: a fresh consumer gets the seam, a consumer
that already has lenses keeps writing where they are. The bootstrap never relocates a tree the repo owner
owns, because seam lenses written beside a legacy tree would split the surface in two — worse than either
layout alone, with the teardown then reasoning about both at once.

A new suite covers all of it (`check-report-lib.tests.ps1`, 12 asserts) — these shared helpers previously
had no direct test at all, only indirect coverage from suites that happen to call them. The pinned
properties: the seam is candidate 0, the legacy locations still resolve and `extensions/` stays last, the
import line never picks up a backslash from `Join-Path`, an *empty* legacy directory does not count as
adopted, and after a hand migration the writer follows to the seam without being told.

**Deliberately still to come, and why the split.** Flipping the bootstrap to write the seam by default
(and teaching the teardown its one-line/one-directory form) changes 30 assertions across five suites that
encode the current layout. Landing the readable half first means the seam can be proved on a real repo —
this one, by hand — before the default moves under every consumer at once.

[PR #253](https://github.com/DaveKJohn/davekjohns-workshop/pull/253)

---

#### #252 · Chris's body can serve as a main-thread system prompt · Feat · 2026-07-29

The blocker on [#215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215) is removed. Chris's
portable body said he *"never executes anything himself — he writes no content, opens no PR, does not
merge"*. As a role inside a general-purpose loop that works; as **the main thread's own system prompt**
it is crippling, because the main thread would refuse to edit files. No configuration change could fix
that, which is why the issue sat blocked.

**The rule was reframed, not weakened: it now forbids unattributed work rather than typing.** Every
executing action still belongs to the specialist who owns it, is announced before it happens, and is
performed under that specialist's craft rules — by handing off to a subagent where subagents exist, and
otherwise by Chris doing that specialist's work *under their name*. What is forbidden is work with no
specialist behind it, work done by Chris's general judgment where a craft has rules, and a handover
claimed but not made. Read it as *"nothing happens anonymously"*.

Two things this surfaced. The old wording was **internally inconsistent** — ritual step 5 has always
read *"execute according to their trade rules"*, so the body both forbade and prescribed the same act.
And in a harness without subagents the old rule was already fiction: the work got done anyway, just
without the wording admitting it. The reframing describes what actually happens and keeps the property
that matters, which is attribution.

**The mechanism was verified from the docs rather than assumed**, and recorded in the
[family README](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/README.md#adoption-the-bootstrap-path): a plugin
root `settings.json` supports `agent` (and `subagentStatusLine`) and *"activates one of the plugin's
custom agents as the main thread, applying its system prompt, tool restrictions, and model"*. The
issue's compaction worry dissolves in this route: only **skill** descriptions are flagged as not
re-injected after `/compact`, and a main-thread agent's body *is* the system prompt, which travels with
every request anyway.

**The switch stays off, deliberately.** What happens when two enabled plugins both set `agent` is
documented nowhere — not on the plugins page, not in the reference — and that is a poor thing to
discover through your main thread. It would also change every consumer's main loop from a version bump
they did not read, and since Chris ships as a persona there is no agent-def to point at: creating one
means its `tools:` and `model` become the whole main thread's policy. Ready, not thrown; settling the
multi-plugin question needs an experiment, not another read.

[PR #252](https://github.com/DaveKJohn/davekjohns-workshop/pull/252)

---

## v2.14.1 — 2026-07-29

### Fixes

#### #251 · Close three measurement gaps: entry scan, machine records, proposal path · Fix · 2026-07-29

Three open issues closed in one pass, each the same species: a check that could not see what it claimed
to cover.

**The lint gate could not see an entry file until it was too late (#234).** `$linkFiles` — the set that
feeds both check 4's link scan and check 10's skill spans — listed every permanent doc but not the root
changelog **entry** files. An entry's text was therefore invisible while the PR was open and became
visible only at **fold** time: directly on `main`, in one of the two sanctioned direct-on-`main` actions,
past every PR gate. The error then surfaced at the next full gate run, `cut-release.ps1`, which is how
v2.13.0 came to be blocked by a changelog sentence. Root entry files are now in the set, keyed on the
entry format's `###` heading (the same structural signature `fold-changelog-entry.ps1` uses), so a
permanent root doc with its `#` heading never joins. No check was wrong here — the *timing* was: the
verdict had been "green so far", not "green".

**`check-connectors` picked one of several machine records and called it a fact (#240).** It took the
first record whose `projectPath` resolved to the checkout and stopped, so the `[OK]`/`[ERROR]` the
session hook prints at every start rested on JSON ordering. Measured: one repo registered at three
versions at once, because `~/.claude.json` held several project records for it in two path spellings. It
now collects every match. Records that agree are reported as before — two spellings of one directory are
not two answers, so the comparison is case-insensitive and ignores a trailing separator. Records that
disagree produce an `[ERROR]` naming every version found and **withholding** the source comparison,
because while they disagree no version claim about that consumer can be trusted. An honest "cannot
determine" beats a confident wrong number, and unlike it, it is actionable.

**The settings proposal could not be seen by git at all (#241).** `specialists-init` announced
`.claude/settings.suggested.jsonc` by relative name, while many consumers gitignore `.claude/*` — so the
file never appears in `git status`, `git checkout .` does not clean it up, and an operator verifying a
round-trip with git alone cannot tell it exists. It cannot announce itself through git, so it now
announces itself by **full path**, in the one output guaranteed to be read. The two items that issue
asked for beyond this were already shipped in `specialists-teardown`'s SKILL.md: that git is not a
complete check, and the filesystem-inventory protocol that replaces it.

Tests for all three, 20 new asserts: an entry file with both a dead link and a quoted marker is reported
while the PR is open (an H1 root doc still is not, proving the set stayed scope-limited, and a folded-away
entry drops out again without complaint); three disagreeing records are reported as a disagreement while
two spellings of one path are not; and the proposal's full path appears in the bootstrap's output.

The lesson behind the first one is recorded in
[Sylvester's lens](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/.claude/plugins/claude-specialists/specialists/05-15-extension.md): when a gate checks
file A and some other step copies text into A, it must also check where that text was authored.

[PR #251](https://github.com/DaveKJohn/davekjohns-workshop/pull/251)

---

## v2.14.0 — 2026-07-29

### Features

#### #250 · Teardown can hand back working copies of the shared scripts · Feat · 2026-07-29

The runtime dependency that no teardown could fix now has a built-in way out. `teardown.ps1 -Apply
-VendorScripts` copies the plugin's shared script payload (`scripts/task`, `scripts/release`,
`scripts/lib`, `scripts/sync`) into the consumer's own `scripts/`, structure preserved, so the daily git
workflow keeps running once the plugin is uninstalled — instead of the resolver throwing and taking
`start-task`, `open-pr` and `fold-changelog-entry` down with it.

**Why it works, and why that was not obvious until it was checked.** The shared scripts were built to
travel as a payload: they locate the repo through `CLAUDE_PROJECT_DIR` / `git rev-parse --show-toplevel`
— never their own location — and dot-source their siblings `$PSScriptRoot`-relative. A copy therefore
behaves identically anywhere inside the repo, provided the *structure* comes along; a flattened copy would
break at the next branch rather than at copy time. This repo is the standing proof, and it settled the
design choice: its five `scripts/` copies are **byte-identical** to the plugin's, so the workshop has been
running the vendored model all along. That is why vendoring won over the alternative of making the
resolver degrade gracefully — one option ends with a repo that works, the other with a repo that fails
clearly.

**It is the one additive act in a subtractive script**, hence opt-in, and it never overwrites. A
destination that exists and differs is reported and left alone — typically the consumer's own wrapper
around the shared script, so the rule that protects a filled-in lens protects it too; an identical
destination is reported as already current, making re-runs safe. The report also states the one
combination that hands back scripts with nothing to dot-source: if the same run removed
`repo-config.ps1`/`branch-info.ps1` because they were still unfilled scaffolds, the vendored scripts
cannot run — and a repo in that state had no working workflow to preserve in the first place.

Twelve new asserts (89 total in `teardown.tests.ps1`) cover the properties rather than the happy path:
the dry run writes nothing, the payload arrives byte-identical to the plugin's, the sibling lib comes
along, a differing destination is provably **not** overwritten, the collision is reported rather than
silent, a second run recognises its own work, and without the switch nothing is written at all.

[PR #250](https://github.com/DaveKJohn/davekjohns-workshop/pull/250)

---

#### #249 · Teardown warns when a consumer script resolves the plugin cache · Feat · 2026-07-29

The teardown documented a leftover it could not act on: the consumer's own resolver locates the
marketplace cache and throws once the plugin is gone, and in the measured repo
(`davekokbwj/smartwatchbanden`, July 29, 2026) three operational scripts dot-sourced it — so an
uninstall took the daily git workflow down rather than leaving debris behind. Documenting that was
right, but it left the dry run silent about the only leftover that breaks a run: the report answered
*"what did the bootstrap put here"* while a reader's actual question before trusting the word
*reversible* is *"what stops working after I uninstall"*.

`teardown.ps1` now answers the second question too. Every `.ps1` under `scripts/` that references the
marketplace cache or `CLAUDE_PLUGIN_ROOT` is reported as a `[WARN]` line together with the scripts that
depend on it, plus a note naming the two ways out (keep local copies of the operational scripts, or make
the resolver degrade to one clear failure instead of a throw) and stating plainly that no teardown can
fix this, because the shared-script model (#81) is what creates the dependency.

**It is report-only by construction, and that is the property under test.** These files are the
consumer's own code; a check that deleted them to make its own summary look clean would do exactly the
damage the classification exists to prevent. So the suite asserts both halves — the report *names* the
resolver and its dependents, and `-Apply` still leaves both files on disk — plus exit code 0 (a warning
is not a failure) and no false alarm on a consumer whose scripts never reach into the plugin. Eight new
asserts, 77 total in `teardown.tests.ps1`.

Two limits stated rather than hidden: the scan covers `scripts/` only, so a resolver living elsewhere is
not counted, and dependents are matched by filename rather than by parsing dot-source syntax — a
consumer may reach the resolver via `$PSScriptRoot`, a variable, or `Join-Path`, and this report only has
to point a human at the right file.

[PR #249](https://github.com/DaveKJohn/davekjohns-workshop/pull/249)

### Documentation

#### #247 · Separate live references from historical ones in the teardown goal · Docs · 2026-07-29

The last two findings of the hand measurement in `davekokbwj/smartwatchbanden` (July 29, 2026), and the
second one moves the goalpost rather than adding to the list.

**A consumer gate that goes blind rather than red.** A consumer that lints its own lens files keeps that
check after a teardown, and in the measured repo the lens category **silently skips** once the directory
is gone: nothing errors, nothing is reported, and the gate stays green while checking nothing. Right for
a deliberate teardown, wrong for an accidental loss — a silent skip cannot tell an operator's removal
from a bad merge or a mistyped path, so the one case it must warn about is the one case it stays quiet
in. The gate is the consumer's own, so this is documented rather than fixed here, together with the
target-shape requirement that a skip should *say* it skipped.

**The goal is no *live* reference, not zero references.** `CHANGELOG.md` (3) and
`releases/development/*` (43) mention specialists in the measured repo — 46 references that are each an
accurate record of something that happened. History is finished business: never rewritten, and a
teardown must not touch it. So the requirement as literally stated ("no lingering reference anywhere in
the repo") is both unreachable and undesirable for any repo that ever adopted the plugin, and it is now
read as: nothing a **session loads**, a **script resolves**, or a **gate depends on** may still point at
the plugin. That reading makes the goal testable and sorts the four known leftovers by what they cost —
a resolver that throws breaks a run, an orphaned roster row only misleads a reader.

Recorded in the [family README](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/README.md#removal-the-teardown-gap)
(the requirement itself, plus a fifth target-shape bullet) and in
[`specialists-teardown`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/specialists/skills/specialists-teardown/SKILL.md),
whose leftover section now runs to four kinds and closes with what is correctly left standing.

[PR #247](https://github.com/DaveKJohn/davekjohns-workshop/pull/247)

---

#### #246 · Record what a teardown leaves behind, honestly · Docs · 2026-07-29

A hand measurement in `davekokbwj/smartwatchbanden` (July 29, 2026) established how far a torn-down
consumer really is from "no reference to the plugin anywhere", and one of the findings contradicted
what the family README claimed. Both docs now state it.

**The finding that matters: a runtime dependency, not clutter.** The plugin is the single source of
truth for the operational scripts (`new-branch.ps1`, `park-branch.ps1`, `new-changelog-entry.ps1`,
`open-pr.ps1`, `fold-changelog-entry.ps1`; #81), and a consumer reaches them through a resolver of its
own that locates the marketplace cache and **throws** once that cache is gone — in the measured
consumer `scripts/lib/plugin-paths.ps1`, dot-sourced by `start-task.ps1`, `open-pr.ps1`, and
`fold-changelog-entry.ps1`. So after a teardown plus `claude plugin uninstall` the repo does not merely
carry leftovers: its daily git workflow stops working. The teardown gap table in the family README
listed the shared scripts as "gone cleanly — plugin-owned", which is true of the plugin's side of the
boundary only; that row is now qualified, and the target shape gains the missing requirement (the
resolver degrades to an actionable failure, or the consumer keeps local copies — decided at adoption,
because no teardown can decide it afterwards).

**Two further leftovers named in [`specialists-teardown`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/specialists/skills/specialists-teardown/SKILL.md).**
The authored text the script refuses to touch is now quantified rather than described — roughly 43
lines across some 6 sections of `CLAUDE.md` (the 22-row roster table, the work-division block, the
loading-strategy paragraph, the safety cross-references), plus loose mentions in `README.md` (5),
`research/plugin-sharing/README.md` (14), `releases/README.md` (1) and
`.github/pull_request_template.md` (1). And the orchestrator's lens survives as an **orphan**: it is
authored, so it is kept, while the `@`-import that loaded it is knowably bootstrap-written and is
removed — a `[KEEP]` line that reads as "still working" when it only means "still there".

The skill also now says plainly that its dry run warns about none of this: it reports what it would
remove and what it keeps, not what breaks afterwards. Making it warn is a script change, deliberately
not folded into this documentation pass.

[PR #246](https://github.com/DaveKJohn/davekjohns-workshop/pull/246)

---

## v2.13.3 — 2026-07-29

### Fixes

#### #243 · An entry body must not use H2 — the release notes reserve that level for categories · Fix · 2026-07-29

Caught while inspecting v2.13.2 before pushing, which is exactly what `-NoPush` exists for. PR #242's
entry body used `##` sub-headings. `cut-release.ps1` puts `## Features` / `## Fixes` / `## Documentation`
/ `## Maintenance` above the entries it groups, so those two climbed out of their category and rendered as
siblings of it:

```
## Fixes
### #242 · The round-trip is honest and idempotent · Fix · 2026-07-29
## On the tests, because one of them was worthless at first    <- reads as a release category
## Filed separately                                            <- reads as a release category
```

Demoted to `####` in both generated artifacts — `releases/development/2.x/2.13.2.md` and
`specialists/CHANGELOG.md`. The root `CHANGELOG.md` needed nothing: the release had already lifted the
entry out of `## Pull Requests`.

**Why this got through, and it is a familiar shape.** The entry file reads perfectly well on its own, and
so does the `## Pull Requests` section it is folded into — there the entry sits under an `##` itself, so a
body `##` looks level-appropriate. The defect only exists once `cut-release` lifts that body into a
context with categories above it. Same blind spot as
[#234](https://github.com/DaveKJohn/davekjohns-workshop/issues/234): the artifact a reader finally sees is
assembled *after* every gate that could have judged it — there by the fold, here by the release.

Recorded in [Rendall #06's lens](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/.claude/plugins/claude-specialists/specialists/05-06-extension.md) beside
the entry format, with the reason it is invisible until release time and the instruction that follows
from it: **inspect the generated notes before pushing.**

The release itself was correct in substance — version, tag, lockstep, notes content — so it was pushed as
cut rather than unwound. Undoing a local release commit means `git reset --hard`, which needs Dave's
explicit permission, and a heading level does not justify asking for it when the normal branch + PR flow
fixes it in minutes.

[PR #243](https://github.com/DaveKJohn/davekjohns-workshop/pull/243)

### Documentation

#### #244 · The round-trip verification protocol lives with the skill, and does not trust git · Docs · 2026-07-29

Addresses item 2 of [#241](https://github.com/DaveKJohn/davekjohns-workshop/issues/241). The first real
round-trip test was verified with `git status` / `git diff`, and that method was **partly blind**: the
consumer ignores `.claude/*`, so `settings.suggested.jsonc` never appeared in `git status` and
`git checkout .` did not clean it up. Since `.claude/` holds most of what the bootstrap writes, git can
miss the bulk of a teardown's effect.

The protocol now lives in the teardown's own `SKILL.md`, where an operator actually looks, rather than in
a prompt that exists once and is then lost:

- **Take a filesystem inventory per stage** — lens count, import count, both script scaffolds, the
  settings proposal — instead of trusting `git diff --stat`.
- **Run the cycle twice.** One pass cannot distinguish "does not accumulate" from "accumulates once", and
  accumulation is exactly what the first round found (1 → 2 → 3, with every hook reporting "in sync").
- **Count lone LFs in `CLAUDE.md`.** The other defect no gate saw.
- **Declare your own empty-lens convention** with `-EmptyLensPattern`, or the report keeps files it cannot
  recognise.

**The sharper warning is recorded with it:** in a repo that ignores `.claude/`, git cannot *restore* a
wrongly deleted lens either. So establish whether `.claude/` is tracked **before** running with `-Apply`,
not after. That is a materially different safety story from the one the skill was written under, and it
was only visible because the test ran somewhere real.

Item 1 of #241 (the teardown noting its own unmeasurability) and item 3 (whether the proposal file should
live outside `.claude/` at all) stay open there.

[PR #244](https://github.com/DaveKJohn/davekjohns-workshop/pull/244)

---

## v2.13.2 — 2026-07-29

### Fixes

#### #242 · The round-trip is honest and idempotent · Fix · 2026-07-29

Three defects from the **first real round-trip test**, run in `davekokbwj/smartwatchbanden`. Every one of
them was invisible to the fixtures and to all three session hooks, which reported "in sync" throughout.

**1. The teardown claimed authorship it could not establish.** Twenty of that repo's 22 lenses are empty
under **that repo's own** "clean slate" convention — a closing sentence, no `(VUL-IN)` heading anywhere —
so the scaffold test did not recognise them and the report called all 22 *"filled in, so it is repo
knowledge somebody wrote"*. The earlier prediction that all 22 would be kept came out for the **wrong
reason**: not because they were authored, but because the test was blind. Adoption was therefore less
reversible than the skill claimed.

Two changes. The report no longer asserts authorship — it says the file is *not recognised as an unfilled
scaffold*, which is all it knows, and the summary dropped its blanket `(authored)`. And a consumer can
declare its own convention with **`-EmptyLensPattern <regex>`**. Verified against the real repo: without
it, 2 to remove / 24 kept; with `-EmptyLensPattern 'Nog niets vastgelegd'`, **20 lenses become removable**
and the two genuinely authored ones (`01-01`, `04-12`) are still kept. The default keeps them, because a
false keep leaves clutter while a false remove destroys someone's work.

**2. The round-trip accumulated.** The bootstrap writes an explanatory line above the `@`-imports. The
teardown removed the imports and, by design, nothing else — so the line survived, the bootstrap's guard
tested only for the lens import, read "not present", and re-appended the **whole block**, line included.
One extra copy per teardown→init cycle, measured 1 → 2 → 3.

Fixed on both sides, because the cycle needed both defects: the teardown now removes that line too
(matched on its literal generated wording, so a reworded or translated version is left alone), and the
bootstrap drops a leftover copy before appending. **Idempotence has to cover everything a script writes,
not just the line it happens to look for.**

**3. Line-ending drift, from init only.** The bootstrap pasted a `` `n ``-built block into a CRLF file,
leaving 8 lone LFs; the teardown was clean. Both sides now match the file's existing convention.

#### On the tests, because one of them was worthless at first

The accumulation cases passed **even with the bootstrap fix reverted** — the teardown change alone breaks
the cycle. So they never covered the bootstrap half. A separate case now isolates it: a repo whose imports
were removed by hand while the line stayed, which is the scenario that guard actually defends. Verified to
fail without the fix and pass with it. The same discipline was applied to the other two, so each fix
discriminates its own test. 69 assertions.

One assertion was rewritten rather than repaired: it hung on the literal phrase `delete by hand`, which
this change reworded. It now asserts the substance — that the reader is pointed at both ways to finish —
so the next wording change does not produce a false failure.

#### Filed separately

- [#240](https://github.com/DaveKJohn/davekjohns-workshop/issues/240) — `check-connectors` picks one of
  several machine records and reports it as fact. That repo had `specialists` listed three times at three
  versions; the check takes the first `projectPath` match and stops, so the version it reports rests on
  JSON ordering.
- [#241](https://github.com/DaveKJohn/davekjohns-workshop/issues/241) — a git-based round-trip check is
  blind to gitignored bootstrap artifacts. `.claude/*` is ignored there, so `settings.suggested.jsonc`
  never showed in `git status` and `git checkout .` did not clean it. A defect in how the test was asked
  for rather than in the script — and it matters more than it sounds, since a consumer that ignores
  `.claude/*` cannot use git to restore a wrongly deleted lens.

Not acted on: that repo's tree stood on `main` carrying work belonging to an existing branch. Its own
housekeeping, reported rather than touched from here.

[PR #242](https://github.com/DaveKJohn/davekjohns-workshop/pull/242)

---

## v2.13.1 — 2026-07-29

### Fixes

#### #236 · The teardown no longer deletes a file that merely mentions `VUL-IN` · Fix · 2026-07-29

**A dry run against a real consumer found a bug that would have destroyed working configuration.** Dave
asked whether a real consumer test was possible yet; it was, read-only, and it earned its keep
immediately.

`specialists-teardown` classified a file as an unfilled scaffold if the string `VUL-IN` appeared
**anywhere** in it. Run against `davekokbwj/smartwatchbanden`, that marked `scripts/repo-config.ps1` for
removal — a file carrying real values for all eight contract functions. The only `VUL-IN` left in it sits
in the scaffold's own **docstring** (*"fill in remaining VUL-IN values"*), which a consumer has no reason
to strip. That is not an edge case: it is the **normal state of a filled-in scaffold**, so the naive rule
would have deleted the file `open-pr`, `fold-changelog`, `new-branch` and `check-roster-sync` all depend
on. The same flaw applied to lenses — an authored lens that happens to explain the scaffold convention
would have gone the same way.

The test now keys on a placeholder in a **position that only real use produces**: a `VUL-IN` inside an
assignment's *value* for `repo-config.ps1`, the *empty prefix table* for `branch-info.ps1`, an unfilled
slot *heading* for a lens.

| dry run, real consumers | before | after |
|---|---|---|
| `smartwatchbanden` | 3 to remove, 23 kept | **2 to remove, 24 kept** |
| `life-hub` | 2 to remove, 26 kept | **2 to remove, 26 kept** |

Both now propose removing only the two `@`-imports, and both checkouts were verified byte-untouched
before and after every run.

**Third instance of one defect in a single day**, now generalised in
[Sylvester #15's lens](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/.claude/plugins/claude-specialists/specialists/05-15-extension.md) as **mention vs
use**: the roster check counted an `@`-import path as a roster row (#227), the lint gate read a marker
quoted in changelog prose as a real enumeration (#235), and this read a docstring explaining placeholders
as a placeholder. When a check's evidence is "this string appears in the file", ask what else in that file
legitimately contains it — and for a script that deletes, resolve every doubt toward keeping: a false keep
leaves clutter, a false remove destroys someone's work.

**Why no fixture caught it.** Every test scaffold was either untouched or fully rewritten; none
reproduced the real-world middle state of a scaffold whose values are filled in while its docstring stays.
The regression test now uses that exact shape, and was verified to **fail against the old heuristic**
before being trusted.

**Consequence worth stating plainly: v2.13.0 shipped with the naive test.** Anyone running the teardown
with `-Apply` from that release risks losing a configured `repo-config.ps1`. This fix is on `main` and
needs a release to reach consumers.

[PR #236](https://github.com/DaveKJohn/davekjohns-workshop/pull/236)

---

## v2.13.0 — 2026-07-29

### Features

#### #233 · `specialists-teardown` — adoption is now reversible · Feat · 2026-07-29

Third item of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221), and the half that
could be built and tested without restructuring anything first. Dave's requirement: a consumer must be
able to install **and uninstall** at any moment and afterwards stand free of the plugin. There was a
`specialists-init` to build up and nothing to take down.

[`specialists-teardown`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/specialists/skills/specialists-teardown/SKILL.md)
is the bootstrap's mirror image: where the bootstrap is strictly **additive** and never overwrites, the
teardown is strictly **subtractive** and never deletes what the owner wrote.

**Classifying before removing is the entire design**, because consumer-side content is three things and
only one is disposable:

| category | what happens |
|---|---|
| generated and untouched — a lens still carrying its `VUL-IN` marker, an unfilled script scaffold, the `@`-imports, `settings.suggested.jsonc` | **removed** |
| authored by the owner — a filled-in lens holding repo knowledge somebody wrote | **reported, never touched** |
| owned by the repo anyway — a real `repo-config.ps1`, a filled branch table | **reported as yours to keep or drop** |

The `VUL-IN` marker is the test, because that is the exact contract `bootstrap.ps1` writes those files
under; its absence means somebody edited the file, which makes it theirs. Deliberately a content test
rather than a timestamp or hash — a reformat or a merge does not make content authored.

**Dry run by default.** A destructive script running on somebody's repo should have to be asked twice,
and the preview doubles as the inventory a reader needs in order to say yes.

**Two things it refuses to do.** It never edits `.claude/settings.json` — disabling the plugin is the
owner's act, and the bootstrap never wrote that file either, so the symmetry that makes this safe cuts
both ways; it is reported instead, noting that the subagents and hooks stay active until the entry is
gone and the session restarted. And it never removes roster rows or repo prose from `CLAUDE.md`: the only
lines it touches there are the two `@`-imports, safe because an import naming a persona body or an
extension lens is knowably bootstrap-written — the same property that let `check-roster-sync` stop
counting them as roster rows (#227).

**Measured round-trip:** bootstrap a fixture → 24 items placed → teardown removes 22 and keeps the 2 the
owner filled in, with the owner's own `CLAUDE.md` prose intact.

**38 tests, and the ones that matter are the negative ones.** A teardown that removes plenty is easy; one
that can be trusted has to demonstrably not touch authored content, not edit `settings.json`, and not eat
an unrelated `@`-import. That last case is the sharpest risk in the design: a consumer's own
`@docs/git-instructions.md` is exactly the line a sloppy rule destroys, and they would have no idea why
their instructions stopped loading. The matcher keys on the specialist shape, and the test proves it.

**What it still cannot finish, stated rather than glossed.** A repo that authored lenses and roster
sections is not blank afterwards — those are reported, not removed. As long as specialist content is woven
through `CLAUDE.md` instead of sitting behind one inclusion, no script can finish without guessing where a
roster row ends and the owner's prose begins. That is the seam, and #221 stays open for it.

The lint gate's skill-enumeration check (#10) caught the new skill missing from two marked
`skills:all` spans in the family README before CI did — the guard working exactly as designed.
(Deliberately naming the marker without its comment delimiters: check 10 scans `CHANGELOG.md` for
those delimiters and does not skip code spans, so writing them out here would make this entry trip
the very check it describes — which is exactly what happened on the first attempt, see #234.)

[PR #233](https://github.com/DaveKJohn/davekjohns-workshop/pull/233)

### Fixes

#### #230 · The bootstrap's scaffolds satisfy the plugin's own contract · Fix · 2026-07-29

Resolves [#226](https://github.com/DaveKJohn/davekjohns-workshop/issues/226). A freshly bootstrapped
repo got **3 `[ERROR]` lines about files the bootstrap had just written** — `Test-BranchName`,
`Get-RosterPath` and `Get-RosterIgnoredIds` missing from the `VUL-IN` scaffolds `specialists-init` places.

The issue asked which side was wrong, and the answer was in the scaffold's own docstring: it advertised
`Get-RepoName / Get-RepoBlobUrl / Get-LintScript`, the contract as it stood when the scaffold was
written. The contract then grew — `Test-BranchName` with `new-branch`, `Get-RosterPath` and
`Get-RosterIgnoredIds` with the roster-sync feature in v1.12.0 — and the scaffold never followed. So the
scaffold side was stale, and the check's wording made it read the other way round: *"this lib predates
the contract"* is the wrong story for a lib written seconds earlier by the current version of the plugin.

All three functions are now in the scaffolds, with the real semantics rather than stubs:
`Get-RosterPath` defaults to `CLAUDE.md`, `Get-RosterIgnoredIds` to an empty array (with a note that
adopting a specialist is the default, and that without this function "skip this one" is not an
implementable outcome at all — which is why the contract marks it required), and `Test-BranchName`
carries the actual reject rules, including that an unknown prefix is deliberately *not* a hard reject.

**The durable part is not the three functions — it is the invariant.** Every existing scaffold assertion
was a spot-check against a hand-maintained list, and that is precisely how this drifted. The new case
spot-checks nothing: it runs the **real contract check against the real bootstrap output**, so adding a
required contract entry without extending the scaffold now fails the suite, whatever the entry is called.
It also asserts the check genuinely probed the libs rather than passing because #225's `[BOOTSTRAP]`
short-circuit swallowed the run — a test that can pass for the wrong reason is not a test.

Measured with the harness from #224: a correctly bootstrapped consumer now shows **19 `[ERROR]` lines,
down from 22.** What remains is the roster rows the owner genuinely has to add, all 19 of them, which is
real work rather than a defect — though 19 near-identical lines is still more noise than one roll-up
would be, and that is worth a separate look now that this is out of the way.

[PR #230](https://github.com/DaveKJohn/davekjohns-workshop/pull/230)

---

#### #229 · An `@`-import no longer passes for a roster row · Fix · 2026-07-29

Resolves [#227](https://github.com/DaveKJohn/davekjohns-workshop/issues/227). `bootstrap.ps1` writes
`@.claude/plugins/<family>/<plugin>/01-01-extension.md` into `CLAUDE.md`, and that path *contains* the
token `01-01`. `Test-InRoster` scans the roster file for the token, so the import line satisfied it:
Chris counted as rostered with no roster row anywhere in the file. Measured on a bootstrapped consumer,
19 specialists produced **18** missing-roster findings, and the one that silently passed was the worst
possible id to lose — a persona appears in no always-on listing, so the roster row is the only thing
that makes them exist for a session. The check was blind exactly where blindness costs most, and blind
*because* the bootstrap had correctly done its job.

`check-roster-sync.ps1` now strips `^\s*@` lines from the roster text before anything reads it, which
fixes both directions: the missing row is reported, and an import naming an id with no backing
specialist no longer manufactures a phantom orphan.

**The fix is narrow on purpose, and that is the interesting part.** The obvious repair — bind the token
to a roster-row/table shape — is exactly what `Get-RosterIdTokenPattern`'s docstring records as
**deliberately rejected** under inbound #182: `Test-InRoster` is asked about an id in free prose, and a
table shape would change behaviour for consumers who format their roster as a list. That reasoning still
holds and is not overturned here. An `@`-import is a different animal: a line the bootstrap writes, never
a roster row under any formatting convention, so excluding it needs none of that risk. The docstring now
records where that documented limitation stopped being cosmetic, and the question to ask next time —
*does the offending text have a writer that is knowably not the roster author?* — so a future case is
weighed against this carve-out instead of reopening the rejected option from scratch.

**Residual, unchanged and deliberately not chased:** a roster file that references a lens path in
ordinary prose still satisfies the test for that id. This repo does precisely that — Chris's lens is
linked from the routing prose — so its `01-01` would pass even without a table row. Harmless here, since
the real roster row exists, and the same accepted class as the prose false positives in #182.

**The error count goes up, not down: 21 → 22.** This fix *adds* a correct finding rather than removing
one, because the bug was concealing real work. Worth stating plainly so the next measurement is not read
as a regression.

The regression test was verified to **fail without the fix** before being trusted — both halves, the
missing row and the phantom orphan.

[PR #229](https://github.com/DaveKJohn/davekjohns-workshop/pull/229)

---

#### #228 · A repo that was never set up is told so, instead of shouted at 44 times · Fix · 2026-07-29

Resolves [#225](https://github.com/DaveKJohn/davekjohns-workshop/issues/225). Dave's bar: a consumer
may still have work to do after installing, **as long as they are told**. Measured before the change
(PR #224), a fresh consumer got **44 `[ERROR]` lines** at session start and **zero** mentions of the
skill that resolves them — which reads as "this plugin is broken", not "you are not done yet". One
channel actively said *"no action is needed on your side."*

The root cause was a distinction the checks could not make: **drift reporting is right for a
bootstrapped repo and wrong for one that was never set up.** A repo with no lenses and no roster rows
has every enabled specialist "missing" twice over, which is not 38 findings — it is one.

Both checks now detect that state and emit a single non-counting **`[BOOTSTRAP]`** marker naming
`specialists-init`, and both hooks give it **its own verdict** rather than folding it under an existing
one. It arrives on an exit-0 run, so without a dedicated branch it would have fallen through to
"roster in sync with the enabled plugins" — a flat untruth for a repo that has no roster.

| a fresh consumer sees | before | after |
|---|---|---|
| `[ERROR]` lines at session start | **44** | **0** |
| lines naming `specialists-init` | **0** | **2** |

**The predicate is deliberately strict, and that is most of the work.** Only *neither lenses nor roster
rows* counts as never-bootstrapped; a repo with one half is a maintained repo that has drifted and must
keep erroring. Same for the contract check: one lib present means real drift, all absent means not set
up. Both directions are asserted, because a fix like this earns its keep by *not* swallowing genuine
findings.

**Also fixed: remediation pointers that named paths the reader does not have.** The hooks told
consumers to run `scripts/sync/check-roster-sync.ps1` and `scripts/sync/check-script-contract.ps1` —
repo-relative paths for scripts that ship in the plugin. Same class as the v2.11.0 fix ("consumer
messages stop pointing at the workshop"); these were remaining instances. The roster hook now names the
`sync-roster` skill, and the contract hook drops the pointer entirely since its findings already name
every function and its file.

**Honest about what is not fixed.** After a *correct* bootstrap the count is still **21**: three are
[#226](https://github.com/DaveKJohn/davekjohns-workshop/issues/226) (the bootstrap's own scaffolds
failing the plugin's own contract check) and eighteen are the roster rows the owner genuinely has to
add. Those eighteen now carry an actionable pointer instead of a path that does not exist, so the state
meets Dave's bar — but 18 lines is a lot of red for someone who just followed the instructions, and
that is worth revisiting once #226 lands.

Two engineering notes recorded in
[Sylvester #15's lens](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/.claude/plugins/claude-specialists/specialists/05-15-extension.md). The
non-counting marker is now a **standing pattern** rather than a fourth exception — `[ORPHANS]`,
`[UNREGISTERED]`, `[INVENTORY]`, `[BOOTSTRAP]` all answer the same problem, and the recipe is written
down so a fifth case reaches for it instead of inventing a shape. And: a repo-wide verdict must be
computed where the evidence is complete, not where it is cheapest. The first implementation
short-circuited before plugin resolution and immediately mistook *plugin not installed on this machine*
for *repo not set up* — two states that need opposite advice. The suite caught it in one run, which is
the argument for landing the guard case in the same commit as the feature.

[PR #228](https://github.com/DaveKJohn/davekjohns-workshop/pull/228)

---

## v2.12.0 — 2026-07-29

### Fixes

#### #220 · Inventory drift in the session's own repo is visible at session start · Fix · 2026-07-29

The register's `extensions` inventory is meant to follow reality. When it does not, the check reports
an `[INFO]` — and the session hook surfaces only `[ERROR]` lines, so the finding is invisible where
someone would act on it. That is not theoretical: the run that prompted this found eleven of them at
once, six in **this repo's own entry**, where the lenses had landed with the adopt-the-six change
(PR #212) and the inventory was never updated alongside. It sat there until someone ran the check by
hand.

The connectors README had carried an "after a refresh, also update the manifest" rule the whole time.
That rule is why this is filed as a fix rather than a feature: it was on the books, it was not
followed, and nothing reported the omission — so nothing prompted anyone. A sharper sentence would
have changed nothing.

`check-connectors.ps1` now also emits a **non-counting `[INVENTORY]`** line that the hook surfaces,
on its own verdict (`no errors, but the register's lens inventory for this repo is behind`) rather
than folded under the not-registered one — those are different situations with different fixes. The
third instance of the `[UNREGISTERED]`/`[ORPHANS]` shape: the `[INFO]` stays for the count and the
deliberate run, the exit code stays 0, and nothing about the plugin install is implied to be broken.

**Scoped as narrowly as the reasoning allows.** The marker fires only for the connector whose checkout
*is* the repo the session is in — the workshop's own `localCheckout: "."` entry on a full sweep, or the
consumer's own entry under `-OnlyConsumer`. Every other connector's drift stays silent, so the
`[INFO]`-silence rule keeps applying wherever its justification ("often the business of another machine
or user") is actually true. Promoting it for all connectors would have reintroduced exactly the noise
that rule removed. Decision by Dave, July 29, 2026.

Fifteen tests cover it (99 pass, up from 84), including the two that matter most: that drift in
*another* repo's entry produces the `[INFO]` and **no** marker, and that the marker still surfaces when
real `[ERROR]` signals are present too — a regression there would drop it exactly when a session is
busiest.

Two verification lessons are recorded in
[Sylvester #15's lens](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/.claude/plugins/claude-specialists/specialists/05-15-extension.md): a
`Write-Host` line is invisible to a same-process pipeline, so an in-process assertion about one passes
whether the line is there or not (both cases read 0 — which makes a negative scoping assertion
worthless unless it runs the check as a child process, the way the hook does); and
`Set-Content -Encoding utf8` restores a file *with* a BOM under PowerShell 5.1, so undo a temporary
probe with `git checkout --` instead.

[PR #220](https://github.com/DaveKJohn/davekjohns-workshop/pull/220)

---

## v2.11.0 — 2026-07-28

### Fixes

#### #213 · Hooks survive compaction, and consumer messages stop pointing at the workshop · Fix · 2026-07-28

Two findings from Dave's principle: **assume a consumer knows nothing about this workshop.** A
colleague who merely installs the plugin must be served by it, not put to work for it.

**1. The three session hooks went silent after the first `/compact`.** `hooks.json` matched only
`startup`, while a SessionStart hook's injected stdout does not survive a compaction on its own — the
[documented](https://code.claude.com/docs/en/hooks) way to keep it is to let the hook run again, which
it does only for the sources its matcher names (`startup`, `resume`, `clear`, `compact`, `fork`). So
every report — roster drift, script-contract drift, connector signals — disappeared from the context at
the first compaction and never came back. Now `startup|resume|clear|compact`.

`fork` is deliberately excluded: a forked session inherits the parent's context, so re-running would
only duplicate the report. The cost was **measured** before widening rather than assumed — all three
hooks together take ~4.6s (the connector check ~2.6s of it, since it runs the drift check per consumer),
less than the compaction they now run alongside. Because `hooks.json` is JSON and cannot carry a
comment, the reasoning lives in the hook docstrings.

This was filed in inbound #204 as one of two closing observations *"offered as data rather than as
asks"*, and left out of scope then. It turned out to be the load-bearing one.

**2. Two consumer-facing messages handed out homework in a repo the reader may not have.**

- **`[UNREGISTERED]`** said *"add connectors/<repo>.json in the workshop"*. Who benefits from
  registration is the plugin's maintainer; who was being instructed was the consumer. It now states that
  nothing there is broken (the plugin works normally; only the maintainer's view is missing) and
  addresses the fix conditionally — *"if you maintain the plugin source … if you just use the plugin, no
  action is needed on your side."* The hook's verdict line drops the word "workshop" too: internal
  nickname, meaningless to that reader.
- **A missing script-contract function** ended with *"update it from the workshop's own
  scripts\repo-config.ps1"* — useless advice for exactly the reader most likely to hit it. Each contract
  record now carries a `Returns` line stating in one sentence what the function must give back, so the
  finding is **self-contained**: the reader can write the function from the report alone. Example:

  > `[ERROR] 'Get-RosterPath' missing from scripts\repo-config.ps1 (required by: check-roster-sync) --
  > this lib predates the contract the shared script(s) call; add the function. It must return the
  > repo-root-relative path to the file holding the specialist roster -- 'CLAUDE.md' unless this repo
  > keeps it elsewhere.`

`Get-RecordReturns` degrades to the shorter message when a record has no `Returns`, so nothing breaks —
which is precisely why a record could be added without one and nobody would notice. A drift guard
asserts the `Returns` count equals the record count, so a ninth record without one turns the suite red.

Two test-quality notes worth keeping. The "no workshop jargon" assertion first failed on the *fixture*
rather than the hook: the stub still carried the old message text, making the hook look guilty of words
it never produced. Stubs that exist to prove a wording must carry the real wording. And the intended
demonstration against smartwatchbanden could not run — that repo's session had already repaired its
script contract while this branch was being built, so its eight functions now report `[OK]`. The
demonstration moved to a throwaway fixture instead.

[PR #213](https://github.com/DaveKJohn/davekjohns-workshop/pull/213)

### Documentation

#### #211 · Adopting a new specialist is the default, not a question · Docs · 2026-07-28

Dave, during the smartwatchbanden catch-up: the session asked him, one by one, which of five new
specialists to adopt. His answer — *it should always just be adopted after a plugin update.*

**The asking came from a hand-written handover prompt, not from the system.** Nothing in the plugin or
the repo docs said to ask; the prompt for that session did, explicitly. That is the interesting part:
the rule had no home, so whoever writes the next prompt is free to invent the approval step again. It
now lives in the two places a session actually reads at that moment — the `sync-roster` skill (where
the catch-up is staged) and `check-roster-sync.ps1`'s docstring (where the `[ERROR]` comes from) —
rather than in a prompt that is written once and forgotten.

**The reasoning, because "always adopt" sounds careless and is not.** The lens scaffold is empty on
purpose: a `VUL-IN` lens may sit untouched until that specialist actually has work in the repo — that
is what the scaffold is *for*, not an unfinished task. So adopting costs a file nobody has to fill in
yet, while asking costs an interruption over a decision with no downside either way. That is exactly
the shape of approval question the governance rule already rules out: reserve them for the
irreversible, the outward-facing, and the genuinely risky.

What stays a judgment call is the *content* — what the lens says once the specialist has work, and
where the roster row belongs — and those are writes to the governance doc, which `sync-roster`
deliberately never makes. Adoption and lens content were being treated as one decision; they are two,
and only the second needs a human.

**The ignore-list keeps its role, with its character corrected.** `Get-RosterIgnoredIds` is for a
specialist that genuinely has no place in a repo, recorded on your own initiative with a comment
naming who and why. It is a statement, not an answer to a per-update question.

Also corrected in the same pass: the ordering advice given for the smartwatchbanden catch-up. Fixing
the script contract still has to come first, but for a different reason than was written down. It is
not "so that skipping becomes possible" — it is that `check-roster-sync` needs `Get-RosterPath` and
`Get-RosterIgnoredIds` to run without a hard error at all.

[PR #211](https://github.com/DaveKJohn/davekjohns-workshop/pull/211)

---

## v2.10.0 — 2026-07-28

### Fixes

#### #208 · An unregistered consumer is visible at session start · Fix · 2026-07-28

Found by Dave: the `specialists` plugin had been installed on a third repo (`djcylow-react`) and it
never appeared in the connectors register. Reproduced against a throwaway clean consumer, and the
result was worse than a missing entry — it was a false all-clear:

```
check-connectors:        [INFO]  not registered: no manifest for this consumer in the register.
connector-sessioncheck:  no errors.
```

The check *knew*. The hook suppresses `[INFO]` (Dave's July 20, 2026 decision), so what a brand-new
consumer actually saw was a positive verdict for a repo this workshop cannot see at all: no
plugin-version check, no lens-inventory check, no agent-def drift check. `djcylow-react` had been
filing inbound issues since July 26 in that state.

**Two gaps, and they compounded.**

**Gap A — nothing pointed towards registration.** `specialists-init` contained no mention of the
register at all (`connector|register|manifest`: zero hits), and it structurally cannot create the
manifest: the register lives in the workshop, the bootstrap runs in the consumer, and the register's
doctrine is explicit that it never writes cross-repo. So it now closes the loop from the other side —
after bootstrapping it prints a **paste-ready manifest block**: repo name derived from the git remote,
lens inventory per plugin, and `visibility`/`localCheckout` left as `VUL-IN` because it genuinely
cannot know them (it has no idea where the workshop checkout sits relative to the consumer, and a
guessed path is exactly what the register's marker check exists to prevent). Printed, never written.

The inventory deliberately covers **both** lens kinds. Collecting only the agents would hand over a
manifest that under-reports the repo by exactly its persona-only specialists — the same class of bug
inbound #204 was about, one layer along.

**Gap B — the "unregistered" signal could not reach a session.** `check-connectors.ps1` now also emits
a non-counting **`[UNREGISTERED]`** line that the hook surfaces, *next to* the no-errors verdict rather
than under it: nothing is wrong with the plugin install in that repo, only with this workshop's view of
it, so the exit code stays 0 and the per-signal `[INFO]` stays suppressed. The `[INFO]` itself remains
for the count and the deliberate run.

Deliberately **not** promoted to `[ERROR]`, which would make the exit code 1 and put a red line in
every session of a repo somebody chose not to register. The mechanism is the one `check-roster-sync`
already uses for `[ORPHANS]` (inbound #204) — a dedicated non-counting token — applied a second time,
which is what makes it a pattern rather than a one-off.

**This is not a relaxation of the `[INFO]`-silence rule.** That rule was justified as *"often the
business of another machine or user"*; this signal is its opposite — about the repo the session is in,
actionable there. The connectors README's own classification rule already pointed the same way: a
category that must not stay out of sight may not be filed as `[INFO]`. Recorded there as a named
exception, so the next extension of the check has a precedent to reason from instead of a
contradiction.

**Someone got halfway here before.** `connectors.tests.ps1` case 5c carries the comment *"regression:
this used to be a bare Write-Host that did not count as an info signal, causing the hook to show 'all
connectors in sync'"* — the false reassurance was spotted once and half-fixed: made countable, so a
deliberate run reports it, while the hook kept hiding it. The remaining half is this change.

Not resolved here: registering `djcylow-react` itself. Its checkout is not on this machine, so its
plugin set and lens inventory cannot be read — that manifest needs a session on the machine where the
repo lives, or the data by hand.

[PR #208](https://github.com/DaveKJohn/davekjohns-workshop/pull/208)

---

## v2.9.0 — 2026-07-28

### Fixes

#### #206 · Roster check covers persona-only specialists · Fix · 2026-07-28

Inbound #204 from life-hub. `check-roster-sync.ps1` never checked whether a **persona-only**
specialist had a roster row and a lens, so the roster could lose Chris's or Derek's row and the check
would stay green. Measured in life-hub: the shared check validated **20** specialists where that
repo's own `lint-plugin-sync.ps1` compared **24** — the gap being exactly the four persona-only
main-loop specialists.

**The old exclusion bundled two decisions into one, and only the first followed from the reasoning.**
*"A persona is not an orphan"* is right — counting personas as backing is what stops them being
flagged as orphans in every real repo, and `Get-BackingIds` keeps doing exactly that, untouched.
*"A persona can therefore never be missing"* does not follow: a persona is a real specialist with a
roster row and a lens, just like an agent, and when the row or the lens is gone that is actionable
drift of precisely the kind this check exists for. The missing-row/missing-lens loop now walks agents
**and** personas, each finding naming which kind it is about.

**One persona exception remains, deliberately: the lens-header drift check.** That comparison needs
the specialist's current name, which comes from an agent file's `name:` frontmatter. A persona file
carries only `id`/`group`. Run it anyway and every persona lens whose header holds a name — i.e. all
the older ones — would be reported as drifting from its own id: a false signal in exactly the
register the session hook is being taught to trust. Documented as a gap in the script, with a test
pinning the absence of the false signal rather than the presence of a feature.

**Two consequences of extending the coverage, both handled rather than discovered later:**

- **A deliberately unrostered persona is now real drift.** This workshop has one: Bianca (03-02), a
  main-loop *intake* persona `CLAUDE.md` explicitly does not roster, because there is no
  intake-interview work here. That choice was prose only; it is now also recorded in
  `Get-RosterIgnoredIds`, where the check can read it. The ignore-list doing its job — the
  alternative was a permanent `[ERROR]` at every session start for a decision made on purpose.
- **The `sync-roster` skill would have staged nothing for the new findings.** Its `[ERROR]`-parsing
  regex matched the literal word `agent`, while both the check's own report and the session hook point
  the reader at that skill to stage the catch-up. Left alone, the pointer would have looked helpful
  and quietly done nothing for exactly the findings this change introduced. The pattern now accepts
  `persona` too. Both downstream steps already cope: the lens scaffold has been nameless since #145,
  so it needs no persona variant, and a proposed roster row falls back to the id plus an explicit
  *"(add a short description)"* placeholder — degraded on purpose rather than inventing a name a
  persona file does not contain.

**Change 2 — the orphan trail is no longer silent.** An orphan (a roster token or lens file with no
backing agent *or* persona — the "specialist removed from the plugin, consumer lens left behind"
case) is `[INFO]`, and the hook suppresses `[INFO]`, so the finding existed only for whoever
deliberately ran the script: in practice nobody. The per-orphan lines stay `[INFO]` and stay
suppressed — an orphan can be a legitimately just-removed specialist, and a red line through every
transition is how a gate gets ignored. What the check now adds is one non-counting `[ORPHANS]`
roll-up naming the count, which the hook *does* surface, in both the drift and the in-sync branch.

Deliberately **not** the alternative the issue also offered (promote the orphan to `[ERROR]`), and
deliberately not a generic *"N info signals"* line either: a repo permanently carries ignore-list
`[INFO]`s — this one has six — so a generic counter would fire at every single session start, which
is the noise PR #99 removed. No orphans means no line at all, and there is a test for that too.

**What this unblocks.** With persona coverage in place the shared check subsumes the repo-local
duplicate, so a consumer can retire its own `lint-plugin-sync.ps1` — the reason #204 was
investigated. Until this reaches a consumer via a release, that duplicate is load-bearing, not
redundant.

The issue's two closing observations (`Resolve-PluginDir`'s cache-based resolution as the reference
behavior, and the `startup`-only hook matcher) were offered as data rather than asks and are left as
they are.

[PR #206](https://github.com/DaveKJohn/davekjohns-workshop/pull/206)

---

#### #205 · SessionStart hooks name the repo a finding is about · Fix · 2026-07-28

Inbound #203 from life-hub. The three SessionStart hooks reported **that** there was drift but not
**where**: they filter their child check's output down to the `[ERROR]` lines, and that filter threw
away the one line naming the inspected repo. On 2026-07-27 that sent an investigation into the wrong
repo — a script-contract alarm about `Get-RosterPath`/`Get-RosterIgnoredIds` that did not reproduce,
against functions that had landed two days *earlier*. The check was right; it was right about a
**different repo** than the session it reported into, and the report had no way to say so.

**The fix is diagnosability, not detection — the checks themselves were sound.** Two mechanisms in
the shared `check-report-lib.ps1`, one per shape of check:

- **`Resolve-CheckRoot` + a `[SCOPE]` line** for a check whose whole run inspects one repo root
  (`check-script-contract`, `check-roster-sync`). Both now delegate their dual-context root
  resolution to that single source and print the resolved root *and how it was resolved*. The
  hooks keep `[SCOPE]` through the `[ERROR]` filter, so a surfaced finding always arrives with its
  repo. Deliberately the root the **check** resolved, not the one the hook assumes it is in: the two
  diverging *is* the failure mode, so printing the hook's own assumption would read just as
  reassuringly and be just as wrong.
- **`Set-CheckScope`** for a check that walks several scopes in one run (`check-connectors`, one
  block per connector). A per-run line cannot disambiguate there, so each finding carries its own
  subject. The label is set per iteration and cleared afterwards, so a run-level notice is never
  attributed to whichever connector the loop happened to end on.

Naming the connector turned out not to be enough, and this repo's own register proved it: the live
session summary showed two **word-for-word identical** `[ERROR]` lines for smartwatchbanden, because
that consumer registers two plugins and both were behind on one outdated install — the
distinguishing `-- plugin:` header being exactly what the filter drops. The label therefore narrows
to `<repo> / <plugin-id>` inside a plugin block. Same defect, one layer deeper.

Two further blind spots in the hooks, from the same issue:

- **A partial drift report used to be indistinguishable from a complete one.** The exit code cannot
  carry that distinction — a complete report *with* findings and a crash halfway both leave a `-File`
  child on a non-zero exit. `Write-CheckSummary`'s `Summary: N error(s)` line is the check's last
  statement, so its absence is the reliable marker; a drift report missing it (or on an unexpected
  exit code) is now flagged as possibly partial. Used only to *qualify* a drift report, never to
  withhold the in-sync line: a check may legitimately exit 0 early without a summary, and turning
  that into "could not complete" would trade one misreport for another.
- **`connector-sessioncheck` printed "signals found -- summary" with an empty list** whenever the
  check exited non-zero without emitting a signal line — a finding that is not there. That case now
  has its own could-not-complete branch, matching the other two hooks.

`Resolve-CheckRoot` also reports a missing `CLAUDE_PROJECT_DIR` explicitly instead of falling back to
the working directory's git root in silence, and returns `$null` rather than letting a caller under
`$ErrorActionPreference = 'Stop'` die on a `.Trim()` of nothing.

**The dual-context invariant moved with the behavior.** `shared-scripts.tests.ps1` asserted that
every shared source matches `CLAUDE_PROJECT_DIR` — which the two sync checks would still have passed
purely on their *comments* after the resolution moved into the lib. It now requires a real call
(inline `$env:CLAUDE_PROJECT_DIR` **or** `Resolve-CheckRoot`), plus an assertion that
`check-report-lib` itself really reads the env var. Otherwise the guard would have quietly stopped
guarding anything.

[PR #205](https://github.com/DaveKJohn/davekjohns-workshop/pull/205)

---

## v2.8.0 — 2026-07-27

### Documentation

#### #199 · A rule that stops a subagent hitting a wall belongs in the agent def too · Docs · 2026-07-27

Two lessons from the same session, both about documentation that was quietly wrong rather than
missing.

**1. The manual-is-leading rule has an exception (Specialists handbook).** The handbook says *"the
manual is leading; the agent def is the executable abbreviation — you change a craft rule in the
manual."* That division assumes the subagent consults its manual at the moment it matters, which
holds for a rule about *what the craft is*: it notices the gap and looks it up. It does not hold for
a rule about *what it will otherwise attempt and fail at* — there it does not know anything is
missing, so it never becomes "in doubt", never opens the manual, and hits the wall instead. Such a
rule now goes in the agent def in compact form **as well as** in the manual in full.

Sylvester #15 (PR #198) is the worked example, recorded with it: his working method opened with
"read before writing, always merge", silently assuming he can write to a permissions file at all.
He cannot — the auto-mode classifier blocks it by design — and he ran into that twice in two
consecutive pieces of work, improvising a recovery mid-task both times. **Fixing only the manual
would have produced a third collision**, which is exactly why #198 touched both files.

**2. Nobody was cleaning up merged branches, and both docs said otherwise.** Seven merged branches
had piled up on the remote unnoticed. Cause: `deleteBranchOnMerge` was **off**, while
`ship-pr.ps1` merges with a plain `gh pr merge --merge` (no `--delete-branch`). So no mechanism was
in force — and the two docs each named a *different* one, which is why the gap survived review:
Derek's persona credited the repo setting, his repo lens credited the `--delete-branch` flag.
Neither claim was true, and **nothing ever errored** — merged branches simply accumulate until
someone reads the branch list.

Fixed at the root: `deleteBranchOnMerge` is now on (Dave's decision, July 27, 2026), which covers
every merge route including the GitHub UI and other machines — not just the script path. Both docs
now describe what actually happens, and both carry the trap that hid this: **`git fetch --prune`
only drops tracking refs for branches already gone from the remote**, so a clean local branch list
is no evidence whatsoever that the remote is clean. Verifying means `git ls-remote --heads origin`.

[PR #199](https://github.com/DaveKJohn/davekjohns-workshop/pull/199)

---

#### #198 · Two permission rules for Sylvester: not agent-editable, never version-pinned · Docs · 2026-07-27

Processes [#196](https://github.com/DaveKJohn/davekjohns-workshop/issues/196) (inbound from
life-hub). Two additions to Sylvester #15, both about permission rules for the plugin's own scripts,
and both holding for every consuming repo — which is why life-hub deliberately placed no bridging
note in its own lens.

**1. A permissions file is never agent-editable.** The existing rule *"Read before write, always
merge — never overwrite"* silently assumed Sylvester can write to `settings.json` /
`settings.local.json`. He cannot: the auto-mode classifier refuses every write, whatever the tool
(both an Edit and a scripted rewrite were blocked). That is correct behaviour — an agent that can
widen its own permissions has stopped being a gate — but because the manual never said so,
Sylvester walked into it, got blocked, and had to improvise a recovery mid-task. Twice in two
consecutive pieces of work. The rule now says: don't attempt the edit, hand over a paste-ready block
(exact lines out, exact lines in) plus the route, then verify by *reading*.

**2. Never pin a plugin-script permission to a version.** Plugin scripts live under
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/...`, so a rule containing the version
number dies at the next release — and it fails as a permission *prompt*, not an error, so it can sit
broken for releases unnoticed. In life-hub two rules had been pinned to `1.18.0` and `2.5.0` while
the plugin had moved to `2.7.3`, which made every `new-branch` and `park` run prompt. **That
friction was actively holding back adoption of the very workflow the plugin had just centralised**
— the skills worked, using them was merely annoying enough to avoid. The rule prescribes the prefix
form, for both the `Bash(...)` and `PowerShell(...)` routes.

**Written into the agent-def as well as the manual, and that is the point.** The subagent reads its
agent-def every run but the manual only "if unsure", so a rule that lives only in the manual does
not stop Sylvester from walking into the wall. Working method step 2 in `agents/05-15-agent.md` held
the exact misconception; it now has both rules beside it in compact form, with the full reasoning in
`manuals/05-15-manual.md`. The `fewer-permission-prompts` mention under "Sylvester is lazy" carries
a warning too, since the skill derives its proposals from concrete transcript paths and therefore
generates precisely the pinned form — the trap is built into the tooling, not a one-off slip.

**Checked in this repo:** no `plugins/cache` rules in its settings at all — the workshop runs its
scripts locally from `scripts/`, not from the plugin cache, so it never had the dead-rule problem.
Nothing to repair here; this is purely a core fix for the consumers.

[PR #198](https://github.com/DaveKJohn/davekjohns-workshop/pull/198)

---

#### #197 · Relax the PR rule: wait only for visible or irreversible work · Docs · 2026-07-27

The rule that a PR only opens on Dave's explicit word was written for a case that no longer occurs:
Dave wanted to look at a frontend change with his own eyes before it went in. In practice the work
here has been tooling, config, dossiers, and agent defs for a long time — none of which he can
meaningfully assess in a few seconds — so nine times out of ten he was rubber-stamping a merge
button that added nothing. **The checkpoint was costing a round trip and buying no safety.**

**The new test is one question: does Dave's own look add something the gates cannot?** Not
"frontend versus backend" — this very change is backend, and it is exactly the kind he *does* want
to see. What matters is whether an automated gate can prove the change is sound.

- **Default — no waiting.** Once a branch is finished, committed, and the gates are green, opening →
  merging → folding runs in one motion, without asking. Scripts, tests, config, manifests, docs,
  agent defs and manuals, the changelog, and research all fall here: the lint gate, the test gate,
  and CI prove them, and anything that slips through is one revert PR away.
- **Exception — stop and report.** Work with a **visible result** (a frontend, styling, rendered
  output, an artifact — no gate proves that something *looks* right) and work that is
  **irreversible or outward-facing** (a release, version bump, tag, repo settings/rulesets,
  publishing outside the PR flow).
- **Dave keeps the wheel in both directions.** He can pull a specific job under the exception when
  he assigns it ("this one I want to see first"), and an explicit PR command still counts as
  approval for the whole movement, so a waiting branch resumes in one move.

The reasoning worth keeping: **substantive approval is given in the conversation before the work is
built, not at the merge button afterwards.** That is why the button is only a checkpoint where it
genuinely buys something.

**Carried through both layers in one pass**, because a half-applied governance rule contradicts
itself. Portable (travels to the consuming repos via a release): the constitution in `CLAUDE.md`
(the permission list plus the "never directly on the main branch" block), Derek's persona
`05-05-persona.md` (his responsibilities and his hard rules), Chris's persona `01-01-persona.md`
(the PR step is no longer automatically a waiting point), the `open-pr` skill (frontmatter
description plus the governance note), the `ship-pr.ps1` docstring, and the inbound-route chain in
the connectors README. Repo lens: Chris's gatekeepers and all four chain descriptions in
`01-01-extension.md`, Derek's branch hygiene in `05-05-extension.md`, and step 4 of the workflow in
`CONTRIBUTING.md`.

**Deliberately left alone:** the `park` and `new-branch` skills say "opens no PR", but that is a
statement about those skills' scope, not an approval rule — unchanged. And the release/version bump
stays firmly on Dave's explicit request; this relaxation touches the merge, never the release.

Decision by Dave, July 27, 2026.

[PR #197](https://github.com/DaveKJohn/davekjohns-workshop/pull/197)

---

## v2.7.2 — 2026-07-26

### Fixes

#### #192 · Correct stale counts, enumerations and a legacy path across lenses and READMEs · Fix · 2026-07-26

A repo-wide documentation audit found eight stale counts, enumerations, and one wrong path, all of
the same kind: the repo grew and the surrounding text did not grow with it. Each was verified
against the actual repo state (agent-def counts, test-file counts, hook registrations, script
signatures) before correcting.

**The two findings that could actually mislead a specialist into a wrong action:** Ravi #24's own
repo lens — his tool for tracking duplicated behavioral rules — named only 4 shared blocks with 3 of
4 counts wrong, when there are 11 shared blocks sourced under `agent-shared/` (`inbound-behaviour`
and `laziness-automation` in all 26 agent defs, `language-behavior` in all but Rebecca's deliberate
local variant, plus `no-conversation-history`, `no-commit-push-pr`, `browser-compatibility`,
`webcontent-boundary`, `changelog-entry-boundary`, `design-owner-boundary`,
`storefront-preview-boundary`, and `artifact-publishing-boundary`) — a sweep against the old text
would have missed seven of them. Chris #01's own repo lens listed the callable-but-unrostered rest of
the `specialists` plugin as four names (Paula, Vera, Gwen, Cody), omitting Auden #30 (the
Academic & Long-form Writer) even though `CLAUDE.md` already counts "those five callable subagents" —
exactly the kind of gap that could make Chris conclude no specialist covers long-form/academic
writing and improvise one, against the rule that new specialists are never invented on his own
initiative.

**Also corrected, lower-stakes but still wrong:** Tycho #18's lens described the test suite as having
"only just begun" with one member, when `scripts/tests/` now holds 15 suites covering nearly
everything Sylvester's lens lists — left as-is, that text would have had Tycho treat well-tested
ground as backlog. Liam's agent-def (`specialists-shopify`) pointed to Gwen's style guide via only
the legacy path `.claude/extensions/04-12-extension.md`, the one cross-reference among all 26 agent
defs that didn't also carry the current plugin path — a consumer that never adopted the legacy layout
would follow it to a file that may not exist. The root `README.md` still said "two" informational
SessionStart hooks, naming only `connector-sessioncheck` and `roster-sessioncheck`, when `hooks.json`
registers a third, `script-contract-sessioncheck` (`CLAUDE.md` already had all three). The family
README undercounted the shared-block circle twice over: "the inbound rule even across all 19" (it's
26, and `laziness-automation` shares that same full reach, so the sentence no longer marked anything
as distinctive), and a "Current blocks" list naming 6 of the 11. Rendall #06's lens listed
`cut-release.ps1` and `fold-changelog-entry.ps1` without their `-SkipLint` and `-RepoRoot` flags
respectively, and the `fold-changelog` skill — which travels to every consumer — likewise omitted
`-RepoRoot`.

**A deliberate judgment call on the two heaviest sections (Ravi's and Tycho's):** rather than
re-hardcoding fresh counts that would only go stale again at the next agent-def or test suite added,
both now name the blocks/suites themselves and point at a live way to re-check the count (a search
over the sentinel, or `Get-ChildItem scripts/tests/*.tests.ps1`) — the same kind of drift this
finding exists to stop from recurring.

**Left alone:** `specialists/scripts/README.md`'s mirrored-script count mismatch is Sylvester #15's
terrain (script/README boundary), not touched here.

[PR #192](https://github.com/DaveKJohn/davekjohns-workshop/pull/192)

---

## v2.6.1 — 2026-07-26

### Documentation

#### #187 · QUICKSTART: new skill from an update needs a session restart · Docs · 2026-07-26

Inbound issue #186 (source: `DaveKJohn/life-hub`) reported that `## Staying up to date` in
`claude-code-plugins/claude-specialists/QUICKSTART.md` only covered the case of an update adding a
new **specialist** (roster + lens catch-up via `sync-roster`) and said nothing about a new
**skill** — after v2.6.0 shipped the `cut-release` skill, `/specialists:cut-release` still did not
appear in the slash list of an already-running session after both `/reload-plugins` and
`/reload-skills`, even though `check-connectors.ps1` confirmed the consumer scope was already on
2.6.0 and the skill layer was demonstrably already reading that cache.

Added a short paragraph to `## Staying up to date` documenting that a new skill only becomes
available after a session restart — neither reload command re-reads the skill set, they only
reload what is already loaded, so a slash command absent from the previous version stays absent
until restart — and that the skill counters those two commands print are not evidence either way,
since they exclude any skill with `disable-model-invocation: true` (`cut-release`, `fold-changelog`,
`open-pr`, `park` in `specialists`), leaving the slash list itself as the only reliable check.

Copy-edit pass (Edith) also caught a real contradiction with
`claude-code-plugins/claude-specialists/specialists/manuals/05-15-manual.md`: its existing reload
note claimed `/reload-plugins` loads plugin content "without a restart" as a general rule, which is
exactly wrong for the new-skill case above. Bounded that claim to where it actually holds (a plugin
being newly registered/enabled, or a locally removed agent-def) and added the same restart
exception, referring back to QUICKSTART's "Staying up to date" section instead of duplicating the
reasoning; its closing note on `CLAUDE.md` imports/settings loading only on a restart is unchanged
and still correct. Also dropped an unsupported `not just for agents` aside from the QUICKSTART
paragraph and unified the terminology on "slash list" between QUICKSTART.md and this entry — the
manual deliberately points back to QUICKSTART's section rather than repeating the term.

[PR #187](https://github.com/DaveKJohn/davekjohns-workshop/pull/187)

---

## v2.6.0 — 2026-07-26

### Features

#### #184 · cut-release skill: the closing-steps checklist, not a mirrored script · Feat · 2026-07-26

Inbound issue #177 (source: `DaveKJohn/djcylow-react`) asked for `cut-release.ps1` as a shared
skill, on the assumption that a shareable version of it exists. It does not: this workshop's own
`scripts/release/cut-release.ps1` is 284 lines of marketplace-specific machinery — it reads
`.claude-plugin/marketplace.json` as the source of truth for what a plugin is, bumps every
`plugin.json` in lockstep, writes per-plugin `CHANGELOG.md` sections and `RELEASE.md` cards, and
fills `releases/README.md` — and dot-sources `scripts/lib/release-lib.ps1`, which is deliberately
not mirrored into the plugin. Mirroring it as-is would have handed a fresh consumer a script that
stops on `.claude-plugin/marketplace.json is missing` on its very first line. Rebecca's research put
three scopes to Dave: mirror a generalized script (a large rebuild of the most sensitive script in
the repo, and more than the issue's real problem needs), add only the config slot without a skill
(leaves the actual forgotten-tag problem unsolved), or codify the closing procedure as a checklist.
Dave picked the recommendation — the checklist.

**What shipped is a checklist, not automation** — the issue's own words: *"not automation, but a
checklist that imposes itself."* The new `cut-release` skill
(`claude-code-plugins/claude-specialists/specialists/skills/cut-release/`) prints the closing steps
of a release as ready-to-paste command blocks, in a fixed order, and mirrors no script:

- **Block 1 — cutting (always):** the annotated tag + push, a `gh release create` +
  `gh release upload` for a Minor/Major bump, and branch cleanup.
- **Block 2 — going live (only where applicable):** the push to the live target, then moving the
  `<- LIVE` marker. Driven by a new optional `Get-LiveStage` in `scripts/repo-config.ps1` (empty by
  default, so this workshop and life-hub get Block 1 only) — the same optional pattern
  `Get-ChangelogHeading` established for #178, added to the `specialists-init` bootstrap scaffold and
  declared in `check-script-contract.ps1` as an `Optional` record, so a consumer without the function
  gets `[INFO]` naming the fallback, never `[ERROR]`.

Bakes in life-hub's hard-won split: the **highlights** become the GitHub Release body, the full
development notes go along as an **attachment** — at life-hub's v2.1.0 the notes were 134,419
characters and `gh` returned HTTP 422 (the release-notes body limit is 125,000 characters). The
skill prescribes that split explicitly so no consumer trips over it again.

[PR #184](https://github.com/DaveKJohn/davekjohns-workshop/pull/184)

### Fixes

#### #185 · Roster token scan no longer reads ISO dates as specialist ids · Fix · 2026-07-26

Inbound issue #182 (source: `DaveKJohn/life-hub`) reported that `check-roster-sync.ps1`'s
orphan-scan reads an ISO date in roster prose as a specialist id: in `2026-07-25` the `07` is
preceded by a hyphen, and the old boundary (`(?<!\d)...(?!\d)`) only excluded a preceding *digit*,
so `07-25` matched and was reported as `[INFO] orphan '07-25' -- no matching agent/persona`. Every
ISO date with a day 01-31 triggers this in any consuming repo that dates its documentation notes --
the normal way to write them.

Verification while fixing this turned up the same boundary duplicated in `Test-InRoster`, with a
more serious consequence: where the orphan-scan only adds `[INFO]` noise, `Test-InRoster` decides
whether a specialist has a roster row at all. A false match there is a missed `[ERROR]` -- a
specialist that has actually been removed from the roster reads as "present" as long as the text
contains a date that happens to look like their id. Concretely reproduced: a roster with no row for
Sylvester (05-15), containing only the prose date `2026-05-15`, made the old `Test-InRoster` return
`True`. The groups this system uses (02 through 06) are exactly the month range covered by everyday
dates, so this was a real, not theoretical, gap -- `2026-05-15` masks Sylvester, `2026-06-16` masks
Tessa, `2026-06-17` masks Edith, and so on.

**Fix:** tightened the leading boundary to also exclude a preceding hyphen
(`(?<![\d-])\d{2}-\d{2}(?!\d)`), as issue #182's option 1 proposed, but implemented as **one shared
source** instead of two separately-tightened regexes -- a new `Get-RosterIdTokenPattern` in
`scripts/lib/check-report-lib.ps1` (optionally parameterized with a specific id), which both
`Test-InRoster` and the orphan-scan's `[regex]::Matches` now call. That single source is the point
of this fix: the bug existed on two call sites in the first place because the same lookaround was
duplicated instead of shared, so a one-sided fix would have left the door open to the same drift
recurring.

The trailing boundary deliberately stays `(?!\d)`, not tightened to `(?![\d-])`: a real lens
reference is immediately followed by a hyphen (`05-15-extension.md`), so excluding a trailing hyphen
too would break that legitimate case. Verified both directions before and after the change (ISO
dates no longer match, `06-24`/`05-15` inside real references still do).

Deliberately **not** done: issue #182's option 2 (binding the token to a roster-row/table shape).
`Test-InRoster` is asked about a specific id in free prose, and consuming repos are free to format
their roster differently (table or list, per `Get-RosterPath`'s own doc note); binding the match to
a table shape would change behavior for those consumers -- a bigger risk than the residual noise
this leaves.

**Known limitation (not silently closed):** this narrows the ISO-date case specifically, but does
not cover every prose false positive. Issue #182 itself named a version range like `1.2-3.4` as the
example, but that example is wrong -- verified against the actual pattern, `1.2-3.4` does not match
at all (`\d{2}` needs two-digit segments, and `1`/`2`/`3`/`4` are single digits). The real residual
case is a plain two-digit number range in ordinary prose, e.g. "see pages 12-34" or "a range of
10-20 items" -- verified those do match. That only surfaces as a visible `[INFO] orphan '12-34'`
line as long as no real specialist happens to share that id; it never escalates to `[ERROR]`.
Accepted as documented residual risk.

Mirror rebuilt (`scripts/sync/build-shared-scripts.ps1`) so
`claude-code-plugins/claude-specialists/specialists/scripts/{lib/check-report-lib.ps1,sync/check-roster-sync.ps1}`
stay byte-identical to the root copies.

[PR #185](https://github.com/DaveKJohn/davekjohns-workshop/pull/185)

---

#### #183 · fold-changelog folds into a configurable section heading · Fix · 2026-07-25

`fold-changelog-entry.ps1` hardcoded the section it folds into (`## Pull Requests`) and the section
boundary below it (`## Releases`). A consumer whose changelog uses a different heading got a hard
stop before anything was touched — and `repo-config.ps1` had no slot to say otherwise. In
`djcylow-react` (Keep-a-Changelog: `## [Unreleased]` with released versions as `## [vX.Y.Z]` below
it) the skill simply could not run: five entries were folded by hand there today, each one a chance
to get the merge date, the newest-first ordering or the BOM-less write subtly wrong.

**`Get-ChangelogHeading`, optional and defaulted.** New in `scripts/repo-config.ps1` (and in the
`specialists-init` scaffold, so a fresh consumer gets it): the literal heading line the fold inserts
under, `'## Pull Requests'` by default. `fold-changelog-entry.ps1` reads it through a `Get-Command`
guard exactly the way `open-pr.ps1` handles its optional repo-config functions, so **every existing
consumer keeps working unchanged** — a repo-config that predates this contract simply gets the
default. The not-found message now names both the heading it looked for and the function to set.

**The section boundary is derived, not hardcoded.** The insert position used to be "before the first
`###` entry, or else before `## Releases`". On a Keep-a-Changelog file that second literal does not
exist, so the entry would have landed at the end of the file rather than at the top of
`[Unreleased]`. The boundary is now structural — whichever comes first after the heading, the first
`###` already in the section or the next `##` section — which reproduces the old behaviour exactly
in this workshop and is correct on Keep-a-Changelog too.

**Declared in the script contract as an INFO signal.** `check-script-contract.ps1` gains an
`Optional = $true` record type: a missing optional function reports `[INFO]` naming the fallback
instead of `[ERROR]`, so it never turns a working consumer red — but a Keep-a-Changelog consumer is
told about it before fold time rather than discovering it at fold time.

**Bug found while testing.** The first implementation named its local variable `$changelogHeading`
while `repo-config.ps1` backs the function with `$script:ChangelogHeading`. PowerShell variable
names are case-insensitive and at script top-level the local and script scopes are the same, so the
default assignment silently overwrote the dot-sourced value and the configured heading always read
back as `## Pull Requests`. Renamed to `$foldHeading`, with the reasoning recorded at the call site
— a sibling of the `$RepoRoot`/`$repoRoot` collision already documented in this script.

Covered by `scripts/tests/fold-changelog.tests.ps1` (a Keep-a-Changelog fixture: folds, and lands
below `[Unreleased]` and above the released section; a heading that is not found stops cleanly with
the entry file intact; a repo-config without the function still folds under the default) and
`scripts/tests/script-contract.tests.ps1` (the optional record reports INFO, exit 0). From inbound
issue #178 (source: DaveKJohn/djcylow-react).

[PR #183](https://github.com/DaveKJohn/davekjohns-workshop/pull/183)

---

#### #180 · Lens path: the family segment is a constant, and every reader shares it · Fix · 2026-07-25

`specialists-init` and the roster check disagreed about **where a repo lens lives**: one wrote a
derived path, the other read a hardcoded one, and they only lined up by coincidence.
`bootstrap.ps1` derived the family segment from the install path, which in the plugin-cache layout
(`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`) yields the **marketplace name** — so a
repo installed through `specialists@davekjohns-workshop` got its lenses in
`.claude/plugins/davekjohns-workshop/specialists/`, where `check-roster-sync.ps1` never looked. In
`djcylow-react` that produced **30 errors of which 24 were false**: 12 perfectly good lenses, each
counted twice (missing lens + missing roster row). Worse than a plain miss — the fix the report
suggested would have left the repo with two copies of every lens on two paths, with the `@`-import
in `CLAUDE.md` still pointing at the wrong one.

**One source, used by writers and readers alike.** `scripts/lib/check-report-lib.ps1` (mirrored into
the plugin) gains two helpers:

- **`Get-LensFamily`** — the family segment as a **constant** (`claude-specialists`). It is a
  property of the plugin family, not of the marketplace the plugin was fetched from, so it is no
  longer derived from anything. The writers use it: `bootstrap.ps1` (both the lens path and the
  `@`-import it writes into `CLAUDE.md`) and `sync-roster.ps1`.
- **`Get-LensDirCandidates`** — the ordered locations a lens may be read from: the canonical path
  first, then any other family segment a pre-fix bootstrap left behind, then the legacy
  `.claude/extensions/`. Every reader now walks that list: `check-roster-sync.ps1`,
  `check-connectors.ps1`, and `check-consumer-drift.ps1` — the last two carried the same hardcoded
  segment and therefore the same false-missing bug.

Consequence: **no migration needed.** A consumer bootstrapped before this fix keeps working — its
lenses are found and counted as present, and the check adds one soft `[INFO]` per directory (not per
lens) pointing at the misalignment. `sync-roster` additionally refuses to write a scaffold when a
lens for that id already exists on a non-canonical path, so it can never produce the second copy.

Covered by regression tests in `scripts/tests/roster-sync.tests.ps1` (scenario 9b: off-path lenses
are found, no false `[ERROR]`, exactly one `[INFO]` per directory) and
`scripts/tests/bootstrap-drift.tests.ps1` (the version-cache scenario now asserts the canonical path,
no lenses under the marketplace name, and a canonical `@`-import). From inbound issue #179 (source:
DaveKJohn/djcylow-react).

[PR #180](https://github.com/DaveKJohn/davekjohns-workshop/pull/180)

---

## v2.5.0 — 2026-07-24

### Features

#### #176 · Shared park-branch script + skill · Feat · 2026-07-24

Add a shared **`park-branch`** step to the centralized branch-workflow layer (issue #81), alongside
`new-branch` and `open-pr`, so consumers do not duplicate it. New script
`scripts/task/park-branch.ps1` + `park` skill: commit **all** outstanding work on the current branch
(`git add -A` + commit) and `git push -u origin <branch>`, so the exact state is immediately
continuable on another device. Guardrails: refuses on `main`, opens **no PR**, does **no live/deploy
action** (git only). Self-contained — depends only on `git` and the shared `native-capture` helper,
so it needs no repo-owned config. Optional `-Intent` records where you left off in the park commit
message. Distinct from `new-branch -Park` (which parks at creation and commits only the changelog
entry): `park-branch` parks an existing branch mid-work and commits everything.

Registered in the shared-scripts registry (mirror generated), covered by
`scripts/tests/park-branch.tests.ps1`, and documented in Derek's lens, the plugin scripts README, and
the family README. From inbound issue #175 (source: BWJ-ecommerce/smartwatchbanden).

[PR #176](https://github.com/DaveKJohn/davekjohns-workshop/pull/176)

---

## v2.4.0 — 2026-07-24

### Features

#### #173 · THESIS.md convention for Auden · Feat · 2026-07-24

Establish `THESIS.md` as the conventional filename for Auden's (#30) formal, structured long-form
deliverable — the academic/thesis-style piece, as distinct from a folder's short navigational
README. A stable, recognizable name makes the output read the same across repos and lets consuming
tooling/viewers key off the filename instead of an ad-hoc one. Documented in Auden's portable manual
(`manuals/06-30-manual.md`) and his agent-def working method (`agents/06-30-agent.md`). From inbound
issue #171 (source: DaveKJohn/life-hub).

[PR #173](https://github.com/DaveKJohn/davekjohns-workshop/pull/173)

---

#### #172 · Worktree parallel-PR pattern for Derek · Feat · 2026-07-24

Document in Derek's portable persona (`personas/05-05-persona.md`) the pattern for running a second
branch's full PR movement (open → merge → fold → cleanup) in an isolated `git worktree` while a
subagent is still editing the primary working tree — instead of switching the busy tree's branch out
from under it. Captures the two gotchas found in practice: keep the worktree path short (Windows
`MAX_PATH`), and fall back to `git branch -D` after verifying the merge with `git merge-base
--is-ancestor` when a pruned upstream makes `branch -d` refuse. From inbound issue #171 (source:
DaveKJohn/life-hub).

[PR #172](https://github.com/DaveKJohn/davekjohns-workshop/pull/172)

---

## v2.3.0 — 2026-07-24

### Features

#### #170 · Add Auden #30 -- academic/long-form content author · Feat · 2026-07-24

New specialist in the shared `specialists` plugin, resolving inbound issue #169 (raised from
life-hub): **Auden 🖋️ #30, the Academic & Long-form Writer.** He fills the gap between research and
editing — the actual *authoring* of long, structured, argued, sourced content: subject-matter
documentation and academic/thesis-style pieces.

Chain: the research specialist gathers and cites the material → **Auden authors the piece** → the
copy editor polishes → follow-up places it. Distinct from the technical writer (governance/meta-docs,
not subject-matter content), the research specialist (gathers sources, does not author the finished
piece), and the copy editor (polishes, does not author).

- **Stable id 30, group 06.** Built as a subagent (agent-def + manual); tools
  `Read, Write, Edit, Grep, Glob, Skill` (an author needs write/edit; research stays with Rebecca).
  Reuses the shared boundary blocks, including the two just globalized into `agent-shared/`
  (`no-conversation-history`, `no-commit-push-pr`).
- New files: `agents/06-30-agent.md`, `manuals/06-30-manual.md` (plugin source).
- **No workshop repo lens** (yet): like Paula/Vera/Gwen/Cody, Auden's work lives in consuming repos
  (life-hub), not in this maintenance repo, so per the house convention he is listed as "also
  enabled, rarely has work here" rather than given a contrived empty lens. Added to that note in
  `CLAUDE.md` and the handbook README, and to the family README manual inventory.
- Never invents facts/quotes/citations — a missing source is flagged back to the researcher.

[PR #170](https://github.com/DaveKJohn/davekjohns-workshop/pull/170)

---

## v2.2.1 — 2026-07-24

### Maintenance

#### #168 · Globalize two verbatim-shared boundary rules into agent-shared/ · Chore · 2026-07-24

DRY cleanup (Ravi): two boundary bullets that were word-for-word identical across many `specialists`
agent-defs now live in a single shared source each and are filled in by `build-agent-defs.ps1` via
the existing shared-block mechanism. The rendered agent-def text is unchanged (generator `-Check`
in sync) — only the sentinel comments are added; no behavioral change.

- New sources: `agent-shared/no-conversation-history.md` (wrapped in 14 defs) and
  `agent-shared/no-commit-push-pr.md` (wrapped in the 10 defs carrying the exact wording).
- Deliberately left alone: the shorter no-PR-clause variant (02-09, 06-16) and the
  production-environment tail variants (04-11, 04-12) — legitimate role nuances, not duplication.
  The lifehub/shopify/ecomm plugins use a differently-worded conversation-history variant and were
  not touched (verbatim-only promotion).
- One incidental normalization: 06-24's PR bullet was on a single line; it now matches the
  canonical two-line wrap of the other nine — same wording.

Generator `-Check`, the lint gate, and all test suites are green.

[PR #168](https://github.com/DaveKJohn/davekjohns-workshop/pull/168)

---

## v2.2.0 — 2026-07-24

### Features

#### #166 · Add Marlowe #29 -- adversarial conclusion reviewer (investigative journalist / watchdog) · Feat · 2026-07-24

New specialist in the shared `specialists` plugin (flows back to every consumer via a release):
**Marlowe 🕵️ #29, the Investigative Journalist / consumer watchdog** — the independent devil's
advocate on the *substance and conclusions* of the team's work.

Where Victor #19 (correctness), Edith #17 (language), and Sebastian #23 (security) review the
**craft**, Marlowe reviews the **conclusion itself**: before anyone acts on a recommendation, he
tries to tear it down — the fine print / the catch, the load-bearing assumption, and real-world
contradicting evidence (customer experiences, complaints, regulator warnings) versus the sales
pitch. His distinct value versus the researcher (Rebecca #07): Rebecca builds the case, Marlowe is
adversarial by mandate and red-teams a case that already exists. Delivers a critical counter-report
with an explicit verdict (HOLDS / WOBBLES / FALLS); read-only in spirit — reviews, does not rewrite,
fixes nothing, commits nothing, opens no PRs.

- **Stable id 29, group 06** (reviewer group). Built as a subagent (agent-def + manual), matching
  the other pre-PR reviewers; no persona file (personas exist only for the main-loop specialists).
  Tools: `Read, Grep, Glob, WebSearch, WebFetch, Skill` (the research/reviewer profile) -- no
  write/edit, no git.
- New files: `agents/06-29-agent.md`, `manuals/06-29-manual.md` (plugin source),
  `.claude/plugins/claude-specialists/specialists/06-29-extension.md` (repo lens).
- Roster updated everywhere: `CLAUDE.md` (roster table), Chris's lens `01-01-extension.md` (routing
  table + the pre-PR quality-check chain), the handbook README (name list, group-06 tree, id table),
  and the family README manual inventory. Registered `06-29` in the connector manifest.
- Housekeeping alongside: added the pre-existing missing `06-25` (Nolan) to the connector manifest
  and to the family README manual inventory, so both are accurate again.

[PR #166](https://github.com/DaveKJohn/davekjohns-workshop/pull/166)

### Fixes

#### #167 · fold-changelog: only fold real changelog-entry files, not root meta docs · Fix · 2026-07-24

**Bug:** in fold-all mode (`fold-changelog-entry.ps1` without `-Branch`) any root `*.md` that was not
in a tiny denylist (`CHANGELOG.md`/`CLAUDE.md`/`README.md`) was treated as a changelog entry — so
the repo-meta files `CONTRIBUTING.md` and `SECURITY.md` (added later) got folded into `CHANGELOG.md`
and then removed. Caught and reverted during the Marlowe fold; nothing shipped.

**Fix:** add a positive, structural gate. A changelog entry always opens with the compact
`### <title> · <type> · <date>` H3 heading (the fold code already relies on that `###` line);
repo-root meta docs open with an H1. Fold-all now folds a file only if its first non-empty line is
that H3 heading, so meta docs are never folded. Deliberately independent of the branch-prefix table,
so consumer-extended prefixes (Shopify's `style/`, `liquid/`, …) still fold. `-Branch` mode is
unchanged (it targets exactly the named entry).

- `scripts/release/fold-changelog-entry.ps1`: new `Test-IsChangelogEntryFile` helper + the fold-all
  filter; header doc updated. Plugin mirror re-synced byte-identical via `build-shared-scripts.ps1`.
- New regression suite `scripts/tests/fold-changelog.tests.ps1` (17 asserts): meta docs survive, a
  genuine entry folds, an extended-prefix entry still folds, a hyphen-named H1 doc is not folded,
  and `-Branch` mode is unaffected.

[PR #167](https://github.com/DaveKJohn/davekjohns-workshop/pull/167)

---

## v2.1.0 — 2026-07-23

### Features

#### #164 · Park move (intent + push) and portable post-merge branch cleanup · Feat · 2026-07-23

Two inbound improvements to the shared branch lifecycle, landing in the source (closes #162 and #163).

**#162 — parking a branch (intent + push, no PR).** `new-changelog-entry.ps1` gains an optional
`-Intent`; when given it becomes the recorded entry body, and when omitted the body now falls back
to a directional block (`**To do / where I left off:**` + a prompting TODO) instead of a bare
one-line TODO — so a forgotten intent still leaves a "what is next / where was I" prompt. `new-branch.ps1`
gains `-Intent` (passed to the child via `CLAUDE_NEWBRANCH_INTENT`, the same injection-safe env-var
handoff as `-Title`) and an opt-in `-Park` switch that commits the entry and pushes the branch to
`origin` with `git push -u` — **no PR** (push is not a PR; the PR rule stays intact and separate).
The push reuses the shared `Invoke-NativeCapture` helper (the `#107` stderr guard). The default
path is unchanged: without `-Park` nothing is committed or pushed.

**#163 — post-merge branch cleanup as a fixed closing step.** Documented in the portable layer: the
`fold-changelog` skill (the last chain step) now names the local cleanup — `git fetch --prune` +
`git branch -d <branch>`, with the remote handled by the repo's auto-delete-on-merge setting — as a
fixed closing step (the canonical exact commands live there); Derek's portable persona body and repo
lens cross-reference that rule, and the `specialists-init` setup checklist tells a new consumer to
enable `deleteBranchOnMerge`.

Regression tests for `-Intent`, the directional fallback, and `-Park` (branch pushed to a bare
`origin`, entry committed, upstream set, no PR) added to `scripts/tests/new-branch.tests.ps1`; the
plugin mirrors were regenerated from the canonical source.

[PR #164](https://github.com/DaveKJohn/davekjohns-workshop/pull/164)

---

## v2.0.2 — 2026-07-23

### Maintenance

#### #157 · Skill/script hygiene: fold-changelog invocation, forward-slash paths, magic-number comment · Chore · 2026-07-23

Applies the three nice-to-haves from Sylvester's own skill audit. `fold-changelog`'s `SKILL.md`
(`claude-code-plugins/claude-specialists/specialists/skills/fold-changelog/SKILL.md`) gets
`disable-model-invocation: true` in its frontmatter, mirroring the `open-pr` pattern from PR #155:
folding commits directly to `main` (the fold exception), and Rendall's own manual already documents
it as a direct `fold-changelog-entry.ps1` call, never a Skill-tool invocation -- so the flag closes
the autonomous-invocation surface without touching the actual fold mechanism.

The bundled scripts `specialists-init/bootstrap.ps1` and `sync-roster/sync-roster.ps1` get their
backslash path literals (`Join-Path` arguments, the script-scaffold `Rel` table, one VUL-IN comment
example) replaced with forward slashes, so a path stays valid if a consumer ever runs these on
non-Windows pwsh. Regex/string-parsing logic that relies on backslash (segment splitting, the
`@-import` normalization) is left untouched, as is the one Windows-style path in the `.EXAMPLE` doc
comment (a user-typed CLI argument, not a script path literal).

`sync-roster.ps1`'s 160-character cap on a proposed roster description now carries an inline
comment explaining the number: it keeps the proposed table/list row on one line for the human to
paste. No behavior change.

Verified: `check-plugin-integrity.ps1` stays green (0 errors), and both `bootstrap-drift.tests.ps1`
and `sync-roster.tests.ps1` (90 asserts, including the git-remote-derivation and idempotency cases
most sensitive to path changes) pass unchanged, alongside the shared-script/open-pr/fold-changelog
suites (104 asserts).

[PR #157](https://github.com/DaveKJohn/davekjohns-workshop/pull/157)

---

#### #155 · Harden open-pr invocation control and fix sync-roster description person · Chore · 2026-07-23

Applies the two must-fixes from Sylvester's own skill audit. `open-pr`'s `SKILL.md`
(`claude-code-plugins/claude-specialists/specialists/skills/open-pr/SKILL.md`) gets
`disable-model-invocation: true` in its frontmatter, removing the autonomous Skill-tool invocation
surface in support of the constitution rule that a PR is only opened on Dave's explicit word — the
same pattern `start-task` already uses in the Shopify family. Note this only closes the Skill-tool
path; a direct Bash call to `scripts/release/open-pr.ps1` or the plugin mirror is not gated by this
field, so the actual guarantee remains the CLAUDE.md constitution rule plus branch discipline.

`sync-roster`'s `SKILL.md`
(`claude-code-plugins/claude-specialists/specialists/skills/sync-roster/SKILL.md`) gets its
description rewritten from second person ("for you to paste", "you want ... done for you") to third
person, same content, matching the style of every other skill description. Verified: the lint gate
(`check-plugin-integrity.ps1`) accepts the new field with no findings, and neither description is
duplicated elsewhere in the repo (plugin.json, generated mirrors, or drift-lint fixtures).

[PR #155](https://github.com/DaveKJohn/davekjohns-workshop/pull/155)

---

#### #154 · Flatten release notes into per-major folders · Chore · 2026-07-23

Flattens the release-notes layout from per-minor folders
(`releases/development/<X.Y>/<X.Y.Z>.md`) to one folder per major
(`releases/development/<X>.x/<X.Y.Z>.md`) — so all 1.x notes now live in `1.x/` and all 2.x notes
in `2.x/`, matching the per-major grouping already applied to the overview table (#152). The 27
existing 1.x notes and the two 2.x notes were moved via `git mv` (renames preserved); the empty
minor folders are gone.

Because the depth is unchanged (a single `<X>.x` folder replaces the single `<X.Y>` folder), the
root-relative links inside the notes (`../../../`) keep resolving — no note body was touched.
Updated: `cut-release.ps1` + `release-lib.ps1` now derive `<major>.x` (was `<major>.<minor>`); the
29 note-path links in `releases/README.md` + the `## Releases` block in `CHANGELOG.md`, the four
per-plugin `RELEASE.md` cards, the descriptive `<X.Y>` references in `README.md`/`05-06-extension.md`,
and the `release-lib` test's expected paths. Git tags (`vX.Y.Z`) are unaffected — they point to
commits, not paths. Archived note bodies keep their original (historical, sometimes Dutch) path
mentions on purpose. Lint gate green (dead-link scan clean); all test suites pass.

[PR #154](https://github.com/DaveKJohn/davekjohns-workshop/pull/154)

---

## v2.0.0 — 2026-07-23

### Features

#### #148 · Script-contract drift check for repo-owned lib helpers (inbound #147) · Feat · 2026-07-22

Adds a detection layer for the repo-owned script contract, closing inbound #147 from life-hub. The
shared, mirrored workflow scripts (`new-branch`/`new-changelog-entry`/`open-pr`/`fold-changelog-entry`/
`check-roster-sync`, issue #81) dot-source **repo-owned** libs from the consumer
(`scripts/lib/branch-info.ps1`, `scripts/repo-config.ps1`), but nothing signalled when those libs
lagged the function contract the shared scripts call at runtime. The real incident: after updating
the plugin v1.12.1 → v1.18.0, the first `new-branch` run crashed with
`The term 'Test-BranchName' is not recognized` — the consumer's `branch-info.ps1` predated that
helper, and the gap stayed invisible until the flow broke. There was a roster-drift guard
(`check-roster-sync` + `roster-sessioncheck`) but no equivalent for the script contract; this mirrors
that architecture exactly.

- **New local check `scripts/sync/check-script-contract.ps1`.** Declares the mandatory
  repo-owned functions per mirrored, consumer-run shared script (`Get-BranchInfo`/`Test-BranchName`
  from `branch-info.ps1`; `Get-RepoName`/`Get-LintScript`/`Get-RosterPath`/`Get-RosterIgnoredIds` from
  `repo-config.ps1`), dot-sources the consumer's copy and asserts each is defined via `Get-Command`,
  reporting a missing one as `[ERROR]` that names the function, its lib, and the shared script(s) that
  call it. Read-only, dual-context repo root, shared `[OK]/[INFO]/[ERROR]` helpers from
  `check-report-lib.ps1`. The consumer libs are dot-sourced in a child scope with StrictMode OFF, to
  match how the real (non-strict) workflow scripts load them — so harmless pre-strict-mode loose
  top-level code in an older consumer's lib does not trip a false `[ERROR]`. The optional `Get-Pr*`
  functions `open-pr.ps1` guards via `Get-Command` are
  deliberately out of the contract (a consumer without them is not drifted); workshop-only scripts
  (`ship-pr.ps1`/`cut-release.ps1`) are out of scope (not mirrored). Registered as a mirrored pair in
  `shared-scripts-lib.ps1` and generated into the plugin via `build-shared-scripts.ps1`.
- **New SessionStart hook `script-contract-sessioncheck.ps1`.** A structural twin of
  `roster-sessioncheck.ps1`: runs the mirrored check silently, surfaces only `[ERROR]` lines into the
  session context, always exits 0. Added as a third SessionStart hook in the plugin's `hooks.json`
  alongside the connector and roster checks (both untouched). This turns the class of runtime crash
  behind #147 into an actionable heads-up right after a plugin update.
- **Tests (`scripts/tests/script-contract.tests.ps1`, 87 asserts).** Happy path, the exact #147
  missing-`Test-BranchName` case, a missing `repo-config` function, an entirely missing lib file, a lib
  that throws on load, and proof the optional `Get-Pr*` functions are never flagged; plus a two-layer
  contract-completeness drift guard (the declared contract still lists the exact six pairs, and each
  declared function still literally appears in its shared script's real source, so a stale entry is
  caught).

Verified: `build-shared-scripts.ps1 -Check` in sync, `check-plugin-integrity.ps1` 0 errors, and all
11 test suites green.

[PR #148](https://github.com/DaveKJohn/davekjohns-workshop/pull/148)

### Fixes

#### #149 · Load repo-config without StrictMode in check-roster-sync (sibling of #147) · Fix · 2026-07-22

Fixes the same strict-mode false-positive in `scripts/sync/check-roster-sync.ps1` that #147/#148 fixed
in `check-script-contract.ps1`. The roster check runs under `Set-StrictMode -Version Latest` +
`$ErrorActionPreference = 'Stop'` and dot-sourced the consumer's `scripts/repo-config.ps1` directly in
that strict scope to read `Get-RosterPath`/`Get-RosterIgnoredIds`. But `repo-config.ps1` is explicitly
written on the no-strict-mode assumption (the real runtime callers never enable StrictMode), so a
consumer copy carrying harmless pre-strict-mode loose top-level code (e.g. an `if` on an unset
variable) threw at the dot-source — and because EAP is `Stop`, that terminated the whole roster check,
making the `roster-sessioncheck` hook report "could not complete" at every session start, for exactly
the older consumer repos the check serves.

- **Strict-off child-scope load.** `repo-config.ps1` is now dot-sourced and probed in a child scope
  with `Set-StrictMode -Off` (the same idiom as the `check-script-contract.ps1` fix), so it matches how
  the real workflow scripts load it and harmless loose top-level code no longer trips it. The resolved
  `Get-RosterPath`/`Get-RosterIgnoredIds` values replace the defaults exactly as before; absent
  `repo-config.ps1` keeps the sane defaults untouched.
- **Genuine load failure degrades gracefully.** A real load error (e.g. a syntax error, not just
  strict-mode noise) now falls back to the sane defaults (`CLAUDE.md`, no ignored ids) with a
  non-blocking `Write-Info`, instead of crashing the whole check — consistent with this check's
  documented "sane default, does not hard-require repo-config" stance.
- **Regression test** (`roster-sync.tests.ps1`, scenario 14): a consumer `repo-config.ps1` defining the
  roster functions plus loose top-level code referencing an unset variable — the check now runs clean
  (exit 0), honors `Get-RosterPath`, and surfaces no strict-mode exception. Verified non-vacuous
  (reverting the fix makes it fail).

`check-roster-sync.ps1` is a mirrored shared script; the plugin mirror was regenerated via
`build-shared-scripts.ps1`. Verified: `build-shared-scripts.ps1 -Check` in sync,
`check-plugin-integrity.ps1` 0 errors, and all 11 test suites green (roster-sync at 58 asserts).

[PR #149](https://github.com/DaveKJohn/davekjohns-workshop/pull/149)

### Documentation

#### #150 · Record the StrictMode-off rule for dot-sourcing consumer libs (Sylvester lens) · Docs · 2026-07-22

Records the lesson behind #148/#149 as a durable rule in Sylvester #15's repo lens
(`.claude/plugins/claude-specialists/specialists/05-15-extension.md`), so the next check or hook that
dot-sources a consumer's repo-owned lib gets it right by design instead of rediscovering it at
runtime. Added in the "Repo-specific rules" section as a third rule of that kind, joining its two
sibling native-command rules (the `$LASTEXITCODE`-before-pipe rule and the stderr-under-`Stop` rule):

- **The rule:** a check/hook that dot-sources `branch-info.ps1`/`repo-config.ps1` to probe it must do
  so in a child scope with `Set-StrictMode -Off`, because the real workflow scripts that consume those
  libs never enable StrictMode and the libs are written on that assumption. Loading under strict mode
  makes harmless pre-strict-mode loose top-level code throw — a false `[ERROR]`, or a full crash under
  `$ErrorActionPreference = 'Stop'` — at every session start, for exactly the older consumer repos the
  checks serve. A genuine load failure should degrade gracefully, not abort the check.

Doc-only; no script or config change (the two fixes themselves shipped in #148/#149).

[PR #150](https://github.com/DaveKJohn/davekjohns-workshop/pull/150)

---

## v1.18.0 — 2026-07-22

### Features

#### #146 · Rename-proof lens scaffold (nameless header + propose-only reconcile) · Feat · 2026-07-22

Made a persona rename stop forcing manual header fixes in every consumer (inbound #145).

- **Nameless generated lens header.** Both scaffold generators (`sync-roster.ps1`'s `New-LensScaffold`
  and `specialists-init`'s `bootstrap.ps1`) now write the stable `# <group>-<id> · repo-lens` slug
  instead of baking the persona's first name into the header + intro. The name now lives in exactly
  one place — the agent-def's `name:` frontmatter — so a later rename can never drift a generated
  header again.
- **Propose-only header reconcile.** `check-roster-sync.ps1` detects an existing lens whose header
  still carries a stale scaffold name (`# Sean · repo-lens` after the agent became Sebastian) and
  reports it as a non-blocking `[INFO]` (silent at session start, shown on a deliberate run). The
  `sync-roster` skill parses that and prints the rename-proof, nameless replacement header to paste —
  it never rewrites the lens file, matching its propose-only stance for roster rows. Hand-customized
  headers (no `· repo-lens` tail) are never touched.
- **`Get-DisplayName` centralized** into the shared `check-report-lib.ps1` (was duplicated across
  `sync-roster.ps1` and `bootstrap.ps1`), now the single source for both the roster-row proposal and
  the header-drift comparison.
- Tests extended: nameless-scaffold assertions + stale-header detection/reconcile coverage across
  `roster-sync`, `sync-roster`, and `bootstrap-drift`.

Out of scope (noted): the persona-lens title copy in `bootstrap.ps1` (which snapshots the plugin
persona's canonical heading) still carries a name; the roster table + routing rule in a consumer's
`CLAUDE.md` remain repo-owned governance.

[PR #146](https://github.com/DaveKJohn/davekjohns-workshop/pull/146)

---

## v1.17.0 — 2026-07-22

### Features

#### #143 · New specialists-ecomm plugin with three e-commerce specialists (SEO, CRO, SEA) · Feat · 2026-07-22

New fourth domain group — the plugin `specialists-ecomm`, for commercial webshop repos of any
platform (not Shopify-only) — with its first three specialists, all group 06 (the
measure-and-optimize family):

- **Sergio 📈 #26 — SEO Specialist.** Technical/on-site SEO: anchor links and internal linking,
  canonical tags, structured data (schema.org/JSON-LD), XML sitemaps, and pagespeed. Auditor and
  builder: measure first, fix at the source, validate, white-hat only.
- **Craig 🎯 #27 — CRO Specialist.** Conversion Rate Optimization: funnel/drop-off analysis, A/B
  experiments, checkout and landing-page optimization. Test, don't guess — keep only what a measured
  experiment proves.
- **Sean 💸 #28 — Performance / SEA Specialist.** The paid side of acquisition and its in-repo
  footprint: conversion tracking, product feeds, UTM conventions, ad-to-landing-page alignment.
  Honest about the boundary that live campaigns live in the ad platforms, and coordinates with
  Sergio so paid doesn't cannibalize organic.

All three carry the standard shared blocks (inbound-behaviour, laziness-automation,
language-behavior), defer visual/front-end changes to the design owner, and defer any preview/live
push to the platform's store owner.

**Rename to free the name for the SEA pun:** the existing Security Engineer **Sean 🛡️ #23** is
renamed to **Sebastian** (keeps 🛡️, #23, and its call name changes `@specialists:sean` →
`@specialists:sebastian`), so the new SEA specialist can be "Sean". Updated across the living
team-definition surfaces — the #23 agent def, manual, and repo lens; the roster in `CLAUDE.md`; the
family handbook; Chris's routing/chains lens; and the cross-references in the Ravi/Victor/Edith
lenses; plus the group-1 listing in `README.md`. History (CHANGELOG/releases, the dated security
baseline) and past-advice attribution comments in scripts/hooks/tests/CI are deliberately left as
records.

- **New plugin:** `claude-code-plugins/claude-specialists/specialists-ecomm/` with `plugin.json`
  (version 1.16.0, lockstep), `CHANGELOG.md`, and `RELEASE.md` card; registered as the fourth entry
  in `.claude-plugin/marketplace.json`.
- **Specialists:** agent defs `agents/06-26|27|28-agent.md` and portable manuals
  `manuals/06-26|27|28-manual.md`.
- Group deliberately set up to grow further (lifecycle/email, analytics) without restructuring.

**Quality-round follow-ups (Victor/Edith/Sebastian/Ravi/Nolan on the diff):**
- Registered the new plugin in the docs that describe the family — root `README.md`, the family
  `README.md`, and `QUICKSTART.md` now say "four plugins" and list `specialists-ecomm`; reframed
  "a repo needs at most one domain group" as **complementary** (a Shopify repo can enable
  `specialists-shopify` + `specialists-ecomm`).
- Fixed a real functional gap: `check-consumer-drift.ps1` hardcoded three plugins, so a consumer's
  drift check would never cover ids 26/27/28 — added `specialists-ecomm`.
- Language norm: translated the three pre-existing Dutch manifests (`marketplace.json` + the
  `specialists`/`lifehub`/`shopify` `plugin.json`) to English, closing the mixed-language state
  instead of extending it; generalized stale "three plugins" wording in scripts and lenses.
- Ravi: promoted three verbatim-shared boundaries across the ecomm agent-defs to `agent-shared/`
  blocks (`design-owner-boundary`, `changelog-entry-boundary`, `storefront-preview-boundary`),
  scoped to Sergio/Craig/Sean.

Verified: `build-agent-defs.ps1 -Check` (shared blocks in sync), `check-plugin-integrity.ps1`
(0 errors), and all test suites green.

[PR #143](https://github.com/DaveKJohn/davekjohns-workshop/pull/143)

---

## v1.15.1 — 2026-07-22

### #131 · shared Invoke-NativeCapture helper (#114 item 1) · Chore · 2026-07-22

Centralized the native-command stderr-capture pattern (#114 item 1) into a new shared helper
`scripts/lib/native-capture-lib.ps1` (`Invoke-NativeCapture`), so the #96/#97/#107 lesson --
run under `ErrorActionPreference = 'Continue'`, capture output, then judge on `$LASTEXITCODE`
instead of on stderr -- lives in exactly one tested place. The helper takes `-FilePath`/`-Arguments`
(not a scriptblock, so the EAP override actually reaches the command) and returns `Output` +
`ExitCode`; `-DiscardStderr` keeps stderr out of machine-readable output. `open-pr.ps1` (git push +
`gh pr create`) and `fold-changelog-entry.ps1` (`gh pr list`) now call the helper instead of each
repeating the save/restore dance. Registered as a mirrored shared script and dot-sourced
`$PSScriptRoot`-relative, matching the `check-report-lib.ps1` precedent. Regression guards in
`shared-scripts.tests.ps1` were re-pointed from the old inline patterns to the centralized helper,
plus a new behavioral test of `Invoke-NativeCapture` (throws-nothing on native stderr under caller
EAP=Stop, real exit code, EAP restored, `-DiscardStderr`).

[PR #131](https://github.com/DaveKJohn/davekjohns-workshop/pull/131)

---

## v1.15.0 — 2026-07-21

### #130 · open-pr/fold consumer-fit: configurable PR markers, optional assignee/milestone, fold -RepoRoot (#101) · Feat · 2026-07-21

Three consumer-fit gaps in the shared `open-pr.ps1` / `fold-changelog-entry.ps1` scripts,
surfaced by smartwatchbanden (inbound #101). All three are backward-compatible: a repo whose
`scripts/repo-config.ps1` does not define the new optional functions, and every existing
`fold-changelog-entry.ps1` call site, keep today's exact behavior.

1. **PR auto-fill markers are now configurable.** `open-pr.ps1` matched its description
   placeholder and its "Requested by Dave" approval checkbox against this repo's own
   (bilingual) template text. Two optional repo-config functions,
   `Get-PrDescriptionPlaceholder` and `Get-PrApprovalPattern`, let a consumer point at its own
   template markers; when absent (guarded via `Get-Command ... -ErrorAction SilentlyContinue`),
   the script falls back to this repo's current markers unchanged.
2. **Optional PR assignee/milestone.** Two more optional repo-config functions,
   `Get-PrAssignee` and `Get-PrMilestone`, are passed to `gh pr create` as `--assignee` /
   `--milestone` only when they return a non-empty value; not defined (or empty) means the
   flags are simply omitted, exactly as before. This repo defines neither.
3. **`fold-changelog-entry.ps1` gained an explicit `-RepoRoot` parameter.** Default (omitted):
   unchanged dual-context resolution (`CLAUDE_PROJECT_DIR`, else the git root). When supplied,
   it wins outright -- letting a consumer that runs the fold from a temporary/detached worktree
   (e.g. smartwatchbanden's `ship-pr.ps1`) write to that tree directly, without the
   env-var workaround.

`open-pr.ps1` and `fold-changelog-entry.ps1` are the mirrored shared scripts (source of truth
here, regenerated into the plugin mirror via `build-shared-scripts.ps1`); `scripts/repo-config.ps1`
is this repo's own file and is unchanged (the workshop keeps the built-in defaults on all four
functions).

[PR #130](https://github.com/DaveKJohn/davekjohns-workshop/pull/130)

---

### #129 · Quiet-moment backlog #114: shared check-report helpers + two-plugin roster-sync test (native-capture assessed, not extracted) · Chore · 2026-07-21

Two dedup points from the quiet-moment backlog (#114), each assessed for the mirror/consumer
boundary first (the #103 lesson: a shared lib must be present in EVERY context that dot-sources
it, not just the workshop).

**Point 1 -- the `Invoke-NativeCapture` pattern (save `$ErrorActionPreference` -> `Continue` ->
native call -> capture output + `$LASTEXITCODE` -> restore, the #107 stderr guard): NOT extracted
to a shared lib -- reported as a mirror-boundary constraint instead of a half measure.** All five
occurrences of the exact pattern live inside three whole-file-mirrored, consumer-run scripts
(`open-pr.ps1` x2 -- push + `gh pr create`, `new-branch.ps1` x2 -- the exists-check + the checkout,
`fold-changelog-entry.ps1` x1 -- `gh pr list`); `cut-release.ps1` (workshop-only) uses a simpler,
different shape (a single `EAP=Continue` for its tail block, no per-call capture/restore) and was
left as is. A cross-file shared lib for these three would need a NEW consumer-scaffolded file
(like `repo-config.ps1`/`branch-info.ps1`), since none of the three currently dot-source a common
lib the helper could ride along on -- that means extending `specialists-init/bootstrap.ps1` and
every already-bootstrapped consumer, real infra scope beyond a same-branch pure refactor. Not
implemented; flagged here for a deliberate follow-up decision instead.

**Point 2 -- a new `scripts/lib/check-report-lib.ps1`: extracted cleanly, no consumer-bootstrap
changes needed.** Unlike `repo-config.ps1`/`branch-info.ps1` (repo-owned, per-consumer-repo-root
files), this lib is not repo-specific, so it can be dot-sourced relative to `$PSScriptRoot` --
which means it ships as part of the SAME plugin/mirror payload as its callers and needs no
consumer scaffold. Registered as a new pair in `scripts/lib/shared-scripts-lib.ps1` (mirrored to
`claude-code-plugins/claude-specialists/specialists/scripts/lib/check-report-lib.ps1` via
`build-shared-scripts.ps1`, exactly like the five whole-script pairs). Extracted: `Write-Ok` /
`Write-Info` / `Write-Fout` (counting variant) / `Write-CheckSummary` (the "Summary: N error(s), N
info signal(s)." line + exit code), `Test-PluginNameSlug` / `Test-PluginMarketplaceSlug` (the
slug-guard regexes), and `Resolve-PluginDir` (the versioned-plugin-cache-dir resolver, honoring
`$env:CLAUDE_PLUGIN_ROOT`, `[version]`-sorted).

Consumers, per their actual mirror/consumer status:
- `scripts/sync/check-connectors.ps1` (workshop-only -- reads the `connectors/` register that only
  exists here): dot-sources unconditionally; kept its own `Write-Skip` and `Get-PluginDir`
  (family-plugin-folder lookup -- a genuinely different function from `Resolve-PluginDir`'s
  cache/version resolution, despite the similar name, so NOT merged).
- `scripts/sync/check-roster-sync.ps1` (whole-file mirror): dot-sources via `$PSScriptRoot`
  (not `$repoRoot` -- this lib is not repo-owned), safe because both files travel in the same
  registered mirror-pair set (drift-lint guarded).
- `claude-code-plugins/claude-specialists/specialists/skills/sync-roster/sync-roster.ps1`
  (plugin-native, never had a root copy): dot-sources the mirrored lib two levels up
  (`..\..\scripts\lib\...`), same reasoning as its existing `Resolve-CheckScript` sibling-path
  logic. Kept its OWN non-counting `Write-Info`/`Write-Fout` (it tracks
  created/kept/proposed and always exits 0 -- a deliberately different shape from the
  error/info-signal counters, so not merged; the later local redefinition intentionally shadows
  the lib's counting versions in the same scope).

Verified: dot-sourcing runs in the caller's own scope, so a shared `Write-Fout`/`Write-Info`
correctly bumps the CALLER's own `$script:errors`/`$script:infos` -- confirmed with a small
throwaway repro before relying on it.

`build-agent-defs.ps1 -Check`, `build-shared-scripts.ps1` (regenerated the two touched mirrors,
then `-Check` green), and `check-plugin-integrity.ps1` all report 0 findings. Adjusted one coupled
assertion in `scripts/tests/shared-scripts.tests.ps1` ("every mirrored source resolves the repo
root via `CLAUDE_PROJECT_DIR`"): `check-report-lib.ps1` is a dot-sourced lib, not a standalone
dual-context entry point, so it is excluded from that specific invariant (still covered by the
existence/in-sync checks). All `scripts/tests/*.tests.ps1` suites pass (behavior identical --
integration tests assert on stdout/exit-code, not on internal function boundaries).

**Follow-up on this same branch -- `Write-Fout` renamed to `Write-Failure`.** After the English
sweep of this repo's content (docs/lens-language-english, #115), `Write-Fout` was the one
remaining Dutch function name -- introduced in the new `check-report-lib.ps1` above specifically to
avoid a name clash with the built-in `Write-Error` cmdlet. Renamed (definition + all call sites) to
`Write-Failure` in `scripts/lib/check-report-lib.ps1`, `scripts/sync/check-connectors.ps1`,
`scripts/sync/check-roster-sync.ps1`, and the plugin-native
`claude-code-plugins/claude-specialists/specialists/skills/sync-roster/sync-roster.ps1` (incl. its
own non-counting shadow definition, kept for the same reasons as before). The mirrors
(`check-report-lib.ps1`, `check-roster-sync.ps1`) were regenerated via `build-shared-scripts.ps1`.
Only the PowerShell identifier changed -- the printed `[ERROR]` marker and message text are
untouched, so hook/test matchers on the output stay intact. `build-shared-scripts.ps1 -Check`,
`check-plugin-integrity.ps1` (0 errors), and all `scripts/tests/*.tests.ps1` suites are green.

**Point 4 -- the two-plugin roster-sync test gap: closed on this branch.** `scripts/tests/roster-sync.tests.ps1` gains scenario 12 ("Cross-plugin orphan aggregation", 7 asserts): two enabled plugins each with their own orphan, asserting the aggregation reports both (not just the first) and that neither plugin's backing ids are lost across the per-plugin passes. No bug found in `check-roster-sync.ps1` -- the accumulation was already correct, now it is actually exercised rather than only documented as a gap.

(Point 3 of #114 -- the English sweep of the script layer -- landed separately in #128; only points 1, 2, and 4 are in scope here.)

[PR #129](https://github.com/DaveKJohn/davekjohns-workshop/pull/129)

---

### #128 · English sweep of the script layer: .ps1 comments and console output to English (#114 item 3) · Chore · 2026-07-21

Translated the Dutch comments/docstrings and Dutch console output (`Write-Host`/`Write-Error`/
`Write-Warning`/`throw` text, summary lines) across the whole script layer to English, per Dave's
repo-wide English-content decision: `scripts/lib`, `scripts/lint`, `scripts/release`,
`scripts/sync`, `scripts/agents`, `scripts/repo-config.ps1`, `scripts/task`, and every
`scripts/tests/*.tests.ps1` suite, plus the two hooks
(`roster-sessioncheck.ps1`/`connector-sessioncheck.ps1`, the latter already English) and the
`specialists-init` bootstrap skill (two leftover Dutch fragments). Test assertions that matched on
now-translated output strings were updated in the same motion so the suites stay green and
verifiable; no test was weakened, only the expected text changed. The five shared-script mirrors
under `claude-code-plugins/claude-specialists/specialists/scripts/` were regenerated via
`build-shared-scripts.ps1` afterward, and `build-agent-defs.ps1 -Check` confirms the shared agent-def
blocks are untouched.

`VUL-IN` is kept as-is everywhere (Dave's explicit decision, technical scaffold marker) -- caught one
regression during the sweep where a first pass had renamed it to "FILL-IN" in a few Write-Error
messages, breaking the literal-marker contract; reverted those to `VUL-IN` and confirmed via the
test suite.

Follow-up (Sylvester, same branch): Dave asked for the generated-content templates in
`scripts/lib/release-lib.ps1` to also go English, since that text ends up in future
`CHANGELOG.md` / release-notes / per-plugin-`CHANGELOG.md` files. Translated: the `catTitle`
category labels (`Feat`/`Docs`/`Chore`/the `Overig` catch-all, now `New features & improvements` /
`Documentation` / `Maintenance (scripts, tooling, config)` / `Other`), the reference line under
`## Releases` ("See [...] for the full release notes"), the `## Releases` genesis intro text
(only ever seen before a repo's first release), the fresh per-plugin-`CHANGELOG.md` intro
paragraph in `Add-PluginChangelogSection`, and the `**Datum:**` label (now `**Date:**`, matching
the `Build-PluginReleaseCard` label it already used). `scripts/tests/release-lib.tests.ps1`'s
fixtures and assertions were updated to the new English expectations (no assertion weakened,
plus one added assertion exercising the genesis-intro fallback path). History remains the
deliberate exception per Dave's decision: `releases/**` and already-folded `CHANGELOG.md`
sections keep whatever language they were written in -- only future generator output changed, so
a mix of Dutch history and English new content is expected and fine.

Two categories of Dutch text were deliberately left untouched, as they are not "script layer"
comments/console output but generated document CONTENT: (1) `releases/**` history plus the
legacy Dutch slot-marker text ('Eigen aan deze repo') that `check-consumer-drift.ps1` and
`bootstrap.ps1`'s templates deliberately still recognize for back-compat with older Dutch consumer
repos; and (2) `cut-release.ps1`'s literal match against `releases/README.md`'s existing Dutch
table header ("Versie | Datum | Type | Titel") -- that header is itself history and the match is
already explicitly documented in that script as a deliberate exception, not touched here.
Bilingual back-compat matchers in `open-pr.ps1` (PR-template checklist strings) and the legacy
`[FOUT]` marker in `connector-sessioncheck.ps1` were left exactly as they were: both languages are
a deliberate feature, not leftover translation debt.

End state: `check-plugin-integrity.ps1` reports 0 errors and all 10 `scripts/tests/*.tests.ps1`
suites pass (`agent-shared`, `bootstrap-drift`, `branch-info`, `connectors`, `new-branch`,
`release-lib`, `repo-config`, `roster-sync`, `shared-scripts`, `sync-roster`).

[PR #128](https://github.com/DaveKJohn/davekjohns-workshop/pull/128)

---

### #127 · Release/fold/lint hygiene: dead-link coverage + Get-TouchedPlugins + fold/cut-release cleanups (#103) · Chore · 2026-07-21

A batch of release/fold/lint hygiene fixes from issue #103 (Victor's earlier code-review
findings #3-#7, plus a dead-link-scan coverage gap):

- **Dead-link scan coverage.** `check-plugin-integrity.ps1`'s scan now also covers the per-plugin
  `claude-code-plugins/claude-specialists/*/CHANGELOG.md`s, the family
  `claude-code-plugins/claude-specialists/README.md`, and its `QUICKSTART.md` — none of these were
  in the scanned set before. No existing dead links surfaced from the widened scan.
- **`Get-TouchedPlugins` as a pure function (Victor #3).** The inline plugin-detection logic in
  `fold-changelog-entry.ps1` (deriving the `Plugins:` line from the PR's touched files) is now the
  pure, testable `Get-TouchedPlugins -Files <paths>` in `scripts/lib/release-lib.ps1` — same
  connectors-exclusion and lowercase-slug rule, no behavior change. Since `release-lib.ps1` is
  deliberately not mirrored to the plugin (unlike `fold-changelog-entry.ps1` itself), the fold
  script now guards the dot-source with a `Test-Path` check: in the workshop root it's found and
  used; in a consumer repo running the plugin mirror it's simply absent, and the `Plugins:`
  enrichment is skipped — functionally identical there, since
  `claude-code-plugins/claude-specialists/<plugin>/` paths never exist outside this repo anyway.
- **One `gh` call instead of two (Victor #4).** `gh pr list --json` supports the `files` field
  directly (verified against the live `gh` CLI), so the second `gh pr view --json files` call is
  gone; `gh pr list` alone now supplies number, url, and files in one round trip.
- **Sharpened the `Add-PluginChangelogSection` insertion match (Victor #5).** The insertion point
  used to match any `(?m)^## ` heading; it now matches specifically a version heading
  (`## vX.Y.Z ...`, the exact shape `Build-PluginChangelogSection` writes), so a manually added
  non-version `## `-heading in a plugin CHANGELOG can no longer misdirect where the new release
  section is inserted. Verified with a smoke test against a synthetic CHANGELOG carrying a
  `## Notes` heading ahead of the first version heading.
- **LF-vs-`$nl` newline hygiene (Victor #6).** `Build-PluginChangelogSection` and
  `Build-ReleaseNotes` are documented as deliberately LF-pure output (self-contained regenerated
  files, unlike the root `CHANGELOG.md`, which detects and keeps its own CRLF via `$nl`) — but they
  were passing through entry bodies verbatim from that CRLF root `CHANGELOG.md`, which produced
  mixed CRLF/LF line endings in the generated per-plugin `CHANGELOG.md`/`RELEASE.md` files and the
  `releases/development/**` notes (confirmed on disk before this fix). Both functions now normalize
  incoming entry text to LF before assembling, so the documented "pure LF output" promise actually
  holds; `Build-PluginReleaseCard` inherits the fix via `Build-PluginChangelogSection`.
- **Merged the two `$manifests` loops in `cut-release.ps1` (Victor #7).** The per-plugin CHANGELOG
  loop and the RELEASE.md loop shared the same `$pluginEntries` selection (`Get-EntryPlugins` filter
  and `Remove-EntryPluginsLine`) computed twice; merged into a single loop per plugin that computes
  the shared selection once and then does both writes (CHANGELOG only when the plugin has entries
  this release, RELEASE.md unconditionally, matching prior behavior) — same output, better
  readability.

Regenerated the `fold-changelog-entry.ps1` plugin mirror (`build-shared-scripts.ps1`); updated one
outdated assertion in `shared-scripts.tests.ps1` that still expected the now-removed `gh pr view`
call. `check-plugin-integrity.ps1` is green (0 errors) and all `scripts/tests/*.tests.ps1` suites
pass. `Get-TouchedPlugins`, the sharpened `Add-PluginChangelogSection` match, and the LF
normalization are covered by automated tests added to `release-lib.tests.ps1` in this pass.

[PR #127](https://github.com/DaveKJohn/davekjohns-workshop/pull/127)

---

### #123 · Translate the GEGENEREERD, bewerk sentinel marker to English across the agent defs · Docs · 2026-07-21

Translated the last Dutch fragment in the agent-def shared-block sentinel comments to English, in
line with the repo-wide English-content norm: `<!-- BEGIN shared:NAME -- GEGENEREERD, bewerk
agent-shared/NAME.md -->` becomes `<!-- BEGIN shared:NAME -- GENERATED, edit agent-shared/NAME.md
-->`. The marker is literal per-file text (the generator preserves the BEGIN/END sentinel lines
as-is and only fills the body between them), so all 21 agent-defs across the three plugins were
updated directly, plus the one docstring example in `agent-shared-lib.ps1` and the one test
fixture string in `agent-shared.tests.ps1`. No regex in the generator or the lint gate matched the
Dutch text, so nothing there needed changing. Verified: `build-agent-defs.ps1 -Check` (in sync),
`check-plugin-integrity.ps1` (0 errors), and all `scripts/tests/*.tests.ps1` suites green.

[PR #123](https://github.com/DaveKJohn/davekjohns-workshop/pull/123)

---

## v1.14.0 — 2026-07-21

### #121 · Make the automation-first (lazy) rule a plugin-owned shared block, like inbound-behaviour · Feat · 2026-07-21

The automation-first ("stay lazy") behavioral rule is now plugin-owned via a new shared block,
`claude-code-plugins/claude-specialists/agent-shared/laziness-automation.md`, wired into the
subagent agent-defs via `<!-- BEGIN/END shared:... -->` sentinels — the same circle as
`shared:inbound-behaviour` — so the rule travels along to consuming repos instead of living only
in this repo's own `CLAUDE.md`. The per-specialist "X is lazy" examples in the manuals stay in
place as elaboration; `CLAUDE.md`'s own "Shared trait — all of them incredibly lazy" paragraph
remains as the governance narrative for the main loop (Chris and the main-loop personas, who carry
no agent-shared blocks), with a light note added that it is the same rule carried by every
specialist's shared playbook, not a second canonical copy.

[PR #121](https://github.com/DaveKJohn/davekjohns-workshop/pull/121)

---

### #120 · Cross-browser compatibility as a standard rule for the browser-facing builders · Feat · 2026-07-21

New shared behavioral rule for the browser-facing builders: what they build must work in all major
browsers (Chrome, Firefox, Safari, Edge), not only the one they happened to preview in. Landed as a
new canonical source block, `claude-code-plugins/claude-specialists/agent-shared/browser-compatibility.md`,
carried into the agent defs of the four specialists who share it — Gwen #12 (Front-End Designer),
Liam #20 (Liquid Developer), Cody #13 (App Developer), Vera #11 (Data Analyst) — via the existing
`agent-shared/` sentinel mechanism, plus a matching prose paragraph in each of their portable
manuals (`04-12-manual.md`, `specialists-shopify/manuals/04-20-manual.md`, `04-13-manual.md`,
`04-11-manual.md`) describing the cross-browser check in that specialist's own context.

[PR #120](https://github.com/DaveKJohn/davekjohns-workshop/pull/120)

---

## v1.13.0 — 2026-07-21

### #119 · Ship a per-plugin RELEASE.md card so consumers see which release they are on · Feat · 2026-07-21

Every plugin now carries a `RELEASE.md` card (version, one-line summary, and the entries for that
version) right next to its `CHANGELOG.md`. Chosen approach: **Model A, plugin-authored** — the card
lives inside the plugin folder and travels with the plugin cache via `claude plugin update`, so a
consumer can see exactly which release they're on without cross-referencing the workshop's own
`releases/` history. `cut-release.ps1` (re)generates the card for every plugin, in lockstep, on
every release; the lint gate's new check 9 guards that the card is present and its `vX.Y.Z` matches
that plugin's `plugin.json`. Deliberately **no SessionStart hook** announces this — the card is
discovered by opening the file in the plugin cache. Seeded on v1.12.1.

[PR #119](https://github.com/DaveKJohn/davekjohns-workshop/pull/119)

---

### #118 · new-branch.ps1: branch creation immediately scaffolds its changelog entry · Feat · 2026-07-21

Branch creation now brings its changelog entry into being in the same move — a branch is never entry-less. Added a shared, Derek-bound `scripts/task/new-branch.ps1` that validates the branch name via `branch-info.ps1` (new additive `Test-BranchName` helper), creates the branch (idempotent `git -C` checkout/checkout -b, no `Set-Location`), and immediately scaffolds the changelog entry by calling `new-changelog-entry.ps1` as a child process. Promoted `new-changelog-entry.ps1` to a dual-context, mirrored shared script (resolves its repo root via `CLAUDE_PROJECT_DIR`, dot-sources `branch-info.ps1` from the repo root, with a #86 pre-flight); registered both scripts in `shared-scripts-lib.ps1` and generated their plugin mirrors. Added the `/specialists:new-branch` skill, and updated Derek's persona + the workflow docs (Derek/Rendall/Tessa lenses, plugin scripts README, root README) so "a branch creates its entry at creation time" is the rule and the separate later step is gone. Consumer seam: the shared script does only git + entry (no push/PR, idempotent), so a consumer like smartwatchbanden can call it first and layer its own step (e.g. a Shopify preview theme) on top. Tests: new `new-branch.tests.ps1` plus extended `shared-scripts` and `branch-info` suites; lint and all suites green.

[PR #118](https://github.com/DaveKJohn/davekjohns-workshop/pull/118)

---

### #117 · English names for agent-shared blocks + script-comment translations · Docs · 2026-07-21

Completed the in-progress English-norm cleanup of the agent-shared machinery. Renamed the four verbatim-shared source blocks to English file names (`grens-inbound` → `inbound-behaviour`, `gedrag-taalkeuze` → `language-behavior`, `grens-webcontent` → `webcontent-boundary`, `grens-artifact-publish` → `artifact-publishing-boundary`) and pulled the whole chain along: the `shared:<name>` sentinels in all 21 agent defs across the three plugins, the generator-lib docstring, and the current-doc references in `README.md` and Ravi's lens. Also folded in the NL→EN comment translation of `connector-sessioncheck.ps1` and `bootstrap.ps1`. Functional/canonical markers deliberately keep their original form per the language convention's technical-identifier exception — the `VUL-IN` scaffold sentinel and a couple of marker phrases the drift tests key on stay as-is. History (`CHANGELOG.md` files, `releases/`) is left untouched. Generator, lint (0 errors), and all test suites are green.

[PR #117](https://github.com/DaveKJohn/davekjohns-workshop/pull/117)

---

### #116 · Add Nolan #25, the Performance Engineer (token/context frugality) · Feat · 2026-07-21

Added a new portable specialist to the Claude Specialists: **Nolan ⚡ #25 — Performance Engineer** (`@specialists:nolan`, stable id `06-25`, group 06). Nolan is a measure-and-advise role for token/context frugality: he measures what each session, agent def, manual, and loading chain costs, and proposes where it can come down without losing function. He reports findings and does not commit, edit, or open PRs himself — execution runs through Ravi #24 (DRY dedup), Sylvester #15 (harness/config), and Tessa #16 (doc-text rewrite). New portable manual (`manuals/06-25-manual.md`) and agent def (`agents/06-25-agent.md`) on the plugin side, a davekjohns-workshop repo lens (`06-25-extension.md`), and roster/routing updates in `CLAUDE.md`, Chris's lens, and the Specialists handbook.

[PR #116](https://github.com/DaveKJohn/davekjohns-workshop/pull/116)

---

### #115 · English repo content becomes a system-wide norm (incl. consumer lenses) · Docs · 2026-07-20

Promotes the "repo content is English" rule from the workshop-only `### Language` slot in
`CLAUDE.md` to a portable, synced norm in Tessa #16's manual body ("Guarding the language
convention"), so every consuming repo inherits it — including that a consumer's own repo lens
(`## Specific to this repo`) is written in English, while the session-reply language stays free and
follows the user. The workshop `CLAUDE.md` slot now defers to that norm and keeps only this repo's
own application of it. Consumers pick up the norm after the next release + `claude plugin update`;
translating their existing lenses stays each consumer's own session job.

[PR #115](https://github.com/DaveKJohn/davekjohns-workshop/pull/115)

---

## v1.12.1 — 2026-07-20

### #113 · Sweep: the git/gh stderr-under-Stop pitfall across the release scripts · Fix · 2026-07-20

Cutting v1.12.0 exposed that the #107 fix (open-pr's push) only patched one spot: the same
`$ErrorActionPreference = 'Stop'` + native-stderr-as-terminating-error pitfall lived on in the other
release scripts. `cut-release.ps1` died on `git add -A` (the autocrlf LF↔CRLF warning goes to
stderr), before its `$LASTEXITCODE` check — the release had to be finished by hand. This sweeps the
whole class.

- **`cut-release.ps1`:** the commit/tag/push block now runs under `EAP=Continue` (with a `git add`
  exit-code check that was missing), so git's chatter can't abort the release before the checks.
- **`fold-changelog-entry.ps1`** (+ mirror): the two `gh pr list`/`gh pr view --json` calls run under
  `EAP=Continue` with `2>$null`, so a `gh` notice can't terminate the fold before its graceful
  `$LASTEXITCODE` handling (and can't pollute the captured JSON). On a non-zero `gh` exit it now
  prints a one-line notice that the PR-number / Plugins-line enrichment was skipped (restoring the
  operator-visibility the raw stderr used to give — review point Victor/Sean).
- **`open-pr.ps1`** (+ mirror): the `gh pr create` call gets the same `EAP=Continue` + capture guard
  the push already had (#107).
- **Query commands left as-is:** `git rev-parse`/`git status`/`git tag --list` write results to
  stdout and only real errors to stderr, so `Stop` is correct there — deliberately not wrapped.
- **Tests:** `shared-scripts.tests.ps1` gains static regression guards that cut-release runs its
  git-mutation block under `Continue`, fold discards `gh` stderr, and open-pr guards `gh pr create`.
- **`05-15-extension.md`** (Sylvester's lens): the #107 lesson now names `git add` and the query-vs-
  mutation distinction, and records the sweep.

The live release/push/gh paths against a real remote stay an honest test-gap (not unit-testable
without a remote); the guards assert the safe shape.

[PR #113](https://github.com/DaveKJohn/davekjohns-workshop/pull/113)

---

## v1.12.0 — 2026-07-20

### #112 · Roster-sync recovery skill (layer 3, feature complete) · Feat · 2026-07-20

The final layer of the roster-sync feature: after the SessionStart hook (layer 2, #111) flags a
specialist missing from a consumer's roster, the `sync-roster` skill stages the catch-up — without
ever writing to `CLAUDE.md`, committing, or touching main. With this, the feature is complete:
detection (#110) → signaling (#111) → recovery.

- **`skills/sync-roster/sync-roster.ps1` (new):** delegates drift detection to
  `check-roster-sync.ps1` (it does not re-decide drift), then for each flagged agent creates the
  missing lens scaffold (`## Specific to this repo (VUL-IN)`, the same structure `specialists-init`
  writes — frontmatter, lens-only intro, the VUL-IN slot; additive, never overwriting) and prints a
  proposed roster row built from the agent's frontmatter
  (name + description, best-effort matched to the roster's table-or-list style). It prints a summary
  with an explicit "main is sacred — review and branch this yourself" reminder. The roster file is
  never modified.
- **`skills/sync-roster/SKILL.md` (new):** when to run it (after the hook flags drift), what it
  stages, and the human follow-up — mirroring the `open-pr`/`specialists-init` skill tone.
- **`roster-sessioncheck.ps1`:** the drift hint now points at the `sync-roster` skill (the forward
  reference deliberately held back in layer 2 until the skill existed).
- **`QUICKSTART.md`:** a "new specialist" note in *Staying up to date* points consumers at the hook
  + skill.
- **Tests:** `sync-roster.tests.ps1` (22 asserts) covers scaffold creation, the never-overwrite
  guard, a proposed row printed for a missing-roster agent, and that the roster file's bytes are
  never changed.

Version gate as usual: consumers get the skill after a release bump + `claude plugin update`.

[PR #112](https://github.com/DaveKJohn/davekjohns-workshop/pull/112)

---

### #111 · Roster-sync SessionStart hook (layer 2 of the feature) · Feat · 2026-07-20

Layer 2 of the roster-sync feature: the detection from layer 1 (#110) now surfaces itself at
session start, so a specialist missing from a consumer's roster is visible right after a plugin
update instead of only when someone happens to run the check.

- **`hooks/roster-sessioncheck.ps1` (new):** a SessionStart hook that runs the mirrored
  `check-roster-sync.ps1` against the current repo and, like `connector-sessioncheck.ps1`, is
  deliberately soft — it surfaces only blocking `[ERROR]` signals (a missing specialist) as a
  compact summary, keeps `[INFO]` (orphans, ignore-list skips, uncached plugins) silent, and always
  exits 0 (a session start never strands here). Read-only.
- **`hooks/hooks.json`:** a second command is added to the existing `SessionStart` (startup) entry,
  so the new hook runs alongside the connector check.
- **`connectors/README.md`:** the named-exception note now covers this second hook.
- **Tests:** `roster-sync.tests.ps1` gains hook cases (missing check script → skipped; an `[ERROR]`
  stub → drift summary + exit 0, never blocking; an `[INFO]`/`[OK]`-only stub → silent in-sync
  message).

Version gate as usual: consumers receive the hook only after a release bump + `claude plugin
update` + session restart. Layer 3 (the semi-automatic `sync-roster` recovery skill) and the full
feature docs follow.

[PR #111](https://github.com/DaveKJohn/davekjohns-workshop/pull/111)

---

### #110 · Roster-sync detection (layer 1 of the feature) · Feat · 2026-07-20

When a plugin release adds a new specialist (e.g. Ravi 06-24), a consumer that updates the plugin
gets no signal that its roster (the specialists table in CLAUDE.md) and its repo lenses now lag
behind — the Ravi and Sean cases were both caught by chance. This is layer 1 of the fix: **detection**.
The SessionStart signaling (layer 2) and the semi-automatic recovery skill (layer 3) follow; full
user-facing docs land with layer 3 when the feature is complete.

- **`scripts/sync/check-roster-sync.ps1` (new, shared):** run from a consumer root, it resolves the
  enabled plugins' agents from the highest-version cache dir, then flags per agent: no roster row
  (`[ERROR]`), no repo-lens (`[ERROR]`), and roster/lens ids with no backing agent or persona
  (`[INFO]` orphan). Same `[OK]/[INFO]/[ERROR]` + exit-code convention and path guardrails as
  `check-connectors.ps1`. Mirrored to the plugin via the shared-scripts pipeline (byte-identical,
  drift-linted).
- **`repo-config.ps1`:** `Get-RosterPath` (default `CLAUDE.md`) tells the check where the roster
  lives; `Get-RosterIgnoredIds` lists agents that are enabled but deliberately have no roster
  row/lens (here: Paula 02-09, Vera 04-11, Gwen 04-12, Cody 04-13 — a documented choice), so the
  workshop's own run is clean. A fresh consumer leaves the ignore-list empty.
- **Tests:** `roster-sync.tests.ps1` (28 asserts, fixture-driven) covers the happy path, a new agent
  missing from the roster, a missing lens, orphans, disabled/uncached plugins, highest-version
  resolution, persona-backing, the `Get-RosterPath` override, the legacy lens path, and the
  ignore-list. `repo-config.tests.ps1` gained asserts for the two new getters.

Layer 1 is not yet wired into any gate — it is a standalone check a consumer can run; the hook
(layer 2) will surface it at session start.

[PR #110](https://github.com/DaveKJohn/davekjohns-workshop/pull/110)

---

### #109 · Shared block for the language directive (Ravi) · Feat · 2026-07-20

Phase B left the closing "respond in the user's language" line verbatim-identical in 19 of the 20
agent defs. Ravi's duplication check recommended promoting it to a single source via the existing
`agent-shared/` mechanism — no new machinery needed, since the generator is line-based.

- **New source `agent-shared/gedrag-taalkeuze.md`** with the canonical line; the 19 identical agent
  defs now carry it between `<!-- BEGIN/END shared:gedrag-taalkeuze -->` sentinels, filled and
  verified by `build-agent-defs.ps1` like the `grens-*` blocks.
- **03-07 (Rebecca) stays local:** its line has a deliberate source-quoting nuance ("...quoting
  sources in another language is fine") — a near-duplicate that Ravi's own rule says not to force-merge.
- **Ravi's lens (06-24)** scope updated: the shared-block circle now names a third category
  (standalone behavior directives outside Boundaries/Working method) and lists `gedrag-taalkeuze`.

Naming note: the new source keeps the Dutch-style name of its `grens-*` siblings for uniformity;
renaming the whole `agent-shared/` set to English is a later-phase consistency item.

[PR #109](https://github.com/DaveKJohn/davekjohns-workshop/pull/109)

---

### #108 · Workshop to English — phase C: machine markers, bilingual · Feat · 2026-07-20

The final English-switch phase: the machine-coupled Dutch markers and the consumer-facing output of
the connector tooling are now English, with **bilingual back-compat** so consumers still carrying
the Dutch markers keep working across a plugin-version skew.

- **Slot marker `## Eigen aan deze repo` → `## Specific to this repo`.** `bootstrap.ps1` now writes
  the English scaffold heading; `check-consumer-drift.ps1` splits the portable body on **either**
  language (a legacy Dutch consumer still splits correctly). Docs (root README, connectors README,
  `specialists-init` skill, Chris's lens) follow the English canonical name.
- **Signal token `[FOUT]` → `[ERROR]`.** `check-connectors.ps1` emits `[ERROR]`; the SessionStart
  hook's blocking-signal filter recognizes **both** `[FOUT]` and `[ERROR]` (the plugin cache and the
  workshop checkout can be on different versions).
- **Consumer-facing output is English.** The connector check/drift-check messages and the hook's own
  session-start lines (`no errors`, `signals found …`) — surfaced into every consumer session — are
  translated.
- **PR template → English, `open-pr.ps1` matches both languages.** The three auto-fill strings are
  English in the template; the script still recognizes the Dutch strings so a consumer whose template
  is still Dutch keeps its auto-fill.
- **Tests:** bilingual back-compat is proven — the drift split is tested with both the legacy Dutch
  and the new English slot fixture; the hook test surfaces both a `[FOUT]` and an `[ERROR]` line.
  All seven suites green.

**Deferred to a later phase (D):** the purely internal, non-consumer-facing Dutch code-comments in
the scripts (and old research docs under `research/`). They ship in no consumer-visible surface, so
they carry no urgency; the English switch of everything consumer-facing is complete with this phase.

[PR #108](https://github.com/DaveKJohn/davekjohns-workshop/pull/108)

---

### #107 · open-pr.ps1 survives git push's stderr chatter · Fix · 2026-07-20

`open-pr.ps1` died on the `git push` step: git writes its `remote:` progress to stderr, and under
`$ErrorActionPreference = 'Stop'` PowerShell 5.1 promotes that stderr to a *terminating*
NativeCommandError — aborting the script before the `$LASTEXITCODE` check, even though git itself
exited 0. This surfaced when opening the phase-B PR (#106): the push succeeded but the script
stopped before creating the PR, so the PR had to be opened by hand.

- **`scripts/release/open-pr.ps1`** (+ its plugin mirror via `build-shared-scripts.ps1`): the push
  now runs with `$ErrorActionPreference = 'Continue'`, captures `2>&1`, records `$LASTEXITCODE`,
  restores the preference, and only then judges — the same shape as the #96 fix.
- **`scripts/tests/shared-scripts.tests.ps1`**: a guard proving the mechanism (naive stderr-under-Stop
  is terminating; the capture pattern is not and reads the real exit code) plus a regression guard
  that `open-pr.ps1` keeps the safe push form. The live push against a real remote stays an honest
  test-gap (no remote in the unit suite).
- **`05-15-extension.md`** (Sylvester's lens): the lesson secured next to the #97 `$LASTEXITCODE`
  note — stderr-as-failure under `Stop` is the sibling pitfall.

[PR #107](https://github.com/DaveKJohn/davekjohns-workshop/pull/107)

---

### #106 · Workshop switched to English — phase B: plugin content · Feat · 2026-07-20

Follow-up to phase A (#105): the shipped plugin content itself is now English, so consumers
worldwide read an English team. Covers all three plugins.

- **Translated:** the 20 agent definitions (prose outside the shared sentinel blocks), all 26
  manuals/playbooks, the 4 personas, `agent-shared/` (the canonical shared-bullet source), the
  three core skills + the shopify `start-task` skill, `specialists/scripts/README.md`, and the
  intro paragraphs of the three plugin `CHANGELOG.md` files (release history left as written).
- **Shared blocks regenerated:** `build-agent-defs.ps1` refilled every `<!-- BEGIN/END shared -->`
  region from the translated `agent-shared/`, so the sentinel content is English and byte-in-sync
  in all 20 agent defs.
- **Language directive aligned with the approved policy:** each agent def ended with a hard
  "work in Dutch" instruction. That contradicts the phase-A Language policy (specialists reply in
  the language the user writes in) and the worldwide-sharing goal, so all 20 now read "Respond in
  the language the user addresses you in." This is a behavior change beyond pure translation —
  flagged for review.
- **Slot-heading canon:** the human-readable `## Specific to this repo` section heading is now
  used consistently across manuals, lenses, and CLAUDE.md.

**Deliberately deferred to a later phase (scripts):** the machine-coupled Dutch marker
`## Eigen aan deze repo` still lives in `bootstrap.ps1` (the scaffold it writes),
`check-consumer-drift.ps1` (`Get-PortableBody` splits on it) and its test fixture; likewise the
`[FOUT]`/`[DRIFTED]` signal tokens, the `VUL-IN` scaffold marker, and the three Dutch PR-template
strings `open-pr.ps1` matches. Migrating those to English needs bilingual back-compat for
consumers that still carry the Dutch slot — a dedicated scripts phase. Lint and all seven test
suites pass.

[PR #106](https://github.com/DaveKJohn/davekjohns-workshop/pull/106)

---

## v1.11.0 — 2026-07-20

### #99 · Sessiestart-hook meldt alleen nog blokkerende signalen — INFO blijft stil · Feat · 2026-07-20

De SessionStart-hook toonde bij elke sessiestart óók de `[INFO]`-signalen uit de connectors-check:
registeradministratie over de sync-stand van consumenten (manifest achter op de bronversie, een
niet-geregistreerde extension). Die stand leeft vaak op een andere machine of bij een andere
gebruiker, en ook waar hij hier bij te werken is, is het administratie op eigen tempo — geen
sessiestart-werk. Het schaalt bovendien niet naarmate meer repo's de plugin installeren (wens
Dave).

- **`connector-sessioncheck.ps1`**: het signaalfilter is beperkt tot `[FOUT]`/`[DRIFTED]` — alleen
  wat hier en nu oplosbaar is bereikt de sessie-context. De OK-melding is daarop aangepast
  ("geen fouten"). `[INFO]` blijft volledig zichtbaar bij een bewuste run van
  `scripts/sync/check-connectors.ps1` in de workshop; aan de check zelf verandert niets.
- **`connectors.tests.ps1`**: nieuwe stub-case borgt dat INFO-regels nooit als sessie-alert
  doorlekken; de bestaande schone-stub-case volgt de nieuwe OK-melding.
- **`connectors/README.md`**: de sessie-check-doctrine beschrijft de FOUT/INFO-scheiding.

Let op de versie-poort: consumenten (en de workshop zelf, die zichzelf consumeert) draaien de
nieuwe hook pas na een release-bump + `claude plugin update` + sessie-herstart.

[PR #99](https://github.com/DaveKJohn/davekjohns-workshop/pull/99)

---

### #96 · RepoName-afleiding immuun voor de pipeline-exitcode-race (echte kern-oorzaak CI-flakiness) · Fix · 2026-07-19

De git-afleiding in de bootstrap bleef na #94 en #95 nog **niet-deterministisch** rood op CI (de
ssh-cases faalden soms, soms niet): dezelfde code, dezelfde omgeving, wisselend resultaat. De kern-
oorzaak is nu gevonden en weggenomen.

- **Oorzaak:** `Get-DerivedRepoName` las de origin als
  `& git ... config --get remote.origin.url | Select-Object -First 1`. Die pipe breekt de upstream
  (git) vroegtijdig af zodra de eerste regel binnen is; als git op dat moment nog niet netjes is
  afgesloten, wordt het proces met een **non-nul exitcode** beeindigd — puur timing-afhankelijk. Die
  flaky `$LASTEXITCODE` liet de exitcode-guard soms `$null` teruggeven, waarna de scaffold op VUL-IN
  bleef staan en de drift-test faalde. Een byte-exacte probe won de race consequent; de echte
  bootstrap soms niet — vandaar het "onverklaarbare" verschil.
- **`bootstrap.ps1`**: de git-aanroep en `Select-Object -First 1` zijn ontkoppeld. Eerst wordt de
  volledige output gevangen, dan meteen `$LASTEXITCODE` in `$code` vastgelegd, en pas daarna volgt
  `Select-Object` op de vaste array. Zo kan de pipeline-afbraak de exitcode niet meer corrumperen.
- **Gevolg:** de afleiding is nu deterministisch — de exitcode weerspiegelt uitsluitend git zelf,
  onafhankelijk van pipeline-timing.

Rondt de jacht af die in #94 en #95 begon; sluit de flaky-blokker onder PR #93.

[PR #96](https://github.com/DaveKJohn/davekjohns-workshop/pull/96)

---

### #95 · Bootstrap leest de origin rauw via git config (immuun voor insteadOf, CI stabiel) · Fix · 2026-07-19

Verhelpt de kern-oorzaak van de flaky RepoName-afleiding-test (opvolger van #94): de bootstrap las de
origin via `git remote get-url`, dat **`insteadOf`-herschrijvingen toepast**. CI-runners (en sommige
dev-machines) zetten zulke regels globaal, en welke vorm ze produceren (kale https, token-https,
`ssh://`) verschilt per run — waardoor de afleiding intermittent op VUL-IN terugviel en de test soms
faalde. De brede regex (#94) verzachtte dat maar nam de onvoorspelbaarheid niet weg.

- **`bootstrap.ps1`**: leest de origin nu via `git config --get remote.origin.url`, dat de **rauwe**
  opgeslagen URL teruggeeft en `insteadOf` volledig negeert — exact wat de consument configureerde,
  immuun voor de git-config van de machine.
- **`bootstrap-drift.tests.ps1`**: de flaky git-config-isolatie (lege global/system) is verwijderd
  (niet meer nodig); de zes afleiding-cases blijven. Bewezen: de suite slaagt nu ook onder een actief
  vijandige `insteadOf` die `git@github.com:`/`ssh://` naar een token-https herschrijft.

Geen gedragswijziging voor consumenten met een gewone origin; puur een deterministische, machine-
onafhankelijke afleiding.

[PR #95](https://github.com/DaveKJohn/davekjohns-workshop/pull/95)

---

### #94 · RepoName-afleiding dekt alle github-URL-vormen (regex verbreed, CI-flakiness weg) · Fix · 2026-07-19

Maakt de RepoName-afleiding (#91) robuust voor álle github-URL-vormen en verhelpt daarmee een
**flaky CI-test**: de git-afleiding-cases faalden intermittent op de windows-runner doordat die een
globale git-`insteadOf` zet die `git@github.com:` naar wisselende vormen herschrijft (kale https,
https met token-userinfo, of `ssh://`) — en `git remote get-url` past die rewrite toe. De regex uit
#91/#92 dekte niet alle vormen, dus soms viel de afleiding terug op VUL-IN en faalde de test.

- **`bootstrap.ps1`**: de derivatie-regex accepteert nu alle gangbare github-vormen —
  `https://`, `ssh://`, `git://` (elk met optionele userinfo) én de scp-achtige `git@github.com:`.
  owner/repo blijft een strikte slug; userinfo wordt niet gevangen (een `evil.com/x@github.com`-spoof
  matcht dus niet).
- **`bootstrap-drift.tests.ps1`**: de git-afleiding-cases draaien met een geneutraliseerde
  global/system git-config (elke case test echt zijn eigen URL-vorm, immuun voor runner-`insteadOf`),
  met een extra `ssh-scheme`-case (`ssh://git@github.com/...`).

Geen gedragswijziging voor consumenten met een gewone origin-URL; puur bredere dekking + een
deterministische testsuite.

[PR #94](https://github.com/DaveKJohn/davekjohns-workshop/pull/94)

---

## v1.10.0 — 2026-07-19

### #92 · Bootstrap schrijft een durabel, versie-loos body-importpad · Fix · 2026-07-19

Dicht een durability-gat dat een acceptatietest van consument djcylow-react aan het licht bracht
(Gat C): bij een user-scope install schreef de `specialists-init`-bootstrap een **versie-gepind**
body-importpad in `CLAUDE.md`
(`@~/.claude/plugins/cache/<marketplace>/<plugin>/<versie>/personas/01-01-persona.md`). De cache is
ephemeer — na een plugin-update wordt de oude versie-map opgeruimd (~7 dagen), waarna de `@`-import
naar een niet-bestaand pad wijst en de **body van de orchestrator (Chris) stil niet meer laadt**.

- **`bootstrap.ps1`**: nieuwe `Get-DurablePersonaDir` vertaalt een cache-pad
  (`…/plugins/cache/<marketplace>/…`) naar de versie-loze marketplaces-clone
  (`…/plugins/marketplaces/<marketplace>/…`) — het durabele anker dat een update overleeft (git-pull,
  pad verandert niet). De marketplace-naam wordt uit het cache-pad gerecupereerd; de clone wordt
  geverifieerd (bestaat, bevat de plugin-personas met `01-01-persona.md`) vóór hij wordt gebruikt.
  Bij elke twijfel terugval op het oorspronkelijke pad — geen regressie voor de source/marketplaces-
  layout (de bron die zichzelf consumeert verandert niet). De feitelijke *read* blijft de cache;
  alleen het geschreven pad wordt durabel.
- **Onderbouwing (research)**: `@`-imports in `CLAUDE.md` kennen géén variabele-expansie
  (`${CLAUDE_PLUGIN_ROOT}` e.d. werken daar niet), dus een vast versie-loos pad is de enige route.
- **`bootstrap-drift.tests.ps1`**: case (2c) toegevoegd die de user-scope layout nabootst
  (`plugins/cache/<mp>/…` naast een `plugins/marketplaces/<mp>/`-clone) en assert dat de geschreven
  `@`-import naar de clone wijst, niet naar de versie-gepinde cache.

Meegenomen robuustheidsfix aan de RepoName-afleiding (#91), aan het licht gekomen doordat CI-runners
een globale git-`insteadOf` zetten die `git@github.com:` naar een https-URL **mét token-userinfo**
herschrijft (`git remote get-url` past dat toe):

- **`bootstrap.ps1`**: de derivatie-regex tolereert nu optionele userinfo in de https-vorm
  (`https://<userinfo>@github.com/owner/repo`); de userinfo wordt bewust niet gevangen — alleen
  owner/repo, streng gevalideerd. Zo leidt ook een consument met credentials in de origin-URL correct af.
- **`bootstrap-drift.tests.ps1`**: de git-afleiding-cases draaien nu met een geneutraliseerde
  global/system git-config (zodat de ssh-case echt SSH test, immuun voor runner-`insteadOf`), plus een
  expliciete `https-cred`-case die de userinfo-tolerantie vastlegt.

[PR #92](https://github.com/DaveKJohn/davekjohns-workshop/pull/92)

---

### #91 · Bootstrap leidt RepoName automatisch af uit de git-remote · Feat · 2026-07-19

Ergonomie-verbetering aan het `specialists-init`-bootstrap-adoptiepad (Gat B): een verse consument
hoeft de repo-naam niet langer met de hand in te vullen.

- **`bootstrap.ps1` (sectie 1c)**: nieuwe `Get-DerivedRepoName` leidt `owner/repo` af uit
  `git remote get-url origin` van de consument en vult daarmee `$script:RepoName` in de neergezette
  `scripts/repo-config.ps1`-scaffold, in plaats van de `VUL-IN/repo`-placeholder. Ondersteunt de
  HTTPS- én SSH-vorm en stript het `.git`-suffix.
- **Guardrails (advies Sean)**: de remote-URL is externe input die in een geschreven `.ps1` én in
  `gh --repo` belandt — daarom een verankerde regex, owner/repo beperkt tot een strikte slug, alleen
  `github.com`, en bij elke twijfel (niet-github host, geen remote, git niet beschikbaar) terugval op
  de `VUL-IN`-placeholder. De git-aanroep zit in een `try/catch` + `2>$null`/`$LASTEXITCODE` en laat
  de bootstrap nooit crashen (blijft additief, exit 0). `Get-LintScript` en de branch-prefix-tabel
  blijven bewust VUL-IN — die zijn niet af te leiden.
- **Schonere scaffold-kop + slotrapport**: de kop van de repo-config-scaffold en stap 2 van het
  bootstrap-rapport melden nu wat er nog handmatig moet als RepoName al is afgeleid.
- **`bootstrap-drift.tests.ps1`**: cases toegevoegd voor de afleiding (HTTPS + SSH → afgeleid, geen
  VUL-IN op de RepoName-regel) en de terugval (niet-github host + geen remote → `VUL-IN/repo`).

[PR #91](https://github.com/DaveKJohn/davekjohns-workshop/pull/91)

---

## v1.9.2 — 2026-07-19

### #88 · specialists-init SKILL.md beschrijft het plugin-pad/lens-only-model (was: oude .claude/extensions-kopie) · Docs · 2026-07-19

Corrigeert een bestaande doc-drift in `specialists-init/SKILL.md`: de skill-tekst beschreef het
oude adoptiemodel (persona-bodykopie naar `.claude/extensions/`), terwijl `bootstrap.ps1` allang het
huidige model hanteert — **lens-only** repo-lenzen op het **plugin-pad**
`.claude/plugins/<familie>/<plugin>/`, met de draagbare body via een `@`-import uit de plugin-install,
en **twee** `@`-imports onderaan `CLAUDE.md` (body + lens).

- Frontmatter-`description`, de "Wat de skill doet"-stappen (persona-lenzen, lens-scaffolds, de
  @-imports) en de "Afronden"/"Belangrijk"-secties volgen nu het feitelijke bootstrap-gedrag.
- Puur documentatie: geen script- of gedragswijziging. De opgekomen drift was gesignaleerd tijdens
  de #86-fix en is bewust apart opgepakt.

[PR #88](https://github.com/DaveKJohn/davekjohns-workshop/pull/88)

---

## v1.9.1 — 2026-07-19

### #87 · specialists-init scaffoldt repo-config + branch-info; open-pr/fold pre-flighten (schone consument) · Fix · 2026-07-19

Dicht het script-afhankelijkheden-gat van de gedeelde workflow-skills op een schone consument (inbound
[#86](https://github.com/DaveKJohn/davekjohns-workshop/issues/86), vervolg op [#81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81)).
`open-pr`/`fold` leunen op twee repo-eigen bestanden in de consument-root (`scripts/repo-config.ps1` +
`scripts/lib/branch-info.ps1`) die de bootstrap niet neerzette — bij een eerste install liep dat op een
rauwe dot-source-fout.

- **Bootstrap-scaffold:** `specialists-init/bootstrap.ps1` zet beide bestanden nu additief als
  `VUL-IN`-scaffold neer (nooit overschrijven), met een **lege** branch-prefix-tabel — de taxonomie is
  per repo anders en wordt bewust niet meegebakken.
- **Pre-flight:** `open-pr` (beide bestanden) en `fold` (alleen `repo-config`) checken vóór de
  dot-source op aanwezigheid én op niet-ingevulde `VUL-IN`-placeholders, en stoppen anders met een
  duidelijke wegwijzer i.p.v. een rauwe fout. De spiegels zijn via de generator opnieuw gegenereerd.
- **Tests:** bootstrap-drift dekt de scaffold + idempotentie; shared-scripts dekt het pre-flight-gedrag
  van beide bron-scripts.
- **Docs:** de skill-teksten (`specialists-init`, `open-pr`, `fold-changelog`) en de plugin-scripts-README
  volgen het nieuwe gedrag; de fold-vereisten corrigeren meteen dat fold géén `branch-info` gebruikt.

[PR #87](https://github.com/DaveKJohn/davekjohns-workshop/pull/87)

---

## v1.9.0 — 2026-07-19

### #85 · Fase 2: open-pr gedeeld als plugin-spiegel (lint-gate via repo-config) · Feat · 2026-07-19

Tweede stap van Fase 2 uit [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81): `open-pr.ps1` wordt gedeeld met consumenten als plugin-spiegel, met dezelfde mechaniek als de fold-pilot.

- **`open-pr.ps1` dual-context** gemaakt (repo-root via `${CLAUDE_PROJECT_DIR}` of git-root); `repo-config` + `branch-info` uit de repo-root i.p.v. `$PSScriptRoot`.
- **Lint-gate geparametriseerd:** het repo-specifieke lint-script komt nu uit `Get-LintScript` in `repo-config` (workshop: `check-plugin-integrity`; een consument kan zijn eigen lint opgeven). De test-poort blijft conventie (`scripts/tests/*.tests.ps1`). Gate-meldingen zijn generiek gemaakt.
- **Spiegel + skill:** `open-pr` geregistreerd in `shared-scripts-lib.ps1`, spiegel gegenereerd, en een consument-skill `open-pr` toegevoegd.
- **Tests/docs:** `repo-config.tests.ps1` dekt `Get-LintScript`; `shared-scripts.tests.ps1` borgt dual-context voor álle gedeelde scripts; de README-statustabel bijgewerkt.

Daarmee zijn beide Fase 2-doelscripts (`fold` + `open-pr`) gedeeld; `branch-info`/`repo-config` blijven bewust per repo lokaal (CI-pin + repo-data).

[PR #85](https://github.com/DaveKJohn/davekjohns-workshop/pull/85)

---

### #84 · Fase 2-pilot: fold-changelog gedeeld als plugin-spiegel (SSOT voor consumenten) · Feat · 2026-07-19

Eerste stap van Fase 2 uit [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81): `fold-changelog-entry.ps1` wordt gedeeld met consumenten als plugin-spiegel — geen verhuizing, de workshop houdt zijn eigen testbare root-kopie.

- **Dual-context repo-root** in `fold-changelog-entry.ps1`: lost de repo-root op via `${CLAUDE_PROJECT_DIR}` (consument die de spiegel draait) of de git-root (workshop). Dezelfde file werkt in beide locaties; `repo-config` wordt uit de repo-root geladen i.p.v. `$PSScriptRoot`.
- **Spiegel-mechaniek** naar het bestaande `build-agent-defs`-patroon: `scripts/lib/shared-scripts-lib.ps1` (register), `scripts/sync/build-shared-scripts.ps1` (generator met `-Check`), en een drift-lint-sectie in `check-plugin-integrity.ps1` die bewaakt dat de plugin-spiegel LF-identiek blijft aan de bron.
- **Consument-skill** `fold-changelog` draait de spiegel via `${CLAUDE_PLUGIN_ROOT}` — het enige door de docs bevestigde mechaniek voor mens én Claude.
- **Tests:** nieuwe suite `shared-scripts.tests.ps1` (register-contract, in-sync-invariant, dual-context-borging, `-Check`-poort).
- **Docs:** `specialists/scripts/README.md` herschreven naar de werkende spiegel-mechaniek + statusoverzicht.

`open-pr` volgt als losse stap (de lint/test-gate moet eerst via `repo-config` geparametriseerd worden).

[PR #84](https://github.com/DaveKJohn/davekjohns-workshop/pull/84)

---

### #83 · Plugin-scripts-README: Fase 2-realiteit corrigeren (branch-info CI-pin + bin/-gaten) · Docs · 2026-07-19

Corrigeert twee onjuistheden in `claude-code-plugins/claude-specialists/specialists/scripts/README.md` die in #82 zelf ontstonden:

- **`branch-info.ps1` kan niet mee naar de plugin.** De README suggereerde dat dat kon zodra `open-pr.ps1` meeverhuist, maar dezelfde PR (#82) liet `release-lib.ps1` `branch-info` dot-sourcen; `release-lib` draait in CI vanaf een kale checkout, waardoor `branch-info` nu ook door CI aan de root is vastgeklonken.
- **De `bin/`-aanroepkeuze is niet settled.** `bin/` staat op de PATH van de Bash-tool (niet de PowerShell-tool), een mens kan het niet direct aanroepen, en Windows `.ps1`-als-kaal-commando + `${CLAUDE_PROJECT_DIR}`-beschikbaarheid zijn ongedocumenteerd. Een skill is het enige bevestigde alternatief. De README verwijst nu naar het Fase 2-addendum op [#81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81).

[PR #83](https://github.com/DaveKJohn/davekjohns-workshop/pull/83)

---

### #82 · Centraliseer workflow-scripts (SSOT): repo-config + type-bron + plugin-scripts-fundament · Feat · 2026-07-18

Eerste stappen op het SSOT-pad uit [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81) (inbound van life-hub), zonder big-bang:

**Fase 0 (repo-lokaal, CI-veilig):**
- Nieuw `scripts/repo-config.ps1` als enige bron voor repo-data (`Get-RepoName`, `Get-RepoBlobUrl`). De repo-naam-hardcode is weg uit `open-pr.ps1` (1x), `fold-changelog-entry.ps1` (2x) en `cut-release.ps1` (blob-URL geinjecteerd i.p.v. de literal-default in `release-lib.ps1`).
- DRY-lek gedicht: de branch-typen (Feat/Fix/Docs/Chore) hebben nu een enige bron in `branch-info.ps1` via `Get-BranchTypes`; `release-lib.ps1` leest die i.p.v. een eigen `$catOrder`-kopie.

**Fase 1 (alleen structuur):**
- Nieuwe map `claude-code-plugins/claude-specialists/specialists/scripts/` met een README als toekomstig SSOT-thuis; de lint-parse-scan (`check-plugin-integrity.ps1`) bewaakt die map nu mee. Er is bewust nog geen script verhuisd (aanroep-mechaniek volgt later).

**Tests:** nieuwe suites `branch-info.tests.ps1` (incl. het type-SSOT-contract) en `repo-config.tests.ps1`.

[PR #82](https://github.com/DaveKJohn/davekjohns-workshop/pull/82)

---

## v1.8.0 — 2026-07-18

### #80 · Bootstrap seedt plugin-pad + lens-only (adoptie-laag) · Feat · 2026-07-18

De laatste stap om het plugin-pad + lens-only-model écht overal de standaard te maken: de
**adoptie-laag**. `bootstrap.ps1` (de `specialists-init`-skill) seedt een verse consument nu op het
**plugin-pad** met **lens-only** persona-lenzen — precies wat deze repo en life-hub al hebben — i.p.v.
het legacy-pad met volledige body-kopieën.

- **`bootstrap.ps1`** zet de lenzen op `.claude/plugins/<familie>/<plugin>/` (familie + plugin
  afgeleid uit het install-pad, met fallback voor de versie-cache-layout). De persona-lenzen zijn
  **lens-only**: alleen de lens-only-kop + het VUL-IN-repo-lens-slot, géén body-kopie. `CLAUDE.md`
  krijgt **twee** `@`-imports voor Chris: zijn draagbare body uit de plugin-install
  (`@~/.claude/plugins/marketplaces/<marketplace>/.../01-01-persona.md`) én zijn repo-lens.
- **Regressietests** (`bootstrap-drift.tests.ps1`) herschreven: plugin-pad, lens-only, de twee
  imports, de versie-cache-fallback en de behouden legacy-body-drift-vergelijking (30 asserts).
- **Docs** (`QUICKSTART.md`, `connectors/README.md`) bijgewerkt naar het plugin-pad + lens-only-model.

De body laadt runtime uit de plugin-install; dat `~`-import-pad is (net als bij life-hub) niet volledig
via de fixture-tests af te dwingen — de tests dekken de pad-/lens-only-structuur, het live `@`-import-
gedrag is bewezen doordat life-hub het draait. Lint + alle testsuites groen.

[PR #80](https://github.com/DaveKJohn/davekjohns-workshop/pull/80)

---

## v1.7.0 — 2026-07-18

### #77 · Repo-lenzen naar het plugin-pad als standaard (primair + legacy-fallback) · Feat · 2026-07-18

De repo-lenzen van deze repo verhuizen van het legacy-pad (`.claude/extensions/`) naar het
**plugin-pad** (`.claude/plugins/claude-specialists/specialists/`) — de nieuwe standaard-locatie
(pariteit met life-hub). Om de andere consumerende repo's (life-hub, smartwatchbanden) niet te breken,
verwijst het gedeelde contract voortaan naar het **plugin-pad als primair, met het legacy-pad als
fallback** — een repo die nog op legacy staat blijft dus gewoon werken.

**Deze repo:**
- De 11 lenzen (incl. Ravi 06-24) + het handboek verplaatst naar het plugin-pad, met de relatieve
  link-diepte bijgesteld (2 → 4 niveaus). De 5 lege stubs (Paula/Bianca/Vera/Gwen/Cody) opgeruimd.
- De `@`-import onderaan `CLAUDE.md` → plugin-pad. Alle doc-verwijzingen (`CLAUDE.md`, `README.md`,
  het handboek) → plugin-pad. De persona-lens-index-regels naar locatie-onafhankelijke platte tekst.
- `check-plugin-integrity.ps1` scant nu de lenzen op het plugin-pad **én** het legacy-pad.

**Het gedeelde contract (raakt alle repo's, via de volgende release):**
- De ~20 agent-defs en de ~20 manuals verwijzen subagents nu naar het plugin-pad (primair) met het
  legacy-pad als fallback. De generieke lens-mention in het gedeelde `grens-inbound`-blok idem.

**Bewust uitgesteld (blijft werken via de fallback):** de **adoptie-laag** — `bootstrap.ps1` seedt
nieuwe consumenten nog op het legacy-pad, en `QUICKSTART.md` / `connectors/README.md` beschrijven dat
zo. Dat volledig omzetten (incl. de bootstrap-tests) is een aparte vervolgstap; tot die tijd landt een
verse consument op legacy en werkt hij via de fallback.

Lint en alle testsuites groen. De `## Releases`-CHANGELOG-entries zijn als historisch record ongemoeid
gelaten.

[PR #77](https://github.com/DaveKJohn/davekjohns-workshop/pull/77)

---

### #76 · Persona-sjabloon-intro's gededupliceerd (Ravi's eerste klus) · Chore · 2026-07-18

Ravi's eerste opdracht: de persona-sjablonen op duplicatie scannen. Bevinding — er zijn **geen
verbatim-gedeelde gedragsbullets** over de vier persona's (Chris, Bianca, Derek, Rendall); de
gedragsregels zijn bewust rol-geformuleerd (rol-nuance, niet harmoniseren). De énige verbatim-duplicatie
was het **intro-uitleg-commentaar** — een grotendeels identieke herhaling van het gesplitste model dat
`README.md` al vastlegt, en dat (in een HTML-commentaar) het gedeelde-blok-mechanisme sowieso niet kan
gebruiken.

Actie: het intro-commentaar in de vier sjablonen ingekort tot een korte verwijzing naar `README.md`,
met behoud van de rol-specifieke eerste regel. Netto ~33 regels boilerplate weg, en minder ruis die een
lens-only consument via de `@`-import meelaadt (sluit aan op de #69-schoonmaak). Het commentaar staat
boven de H1, dus `Get-PortableBody` raakt het niet — geen drift-regressie.

Conclusie voor de toekomst: het sentinel-mechanisme uitbreiden naar persona's heeft nú geen payload
(geen deelbaar body-blok); dat wacht tot een verbatim-gedeelde persona-bullet daadwerkelijk opduikt.

[PR #76](https://github.com/DaveKJohn/davekjohns-workshop/pull/76)

---

### #75 · Ravi (refactoring-specialist / DRY-bewaker) toegevoegd aan het team · Feat · 2026-07-18

Een nieuw teamlid in de `specialists`-plugin (groep 06, de vóór-de-merge-bewakers): **Ravi ♻️
#06-24**, de refactoring-specialist. Zijn vak is *single source of truth*: hij is de staande
verantwoordelijke voor duplicatie van **gedragsregels** (grenzen/werkwijzen) over agent-defs en
persona's. Zodra dezelfde regel op ≥2 plekken staat, slaat hij alarm en promoveert die tot één
gedeelde bron — beschikbaar voor de kring die de regel deelt, **niet** automatisch voor iedereen.

- **`specialists/agents/06-24-agent.md`** — de subagent-def (`@specialists:ravi`), die zelf het
  gedeelde `grens-inbound`-blok via sentinels gebruikt (dogfooding).
- **`specialists/manuals/06-24-manual.md`** — het draagbare vakboek, met "globaal = beschikbaar voor
  een deel, niet automatisch voor iedereen" als harde regel.
- **`.claude/extensions/06-24-extension.md`** — de repo-lens: wat Ravi hier bewaakt (de agent-defs +
  persona's van deze marketplace) en het `agent-shared/`-build-en-lint-mechanisme dat hij bedient.
- **Roster ingehaakt** in `CLAUDE.md`, Chris' routingtabel + twee ketens (parallelle
  kwaliteitscheck vóór PR én een eigen "duplicatie globaliseren"-keten), en het
  specialisten-handboek (`.claude/README.md`) + de root-README.

Ravi's eerste openstaande klussen: het gedeelde-blok-mechanisme uitbreiden naar de persona-sjablonen,
de Tier 2-sweep (eindbericht/gespreksgeschiedenis/branch), en een detectie-lint als
alarmbel-automatisering. Doel: het project zo klein en efficiënt mogelijk houden.

[PR #75](https://github.com/DaveKJohn/davekjohns-workshop/pull/75)

---

## v1.6.0 — 2026-07-18

### #74 · Gedeelde agent-def-blokken uit een enkele bron (build-en-lint) · Feat · 2026-07-18

Verbatim-gedeelde bullets onder **Grenzen** — de inbound-regel (19/19 agent-defs), de
webcontent-regel (3) en de Artifact-publiceer-regel (2) — werden tot nu toe in elke agent-def
handmatig gedupliceerd; één regel wijzigen betekende tot 19 bestanden aanraken. Ze komen nu uit
**één bron**, ingevuld door een generator en bewaakt door de lint-poort.

- **`claude-code-plugins/claude-specialists/agent-shared/<naam>.md`** — de canonieke bron van elk
  gedeeld blok (naast de plugin-mappen, zodat het niet met de plugin-cache meereist).
- **In de agent-defs** verschijnt elk blok tussen `<!-- BEGIN/END shared:<naam> -->`-sentinels. De
  inhoud staat er letterlijk (altijd-geladen, self-contained — Claude Code kent geen native
  transclusie in een agent-def), maar is als gegenereerd gemarkeerd.
- **`scripts/agents/build-agent-defs.ps1`** (+ `scripts/lib/agent-shared-lib.ps1`) — vult elke
  gemarkeerde regio uit zijn bron. Wijzig het bronbestand → draai het script → alle agent-defs bij.
  `-Check` meldt drift zonder te schrijven.
- **`check-plugin-integrity.ps1` (check 7)** faalt zodra een gemarkeerde regio afwijkt van zijn bron
  (hand-edit binnen de sentinels of een vergeten rebuild) — dezelfde poort die `open-pr.ps1` en CI
  al draaien.
- Regressietests in `scripts/tests/agent-shared.tests.ps1` (10 asserts) dekken de expansie, de
  drift-detectie, een BEGIN-zonder-END, een onbekend blok en de repo-in-sync-smoke.

De 19 agent-defs zijn puur omwikkeld met sentinels — nul inhoudelijke wijziging. Aanpassen van een
gedeelde grens kost voortaan één edit + één build in plaats van 19 handmatige wijzigingen.

[PR #74](https://github.com/DaveKJohn/davekjohns-workshop/pull/74)

---

## v1.5.2 — 2026-07-18

### #73 · Persona-indexregel locatie-onafhankelijk (bron-fix inbound #64) · Fix · 2026-07-18

De indexregel onder de titel van de vier persona-sjablonen (`01-01`, `03-02`, `05-05`, `05-06`) droeg een pad-diepte-afhankelijke markdown-link naar de repo-CLAUDE.md (`](../../CLAUDE.md)`). Die diepte klopt alleen op het legacy-pad (2 niveaus); op het plugin-pad (4 niveaus) was het een dode link, waardoor de draagbare body daar nooit byte-identiek aan de bron kon zijn.

- **De indexregel is nu platte tekst** (`Index: de repo-CLAUDE.md · …`), locatie-onafhankelijk. Een consument neemt de body op elk pad byte-identiek over — geen dode link meer.
- **De link-diepte-normalisatie in `check-consumer-drift.ps1` (`Get-PortableBody`) is verwijderd**, want overbodig geworden: er is geen pad-afhankelijke link meer om te normaliseren. Dit ruimt de workaround uit PR #68 (v1.5.0) op ten gunste van een bron-fix.
- De regressietests zijn navenant bijgewerkt: de twee normalisatie-tests zijn vervangen door één guard die borgt dat de indexregel geen pad-diepte-link meer draagt.

Dit is de bron-oplossing voor inbound life-hub [#64](https://github.com/DaveKJohn/davekjohns-workshop/issues/64): PR #68 doodde het vals-positieve `DRIFTED`-signaal aan de check-kant, deze wijziging neemt de wortel weg. Consumenten laten bij de volgende sync de link in hun indexregel vallen.

[PR #73](https://github.com/DaveKJohn/davekjohns-workshop/pull/73)

---

## v1.5.1 — 2026-07-18

### #72 · Persona-sjablonen en drift-check kennen het lens-only-model · Fix · 2026-07-18

Twee samenhangende punten uit inbound life-hub [#69](https://github.com/DaveKJohn/davekjohns-workshop/issues/69), beide gevolg van het lens-only-model dat een consument geen body-kopie meer laat bewaren:

- **Het `## Eigen aan deze repo (VUL-IN)`-slot is uit de vier persona-sjablonen gehaald** (`01-01`, `03-02`, `05-05`, `05-06`). Bij een consument die de body rechtstreeks importeert (lens-only) laadde dat slot — een bootstrap-instructie, geen persona-inhoud — als ruis mee in elke sessie. De sjabloon-intro-comments zijn navenant bijgewerkt.
- **`bootstrap.ps1` genereert het VUL-IN-slot nu zelf** bij het kopiëren van een persona, in plaats van het uit het sjabloon over te nemen — zo houdt een verse consument een duidelijke plek voor de repo-lens (DRY met de lens-scaffolds van stap 1b).
- **`check-consumer-drift.ps1` kent het lens-only-model.** Een consument-extension die met de `> Repo-lens (lens-only persona)`-blockquote opent, heeft per definitie geen body-kopie; de check meldt die nu als `LENS-ONLY` in plaats van de vals-positieve `DRIFTED`. Zo betekent een `DRIFTED`-melding weer altijd een écht werkpunt.

De regressietests in `scripts/tests/bootstrap-drift.tests.ps1` borgen dat het sjabloon schoon is, dat de bootstrap zelf een VUL-IN-slot toevoegt (geen drift-regressie op een verse kopie) en dat een lens-only extension als `LENS-ONLY` wordt gerapporteerd.

[PR #72](https://github.com/DaveKJohn/davekjohns-workshop/pull/72)

---

### #71 · Inbound-regel toegevoegd aan alle agent-defs · Docs · 2026-07-17

Elk van de 19 agent-defs in de drie plugins (`specialists`, `specialists-lifehub`,
`specialists-shopify`) heeft nu een eigen bullet in zijn **Grenzen**-sectie die de
inbound-route benoemt: verbeterpunten aan de gedeelde kern (de eigen agent-def en vakboek,
die van collega's, en alle andere onderdelen die de plugin draagt) bouwt een specialist
niet lokaal om; hij meldt ze via de vaste, afgesproken route — een issue met het label
`inbound` op de bron-repo van de plugin (het issue-sjabloon staat er al klaar), generiek
beschreven en zonder repo-eigen, persoonlijke of gevoelige details uit de eigen repo.
Werkt hij al in de bron-repo zelf, dan volgt hij daar gewoon de normale keten. Repo-eigen
aanvullingen horen in de repo-lens. Zo kent ook een rechtstreeks aangeroepen
werker-subagent deze regel, niet alleen Chris' persona-body en de QUICKSTART. De
formulering is na twee correctierondes (Edith's eindredactie: generieke plugin-onderdelen
+ collega's-agent-defs; Sean's security-review: standing-route-framing + de
anonimiseringscaveat) tot deze definitieve tekst gekomen.

[PR #71](https://github.com/DaveKJohn/davekjohns-workshop/pull/71)

---

## v1.5.0 — 2026-07-17

### #66 · Chris sluit af zonder vaste slotformule · Docs · 2026-07-17

Op verzoek van Dave: de vaste afsluitvraag ("hoe kan ik verder van dienst zijn?") is uit stap 6 van Chris' ritueel gehaald — die werd eentonig. Chris vat nog steeds samen en mag een concrete volgende stap noemen, maar sluit af zonder standaard slotformule. Aangepast in beide bronnen: de repo-lens (`.claude/extensions/01-01-extension.md`) en het canonieke persona-sjabloon in de plugin (`personas/01-01-persona.md`).

[PR #66](https://github.com/DaveKJohn/davekjohns-workshop/pull/66)

---

### #61 · Per-plugin CHANGELOGs: consument-gerichte release-geschiedenis die meereist · Feat · 2026-07-16

Elke plugin draagt nu een eigen `CHANGELOG.md` die met de plugin-cache meereist: de
consument-gerichte selectie uit de werkplaats-geschiedenis. De fold leidt per entry automatisch
een `Plugins:`-regel af uit de PR-bestanden (`gh pr view --json files`; de `connectors/`-map telt
niet mee), en `cut-release.ps1` schrijft bij elke release per plugin de rakende entries bij —
nieuwste bovenaan, met root-relatieve links herschreven naar absolute GitHub-URLs zodat ze in een
consument-cache blijven werken. Vier nieuwe pure functies in `release-lib.ps1` met twaalf nieuwe
asserts (50 totaal); drie seed-CHANGELOGs; Rendall's lens en het root-README beschrijven het
mechaniek. De root-`CHANGELOG.md` en `releases/` blijven de volledige werkplaats-geschiedenis.

[PR #61](https://github.com/DaveKJohn/davekjohns-workshop/pull/61)
