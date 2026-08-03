# Release v3.1.2

**Date:** 2026-08-02  
**Type:** Patch

Round v12 processed: the teardown papers corrected, and the staleness gate reaches into prose

This card describes v3.1.2, the version your plugin manifest carries. Whether it is the code you are running is a separate question: the documented update path installs from `main`, so a `main` that has moved past the tag reports this same number. [The version is not the code](https://github.com/DaveKJohn/claude-code-specialists/blob/main/claude-code-plugins/claude-specialists/QUICKSTART.md#staying-up-to-date) in the QUICKSTART is the check.

## Documentation

### #378 · Repairing a claim means finding its other sites · Docs · 2026-08-02

The lesson from test round v12, recorded rather than left in a round-up comment. All three of the round's
core findings ([#372](https://github.com/DaveKJohn/claude-code-specialists/issues/372),
[#373](https://github.com/DaveKJohn/claude-code-specialists/issues/373),
[#374](https://github.com/DaveKJohn/claude-code-specialists/issues/374)) turned out to have a **second,
unreported site in the same document** — and in two of the three, the document already stated the truth
somewhere else and was simply disagreeing with itself.

- `UNINSTALL.md` told the reader to resolve `<plugin>` to a **cache** path, then three paragraphs later
  said Step 2 removes the tool sitting there — while its own #339 table at the foot of the page listed the
  cache as the one location **no step** closes.
- The over-generalised clean-machine claim appeared **twice**, one section apart. Only the first was filed;
  the second carried three byte figures from a single machine.
- *"no tags"* sat one bullet above *"its tag set is frozen at whatever came along when the clone was
  created"* — which only makes sense if tags come along — with a third *"tag-less"* further down the page.

**Why this is a hard rule and not good practice.** Two failure modes, and they compound. The unfixed site
is the one that **survives** into the next reader and the next round, and it survives precisely because
each half of a contradiction reads as reasoned on its own — nothing looks wrong at any individual line.
And the document frequently **already knows the answer**, which means the correct passage is free evidence
about which way to repair, sitting unused. Whoever files a finding sees the site that bit them; finding the
rest is the writer's job.

Landed in two places along the existing split: the portable rule goes in
[Tessa #16's manual](https://github.com/DaveKJohn/claude-code-specialists/blob/main/claude-code-plugins/claude-specialists/specialists/manuals/06-16-manual.md) as a hard
rule beside *"consistency first"* — those two are neighbours but not the same rule, since consistency-first
is about not duplicating a rule and this one is about a claim that **is** already duplicated. The concrete
evidence and the resulting habit (*grep the claim across the page before editing the reported line, and
treat a disagreeing passage as the likely-correct one*) go in the repo lens, where the issue numbers
belong.

**Deliberately not gated, and worth saying so.** Internal contradiction is not mechanically checkable in
general, so this stays a craft rule rather than a lint check. The narrower and genuinely buildable version
— *a measured figure in prose names what it was measured on*, extending check 15 beyond fenced samples to
byte counts and file sizes — is a separate decision and is not made here.

[PR #378](https://github.com/DaveKJohn/claude-code-specialists/pull/378)

---

### #377 · The cached clone does carry tags, and annotated ones invert the answer · Docs · 2026-08-02

Test round v12's [#372](https://github.com/DaveKJohn/claude-code-specialists/issues/372), against the #322
block in the `specialists-init` skill. Two things, and the second is the one that matters.

**The "no tags" clause was false, and it survived a round after being reported.** The bullet read the
fetch refspec `+refs/heads/main:refs/remotes/origin/main` as proof that the cached clone carries no tags.
The refspec governs later *fetches*; the initial `git clone` still brings along every tag pointing at
history it fetched. Both clones measured this round had them — a fresh one carrying `v3.1.1`, an older one
carrying 66. The block already contradicted itself on this point, since the very next bullet says the tag
set *"is frozen at whatever came along when the clone was created"*, which only makes sense if tags come
along at all. The clause is gone, and the other place that leaned on it (*"a shallow, tag-less clone"*) is
corrected with it.

**The substantive half of #322 was genuinely fixed, and the repair has a hole the original never
considered.** The block names two outcomes for resolving a tag locally: it matches, or you get
`fatal: ambiguous argument`. There is a third. This family's release tags are **annotated**, so
`git rev-parse v3.1.1` returns the *tag object* (`12b2d1b`) rather than the commit (`4b1a74d`). On a clone
sitting exactly on the release commit, the comparison therefore **succeeds** — no error, no missing tag —
and hands back a sha that does not equal `HEAD`.

That is the same inversion #322 was filed about, reached from the opposite side. The old failure mode was
*the tag is absent, so the failure reads as "not the release"*; this one is *the tag is present, peels, and
the mismatch reads as "not the release"* — while the reader is standing on it. And the false "no tags"
clause actively fed it, by telling the reader the comparison was impossible on a machine where it will
quietly run and lie. Both facts were verified against this repo before writing rather than taken from the
report: `git cat-file -t v3.1.1` returns `tag`, and `v3.1.1^{}` peels to the commit `HEAD` was on.

The third outcome is now named, with the measured triple, and the instruction is explicit: if you resolve
a tag locally at all, peel it with `^{}`. The `gh api …/tags` route is noted as immune — its `.commit.sha`
is the commit already.

[PR #377](https://github.com/DaveKJohn/claude-code-specialists/pull/377)

---

Full workshop notes: [releases/development/3.x/3.1.2.md](https://github.com/DaveKJohn/claude-code-specialists/blob/main/releases/development/3.x/3.1.2.md)
Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)
