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

**1 / 4 minor entries** <!-- pending-tally -->

### DEPLOY: fix/1762-pasteable-path-absolute · 20260910-082956

`Get-PasteableRef -Kind Path` now judges a filesystem path against its own allowlist
(`$PathPasteSafePattern`) instead of the ref one, so an **absolute** path can pass: the pattern adds the
drive/scheme `:` and a leading `/` for a POSIX root, and `ConvertTo-PastePath` folds `\` to `/` first so
the one printed token is correct in Git Bash as well as PowerShell and cmd. Everything the ref allowlist
refuses -- a space, `$`, a backtick, a quote, `;`, `&`, `|` -- is still refused, and the deliberately
narrow `-Kind Ref` axis (#1594, #1617) is unchanged. Fixes inbound #1762: the `-Kind Path` callers that
carry an absolute path -- `check-plugin-integrity.ps1`'s nested-worktree remedy today, `tidy-machine` and
`worktree-lane` next -- were getting the `<path>` placeholder for every real path.

**Score:** 3

#### What makes this deploy extra special

N/A -- an internal formatter for the workflow's own printed remedies; no subscriber of a service reaches it.

**Score:** N/A

#### Pull Request

Get-PasteableRef -Kind Path accepts an absolute filesystem path

Plugins: dkj-policy, dkj-subagents-shopify

[PR #1765](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1765)

---

### DEPLOY: fix/1760-prune-merged-worktree-held-branch · 20260910-081941

`prune-merged.ps1` no longer attempts a delete git is certain to refuse. A branch that is provably
merged but checked out in another worktree is reported kept in the script's own vocabulary, naming
the directory holding it and the `worktree-lane.ps1 -HandBack` command that frees it -- the sentence
#1069 already gives for a lane holding the trunk. `-DryRun` answers the same question, so the
look-first run no longer promises a delete the real run cannot perform.

The seam this closes: `worktree-lane.ps1` states that branch cleanup is `prune-merged.ps1`'s, and
`prune-merged.ps1` removes no worktree -- so a lane whose work had landed was owned by neither, and
the hand-back was a manual act nothing prompted for.

Small, and only visible to somebody running lanes: it prevents a confusing report rather than a loss.
The failure it prevents, named because the tier asks for it -- a session reads `git branch -D
refused: error: cannot delete branch 'x' used by worktree at '...'`, which is git's vocabulary rather
than this script's proofs, and has to work out for itself that the way out is a hand-back.

**Score:** 2

#### What makes this deploy extra special

Nothing reaches a subscriber: this is a maintainer's tidy-up command in the workflow plugin.

**Score:** N/A

#### Pull Request

prune-merged: a merged branch held by another worktree is kept with the hand-back, not handed git's refusal

Plugins: dkj-policy

[PR #1763](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1763)

---

### DEPLOY: docs/release-title-convention · 20260910-080700

From `v4.33.0` on, this repo titles every release `Release version X.Y.Z` and stops composing a
one-sentence summary that a large multi-theme cut makes meaningless. The decision and its reasoning are
in `dkj-policy/releases/README.md`'s *Local decisions* section; Rendall's lens carries the operating
instruction. The `-Title` parameter is untouched — a descriptive sentence is still valid for a repo
whose releases each carry one theme, and `-SummaryFile` still handles a genuine milestone.

**Score:** 1

The failure it prevents: a `history.md` title column and a GitHub Release heading filling up with
forced one-liners that describe none of the dozens of unrelated entries beneath them.

#### What makes this deploy extra special

One portable clause reaches a consumer, in the `cut-release` skill they read: a stable
`Release version X.Y.Z` is named as a legitimate title rather than something to apologise for. It
changes no command and no behaviour — the entries and attachments carry the detail either way.

**Score:** 1

#### Pull Request

Record that this repo titles every release Release version X.Y.Z

Plugins: dkj-policy

[PR #1761](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1761)

---

### DEPLOY: docs/1719-concurrent-pair-voiding-rate · 20260910-075556

Anyone changing `ship-pr.ps1`'s staleness gate now reads why it refuses, not just how often. The
block already carried the rate and (since #1750) its predicate; what it did not carry is the driver.
Issue #1719 measured it while being closed: the refusal tracks two branches CERTIFYING at the same
time -- 2 of 5 tight concurrent pairs lost a lap against 0 of 10 PRs outside such a pair -- and not
the trunk's own commit rate, which the paragraph above it had reached for. The practical consequence
is recorded with it: shipping one branch at a time drives the row to zero at no cost, which is why
#1719 closed against its own ranked converger options instead of building one. The measurement's
window, population and discount are stated, so the next reader can compare rather than re-argue.

**Score:** 3

#### What makes this deploy extra special

N/A -- a comment block inside a maintenance script. No consumer of this repo's plugins reads it and
no released behaviour changes; the mirror moves only so the drift lint stays green.

**Score:** N/A

#### Pull Request

Record the concurrent-pair voiding rate beside the step-3b predicate

Plugins: dkj-policy

[PR #1759](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1759)

---

