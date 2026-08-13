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

