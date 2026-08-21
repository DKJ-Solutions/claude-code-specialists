# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections answering what a reader arrives with — what the change deploys to `main`, and the PR.
The first holds the change's two audiences, the second of them under `#### What makes this change extra
special`; the tier numbers live in the parser rather than in any heading. Entries written before
August 16, 2026 carry the longer set of headings that shape replaced, and every earlier shape is read
exactly as it always was. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier, each closing with its score. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## `feat/register-xoxowildhearts-workflow-slot` deployment

### What does the change on this branch deploy to main?

The workflow slot in `connectors/xoxowildhearts.json`, which that manifest deliberately left blank on
2026-08-20 -- inbound [#800](https://github.com/DaveKJohn/claude-code-specialists/issues/800), and the
follow-up the manifest's own note asked for rather than a defect report. The deferral was right and the
answer it predicted was the losing one: `feat-harness-hardening` merged as PR #7, `ad315a1` did switch the
slot to `workflow-default`, and the same day the consumer reversed it -- `463e091` adopts
`workflow-davekjohn`, `01a2723` disables `workflow-default` so exactly one workflow holds the slot. All
four commits were read in the consumer's own history rather than taken from the report, and
`extensions: []` is the measured answer: the plugin ships no `agents/` directory.

**The condition the deferral set is now measured wider than the report could.** It said to write the block
once the branch had merged, because a state about to move records an `[ERROR]` half the time. Rather than
check `main` alone, all **16** of the consumer's remote branches were read: every one carries
`workflow-davekjohn: true`, so nothing in flight moves the slot back. `check-connectors.ps1` now reports
four plugins `[OK]` for this consumer where it reported three.

**Why registering it is the repair and not a formality.** `check-connectors.ps1` loops over the plugins a
manifest *lists*, so an enabled plugin absent from that array is invisible to the version check -- and the
report walked into it: a session-start `[ERROR]` named three drifted plugins where four had drifted, and
the one it could not name was `workflow-davekjohn`, the plugin that ships `connector-sessioncheck` itself.
**Measured across all five connectors, this was the only enabled-but-unregistered plugin anywhere**, so
registering it empties the class. The asymmetry is named and not repaired: the analogous case one level
down -- a lens present but unregistered -- already prints an `[INVENTORY]` line, and the plugin level has
none. A risk whose population is now zero gets written down, not built.

**And the recount found more than the issue asked about, which is the half worth reading.** #800 asked for
one block. Verifying the manifest around it showed that **all three** "differences" it records for this
consumer had become false, each overtaken by the very branch the slot note named as in-flight:

| the manifest said | measured 2026-08-21 |
|---|---|
| no `CHANGELOG.md` at all, a flat `update_log.txt` | `CHANGELOG.md`, 15 `##` sections, the workflow's own intro (`8541994`) |
| has not adopted `workflow-davekjohn/` | present and fully scaffolded -- `branch/`, `prompts/`, `releases/`, three docs |
| lint gate at `--fail-level crash`, 1504 pre-existing offences | `--fail-level error` since `ad315a1`, green on five consecutive runs |

They are corrected in the same change, because a register whose whole purpose is to record what a consumer
**has** cannot carry three claims it no longer has while a fourth accurate one is added beside them. One of
the three also carried a wrong reading of inbound #763 -- it recorded that the missing-folder `[ERROR]` had
been answered by disabling the hook's own plugin, and the consumer did the opposite and adopted the folder.

**Score:** 3

#### What makes this change extra special

Nothing here travels to a consumer -- the register lives in the source and only this repo can write to it,
which is why the issue placed no bridging note anywhere. What travels is the shape of the mistake, and it
is the one the workflow's own folder page already warns about in a different document: **a stale line
copied forward becomes a false line.** Every one of those three claims was true when written. Each was
measured against `main` on a day when a named, in-flight branch was about to change the answer -- the same
branch the slot note was deliberately waiting on -- and none was re-read when it merged. So the note that
correctly deferred the one field it knew would move sat directly above three fields that moved for exactly
the same reason.

The transferable rule is narrower than "re-verify everything": **when you defer one field because a branch
is in flight, the other fields that branch touches are deferred too, whether or not you wrote them down.**
Waiting on a branch and then reading only the field you were waiting on is how a record ends up
three-quarters wrong while its one careful sentence looks like diligence.

**Score:** 2

### Pull Request · 20260821-130211

the register records xoxowildhearts' workflow slot

