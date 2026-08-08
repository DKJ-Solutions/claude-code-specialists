# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `fix/adopt-config-plugin-root` changelog

### Branch title

The adopt-config page stops sending consumers to the author's own disk

### Branch ID

20260809-010428

### Branch type

fix

### What does the change on this branch bring to main?

The `adopt-config` skill page printed both of its commands as an absolute path into the plugin author's
own cache — `C:/Users/DaveKok/.claude/plugins/cache/.../3.8.0/scripts/...` — and shipped that way in
`v3.8.0` and again in `v3.9.0`. Wrong for every consumer twice over (a different username, often a
different OS) and pinned to a version that goes stale at each release. It was the **first command a
consumer runs to reach v3.9.0's headline feature**, which is the release that had just gone out.

**Found by verifying an instruction rather than by reading the page.** The v3.9.0 highlights were about
to tell consumers to run the same script through `$env:CLAUDE_PLUGIN_ROOT`, and checking whether that
actually resolves — it does not, outside a plugin-owned component — is what surfaced the page behind it.
The `cut-release` skill has this lesson written down about its own first command; `adopt-config` was
written after it and did not inherit it.

**The page now uses `${CLAUDE_PLUGIN_ROOT}`**, like the other ten skill pages, and says in one paragraph
what that form does and does not resolve — so a reader who wants to paste the line in a terminal knows
why it will not work there.

**A gate, because the page was correct-looking and nothing read it.** New lint check **22**: the `-File`
argument of a runnable command in a shipped `SKILL.md` may not be an absolute path.

**The subject is the COMMAND and not the path, and that was decided by measuring rather than by
argument.** The obvious rule — no absolute paths under `plugins/` — is **born with three findings and
all three are correct**: comments in `check-report-lib.ps1` and `check-roster-sync.ps1` that quote
`C:\Users\x\.claude\...` precisely in order to explain a path-mangling bug. A check that needs an
exemption list on its first run is the shape this repo already has scar tissue from, so the rule reaches
only the one token a reader is told to execute. Over the tree's **26** invocations in **11** skill
pages: 23 use the substitution, 3 use a `<plugin>` placeholder, **0** exemptions.

**The `<plugin>` placeholder passes on purpose**, and that is asserted rather than left implicit: angle
brackets ask the reader to substitute, while an absolute path reads as a line to paste. A test pinning
only the positive would pass against a stricter check that starts accusing the teardown page.

**The script's own check list was three behind, and is caught up in the same change.** The docstring
enumerated checks 1–18 while 19, 20 and 21 had been added without being listed — adding a 22nd to an
already-stale list would have widened the gap it sits in. All four are now described.

Six asserts pin both directions plus the deliberate pass, including a POSIX home path, which a
drive-letter-only rule would miss.

**Noted, not repaired: the teardown page's three commands use `<plugin>/...` where every other page uses
the substitution.** Honest, and strictly worse than a form that actually resolves when the skill runs —
but it is a consistency question rather than the defect this branch is about, and bundling it in is how
a diff stops being reviewable.

Plugins: specialists-workflow-davekjohn

### Significance

#### Tier 0

The check list in the lint's own docstring was three entries behind and is now current, which matters to
whoever adds check 23. The gate itself costs a developer here nothing: the tree already passed it.

**Score:** 2

#### Tier 1

Nothing here is legible outside this repo's own developers and the consumers below — there is no
organisational effect distinct from the consumer-facing repair itself, which tier 2 states.

**Score:** N/A

#### Tier 2

A consumer following the `adopt-config` page ran a command naming a directory that does not exist on
their machine. That is the entry point to `v3.9.0`'s headline feature, so the failure landed on the
readers most likely to be adopting. Not a 5: the skill route worked all along, so nobody was blocked —
they were sent to a path that could only fail, with no hint of the working alternative.

**Score:** 4

### Pull Request

Plugins: specialists-workflow-davekjohn

