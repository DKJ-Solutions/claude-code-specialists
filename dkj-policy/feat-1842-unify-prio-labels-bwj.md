## feat/1842-unify-prio-labels-bwj

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### The scope #1842 filed, and the sixth file it does not name

The issue names five files. Measured on pickup, a sixth carries the same now-reversed claim:
`.claude/specialists/lenses/05-05-extension.md` states the two label sets are *"deliberately
disjoint"*, that the different names are *"load-bearing"*, and that *"nothing here needs doing about
it"*. It is always-on prose in the repo that ships the change, so leaving it would ship a
contradiction. It is in scope.

#### The two questions #1842 leaves to whoever picks it up

- **"The window is the thing to plan for, not the rename."** Answered by measurement rather than
  assumption. The consumer's `asana-mirror.ps1` is a **hand-copied** file in its own
  `.github/scripts/` (`adopt-dkj-policy-bwj` step 1), not something a plugin update delivers; and the
  prio sweep runs **only** in `reconcile` mode -- the daily `17 6 * * *` cron plus
  `workflow_dispatch`, never on an `issues:` event. So the gap between the template refresh and the
  label rename is one operator's, in one sitting, and any sweep caught inside it is repaired by the
  next morning's run. **No compatibility shim was built**: it would be shipped code with a
  one-release lifetime that nothing would remember to remove, which is the enforced-by-memory shape
  this tree files issues against. The rollout order is documented instead, at the two places the
  operator actually reads -- the skill's step 4 and `Set-IssuePrioLabel`'s own docstring.
- **The half-migrated repo is a different hazard, and that one IS guarded.** `gh label edit --name`
  renames in place and leaves nothing behind, but `adopt-dkj-policy-bwj` step 4 is **additive and
  never rewrites an existing label** -- so a repo brought over by re-running that step holds all
  eight, with the old name still sitting on every issue, and the sweep would add `prio-4` beside a
  standing `very high`. The four old names therefore stay on the **removal** side of
  `Set-IssuePrioLabel`, never on the write side. **Bounded rather than permanent**: the four are
  generic English words, and once both stores are migrated the names are free again, so an unrelated
  label named `low` would be stripped by a daily job holding `issues: write`. Not new behaviour --
  the same strings sat in `$script:PrioLabels` before the rename and were swept the same way -- but
  the likelihood only rises. Raised by the security review, recorded beside the array, and given a
  number so the removal is tracked rather than remembered:
  [#1848](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1848).

#### What was found and filed rather than fixed here

#1842's mapping puts BWJ's `prio-2` on `FBCA04`, which is the hex `tier-1` has carried in those same
repos since `adopt-dkj-policy-bwj` shipped. Before this change that clash was *across* the family
and [#1691](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1691) weighed it and left
it; now the two are the same yellow **inside one repo**, on one issue, on two different axes.
Implemented as #1842 specifies and filed as
[#1844](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1844) -- moving either hex is an
edit to live labels in two repos this one does not own.

#### The parallel review, and what it changed

Victor, Edith and Sebastian ran on the diff at once. Sebastian: no blockers, one advisory that became
[#1848](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1848) above. Victor: no bugs, and he
verified the 5.1 array concatenation and `$null -contains` against a real `powershell.exe` rather than
reasoning about them; his one finding was a worked example in `SKILL.md` still naming the retired
labels two paragraphs past the block that renamed them, filed as
[#1847](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1847) and **fixed on this branch**,
since it is inside this branch's own scope rather than outside it. Edith found the same sentence plus
four more: the new #1686/#1691 citations carried the retired repo name, the hex casing in `SKILL.md`
broke that file's own lowercase convention on the very line arguing about `fbca04`, the one-line rename
example in `WORKFLOW-portable.md` omitted `--color` where two of the four rungs change colour, and a
missing article in the template docstring. All five applied, and the URL correct-on-edit was applied
to the four files this branch edits and to no others.

### CREATE

- [x] `templates/asana-mirror.ps1`: `$script:PrioLabels` onto the new four, the four returns in
      `Get-PrioLabelForScore` and its band table, and `$script:LegacyPrioLabels` read by
      `Set-IssuePrioLabel`'s stale set only
- [x] `skills/adopt-dkj-policy-bwj/SKILL.md` step 4: the four create lines (names **and** hex), a
      rename block for a repo adopted before today, the rollout-order note, and the `FBCA04` note
- [x] `WORKFLOW-portable.md` §5: the band table, and the disjointness paragraph rewritten into what
      separates the two motors now -- the label DESCRIPTION, which a rename leaves untouched
- [x] `plugins/dkj-policy/dkj-policy-bwj/README.md`: the four names in its summary sentence
- [x] `.claude/specialists/lenses/05-05-extension.md`: the reversed-decision block and the colour
      table, which is a mirror across the family now rather than a disagreement

### TEST

- [x] `scripts/tests/dkj-policy-bwj.tests.ps1` repinned: the 8 boundary asserts, the
      culture-invariance assert, the `Set-IssuePrioLabel` assert, plus two new ones for
      `$script:LegacyPrioLabels` -- its count, and that the two sets never overlap
- [x] The third candidate assert was **dropped as derivable**: "the mapper never returns a legacy
      name" follows from the existing `PrioLabels -contains` loop plus disjointness
- [~] That the removal itself FIRES is not asserted -- it sits past the early return and would need a
      `gh` call. Named in the suite as a known test gap rather than left implied
- [x] `check-plugin-integrity.ps1`: 0 errors
- [x] All suites green

### DEPLOY: feat/1842-unify-prio-labels-bwj

The BWJ store repos rank their issues on the same four labels as every other repo in the family:
`prio-1` to `prio-4`, on the same four colours, replacing `very low` / `low` / `high` / `very high`.
One vocabulary across the family, reversing half 1 of
[#1686](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1686) on Dave's instruction.
The score bands behind them are untouched -- the same mapping, said in the other repos' words -- and
what now says which motor set a rung is the label's **description**, which a rename leaves alone:
`Asana Prio-Score 2.00-2.99` over there against `Priority 2 of 4` here. The sweep sheds the four old
names as it sets a new one without ever writing them, so a repo migrated with the additive create
step instead of the rename is swept clean rather than left claiming two priorities at once.

**Score:** 3

#### What makes this deploy extra special

N/A. This workflow's consumers are the BWJ store repos, whose *developers* read these labels; no
customer of either store ever sees one. The migration itself is two `gh label edit` commands per
store, documented in the skill.

**Score:** N/A

#### Pull Request

Unify the BWJ priority labels on prio-1..prio-4
