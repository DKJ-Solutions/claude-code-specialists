### Repairing a claim means finding its other sites · Docs · 2026-08-02

The lesson from test round v12, recorded rather than left in a round-up comment. All three of the round's
core findings ([#372](https://github.com/DaveKJohn/davekjohns-workshop/issues/372),
[#373](https://github.com/DaveKJohn/davekjohns-workshop/issues/373),
[#374](https://github.com/DaveKJohn/davekjohns-workshop/issues/374)) turned out to have a **second,
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
[Tessa #16's manual](claude-code-plugins/claude-specialists/specialists/manuals/06-16-manual.md) as a hard
rule beside *"consistency first"* — those two are neighbours but not the same rule, since consistency-first
is about not duplicating a rule and this one is about a claim that **is** already duplicated. The concrete
evidence and the resulting habit (*grep the claim across the page before editing the reported line, and
treat a disagreeing passage as the likely-correct one*) go in the repo lens, where the issue numbers
belong.

**Deliberately not gated, and worth saying so.** Internal contradiction is not mechanically checkable in
general, so this stays a craft rule rather than a lint check. The narrower and genuinely buildable version
— *a measured figure in prose names what it was measured on*, extending check 15 beyond fenced samples to
byte counts and file sizes — is a separate decision and is not made here.
