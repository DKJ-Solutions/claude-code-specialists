# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `docs/cut-release-docstring` changelog

### Branch title

The cut-release docstring describes the script that exists

### Branch ID

20260809-205550

### Branch type

docs

### What does the change on this branch bring to main?

`cut-release.ps1`'s header described a script that stopped existing over three separate decisions in
August. Measured against the code in the same file rather than proofread, **twelve** claims were wrong,
and the file already contradicted itself in two places: an in-line comment at the retirement point
records that steps 3b/3c are gone, and a seam comment further down records that `Get-ReleaseLiveMarker`
is retired — while the header above both still presented them as live.

**The half with teeth is the seam list, because that list is an interface.** A consumer configures this
shared script by defining optional functions in their own `repo-config.ps1`, and this header is where
they read which ones exist. It named seven; the script reads seven; **they were not the same seven**:

| named, but retired | read, but unnamed |
|---|---|
| `Get-ReleaseLiveMarker` — described the retired release block in `CHANGELOG.md` | `Get-LintScript` — which script the lint gate runs |
| `Get-ReleaseCategoryTitles` — labelled the retired category headings | `Get-ReleaseHistoryPath` — where the release overview table lives |

Both directions cost a consumer something, and the second more than the first. Defining a retired
function does nothing and *looks configured*, which is worse than an error. And `Get-ReleaseHistoryPath`
is the one this repo just paid for: cutting `v4.0.0` refused outright until a `#### 4.x` section was
opened by hand in the very page that function points at — a refusal a consumer would meet with no
documented way to know which file was meant. The list is now the seven the script actually reads, taken
from the script rather than from the previous list, and cross-checked against the script contract's own
registry, which independently names the same seven.

**The other ten are the tier-model drift, one layer below where the `v4.0.0` release just repaired it.**
The header still said `CHANGELOG.md` holds one section per tier, that the notes group by branch type
inside each tier, that a cut writes a reference under `## Releases` and empties "every tier section", and
that the model switches off in "a repo that declares a single section" — the exact test this repo has
recorded as a landmine, since a flat changelog gives an unadopted repo and an adopting one one group
each. Each of those is now what the code does, with the reasoning kept where it changes behaviour rather
than merely dated. Step 3d gained the condition it had always been missing: the highlights need a
**tier-2 entry** as well as a matching bump type, which is the whole of what keeps a tier-1-only minor
from handing an outsider a document about work they cannot see.

**One claim was corrected twice, which is the argument for measuring instead of reading.** The first
rewrite of step 3 said the entries are ranked within each tier by significance. The suites say otherwise
in as many words — *ranked from tier 1 up, and deliberately not at tier 0* — because the development note
is the record and keeps the order the folds left. A plausible sentence, written while repairing eleven
implausible ones, and it would have shipped as the twelfth.

**The retired step numbers 3b/3c are kept as headings that say they are retired**, rather than
renumbered. Consumers' own release notes refer to "step 3b", and a reader on an older copy of this
script should land on the answer instead of on a step that has quietly come to mean something else.

**The mirror was regenerated rather than hand-edited**, so the root copy and the one in
`workflow-davekjohn` stay byte-identical, which is what the shared-scripts drift lint enforces.

### Significance

#### Tier 0

This is the header a maintainer reads before touching the release cut, and it disagreed with the code
directly beneath it in two places. The next person to change this script would have been reasoning from
a description of the version before last.

**Score:** 3

#### Tier 1

The class is the one this project keeps paying for: a decision changes the mechanism and leaves the
sentence describing it. Three separate August decisions each left their traces here, in the one file
where the correction is a docstring rather than a document somebody has to remember exists.

**Score:** 3

#### Tier 2

The seam list is how a consumer learns what they may configure in a shared script they run but do not
own. It advertised two knobs that do nothing and hid one that a release cut refuses without — including
the refusal this repo hit today, which names no file.

**Score:** 4

### Pull Request

Plugins: workflow-davekjohn

