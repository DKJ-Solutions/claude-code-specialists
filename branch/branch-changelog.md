## `docs/branch-name-rule-why` changelog

### Branch description
<!-- Short description of branch-->

The branch-name rule records why it exists

### Branch ID
<!--unique ID for branch like a timestamp of the moment this branch is created-->

20260807-100032

### Branch type
<!-- options for type are: feat, fix or docs-->

docs

### What does the change on this branch bring to main?
<!--
     What the change DOES, for someone reading CHANGELOG.md months from now --
     not a report of what you did on the branch. Name what is different afterwards,
     and where a decision was measured rather than assumed, say what was measured.
-->

`Test-BranchName` refuses a branch name containing `final`, and now records **why** and **what to do
instead**. The rule is Dave's — *"je weet nooit zeker of iets echt final is"* — so a name claiming to be
the last word is a prediction, and a wrong one forces the next round to be called `final-2`. The remedy is
a version suffix (`fix/template-newline-v2`), which makes no such claim.

The refusal message says so too. It used to be `"Branch name must not contain the token 'final'."` and
nothing else, so the obvious next guess was `finished` or `done` — the same claim in a different word.

The docstring also records that the **opposite** rule once existed, before anyone restores it: a `-v2`
suffix used to be forbidden, because the fold looked an entry up by the exact branch name and a suffix
broke both the match and the cleanup after it. The `branch/` split retired that — the fold reads the branch
out of the document now — so nothing rejects `-v2`, deliberately.

Attributed to Derek in that docstring until the reasoning was actually asked for, which is how a decision
ends up looking like a habit somebody picked up.

### Significance

#### Tier 0

<!--
     Why the change matters AT THIS REACH specifically. A reason that would read the
     same under every tier is a sign the tier is wrong. Then Score: 1-5 against the
     rubric new-branch printed when it wrote this file.
-->

A gate that only says "not that" gets guessed at; this one now answers the question it provokes, and the
reasoning behind a hard rule is on the page instead of in one person's head.

**Score:** 2

<!--
     Is this change also relevant to colleagues and employers? Then continue to Tier 1.
     If not, stop here and move on to the next section.
-->

#### Tier 1

Anyone creating a branch here meets this refusal sooner or later, and the retired `-v2` prohibition is
exactly the kind of dead rule a later reader reinstates in good faith.

**Score:** 2

<!--
     Is this change also relevant to the people who consume this product? Then
     continue to Tier 2. If not, stop here and move on to the next section.
-->

### Pull Request
<!-- link to the PR in github when branch is merged to main and the date this happened-->

