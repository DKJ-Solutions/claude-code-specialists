## `fix/test-capture-keeps-the-message-whole` deployment

### What does the change on this branch deploy to main?

`prune-merged.tests.ps1` goes green on a developer machine. Its no-trunk case asserts that the refusal
**names the branch it looked for** (`no local branch 'main'`), and that assert failed here four runs out of
four while CI passed the very same commit — so the local test gate refused every release and every PR on
this machine, over a script that was correct in both places.

The cause was in the test harness rather than in
[`prune-merged.ps1`](scripts/task/prune-merged.ps1), and it is worth stating precisely because the obvious
reading is wrong. `Get-FlatOutput` removed newlines from the captured child output, which is the documented
guard against a console wrap splitting an asserted phrase. That guard is sound for a wrap and useless here:
a native child's stderr captured with `2>&1` arrives as **one `NativeCommandError` per stderr line**, and
`Out-String` then *formats* each of those records for display. The decoration it adds — `At <file>:<line>
char:<n>`, the `+ CategoryInfo` block, `+ FullyQualifiedErrorId : NativeCommandError` — lands **between**
the two halves of the wrapped sentence. Removing newlines cannot bridge that: the gap holds a paragraph of
PowerShell, not a line break.

So the fix is upstream of the normalisation, not another normalisation. The records are read as text
(`[string]$_`) and joined with nothing between them, which reconstructs the child's hard column break
exactly — `'dirt'` + `'y working tree'` — and never invites the formatter that was inserting the gap.

**Why it was invisible until now.** The wrap point moves with the console width **and with the length of
the fixture's temp path**, which carries the process id (`prune-merged-test-27324-e`). Neither is decided by
anything under test, and CI's combination happens to keep that sentence whole. A green CI was therefore not
evidence: it measured a different wrap point, and the assert had been a coin toss on the sentence's length
since it was written.

**Score:** 4

#### What makes this change extra special

A consumer running the shared `prune-merged.ps1` — new in 4.17.0's payload, so this is its first release
in anyone's hands — meets its test suite on their own machine, at their own path length, in their own
console. The assert that was fragile is the one covering the single case where a wrong answer would delete
branches against the wrong ancestry, so it is the assert a consumer most wants to be able to trust.

The generalisable half is the reading, and it is the reason this entry is longer than the diff. **A phrase
assert on a captured child refusal is not made safe by flattening whitespace**, and five sibling suites are
currently written as though it were: `park-branch`, `session-status`, `new-branch`,
`find-specialist-mentions` and `shared-scripts` all render the capture with `Out-String` first. They have
diverged on the part that does not matter — three different normalisations between them (`''`, `' '`, and
`-replace '\s',''`) — and agree on the part that does. **They are green and are deliberately left alone**;
this names the risk rather than repairing what has not bitten. Whoever does meet it next has the mechanism
written down instead of the four hours.

**Score:** 3

### Pull Request

A captured refusal is read as text, so a console wrap cannot split the phrase a test asserts on
