# Development cycle: `feat/script-layer-ascii-gate-v1` · 20260823-181640

<!--
     The plan for this branch. Every step must be resolved before the PR: open-pr and
     ship-pr both refuse while anything is still "- [ ]", and there is no -Force.

       - [ ] not done yet
       - [x] done
       - [~] dropped -- why it turned out not to be needed

     The dropped mark exists so nobody is pushed into ticking a box for work they did
     not do. It keeps its line and its reason, which is the half worth reading later.

     PLAN / CREATE / TEST / DEPLOY are the arc, not a quota: a phase with nothing
     under it is a statement that this branch had nothing there. The headings are
     invisible to the gate, which reads step marks only.

     DEPLOY takes no steps of its own. It is not a step but the result -- the
     section at the foot of this file, which is the part that travels verbatim into
     CHANGELOG.md at the merge. So a step written for after the merge is refused
     here: what happens after the merge is what DEPLOY describes, not a box to tick.
-->

## PLAN

- [x] Measure the real violation set: 158 tracked `.ps1`, exactly **two** files carrying a non-ASCII
      character -- `scripts/lib/pr-issues-lib.ps1` and its plugin mirror, two lines each, a deliberate
      en/em dash in a regex class. Damage in neither, so the check can be born green after one repair.
- [x] Second measurement, unplanned: the file set check 5 parses holds **151** of those 158. The seven
      absentees are every `plugins/<kind>/<plugin>/hooks/*.ps1`, so a parse error in a SessionStart hook
      was invisible to this gate -- and the ASCII rule names that layer explicitly.

## CREATE

- [x] Repair `scripts/lib/pr-issues-lib.ps1` -- the dash class is composed from `[char]` code points --
      and rebuild its plugin mirror with `scripts/sync/build-shared-scripts.ps1`.
- [x] Add check 27 `[script-ascii]` to `scripts/lint/check-plugin-integrity.ps1`, plus its entry in that
      script's own check index.
- [x] Widen the shared `.ps1` set to the plugin hooks, which fixes check 5 in the same edit, and cache it
      so two readers cost one directory walk.
- [x] Update `.claude/rules/language-layers.md`: the rule has a gate, and the two spots it named as
      deliberately unrepaired are repaired -- with the reason that is not the no-pre-emptive-fixes rule
      being overruled.

## TEST

- [x] Ten scenarios in `scripts/tests/check-plugin-integrity-docs.tests.ps1`: it fires with file, line,
      code point and remedy; the escaped form is silent; a BOM is silent; a plugin hook is in scope; and
      a hook that does not parse is now reported by check 5.
- [x] Four asserts in `scripts/tests/pr-issues.tests.ps1` for the en and em dash ranges, which nothing
      exercised -- so the repaired composition is provably behaviour-preserving.
- [x] Proven born green on the real tree (158 files, 0 findings) and proven to fire, by reintroducing the
      middot and reading the finding back.
- [x] Full lint + test gate green, with the wall-clock measured: the lint gate does not move
      (12.3s -> 11.9s, inside the noise), and the docs suite carries the new scenarios' five gate runs.

## DEPLOY: `feat/script-layer-ascii-gate-v1`

<!--
     Why the deploy matters AT THIS REACH specifically. A reason that would read the
     same under every tier is a sign the tier is wrong. Write it ABOVE the Score line --
     everything below that line is discarded. Then Score: 1-5 against the rubric
     new-branch printed when it wrote this file.

     Relative links resolve FROM THE REPO ROOT, not from this directory: this text is
     folded verbatim into CHANGELOG.md at the root. So write scripts/x.ps1, never
     ../../scripts/x.ps1 -- the second reads correctly here and is dead once it lands.
-->

The rule that the script layer is ASCII now has a gate. `[script-ascii]` — check 27 in
[`check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1) — holds every `.ps1` in the tree
to it and reports the file, the line, the code point, and the `[char]0x..` form to write instead.
[`.claude/rules/language-layers.md`](.claude/rules/language-layers.md) has required that since
August 19, 2026, after a middot typed literally into `scripts/lib/entry-scaffold-lib.ps1` came out of
every generated changelog template as two wrong characters. Nothing enforced it, and the reason it
needed its own check rather than an extension of the mojibake one is where the two look: `[mojibake]`
walks markdown, so it sees the mangled character **downstream**, in the generated document, after it has
been copied into somebody's entry. This one sees the literal upstream, in the source that will emit it.

A BOM is deliberately **not** a finding. On a `.ps1` a BOM is what makes Windows PowerShell 5.1 read the
file correctly, so accusing it would push an author toward the very defect; check 26 owns the documents
where a BOM does break something, and it reads bytes precisely because this check reads text.

**Measuring the set found a second defect, in a check nobody was looking at.** The `.ps1` set check 5
parses held **151** of this repo's 158 tracked scripts, and the seven absentees were every
`plugins/<kind>/<plugin>/hooks/*.ps1` — so a parse error in a SessionStart hook, the five that speak at
every session start here among them, was not seen by the PR gate at all. A hook that does not parse does
not announce itself: the harness reports it and the session simply continues without whatever the hook
was there to say. The set is one cached definition now, read by both checks and widened to those hooks,
which repairs check 5 in the same edit — and the alternative, letting each check decide for itself what
the set is, is the second-definition drift this gate exists to catch elsewhere.

The check is **born green**, which cost one repair rather than an exemption list: the two literal en/em
dashes in `scripts/lib/pr-issues-lib.ps1`'s regexes — the only non-ASCII characters in all 158 files —
are composed from `[char]` code points now. `.claude/rules/language-layers.md` had named those two lines
as deliberately unrepaired under the no-pre-emptive-fixes rule, and that is not being overruled: the rule
says a risk that has not bitten is written down rather than built against, this one had bitten in the
middot, and what it forbade was sweeping the lines along with an *unrelated* change. The change that
enforces the rule they break is the related one. Repairing them also exposed a live test gap —
[`pr-issues.tests.ps1`](scripts/tests/pr-issues.tests.ps1) asserted the ASCII hyphen range and neither
typographic dash, so a composition producing the wrong two characters would have passed every existing
assert. It asserts both now.

**Score:** 3

### What makes this deploy extra special
<!--
     Why the deploy matters AT THIS REACH specifically. For tier 2 audiences: the subscriber of a service.
     That reader and nobody else -- what matters only inside this repo is said in the section above.

     If it has no significance at this reach at all, then explain shortly why and insert N/A in Score.
     That reason goes above the Score line too, and one or two lines is the whole of it: N/A is a
     complete answer and the common one.
-->

Almost nothing, and the honest reason is where the gate lives. `check-plugin-integrity.ps1` is repo-owned
— a consumer names their own through `Get-LintScript` — so this check does not travel, and a consumer's
own script layer is not held to the ASCII rule by it. What does reach them is the shared mirror
`pr-issues-lib.ps1`, whose dash class is composed rather than typed: identical behaviour, now covered by
two dash asserts it did not have, so nothing to run and nothing to migrate. Worth one line rather than
none because the *failure* is theirs too — a literal typographic character in any `.ps1` they write is
decoded by Windows PowerShell 5.1 as two CP1252 characters, silently, and reaches whatever that script
emits.

**Score:** 1

### Pull Request
<!-- the PR title on the first line -- no feat:/fix:/docs: prefix, open-pr puts the branch type in front.
     link to the PR in github when branch is merged to main and the date this happened-->

A lint check holds the script layer to ASCII

