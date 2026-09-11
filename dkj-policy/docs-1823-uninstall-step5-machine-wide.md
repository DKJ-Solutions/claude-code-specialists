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
because the alternative is strictly worse: running the step and then reinstalling in the other
checkouts asks the reader to break two repos in order to repair them, for no gain over not breaking
them. Unlike #1820's fork — reorder versus state the consequence, which genuinely traded one reader
population against another — there is no second population here: `marketplace remove` is already last,
so there is nothing to reorder, and the reader's own intent was to disconnect one repo.

What that decision then obliges, and why three of the four edits are not the warning itself: the
page's *"the registration comes off last"* framing, its `marketplace list` verification and its
clean-machine section are all written for a reader who finishes at Step 5, and each reads as a failed
teardown to one who correctly stopped at Step 4.

#### What is deliberately NOT measured here

No teardown-specific run on a two-checkout profile, which is what #1823 asked for. Taking it means
de-installing this family from every other checkout on the machine — the thing being warned about —
and it would re-measure the same command's reach that #1820 already measured with record counts.
So the page carries #1820's numbers under an explicit label saying they are install-side, plus a
sentence saying no teardown measurement was taken and why. Stated rather than quietly reused: this
page's own convention is that a bracket names the profile it was taken on.

### CREATE

- [x] `UNINSTALL.md` — new `## If this machine has more than one checkout` section before Step 5:
      the reach, #1820's record counts labelled install-side, the no-floor difference, the
      no-way-to-report silence, the skip instruction, what skipping costs, and the record query that
      answers whether Step 5 is yours to run
- [x] `UNINSTALL.md` — Step 5's command block carries the fence comment, and its scope-flag sentence
      no longer implies the flag narrows the reach (#1820 lists that as untested)
- [x] `UNINSTALL.md` — the three claims written for a finish-at-Step-5 reader get their second
      reading: Step 4's *"comes off last"* closer, the `marketplace list` verification, and the
      clean-machine section's opening
- [x] `UNINSTALL.md` — the per-file teardown table stops attributing install records to Step 2 alone
- [x] `UNINSTALL.md` — `Before you start` tells the reader to count checkouts first, since it decides
      how long the procedure is
- [x] `05-15-manual.md` (portable) — the teardown half of the mechanism: no `add` behind it, so the
      reach has no floor, and a teardown page must say *skip* rather than merely warn

### TEST

- [x] Lint gate + all suites green (`open-pr.ps1` runs both; no script changed on this branch)
- [~] No new automated test — the change is prose in a published document and a portable manual, and
      the dead-link scan in `check-plugin-integrity.ps1` already covers the five new anchors

### DEPLOY: docs/1823-uninstall-step5-machine-wide

`UNINSTALL.md`'s Step 5 ran `claude plugin marketplace remove` with no reader-facing statement that the
command is machine-wide over install records. On a machine with more than one checkout, a reader tearing
down one repo exactly by the book silently de-installed this family from every other repo on it — and
`INSTALL.md`'s migration has a floor that this page does not: there the remaining checkouts reinstall,
here nothing does, and a repo loading no plugin cannot report it (the hooks are in the plugin, `git
status` is clean, `enabledPlugins` still reads correct). The page was thorough about this command and
measured a different axis: its per-file table credited Step 5 with the clone and the
`known_marketplaces.json` entry, attributed every install record to Step 2, and every bracket on the page
was taken on a single-adoption profile, where Step 5 provably touches no record because Step 2 already
took the only one. Such a reader is now told to skip Step 5 and stop at Step 4, and the three claims
written for a reader who finishes there — *"the registration comes off last"*, the `marketplace list`
verification, and the clean-machine section — each say so. The scope flag no longer reads as a fence,
since whether it narrows the reach is untested. The teardown half of the mechanism lands in Sylvester's
portable manual rather than a lens: it is a property of the CLI, so it travels to every consumer.

**Score:** 3

#### What makes this deploy extra special

`UNINSTALL.md` is one of the two procedures a consumer of this marketplace meets, and this is the step
where following it correctly broke their other repos. Anyone running the teardown on a machine with more
than one adoption is affected, and the damage was silent in all three of the places they would look. The
failure being prevented, named because no teardown run has been measured hitting it: a consumer
disconnecting one of several checkouts loses this family from every other repo on the machine, with no
signal anywhere — their `enabledPlugins` still reads correct and the hooks that would complain went with
the plugin.

**Score:** 4

#### Pull Request

UNINSTALL.md's Step 5 states its machine-wide reach, and a multi-checkout reader is told to skip it

