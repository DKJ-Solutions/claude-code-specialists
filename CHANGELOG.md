# Changelog

The history of the claude-code-specialists marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

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
itself. The gates did run, locally, before the commit — but they did not run as CI, and that distinction
was not written down anywhere before now.

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
