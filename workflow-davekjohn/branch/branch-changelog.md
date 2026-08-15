## `docs/doctrine-layer-and-evidence` changelog

### Branch title

The layer table measures itself again, and the always-on path sheds its evidence

### Branch ID

20260815-230038

### Branch type

docs

### What does the change on this branch bring to main?

Three findings from the team-wide review of August 15, 2026, all about the documents that describe how
this repo documents itself.

**The layer table that carries the source-vs-lens doctrine was measuring nothing.** It read *"14
manuals, 4 personas and 9 skills"* and *"103 references across the 9 skills"*; the tree holds **15, 4
and 4** — a manual was added, and the August 8 workflow split moved nine of `team-alpha`'s skills into
`workflow-davekjohn`. `CLAUDE.md` points at this table as the evidence for the whole doctrine, so a
reader who checked found three wrong numbers and no way to tell whether the doctrine was wrong with
them. Re-measured: **250** references across the 4 skills (137 issue numbers, 93 repo names, 15
versions, 5 person names), and the table now states the **date and the method**, so the next reader
re-runs it in one command instead of trusting it.

**And the table's own claim was false — but by less than was reported, which changed the repair.** The
claim is specific: *"zero issue numbers, versions, repo names or person names"*. Dates are not in that
list, so Nolan's two dated measurements — reported as violations — are not violations at all; his
manual carries no forbidden category. What did violate it was **two person names**, both "Dave", in
Tessa's manual and Rendall's persona. Repaired by making the claim true rather than softening it: the
substance stays portable, the attribution moves to the lens. Rendall's needed no new home — `CLAUDE.md`
already records that decision and points back at his body. Tessa's had none, so her lens now carries
it, which is her own *"nothing silently drops"* rule applied to her own manual. The one `vX.Y.Z` a
regex still finds is Rendall's *"How he sounds"* line, an invented example of speech; the table says so
rather than pretending the count is zero.

**`CLAUDE.md` shed 9,440 B of evidence it was making every session pay for.** The lint-gate bullet
carried 102 lines of measurement history — the entry-format count and its four candidate rules, the
stale-path check declined at 124 findings all false, the PR template measured over 60 PRs, the two
repairs it took to reach `CHANGELOG.md`'s intro. None of it is a rule a reader needs before starting
work; all of it is *why* the rule is what it is. It moved **verbatim** to Sylvester's lens, beside his
existing description of those same checks, leaving the operative statement and a pointer. `CLAUDE.md`
goes from **36,967 B to 28,298 B — 23% smaller**, and this is the same split performed for the release
craft the day before, applied to the block that was sitting directly above it.

**A writing convention, because the review found a crack no gate can cover.** This repo argues from
measurement, and holds two kinds of number that read identically: ones a reader can recompute from the
tree, and snapshots of something outside it — which version a consumer runs, what an organisation has
installed. Only the first kind can be gated. The second already cost a published falsehood: `v4.11.0`'s
note told readers colleagues were *two* releases behind when they were one, *"false at the moment it
was typed"*, and the copy on the GitHub Release still carries it. The rule now sits in Tessa's manual —
a re-derivable figure states its method, an outside claim states that it was true when written and is
not verified since — with the instance and two named at-risk figures in her lens.

### Significance

#### Tier 0

Every session pays for `CLAUDE.md` before doing anything, and it is now 23% lighter with no operative
rule lost. The layer table is the evidence a reader checks before accepting where a rule belongs; it
now reproduces.

**Score:** 4

#### Tier 2

The manual and persona edits ship. A consumer reading Tessa's manual gets a new writing rule that
travels, and two portable documents stop carrying an attribution that belonged in a lens. Scored 2
because nothing a consumer does changes — it is the documents around them that got more honest.

**Score:** 2

### Pull Request

