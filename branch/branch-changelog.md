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

