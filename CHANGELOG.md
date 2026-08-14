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

## `feat/workflow-folder-scaffold` changelog

### Branch title

A consumer gets the workflow folder scaffolded, and the session check reports it missing

### Branch ID

20260814-094602

### Branch type

feat

### What does the change on this branch bring to main?

Phase 2 of the workflow folder (Dave, August 14, 2026): a consumer can now receive the folder's
contents, and hears about it while they have not. Three pieces:

**The `adopt-workflow-folder` skill + shared script** (`scripts/task/adopt-workflow-folder.ps1`,
mirrored and registered like its sibling `adopt-config`) scaffolds `workflow-davekjohn/` in one move:
`README.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `releases/README.md` with the history table header the
cut inserts its row after, `releases/audience/` (a `.gitkeep` until the first cut), and the branch
dossier in its reset state — written by the same formatters `new-branch` and the fold call, so the
scaffold cannot write a shape of its own. Dry-run by default, strictly additive, never overwrites;
refused in a repo that publishes plugins, because the source keeps its docs at its root (Dave's
decision when the folder was scoped). A plugin install writes nothing into a repo, which is why this
is a skill and not an install step.

**The session signal**: `check-script-contract.ps1` now reports `[ERROR]` while `workflow-davekjohn/`
does not exist — existence only, since the folder's contents legitimately differ per repo — surfaced
at session start by the script-contract hook, naming the skill that closes it.

**Two release-machinery repairs the relocated releases root needed**, both latent until a consumer
answers `Get-ReleaseNoteRoot` with `workflow-davekjohn/releases/audience`: the history-table row is
now computed relative to the history file's own directory (`Get-RelativeLinkPath`, new in
`release-lib.ps1`) instead of stripping a hardcoded `^releases/` prefix — the exact "root outside
releases/ would need a `../` here" case the old comment said no repo had asked for yet — and the
hand-written note's link prefix is derived from the note's own depth instead of the fixed `../../../`.
For this repo both derivations produce byte-identical output to the old code, which is what made
replacing them safe.

### Significance

#### Tier 0

The two release repairs are latent here (this repo's layout produces byte-identical output), and the
new script is refused in this repo by design — the working difference is one more registered mirror
and one more [OK] line at session start.

**Score:** 1

#### Tier 2

The folder model becomes usable: a consumer installing the workflow gets told at session start what to
run, one skill places everything portable in one folder, and the first cut against the relocated
releases root writes working links instead of dead rows.

**Score:** 4

### Pull Request

Plugins: workflow-davekjohn

[PR #656](https://github.com/DaveKJohn/claude-code-specialists/pull/656) · merged 2026-08-14

---

## `feat/workflow-folder` changelog

### Branch title

The branch dossier moves into the workflow's own root folder

### Branch ID

20260814-085807

### Branch type

feat

### What does the change on this branch bring to main?

The `branch/` directory — the entry, the step list and the generated templates — moves from the repo
root into `workflow-davekjohn/`, the workflow's own root folder. This is phase 1 of gathering
everything portable about the workflow in that one folder at every consumer (Dave, August 14, 2026),
instead of scattering it through their root; phase 2 adds the scaffold skill that places the folder's
docs (`README.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `releases/README.md` + `audience/`).

