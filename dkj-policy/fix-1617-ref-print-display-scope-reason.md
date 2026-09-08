## fix/1617-ref-print-display-scope-reason

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

#### What #1617 reported, and what re-measuring it found

`ref-print-lib.ps1` (from #1594) scopes itself out of the display axis with the sentence *"git already
rejects the control characters that would make prose deceptive."* The report says that is false for
`\p{Cf}`. Verified here before anything was changed, per the repo's verify-the-reason rule:

| ref | `git check-ref-format --branch` |
|---|---|
| `fix/a<U+202E>b` RIGHT-TO-LEFT OVERRIDE | 0 |
| `fix/a<U+200D>b` ZERO WIDTH JOINER | 0 |
| `fix/a<U+200B>b` ZERO WIDTH SPACE | 0 |
| `fix/a<U+2066>b` LEFT-TO-RIGHT ISOLATE | 0 |
| `fix/a<BEL>b`, `fix/a<ESC>b` | 128 |

**The report is right and understates the reach twice.** It names two code points; the class is every
`\p{Cf}`, and U+200B and U+2066 pass as well. And it reports two claim sites in the lib; there are
**four**, plus a fifth in the suite:

1. `.DESCRIPTION` opening -- *"which is why the ANSI/OSC-repaint class ... is already closed for a ref name"*.
2. `.DESCRIPTION` scope note -- the sentence the issue quotes.
3. `Get-PasteableRef`'s docstring -- *"as prose, where git's own rejection of control and whitespace characters means it cannot repaint a terminal"*, which credits git for a safety the strip two lines below actually provides.
4. The strip's own implementation comment -- *"For a name that came from `git rev-parse` this is belt-and-braces -- git rejects those characters in a ref"*. It is **load-bearing** there, not belt-and-braces.
5. `ref-print-lib.tests.ps1` grouped `fix/a<U+202E>b` under a header reading *"Whitespace and control characters -- refused here too, independently of git"*, marked `NOT REACHABLE THROUGH A REF`. The same wrong claim, in the file that exists to measure the premises.

Reachability confirmed end to end in a throwaway repo: `git branch`, `git checkout` and
`git rev-parse --abbrev-ref HEAD` all accept and return `fix/a<U+202E>b` verbatim -- and `rev-parse` is
the exact source `ship-pr.ps1` reads `$branch` from.

#### Scope: the reasoning, not the prose sites

#1594's own subject stays closed -- `Test-RefPasteSafe`'s allowlist refuses all four code points, so no
guarded command is affected, and every one of the seven paste sites still names the token. What this
branch repairs is the **reason**, which is what the issue asked for; it explicitly left the decision
about the display sites to whoever picked it up. That decision is *not here*: it is a different subject
(sanitising ~10 prose interpolations across `ship-pr.ps1`, `sync-main.ps1` and
`remote-ahead-lib.ps1`'s `$BranchLabel`), it carries its own risk, and one-subject-per-issue applies.
Filed separately with this branch's measurement already in hand.

### CREATE

- [x] `scripts/lib/ref-print-lib.ps1`: correct all four claims -- name `\p{Cc}` vs `\p{Cf}` exactly, state the measurement, cite #1446 for the two code points that already bypassed the neighbouring sanitiser, and say plainly that the display axis is left open knowingly rather than closed by git
- [x] Same file: the strip in `Get-PasteableRef` re-described as load-bearing on both inputs, not belt-and-braces on a `rev-parse` name
- [x] Mirror to `plugins/dkj-policy/scripts/lib/` and `plugins/dkj-teams/dkj-team-shopify/scripts/lib/` -- byte-identical, per the shared-scripts drift lint

### TEST

- [x] `scripts/tests/ref-print-lib.tests.ps1`: move the format characters out of the git-rejects group into a reachable block of their own, with `git ACCEPTS ...` asserted as the premise the same way the shell-metacharacter cases assert theirs -- so if a future git tightens its rules, the assert goes red and the lib's scope note gets re-read
- [x] Add U+200B and U+2066 alongside U+202E and U+200D, since the class is wider than the report measured
- [x] Pin the correction itself: the lib cites #1617, and the retired sentence must not come back
- [x] Suite green: 261 pass, 0 fail
- [x] Full gate: `check-plugin-integrity.ps1` + every suite

### DEPLOY: fix/1617-ref-print-display-scope-reason

`ref-print-lib.ps1` said git already closes the deceptive-character class for a ref name. It does not:
`git check-ref-format` enforces `\p{Cc}` and accepts `\p{Cf}`, so U+202E, U+200D, U+200B and U+2066 are
all legal in a branch name -- creatable, checkout-able, and returned verbatim by `git rev-parse`. Those
first two are the exact code points #1446 was filed for. The guard itself was always right; only the
sentence explaining it was wrong, and a reader who is told a class is closed cannot weigh a gap they
have been told does not exist. All four claim sites now name the two Unicode classes exactly, carry the
measurement, and say the display axis is left open knowingly. The suite moves the format characters
into its reachable half, where git's acceptance is asserted as a premise rather than assumed away.

**Score:** 3

#### What makes this deploy extra special

N/A. Nothing a subscriber can observe changes -- no guard loosens or tightens, no printed line differs,
and the four code points were refused on the paste axis before this branch and are refused after it.
The correction is to the reasoning a maintainer reads in the lib and its suite.

**Score:** N/A

#### Pull Request

Correct ref-print-lib's display-scope reasoning: git accepts format characters in a ref

