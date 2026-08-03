# Changelog

The history of the claude-code-specialists marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

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