Concretely: `Get-BranchFilePaths` and the template-dir constant now answer
`workflow-davekjohn/branch/...`, so every shared script (`new-branch`, `open-pr`, `ship-pr`, the fold,
the cut's unfolded-entry guard) and every seam-reading lint check follows in one move. The three
genuinely hardcoded sites moved with it: `Get-MojibakePaths` in `scripts/repo-config.ps1` now covers
`workflow-davekjohn/` whole (forward-compatible with phase 2's scaffolded docs), and two test fixtures
pin the new location. The PR-template placeholder names the new path — recognise four, write one: the
three older placeholder strings stay recognised because every consumer's template carries one of them
right now. The directory itself moved by `git mv`, with the moved `README.md`'s relative links
repointed one level deeper, and the live docs (portable pages, skills, lenses, root docs) now name the
new location; dated records and release notes keep the old name, as published records do.

**No dual-read of the old root `branch/` location, deliberately** (Dave): `new-branch` creates the new
directory on the first branch, and a repo still carrying a root `branch/` from before removes it by
hand. One consequence to know: `Get-MojibakePaths` is an `Adopt = 'copy'` seam, so a consumer's copy
taken before this change still names the old location and drops the moved files out of mojibake
coverage until they re-adopt — the contract record now says so, and phase 2's scaffold will surface it.

### Significance

#### Tier 0

The branch files, the templates and this repo's own muscle memory move to a new path; every script
follows the seam, so the working difference is one directory level.

**Score:** 2

#### Tier 2

Every consumer's branch dossier lands in `workflow-davekjohn/branch/` after the plugin update — the
first visible piece of the one-folder model — and a leftover root `branch/` must be removed by hand.

**Score:** 4

### Pull Request

Plugins: workflow-davekjohn

[PR #654](https://github.com/DaveKJohn/claude-code-specialists/pull/654) · merged 2026-08-14

---

## `docs/v4-8-0-release-note` changelog

### Branch title

The v4.8.0 release note

### Branch ID

20260813-204153

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged tonight: the consumer section rewritten from the
cut's draft against the seven writing tests, and the two organisational sections no script can
generate.

**The consumer section leads with the one item that asks the reader to re-check something** — an
audience-tier answer given from strings that stated the superseded ladder — and gives the check in one
look: who reads your release notes decides your tier, not who uses your product. The other items are
opt-ins: one seam answer to put a whole test suite behind the gates, one deletion to replace a
hand-copied process page with the plugin's maintained one, and a pointer back at `v4.7.0`'s notes.

**The *what it is worth* section is built on the release's own shape: four of the seven changes arrived
as consumer-filed inbound issues, each measured against a real adoption attempt.** The section names
what the organisation stops paying — not the 4,154 hand-copied words per mirror, but the standing risk
that a page a consumer's gates enforce against them describes a convention three claims out of date —
and records that both silent failures this release closed had produced plausible output the whole time
they stood.

**Step 0a's first pass is a subtotal of 5m 02s to the pushed tag**, three times less than `v4.7.0`'s
frozen 15m 31s, and the note says plainly that the gates cost the same three-and-a-bit minutes in both:
the difference is a pre-flight of two reads, on the second consecutive cut to start on the first
attempt. It names that five-minute figure as the fixed cost the release-cadence trade should be
computed against.

### Significance

#### Tier 0

The record of what a clean release now costs (about five minutes to the pushed tag) lives here or
nowhere, and it is the figure the next "make releases cheaper" discussion should start from.

**Score:** 3

#### Tier 2

It is the only document written *to* a consumer for `v4.8.0`, and it leads with the one item that asks
them to act: re-checking an audience-tier answer that, given wrong, silently degrades every release to
a patch — the failure one consumer already met.

**Score:** 4

### Pull Request

[PR #651](https://github.com/DaveKJohn/claude-code-specialists/pull/651) · merged 2026-08-13

---

## `feat/contributing-into-workflow-folder` changelog

### Branch title

The contributing documentation becomes two layers, and the workflow's layer wins

### Branch ID

20260814-105051

### Branch type

feat

### What does the change on this branch bring to main?

The contributing documentation becomes **two layers, deliberately** (Dave, August 14, 2026). The root
`CONTRIBUTING.md` does not move and does not describe the plugin any more: it is the **standard
workflow** — branch + PR, CI green, merge — the page that stays meaningful in a repo where the plugin
is absent: a fresh checkout, a teardown, a contributor who installed nothing. Beside it, as an **extra
file**, `workflow-davekjohn/CONTRIBUTING.md` carries the workflow's layer: everything the plugin owns
(the branch dossier, the folded entry, the significance model, the release cycle) plus this repo's
answers to the seams — the content the root page used to hold. **Where the two disagree, the workflow's
page wins**; the rule is stated on both pages, in the portable half
(`CONTRIBUTING-portable.md` gained a "two contributing pages" section), and in the
`adopt-workflow-folder` scaffold, whose consumer template now opens with it.

An earlier reading of this assignment moved the root file into the folder; Dave corrected it mid-build
— "het verhuist niet, het komt als extra bestand erbij" — and the move was reverted before anything
shipped: `Get-ReservedRootMd` still lists `CONTRIBUTING` (the root page is permanent), README and
SECURITY keep pointing at the root page as the entry point, and `CHANGELOG.md`'s intro points its
mechanism sentence at the workflow layer, which is the page that actually describes the mechanism.

### Significance

#### Tier 0

Where a rule lives is now answerable in one sentence — standard rules in the root, plugin rules in the
folder, folder wins — and this repo's seam-answers table moved to the page a reader of the folder finds
first.

**Score:** 2

#### Tier 2

A consumer's root CONTRIBUTING.md is never rewritten by adoption: the scaffolded folder page arrives
beside it, states that it wins on conflict, and the portable page now says so — closing the open
question of what adopting the workflow means for a repo that already has contribution rules.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #661](https://github.com/DaveKJohn/claude-code-specialists/pull/661) · merged 2026-08-14

---

## `feat/releases-into-workflow-folder` changelog

### Branch title

The audience releases and their history move into the workflow's own root folder

### Branch ID

20260814-102908

### Branch type

feat

### What does the change on this branch bring to main?

Phase 3 of the workflow folder (Dave, August 14, 2026): this repo now carries the `releases/` half of
the folder it ships — `releases/README.md` (the release history) and `releases/audience/` (the
hand-written notes) moved by `git mv` into `workflow-davekjohn/releases/`, and the two seams follow:
`Get-ReleaseHistoryPath` answers `workflow-davekjohn/releases/README.md`,
`Get-ReleaseNoteRoot` answers `workflow-davekjohn/releases/audience`. The generated
`releases/development/` and `releases/github/` trees stay at the repo root, as decided when the folder
was scoped. The shared defaults do not move — an unstated seam keeps meaning what it meant yesterday —
and phase 2's two derivations (the history row computed relative to the README, the note's link prefix
from its own depth) are what make this repointing safe: for the new layout they produce
`../../releases/development/...` rows and `../../../../` prefixes instead of dead links.

What moved with it: the moved records' links repointed one level deeper (prose untouched, the standing
published-record rule — six dead links in `releases/development/` archives repointed the same way), the
live docs and the two lenses now name the new paths, the lint's link scan covers the whole workflow
folder by deriving it from the branch seam, the history exclusions of checks 11/12/20 recognise the new
address alongside the old, and `find-specialist-mentions` files the moved records as history while
keeping the README live at both addresses. `Get-ReleaseHistoryPath`'s copy record now carries the
folder answer, so `adopt-config` and `adopt-workflow-folder` propose the same location.

One latent phase-1 defect surfaced and is repaired here: the lifecycle checks' branch-dir exclusion
compared the seam's forward slashes against a backslash path and had silently stopped matching since
the branch move — separators are now normalised, the same lesson check 20 already recorded.

### Significance

#### Tier 0

Every release-history edit, hand-written note and its lint coverage moves address; the cut writes rows
and notes to the folder from now on.

**Score:** 3

#### Tier 2

The folder a consumer adopts is now also the folder the source itself runs: the shipped seam copy and
the scaffold propose the same `workflow-davekjohn/releases/` location, and a consumer's first cut
against it writes working rows.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #659](https://github.com/DaveKJohn/claude-code-specialists/pull/659) · merged 2026-08-14

---

## `feat/publish-to-business` changelog

### Branch title

The marketplace publishes to the business repo with one script

### Branch ID

20260814-120015

### Branch type

feat

### What does the change on this branch bring to main?

The marketplace can now be published to the business organisation with one script
(`scripts/release/publish-to-business.ps1`), so Claude Enterprise can sync a private business repo
as a plugin marketplace and colleagues without GitHub access receive the plugins. The model: this
repo stays the single source of truth, the business repo is a publication target that every run
overwrites — it empties the target (except `.git`) and rebuilds it from a fixed published set
(manifest, `plugins/` including `agent-shared/`, the reader-facing root docs — 148 files, measured
by the dry run; `scripts/`, `.claude/`, `connectors/`, `releases/`, `workflow-davekjohn/` and the
governance root docs are the maintainer's half and stay behind), so a plugin removed here disappears
there too. Before committing it verifies that every
`source` in `marketplace.json` resolves to a folder with a `plugin.json` in the rebuilt tree — a
manifest pointing at a folder that did not travel is invisible here and loud for every colleague, so
it is a hard stop with nothing committed. Versions are untouched: the lockstep bump of the release
is the update signal, and the commit message records the source commit and every plugin version it
carried, so the target's history reads as a release log.

Four things around the script itself:

**The target lives in the seam, not in the script.** `Get-BusinessMarketplaceRepo` in
`scripts/repo-config.ps1` names `BWJ-ecommerce/claude-plugins-bwj` — the same rule that moved
`Get-RepoName` out of `open-pr` — read as an optional function with a fallback; `-TargetRepo` stays
as the override for a second organisation, and no seam plus no parameter is a refusal, not a guess.
Deliberately **not** in the script contract and not mirrored into the plugin: like the blueprint
generator, this is the marketplace source's own tool, and a consumer would be answering a question
no script of theirs reads.

**Windows PowerShell 5.1 compatibility, repaired rather than assumed — three defects, and the third
was invisible to the testing that found the first two.** The script was written and tested on
PowerShell 7.4.6. On 5.1 its raw `& git ... 2>&1` under `$ErrorActionPreference = 'Stop'` would die
on the first stderr progress line (the #96/#97/#107 lesson) — git clone and push write their
progress there — so every git call now runs through the shared `native-capture-lib.ps1` guard, with
output stringified before the report's `Group-Object` substrings it. `git init -b` (needs
git >= 2.28) became `init` + `symbolic-ref`, so the fresh-history path has no version floor.

The third came out of the code review and is the one worth recording: under
`Set-StrictMode -Version Latest` a **missing property is a terminating error on 5.1 and silent on
7.4.6**, measured on all three shapes the script used (a missing property, a missing top-level key,
`.Count` on a non-array). So `$plugin.source` threw before the integrity check that exists to
explain a malformed manifest could report anything — which means the manual test *"missing required
manifest field → clean error"* passed on the machine it was run on and would have failed on the
convention this repo actually runs. Every JSON field is read through a `Get-JsonField` helper now,
so the defensive branches are reachable and the reader gets the named problem instead of *"The
property 'source' cannot be found on this object"*.

**Tests without network or tokens**: `scripts/tests/publish-to-business.tests.ps1`, 34 asserts
against a fixture source repo and local bare targets (`git init --bare`) — first publication,
idempotence (second run publishes nothing), a version bump travelling as exactly one change, the
integrity hard stop with the target history untouched, a deletion travelling once the manifest
agrees, dry run committing nothing, the seam answering, the no-target refusal, and the two
malformed-manifest shapes above, each asserted on the message rather than only the exit code —
both paths exited 1 before the repair too, so an exit-code assert would have been green over the
bug. Two asserts in `repo-config.tests.ps1` hold the seam value's form.

**Publishing is a boundary, documented where releases are documented**: Block 3 of the
`cut-release` skill (the `Get-LiveStage` pattern — driven by facts of the repo, absent for every
consumer) and a paragraph in `RELEASES-portable.md`. Publishing is a separate, deliberate decision
after the cut, only on the owner's explicit request — releasing without publishing is a normal
outcome, not a half-finished one (Dave, August 14, 2026).

The marketplace name stays `claude-code-specialists` even though the target repo is called
`claude-plugins-bwj`: the name is the key in every consumer's `enabledPlugins`, and aligning it with
the repo name would break that line in every consuming repo (Dave's decision, recorded at the seam).

### Significance

#### Tier 0

The release manager gets a tested, gated publication step where publishing used to be impossible
without hand-copying 148 files; the seam keeps the target out of the script and the suite keeps the
delete-before-copy model honest.

**Score:** 3

#### Tier 2

Nothing changes for any current consumer until the owner actually publishes: the new checklist block
tells them explicitly it does not exist for their repo. The reach it prepares — colleagues receiving
the plugins through Claude Enterprise without GitHub access — arrives with the first publication,
not with this merge.

**Score:** 2

### Pull Request

Plugins: workflow-davekjohn

[PR #663](https://github.com/DaveKJohn/claude-code-specialists/pull/663) · merged 2026-08-14

---

## `docs/v4-8-0-timing-total` changelog

### Branch title

The v4.8.0 release note gains its end-to-end total

### Branch ID

20260813-210057

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.8.0`'s note was frozen at a 5m 02s subtotal; the five remaining legs — writing the
document (3m 48s), its gates (3m 12s), its CI (7m 33s), the merge with the fold (3m 54s) and the
publish (20s) — are added, giving a **total of 23m 49s** from clock start to a published Release with
its attachments.

**The tail was 18m 47s, 79% of the total — and within forty seconds of `v4.7.0`'s 19m 26s.** Four timed
releases have now produced four different fractions, but the last two agree on something more useful
than a fraction: the tail is nearly constant in absolute terms, because it is made of fixed legs — this
CI run landed within two seconds of the previous release's, the document gates within three seconds.
The fraction grew only because the head shrank. That moves the optimisation question: the head is at
five minutes and nearly all gates, so the next saving lives in the tail's one duplicated leg — the
merge re-running the suites the PR already proved — measured here at about three of the merge leg's
3m 54s, consistent with `v4.7.0`'s 3m 18s.

**The copy attached to the GitHub Release is the frozen one**, and the note says so, following the rule
`v4.7.0` set: an attachment is what was published at the moment of publication, and silently replacing
it is the opposite of the record the document is for.

### Significance

#### Tier 0

The fourth timed release turns "the tail is unpredictable" into something sharper — the tail is
constant, the head is what varies — which redirects the next optimisation from the head (already at
five minutes) to the duplicated merge-leg gate run.

**Score:** 3

#### Tier 2

A consumer reads the release note, so a measured claim inside it is a claim made to them; this one
tells them where a release's time actually goes, on numbers from two consecutive releases that agree.

**Score:** 2

### Pull Request

[PR #652](https://github.com/DaveKJohn/claude-code-specialists/pull/652) · merged 2026-08-13

---

## `feat/rename-finds-every-mention` changelog

### Branch title

a rename gets a tool that finds every live mention

### Branch ID

20260813-225519

### Branch type

feat

### What does the change on this branch bring to main?

`scripts/sync/find-specialist-mentions.ps1` reports every live mention of a specialist's **name**,
grouped by the layer it sits in, so a rename can be finished by hand without missing a place. Run bare
it prints the overview — every specialist, their live count, how many of those sit in link text, and
how many are history. Run with `-Name <specialist>` it prints each mention with `file:line`, split
into **context** (read by a model every session), **docs** (read by a human on GitHub), **scripts**
and **tests**, with **history** counted but not listed unless `-IncludeHistory` is passed.

**The roster is derived, never hardcoded** — the same two sources and the same reasoning as the
teardown skill's audit: an agent def's `name:` frontmatter and a persona's H1. A hardcoded list would
be a guess that rots at the next rename, which is precisely the event this tool exists for. A name
that is *not* in the roster is scanned anyway rather than refused, because verifying a **finished**
rename means asking about a name that has just been retired.

**It is a tool, not a gate, and that is the decision rather than a first step towards one.** A check
matching on names is the shape this repo has already been bitten by: the name-matching candidate
measured for the entry-format check produced six findings, all six false. And the one rename this repo
has performed — Sean → Sebastian, `a437df9`, July 22, 2026 — *deliberately left mentions standing*
(the history, and the attribution comments in scripts and tests, which record who said something on a
day when that was their name). A gate would need an exemption list holding exactly what that rename
decided to keep. A gate that is argued with is a gate that gets switched off, so this one prints and
the reader decides. It exits 0 on every finding — a count is never a failure — and a test asserts the
tree is untouched after four runs.

**Three measurements came out of building it, and they are why the alternatives were declined.** The
question that started this was whether specialist names should become keys with a central value. All
three were taken with the script itself, against the tree as it stood **before this branch**, so they
are reproducible by checking out that commit and running it:

- **A rename's cost is not uniform.** Chris has **179** live mentions across 59 files; Sebastian has
  **46** across 18 — a factor of four. Nothing before this could tell you that number before you
  started, and it is what decides whether a rename is an afternoon or a minute.
- **Only 7.5% of live mentions sit in link text** — 97 of 1,291. So replacing the name there with the
  id (`[#16]`) or the filename (`[06-16-extension]`) reaches a fourteenth of the problem. `#16` also
  collides with the **2,404** `#nnn` references outside `releases/` and `CHANGELOG.md` — `#12` is
  demonstrably both Gwen and PR 12 — and the filename form costs **46% more characters** (88 link
  texts of the form `[Name #NN]` average 10.3 characters against 15) in files loaded every session.
- **A quarter of those link-text mentions are grammatically part of the sentence** (`[Rendall
  #06](…)'s domain`, `[Tessa #16](…) guards the split`), where a bare id or filename reads as a file
  doing a person's work.

Full substitution was researched before being declined: Claude Code has no substitution layer for free
text — `@`-imports are file inclusion and `${CLAUDE_PLUGIN_ROOT}` is path resolution — so it would be
self-built tooling with no platform support, a second generator (the existing one copies whole blocks
between sentinels, not words mid-sentence), inflection rules for possessives, and a new silent failure
mode where an unexpanded placeholder ships to consumers as literal context.

Documented at the two places a renamer looks: the entry-point table in
[`scripts/README.md`](scripts/README.md) and the stable-id section of the
[specialists handbook](.claude/specialists/README.md), which is where the repo already states that
names are free to change.

31 tests in `scripts/tests/find-specialist-mentions.tests.ps1`, against a fixture carrying invented
specialists (Zephyr, Quill) so the counts are decided by the suite rather than by whatever the real
tree happens to contain that week.

**Review found three defects the first version shipped with, and two of them were invisible in the
output** — worth recording because all three are the same class: a report that is confidently wrong is
worse than one that errors.

1. **Counting per line, not per occurrence.** A line naming a specialist twice — once inside a link,
   once in prose — was reported once and filed as *link text (reading aid)*, hiding the prose half
   behind a "safe to leave" label. Real instance: `06-25-extension.md:430`. The docstring's own
   example, *"Chris never acts as Chris"*, is the same shape.
2. **A one-line file reported nothing.** PowerShell unrolls a one-element array on return, so the
   caller indexed a bare string character by character while `.Count` still read 1. Every one-line
   file — most of the `.ps1` fixtures — was silently skipped.
3. **`[regex]::Matches` is case-sensitive where `-match` is not**, so moving between them dropped
   `name: tessa` — the very line a rename must change first.

A hardcoded nine-path allowlist for "human documentation" was replaced with a filename rule in the
same round: it had already missed `.claude/specialists/README.md` (eleven mentions of Chris, filed as
model context) and six READMEs under `plugins/`.

Plugins: —

### Significance

#### Tier 0

The one moment this repo has to rename a specialist, it currently has grep and hope. This turns that
into a list with `file:line`, split by whether the name is content or reading aid — and, in the
overview, tells you the size of the job before you accept it. It is noticed the moment somebody
touches that part, and not before: renames are rare here (one in four months), which is exactly why
nobody carries the knowledge of where the names are.

**Score:** 3

#### Tier 2

The script is repo-owned and is not mirrored into any plugin, so nothing reaches a consumer. Whether
it earns a mirror is deliberately left open until it has been used at a real rename — the same
"has it earned it" test the repo applies to every shared script.

**Score:** N/A

### Pull Request

[PR #653](https://github.com/DaveKJohn/claude-code-specialists/pull/653) · merged 2026-08-13

---

## `feat/workflow-folder-docs` changelog

### Branch title

The workflow folder carries its own README and CLAUDE.md in this repo too

### Branch ID

20260814-112403

### Branch type

feat

### What does the change on this branch bring to main?

The workflow folder's last two residents arrive in this repo (Dave, August 14, 2026):
`workflow-davekjohn/README.md` — the folder's index, naming each page and its portable half, and the
two deliberate differences with a consumer's folder (the generated release trees stay at this root, and
the page is hand-written because the scaffold refuses a plugin source) — and
`workflow-davekjohn/CLAUDE.md`, the working rules a session needs in this folder: the branch files
belong to the current branch, the entry folds verbatim, the release index writes its own rows, records
keep their prose, templates are generated, and the folder's CONTRIBUTING wins over the root's on
conflict. Written by hand as this repo's own answers, exactly like the folder's other pages; consumers
already receive their versions from the `adopt-workflow-folder` scaffold, which is unchanged.

### Significance

#### Tier 0

The folder now answers "what is this and how do I work here" on its own doorstep, and a session that
reads a file in the folder loads the CLAUDE.md rules with it.

**Score:** 2

#### Tier 2

Nothing in the plugin payload changes; a consumer's folder already carries both pages from the
scaffold.

**Score:** N/A

### Pull Request

[PR #662](https://github.com/DaveKJohn/claude-code-specialists/pull/662) · merged 2026-08-14

---

