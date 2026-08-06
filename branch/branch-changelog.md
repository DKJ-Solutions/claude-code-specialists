## branch/README.md gains the entry template and the reasoning behind the fixed filenames

### What does this change do?

Two things the page was missing, both of which someone had to ask for.

**The entry template, spelled out and pasteable.** `new-branch` already writes the shape into
`branch-changelog.md`, so a fresh branch is a form rather than a blank page -- but there was nowhere to
see the whole thing at once, or to get it back after cutting the file about. The README now carries the
empty shape, a worked example as it looks just before the PR, and the four things about it that have
each been got wrong before: the heading is the title alone, nothing in the body may use `##` or `###`,
the three section names are exact, and the impact table's empty scores are a question rather than a
default.

**And why the two files are called the same thing on every branch.** The obvious alternative --
`<branchname>-changelog.md` and `<branchname>-progress.md` -- was weighed and declined the same day, and
without that on the page the next person to look at the folder asks the question again with nothing to
answer it.

**The decisive reason is the warning on the trunk.** It exists because the files exist on `main`. Unique
names put nothing there: no template, no warning, and no `#` heading standing between the fold and a file
it must not read as a change. Two further reasons are recorded with it -- unique names reinstate the
derived filename that made a `-v2` suffix break the fold's lookup, and the collision they solve does not
happen, because git already tracks these files per branch.

**And the case *for* unique names is written down too, because it is real.** Taking `main` in during the
window between another branch's merge and its fold puts that branch's entry briefly beside yours in the
same file. That is a genuine conflict; unique names would not have it. It stays unsolved on purpose --
the conflict is visible, the resolution is trivial, the window is small, and the cheap repair (a merge
strategy for `branch/**` in `.gitattributes`) is named so nobody has to rediscover it.

**Leaving it is the decision, not the absence of one** (Dave, August 6, 2026): a mitigation for something
that has never occurred is machinery whose behaviour nobody has watched, bolted onto a design that works.
Recording the risk beside the choice is what keeps that honest -- the next reader meets the weak spot and
the reason it is tolerated in the same paragraph, instead of finding one without the other.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 1 | 3 | the entry format is visible in one place instead of being inferred from a scaffolded file, and the four mistakes it invites are named beside it |
| 0 | 2 | documentation only; the mechanism is unchanged |

### Type of change

Docs
