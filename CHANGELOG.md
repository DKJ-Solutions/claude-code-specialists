# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`workflow-davekjohn/releases/README.md`](workflow-davekjohn/releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `docs/v4-12-0-release-note` changelog

### Branch title

The v4.12.0 release note

### Branch ID

20260816-114831

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this morning: the consumer section rewritten from
the cut's draft against the seven writing tests, and the two organisational sections no script can
generate.

**The item that led *what was still open* for five consecutive releases is closed, and it leads the
consumer section instead.** The merge re-running the gates the pull request had already proved was
named without being acted on at `v4.7.0` through `v4.11.0`; `#728` repairs it. So the document's first
no-action section is the one telling a consumer to stop reaching for `-SkipLint -SkipTests`, which is
the behaviour change they will actually feel. Test 3 orders by urgency, and a five-release backlog item
being gone outranks everything else in the release.

**The publication line was read at the target rather than carried forward, and it had moved.**
`v4.11.0`'s note -- corrected once already -- said colleagues were on 4.10.0. Read live from
`BWJ-ecommerce/claude-plugins-bwj` at commit `d528567`: the four team plugins are on **4.11.0**,
published 2026-08-15T15:44:13Z, taken from the `plugin.json` files themselves rather than from the
publishing commit's own message. That is the habit `#694` established being applied at the first
opportunity to inherit a wrong line instead.

**And the previous note was checked for a second correction, which it does not need.** `#694`'s
correction merged at 14:42:11Z and the publication ran at 15:44:13Z -- 62 minutes later -- so that line
was **true when published and went stale afterwards**, which is the record working rather than a false
line to repair. `4.11.0.md` is therefore left untouched, and the check is recorded here so the next
reader does not re-derive it.

**The migration item leads the section for a third release running**, now naming three intervening
notes rather than two. A consumer updating from 4.8.0 or earlier is no more carried past v4.9.0's two
actions by 4.12.0 than by 4.10.0 or 4.11.0.

**Fourteen tier-2 entries became six consumer sections plus a short list**, which is the rewrite the
skill budgets for rather than a trim. Four entries carry no heading of their own: the two decisions
recorded as decisions, the layer-table re-measurement and the documentation corrections are internal
craft, and their consumer-facing halves survive as one bullet each under *smaller fixes you may
notice*. Test 2's line is what removed them -- they describe our effort, not the reader's outcome.

**Step 0a's first pass is a subtotal of 4m 57s to the pushed tag**, against `v4.11.0`'s 5m 25s,
`v4.10.0`'s 5m 12s, `v4.9.0`'s 5m 36s and `v4.8.0`'s 5m 02s -- the fifth consecutive head inside a
thirty-nine second band. The cut's test gate ran 43 suites in **158s** against the 218s that had been
the floor, reported as a single observation rather than a trend: the machine was otherwise idle and the
suite split from `#730` landed between the two measurements. About two minutes blocked a person, higher
than recent releases because the release was named by asking rather than by deciding alone -- a choice
about this release, not a cost of the procedure, and the document says so in those terms.

### Significance

#### Tier 0

The release's own record of what it cost and what it closed, including the first head measurement taken
after the suite split.

**Score:** 2

#### Tier 2

The one document a consumer reads to decide whether to update -- and this release's headline is a
behaviour change they act on, since the workaround they have been using is now the wrong reflex.

**Score:** 4

### Pull Request

[PR #732](https://github.com/DaveKJohn/claude-code-specialists/pull/732) · merged 2026-08-16

---

