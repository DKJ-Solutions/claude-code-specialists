# Changelog

The history of the claude-code-specialists marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #433 · The route for the two hand-written release documents, confirmed · Docs · 2026-08-04

**A rule that was actually an unanswered assumption now has an answer.** The edited highlights draft and
the filled-in internal note are both written *after* the cut — `cut-release.ps1` commits and tags in one
motion, and `new-internal-note.ps1` takes the development notes as its input — so the question of how they
reach `main` is unavoidable. It was put to Dave twice on August 3, 2026, went unanswered, and the
answer-shaped text ("via a branch + PR") was written into the docs anyway. Asked once more and answered:
**branch + PR, confirmed.**

**The alternative was concrete, and declining it is the substance of the decision.** The other option was
widening the direct-on-`main` release exception to cover "the release *and* its written notes", which would
have let both documents ride along. Declined for the reason this repo has already had to learn the hard
way: an exception is only safe while it stays the size it was granted at — the same principle that forced
the August 2, 2026 repair of `ship-pr.ps1`, whose fold step was making an unscoped commit under an
exception granted for a scoped one.

**The route has a measured instance now, not only an argument.** `v3.2.0`'s internal note shipped this way
in [PR #432](https://github.com/DaveKJohn/claude-code-specialists/pull/432) — gates green, entry folded,
and nothing about being written post-tag causing friction. So the confirmation records something that has
been run, which is what the previous wording lacked.

**One of the four documents the rule was said to live in did not carry it — and it was the one that
mattered most.** Checking before editing (rather than trusting yesterday's own note about where the text
had been placed) found the claim in `CLAUDE.md`, `releases/README.md` and the `cut-release` skill, but
**not** in Rendall's lens: the single place the release manager doing this work would look. That gap is
closed here, and the two root documents gained the attribution and the declined alternative so the next
reader sees a decision instead of a sentence with no origin. The portable `cut-release` skill was
deliberately left alone — it is person-neutral by design and already derives the route from the rule
rather than from an attribution.

[PR #433](https://github.com/DaveKJohn/claude-code-specialists/pull/433)

---

### #432 · The internal summary for v3.2.0 · Docs · 2026-08-03

**The first document in the third tier, and it is written rather than generated.** `v3.2.0` was cut before
`new-internal-note.ps1` existed, so it was the one release the "at every release" rule could not cover.
This closes that gap: the skeleton was generated from the release's own 21 entries and then filled in.

**Written to the tier's own constraints, which are stricter than they look.** The skeleton states them —
one page at most, 1-3 lines per subject, no file names, no code, and remove anything that means nothing
outside the team. Verified rather than assumed: 56 lines, zero file names, zero code fences, zero issue
numbers, and no skeleton comment blocks left behind. Those constraints are the tier: without them it grows
back into the developer notes it exists to avoid.

**What the release turned out to be about, once translated out of 21 technical titles.** Two halves. The
visible one is the rename and reorganisation, which every existing user has to act on once. The quieter and
more valuable one: work that was maintained three times is now maintained once, and four checks that
reported success without checking have been repaired — including one whose silence could switch off the
entire specialist layer without erroring.

**"What it is worth" is the middle heading and the only part no script could produce.** Four items, each in
terms of what it saves rather than what changed: maintenance paid once instead of three times; less false
confidence, which is the expensive kind, because nobody looks behind a green result; someone can now start
without help, after three separate people got stuck in the same place; and one working rule written down
that had already cost real repairs — verify a report's stated *reason* before building the fix on it.

**The open list names what a release cannot do.** The rename means every existing installation points at a
name that no longer exists, and nothing errors — it simply stops loading. That is documented rather than
fixable from this side, and it is stated as such instead of being left out because it is unflattering.

Plugins: specialists

[PR #432](https://github.com/DaveKJohn/claude-code-specialists/pull/432)

---

### #431 · The internal tier: a release summary for colleagues and employers · Feat · 2026-08-03

**The third tier, and the one that covers a patch.** `new-internal-note.ps1` is ported from the consumer
repo as a **shared** script and writes `releases/internal/<X>.x/<X.Y.Z>.md` — for colleagues, employers
and management, at **every** release including a patch. That last part is the whole reason it exists next
to highlights: the two answer different questions. Highlights is *what a consumer notices*; internal is
*what the organisation gets out of it*. They come apart most clearly on a patch — a release with nothing
for a consumer, correctly a patch and therefore without highlights, can still be the one where a routine
change stopped needing a developer.

**It generates only half, deliberately.** Version, date, type and the entry titles come from the
development notes; *"what it is worth"* cannot be derived from a changelog. So the output is a **skeleton**:
the metadata, the titles as `[type]`-prefixed bullets, and three fixed headings. The headings are fixed on
purpose — without that boundary this tier grows back into the developer notes it was created to avoid.

**Its own script rather than part of `cut-release`, and the reason changed on the way.** The source repo
kept it separate because `cut-release.ps1` was marked "temporarily diverged" and must not be extended —
which #417 settled, so that reason is gone. What holds instead is better: `cut-release` **commits and
tags in one motion**, so a skeleton generated there would put an empty document inside the release tag
while the written version landed afterwards anyway. Separate keeps the release commit what it is —
purely generated artefacts — while the one document that is human-written end to end travels the normal
reviewed route.

**So both hand-written documents ship via a branch + PR**, and that is now stated in `CLAUDE.md`, Rendall's
lens, `releases/README.md` and the skill rather than left to be worked out: the edited highlights draft and
the filled-in internal note are both written *after* the cut, when the release commit is already tagged, and
neither is one of the two named direct-on-`main` exceptions.

**`cut-release` now names what it did not write.** At the end of a run it prints the highlights draft still
needing an edit and the `new-internal-note.ps1` invocation — **gated on that script existing**, not on a
config knob, because whether a repo has an internal tier is a fact its file tree already answers. Same
reasoning as `Get-ReleasePluginTier`'s computed fallback. Printed on the `-NoPush` path too, where it is
most useful.

**English script, repo-owned document.** Console output and errors are English like every shared script
here, but the eleven strings that land *in the file* come from the optional `Get-InternalNoteWording` —
the #410 class, third time in `repo-config.ps1`. Merged over the English defaults, so a consumer
translating three headings does not silently lose the fill-in hints. Contract: 22 records → 23.

**Verified against real data, not only fixtures:** run against this repo's own `v3.2.0` notes it read all
21 entries, copied the date and type, and stripped every PR number and date from the titles. That probe
skeleton was then removed — the script belongs in this PR, the *written* note for v3.2.0 is content for a
separate one.

**Tests: a new suite, `internal-note.tests.ps1`, 52 asserts**, weighted toward the refusals rather than the
happy path — an existing note is the one document of the three that cannot be regenerated from anything, so
`-Force` being required is asserted by writing text into a note and checking it survives. Also: the folder
scheme really follows `Get-ReleaseNotesGrouping` (per-minor lands in `3.2/` and *not* in `3.x/`), only H3
headings count (an H4 inside an entry body does not become a bullet), missing metadata becomes a visible
`(fill in)` plus a warning rather than a blank line, and every document string is overridable while an
unmentioned key keeps its default.

**Two PowerShell traps hit while writing that suite, both now comments in it.** `$args` inside a function
is an *automatic* variable holding the caller's arguments, so assigning to it and splatting passes
something else entirely — it made a correct refusal look like exit 0. And `[string]$Param = $null` coerces
to `''`, so a fixture could not tell "no notes file" from "an empty notes file" and wrote an empty one,
which made the same refusal look broken while the script was right. Both were measured by running the
script by hand rather than reasoned about.

Plugins: specialists

[PR #431](https://github.com/DaveKJohn/claude-code-specialists/pull/431)

---

### #430 · Block a PR whose changelog entry still carries its scaffold wording · Feat · 2026-08-03

**A third gate in `open-pr.ps1`, and it was found by the highlights tier rather than by a review.**
Rendering v3.2.0 for a non-developer audience surfaced that three of its twenty-one entries (#424,
#425, #426) still carried the scaffold heading `new-branch` had written, with a status appended behind
it:

```text
**To do / where I left off:** phase 1 done -- lint gate green, all 23 suites green.
```

A progress note. Correct on the branch, wrong the moment it is published — and it had already reached
the release notes *and* the per-plugin `CHANGELOG.md` files that travel to consumers in the plugin
cache.

**Why a gate rather than a habit.** The window closes at the merge, and it closes **invisibly**: the
fold moves the entry into `CHANGELOG.md`, the next release moves it on into `releases/` and empties the
Pull-Requests section. By the time anyone would review it, the place they would look is the one place it
no longer is. Measured across all 70 archived release notes: one older instance, then three in a single
day — a rate, not a one-off.

**The wording became a single shared source first, because otherwise the guard could drift.**
`new-changelog-entry.ps1` hardcoded the three strings; the gate needs the same three. A copy in each
would let the gate silently miss whatever the writer changed — a drift guard that drifts, which is worse
than no guard because it reports success. So they moved to
[`entry-scaffold-lib.ps1`](scripts/lib/entry-scaffold-lib.ps1), a shared lib both scripts dot-source,
registered in the mirror. `Get-EntryFallbackType` deliberately stayed behind: a changelog *type* is not
scaffold prose, so `Chore` is a legitimate final value and can never be evidence of an unedited entry.

**Two deliberate design choices, both measured rather than assumed:**

- **Substring, not whole-line.** The shape that actually shipped kept the heading and appended to it, so
  a whole-line match would have passed all three real cases.
- **Fenced code excluded.** This repo's own docs quote that wording while explaining the mechanism —
  this very entry does, above — and a guard that cannot tell a quote from the real thing gets switched
  off. An unclosed fence hides the tail, which is the safe direction: a missed finding, never a false
  accusation against prose somebody did write.

`-Force` is the escape valve, deliberately separate from `-SkipLint`/`-SkipTests`: those skip a tool,
this overrules a judgement about content, and conflating them would let a routine "skip the slow suites"
also wave prose through. `ship-pr.ps1` passes it along.

**The contract check learned about indirection.** Three `Get-Entry*` records are now read by two scripts
through a lib, so neither names them directly. Rather than weaken the "really references this, not a
stale entry" assertion, records gained a `ViaLib` field and the check now proves **both** halves: the
script really dot-sources that lib, and the lib really names the function. That is stricter than what it
replaced — the old text match was satisfiable by a mention in a docstring, which is exactly how this
would have passed unnoticed.

**A pre-existing flaky test found and fixed on the way, and it is the more interesting find.**
`shared-scripts.tests.ps1`'s resolves-gate assert failed four runs in a row when the suite's output was
redirected to a file and passed four runs in a row when it went to the terminal — same commit, with
`open-pr.ps1` behaving identically both times (verified by stashing my change: it failed against `main`'s
version too). The cause is the documented one: `Write-Error` wraps at the child's own console width, and
this scenario normalized whitespace by *collapsing* it, which only survives a wrap landing on a space. A
mid-word wrap yields `resol` + `ves gate`. #415 fixed exactly this in the branch suites; this scenario
kept the weaker form. **Green in the setup a human watches, red in the one CI uses** — the worst
direction for a gate to fail in. Now stripped rather than collapsed, verified on both paths.

**Tests: a new suite, `entry-scaffold.tests.ps1`, 31 asserts.** The one it exists for is the round trip:
the real `new-changelog-entry.ps1` writes an entry in a throwaway repo and the real matcher is handed its
output. "The writer and the guard cannot disagree" is a claim about code; that assert measures it. Plus
the seam probe (an empty override is *ignored* — a blank marker is a substring of everything and would
refuse every PR in the repo), the exact v3.2.0 shape, and the fence handling in both directions.

Plugins: specialists

[PR #430](https://github.com/DaveKJohn/claude-code-specialists/pull/430)

---

### #429 · Drop the print-ready HTML from the highlights tier · Chore · 2026-08-03

**Dave, August 3, 2026: the HTML is not wanted anywhere.** So this is a removal from the *shared* code,
not a knob switched off in this repo — the tier can no longer produce HTML in any consumer, including the
one it was ported from.

**What is gone.** `ConvertTo-ReleaseHtml` and `Format-InlineMarkdown` in `release-lib.ps1` (88 lines,
ported and removed the same day), the `.html` write in `cut-release.ps1` step 3d, and the `HtmlLang` key
from `Get-ReleaseHighlightsWording` — which now carries two keys instead of three. The highlights tier
keeps doing everything else: the stakeholder/developer split, the metadata stripping, the marker.

**Why the removal is an improvement and not just a subtraction.** That renderer was the weakest part of
the port and the part needing the most explanation: a partial markdown subset that passed links through
as literal `[text](url)`, documented as a known limitation and pinned by a test asserting the limitation
stayed. A page that silently renders a link as its own source text is worse than no page. Anyone wanting
a PDF renders the markdown with a tool built for it.

**The generated `v3.2.0.html` is removed from `main`, and the `v3.2.0` tag still contains it.** That is
deliberate: a tag records a moment and is not rewritten. So `git show v3.2.0` and `main` differ by that
one file, which is stated in `releases/README.md` rather than left for someone to discover.

**Tests assert the ABSENCE rather than dropping the old asserts** (`release-lib.tests.ps1` 199, down 20;
`cut-release-guardrail.tests.ps1` 11, up 2). A partial HTML renderer is exactly the kind of thing that
gets helpfully reintroduced, so re-adding one should turn a test red: the two function names must not
resolve, the generated document must carry no HTML tag other than the marker comment it is built from,
and `cut-release.ps1`'s text must contain no `.html` path at all.

**Docs corrected in five places** — `CLAUDE.md`'s tier table, [Rendall
#06](.claude/specialists/lenses/05-06-extension.md), `releases/README.md`, the `cut-release` skill, and
the seam comments in `repo-config.ps1`. Each one said the tier produces a print-ready page.

**One consequence for the consumer, worth naming.** smartwatchbanden has eleven `.html` files under
`releases/highlights/` from its own unshared script. Those stay — they are that repo's history — but once
it picks up this plugin version its next cut produces markdown only.

Plugins: specialists

[PR #429](https://github.com/DaveKJohn/claude-code-specialists/pull/429)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

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
