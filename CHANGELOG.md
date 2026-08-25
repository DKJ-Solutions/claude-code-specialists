# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections. The `##` heading is the change's own — `` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `### What makes this deploy extra special` for the second audience, and `### Pull Request`.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
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

## DEPLOY: `docs/development-portable-rename-v1` · 20260825-222427

Renamed `DEVELOPMENT-CYCLE-portable.md` to `DEVELOPMENT-portable.md` and repointed every reference
to it repo-wide, so the manual's name no longer contradicts the working file it describes
(`development-cycle.md`, not `development-cycle-cycle`).

**Score:** 1 — cosmetic naming cleanup; no behavior, script contract, or consumer-facing change.

### What makes this PR extra special

N/A — an internal doc rename, nothing a subscriber of the service would ever see.

**Score:** N/A

### Pull Request

Rename DEVELOPMENT-CYCLE-portable.md to DEVELOPMENT-portable.md and update every reference

Plugins: workflow-davekjohn

[PR #893](https://github.com/DaveKJohn/claude-code-specialists/pull/893)

---

## DEPLOY: `feat/isolate-workflow-from-consumer-root-v1` · 20260825-204036

Nothing changes for this repo's own release runs today — the computed defaults exempt the source repo
outright, so `CHANGELOG.md` and `releases/` keep resolving to the exact root paths they always did. What
a developer here meets is the plumbing underneath: the two duplicate `Get-SeamValue` copies collapse into
one shared `seam-lib.ps1`, which also carries the four isolate-by-default seams and the new
`Assert-WorkflowIsolatedSeamPath` provenance preflight, backed by its own dedicated suite
(`seam-lib.tests.ps1`, 8 asserts) among the eleven suites this branch touched. Noticed the next time
somebody works in a release script, not before.

**Score:** 2

### What makes this PR extra special

A consumer no longer risks the plugin reaching into their repo root: the changelog, the three release-note
roots (`releases/development/`, `releases/github/`, `releases/internal/`) and the release-history index
all default inside `workflow-davekjohn/` now, and the provenance preflight refuses outright if a
consumer's own explicit override still resolves outside that folder. This closes a hazard that was
measured rather than theoretical — the root `*.md` sweep could misread a consumer's own permanent doc as a
stray, unfolded changelog entry, and two portable pages (`TICKETWORK-portable.md`,
`CONTRIBUTING-portable.md`) carried hand-written workarounds telling consumers how to dodge it; both are
gone now because the sweep itself no longer needs them — it reads content, not a name list. An
already-adopted consumer does have to notice this on their next fold or cut: entries land in
`workflow-davekjohn/CHANGELOG.md` rather than their root file from here on, and a pending entry already
sitting in their old root `CHANGELOG.md` is not picked up automatically — the re-adoption migration note
this branch added documents exactly that. The same split reaches `releases/README.md`: an already-adopted
consumer's release history moves to `workflow-davekjohn/releases/history.md` from here on (named
`history.md`, not `README.md`, because that folder already uses `README.md` for its own hand-written
seam-answers page) — old rows stay at the root file, new rows land in the folder, the same accepted-cost
duplication as the changelog rather than a silent redirect.

**Score:** 5

### Pull Request

Isolate the workflow from the consumer's repo root

Plugins: workflow-davekjohn

[PR #890](https://github.com/DaveKJohn/claude-code-specialists/pull/890)

---

## DEPLOY: `fix/remove-prompt-inbox-v1` · 20260825-155219

Removed the prompt-inbox mechanism entirely (issue #882, Dave): the `workflow-davekjohn/prompts/`
folder, the `prompt` skill, its two scripts (`prompt-inbox.ps1` + `prompt-inbox-lib.ps1`, root and
plugin mirror), the `prompt-sessioncheck` SessionStart hook, and every doc that named any of it — the
plugin's own README and scripts README, this repo's `workflow-davekjohn/CLAUDE.md` and
`workflow-davekjohn/README.md`, the root README's two skill-list spans, `SPECIALISTS.md`,
`connectors/README.md`, and a stale cost baseline. No replacement: Dave now hands assignments over as
GitHub issues instead.

Tier 1 — this repo's own contributors notice one fewer skill and, once merged, one fewer SessionStart
hook line; nothing in how a branch, PR or release works changes.

**Score:** 3

### What makes this PR extra special

N/A — nothing here reaches a service subscriber; the prompt inbox was a workflow-authoring convenience
inside this repo and its consumers, never anything an end user of a published product could see.

**Score:** N/A

### Pull Request

Remove the prompt inbox from workflow-davekjohn

Plugins: workflow-davekjohn

[PR #889](https://github.com/DaveKJohn/claude-code-specialists/pull/889)

---

## DEPLOY: `fix/release-notes-at-the-changelogs-own-level-v1` · 20260825-125958

**The generated developer release notes now render at `CHANGELOG.md`'s own heading levels.** Entries sit at
`##` and their sections at `###`, exactly where the fold wrote them, so an entry copied out of the record
into a hand-written note pastes at the level it was written at instead of needing a manual shift.
`Build-ReleaseNotes` no longer opens each tier group with `## Tier <n> - <audience>` — measured at `v4.19.0`
in [#881](https://github.com/DaveKJohn/claude-code-specialists/issues/881), that wrapper put all 35 entries
at `###` where their source had them at `##`, a pure one-level shift of every heading in the file. The tier
still decides the order (highest first, ranked inside a tier); it no longer prints a heading to say so,
because where a change reached is a claim about attribution and this document is the record of what changed.
Each entry states its own reach, so nothing is lost with the heading.

**The heading was machine-read, and that is the half the report did not see.** `new-internal-note.ps1`
filtered tier 0 out of the internal note by walking those `## Tier <n>` headings, with a documented
fallback — no tier headings means take everything — that would have carried all 11 tier-0 entries of a
release into the one document tier 0 exists to stay out of: no error, plausible output, a document written
for colleagues listing repo-internal housekeeping. `releases/development/4.x/4.8.0.md` had recorded this
dependency in so many words when it left the wording alone. The filter now reads each entry's **own**
declaration through `Resolve-EntryImpact` — the same reader `Get-PullRequestEntriesByTier` groups on, so
the two cannot disagree — and keeps the container heading as the fallback, because it is the only tier
information an archived note carries whose entries pre-date the declaration entirely, and this script takes
a version: it can be run against any release ever cut.

**`v4.19.0`'s own notes were regenerated rather than edited.** The 35 entries were read back out of
`CHANGELOG.md` at `9983299`, the commit before the cut, and re-rendered by the new generator; the
normalised diff against the published file is exactly the two tier headings gone plus one `---` at the
seam, and the heading profile now matches the pre-cut changelog's 35/70/7 line for line.
`Get-ReleaseTierHeading` and the `Heading` field are kept and documented as unrendered, for the reason
v4.8.0 already gave for this same heading: they are the single source of that wording, every note ever cut
carries it, and removing a published field of that contract is a decision of its own.

**Score:** 2

### What makes this PR extra special

A consumer's cut writes this document too, so the level correction and the repaired tier filter both
arrive with the plugin — including the failure the filter prevents, which a consumer would have met as
repo-internal entries appearing in the note they hand to colleagues. `RELEASES-portable.md` states the new
shape, so the page describing the document and the generator writing it agree.

**Score:** 3

### Pull Request

Developer release notes render at CHANGELOG.md's own heading levels

Plugins: workflow-davekjohn

[PR #883](https://github.com/DaveKJohn/claude-code-specialists/pull/883)

---

