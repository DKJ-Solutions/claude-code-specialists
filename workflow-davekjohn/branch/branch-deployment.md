## `fix/entry-link-destination-gate` deployment

### What does the change on this branch deploy to main?

A branch writes its entry in `workflow-davekjohn/branch/branch-deployment.md`, two directories down, and
the fold copies that text **verbatim** into `CHANGELOG.md` at the repo root. So a relative link in an entry
has to be written root-relative — which means it looks wrong in the file being edited and only becomes
right after it moves. Nothing said so, and the natural instinct produces the broken form.

Three parts, in the order an author meets them:

- **The convention is stated where the body is typed.** The guidance block above the entry's first section
  ([`scripts/lib/entry-scaffold-lib.ps1`](scripts/lib/entry-scaffold-lib.ps1)) now names the rule with both
  forms side by side, so it reaches the author before any gate does — and because the templates are
  generated from that block, it travels to every consumer through the same plugin update as the scripts.
- **`open-pr` gains a link gate.** `Get-EntryLinkTargets` and `Get-EntryLinkFindings` read the entry's
  relative links and hold them against the repo root; [`scripts/release/open-pr.ps1`](scripts/release/open-pr.ps1)
  refuses to push while one of them is dead. The message prints the **root-relative form**, not only the
  dead one — a finding that says merely *"does not exist"* sends the author to add another `../`, which
  breaks a link that was right.
- **The portable half says it too**, in
  [`BRANCH-portable.md`](plugins/workflows/workflow-davekjohn/BRANCH-portable.md) and in
  [the `open-pr` skill](plugins/workflows/workflow-davekjohn/skills/open-pr/SKILL.md), including why
  `branch-cycle.md` is deliberately **not** subject to the rule: that file never travels, so `../` is
  correct there.

**Two departures from what inbound
[#806](https://github.com/DaveKJohn/claude-code-specialists/issues/806) asked for, both measured.**

It reported that *"a consumer-side linter structurally cannot [check this] — it runs before the move"*, and
proposed the fold as the only place that knows both paths. This repo's own lint has resolved the entry's
links **from the repo root** since August 6, 2026 —
[`scripts/lint/check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1) carries that branch
with the measurement of the day the `branch/` split broke it, and even names the base in its finding for
exactly the reason above. So a linter can; what the reporting consumer lacked was not a mechanism but the
**rule**, and a rule is what a plugin can ship. Building the fold check would have been a second
implementation of a rule the lint already owns — the double-registration failure #805 names in the same
batch.

And the gate sits in `open-pr` rather than in the fold because that is the fold's **own** doctrine on this
kind of fault, stated in its own words about a missing significance score: a defect decidable before the
merge is refused while the branch is still the only thing affected, since refusing an already-merged
branch's fold leaves an unfolded entry on the trunk with `main` looking finished. The report's preferred
option — rewriting the links as it folds — is declined for a second reason: the fold copies the entry
verbatim on purpose, and an author whose link is silently corrected writes the same link again into the
next document, where nothing corrects it.

**Score:** 3

#### What makes this change extra special

`open-pr.ps1` and `entry-scaffold-lib.ps1` are both mirrored into `workflow-davekjohn`, so every consumer
gets the gate and the guidance — including the one that filed this, whose PR #43 would have been refused
before the push instead of leaving two dead links in the file nobody re-reads.

The exclusion set was measured rather than assumed, and the measurement is what makes the gate usable:
across the last **80 revisions** of this repo's own entry file, a scan that strips only fenced code
produces exactly **one** finding, and it is false — `[PR #N](url)` in inline backticks, in an entry
explaining what the fold writes. So inline code and HTML comments are stripped as well, which is the same
three-way exclusion this repo's link lint arrived at from the same case.

**Score:** 3

### Pull Request

an entry's relative links are held against the destination they fold into
