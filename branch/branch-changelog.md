## `docs/post-merge-steps-convention` changelog

### Branch title

post-merge work is not a step, and the step list says so

### Branch ID

20260813-104921

### Branch type

docs

### What does the change on this branch bring to main?

Work that happens *after* the merge — opening the PR, waiting for CI, merging, folding, publishing a
Release, a measurement that only exists once the run is over — is now stated to belong under
`### Where I left off` rather than under `### Steps`. Written into
[`branch/README.md`](branch/README.md) as rule 5, and into the **portable** `new-branch` skill so a
consumer receives it, since the mechanism it follows from is theirs too.

**The argument is the gate's timing, not taste.** The step-list gate reads the list *before* the push, so
at that moment a post-merge step cannot be done — and **neither mark fits it**: `- [x]` reports work that
has not happened, `- [~]` says the step turned out not to be needed when it is needed and merely comes
later. The only way past the gate is to tick a box for work you did not do, which is precisely the failure
the third mark was introduced to prevent, arriving through the front door.

**It was carried as "a convention question raised three times". It is worse than that, and measuring it is
what this branch actually adds.** Across the **105** branches that have ever carried a step list, **17**
wrote a post-merge step: **4** were blocked by it, and **14** ticked it in advance — *provably* in advance,
because the fold **resets** `branch-progress.md` at the merge, so a ticked PR step can only have been
written before the PR existed. One branch sits in both counts and is the whole case in two commits:
`docs/check-20-and-inbound-catch-up` hit the gate on `- [ ] Lint + tests green, then PR + merge + fold`
(`0efeff8`), and its next commit (`e2d633e`) changed nothing but that box to `- [x]`. Two other branches
had already reached the right answer unaided and dropped the step with the reason on the line; the rule
generalises what they did.

**Two of the seventeen are from the session that wrote this rule**, which is why it is stated rather than
merely noticed — the convention was being violated by the specialist documenting it, one branch after the
lock flagged it.

**No gate enforces it, deliberately, and that half is the transferable one.** A check would have to
recognise a post-merge step by its wording, and `open-pr`, `merge` and `fold` are also the subjects of
perfectly ordinary steps — *"`open-pr.ps1`: recognise the new placeholder alongside the two legacy ones"*
is real work on a branch. Separating the two needs an exclusion list, which is the shape this repo has been
bitten by often enough to stop reaching for it. The convention costs nothing to follow and the failure is
self-correcting: write it as a step and the gate stops you.

Plugins: workflow-davekjohn

### Significance

#### Tier 0

The gate stops being satisfied by a tick instead of by the work. That is not hypothetical here — 14 of 17
instances were ticked in advance, and one branch is on record doing it in a commit that changed nothing
else. Anyone writing a step list now has the answer in the file that scaffolded it.

**Score:** 3

#### Tier 2

A consumer runs the same gate with the same timing, so the same trap is theirs — and the portable
`new-branch` skill now states the rule, the reasoning, and why no check enforces it. It also hands them the
count to run over their own branches rather than this repo's conclusion.

**Score:** 3

### Pull Request

