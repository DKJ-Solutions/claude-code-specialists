# Changelog

Everything merged since the last release sits under **`## [Unreleased]`**, **newest first**: **one `###` per
change**, and under it two named `####` sections. The `###` heading is the change's own —
`` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `#### What makes this deploy extra special` for the second audience, and `#### Pull Request`.
Every level here moved one deeper on August 26, 2026, when the pending section above them was introduced and
the development cycle beside them shifted to match; entries written before that day carry the whole set one
level shallower and are read exactly as they always were.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
[`releases/history.md`](releases/history.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`contributing-davekjohn/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## [Unreleased]

### DEPLOY: `fix/record-shape-rollup-observational-v1` · 20260830-121348

The `[RECORD-SHAPE]` session-start report stops calling a deliberate machine-wide install a defect.
Its two headlines — the check's roll-up and the hook verdict above it — asserted one unconditionally:
*"not the assumed shape"*, *"what is wrong is the administration"*, *"its record is not the shape the
docs assume"*. Directly beneath them sat the `pathless-only` detail line, which since
[#1095](https://github.com/DaveKJohn/claude-code-specialists/issues/1095) says in so many words that
the same state may be entirely deliberate and *"needs no action"*. Two lines about one plugin, in one
hook output, saying opposite things — at every session start, for as long as that plugin stays
installed machine-wide.

Both headlines now report what they observed and leave the verdict to the arms, which are the only
lines that can answer it. The count says the record **differs from** the assumed shape, and the
sentence after it points at the detail lines instead of pronouncing on them. Every arm still fires,
and the roll-up still says that nothing else on the machine reports this shape — that half was never
the defect, and dropping it would have traded one silence for another.

**The predicate is unchanged, deliberately.** #1095's third proposal — stop counting a plugin this
repo's own `.claude/settings.json` never enabled — reads a field the demotion does not touch, so it is
not the scope gate [#323](https://github.com/DaveKJohn/claude-code-specialists/issues/323) disproved.
It is *unmeasured*: whether `claude plugin install --scope project` always writes that enable is the
fact it would rest on, and if it does not, the gate restores exactly the silence
[#314](https://github.com/DaveKJohn/claude-code-specialists/issues/314)/[#315](https://github.com/DaveKJohn/claude-code-specialists/issues/315)/#323
were built to end. The wording needed no measurement, so the wording is what changed.

Reported as inbound [#1130](https://github.com/DaveKJohn/claude-code-specialists/issues/1130) from
`DaveKJohn/ccs-testrun-3` against `4.24.0`, and repaired one line wider than reported. The report named
the check's roll-up; the line a session reader meets *first* is the hook's own verdict, which made the
identical claim above it. Fixing only the roll-up would have left the contradiction verbatim in the
output the report was looking at.

**Score:** 2

#### What makes this deploy extra special

A consumer whose plugins are installed machine-wide — the ordinary, correct arrangement — met a yellow
"what is wrong is the administration" at every single session start, and had to read down two lines to
learn it applied to nothing. That false alarm is gone without any arm going quiet: the same states are
still reported, with the same remedies, and now the headline agrees with them.

**Score:** 3

#### Pull Request

the [RECORD-SHAPE] headline states what it observed instead of a defect it cannot establish

Plugins: team-alpha

[PR #1137](https://github.com/DaveKJohn/claude-code-specialists/pull/1137)

---

### DEPLOY: `fix/manifest-unescape-not-backslash-aware-v1` · 20260830-120957

The published marketplace manifest's un-escape now counts the run of backslashes in front of a `\u`
sequence, so a manifest field holding a Windows path no longer has that path folded into an invalid
escape. Before this, a filtered publish whose manifest carried such a path stopped with
*"marketplace.json is not valid JSON"* -- about a file `publish-to-business.ps1` had just written
itself, from a source manifest that was fine. The expression is now identical to the one
`specialists-init/bootstrap.ps1` has carried since inbound #1124, and the docstring says why the two
stay separate copies rather than one shared lib: the bootstrap must run standalone in a consumer's
tree, and the only fallback for a missing JSON-escape lib is a degraded mode with no visible symptom.

**Score:** 2

#### What makes this deploy extra special

N/A -- this is release tooling for publishing a marketplace subset to a business repo. No consumer of
the plugins runs it, and nothing about what they install changes.

**Score:** N/A

#### Pull Request

the published manifest's un-escape counts the backslashes in front of it

[PR #1136](https://github.com/DaveKJohn/claude-code-specialists/pull/1136)

---

### DEPLOY: `fix/contributing-page-points-at-the-release-list-v1` · 20260830-114709

The scaffolded `contributing-davekjohn/CONTRIBUTING.md` no longer claims that `releases/README.md` is the
release list. It now names the list where it actually lives -- `releases/history.md`, beside it -- says
that file is the one document the scaffold deliberately does not write, and states the consequence
outright: a row added by hand to `releases/README.md` is a row the cut will never see.

The verb was simply true until the list moved (#786/#885); the parenthetical `(at <path>)` bolted on
afterwards was doing a correction's work inside a sentence that still said the opposite. The script's
own header, its comment at line 122 and the sibling page it writes had all followed the move -- this one
bullet had not.

**Score:** 2

#### What makes this deploy extra special

A consumer scaffolding the workflow folder reads `CONTRIBUTING.md` as the page that holds the rules, and
stopping there was enough to send their release rows into a file `cut-release` never reads -- leaving
`history.md` empty while looking maintained, and the cut warning about a path the reader had been told
was the wrong one. Nothing refused, which is what made it worth repairing.

**Score:** 3

#### Pull Request

the scaffolded CONTRIBUTING page points at the release list instead of claiming to be it

Plugins: contributing-davekjohn

[PR #1134](https://github.com/DaveKJohn/claude-code-specialists/pull/1134)

---

### DEPLOY: `docs/pr-template-interface-is-the-placeholder-v1` · 20260830-114603

`CONTRIBUTING-portable.md` told a consumer the PR template's interface was **two lines** — a first heading
and a placeholder — and warned that breaking either silently costs them every PR description. The heading
half came off on August 24, 2026 with #865, when `-RefreshBody` stopped reading "the first heading" and
started reading where the placeholder sits. The page never followed, so the paragraph that instructs a
consumer to *copy the shipped reference and diff against it* described a rule the reference itself breaks:
that file is one line, an HTML comment, with no heading at all. Every available reading was wrong — add a
heading the tooling does not want, treat the shipped reference as stale, or go read `open-pr.ps1` to find
out which of the two documents is lying.

**It demonstrably misled, which is the part worth having.** The testrun plan on #1079 — written by a
careful reader of exactly this page — states its assert as *"`.github/pull_request_template.md` from
`${CLAUDE_PLUGIN_ROOT}/templates/`, **with its first heading** and its placeholder line intact"*. That
assert cannot be satisfied by the file it names, and it sat there unsatisfiable until a run copied the
file and looked at it.

**The interface is now stated as one line, in all four places that describe it.** The placeholder is the
whole contract; a template carrying nothing else is the normal shape rather than a broken one; the
headings you add below it are the form's, and each is a boundary the refresh will not cross. The
`open-pr` skill gets the mechanism in full — the description sits under the **last** heading *above* the
placeholder, or is the body's leading section where there is none, and only a **missing** template makes
`-RefreshBody` warn and change nothing. That skill also stopped claiming the matcher compares against
*three* built-in strings, which has been twelve for some time and is now described by what the list is
(every placeholder this family has ever shipped, oldest first) rather than by a count that goes stale in
silence.

**Score:** 3

#### What makes this deploy extra special

N/A. This repo is the source of the plugin, not a subscriber to a service; the reader who gains is the
consumer adopting `contributing-davekjohn`, and they receive it through the next release rather than from
anything visible here.

**Score:** N/A

#### Pull Request

the PR template's interface is the placeholder line, and a heading-less template is the normal shape

Plugins: contributing-davekjohn

[PR #1133](https://github.com/DaveKJohn/claude-code-specialists/pull/1133)

---

### DEPLOY: `fix/settings-proposal-pasteable-v1` · 20260830-112706

`specialists-init` now writes a **second** settings artifact beside the annotated one:
`.claude/settings.proposed.json`, the merged end result. It is the consuming repo's own
`.claude/settings.json` key for key with both `permissions` halves folded in — strict JSON, no
comments to strip, and no hooks stub. Adopting the proposal becomes *replace one file with the other*
instead of a hand-merge the reader has to invent. `specialists-teardown` removes it alongside the
`.jsonc`, both names coming from one new `Get-SettingsArtifactNames` so the writer and the remover
cannot drift apart.

The annotated `.jsonc` stays, and gains the warning it never had: **it must not be pasted whole**,
because the destination is not empty. `.claude/settings.json` already holds `enabledPlugins` and
`extraKnownMarketplaces` — the two keys that got the adoption this far — and the proposal contains
neither, so overwriting the file with it deletes both. The result is a settings file that parses
perfectly and loads nothing at all: no skills, no subagents, no SessionStart hooks, and no message of
any kind. That is [#1076](https://github.com/DaveKJohn/claude-code-specialists/issues/1076)'s
zero-surface state (3 → 0 hooks, 6 → 0 skills, 15 → 0 subagents across one restart), reached without
ever touching an install record — and reached in the one act this family reserves for the human, since
a session may not widen a permissions file.

Two of that file's three copy traps were already papered over with warnings (the comments, #1097; the
hooks stub, #363) and the third was warned about nowhere. It is the third that costs the adoption, and
it is the one no amount of further warning text closes: the instruction was *"copy what fits"*, which
is a merge, and the fix is to do the merge.

**The merged file is not written when the destination cannot be read whole** — it does not parse, it
parses to something other than an object, its `permissions` key is not an object, or `permissions.allow`
/ `permissions.deny` is not a list of rules. The run says which shape it found, and the next-steps fall
back to the hand-merge *naming the two keys that must survive it*. Composing a merge from a file that
could not be fully read would drop part of it while wearing the label "safe to paste", which is the
reported defect arriving through its own fix.

Two smaller guarantees fall out of the same principle. The JSON is re-indented by a **scanner** and its
`\uXXXX` un-escape **counts the run of backslashes**, so a hook command naming a Windows path survives
byte for byte instead of shipping an invalid escape. And where `.claude/settings.json` is gitignored
while the merged copy beside it is not, the run says so: the copy holds every key that file held, and
the ignore rule that was hiding them names the old path.

The permission rules are now declared once as data and rendered into both files, so the proposal that
explains a rule and the file that carries it cannot disagree.

**Score:** 4

#### What makes this deploy extra special

A consumer adopting the specialists follows this step exactly once per repo, by hand, and until now it
could silently switch off everything they had just installed — with a valid settings file and no error
to read. From this release the same step is a single file replacement, and the file that must not be
pasted says so and names what it would destroy.

**Score:** 4

#### Pull Request

the settings proposal ships a pasteable merged file, and the proposal itself names the keys that must survive

Plugins: contributing-davekjohn, team-alpha

[PR #1132](https://github.com/DaveKJohn/claude-code-specialists/pull/1132)

---

### DEPLOY: `fix/blueprint-record-carries-only-its-own-value-v1` · 20260830-111440

The config blueprint's generator handed the first function under a shared assignment block every value
in that block, while each of the block's other functions already shipped its own. Three variables
therefore arrived in a consumer's `scripts/repo-config.ps1` assigned twice, the second assignment
silently winning. `Get-FunctionBlock` now trims its walk back to the values the function itself reads,
asked of that function's own AST rather than of the assembled text -- where an assignment target is
indistinguishable from a read.

Nothing errored and a fresh adoption behaved correctly, because the duplicate values agreed. The cost
lands on the next reader: these four strings are the entry-scaffold wording, and they exist to be
translated (#410). A consumer editing them under the comment that explains them would have had an
assignment three lines further down -- one they had no reason to read past -- put the English back,
after which `new-branch` writes English stubs and `open-pr`'s body-heading gate goes on recognising
only the English marker, with nothing anywhere saying why.

**Score:** 3

#### What makes this deploy extra special

It is only visible in a file `adopt-config` has written. The source repo's own `repo-config.ps1`
assigns each of these variables exactly once, so no amount of reading this tree shows the defect --
which is why the regression test asserts on the placed consumer lib and not only on the artefact.

The measurement that mattered was not the fix but the test: the natural way to write the per-record
assert passes against the broken artefact, because the parser cannot distinguish an assignment target
from a read. Running the new asserts against the old generator is what caught it.

**Score:** N/A

#### Pull Request

a blueprint record carries only the values its own function reads

Plugins: contributing-davekjohn

[PR #1129](https://github.com/DaveKJohn/claude-code-specialists/pull/1129)

---

### DEPLOY: `docs/portable-cycle-begins-at-the-issue-v1` · 20260830-102958

**The portable half of the cycle began at `new-branch`.** This repo's own page has opened at
`## 1. NEW ISSUE / TASK` since August 29, 2026 ([PR #1058](https://github.com/DaveKJohn/claude-code-specialists/pull/1058)),
so for a day the document every consumer reads described a cycle starting one step later than the cycle it
describes — and the step it was missing is the one that says where the work comes from.

`CONTRIBUTING-portable.md` now opens at `### 1. New issue or task`, with `Human` and `Claude` as **kinds
rather than sub-steps** — neither precedes the other, both end in one issue in the repo the branch will be
opened in — and Branch through Fold renumbered 2 to 6, in-page back-references included. It is the only step
that names no skill, and that is stated on the page: no script runs it, which is exactly why it was the step
the page went without.

**`TICKETWORK-portable.md` is gone, folded in whole** as `## Ticket work — the layer before the branch`,
which step 1's `Human` half points at. It had been a fourth portable page for three weeks, and what retired
it was reach rather than size: the cycle document never mentioned it once, and the plugin README framed it as
an optional extra — so a reader following the cycle end to end met neither the section nor the step it
belonged to. Nothing was dropped in the move; the ten rules keep their own headings one level down, and the
framing that makes them survivable (one repo, one day, rules rather than a format) travels with them.

Its four live references follow it: the plugin README's pointer paragraph and its table row, the folder
README both copies of `adopt-workflow-folder.ps1` scaffold, and this repo's own step 1. The two archived
`4.5.0` documents that linked to the file are **de-linked rather than repointed** — the dead-link scan reads
`releases/` recursively, and an archived note should keep saying what was true on its day rather than
pointing at a page whose name it does not carry.

**Score:** 2

#### What makes this deploy extra special

**A consumer's route no longer has a hole at the front.** The cycle they read starts where their work
actually starts, and the ticket-work rules are reachable from it instead of from a page the cycle never
named. Nothing to run and nothing to migrate: no script, gate or seam changed, and a repo where nothing
arrives from an upstream tracker skips that section exactly as it skipped the page.

**Score:** 3

#### Pull Request

The portable cycle begins where the local one does, and ticketwork moves into its first step

Plugins: contributing-davekjohn

[PR #1125](https://github.com/DaveKJohn/claude-code-specialists/pull/1125)

---

