### a gate for the class: printed lifecycle commands must carry their flags · Feat · 2026-07-31

The structural half of test round v5's result
([#287](https://github.com/DaveKJohn/davekjohns-workshop/issues/287) §4), and the reason that issue
exists at all. Three adoption rounds in a row found the same kind of defect and almost nothing else: a
doc place printing a command, a count or a step that no longer holds. v3 was the adoption path plus
three reporting errors; v4 was #279 + #280; v5 was **all four** of its findings — and three of the five
repairs in 3.0.3 were of that kind too. Four doc fixes close four instances, and the instances came
back every round. This adds **check 11** to
[`check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1), so the part of that class a
gate can actually decide stops depending on someone noticing.

**The rule.** Every printed `claude plugin install` / `update` / `uninstall` must carry
`--scope project`, and `install`/`update` must have `claude plugin marketplace update` — or a link to
*Staying up to date* — within 12 lines above or 6 below. Both are things a reader **copies**, and both
fail *silently* when wrong: a scopeless install writes a machine-wide record with no `projectPath` and
reports success (#274/#279), a stale cache serves the previous version and reports success (#282/#284).

**Why this can be a generic scan where check 10 had to be opt-in.** That one (the marked all-skills
enumeration check) measured 147 hits repo-wide on a generic prose scan — including a deliberately
illustrative list that would false-positive forever — and was made sentinel-driven for exactly that
reason. The discriminator here is the **`@`-target**: `claude plugin install
specialists@davekjohns-workshop --scope project` is an instruction someone runs, while
"`claude plugin update` has the same default" is prose discussing the command, and demanding flags of
prose would be nonsense. Measured over the scan set: **11 targeted, 13 bare.** That separation is what
makes the check viable, and it is the case the test suite guards first.

**History is excluded permanently and on purpose:** `CHANGELOG.md` (root and per-plugin),
`releases/**`, every `RELEASE.md` card, and the root changelog entry files. Those record what was true
at the time and are never rewritten — the same principle the teardown's own audit already applies. The
repo proves the need: `specialists/CHANGELOG.md` prints a targeted install with no scope flag,
correctly, because that is what the release it describes actually said.

**Three implementation bugs, all three worth recording, because each one was a way for the gate to be
quietly wrong.** The first build was line-based and flagged the teardown SKILL's own
`claude plugin uninstall …` line, whose `--scope project` sits on the *next* line of the same
inline-code span — so the unit became the enclosing span. The second was quieter and therefore worse:
spans are found with a `` `…` `` pattern, and a fence delimiter opens a phantom span that pairs every
real span downstream one position out, which made the wrapped command look *flagless* rather than
raising anything; reusing check 10's `Get-FenceMaskedText` fixed it. The third came out of the code
review: both rules judged the whole span, so two commands in one span meant the second borrowed the
first one's `--scope project` and read as correct while a reader copies a scopeless line. The unit is
now this verb's own arguments, up to the next lifecycle command. All three are locked in as scenarios
21, 22 and 25 — and the second and third are the kind that fail *green*, which is the same failure mode
as the findings this whole round was about.

**And it immediately earned its place**: on first green run it found a fourth spot PR #289 had left
alone — the family README's `--scope project` blockquote printed an update command with the refresh
seven lines too far below. The doc was rewritten so the sentence that prints the command carries the
refresh, rather than widening the window to fit the doc.

**What this deliberately does not claim.** #287 frames one such gate as closing *the class*; it closes
the half that is decidable by pattern — the flags on a printed command. A stale **count** ("nineteen
lenses", "three acts") or a stale **step** in a procedure is still a human finding, and check 11 would
not have caught #283, #285 or #286 either. It also checks *presence*, not order: whether the refresh is
described before the install in reading order is a judgement about prose, and the check does not pretend
to make it. Coverage is stated out loud for the same reason — an empty scan prints *why* it is empty, so
"nothing to enforce" cannot be misread as "the docs are right".

Also updated so the gate's description stays true where it is made: `CLAUDE.md`, `CONTRIBUTING.md`, and
[Sylvester #15's lens](.claude/specialists/lenses/05-15-extension.md).

Plugins: specialists
