## One fence reader, in the lib that owns the format

### What does this change do?

**There were four fence walks across the two libs, and they were not equivalent** — which is the finding,
not the tidy-up. `Get-FencedLineFlags` in `release-lib.ps1`, a second named function in
`entry-scaffold-lib.ps1`, and an inline walk inside each of that lib's two removers
(`Remove-EntryTierLine`, `Remove-EntryImpactTable`). Three of the four matched only backtick fences; **only
release-lib's recognised `~~~`.**

So an entry using tilde fences had its quoted content read as **structure** by every reader in
`entry-scaffold-lib` — the tier line, the impact table, the section headings, the ranked insert — while
release-lib's readers handled the same entry correctly. Nobody had hit it, because this repo writes
backtick fences; it was found by comparing the four walks rather than by anything failing. That is precisely
what "two answers that can drift" costs, and this one had already drifted before anyone looked.

**One owner now, and it had to be the lower lib.** The dependency can only run one way: the fold and
`entry-scaffold-lib`'s own suite load that lib standalone, while nothing loads `release-lib` without it. So
the canonical `Get-FencedLineFlags` moved down, keeping the union rule — the tilde form is honoured
everywhere now, which is strictly the safe direction: it can only stop a quotation being read as structure,
never the reverse.

**The name deliberately did not gain an `Entry` prefix on the way down.** Release-lib's three readers scan a
whole `CHANGELOG.md` rather than one entry, so a name claiming otherwise would be wrong at those call sites
— and keeping it meant the move changed **no call site in either lib**.

**The two inline walks went too**, via a small private helper that returns the split-with-separators and the
resolved flags together. Those two needed both facts, which is an awkward pair to derive twice — and
deriving it twice is exactly how the tilde gap survived unnoticed inside them.

#### Two asserts that had to be falsified before they could be trusted

**The first version of "no inline walk left" passed by looking at nothing.** It was written as an escaped
regex and matched nothing at all — the same class as the fixture that did not contain what it was written to
contain, which this suite has already paid for once. Rebuilt as a literal count and **checked against the
previous revision**: the old shape appears **3 times** there and the union rule **0**, which is what makes
the counts evidence rather than decoration.

**The second — "release-lib no longer defines it" — was falsified in both directions**, by building a
throwaway pair of libs and reading `ScriptBlock.File`: `False` where the upper lib only dot-sources, `True`
the moment it defines a copy of its own. So re-adding a per-lib copy turns a test red instead of being
silently shadowed and invisible, which is what a duplicate definition would otherwise be — both libs are
loaded together in every real caller.

#### What is deliberately still outside this change

Measured while scoping it, and stated rather than left for somebody to rediscover: **six more fence walks
exist in the script layer**, none of them a per-line-flag reader and none of them reachable from this owner
without a new dependency. `pr-body-lib.ps1` and `check-roster-sync.ps1` strip fences out of a text; the lint
gate has `Get-FenceMaskedText` (which masks rather than flags, to preserve character offsets) plus three
single-purpose walks of its own. Each would need its own dependency decision, and none shares the defect
this change repairs — the entry format's readers now agree with each other, which is what mattered.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 2 | a consumer whose entries use `~~~` fences stops having quoted text read as a real declaration -- a latent gap rather than one anyone had hit, so small, and noticed only if somebody points it out |
| 1 | 3 | the entry format's readers can no longer disagree about where a fence starts, which is the cause behind four separate defects in this format's first days -- a clear improvement, noticed the moment somebody touches that lib |

### Type of change

Fix
