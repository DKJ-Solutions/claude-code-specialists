## Development: `fix/the-one-script-carrying-a-byte-order-mark-v1` · 20260829-210156

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

`scripts/tests/internal-note.tests.ps1` is the only one of **162** tracked `.ps1` files in this tree that
carries a UTF-8 byte-order mark. PR #1108 put it there, three commits ago, and both gates were green.

#### Why the gates were green, and why neither is changed here

`Set-Content -Encoding utf8` on Windows PowerShell 5.1 means UTF-8 **with** a BOM -- there is no
BOM-less option on that parameter, which is why every writer in this repo goes through
`Write-Utf8NoBom` or a `UTF8Encoding $false` instead.

**Check 27 does not see it, and that is a decision rather than a hole.** It reads each file with
`[System.Text.Encoding]::UTF8`, which strips the BOM while decoding, and its own comment says why the
exclusion is deliberate:

> A BOM is deliberately NOT a finding here: on a .ps1 it is the one thing that makes 5.1 read the file
> correctly, so flagging it would push authors toward the defect.

That reasoning still holds and **nothing in check 27 is touched**. Check 26 reads bytes but is scoped to
frontmatter-bearing shipped documents, so a test script is outside it -- also correctly.

So this is a **convention** repair, not a correctness one: the file works exactly as well with the BOM as
without. What it is, is the single odd one out in a tree that is otherwise uniformly BOM-less, in a layer
this repo holds to pure ASCII. Left alone, nothing would ever have reported it.

#### No new check, deliberately

The tempting follow-up is a byte-level BOM check over the script set. It is not built here, under this
repo's rule that a risk which has not bitten gets named rather than repaired -- and this one has bitten
exactly once, cosmetically, in a file nothing mirrors. Naming it is the point; if a BOM ever reaches a
**shared** lib, where the mirrors are held byte-identical, that is a different finding with a real cost
behind it.

### CREATE

- [x] The three BOM bytes removed, and nothing else: 43,611 -> 43,608 bytes.

### TEST

- [x] `internal-note.tests.ps1` still runs: 102 asserts pass.
- [x] The lint gate is green.
- [x] Re-measured across the gate's script set: 0 of 162 files carry a BOM, where it was 1 of 162.

### DEPLOY: `fix/the-one-script-carrying-a-byte-order-mark-v1`

`scripts/tests/internal-note.tests.ps1` loses the UTF-8 byte-order mark PR #1108 wrote into it -- the only
one of 162 tracked `.ps1` files in the tree that had one. `Set-Content -Encoding utf8` means *with* a BOM
on Windows PowerShell 5.1, which is why every writer in this repo goes through `Write-Utf8NoBom` instead.

Nothing was broken by it and no gate is changed: check 27 strips the BOM before scanning, deliberately and
with its reason written down, and check 26 is scoped to frontmatter-bearing shipped documents. This is the
odd file out being brought back in line, not a defect being repaired -- which is also why no new check
comes with it.

**Score:** 1

#### What makes this deploy extra special

It is the case where the gate was right to stay quiet and the tree was still wrong. Check 27 excludes a
BOM on purpose, because on a `.ps1` a BOM *helps* 5.1 rather than hurting it -- so the one thing that
could have caught this was correctly designed not to. Worth writing down, because the obvious reaction to
"a defect shipped past the gate" is to widen the gate, and here that would have made it worse.

**Score:** 1

#### Pull Request

The one .ps1 in the tree carrying a byte-order mark loses it
