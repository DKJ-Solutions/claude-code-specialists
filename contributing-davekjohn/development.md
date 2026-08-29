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
annotation this repo emits can reach 597 while its own relay cuts at 500, and the half it cuts is the
tail of the reason: the only part naming which limit was hit and when it returns.

#### The measurement the issue left open, now taken

The issue asked its picker to sample real runs rather than reason from the one it had. Sampled all 54
red `claude-code-review` runs available on August 29, 2026 (August 27-29), which carry **45 titled
failure annotations**. Every one is a 429, and upstream's `result` first line is one of four strings:

| reason (upstream `result`, first line) | length | n |
|---|---|---|
| `You've hit your weekly limit - resets Aug 31, 7am (UTC)` | 54 | 33 |
| `You've hit your session limit - resets 11:20am (UTC)` | 51 | 4 |
| `You've hit your session limit - resets 12:20pm (UTC)` | 51 | 1 |
| `You've hit your session limit - resets 5:10pm (UTC)` | 50 | 7 |

So the reason has never exceeded **54** characters against a 300 cap, and the longest composed message
observed is **341**. The mismatch is real and latent, exactly as filed -- it needs a reason of 204
characters before it bites, roughly four times anything measured.

#### And the number justifying the 500 is wrong

`Get-AuthoredFailureNote`'s comment cites run `33267175141` as a **460**-character note, twice. Read
back through the function itself, that run's note is **400** -- title 55, separator 4, message 341.
The bound is right; the measurement defending it is off by 60, and #1116 repeats it.

#### The repair, and why not one of the issue's three

The issue offered three answers and called none obviously right. A fourth dissolves the trilemma: the
workflow already knows its own headline, so it can budget the reason against the bound the relay
states rather than against a number chosen independently of it. That keeps the reason whole instead of
choosing which half to lose, and it is the specific party accommodating the generic one rather than
the reverse. It costs one mirrored constant, and a test stands over it so the mirror cannot drift
silently -- which is the defect #1116 actually reports.

`claude-code-review.yml` is this repo's own CI and not plugin payload (stated in the 4.20.0 and 4.23.0
entries), so the coupling is local-to-local and reaches no consumer.

### CREATE

- [x] `claude-code-review.yml` budgets the reason against the relay's bound instead of a flat 300:
      read the status, choose the headline, then trim the reason to `cap - len(headline) - 1` in
      bash -- not in jq, which this step only exercises on a red run and swallows via continue-on-error
- [x] Guard a negative budget -- a negative length in a bash substring is not an error, it counts
      from the end, so an over-long headline would silently mangle the reason rather than fail
- [x] `pr-issues-lib.ps1`: correct the 460 to the measured 400 in both places, and record that this
      repo's own workflow now budgets against the bound
- [x] Regenerate the plugin mirror via `scripts/sync/build-shared-scripts.ps1`

### TEST

- [x] `pr-issues.tests.ps1` pins the two numbers to each other: the cap the workflow budgets against
      equals the cap the relay enforces
- [x] and that every headline the workflow can choose leaves room for the longest reason measured (54)
- [x] the full suite green through the lint + test gate

### DEPLOY: `fix/the-annotation-fits-the-relay-that-carries-it-v1`

A red `claude-review` can no longer lose the half of its own explanation that says **when the quota
comes back**. Two caps bounded the same sentence and each was chosen without seeing the other: the
workflow capped the reason it appends at 300, `Get-AuthoredFailureNote` caps the whole message it
relays at 500, and `headline + ' ' + reason` reaches 597. The relay is generic and cannot tell where
the headline stops, so the part it would cut is always the tail -- *"resets Aug 31, 7am (UTC)"*, the
only actionable word in the note. The workflow now computes its reason's bound **from** the relay's,
so what it emits is never something its own relay has to trim, and a test fails the day either
number moves without the other.

**The failure it prevents has not happened yet, which is worth naming rather than glossing.**
[#1116](https://github.com/DaveKJohn/claude-code-specialists/issues/1116) told whoever picked it up
to sample real runs rather than reason from the one it had, so that is what this branch did first:
all 54 red runs available, **45 titled failure annotations** across August 27-29, 2026. Every one a
429; upstream's `result` first line ran **50 to 54** characters against its 300-character cap; the
longest message actually emitted was **341**. It takes a reason of 204 characters before a reader
loses a word -- roughly four times anything measured. The mismatch is real, latent, and now closed
by construction instead of by headroom nobody owned.

**And the number defending the bound was wrong.** The comment justifying the 500 cited run
`33267175141` as a **460**-character note, twice, and #1116 repeated it. Put back through the
function, that note is **400** -- a 55-character title, a 4-character separator, a 341-character
message. The bound was never in question; its evidence was, by 60.

**Score:** 2

#### What makes this deploy extra special

For a repo consuming this workflow the change is in the comment, not in the behaviour:
`Get-AuthoredFailureNote` still cuts at 500 and still relays whatever an author wrote. What it now
states is the rule the repair followed, which transfers to any workflow a consumer writes against
it -- **the party that can see both halves is the one that budgets.** A workflow knows where its own
headline stops and upstream's text starts; the relay cannot, and raising a generic bound to fit one
verbose author spends that room in every repo downstream. So the specific party accommodates the
generic one, and the corrected 400 sits beside it as what that bound was actually measured against.

**Score:** 1

#### Pull Request

