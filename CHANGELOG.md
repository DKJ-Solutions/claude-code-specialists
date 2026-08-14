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

