### The written notes for v3.3.0: the internal summary and the highlights · Docs · 2026-08-04

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
