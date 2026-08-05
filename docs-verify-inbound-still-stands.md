### An inbound issue is verified as still standing before it is routed · Docs

Tier: 2

**An inbound issue was picked up as open work an hour after it had been repaired.** #469 reported that
`fold-changelog-entry.ps1` kept the entry-creation date instead of the merge date. It was filed at
08:04; #472 repaired it on `main` at 09:24; it was still labelled open when the next session reached
for it. Nothing was built twice — the check that caught it was reading the code before starting — but
nothing in the intake required that reading either, and the outcome would have been a second repair
competing with the first on a defect nobody had.

**So the check is now the front of intake, in Chris's portable persona.** A filed report is a snapshot
of the moment somebody wrote it, and the gap between filing and pickup is exactly the window in which
the defect may already have gone — sometimes closed by the very work that was underway while the report
was being written. His first act on an inbound item is therefore to read the code, doc or output it
describes and establish that what it reports is still true, before classifying anything.

**This repo is where that gap is widest, which is why the rule is portable rather than local.** A
consumer *files* inbound issues; the source both receives them and does the repairing, so filing and
fixing can cross inside a single morning — and they did. But the rule is a timeless statement about
intake, not something only true here, so it goes to the source and the lens keeps just the citation
of where it was measured. The layer test in the
[Specialists handbook](.claude/specialists/README.md#where-a-new-rule-goes--the-source-is-the-default-the-lens-is-the-exception)
is what decided that, and it is the reason the persona text carries no issue numbers or dates at all.

**Closing an already-repaired item is stated as the assignment, with the evidence attached** — because
two things about #469's close showed that "check first, then close" is not enough on its own:

- **The repair had gone further than the report proposed.** #469 offered three options and preferred
  restamping the date at fold time; what shipped removed the date from the heading altogether and let
  the fold add it at the bottom. A silent close would have left the reporting repo applying the
  documentation fix it had planned — which was now the wrong wording, since the author no longer writes
  a date at all.
- **The audit the report suggested in passing was worth running.** #469 noted that anyone auditing an
  existing `CHANGELOG.md` could compare each heading's date against `gh pr view --json mergedAt`. Run
  here across `CHANGELOG.md` and `releases/`: **7 of 326** dated headings disagree, all by one or two
  days. They are deliberately left alone — they sit in published records that already travelled to
  consumers in the plugin cache, and moving a date by a day rewrites shipped history for no reader's
  benefit. Both entries still pending in `CHANGELOG.md` were correct.

**And the companion rule it does not replace.** This repo already required that a finding's *reason* be
verified before it is repaired, after an inbound report whose symptom was real and whose explanation was
wrong. That guards against repairing the wrong cause; this one guards against repairing a cause that is
already gone. The persona now names both in order: establish the report still stands, *then* verify the
reason it gives.
