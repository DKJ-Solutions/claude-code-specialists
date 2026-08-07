## `fix/release-runs-the-suites` changelog

### Branch description

The release passes the same test gate every PR does

### Branch ID

20260807-171359

### Branch type

fix

### What does the change on this branch bring to main?

`cut-release.ps1` runs all the test suites before it writes anything, with `-SkipTests` as the escape
valve. Until now it ran the **lint alone**, which made the release commit the least-checked commit in the
whole workflow:

| | lint | the 26 suites | CI |
|---|---|---|---|
| every ordinary PR | yes | yes | yes, and blocking |
| the release | yes | **no** | yes, but after the fact |

That is the commit which bumps four plugin versions in lockstep, rewrites four `RELEASE.md` cards,
regenerates the per-plugin changelogs and empties `CHANGELOG.md`. A red suite could be committed, tagged
and pushed, with CI reporting it only once the tag was already on it.

**The gate is shared, not copied.** `open-pr` has run the suites since PR #54's lesson, and the obvious
repair was to paste its fifteen lines into the cut. That is the duplication this repo spent the day
removing in six other places -- two copies of one rule, free to drift, and the one that drifts is whichever
nobody looked at. The loop moved into `Invoke-TestSuiteGate` and both callers use it. Its home
(`native-capture-lib.ps1`) is an imperfect fit and the header says so: both callers already load it and
running child processes is what it does, weighed against the cost of a new shared file -- a registry entry,
a mirror and a contract row for one function.

**What this still cannot see, stated so nobody reads more into it.** The suites run against the tree
*before* the cut, so a defect the cut itself introduces -- a malformed `RELEASE.md` card, a broken
generated note -- is invisible to them. CI on the `main` push catches that afterwards. The two are
complementary and neither replaces the other.

**A correction that came with the measurement.** The original issue claimed CI does not run on the release
at all, reading `Bypassed rule violations` as proof. It does run, and the v3.7.0 run was green -- what was
bypassed is the *ruleset* that would have held the push back, not the workflow. The real gap was narrower
than first reported, and the issue now says so rather than being quietly rewritten.

### Significance

#### Tier 0

The one commit that cannot be un-pushed cheaply is now checked as thoroughly as a documentation typo, and
before it is written rather than after.

**Score:** 4

#### Tier 1

A release is the moment the project speaks to everyone at once. Cutting one on a red suite would be found
by whoever reads the notes, not by whoever cut them.

**Score:** 3

#### Tier 2

`cut-release` is plugin-carried, so a consumer's releases gain the same gate and the same `-SkipTests`
escape valve. Their cut takes longer by exactly the time their own suites take.

**Score:** 3

### Pull Request