[PR #529](https://github.com/DaveKJohn/claude-code-specialists/pull/529) · merged 2026-08-09

---

## `docs/v3-9-0-release-documents` changelog

### Branch title

The v3.9.0 release documents

### Branch ID

20260809-000412

### Branch type

docs

### What does the change on this branch bring to main?

The two hand-written documents `cut-release.ps1` deliberately does not write: the **highlights** for
consumers and the **internal summary**. `v3.9.0` is already committed and tagged, so these land the
ordinary way — a branch and a PR — rather than under the release exception, which stays the size it was
granted at.

**The highlights lead with a release the reader may have skipped past.** Nothing in v3.9.0 itself
requires a consumer to act — the blueprint is an offer, and every proposed record has a working
fallback. But anyone updating from **before** v3.8.0 lands here without ever meeting that release's one
required decision, and losing `ship-pr` at the next update is not a thing to discover from a failing
merge. So the carried-forward action is the first section, with its commands, ahead of this release's
own headline.

**The rest is a rewrite, not a trim.** The draft is the two tier-2 entries as their authors wrote them
for a reviewer: what was built, which bugs were found, why the second axis is not #522's split. A
consumer needs the opposite shape — what the command does for them, that it is a dry run, that nothing
is ever overwritten, and why ten records arrive as questions instead of answers. The `decide`-is-not-a-
stub reasoning is the one piece of internal design detail kept, because a reader meeting a proposal
document will otherwise read it as an unfinished feature.

**One instruction was corrected before shipping rather than after.** The highlights first told the
reader to run `adopt-config.ps1` through `$env:CLAUDE_PLUGIN_ROOT`, which resolves inside a
plugin-owned component and **not** in a terminal — the exact failure the `cut-release` skill records
about its own first command. The page now points at the `adopt-config` skill, which knows where the
plugin lives on that machine. That verification surfaced a live defect in the skill page itself; it is
recorded below and deliberately left to its own branch.

**The internal note answers the other question.** Tier 2 is what a consumer notices; tier 1 is what the
organisation gets out of it. Here that is the second half of the barrier v3.8.0 began removing: that
release stopped forcing our way of working on anyone, and this one stops making them reverse-engineer
its settings. It also closes the item the previous note left open — the changelog intro that had
drifted, unseen because every cut copies it through verbatim — and records what was deliberately not
built.

**Found while verifying, not repaired here.** The consumer-facing `adopt-config` skill page prints two
commands as hardcoded absolute paths into the plugin author's own cache
(`C:/Users/DaveKok/...`), pinned to version `3.8.0`. Both are wrong for every consumer — a different
username, often a different OS — and the pinned version goes stale at every release, this one included.
The other shared skills use `${CLAUDE_PLUGIN_ROOT}`. It shipped in v3.8.0 and is still shipping;
bundling it into the release-documents PR is how a diff stops being reviewable, so it gets its own
branch.

Plugins: none

### Significance

#### Tier 0

The recorded pointer to the `adopt-config` path defect is what a developer here gains — the next person
to open that skill page is not the one who has to notice it. Nothing about how this repo is developed
changes; these are two documents about a release that is already cut.

**Score:** 2

#### Tier 1

The internal note is this tier's document, so it exists precisely for this audience. It states what
v3.9.0 is worth — adoption stops requiring twenty hand-derived answers, and the reasoning travels with
the values rather than the values alone — instead of restating the file-level changes the developer
notes already carry.

**Score:** 3

#### Tier 2

The highlights are what a consumer meets when they update. This release asks nothing of them, but the
reader arriving from before v3.8.0 still owes that release a decision, and the generated draft buried
it under two reviewer-facing entries. Putting the carried-forward action first, and stating plainly
that this release itself needs nothing, is the difference between a consumer acting in time and finding
out when a merge fails.

**Score:** 4

### Pull Request

[PR #528](https://github.com/DaveKJohn/claude-code-specialists/pull/528) · merged 2026-08-09

---

