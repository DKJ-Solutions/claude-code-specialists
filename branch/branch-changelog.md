## `feat/the-pr-template-has-a-portable-half` changelog

### Branch title

The PR template's shape ships with the plugin

### Branch ID

20260810-132301

### Branch type

feat

### What does the change on this branch bring to main?

Items 2 and 3 of [#573](https://github.com/DaveKJohn/claude-code-specialists/issues/573), after item 1
shipped the warning in [#574](https://github.com/DaveKJohn/claude-code-specialists/pull/574).

**The reference now exists**, at
[`plugins/workflows/workflow-davekjohn/templates/pull_request_template.md`](plugins/workflows/workflow-davekjohn/templates/pull_request_template.md).
`.github/pull_request_template.md` is the one file in this whole cycle that **cannot** live in the
plugin — GitHub reads it only from that path in the consumer's own repo — so unlike
`CONTRIBUTING-portable.md` there is nothing to `@`-import and the file has to be copied. That is what
makes it the drift-prone one, and it had no shared copy to drift *from*.

**The placeholder list moved, and that move is the fix rather than tidying.** The three recognised
strings were three literals inside `open-pr.ps1`, which meant **nothing outside that script could read
them** — so no gate could hold the reference against the list that has to recognise it, and a reference
shipping a placeholder the matcher walks past is worse than no reference at all: it arrives looking
authoritative. They live in `pr-body-lib.ps1` now, beside `Get-PrTemplateCanonicalPlaceholder` (the one
that is *written*, taken from the end of the recognised list rather than spelled out again) and
`Get-PrTemplateReference` (the two-line body, built from that placeholder). A second literal anywhere in
that chain would be free to drift, and drift between those two is exactly what #573 was filed about.

**Lint check 24 holds both templates, at deliberately different strengths.** The shipped reference is
held **byte for byte** to `Get-PrTemplateReference` — it is an answer this family hands out, not a
document anyone edits, the same reasoning as check 13b for `branch/templates/` and check 21 for the
config blueprint. This repo's own `.github/pull_request_template.md` is held only to the **contract**: a
first heading at any level, and a placeholder line the matcher recognises. Weaker on purpose — that file
is genuinely repo-owned, and the day it grows a section this repo needs, a byte rule would refuse a
correct change and the gate would be edited to allow it, which is how a check gets switched off rather
than heeded. A repo with **no** template is not a finding either: only a template that exists makes a
promise.

**What a consumer gets, stated rather than implied:** the warning from #574 at the moment they run
`open-pr`, and this reference to diff against. Their own tree is checked by nothing, because this gate
runs here — and `check-script-contract.ps1` cannot close it either, since `Get-PrDescriptionPlaceholder`
is **optional**, so a repo that does not define it is correct. That is the same shape already recorded
for `Get-BranchTypes`.

**Item 3, which is the part worth reading twice: what travels is the MEASUREMENT, not the answer.**
[#538](https://github.com/DaveKJohn/claude-code-specialists/pull/538) removed this repo's checklist after
counting 60 PRs, and the temptation is to ship the conclusion — *"the portable template has no
checkboxes"*. The rule is `keep what is neither restated by the entry nor proven by a gate`, and that
nothing survived it **here** is a fact about this repo. The consumer who filed #573 re-ran the same count
over their own 60 PRs and found **one box of eight that genuinely varied**: a preview-URL approval, on a
repo whose result has to be judged by eye and which no gate can prove. They kept it and dropped the other
seven — #538 applied, not ignored. So the `open-pr` skill and `CONTRIBUTING-portable.md` state the method
and ask the next repo to run it, and the reference stays two lines without claiming two lines is the
answer. Their pass also confirmed the failure this repo predicted when it removed the prefix checklist:
**5 of their 60 PRs ticked two rows and 2 ticked none**, while the label came from `Get-BranchInfo` in all
60.

**One thing the issue asked for is deliberately not built: the `## Specific to this repo` slot.** The
observation behind it is right and the mechanism does not carry over — a contributing guide is read once,
while every heading in a PR template is repeated in **every PR body forever**, so a pre-written empty slot
would be a permanent empty section in a consumer's PR list. Both documents say to add one when there is
something to put in it, and say why it is not there already.

**A trap this branch fell into, now written where the next person will be standing.** Two suites COPY
`check-plugin-integrity.ps1` into a temp tree and run it for real, so each one has to mirror the lint's
dot-source list by hand. A lib a fixture does not copy does not make one check misbehave — the script
**dies at the import**, and every check after it silently never runs. It surfaced as four failures in
check 23, a check this branch never touched. The warning now sits at the import block in the lint rather
than in the suite that felt it.

Two smaller repairs came along because the same files were open: `pr-body.tests.ps1`'s load-bearing assert
was a substring search over `open-pr.ps1`'s text — the only thing available while the literals lived there
— and now calls the list, performing the same whole-line comparison the script performs instead of an
approximation of it. And the plugin README's folder table did not mention `templates/`; a shipped artefact
no document names is one a consumer never finds.

Plugins: workflow-davekjohn

### Significance

#### Tier 0

Check 24 is the first gate that can see the PR-template contract at all, and it exists only because the
placeholder list became readable. It also holds the shipped reference, which nothing here reads — the
class of artefact this repo has twice found stale, since a wrong one breaks nothing locally.

**Score:** 3

#### Tier 1

Names the shape for the next seam that has this problem: where a shared script matches against a literal
list, that list belongs where a gate can reach it, or the thing it must recognise cannot be held to it.
Three consumer defects in one week came through seams that degrade quietly — `Get-BranchTypes`,
`Get-ReleaseNotesGrouping`, and this one.

**Score:** 3

#### Tier 2

A consumer gets something to copy and to diff against, where before there was nothing — and gets the
reasoning behind the two-line default rather than the default presented as the rule, so they run the
count on their own history. The repo that filed this held a hand-written template and a private copy of
our three placeholder strings in their test suite; both can go.

**Score:** 4

### Pull Request
