# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #378 · Repairing a claim means finding its other sites · Docs · 2026-08-02

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

Plugins: specialists

[PR #378](https://github.com/DaveKJohn/davekjohns-workshop/pull/378)

---

### #377 · The cached clone does carry tags, and annotated ones invert the answer · Docs · 2026-08-02

Test round v12's [#372](https://github.com/DaveKJohn/davekjohns-workshop/issues/372), against the #322
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

Plugins: specialists

[PR #377](https://github.com/DaveKJohn/davekjohns-workshop/pull/377)

---

### #376 · The teardown papers, corrected against round v12 · Docs · 2026-08-02

Two findings from test round v12 ([#375](https://github.com/DaveKJohn/davekjohns-workshop/issues/375)),
plus the two measurements the round-up asked to be folded back in. All four are the same defect class:
**a sentence that was true of the machine it was written on, stated as if it were true of every reader.**

**[#373](https://github.com/DaveKJohn/davekjohns-workshop/issues/373) — `UNINSTALL.md` was wrong about when
its own instruments die, and it contradicted itself inside a single step.** Step 1 said the audit is
*"the last point at which you can produce it"* because `teardown.ps1` lives in the payload Step 2 removes.
Measured in v11 and again in v12: after `claude plugin uninstall … --scope project`, both `teardown.ps1`
and `UNINSTALL.md` are still on disk. The tool sits in the version-pinned **cache** — the very `<plugin>`
path Step 1 makes the reader resolve three paragraphs earlier — and the cache follows the *marketplace*,
not the install, which is exactly what this page's own #339 table has said all along. Step 2 takes the
record and the **data** directory and drops an `.orphaned_at` marker; the instruments survive until the
manual cache delete in Step 5.

The advice was never the problem and it stays: keeping the audit output is cheap. What changed is the
**reason**, and the cost of getting it wrong was concrete — Step 4 told a reader who had not kept the
output that their only route was re-install → re-audit → uninstall again, a full cycle for a script sitting
on their disk. Step 4 now offers the re-run from the cache first. #328's observation survives intact, one
step further down the page than it was filed: the procedure does remove its own instruments, at the end
rather than in the middle.

**[#374](https://github.com/DaveKJohn/davekjohns-workshop/issues/374) — Step 5's empty-key warning cannot
fire on the path this family prescribes.** #357's repair was correct about the behaviour and wrong about
its audience: a *user-scope* declaration does leave `"extraKnownMarketplaces": {}` behind, but the
QUICKSTART puts that key in the **repo's** `.claude/settings.json` and gives `marketplace add` as
`--scope project` precisely to avoid the #279 defect — and Step 3 has already removed it several steps
before Step 5 runs. The claim is now conditional, and the stronger half (*"**never** literally clean"*) is
gone: on a virgin profile every one of the six clean-machine rows came back literally clean.

That sentence mattered more than its size, because it is the one that tells a future round what its
step-0 table is *allowed* to look like. A round trusting it would have filed v12's fully clean baseline as
an anomaly. The mirror of the same over-generalisation, further down the page (*"a torn-down profile is not
byte-identical to a virgin one"*, with three byte figures from one machine), is now a two-column table
bracketing the range, with the instruction to read your own numbers against your own starting point.

**Folded back in, both from the round-up.** #336's honest note said v10 never captured a hash pair at the
moment of the install, so the page described what changed rather than proving it; v12 captured the pair,
and the 22-byte delta is exactly the two documented changes — *behaviourally equivalent, textually
different* is now measured rather than inferred. And #327's self-healing trap is refined from "an enable
key is enough" to the two conditions it actually needs: marketplace registered **and** cache present.
Three states measured on one profile pin it down, and the useful half was documented nowhere — **finishing
the teardown through Step 5 disarms the mechanism**, stray key or not. The warning is therefore about the
*half-finished* teardown, which is a sharper and more actionable thing to warn about.

[PR #376](https://github.com/DaveKJohn/davekjohns-workshop/pull/376)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

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
