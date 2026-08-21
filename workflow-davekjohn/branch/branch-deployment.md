## `fix/sync-reference-point-no-merges` deployment

### What does the change on this branch deploy to main?

`--no-merges` in the `git log` lookup inside `Get-SyncReferencePoint`, and it is a one-flag repair for the
worst failure this script can have: the exclusion rule keeping **nothing** back while printing a reference
point as though all were well. Reported from `xoxowildhearts` as inbound
[#801](https://github.com/DaveKJohn/claude-code-specialists/issues/801) against the 4.17.0 payload.

`--grep` matches any **line** of a commit message rather than the subject, and a sync branch merged with a
merge commit carries the sync commit's own subject in its body. So the merge matches `^[Ss]ync`. Right after
a sync PR lands that merge is `HEAD`, the floor becomes `HEAD`, `Test-MainTouchedSince` answers `$false` for
every path, and every file on live wins -- including every file a merged PR had just changed on the trunk.

**The reason was verified before the repair, and the file predicted its own defect twice.**
`Get-SyncDefaultReferencePattern`'s docstring already says a floor that is too recent "is the direction that
loses work", and `Get-SyncReferencePoint`'s already says that without a floor "the exclusion rule silently
passes everything through -- which is precisely the failure it exists to stop". Both were written about the
pattern and neither covered the merge. The seam cannot close it either: no `--grep` pattern separates a
subject from a body line, and `--no-merges` does. Skipping merges can only move the floor **backward**, onto
the sync commit the merge brought in, which is the protective direction.

The suite pins **both halves** -- that the shipped lookup finds the sync commit, and that the same lookup
*without* the flag genuinely picks the merge -- so `--no-merges` cannot be tidied away later as a style
choice. The consumer's own report asked for that second assert and it earns its place.

Two smaller things came off the same report. The `--` pitfall note now sits beside `Invoke-SyncGitQuiet`
itself rather than only at the one caller that had learned it: a bare `--` typed inline never reaches git,
and for a path the trunk has **deleted** the resulting error goes to the stderr this wrapper swallows by
design -- a silent `$null` and the losing answer.

**Two of the report's four items are deliberately not built, both with their measurement.** Its
`> $tmp` byte-mangling trap does not apply here -- these scripts never redirect blob content, and
`sync-main.ps1` contains no `cat-file` and no redirect to a temp file at all, so there was nothing to
repair. And its section 2 replaces the time-window measurement wholesale with a content-history rule, moves
the live pull into a mirror outside the repo, and forbids deletion. That is a redesign of the sync policy,
not a defect repair, and it goes to Dave as a proposal rather than riding in on a one-flag fix. The floor
repair here is what makes waiting on that decision safe.

**Score:** 4

#### What makes this change extra special

For a consumer running `sync-main.ps1` from 4.17.0, this is the difference between a sync that protects
merged work and one that quietly reverts it, and the failure was measured rather than reasoned about. In
`xoxowildhearts` on 2026-08-21 the next sync was about to delete 21 lines from `locales/de.json` and 20 from
`locales/nl.json` -- the twelve translation keys a PR had merged the previous day -- revert two `| raw`
removals in `snippets/switch-module.liquid`, and resurrect 23 locale files a commit had deliberately
dropped. Thirty-one files, three merged PRs, and a green run.

**The second Shopify consumer is exposed and not yet bitten, which is the part worth reading.** In
`smartwatchbanden` the newest matching commit is the same with and without the flag, because that sync
landed as a squash rather than a merge commit -- so nothing is wrong there today, and the first sync PR that
lands as a real merge poisons its floor. It has `Get-ShopifySyncMerges = $true`, which is the path that
produces exactly that merge. Update before the next sync rather than after it.

The transferable lesson sits one level up from Shopify: **a guard whose failure mode is a green run has to
be tested from the failing side too.** This one had a suite, six asserts on the reference point, and a
docstring naming the losing direction -- and it shipped with a hole, because every case asked what the
lookup finds and none asked what it must not find.

**Score:** 5

### Pull Request

the sync floor no longer lands on a merge commit
