### A branch carries a step plan, and the PR waits for it · Feat

| Tier | Significance | Why |
|---|---|---|
| 1 | - | - |
| 0 | - | - |

**To do / where I left off:**

**PARKED -- nothing built yet.** Requirement from Dave, August 5, 2026, in his own words:

> Zodra een nieuwe branch wordt aangemaakt wil ik een extra markdown bestand aanmaken waarin het
> stappenplan gezet wordt van deze branch. Pas als alle punten zijn afgevinkt kan de branch met een PR
> gemergd worden. Dus je hebt dan de standaard entry branch met omschrijving wat al gedaan is, dat ook
> makkelijk te verplaatsen is naar de CHANGELOG in de main branch. En een to do list.

Quoted verbatim, and deliberately: everything below is one reading of it, and if a decision here turns
out wrong the sentence that was actually said is still on the page to re-read.

**What it splits.** A branch gets **two** files instead of one, each with a single job:

| file | subject | audience | lifetime |
|---|---|---|---|
| `<branch>.md` (exists) | what the change **does** -- the description that folds into `CHANGELOG.md` | whoever reads the changelog later | folded at the merge |
| the new one | what still **must happen** -- a checklist | whoever is working on the branch | ends at the merge |

**And that is the whole reason the split earns its keep, rather than being a second file for its own
sake.** The entry file currently does both jobs: `new-changelog-entry.ps1` scaffolds it with a body
heading that literally reads `**To do / where I left off:**`, and the scaffold gate refuses to ship a PR
while that heading is still there. So the entry is today's to-do carrier *and* tomorrow's changelog
prose, which is why "replace this whole block before the PR" has to be a written instruction rather than
something the format makes obvious. Two files make it obvious.

**The reading that was given to Dave (his to correct):**

1. **The to-do half moves OUT of the entry.** `new-changelog-entry.ps1` stops writing a
   `**To do / where I left off:**` body into `<branch>.md`, and writes it into the plan file instead.
   Leaving it in both places is the same fact in two places, which is the drift shape this repo has paid
   for repeatedly -- and the more expensive version of it, because the two would disagree about *which*
   is the real list. The scaffold gate's marker set moves with it.
2. **The plan file opens with an H1**, and that is load-bearing rather than cosmetic. Two mechanisms key
   off the entry format structurally: `Test-IsChangelogEntryFile` in the fold treats an H2 (or a
   pre-format H3) as "this is an entry, fold it", and `cut-release.ps1` treats every root `*.md` outside
   `Get-ReservedRootMd` as an entry somebody forgot to fold and refuses to cut. An H1 makes the first
   ignore it -- exactly as `CONTRIBUTING.md` and `SECURITY.md` are ignored -- while the second still
   screams if the file ever reaches `main` unremoved. That second half is a **feature**: it is the guard
   that catches a plan file the fold failed to clean up.
3. **The gate fires twice, and that is not belt-and-braces.** `open-pr.ps1` refuses to push while an
   unchecked item remains -- that is where the scaffold gate and the impact gate already live, and it
   fails before anything leaves the machine. `ship-pr.ps1` refuses to merge for the same reason. Dave
   said *merged*, and `open-pr` has `-Force`; a PR opened through that escape valve would otherwise land
   with an unfinished plan, which is precisely what he asked to be impossible.
4. **The fold removes it alongside the entry**, and names it in the same pathspec. The fold commit's
   scope is enforced by git rather than by care (it lands directly on `main` under a named exception), so
   a second path has to be added deliberately -- and the "only the ones git already tracked" rule applies
   to it identically.

**Open, and genuinely undecided:**

- **The file name.** `<branch>.plan.md` sits beside the entry and sorts next to it; a `plans/` directory
  keeps the root clean but loses the at-a-glance "what is in flight" read that makes the root worth
  scanning. Root is the current preference, for that second reason.
- **Whether it is required.** Does `open-pr` refuse a branch with **no** plan file at all, or only one
  with unchecked items? Refusing its absence makes the mechanism real; tolerating it makes a one-commit
  typo fix not need ceremony. This is Dave's call, and it is the one that decides whether this is a
  workflow or a convention.
- **What counts as "afgevinkt".** `- [ ]` versus `- [x]` is the obvious parse, but a plan legitimately
  grows items that turn out not to be needed. Something has to exist for "dropped, deliberately" or the
  gate teaches people to tick boxes they did not do -- which is worse than no gate, because it reports
  success.

**Sequencing, and why this is parked rather than built.** It touches five files that
`feat/changelog-one-heading-per-change` is already rewriting across its remaining steps:
`new-changelog-entry.ps1`, `entry-scaffold-lib.ps1`, `open-pr.ps1`, `ship-pr.ps1` and
`fold-changelog-entry.ps1`. Building both at once makes one unreviewable diff and one release entry
carrying two changes. So this waits for that branch to merge, then starts from `main`.

One consequence worth knowing before that happens: **this entry file is itself in the pre-flat format**
(an H3 heading, no named sections), because it was scaffolded from `main`. When the other branch merges,
this file becomes a live test of the promotion path that branch's step 1 built -- the fold will lift its
heading to an H2 and say so. That is intended, not an oversight.

**Before the PR:** replace this whole block with what the change does, and fill in the two significance
cells -- the tier rows are certain (a colleague working here meets a new required file; nobody outside
this repo does), the scores belong to whoever finishes it.
