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

## `feat/teams-and-workflows-rename` changelog

### Branch title

The plugins are renamed to teams and workflows

### Branch ID

20260809-041233

### Branch type

feat

### What does the change on this branch bring to main?

Every plugin here is now either a **team** — who the specialists are — or a **workflow** — how work
moves through the repo they land in. The names say which:

| was | is |
|---|---|
| `specialists` | `team-alpha` |
| `specialists-lifehub` | `team-lifehub` |
| `specialists-shopify` | `team-shopify` |
| `specialists-ecomm` | `team-ecomm` |
| `specialists-workflow-davekjohn` | `workflow-davekjohn` |

**The distinction is not new; only its visibility is.** It was decided on August 8, 2026, when the
branch/release machinery moved out of the core because 47% of what the core shipped was one particular
way of working that no consumer had chosen. What did not move with it was the naming: five plugins
sharing one prefix, numbered group 1 to group 5, which is the shape of a single family with variants
rather than of two different kinds of thing.

**The numbering is gone with it, and that is the half worth arguing.** A number implies an order and a
completeness that never held: group 3 and group 4 are not steps, they are a platform and a set of
disciplines that a commercial Shopify repo enables *together*. What replaces it is a rule a reader can
apply without a table — **teams stack, workflows do not.** Enable the core team plus whichever add-on
teams fit the repo; enable exactly one workflow, because two would answer the same question
differently and the specialists would have no way to tell which answer is the repo's.

**Consumers must act, and there is no automatic path.** A renamed plugin is a different install id, so
an existing consumer uninstalls the old ids and installs the new ones. Nothing breaks quietly in the
meantime — the old ids simply stop existing in the marketplace — but nothing migrates on its own
either.

**Three things the rename quietly hollowed out, none of which turned a test red.** They are recorded
because a mechanical rename cannot see any of them, and the next one will not either:

- Two asserts in `release-lib.tests.ps1` test a **relationship between two names** — one shares a
  prefix with another, one differs only in case. Both sides were renamed correctly, and the pair was
  left comparing names that no longer share a prefix and no longer differ only in case. They kept
  passing while testing nothing.
- The ordinal-sort choice in `check-report-lib.ps1` rests on a measurement taken on a name pair where
  culture-aware and ordinal collation disagree. For the renamed pair they agree — so the next person
  to verify the claim finds no difference and concludes the sort is pointless. It is asserted on a
  synthetic pair now, with the trap written down above it.
- The bootstrap's durable-body fixture named the cache directory after one plugin and the marketplace
  clone after another. The symptom was exactly what that scenario exists to catch: the `@`-import fell
  back to the version-pinned cache path.

**One consequence named and deliberately not built for.** A consumer whose lenses still sit on the
pre-seam path `.claude/plugins/claude-specialists/<plugin>/` has that second segment named after the
plugin — so after they reinstall under the new name, the readers look under `team-alpha/` and their
lenses go unseen. It is recorded here rather than repaired because nothing has measured such a consumer:
of the four in the register, the layout is known to be the seam or unknown, never confirmed pre-seam.
The migration page is where it belongs, and it is on that branch's list. Building the fallback now would
be a repair for a consumer nobody has found.

**Two boundaries drawn deliberately.** The consumer register keeps the **old** ids for the three repos
that have not migrated, because it records what a consumer *has* — claiming a migration nobody
performed turns the register itself into a false alarm. And in `releases/**` only the link **targets**
were repointed: a historical note's claims are history, but its links have to keep resolving or the
note is unreadable.

One stale claim was repaired on the way past: the core's manifest still said it ships
`connector-sessioncheck`, which moved to the workflow plugin on August 8.

### Significance

#### Tier 0

The tree finally says what the doctrine says. Until now a maintainer had to know that `specialists-`
meant two unrelated things depending on the suffix, and the group numbering had to be looked up rather
than reasoned about.

**Score:** 3

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Yes. Deciding what a new plugin *is* used to require reading the table; it is now a question with two
answers, and the answer picks the name. It also settles a question that had no home before: whether
two of a kind may be enabled at once. For teams the answer is yes and always was; for workflows it is
no, which is stated in the manifests here and enforced in a later change.

**Score:** 3

#### Tier 2

Is this next one still relevant for a consumer of the product?

Yes, and it is why this is the only breaking change in the sequence. Every existing install carries an
id that no longer exists: `specialists@claude-code-specialists` and its four siblings. A consumer
uninstalls the old ids, installs the new ones, restarts, and re-runs `specialists-init`. The skill
names deliberately did **not** change, so only the prefix moves — `/team-alpha:specialists-init`
rather than `/specialists:specialists-init`.

**Score:** 5

### Pull Request

Plugins: team-alpha, team-ecomm, team-lifehub