[PR #554](https://github.com/DaveKJohn/claude-code-specialists/pull/554) · merged 2026-08-09

---

## `docs/v4-0-0-release-body-lead-in` changelog

### Branch title

The v4.0.0 release body says where the instructions are

### Branch ID

20260809-203951

### Branch type

docs

### What does the change on this branch bring to main?

A lead-in block at the top of the `v4.0.0` internal summary, matching the one `v3.10.0` received for the
same reason: that document is the **body** of the published GitHub Release, and the internal tier
deliberately carries no file names, no commands and no code — so where a reader has to act, the
instruction is on an attachment rather than on the page they are looking at.

**`v4.0.0` is the case that reads as not needing one, which is why it does.** The release itself asks
nothing of anyone: eleven documentation and pull-request-body changes, nothing breaking, nothing to run.
But a **major** is the version number most likely to make somebody open the page after skipping several
releases — and the chapter it closes contains **two** changes that break every existing installation
without producing an error message, the marketplace rename in `v3.2.0` and the plugin-id rename in
`v3.10.0`. A reader arriving from before either one has a session that starts normally with no specialists
in it, and a body that opens "this release asks nothing of you" is, for them, true and useless.

**So the block states both halves and hands off.** It says the release requires nothing, that the version
they are coming *from* may, and that the routing lives in the attached notes for users — which is where
the three from-which-version sections were written, one per breaking release, keyed on the state the
reader is in rather than on a version they have to work out for themselves.

**Written before the Release was published rather than after.** The body is a file, so a pointer added
later would mean editing a published page — and the ordering the closing checklist already enforces, that
the hand-written documents merge before the Release is created, is exactly what makes this the cheap
moment to notice it.

### Significance

#### Tier 0

The lead-in is now the second instance of a pattern rather than a one-off, which is what makes it
findable next time: the previous release's note carries the same block for the same structural reason.

**Score:** 2

#### Tier 1

This is the tier that reads the internal note, and it is the page's own opening. Before this block the
document told a reader on an old install that nothing was required of them, which is the one thing that
page should never say to that reader.

**Score:** 3

#### Tier 2

The published Release page is where a consumer lands from a version notification, and a major is the bump
most likely to be reached after skipping releases. This is the sentence that stops a silent broken install
from being read as a working one.

**Score:** 4

### Pull Request

[PR #553](https://github.com/DaveKJohn/claude-code-specialists/pull/553) · merged 2026-08-09

---

## `docs/v4-0-0-release-documents` changelog

### Branch title

The v4.0.0 release documents

### Branch ID

20260809-202557

### Branch type

docs

### What does the change on this branch bring to main?

The two documents `cut-release.ps1` deliberately does not write, for the major tagged earlier today: the
**internal summary** and the **consumer-facing highlights**. They arrive via a branch and a PR because the
release commit is already tagged, and neither is one of the two changes allowed to land directly on the
trunk.

**A major is a recap, so the milestone block was the first thing written and it went into the development
notes rather than here.** `v4.0.0` closes chapter 3 — twenty-one releases and fifty-one pull requests
between `v3.0.0` and `v3.10.0` — and `-SummaryFile` is the parameter that exists for exactly that: a
`-Title` is one sentence and the entries are per-PR, so neither can carry the arc. The recap was authored
against the release register and the chapter's own highlights rather than from memory, and it names the
thing a reader of a major most needs and is least likely to be told: chapter 3 shipped **two** silent
breakages — the marketplace rename in `v3.2.0` and the plugin-id rename in `v3.10.0` — neither of which
produces an error message.

**The highlights went from 319 lines to 87, and the cutting was not the work.** The generated draft is the
nine tier-2 entries verbatim, still in the words their authors wrote for someone reviewing a diff. What a
consumer needs from a `v4.0.0` page is almost the inverse of what those entries say: this release asks
nothing of them, so the page leads with that, and then spends its length on the question the version number
actually raises — *where are you updating from?* Three sections at the bottom route a reader to `v3.2.0`,
`v3.8.0` or `v3.10.0` by the state they are actually in, because those are the releases that do require an
action and none of them announces itself.

**The internal note is the published Release body, which is why its "what was still open" section is
written as a snapshot.** That is the section this repo has already measured going stale in hours rather
than months — once by a line stating that the previous release had no public page, published by the very
act it was describing. It says what was open *at the cut* and names nothing that the publish step itself
resolves.

**Two commits landed directly on `main` ahead of the cut, and they are named here rather than left in the
log.** `cut-release.ps1` refuses to file a `v4.0.0` row under a `3.x` heading and deliberately does not
open a new major's section itself; opening it then turned the live-document assert in
`release-lib.tests.ps1` red, by that assert's own instruction to be updated whenever a major section is
opened. The two halves are one fact written twice, and a cut is the one moment they may disagree — so both
were committed as release preparation, in the same spirit as the release commit they exist to enable.

### Significance

#### Tier 0

Neither document can be regenerated: the internal note is the one tier with no source to rebuild it from,
and the highlights draft is overwritten by any re-run of the cut. Writing them the same day is what keeps
the release record complete rather than "to be filled in".

**Score:** 2

#### Tier 1

This is the tier that reads the internal note, and on a major it is the one asking what ten days of work
added up to. It answers that with the chapter's arc rather than with the eleven entries that happen to
have been pending on the day the version was bumped.

**Score:** 3

#### Tier 2

The highlights are the consumer's page for a major, and the version number is what makes them open it.
The routing sections are the substance: a reader arriving at `v4.0.0` from before `v3.10.0` or `v3.2.0`
has a broken install and no error message telling them so, and this is the page where they find that out.

**Score:** 4

[PR #552](https://github.com/DaveKJohn/claude-code-specialists/pull/552) · merged 2026-08-09

---

## `docs/major-prep-exception` changelog

### Branch title

The release exception names the preparation a major needs

### Branch ID

20260809-215721

### Branch type

docs

### What does the change on this branch bring to main?

Cutting a new major takes two commits that land directly on `main` **before** `cut-release.ps1` will run
at all: the `#### <X>.x` section in the release overview, and the live assert that pins which major the
overview targets. `v4.0.0` needed both by hand on August 9, 2026 (`b2cea9c` and `1d2d3ff`) — under a
release exception that on paper covered only the release commit itself.

The exception now says so. The safety rules gain the mirror image of the rule they already carry for the
closing steps: preparation a requested cut cannot run without is covered by that same request, and
**bounded by it** — a major only, those two paths only, and only once the cut has been asked for. Outside
a cut both files take the ordinary branch + PR route. The same statement lands in Rendall #06's lens as a
numbered step 0, and in the portable `cut-release` skill, so a consumer cutting their own major does not
meet the refusal without knowing there is a documented way through it.

Neither half is automated, deliberately: opening the section is the milestone moment the script leaves to
a person, and the assert is one fact written twice on purpose — a script that repointed it would remove
the tripwire that caught the half-done edit here. What *was* repaired is the advice. The refusal named
only the section, so following it exactly still produced a red test and a second, unannounced commit; it
now names both edits and where they belong, pinned by four asserts in `cut-release-guardrail.tests.ps1`
against the block itself rather than the file, so the explanation in the comments cannot satisfy them.

### Significance

#### Tier 0

A major is not rare here — `v1.0.0` through `v4.0.0` fell on July 14, July 23, July 30 and August 9,
2026, roughly one every nine days — so the next person to cut one meets this within a fortnight, and
meets it as a documented step instead of an exception they have to decide about mid-cut.

**Score:** 3

#### Tier 1

The rule that was actually followed is on paper now, at its granted size. The value for a colleague is
less the procedure than the bound around it: this repo has already paid once for an exception that grew
past what it was granted at, and this one records its own limits in the same breath as its permission.

**Score:** 2

#### Tier 2

Both the refusal text and the `cut-release` skill travel to consumers. A consumer cutting `X.0.0` hits a
guardrail whose advice used to be complete-looking and short by one edit; they now get both, plus the
statement that these commits belong to the cut they already authorised.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #559](https://github.com/DaveKJohn/claude-code-specialists/pull/559) · merged 2026-08-09

---

## `fix/smartwatchbanden-is-gemigreerd` changelog

### Branch title

The connector register records smartwatchbanden's migrated plugin ids and its real org

### Branch ID

20260809-215340

### Branch type

fix

### What does the change on this branch bring to main?

`connectors/smartwatchbanden.json` now records what that consumer actually has. It migrated to the
`team-*` ids on August 9, 2026 — the three retired ids out, `team-alpha`, `team-shopify` and
`team-ecomm` in, plus `workflow-davekjohn`, which it had never had — and the register still named the
retired ones, so `check-connectors.ps1` reported it as unmigrated four times over.

Three things were measured while updating it, and only one of them is the migration:

- **The `repo` field named the wrong organisation.** It said `davekokbwj/smartwatchbanden`; the real
  remote is `BWJ-ecommerce/smartwatchbanden`, private. That drift is older than today's migration and
  no check can see it, because nothing here resolves the slug against GitHub — the checks all run
  against `localCheckout`, which was correct and is unchanged (the local folder genuinely is
  `davekokbwj/`). Worth knowing rather than repairing in code: a slug that is only ever read by a human
  is exactly the field that goes stale in silence.
- **`team-ecomm` had never been registered at all.** It was enabled in that consumer's
  `settings.json` well before today, so its three extensions are an addition, not a rename — the
  migration is what made anyone look.
- **`workflow-davekjohn` ships no `agents/`**, so its extension list is deliberately `[]`. An empty
  array is the measured answer; leaving the plugin out entirely would have said the consumer does not
  have it.

Verified after the edit rather than assumed: all four plugin blocks report `[OK]` on every line —
19 + 3 + 3 + 0 registered extensions present, each on source version v4.0.0. The register was updated
only after the consumer's own PR had merged, per its own rule that it records what a consumer **has**;
writing it earlier would have made the register itself the false alarm.

### Significance

#### Tier 0

`check-connectors.ps1` stops reporting a migrated consumer as unmigrated. Four `[INFO]` signals that
were correct yesterday became noise the moment that consumer moved, and noise in a check is how a
check gets ignored — the register is the only thing this repo has that says what consumers run.

**Score:** 3

#### Tier 1

Nobody but this repo's own developers reads the connector register; it is maintenance bookkeeping for
the source repo and is not shipped to anyone.

**Score:** N/A

#### Tier 2

A consumer never sees this file. Their own migration landed in their repo and is already merged there.

**Score:** N/A

### Pull Request

[PR #558](https://github.com/DaveKJohn/claude-code-specialists/pull/558) · merged 2026-08-09

---

