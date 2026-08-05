### The lens scaffold's title carries no (VUL-IN) -- only its slot does · Fix

Tier: 2

**`specialists-teardown -Apply` would have deleted written repo knowledge, and the dry run pointed at
the wrong files.** The lens template wrote `(VUL-IN)` into the H1 title *and* the slot heading;
filling a lens replaces only the slot; and `Test-LooksGenerated` matches `(VUL-IN)` at **any** heading
level. So the title outlived the filling and a lens somebody had written kept classifying as a
disposable scaffold — permanently, and more so the longer that repo worked with it. Inbound
[#451](https://github.com/DaveKJohn/claude-code-specialists/issues/451) measured it in a consumer with
24 lenses: three filled specialist lenses holding 153 lines between them all printed `[remove]`.

**The fix is the rule this same script already followed 320 lines further down**, for `SPECIALISTS.md`,
where the code comment spells out the reasoning it was breaking here — *"A (VUL-IN) title would survive
a filled-in roster and make the teardown delete somebody's work."* The lens template did exactly what
that comment forbids, for every lens instead of one file. The marker now sits on the slot alone, which
is also the only thing an unfilled scaffold needs: the slot heading is still there, so an untouched
lens is still recognised and still removed.

**The dangerous direction was the one that had no test, and the reason is worth keeping.** A filled
lens was already covered — but that fixture *hand-wrote* its lens, and gave it a title of its own
(`# 06-16 repo lens`) rather than the title the bootstrap produces. Inventing the boilerplate is what
made it blind: the only shape that reproduces this defect is the real generated file edited the way a
consumer edits it. The new test therefore runs the actual bootstrap, replaces only the slot heading,
and asserts the file survives `-Apply`. Verified by falsification rather than by passing: with the
marker put back, that assertion fails and the lens is deleted.

**And it is not retroactive, so the instructions carry the other half.** A repo bootstrapped before
this release keeps a marked title on every lens it fills from here on, and that repo cannot be reached
from this one. The bootstrap's closing hints and the `specialists-init` skill page now say that filling
a lens means the marker goes — and that on an older repo it has to come off the **title** too, with the
one-time sweep to find them. Of the two pairings #451 offered, this is the instructions one; the
alternative it also suggested — a check reporting "content beyond the boilerplate but still a
`(VUL-IN)` heading" — is deliberately **not** built here, because the obvious implementation
misclassifies an *untouched* `SPECIALISTS.md` as authored: that scaffold legitimately contains real
import lines, so "anything beyond headings and comments" is not boilerplate there. Doing it properly
means moving the scaffold wording into a shared source both scripts read, which is the
`Get-ClaudeMdScaffold` pattern and a larger change than this defect needs. The front-matter `filled:`
key stays with [#237](https://github.com/DaveKJohn/claude-code-specialists/issues/237), where it was
already proposed.

**In this repo the risk is latent rather than live**, which is why it went unnoticed here: six lenses
carry a marked title (02-09, 03-02, 04-11, 04-12, 04-13, 06-30) and all six are genuinely unfilled, so
they are classified correctly today. Each is one edit away from the trap.
