## `docs/v4-1-0-release-documents` changelog

### Branch title

The v4.1.0 release documents

### Branch ID

20260810-140324

### Branch type

docs

### What does the change on this branch bring to main?

The two documents `cut-release.ps1` deliberately does not write, for the minor tagged earlier today: the
**consumer-facing highlights** and the **internal summary**. They arrive via a branch and a PR because the
release commit is already tagged, and neither is one of the two changes allowed to land directly on the
trunk.

**The highlights went from 849 lines to about 130, and the cutting was not the work.** The generated draft
is the tier-2 entries verbatim, still in the words their authors wrote for someone reviewing a diff — six
of the fourteen open with the branch id and type before saying anything. What a consumer needs from
`v4.1.0` is almost the inverse: this release is largely about failures that produce **no error message**,
so the page leads with **three checks to run against their own repo**, each about state that may already
be wrong there rather than about anything this release changes underneath them.

The order of those three is a judgement rather than the draft's order, and it is the one editorial
decision on this branch worth arguing about. The drifted PR-template placeholder leads because it is the
only one with a measured cost attached — twelve merged PRs with no description — and because a reader can
test it in one action: open a PR and see whether the warning appears. `Get-ReleaseNotesGrouping` is second
because its failure is invisible *and* delayed: the contract check reports `[OK]` after a wrong adoption,
and the wrong tree only appears one release later. The `v3.x` migration path is third because it reaches
the fewest readers, and the ones it reaches are the ones least likely to be reading at all.

**The internal note is the published Release body, so its "what was still open" section is written as a
snapshot.** That is the section this repo has measured going stale in hours rather than months. It names
the two follow-ups that were declined with their reasons — the pre-written repo slot in the shipped
template, and extending `adopt-config` to files — and the one real gap: a consumer's own template is
checked by nothing, because the new gate runs here.

**Its "what it is worth" section names the theme rather than the changes**, which is what separates this
tier from the highlights: failures with no error message. Twelve empty PR bodies is not a crisis on any
given day; it is a record that quietly stopped being usable, found by diffing two files months later. The
same shape appeared three times in one week across different seams, and that pattern is the thing a
colleague outside this repo can actually use.

### Significance

#### Tier 0

Two documents that would otherwise be missing from the release, plus the `releases/README.md` row now
pointing at the internal note. Routine work with a checklist behind it.

**Score:** 2

#### Tier 1

The internal note is what a colleague reads about this release, and it is the only place the release's
theme is stated as a theme rather than as fourteen separate changes.

**Score:** 3

#### Tier 2

The highlights are the page a consumer opens, and this release's whole point is three things that may
already be wrong in their repo. A draft left in reviewer language would have buried all three under
branch ids.

**Score:** 4

### Pull Request
