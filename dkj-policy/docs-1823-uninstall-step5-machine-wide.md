## docs/1823-uninstall-step5-machine-wide

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Mirror #1820's repair onto UNINSTALL.md: a multi-checkout section, a fence at Step 5, the teardown table row, and re-read the 'comes off last' framing plus the clean-machine claim for the skipping reader. One sentence in Sylvester's portable manual for the no-floor half.

#### The decision the issue left open

#1823 filed the repair as a procedural decision rather than a sentence, and named the candidate:
tell a multi-checkout reader to **skip Step 5 entirely** and leave the registration standing. Taken,
on the ground that the alternative — run it, then reinstall in the other checkouts — asks the reader
to break two repos in order to repair them, for no gain over not breaking them. Unlike #1820's fork
(reorder versus state the consequence, which genuinely traded one reader population against another)
there is no second population here: `marketplace remove` is already last, so there is nothing to
reorder, and the reader's own intent was to disconnect one repo.

**Not "strictly worse", which is how the first draft put it** — Marlowe's review was right that this
is a judgement about reader intent rather than a measured fact. A reader deliberately decommissioning
several of their *own* checkouts from one machine gets no credit for that intent under this advice;
they are routed into finishing one at a time and running Step 5 last. The page's *"when Step 5 is
yours"* section is the escape hatch for exactly them, which is why the advice stands as a default
rather than a rule.

What that decision then obliges, and why most of the edits are not the warning itself: the page's
*"the registration comes off last"* framing, its `marketplace list` verification and its clean-machine
section are all written for a reader who finishes at Step 5, and each reads as a failed teardown to
one who correctly stopped at Step 4.

#### The review round — the reason in #1823 did not hold, and the page already said so

