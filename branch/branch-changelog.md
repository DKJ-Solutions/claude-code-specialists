## `fix/seam-docs-follow-the-one-document-model` changelog

### Branch title

The blueprint and the contract describe the one-document release model the script actually runs

### Branch ID

20260811-165209

### Branch type

fix

### What does the change on this branch bring to main?

`cut-release.ps1` moved to the one-document release model in v4.3.0/v4.4.0, and the two artefacts that
*describe* that seam to a consumer did not move with it. Reported from `DaveKJohn/life-hub`
([#605](https://github.com/DaveKJohn/claude-code-specialists/issues/605)) while bringing that repo up from
v4.2.0, where the blueprint was the natural reference for "what does this knob mean now" and had to be set
aside as unreliable in favour of reading `cut-release.ps1` itself.

All three of the report's claims were verified against the tree before anything was changed, and all three
stood: `releases/notes` appeared **0** times in the blueprint while the script writes exactly that path;
`SectionConsumers` and `HintConsumers` are read by `Build-ReleaseNoteDraft` and were documented nowhere;
`Get-ReleaseNoteWording` is read **first** by the cut and appeared in no contract record and no blueprint.

**The sharpest half is a knob whose question inverted while its values stayed valid.**
`Get-ReleaseConsumerBumps` used to mean "which bumps also get a consumer document", where `@()` cost only
the consumer half because a tier-1-only minor still produced an internal note from a second script. It now
means "which bumps get the hand-written note **at all**", so the same value switches off the only such
document a release gets. `@('minor','major')` was correct before and is correct after -- only the sentence
explaining it was wrong, which is exactly why nothing reported it: the contract check compares which
functions exist against which are requested, and **no gate reads a sentence**. `check-script-contract`
reported 0 errors and 0 signals against v4.4.0 throughout.

**Why that mattered more than an ordinary stale comment**, and the reason this was worth a `fix/` rather
than a tidy-up: `adopt-config` places the blueprint's `text` field **verbatim** into the adopting repo's own
`scripts/repo-config.ps1`. So a consumer adopting config today did not merely read a stale description --
they received it as their own committed documentation, explaining a directory the script will never write.
Being wrong shipped as instruction.

What changed:

- **`Get-ReleaseConsumerBumps`' contract record** now names `releases/notes/<dir>/<X.Y.Z>.md` and states the
  split the script already makes: this knob decides *whether* a document is written, while the release's
  tier-2 entries decide only whether that document gets a **consumer section**.
- **`Get-ReleaseNoteWording` is declared**, with its actual nine keys and the honest note that they are
  **not** the same set as `Get-InternalNoteWording`'s eleven -- `SectionConsumers`/`HintConsumers` exist
  only here, and `SkeletonNote`/`SectionChanged`/`NoEntries`/`Unknown` only in the other. Two maps for two
  documents, not two names for one, so overriding by the wrong list configures a flow you are not running.
- **`Get-InternalNoteWording` stays declared** and is not treated as legacy tolerance: `new-internal-note.ps1`
  is still shipped and still reads all eleven keys. Its record now says it belongs to the two-document flow
  and that the cut only falls back to it.
- **This repo's own `repo-config.ps1` prose** -- the text that travels through `adopt-config` -- was rewritten
  where it described three tier-per-document files, and the paragraph that stated this knob's meaning
  backwards was replaced with what it now does, plus why the inversion was invisible.
- **This repo defines `Get-ReleaseNoteWording`**, so it stops being served by the retired name it could never
  have noticed it was relying on. Empty, like its neighbour: an English repo is served by the defaults.

Three pinned counts in `script-contract.tests.ps1` moved with the new record (23 -> 24 records, 21 -> 22
`[OK]` lines in two places), and the record joined the expected-contract list. The three `[INFO]` signals
the contract check reports were confirmed **identical on `main`**: pre-existing, unrelated, and not created
by this change.

One thing deliberately left standing, verified rather than assumed: `releases/internal` still appears twice
in the blueprint, and both mentions are correct -- they describe `new-internal-note.ps1`, which is still
shipped for a repo running the two-document flow.

### Significance

#### Tier 2

A consumer adopting config received a description of a directory the cut will never write, and was told the
opposite of what `Get-ReleaseConsumerBumps` now does -- as their own committed documentation. The concrete
cost is already measured: nine files in the reporting repo had to be rewritten after the update, with the
blueprint set aside as unreliable while it happened. Anyone who adopted config since v4.3.0 has the wrong
text in their repo now and it will not correct itself.

**Score:** 4

#### Tier 1

The canonical name of a wording seam changed and nothing told anybody, because the fallback worked -- which
is the failure mode this project keeps meeting from a new angle: a value that stays valid while its question
moves passes every gate there is. Naming it here is what makes the next one findable.

**Score:** 3

#### Tier 0

This repo was itself being served by the retired seam name and had no way to notice, so it now declares the
current one. Small in effect -- both maps are empty here -- and worth naming for what it prevents: the day
this repo's release documents need another language, the override would have gone into the map the cut reads
second.

**Score:** 2

### Pull Request
