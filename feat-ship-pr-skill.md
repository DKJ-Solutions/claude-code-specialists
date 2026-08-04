### The safety-critical ship-pr sequence gets the page it was already being sent to · Feat · 2026-08-04

**Check 18 declared this gap two days ago; this closes it, and the count turned out to be one smaller
than the note said.** The parameter gate's coverage line named four mirrored scripts documenting nothing,
of which three were called real gaps: `ship-pr`, `fix-mojibake` and `verify-resolved-issues`. Reading the
registry rather than the summary shows the third was never a gap of its own — its registration already
said so in as many words: *"No skill of its own, and that is right: it IS ship-pr's step 6 ... It
therefore inherits ship-pr's gap above."* So one page closes two entries, and `fix-mojibake` is the only
one left.

**The route existed before the page did.** The `cut-release` skill has been sending readers to "the normal
`new-branch` → `ship-pr` route" while no page described the second half of it — a consumer following that
sentence arrived nowhere. This is also the sequence the registry itself classifies safety-critical, on the
grounds that it merges to the main branch and then commits directly to it, which is the one procedure where
arriving nowhere is worst.

**What the page carries beyond the invocation**, because a consumer has only the mirror and this text:
all eight parameters plus the three of `verify-resolved-issues`; that **when** it may run is governance and
not script logic; why step 3 polls the *text* before it watches (`gh pr checks` prints "no checks reported"
and exits **0**, indistinguishable from "all passed", so a bare `--watch` walks the merge into a `BLOCKED`
wall); why the merge method is validated rather than passed through; why there is no `--admin`; and why the
fast-forward names `origin/main` explicitly instead of using a bare `git pull --ff-only`.

**One correction landed on the way, and it is the kind only a reader finds.**
`verify-resolved-issues.ps1`'s header said *"Deliberately workshop-local (like ship-pr.ps1 and
cut-release.ps1): NOT mirrored into the plugin."* It has been mirrored since it started travelling with
`ship-pr`, so that sentence sat **in the mirror, denying the mirror existed** — and it was wrong three
times over, because both scripts it cited as fellow cases had been shared too (`ship-pr` by #411,
`cut-release` by #417). A claim that names its own supporting evidence and gets all of it wrong is worth
more than a silent fix. **No gate could have caught it:** the drift lint compares the two copies against
each other, and a wrong sentence present in both is not drift. Verified against the registry and the
mirror directory rather than taken from the sentence itself.

**`-Resolves` gets the space it needs rather than a table row.** It is a string and not an `[int[]]`
because across `powershell -File` a comma list is cast to one number via the thousands separator —
`-Resolves 332,340` silently becomes issue `332340`. That is the one parameter here whose *type* is
load-bearing, and a consumer reading only the mirror would have no way to know.

**No new test, stated rather than skipped.** The `shared-scripts` suite already asserts that every non-lib
entry declares a `Skill` and that a non-empty one names a skill that exists — it went from 183 to 185
asserts on the two new declarations without a line being written. That is the registry-beside-the-
registration design doing what it was built for. The orchestrator's own test gap (it drives live `git`/`gh`)
is unchanged and now stated on the page as well.
