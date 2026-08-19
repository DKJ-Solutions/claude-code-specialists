## Branch `docs/root-plugin-neutral` changelog - 20260819-095123

### What does the change on this branch bring to main?

#### Tier 0

The root `CLAUDE.md` stops claiming things that stop being true when a plugin is uninstalled. It used
to open with *"the operating guide for this repo, which is run by the **Claude Specialists** — a team
of specialized Claudes under a single Chief of Staff"*; it now opens by stating that everything in it
holds on its own, and names the two plugins that layer on top — `workflow-davekjohn` on its own page,
`team-alpha` behind the single `@`-import at the foot. That import is the whole specialist surface of
the file, which is what the seam was designed for in the first place
([README.md](README.md#removal-the-teardown-gap)).

**One test decided every edit: does the sentence become false with the plugin gone?** A rule phrased
through a character was reworded — *"if a **specialist** learns a lesson"* became *"if a **session**
learns a lesson"*, *"a specialist picks a sensible default"* became *"pick a sensible default"* — and
four `See [Name #NN]` link labels now name the document instead of the person, keeping every link.
**A product fact was left exactly as it was**, and that is the half worth stating: this repo *builds*
the specialists, so its agent defs, its `plugins/teams/` layout, the retired workshop framing, and the
measurement that one portable persona was 1,700 B against a 26,914 B lens are all still true after an
uninstall. Repairing those too would have stripped correct measurements out of the document — the
same failure [#701](https://github.com/DaveKJohn/claude-code-specialists/issues/701) caused when a
report's count was taken as its subject.

**The root grew by 568 B** (24,518 → 25,086). This branch bought correctness; the branch before it
bought the size.

**Two stale citations repaired.** Both pointed at the root's safety-implementation section for a
measurement that has never been there, verified against `git show HEAD:CLAUDE.md` rather than assumed:
the release lens cited it for the twelve-releases/38% merge measurement, which sits further down its
own page, and the performance lens cited it for the record that the cut once ran the lint alone, which
is in the release lens. Both now point where the material actually is. The link scan passed them all
along, because the anchor exists — a gate that checks anchors cannot check claims.

**A fresh consumer's scaffolded folder page now says it is the layer on top of their root
`CLAUDE.md`** — it only said so for `CONTRIBUTING.md`. Deliberately limited: the scaffolder never
overwrites, so this reaches **new** consumers only. An existing consumer's page is theirs and stays.

**And the lint now says why a link is dead where the resolution base is not the file's own
directory.** An entry's links resolve from the repo root because the entry folds there; the finding
said only *"expected file does not exist"*, which reads as "this path is wrong" when the path is
right for where the file sits — and the next move it invites is a `../` that breaks on landing.
Measured the day before: three suites failed on one entry, and the message named neither the base nor
the reason. **No documentation was added for it**, deliberately: `BRANCH-portable.md` rule 2 already
states the convention and `branch/README.md` already says to read it first. The gap was in the
message, not the docs.

**Score:** 3

#### Higher than tier 0?

The scaffolder change is payload, so it travels. A consumer adopting the workflow after this release
gets a folder page that explains the layering instead of one that leaves them to infer it. Small, and
invisible to anyone already adopted.

**Score:** 2

### Pull Request

The root CLAUDE.md stops leaning on the specialists
