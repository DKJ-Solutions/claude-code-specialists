## `docs/markdown-only-does-not-mean-script-free` changelog

### Branch title

Nine of thirty suites read this repo's own markdown

### Branch ID

20260811-113314

### Branch type

docs

### What does the change on this branch bring to main?

Answers item 2 of Nolan #25's own "three numbers owed" list in
[`06-25-extension.md`](.claude/specialists/lenses/06-25-extension.md#wall-clock-here--the-gates-and-the-baseline-measured-at-v420-august-10-2026):
which of the 30 suites in `scripts/tests/*.tests.ps1` can change behaviour on a markdown-only diff. Measured
rather than guessed, over all 30 files: **9** read this repo's own real markdown for content and can flip on
a docs-only diff, **21** build and read only their own fixtures and cannot, **0** were undecided. So the
assumption "markdown-only, therefore skip the second local run" does not hold in this repo — 9 of 30 read
real content a docs change can move.

The transferable half is not the count but the method that produced it, and the reason that matters is the
result it caught: the obvious guess — that the lint-gate suite (`check-plugin-integrity.tests.ps1`), which
exercises checks over agent defs, manuals and the changelog, must be one of the nine — is wrong. It builds
every document into its own fixture and is in the 21. A guess sorted by "sounds document-heavy" would have
put the wrong nine in the risk bucket; only reading each suite's source and citing the line that reads (or
doesn't read) the real repo root got the right nine. That is the repeatable part for any future "can a
diff of shape X change behaviour in suite Y" question: cite the line, don't infer from the suite's name or
subject matter.

No recommendation is made about whether to change how the second local run works — that is a change to
this repo's safety rules and is not this branch's decision to take.

### Significance

#### Tier 0

A repo-internal cost question — is a tempting optimisation (skip the second local suite run on a
markdown-only diff) actually safe here — is closed with evidence instead of instinct, and the answer is "no,
don't", with the nine named suites and their exact triggers as the record. That refusal-on-measurement is
the substantive part: without this branch, the next person tempted by that shortcut would either skip it on
a hunch (and might silently lose coverage on the 9) or re-derive the same 30-file audit from scratch to be
sure.

**Score:** 4

#### Tier 1

Colleagues on this project gain a citable answer to a question that was open in the shared lens, plus the
method (read the source, cite the line) for the next such audit — useful, but it is the same fact as tier 0
seen by a different reader, not a new one.

**Score:** 2

#### Tier 2

This measurement is about *this* repo's own thirty suites and their real-file reads — a consumer has a
different suite set, if any, and would have to re-run the same audit against their own tree rather than
inherit this count. Only the method travels, and the method is already carried by tier 0/1's record of how
it was done; there is nothing here written for a consumer to read.

**Score:** N/A

### Pull Request

