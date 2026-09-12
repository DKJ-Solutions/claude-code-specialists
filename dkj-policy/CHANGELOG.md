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
[`dkj-policy/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

**The line directly under `## [Unreleased]` is a tally, and nobody types it.** It reads
`**4 / 9 minor entries**`: how many of the pending entries reach the audience this repo publishes to, out of
how many are waiting for the next release, and which bump that work has earned. The two numbers answer
different questions and may differ — the fraction counts tier 2 and above, the bump follows tier 1 and
above — so `**0 / 8 minor entries**` says nothing reaches a subscriber while the version still owes a minor
for what reaches management. It is
**derived from the entries below it every time it is written**, by the fold that adds one and the cut that
removes them all, so it holds no state of its own and a hand-edited count is simply corrected on the next
fold. It ends with an HTML comment that marks it as machine-written; that marker is what the next run
replaces, so anything else written in this space is left alone.

---

## [Unreleased]

**2 / 2 minor entries** <!-- pending-tally -->

### DEPLOY: feat/1895-triage-label-adopter · 20260912-141115

`dkj-policy` shipped no machinery for the triage-priority label set this repo's own orchestrator
already prescribes on every issue (`prio-1`..`prio-4`) -- the scale existed only as prose in
`.claude/specialists/lenses/01-01-extension.md`, so any other dkj-policy consumer adopting the
convention had to retype four names and four colours by hand, with no gate to catch a typo before
`gh label create` refused it. `Get-MissingLabelNote` already established the precedent for this class
of problem on a PR label (compose the exact `gh label create` and stop, never substitute, never drop),
and `Get-ReachLabel` already established the precedent for sharing a label's SPELLING as a `copy`
seam across dkj-policy consumers. This closes the gap between the two for the priority axis: a new
`Get-TriageLabels` seam states the canonical four (`Adopt = 'copy'`, since the rungs are a shared
convention rather than a fact about the adopting repo -- unlike `Get-BranchInfo`, which is `decide`),
and a new print-only script, `adopt-triage-labels.ps1`, reads a repo's `gh label list` and prints a
paste-ready create command for whatever it is missing -- never creating one itself. Split from #1843
per its own red-team review; the three open questions it left (apply-or-print, is there a shared set,
where does it live) are answered by this branch: print, yes one set, and in its own seam rather than in
`branch-info.ps1`. This does not touch `#1686`'s BWJ-versus-source disjointness, or `#1841`/`#1870`'s
reach-label machinery -- it is the neighbouring axis, for ordinary dkj-policy consumers only.

**Score:** 2

#### What makes this deploy extra special

A dkj-policy consumer that has adopted the shared triage convention (or wants to) now has a single
command that tells them exactly which of the four canonical labels their tracker is missing and hands
them the paste-ready fix -- one command instead of four hand-typed ones, and no risk of a typo'd hex
colour or a `gh label create` failing after the fact. It never writes anything on its own.

**Score:** 2

#### Pull Request

Print-only adopter for the shared triage-priority labels

Resolves #1895.

`dkj-policy` prescribes the four `prio-1`..`prio-4` labels on every issue this repo files, but shipped
no machinery for a consumer to adopt them -- the scale was prose in one family's page, and creating a
label is a GitHub-side write nothing here should do silently. This gives the axis its own `copy` seam
(`Get-TriageLabels`, next to `Get-ReachLabel`) and a print-only adopter script,
`adopt-triage-labels.ps1`, that composes a paste-ready `gh label create` for whatever a repo's tracker
is missing and never runs it -- the same compose-and-stop shape `Get-MissingLabelNote` already
established for a PR label. Mirrored into the plugin, wired into the script contract and the
shared-scripts registry, with a new dedicated test suite plus additions to `repo-config.tests.ps1` and
`script-contract.tests.ps1`. Lint and the full test suite are green.

Not in scope, per the issue: `Get-BranchInfo`, the BWJ reach labels/buckets (#1686, #1841, #1870), any
colour/description drift detection on an existing label, and a new skill page or a fifth "Part" of
`adopt-dkj-policy` (documented instead via `plugins/dkj-policy/scripts/README.md` and one sentence in
`CONTRIBUTING-portable.md`).

Plugins: dkj-policy

[PR #1899](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1899)

---

### DEPLOY: fix/1897-reupload-stale-attachment · 20260912-123206

The `cut-release` checklist now says to re-upload the release attachment the timing pass edits. Step 0a
prescribes a second timing pass *after* step 5, and step 5 is where the hand-written documents are
attached — so the published asset was one revision behind the tree by construction and permanently
lacked the end-to-end duration that step exists to capture. Measured at `v5.1.0`: 11,487 bytes published
against 12,275 committed, caught only because somebody was watching the byte count. The step now carries
the `gh release upload --clobber` line, names which document is the stale one in each flow (the consumer
note in the merged flow, the internal note in the two-document flow), and rules the generated development
notes out with the reason — it is the editing that creates the exposure, not the attaching.

**Score:** 3

#### What makes this deploy extra special

A consumer running this workflow publishes a Release whose attached note is missing the one figure the
checklist told them to measure, and nothing reports it — the tree, the tag and the commit are all
correct. They find out when somebody downloads the note and the total is not in it.

**Score:** 3

#### Pull Request

The second timing pass re-uploads the attachment it just edited

Plugins: dkj-policy

[PR #1898](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1898)

---

