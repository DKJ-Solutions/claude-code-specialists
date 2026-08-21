## `fix/sync-floor-anchors-on-the-subject` deployment

### What does the change on this branch deploy to main?

The Shopify pre-task sync reads its floor off the commit **subject**, so a commit that merely *talks*
about a sync can no longer become the reference point. Reported as inbound
[#819](https://github.com/DaveKJohn/claude-code-specialists/issues/819) by the consumer that had just
taken the previous repair, and it is the rare inbound that reports **a fix as incomplete rather than a
defect as new**.

`--no-merges` was the repair for
[#801](https://github.com/DaveKJohn/claude-code-specialists/issues/801), and the docstring that landed
with it said the flag "separates a subject from a body line". It does not. It removes **merge** commits
and nothing else, while `--grep` stays line-oriented over the whole message -- so any **ordinary
single-parent** commit whose body happens to open a line with `sync` still won. A commit message that
*discusses the sync script* was enough to become the floor for the sync script.

**What the wrong floor costs, measured in the consumer:** the floor landed on a `fix:` commit 48 minutes
newer than the real previous sync, because line 28 of its body read `sync-main.tests.ps1 goes from 20 to
32 asserts`. `floor..HEAD` fell from **13 commits to 5** -- eight commits of merged trunk work reading as
untouched, so the exclusion rule passed those files through to live's older version. Same green run, same
failure mode #801 was filed against; the flag had narrowed the hole rather than closed it. Of the three
false positives in that repo's history, `--no-merges` caught one.

**Re-measured here, where it is starker, and this is the half the report could not see.** The source repo
runs no live-theme sync and therefore has **zero** commits with a sync subject -- and the `--grep` lookup
still answered one, `fix: the Shopify pre-task sync decides by content provenance...`, six such false
positives across 2,012 commits. The truthful answer here is *no sync commit, fall through to the tag*,
which is what the repo now gets: `v4.17.0`, a wide and protective window, instead of a floor an hour old.

So `Get-SyncReferencePoint` no longer passes `--grep` at all. It reads `%H%x09%s` and applies the pattern
to the subject field. **The seam is untouched** -- `Get-SyncDefaultReferencePattern` and the `-Pattern`
parameter mean exactly what they did, and still narrow; only *where* the pattern is applied changed.
`--no-merges` stays, now for legibility rather than for correctness: a merge's own subject is `merge:`,
so the anchoring already excludes it.

**The prefilter was deliberately not kept, though it would have been correct.** Every subject is a line of
its own message, so `--grep=$Pattern` is a strict superset and could have narrowed the scan first. It
would also put git's POSIX basic regex and .NET's engine both in the correctness path, for a pattern a
**consumer** supplies through the seam -- and a pattern .NET matches that git's BRE does not would be
filtered out before the subject was ever read, failing as a floor that is silently too recent. Measured at
2,012 commits: the full subject scan costs **94 ms** against the old query's **48 ms**. 46 ms is not worth
a second regex engine deciding whether a consumer loses work.

`scripts/tests/sync-rules.tests.ps1` goes from 46 to **51 asserts**. The new `ref/chatty` fixture is the
case that had no coverage -- one parent, subject `fix:`, a body line opening with `sync` -- and its
regression half passes `--no-merges` explicitly and asserts the old shape *still* picks the body line, so
"necessary and not sufficient" is pinned rather than asserted in prose. The `ref/merged` regression was
**relabelled rather than deleted**: it still passes, but not for the reason its label gave, since the
anchoring is now what excludes the merge.

Three places stated the retired conclusion as settled fact and all three are repaired, because the
docstring is what the next reader would have re-derived it from: both `sync-rules.ps1` docstrings, the
`sync-main.ps1` header note, and the consumer-facing `sync-main` skill page.

**Score:** 3

#### What makes this change extra special

**Both Shopify consumers are running the incomplete version right now, and neither can see it.** That is
the whole weight of this entry. The floor is not something an operator inspects -- it is printed as
`Reference point: <sha> (the previous sync commit)`, which reads as *the rule found its footing* whether
the sha is right or wrong. A too-recent floor does not error, does not warn, and does not slow anything
down; it silently shrinks the set of files the exclusion rule protects, and the run ends green. The
consumer that filed this only found it because it went looking for whether the *previous* fix had worked.

And the trigger is not exotic, which is what makes it worth a 5. It is not a merge commit or an unusual
history shape -- it is **any commit message that mentions a sync in its body**, which in a repo that
*maintains a sync script* is a normal Tuesday. The measured instance is a `fix:` commit whose body reads
`sync-main.tests.ps1 goes from 20 to 32 asserts`: a commit about test counts, deciding which of a live
store's files may be overwritten. Eight commits of merged trunk work fell below the floor that way.

This is the **third** repair to the same pre-task sync queued behind one release decision (#801's flag,
#807's provenance rule, and now the anchoring), and until that release goes out the shipped skill keeps
handing consumers the version measured to lose work. The reporting consumer states its own exposure is
doubled and neither half is bridged: it runs a **local** `sync-main.ps1` of its own that predates the
shipped one, the `team-shopify:sync-main` skill runs the **plugin's** copy, and on that repo's history
both compute the same wrong floor. So reaching for the skill or for the documented local script gives the
same answer, and neither reports anything.

**Score:** 5

### Pull Request

The sync floor is read off the commit SUBJECT, so a body line about sync cannot become the reference point