[PR #804](https://github.com/DaveKJohn/claude-code-specialists/pull/804)

---

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

### Pull Request · 20260821-123711

the sync floor no longer lands on a merge commit

Plugins: team-shopify

[PR #803](https://github.com/DaveKJohn/claude-code-specialists/pull/803)

---

## `docs/v4-17-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.17.0 release
document froze at a subtotal of **11m 12s** because three of its legs were still running on the file it was
written into -- its local gates, its CI and merge, and the publish. Those legs now have clock readings, so the
total goes in: **32m 19s** end to end, with the local gates and push **4m 03s**, CI and the merge **15m 22s**,
and the fold plus publish **40s**. There was no requester gap to separate out this time; the run was
continuous, so wall clock and working time are the same number.

**The reading worth the branch is which check governed the wait.** `lint-en-tests` is the only required check
on `main` and it passed in **9m 29s**. `claude-review` is not required and took **15m 09s**, and `ship-pr`
waits for every check rather than for the required one -- so the merge landed 15m 22s after the pull request
opened, and that single leg is **48%** of the release. Both figures were read from `gh pr checks` and the
ruleset rather than inferred from the wall clock.

**It is named and not repaired**, under the rule that a risk which has not bitten gets written down rather
than fixed. One measurement is not evidence for changing what the merge path waits on, and the same wait is
what a reviewer would want if the review were the point. It is recorded in the release document's open
section so the next release has something to compare against.

Two readings the first pass could not produce. The head came to **18%** of the total, the lowest of the six
releases timed so far (`v4.15.0` 21%, `v4.12.0` 24%, `v4.16.0` 26%, `v4.13.0` 30%, `v4.14.0` 32%) -- and the
reason is stated rather than left to read as an improvement: the head did not get faster, the tail got longer.
And the frozen subtotal was 65% short of the total, in line with 66% at `v4.4.0` and 70% at `v4.16.0`.

**Score:** 2

#### What makes this change extra special

It puts a third consecutive end-to-end measurement beside the first two, and this one complicates the
fixed-cost claim in a useful direction rather than confirming it: **24m 34s** for v4.15.0's thirteen entries,
**25m 29s** for v4.16.0's four, **32m 19s** for v4.17.0's nine. The spread still does not track the entry
count, which is the claim -- but the longest of the three is longest for a reason that has nothing to do with
its contents, and a reader who saw only the three totals would draw the wrong conclusion about batching.

For a consumer running this workflow, the transferable part is the diagnostic rather than the number: when a
release feels slow, check which check is governing the merge wait before assuming the work grew. The required
gate and the slowest gate are not necessarily the same one, and only the first is the one anybody chose.

**Score:** 2

### Pull Request · 20260820-200637

The v4.17.0 release note gains its end-to-end total

[PR #799](https://github.com/DaveKJohn/claude-code-specialists/pull/799)

---

## `docs/v4-17-0-release-note` deployment

### What does the change on this branch deploy to main?

The hand-written release document for v4.17.0. The cut drafts it from the tier-2 entries in the words their
authors wrote for a diff reviewer and commits it inside the tagged release commit; this is the rewrite for
somebody deciding whether to update, held against the seven tests in the `cut-release` skill.

All nine of this release's entries reach tier 2, which is the largest set this document has had to order.
Five of them carry an action, so those five open the page -- the `team-shopify` pre-task sync first, since it
is the only item where the thing being replaced has already destroyed work in both repos that hand-wrote it.
The four that carry none say **no action needed** in as many words rather than leaving it to be inferred, and
the theme-delete marker gets the same treatment despite being a new capability, because doing nothing is a
complete answer to it.

Every mechanism the page instructs a reader to invoke was read in the tree before it was written down, not
carried over from the entry bodies: `adopt-shopify-floor`'s `-StoreDomain` and `-LiveThemeId`, `sync-main`'s
six seams and which two of them refuse to guess, `adopt-workflow-folder` as the placer of
`.github/workflows/branch-entry.yml`, and `Get-EntryGateExemptPrefixes` defaulting to `sync`. That check is
the reason the sync section names two required seams rather than the one the entry emphasises.

Both organisation sections are written. *What it is worth* leads on the distinction between the guard this
family shipped in v4.15.0 and the sync it ships now -- one prevents a bad act, the other prevents a good act
from silently reverting finished work -- and on the two-consumers-derived-the-same-artefact pattern appearing
for the second release running, this time with both consumers making the same mistake. *What was still open*
is a snapshot, with every figure read at its source: the organisation's publication target at `84e6316` with
all four team plugins at 4.16.0, and the registered consumer three releases behind, read from the session
check rather than from a document.

**Step 0a's baseline was taken before starting this time**, which the v4.16.0 record notes was missed, so this
page's timing legs are clock readings rather than reconstructions from file timestamps.

**Score:** 2

#### What makes this change extra special

It is the one document a consumer reads to decide whether to update, and it reaches every one of them as an
attachment on this release's GitHub Release.

The item that earns the top of the page is the one where the cost of doing nothing is invisible until it has
already happened. A `team-shopify` consumer who keeps their own sync keeps an implementation whose first
version destroyed work in both repos that wrote one, over a failure -- a deletion is also a touch -- that
produces no error and no warning, only quietly reverted files. The page gives them the command, names the two
seams the script refuses to guess, and states what it never does, so converging onto it does not read as
handing a script the authority to push.

The page also carries the correction the previous release could not: v4.16.0's Release was published one step
early and its attachment was the generated draft. This one follows the checklist's order, so what a reader
downloads is this document rather than the entry bodies.

**Score:** 3

### Pull Request · 20260820-194607

The v4.17.0 release note

[PR #798](https://github.com/DaveKJohn/claude-code-specialists/pull/798)

---

