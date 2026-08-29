## Development: `fix/the-annotation-fits-the-relay-that-carries-it-v1` · 20260829-220627

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
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

Issue [#1116](https://github.com/DaveKJohn/claude-code-specialists/issues/1116): two caps bound the
same string and neither owner can see the other's number. `claude-code-review.yml` caps the **reason**
it appends at 300; `Get-AuthoredFailureNote` caps the **whole message** it relays at 500. The workflow
writes `headline + ' ' + reason`, and the 429 headline is 296 characters since #1115 -- so the
annotation can reach 597 while the relay cuts at 500, and the half it cuts is the tail of the reason:
where *"resets Aug 31, 7am (UTC)"* lives.

The issue offered three answers, called none obviously right, and told whoever picked it up to
**sample real runs rather than reason from the one it had**. That is what this branch did first, and
the sampling is what decided the outcome.

#### The measurement

All 54 red `claude-code-review` runs available on August 29, 2026 (August 27-29), carrying **45 titled
failure annotations**. Every one is a 429, and upstream's `result` first line is one of four strings:

| reason (upstream `result`, first line) | length | n |
|---|---|---|
| `You've hit your weekly limit · resets Aug 31, 7am (UTC)` | 55 | 33 |
| `You've hit your session limit · resets 11:20am (UTC)` | 52 | 4 |
| `You've hit your session limit · resets 12:20pm (UTC)` | 52 | 1 |
| `You've hit your session limit · resets 5:10pm (UTC)` | 51 | 7 |

The separator is a middot (U+00B7) and that is the source, read back from the annotation payload of
run `33267175141` as bytes. The captured fixture in `pr-issues.tests.ps1` writes it as a hyphen because
a `.ps1` in this repo is pure ASCII -- so the fixture is the copy that differs, not the table. Both are
one character wide, so the lengths hold either way.

The reason has never exceeded **55** characters against a 300 cap, and the longest composed message is
**341**. A reason must reach 204 characters -- nearly four times the longest ever seen -- before a
reader loses a word. The mismatch is real and latent, exactly as filed.

#### And then the arithmetic said the obvious repair is a net loss

Candidate 2 (lower the workflow's 300 so the sum fits) was **built, measured and withdrawn**. The
console shows `500 - 296 - 1 = 203` characters of reason whichever end owns the cut, so:

| reason length | today: annotation / console | capped at 203: annotation / console |
|---|---|---|
| 55 | 55 / 55 | 55 / 55 |
| 250 | 250 / 203 + `...` | 203 / 203 |
| 400 | 300 / 203 + `...` | 203 / 203 |

It hands the console reader the **same 203 characters**, drops the `...` that honestly marks the loss,
and costs the GitHub annotation -- read in the checks UI, where no 500-character bound applies -- up to
97 characters it currently keeps. Candidate 3 (cut from the front in the relay) is the only one that
would give the console *more*, and it is not free either: the relay carries workflows it has never
seen, and for one whose message is all content and no preamble the front is the part worth keeping.

So the answer is **candidate 1, now on evidence rather than on a shrug**: leave the two bounds, write
down the arithmetic where each is set, and give the coupling the thing it actually lacked -- an owner.

#### Separately, the number defending the 500 is wrong

`Get-AuthoredFailureNote`'s comment cites run `33267175141` as a **460**-character note, twice, and
#1116 repeats it. Read back through the function itself, that note is **400**: a 55-character title,
the 4-character separator and a 341-character message. The bound was never in question; its evidence
was, by 60.

### CREATE

- [x] `claude-code-review.yml`: record beside the 300 what it overlaps with, what lowering it would
      cost, and the sampled traffic that makes the case hypothetical -- no behaviour change
- [x] `pr-issues-lib.ps1`: correct the 460 to the measured 400 in both places, and record the same
      arithmetic beside the 500 from the relay's side
- [x] Regenerate the plugin mirror via `scripts/sync/build-shared-scripts.ps1`
- [~] Change either cap -- dropped: built as a flat 203 budget in the workflow, then withdrawn when
      the arithmetic above showed it costs the annotation up to 97 characters and buys the console none

### TEST

- [x] `pr-issues.tests.ps1` pins all three numbers the arithmetic rests on -- the relay's 500, the
      workflow's 300, and every literal headline's length -- so none can move without a red test
      naming the reasoning to read
- [x] mutation-tested: raising the reason cap, lengthening a headline by 250, and lowering the relay
      cap each go red, and each names the right one
- [x] the full suite green through the lint + test gate

### DEPLOY: `fix/the-annotation-fits-the-relay-that-carries-it-v1`

The two caps that bound a red `claude-review`'s explanation -- the workflow's 300 on the reason it
appends, `Get-AuthoredFailureNote`'s 500 on the whole message it relays -- now carry the arithmetic
that relates them, and a test that fails the day either one moves. Neither number changed, and
that is the finding rather than a shortfall: the annotation can reach 597 against a 500-character
relay, but `500 - 296 - 1 = 203` is what the operator's console shows **whichever end owns the cut**,
so lowering the workflow's cap to make the sum fit hands that reader the same 203 characters, drops
the `...` that marks the loss, and costs the GitHub annotation up to 97 characters no bound applies
to. It was built that way and withdrawn on the arithmetic.

**The measurement #1116 asked for, taken first and decisive:** all 54 red runs available on
August 29, 2026, carrying **45 titled failure annotations** across August 27-29. Every one a 429, and
upstream's `result` first line ran **51 to 55** characters against 203 of room, with the longest
message actually emitted at **341**. A reason must reach 204 characters -- nearly four times the
longest ever seen -- before a reader loses a word.

**What was actually broken is now fixed**: the comment defending the 500 cited run `33267175141` as a
**460**-character note, twice. Put back through the function, that note is **400** -- a 55-character
title, a 4-character separator, a 341-character message.

**Score:** 2

#### What makes this deploy extra special

**An overlap between two bounds is not automatically a defect, and the change that removes the overlap
is not automatically the fix.** That is the whole of what travels, and it is a shape rather than a
number: before tightening one of two caps that bound the same string, work out what the reader on the
far end actually sees in each case. Here the tighter cap delivered that reader the identical text,
took away the ellipsis telling them something had been dropped, and spent a second reader's margin to
do it -- so the overlap stayed and the reasoning was written down beside both numbers instead.

**The second half: a bound is only as good as the measurement cited for it.** The comment defending
this one named a specific run, and naming it is what let somebody eventually check it and find the
figure wrong by 60. Cite the run.

**Score:** 1

#### Pull Request


The annotation's two caps get an owner, not a tighter number
