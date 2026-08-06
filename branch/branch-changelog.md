## A branch does not open a PR while a step is still open

### What does this change do?

The step list becomes a gate. `open-pr.ps1` refuses to push and `ship-pr.ps1` refuses to merge while
`branch/branch-progress.md` has anything unresolved in it. This is the second half of the requirement
that produced the `branch/` split -- *"pas als alle punten zijn afgevinkt kan de branch met een PR
gemergd worden"* -- with the first half being the two files themselves.

**Three marks, and the third is what makes the gate honest:**

```text
- [ ] not done yet          -> blocks the PR and the merge
- [x] done
- [~] dropped -- <why it turned out not to be needed>
```

A plan legitimately grows items that stop making sense. A gate offering only *tick it* teaches people to
tick boxes for work they did not do, and then reports success -- which is worse than no gate, because it
comes with a citation. `- [~]` keeps the line and the reason on the page, which is the half worth
reading later, and it is precisely what lets this gate be **un-`-Force`-able**: there is no legitimate
case left for overruling it, so a second escape valve would only ever be used to skip the first. That is
the same reasoning the impact gate runs on, and the opposite of the scaffold gate's, which does have a
`-Force` because an entry can legitimately quote the wording it refuses.

**A step still carrying the scaffold's own placeholder is refused, ticked or not.** Ticking the
scaffolded first step without replacing it reports a plan as finished that was never written -- the same
shape measured on three of v3.2.0's entries one file over, where the author kept the stub and appended a
status behind it.

**It fires in both scripts, deliberately.** The requirement is about the *merge*; `open-pr` has a
`-Force`, and a PR can also be opened by hand on github.com or opened days ago and resumed. Checking
only at the push would leave all three routes able to land an unfinished plan. `ship-pr` re-reads the
working copy rather than trusting step 1, because it may have changed since.

**A branch with no step list at all is not refused.** A branch created by hand rather than by
`new-branch` carries the trunk's empty reset state, which holds no steps -- the one-commit typo fix.
Refusing that would make the mechanism ceremony rather than a tool. What is not tolerated is a
scaffolded list left as scaffolded: that branch did run `new-branch` and then ignored what it wrote.

**And the directory gets a README.** `branch/README.md` states what the two files are for, why their
names are fixed, why the reset state opens with an `#`, how links in each are resolved, and the six
rules -- including this gate. It is the page to send someone to instead of explaining the folder.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 3 | a consumer's PR is now refused while a step is open, and the `- [~]` mark is the thing they have to know about before it happens to them |
| 1 | 4 | the plan a branch wrote down at the start is the plan it has to finish, checked rather than remembered -- and the folder finally has a page that explains itself |

### Type of change

Feat
