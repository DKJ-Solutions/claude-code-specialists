## fix/1446-tip-utf8-decode

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

new-branch.ps1 reads the remote tip subject through Invoke-NativeCapture WITHOUT -Utf8, so on a non-UTF-8 console git's UTF-8 bytes are decoded with the console code page and U+202E/U+200D arrive as ordinary printable characters -- which the control/format strip then leaves alone. Pass -Utf8, and make the suite's premise assert read the same way.

### CREATE

- [x] `scripts/task/new-branch.ps1`: the remote-tip read passes `-Utf8` to `Invoke-NativeCapture`, with the
      reason stated at the call site -- the strip below it is what makes the flag load-bearing rather than
      cosmetic
- [x] `scripts/tests/new-branch.tests.ps1`: the premise assert reads the commit subject back through
      `Invoke-NativeCapture -Utf8` instead of `& git`, so it can no longer be defeated by the console it
      runs on; `native-capture-lib.ps1` is dot-sourced into the suite's own scope for it
- [x] A third premise assert added for the zero-width joiner -- two of the three stripped characters were
      asserted on the way in, and the third was only asserted on the way out
- [x] The plugin mirror regenerated
- [~] The other unflagged `Invoke-NativeCapture` reads are NOT changed. Swept and each one answered: the
      SHAs, counts and `gh` logins are ASCII by construction, and `fold-changelog-entry.ps1`'s two
      `git show` reads feed a remote-vs-local comparison where a shared mis-decode is symmetric and
      cancels. One genuine instance existed and it is the one repaired here

### TEST

`new-branch.tests.ps1` standalone: **255/255 pass**, where the same suite was **3 red** on `main` at
`40d3755a` and at `ca68788b` -- reproduced in a clean detached worktree with no local changes, so the red
was the tree's and not the branch's.

The three that flipped are the point, and two of them were reporting a real bypass rather than a test
artefact: `nor an RTL override` and `nor a zero-width joiner` assert that the payload does **not** reach
the output, and they were failing. They pass now because the sanitiser finally sees a format character
where it previously saw three ordinary printable ones.

`check-plugin-integrity.ps1`: **0 errors**. The full gate runs as `open-pr`'s own, at `-MaxParallel 4` --
which is [#1443](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1443)'s knob, on the
branch that has to go second because this one unblocks the gate for it.

### DEPLOY: fix/1446-tip-utf8-decode

`new-branch.ps1` reads the remote tip's subject with **`-Utf8`**, so the control-and-format strip added in
[#1439](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1439) sees the characters it exists
to remove. Until now it did not, on any Windows console whose code page is not UTF-8 -- which is the
default.

**The guard was green in the one environment that did not need it.** Windows PowerShell 5.1 decodes a
native child's stdout with `[Console]::OutputEncoding`. On a cp850 console the three UTF-8 bytes of an RTL
override (`e2 80 ae`) arrive as the three ordinary printable characters cp850 maps them to -- and
`\p{Cf}` does not match an ordinary printable character, so nothing was stripped. Encoding those same three
characters back out is byte-identical, so the payload was reconstituted intact the moment anything
downstream decoded as UTF-8. The ESC half of the guard always worked, because `0x1B` is ASCII and every
candidate code page agrees below `0x80` -- which is exactly the property
[`language-layers.md`](../.claude/rules/language-layers.md) already names as the reason to hold the wire to
ASCII and decode it yourself.

**The mechanism was already built, documented and unused at this call site.**
`Invoke-NativeCapture -Utf8` exists for precisely this
([#907](https://github.com/DKJ-Solutions/claude-code-specialists/issues/907)), and its docstring says *pass
it wherever the output is DATA rather than progress*. A commit subject that a matcher then inspects
character by character is the strongest form of that case, and the flag was simply not passed.

**And the suite could not have caught it.** Its premise assert -- *"the commit on origin really carries the
RTL override"*, written so the asserts below it are not vacuous -- read the subject back through `& git`,
the same console-code-page decode the product code used. So on a non-UTF-8 console it reported the fixture
as broken while the fixture was intact, and on a UTF-8 console everything passed. It now reads through the
same explicit decode, which is what makes it independent.

**Score:** 4

#### What makes this deploy extra special

Every consumer runs `new-branch.ps1` from the plugin mirror, on their own machine, and the guard this
repairs is about **somebody else's text**: the tip subject is written by whoever pushed to the shared
branch. A consumer on a default Windows console had the strip in their copy of the script and not in
effect -- and the output it protects is read by an agent session as well as by a person, where a crafted
subject wearing this script's own `WARNING` prefix is an injection surface rather than a display bug.

Nothing about how the script is used changes, and no flag is added for them to know about. The line they
already see is now the line the script promised.

**Score:** 4

#### Pull Request

the remote-tip read decodes as UTF-8, so the sanitiser sees the characters it strips
