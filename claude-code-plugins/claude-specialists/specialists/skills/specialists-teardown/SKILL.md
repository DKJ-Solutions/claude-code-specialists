---
name: specialists-teardown
description: >-
  Remove what specialists-init put into a consuming repo, so the repo can stand free of the plugin:
  the generated lens scaffolds, the two @-imports in CLAUDE.md, the untouched script-config
  scaffolds and the settings proposal. Strictly subtractive and the mirror image of the bootstrap --
  it never deletes anything the repo owner filled in, and never edits settings.json. Dry run by
  default. Use this when a consumer is being disconnected from the plugin, or to verify that
  adoption is genuinely reversible before relying on it.
---

# specialists-teardown -- give the repo back

The counterpart to [`specialists-init`](../specialists-init/SKILL.md). Adoption is reversible by
design (Dave's requirement, July 29, 2026): a consumer must be able to install **and uninstall** at
any moment, and afterwards carry no *live* reference to a specialist, manual, persona or roster --
nothing a session loads, a script resolves, or a gate depends on. Its own changelog history is
exempt, and stays as written.

## Run it

From the root of the consuming repo:

```powershell
# Preview -- nothing is removed
powershell -NoProfile -File "<plugin>/skills/specialists-teardown/teardown.ps1"

# Act
powershell -NoProfile -File "<plugin>/skills/specialists-teardown/teardown.ps1" -Apply

# Act, and keep a working git workflow afterwards (see the runtime dependency below)
powershell -NoProfile -File "<plugin>/skills/specialists-teardown/teardown.ps1" -Apply -VendorScripts
```

**Dry run by default.** A destructive script that runs on somebody's repo should have to be asked
twice, and the preview doubles as the inventory a reader needs in order to say yes.

**The preview and the apply run report the same total** (inbound #275). They used to differ by two: the
directories the run cleans up (`lenses/`, then `specialists/`) were pruned, listed and tallied only under
`-Apply`, so the same work read as "29 item(s) to remove" and then "31 item(s) removed". A preview that
undercounts its own execution weakens exactly the property it exists to provide, so both modes now list
those directories under `[remove]`. On a dry run the emptiness is predicted -- a directory counts as empty
when every file still in it is already on the remove list -- which is the question `-Apply` answers by
looking, off one shared code path.

## What it classifies, and why that is the whole design

Consumer-side content is three things and only one is disposable. Deleting indiscriminately would
destroy governance and repo knowledge the owner authored -- a worse outcome than leaving clutter. So
the script classifies before it removes:

| category | what it is | what happens |
|---|---|---|
| **Generated and untouched** | a lens still carrying its `VUL-IN` marker, an unfilled script scaffold, the `@`-imports, `settings.suggested.jsonc` | **removed** |
| **Authored by the owner** | a filled-in lens -- repo knowledge somebody wrote | **reported, never touched** |
| **Owned by the repo anyway** | a `repo-config.ps1` with real values, a filled branch table: this repo's own conventions | **reported as yours to keep or drop** |

The signals are the scaffold shapes **this plugin writes**: a `(VUL-IN)` slot heading for a lens, a
`VUL-IN` in an assignment's *value* for `repo-config.ps1`, an empty prefix table for `branch-info.ps1`.
Deliberately a content test rather than a timestamp or hash: a reformat or a merge does not make content
authored.

> **It only recognises its own conventions, and says so rather than guessing.** A round-trip in
> `davekokbwj/smartwatchbanden` (July 29, 2026) found 20 of its 22 lenses empty under **that repo's own**
> "clean slate" convention — a closing sentence, no `(VUL-IN)` heading anywhere. All 22 were kept, and the
> report claimed they were "filled in". Right answer, wrong reason, and adoption was less reversible than
> this skill implied. Two changes followed: the report no longer asserts authorship it cannot establish
> (it says the file is *not recognised as a scaffold*, which is all it knows), and a consumer can declare
> its own convention with **`-EmptyLensPattern <regex>`**, e.g.
> `-EmptyLensPattern 'Nothing recorded yet'`. Without it those lenses are kept — the safe direction,
> since a false keep leaves clutter while a false remove destroys someone's work.

## What it deliberately will not do

- **It never edits `.claude/settings.json`.** Disabling or uninstalling the plugin is the owner's act,
  and the bootstrap never wrote that file either -- the symmetry that makes this safe to run cuts both
  ways. It is reported instead, with the note that the subagents and session hooks stay active until
  the entry is gone and the session restarted.
- **It never removes roster rows or repo-specific prose from `CLAUDE.md`.** Those are authored text in a
  file full of other authored text, and no rule this script could apply safely tells where a roster row
  ends and your own prose begins. The only lines it touches there are the two `@`-imports, which are
  knowably bootstrap-written and cannot be anything else -- the same property that let
  `check-roster-sync` stop counting them as roster rows.
- **It never touches the plugin install or cache.** `claude plugin uninstall` is a separate step.

## Verifying a round-trip — and why `git status` is not enough

The first real round-trip (`davekokbwj/smartwatchbanden`, July 29, 2026) was verified with
`git status` / `git diff`, and that method turned out to be **partly blind**: that repo ignores
`.claude/*`, so `settings.suggested.jsonc` never appeared in `git status` and `git checkout .` did not
clean it up. Since `.claude/` is where most of what the bootstrap writes lives, git can miss the bulk of
it. Worse, in such a repo git cannot **restore** a wrongly deleted lens either — so establish whether
`.claude/` is tracked *before* running with `-Apply`.

### Pre-flight: is your lens tree actually under version control?

One command, and it decides whether this whole procedure has an undo:

```powershell
git ls-files .claude | Select-String 'extension\.md|SPECIALISTS\.md'   # empty = NOT tracked
```

**And the answer can change when you migrate to the seam, which is the trap.** Measured across the two
real consumers on July 30, 2026:

| repo | `.gitignore` | consequence |
|---|---|---|
| `DaveKJohn/life-hub` | no `.claude` entry at all | the whole tree is tracked — a wrongly removed lens is one `git checkout` away |
| `davekokbwj/smartwatchbanden` | `.claude/*` with `!.claude/plugins/` | tracked **only** on the pre-seam path |

That second row is fine today and breaks silently on migration: the exception un-ignores
`.claude/plugins/`, the **pre-seam** location. Move the lenses to `.claude/specialists/` and they match
`.claude/*` with no exception covering them — so the tree leaves version control **without a single line
of the migration looking wrong.** Every gate stays green (the readers accept the seam, which is the
point), `git status` shows nothing (they are ignored), and the teardown's undo is gone.

**So a seam migration in a repo that ignores `.claude/*` is two steps, in this order:** add the
`!.claude/specialists/` exception (and commit it), *then* move the files. Reversed, the move lands
untracked and the commit that would have captured it has nothing to capture.

More generally: **an ignore rule written against a path is a bet that the path will not move.** The
migration is exactly the moment that bet is called in, and nothing in this family's tooling can see the
consumer's `.gitignore` for you — which is why this is a pre-flight step for the operator rather than a
check.

Take a **filesystem** inventory at each stage instead, and compare the numbers:

```powershell
# count of lenses, imports, scaffolds, and the settings proposal
@(Get-ChildItem .claude -Recurse -Filter '*-extension.md' -File).Count
@([System.IO.File]::ReadAllLines('CLAUDE.md') | Where-Object { $_ -match '^\s*@' }).Count
Test-Path scripts\repo-config.ps1; Test-Path scripts\lib\branch-info.ps1
Test-Path .claude\settings.suggested.jsonc
```

**Read the two scaffold lines correctly, or the whole protocol tells you the wrong thing.** They are an
*inventory*, not an expectation — and what the right answer is depends on something the numbers cannot
show you: **whether the repo already had those files.** This tripped up the first real adoption attempt
(life-hub, July 30, 2026), which stopped before installing and was right to:

| the repo before adoption | after bootstrap | after teardown `-Apply` |
|---|---|---|
| the addresses were **empty** | placed as `VUL-IN` scaffolds | **removed** — nobody filled them in |
| the addresses were **occupied** (a real `repo-config.ps1`, a filled prefix table) | `[keep] ... already exists -- not overwritten` | **kept** — the teardown never removes what it did not write |

So "both scaffolds present after the bootstrap" is trivially true in an occupied repo and measures
nothing, and "both scaffolds gone after the teardown" can only go green there by deleting two
load-bearing files. **Check the report lines, not just the `Test-Path` results:** `[create]` versus
`[keep]` on the way in, and `[remove]` versus `[KEEP]` on the way out, are what actually tell you which
of the two rows above you are in.

This is not a special case. The plugin scaffolds precisely the files that were *extracted from* repos
like these, so on a fresh fixture the addresses are free and in any real consumer they are inhabited —
which is why the round-trip suite now carries an explicit *occupied consumer* scenario.

Two further checks the hooks will not do for you, both of which caught real defects:

- **Count the bootstrap's note line.** A `teardown` → `init` cycle used to add one copy per cycle
  (measured 1 → 2 → 3) while all three session hooks reported "in sync". Run the cycle **twice**: once
  cannot distinguish "does not accumulate" from "accumulates once".
- **Count lone LFs in `CLAUDE.md`.** `([regex]::Matches($text, "(?<!\`r)\`n")).Count` — the bootstrap
  used to paste LF into a CRLF file, invisible to every gate.

And declare your own empty-lens convention if you have one, or the report will keep files it cannot
recognise: `-EmptyLensPattern '<your marker>'`.

## What is left over afterwards, honestly

A repo that ran the bootstrap, filled in its lenses, and then tore down is **not** blank. The remaining
distance was measured by hand in `davekokbwj/smartwatchbanden` (July 29, 2026) rather than estimated,
and it is four different kinds of leftover. Only the second is this skill's own limitation. Note that
the target is **no *live* reference, not zero references** -- see
[what is correctly left standing](#and-what-is-correctly-left-standing) at the end of this section, and
the requirement itself in the [family README](../../../README.md#removal-the-teardown-gap).

**1. A runtime dependency no teardown can undo -- the one that actually hurts.** The plugin is the
single source of truth for the operational scripts (`new-branch.ps1`, `park-branch.ps1`,
`new-changelog-entry.ps1`, `open-pr.ps1`, `fold-changelog-entry.ps1`;
[issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81)), and a consumer reaches them
through a resolver of its own that locates the marketplace cache and **throws** when that cache is gone.
In the measured consumer that resolver is `scripts/lib/plugin-paths.ps1`, and three operational scripts
dot-source it: `start-task.ps1`, `open-pr.ps1`, `fold-changelog-entry.ps1`. So after a teardown plus a
`claude plugin uninstall`, the repo does not merely carry clutter -- **its daily git workflow stops
working.** No option to this script can fix that: adopting the shared-script model is what creates the
dependency, and undoing it means the consumer holding local copies of those scripts (or its resolver
degrading instead of throwing). State the promise precisely, then: what the bootstrap *wrote* is
reversible; what the consumer *built on top of the plugin* is not, and a consumer that relies on the
shared scripts has to plan that step itself.

**What the script does about it, first: warn.** Any `.ps1` under `scripts/` that references the
marketplace cache or `CLAUDE_PLUGIN_ROOT` is reported as a `[WARN]` line, together with the scripts that
depend on it, and is **never removed** -- it is your code. Everything else in the report answers "what
did the bootstrap put here"; this answers "what breaks after you uninstall", which is the question a
reader actually has before trusting the word *reversible*. The scan covers `scripts/` only, so a resolver
living elsewhere is still yours to spot.

**And second: `-VendorScripts` hands the scripts back, which is the actual way out.** It copies the
plugin's shared script payload (`scripts/task`, `scripts/release`, `scripts/lib`, `scripts/sync`) into
your own `scripts/`, structure preserved, so the workflow keeps running with the plugin gone. This works
because the payload was built to travel: the scripts locate the repo through `CLAUDE_PROJECT_DIR` /
`git rev-parse --show-toplevel` -- never their own location -- and dot-source their siblings
`$PSScriptRoot`-relative, so a copy behaves identically anywhere inside the repo. The source repo is the
standing proof: its `scripts/` copies are byte-identical to the plugin's, and that is asserted on every
vendor test run.

Three things to know before using it:

- **It is the one additive act in a subtractive script**, which is why it is opt-in rather than default.
- **It never overwrites.** A destination that exists and differs is reported and left alone -- that file
  is typically your own wrapper around the shared script, so the rule protecting a filled-in lens
  protects it too. Reconciling those is yours; an identical destination is reported as already current,
  so re-running is safe.
- **The vendored scripts still need the repo-owned script contract** they dot-source
  (`scripts/lib/branch-info.ps1`, `scripts/repo-config.ps1`). Keep those whatever else you drop. If the
  same run removed them because they were still unfilled scaffolds, the report says so outright: that
  repo never had a working workflow to preserve.

**2. Authored text this script refuses to touch.** By design, per
[the section above](#what-it-deliberately-will-not-do) -- and measured, so the size of the hand work is
known. `CLAUDE.md` carried the roster table (22 rows), the work-division block, the loading-strategy
paragraph, and the safety cross-references into the orchestrator's lens: roughly 43 lines across some 6
sections. Outside that file the mentions are loose and few -- `README.md` (5),
`research/plugin-sharing/README.md` (14), `releases/README.md` (1),
`.github/pull_request_template.md` (1). As long as specialist content is woven through `CLAUDE.md`
rather than sitting behind a single inclusion, a script cannot finish this without guessing where a
roster row ends and the owner's prose begins. Closing it is the seam in
[issue #221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221) -- this skill is the half that
can be built and tested today.

**3. A lens that outlives the import which loaded it.** The orchestrator's lens
(`01-01-extension.md`) is authored content, so it is kept -- while the `@`-import that loaded it is
removed, being knowably bootstrap-written. The file therefore survives as an orphan: present, tracked,
and read by nothing. Both halves are correct, and the combination is worth naming, because a `[KEEP]`
line reads as "still working" when all it means is "still there".

**On a seam consumer this leftover shrinks to one named file.** Where the specialist surface sits behind
`.claude/specialists/` (issue #221), a teardown removes that whole directory and the single import line.
If `SPECIALISTS.md` still carries its `## The roster (VUL-IN)` slot it goes with the rest; if the owner
filled the roster in, it is kept, the import is still removed -- that line is what made the content
*live* -- and the report says outright that nothing loads it any more. So the orphan is not gone, but it
is **one file with a name, holding the roster in one piece**, instead of 43 lines scattered through six
sections of `CLAUDE.md`. That trade is what the seam actually buys.

**4. A consumer gate that goes blind rather than red.** A consumer that lints its own lens files keeps
that check afterwards, and in the measured repo the lens category **silently skips** once the directory
is gone: nothing errors, nothing is reported, and the gate stays green while checking nothing. That is
the right outcome for a deliberate teardown and the wrong one for an accidental loss -- a silent skip
cannot tell an operator's removal from a bad merge or a mistyped path, so the one case it must warn about
is the one case it stays quiet in. Not this script's to fix (the gate is the consumer's own), but worth
knowing before you rely on a green gate to tell you the repo is intact: a skip that *says* it skipped
costs one line.

And `.claude/settings.json` is unchanged -- that is the refusal above rather than a leftover. The plugin
stays enabled, subagents and session hooks included, until the owner removes the entry and restarts.

### And what is correctly left standing

Some references are supposed to survive, and counting them as debt would be a mistake. In the measured
repo, `CHANGELOG.md` (3) and `releases/development/*` (43) mention specialists -- 46 references that are
each an accurate record of something that happened. **History is finished business: it is never
rewritten, and a teardown must not touch it.**

Which is why the goal is *no live reference* rather than *no reference*: nothing a **session loads**, a
**script resolves**, or a **gate depends on** may still point at the plugin. Read that way the four
leftovers sort by what they actually cost -- (1) breaks a run, (2) and (3) mislead a reader, (4) misleads
a gate, and the changelog is simply the record of having adopted the plugin in the first place.

## The free-standing audit -- the run proves it instead of claiming it

Every section above answers *"what did the bootstrap put here, and what did I take away"*. None of them
answers the question the requirement actually poses: **after this, does the repo stand free?** So the run
closes with an audit that goes looking, and lists what it finds by **file and line**:

```
-- free-standing audit: LIVE references left after this teardown --
   scanned 24 file(s) under CLAUDE.md, .claude/ and scripts/ against 19 known specialist name(s)
  [LIVE]   CLAUDE.md:3 -- name 'Derek'
  [LIVE]   CLAUDE.md:6 -- specialist id + name 'Derek'
  [LIVE]   scripts\repo-config.ps1:3 -- plugin-only contract function
```

**Report-only, unconditional, and it runs on a dry run too** -- it removes nothing, so it needs no
`-Apply`, and a preview that cannot tell you what would still be left is not the inventory a reader needs
in order to say yes. A clean repo gets `[FREE]` instead, and that line is the requirement met *verified
rather than assumed*.

**Why it finds rather than fixes.** The target shape's second item is *"reword category 3 plugin-neutrally
so it stays true after an uninstall"* -- turning *"Derek opens the PR"* back into *"changes go in via a
branch and a PR"*, a rule that stays true with the plugin gone. That was never something a script could
do: it is the owner's governance prose, and a plugin rewriting it would be the exact damage the
[classification](#what-it-classifies-and-why-that-is-the-whole-design) exists to prevent. What a script
*can* do is turn an unbounded hand-audit into a checklist. Three kinds of hit, each with a different
answer:

| hit | what it means | what to do |
|---|---|---|
| a **specialist id** (`05-05`) | a roster row, a routing table, a chain | usually **delete** -- it only ever existed for the plugin |
| a **name** (`Derek`, `Tessa`) | a still-valid rule phrased through a character | usually **reword** -- keep the rule, drop the name |
| a **plugin-only contract function** (`Get-RosterPath`, `Get-RosterIgnoredIds`) | a line inside a file that is otherwise yours | **delete the line**, keep the file |

The choice is per line, not per file -- which is why the audit reports lines.

**Three deliberate boundaries, so the output can be trusted:**

- **The names come from the plugin's own payload**, never a hardcoded list that would rot on the next
  rename: an agent def's `name:` frontmatter, and a persona's H1. But this skill ships inside **one**
  plugin and can only see that plugin's specialists -- a consumer that also enables a domain plugin has
  names this scan does not know. The **id scan is the general net** (a `<gg>-<ii>` token is
  name-independent and catches a specialist from any plugin); the name scan is the extra pass on top.
- **Matching is case-insensitive and covers possessives, biased toward over-reporting.** The expensive
  failure for an audit whose purpose is proving nothing was missed is a reference it did not find, not one
  a reader dismisses in five seconds -- and every hit carries `file:line`, which makes a false positive
  cheap and a false negative silent. **Possessive forms count as the name**: Dutch takes no apostrophe, so
  a trailing word boundary silently rejected `Dereks` and a live reference in a non-English consumer's own
  prose went unreported (found in a Dutch consumer, inbound #271 -- and it applies to every non-English
  repo, not to an edge case). The hit reports the text **as it appears in the file**, possessive included,
  so a reader can search for what they were shown.
- **Files this run is about to delete are excluded, and the exclusion is stated.** A reference inside a file
  that is going away is not a surviving reference. Without this, a dry run's list was filled entirely by the
  lens files the same run had just put on the `[remove]` list -- they all mention a specialist -- and the
  handful of hits that actually matter only appeared after `-Apply`. That inverts the purpose of a preview
  that is explicitly the inventory you say yes to.
- **And so are the *lines* it is about to delete, in a file that stays** (inbound #275). The exclusion above
  is per file; the bootstrap's orchestrator note and the `@`-import(s) are lines removed from a `CLAUDE.md`
  that survives. A dry run used to report the note as a live `name 'Chris'` hit on the very run that lists it
  under `[remove]`, so the audit dropped from 5 live references to 4 after `-Apply` on a consumer that had
  changed nothing in between. Same defect as the lens-file one, one order of granularity smaller, and the
  line count is stated in the scan line exactly like the file count.
- **History is out of scope and never rewritten.** `CHANGELOG.md` and `releases/` are excluded entirely.
  Other root prose (`README.md`, `CONTRIBUTING.md`) is outside the live set by the reading above, so it is
  **counted, not listed** -- a pointer, not a work queue.