[PR #531](https://github.com/DaveKJohn/claude-code-specialists/pull/531) · merged 2026-08-09

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

## `feat/plugin-tree-is-name-agnostic` changelog

### Branch title

The plugin set is derived from the marketplace instead of hardcoded

### Branch ID

20260809-023648

### Branch type

feat

### What does the change on this branch bring to main?

Five scripts each answered *which plugins exist and where do their folders sit* by themselves, and
every one of them answered it by encoding the layout: a hand-written list of four `agents/`
directories in the drift check, a `^plugins/([a-z0-9-]+)/` regex with an exception for the one
sibling that is plugin source but not a plugin, a path-segment index in the shared-scripts registry,
three `Split-Path`s upward from a `plugin.json`, and a `Join-Path <plugins root> <name>`. None of
those is a fact about plugins. They are facts about one particular directory shape, and this repo has
changed that shape twice in 2026.

They now ask [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json), through one new
dependency-free lib, [`scripts/lib/plugin-tree-lib.ps1`](scripts/lib/plugin-tree-lib.ps1): a plugin's
name, its root, and its manifest path, derived from the `plugins[].source` the marketplace already
declares. `Get-PluginManifestPaths` became a wrapper over it, `Get-TouchedPlugins` moved into it, and
the shared-scripts registry stopped carrying 21 full mirror paths — measured first, every one of them
was exactly `<plugin root>\<Source>`, so each line restated its own source path and the layout beside
it. A pair now names its plugin and nothing else.

**Three claims in this area turned out to be false, and the branch is the reason they were read at
all.** Each is repaired where it stood:

- [`fold-changelog-entry.ps1`](scripts/release/fold-changelog-entry.ps1) looked `release-lib.ps1` up
  under the consumer's own repo root, justified by a comment saying the lib "is deliberately NOT
  mirrored to the plugin". That stopped being true on August 8, 2026, when it was registered as a
  mirror pair — so a consumer running the fold had a good copy sitting beside the script and looked
  for it one directory over, where it is not. The outcome was right by accident, which is the shape
  that survives a review.
- The canonical-skillset scan in [`check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1)
  claimed to match *plugin, then `skills`, then one folder*. It matched any `skills/` directory
  anywhere under `plugins/`, published or not. Nothing was wrong in the output — measured the same
  day, every such directory did belong to a published plugin — so this is a claim being made true, not
  a defect being repaired.
- The drift check's two lists disagreed by one plugin: `specialists-ecomm` was under `agents` and not
  under `personas`. **That had cost nothing**, because that group ships no `personas/` at all, so both
  lists selected the same three directories. It was a trap with no way to see it: the day that group
  gains a persona it goes uncovered, silently, and a hand-written list cannot be measured against
  anything. Deriving both closes it, and retires checklist item 4 of *Adding a new plugin group*,
  which existed to keep them current by hand.

**What it is for.** The plugin tree is about to be regrouped into `plugins/teams/` and
`plugins/workflows/`, and a rename of every plugin comes with it. Doing that against five encoded
layouts means five chances to move a folder and leave a script pointing at where it used to be. The
proof that this branch works is that the next one should need no script change at all — asserted here
rather than promised: `release-lib.tests.ps1` now runs the whole detection against a **nested**
plugin tree, two levels down, with names that do not match their parent directory.

One trap is recorded in the lib's own header because this repo has paid for it before: an empty
collection unrolls to `$null` on the way through a PowerShell call, so every `$PluginRoots` parameter
accepts null and re-wraps. The empty set is the *ordinary* input here — a repo that publishes no
plugins — and a function whose empty case is normal must not be able to fail on it.

### Significance

#### Tier 0

The next two branches are a rename and a move. Before this, both had to be done in lockstep with five
scripts that each encoded the old shape, and a miss would surface as a broken release or a silent
gap rather than a failing gate. It also removes a standing checklist item and closes three
documentation claims that were measurably untrue.

**Score:** 4

#### Tier 1

Is this next one still relevant for a colleague working on this project?

No. Nothing observable changes: the same gates run, the same mirrors are generated byte-for-byte, and
the release cuts exactly as it did. This is the tree of scripts being made ready for a move that has
not happened yet.

**Score:** N/A

#### Tier 2

Is this next one still relevant for a consumer of the product?

No. A consumer receives identical script mirrors and identical behaviour. The one change they could
in principle observe is a repair they could not have reached anyway: the fold now finds `release-lib`
beside itself, but what it does with it — omit the `Plugins:` line in a repo that publishes no
plugins — is unchanged.

**Score:** N/A

### Pull Request

Plugins: specialists-workflow-davekjohn

[PR #530](https://github.com/DaveKJohn/claude-code-specialists/pull/530) · merged 2026-08-09

---