Marlowe red-teamed the advice and found the **why** overstated, against a table this very document
carries. #1823 asserts *"nothing reinstalls"* and the first draft built on it. Step 3's own measured
table (rounds v12/v13, inbound #327/#382) says otherwise: a sibling checkout still holds both of its
own adoption keys, because a teardown removes only the keys *its own* repo wrote, and
`extraKnownMarketplaces` is the key that puts the marketplace back. Such a checkout repairs itself in
**two session starts** with no command run — the first re-registers the marketplace and rebuilds the
clone, the second writes a full record.

This is the repo's own rule biting exactly where it was written to bite: a filed report's *reason* is
verified before it is repaired, and this one's was not. The symptom was real and verified; the
explanation was inherited. The advice survives — the cost is one session silently loading nothing, a
clone rebuilt at the marketplace's **current HEAD** rather than at the version that repo was running,
a recovery that is CLI behaviour nobody owns, and nothing at all for a checkout whose owner has since
tidied that key away — but the certainty does not, and the portable manual had shipped the confident
version of it.

Two more from the same round, both real:

- **The query dismissed the one case the page calls untested.** It told the reader a `user`-scope
  record is "not a checkout at all", i.e. noise — while Step 5 says the effect of `marketplace remove`
  on `user`-scope records is unmeasured. It now reads as a reason to hold off.
- **The query can print the reader's own stray record.** Step 2 documents a session start flipping a
  project record to `local`; that leftover prints here too, and the instruction was to go ask its
  owner. It now says to compare paths first.

#### One contradiction found between the two pages, and resolved by measurement

Edith found `UNINSTALL.md` and `INSTALL.md` disagreeing about the same command while citing the same
issue: one says `marketplace remove` takes an optional `--scope`, the other that the flag is on `add`
and not on `remove`. Settled against the CLI rather than by picking a side —
`claude plugin marketplace remove --help` on `2.1.268` documents the flag, so `UNINSTALL.md` was right
and `INSTALL.md`'s reason was false. Its *conclusion* survives, because what the flag governs is which
settings scope the declaration comes out of, and the record reach was measured without it. Corrected in
place, which is this repo's correct-on-edit rule rather than a sweep.

#### What is deliberately NOT measured here

No teardown-specific run on a two-checkout profile, which is what #1823 asked for. Taking it means
uninstalling this family from every other checkout on the machine — the thing being warned about —
and it would re-measure the same command's reach that #1820 already measured with record counts.
So the page carries #1820's numbers under an explicit label saying they are install-side, plus a
sentence saying no teardown measurement was taken and why. Stated rather than quietly reused: this
page's own convention is that a bracket names the profile it was taken on.

### CREATE

- [x] `UNINSTALL.md` — new `## If this machine has more than one checkout` section before Step 5:
      the reach, #1820's record counts labelled install-side, what the teardown case actually costs
      (rewritten in the review round, see below), the no-way-to-report silence, the skip instruction,
      what skipping costs, and the record query that answers whether Step 5 is yours to run
- [x] `UNINSTALL.md` — Step 5's command block carries the fence comment, and its scope-flag sentence
      no longer implies the flag narrows the reach (#1820 lists that as untested)
- [x] `UNINSTALL.md` — the three claims written for a finish-at-Step-5 reader get their second
      reading: Step 4's *"comes off last"* closer, the `marketplace list` verification, and the
      clean-machine section's opening
- [x] `UNINSTALL.md` — the per-file teardown table stops attributing install records to Step 2 alone
- [x] `UNINSTALL.md` — `Before you start` tells the reader to count checkouts first, since it decides
      how long the procedure is
- [x] `05-15-manual.md` (portable) — the teardown half of the mechanism, and after the review round the
      corrected version of it: the reach lands differently rather than being unrecoverable, with the
      three real costs and the standing warning against the confident claim
- [x] Review round applied — `UNINSTALL.md`'s self-heal correction, the query's `user`-scope and
      own-stray-record readings, the teardown table's `{}` qualifier, `de-install` → `uninstall`,
      the phrasing alignment
- [x] `INSTALL.md` — the `--scope`-is-on-`add` claim corrected against the CLI, conclusion kept

### TEST

- [x] Lint gate green (0 errors) and all 91 suites pass in 701s — run before the first commit, and the
      lint re-run after every review-round edit
- [x] `claude plugin marketplace remove --help` read on CLI `2.1.268` to settle the `--scope`
      contradiction, rather than picking whichever page sounded surer
- [x] The printed record query run exactly as written, which is how the retired-marketplace-name false
      negative was found — it returns empty on this machine while six records sit under the old name
- [~] No new automated test — the change is prose in a published document and a portable manual, and
      the lint gate's link scan plus check 12's record-query rule already cover the mechanical layer
      (check 12 did fire on the first draft, and was right)

### DEPLOY: docs/1823-uninstall-step5-machine-wide

`UNINSTALL.md`'s Step 5 ran `claude plugin marketplace remove` with no reader-facing statement that the
command is machine-wide over install records, so a reader tearing down one of several checkouts, exactly
by the book, silently took this family's install records off every other repo on the machine. The page was
thorough about that command and measured a different axis: its per-file table credited Step 5 with the
clone and the `known_marketplaces.json` entry, attributed every install record to Step 2, and every
bracket on the page was taken on a single-adoption profile — where Step 5 provably touches no record,
because Step 2 already took the only one. Such a reader is now told to **skip Step 5** and stop at Step 4,
and the claims written for a reader who finishes there each get their second reading: *"the registration
comes off last"*, the `marketplace list` verification, and the clean-machine section. What skipping costs
is stated so it can be weighed, and the query that answers *"am I the last checkout?"* is given — with the
three ways it misreads, including the false negative found by running it here: a machine registered under
the marketplace's retired name answers nothing to a filter naming the current one.

**The reason #1823 gave for the severity does not hold, and the page now says what does.** That issue
argued the damage has no floor because nothing reinstalls. Step 3's own measured table (inbound
#327/#382) says a sibling checkout repairs itself in two session starts with no command run, because a
teardown removes only the keys its own repo wrote and `extraKnownMarketplaces` is what puts the
marketplace back. The real cost is narrower and worth avoiding anyway: one session that silently loads
nothing, a clone rebuilt at the marketplace's current HEAD rather than the version that repo was running,
a recovery that is CLI behaviour nobody owns, and no recovery at all for a checkout whose owner has since
tidied that key away. `INSTALL.md` also loses a false claim caught alongside this: `--scope` is documented
on `marketplace remove`, verified against the CLI, though it still fences nothing that was measured. The
mechanism lands in Sylvester's portable manual rather than a lens, being a property of the CLI, and it
carries the corrected version plus a standing warning against the confident one.

**Score:** 3

#### What makes this deploy extra special

`UNINSTALL.md` is one of the two procedures a consumer of this marketplace meets, and this is the step
where following it correctly reaches into their other repos. Anyone running the teardown on a machine with
more than one adoption is affected, and it was silent in all three of the places they would look. The
failure being prevented, named because no teardown run has been measured hitting it: a consumer
disconnecting one of several checkouts loses this family's install records from every other repo on the
machine with no signal anywhere — `enabledPlugins` still reads correct and the hooks that would complain
went with the plugin — and gets them back, if at all, from a self-repair nobody commanded, onto whatever
the marketplace's HEAD is by then.

**Score:** 4

#### Pull Request

UNINSTALL.md's Step 5 states its machine-wide reach, and a multi-checkout reader is told to skip it

