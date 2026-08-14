## `fix/resolves-gate-assert-width` changelog

### Branch title

the resolves-gate assert stops depending on the console width and the checkout path

### Branch ID

20260814-180753

### Branch type

fix

### What does the change on this branch bring to main?

`shared-scripts.tests.ps1` failed on `main` for a reason that has nothing to do with any script it
tests. It was found by the gate refusing to push a finished, unrelated branch, and it is
**deterministic rather than flaky**: at a 152-column console the suite went red twice in a row, and on
the same machine, same commit, in an 80-column shell it went green twice in a row.

**What decided the verdict was the console width and the length of the path this repo is checked out
at.** Scenario C1 captured the child with `& powershell ... 2>&1 | Out-String`, which makes the
**parent** re-render the child's stderr as its own `NativeCommandError`: it cuts the first line at the
parent's buffer width — and what it cuts is `<powershell.exe> : <full script path> : <message>`, so
where the cut lands moves with the path — then inserts the record decoration (`At line:`, the `+ `
source echo, `CategoryInfo`, `FullyQualifiedErrorId`) at that point. Measured: the error arrived as
`...open issue(s) #33`, five lines of decoration, `2, but the PR declares...`. The assert on `#332`
then failed while `open-pr.ps1` was doing exactly what it is specified to do.

**The repair was already invented here and this one scenario had not adopted it.** `Invoke-CapturedScript`
— `Start-Process` with redirect files, so the capture receives what the child actually wrote — lives in
this very file, and four other suites use the same pattern after #415. It was defined **inside the
pre-flight scenario's `try` block**, reachable 600 lines later only because PowerShell leaks a function
out of a `try` at script scope, and scenario C wrote around it instead of using it. It now sits at the
top of the file with the other helpers, which is the half that stops this recurring.

**The old comment named the failure mode and then argued past it**, which is the part worth recording:
it said a phrase can only fail to match if it is absent *"or has other content inserted into the middle
of it (the NativeCommandError decoration case, which is why the asserts below deliberately match SHORT
phrases rather than whole sentences)"*. That parenthesis was the whole defect — the decoration case is
not an edge of that capture, it **is** that capture, and short phrases dodge it by luck rather than by
construction. `#332` is four characters and was cut in half.

**The new guard is about the capture, not about a phrase.** A probe child writes to stderr and the suite
asserts the captured text does **not** contain `NativeCommandError` — a string that can only be there if
a parent rendered an error record, at any width and any path length — plus, in the other direction, that
the message itself arrived whole, so an empty capture cannot pass. Verified both ways: the old
`2>&1` form does produce that string, so switching the capture back turns the suite red everywhere
instead of on somebody's machine.

**Named and deliberately not built:** scenarios A, B2 and B3 in the same fixture still capture with
`2>&1` and match with `-replace '\s+', ' '`. They carry the same hazard and have not fired; the phrases
they assert are long enough that a cut inside them has not been observed. They are left alone, with the
helper now visible at the top of the file for the next assert that needs it.

### Significance

#### Tier 0

A test suite whose verdict depends on the width of the window it runs in is worse than no test: it was
green on CI and on a narrow shell while it was red on a developer's machine, and the first thing it did
was block an unrelated finished branch. The reason took a measurement to find, because nothing in the
output says the message was interrupted.

**Score:** 4

#### Tier 2

Nothing reaches a consumer. Checked rather than assumed, because the obvious guess is wrong in the
usual direction here: this repo mirrors its shared *scripts* into the plugin, so a change under
`scripts/` normally does travel — but **no `*.tests.ps1` is mirrored at all**, and the suites are not in
the shared register. The scripts this one tests are byte-identical after the change.

**Score:** N/A

### Pull Request

