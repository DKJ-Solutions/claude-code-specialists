## `fix/tier-reason-below-score` changelog

### Branch title

The scaffold gate names a tier reason written below its score instead of calling it missing

### Branch ID

20260811-152836

### Branch type

fix

### What does the change on this branch bring to main?

A tier whose reason was written *below* its `**Score:**` line was refused as `a tier with no reason`. The
refusal was correct -- the fold would have published that tier empty -- but unactionable: "no reason" is the
one thing an author looking at their own three written paragraphs can verify is untrue, so the natural next
move is to distrust the gate rather than to move the text. Reported from a consumer
([#596](https://github.com/DaveKJohn/claude-code-specialists/issues/596)) where all three tiers were
answered and all three were reported as unanswered, and finding out why took reading
`entry-scaffold-lib.ps1` line by line.

The cause was one branch of one loop. `Read-EntryTierSections` collects a section's lines until the next
heading, and `$whyLines.Add($line)` sat behind `elseif ($null -eq $scoreCell)` -- so everything after the
score was read and then thrown away. The text needed to tell the two cases apart was already in hand at the
moment the gate said there was none.

Both halves of the section are now kept, and both gates that read the row say which case they are looking
at. The lines below the score become `WhyBelowScore`, which is diagnosis and never content: nothing
publishes it, nothing counts it as an answer, and the reason still has to move above the score line before
the entry passes. `open-pr.ps1`'s explanatory paragraph gains the third reading it was missing, and states
the rule once -- above the score is the reason, below it is discarded.

Three details that are part of the change rather than alongside it:

- **The filtering is one shared helper**, `Get-EntryTierReasonText`, called for both sides. This format's
  guidance comments live in the section, and one sitting under the score would otherwise read back as a
  misplaced reason -- accusing an entry nobody has written in yet, on every consumer, from the first branch.
  Asserted in both directions.
- **The release gate carried the same misdiagnosis**, which #596 did not report. `Get-EntryImpactFindings`
  reads the same row, so a below-score reason reached `cut-release` with the same unactionable wording --
  days later, when whoever wrote it is no longer the one reading the refusal.
- **The paragraph also still promised per-plugin `CHANGELOG.md` files that travel to consumers.** Those were
  retired on August 8, 2026. It was rewritten anyway, so the false clause went with it rather than being
  left in text this change was already touching.

The report's other suggestion -- moving the blank space *above* `**Score:**` so the mistake is harder to make
-- was deliberately not built. It changes what every consumer's scaffolder writes, and the report files it as
a consideration rather than a proposal. Measured while verifying: the scaffold leaves exactly one blank line
on *each* side of the score, which is why the mistake is easy rather than merely possible, and that
measurement is now written into the code as the reason the distinction exists.

One correction to the report, since the repair was built on reading rather than on it: the loop it describes
is in `Read-EntryTierSections`, not `Resolve-EntryImpact` -- the line numbers it gave were right, the
function name was one off.

### Significance

#### Tier 0

The same refusal runs here, at this repo's own `open-pr` and at its own cut. An author here loses the same
half hour, and the release gate half means it can be met days after the entry was written.

**Score:** 3

#### Tier 1

A colleague on this project meets this at the cut rather than on the branch, which is the expensive end: the
entry is already merged and folded, and the person reading the refusal is not the person who wrote it.

**Score:** 3

#### Tier 2

Consumers receive both gates through a plugin update rather than by choosing to, and the reporting repo lost
the better part of a round trip to a message that had the answer available and did not say it. The local
documentation net written there to stand in for this fix can now be deleted.

**Score:** 4

### Pull Request
