## `docs/the-quoting-trap-is-the-argument-boundary` changelog

### Branch title

The inline-body rule names the mechanism instead of hedging about shells

### Branch ID

20260810-103746

### Branch type

docs

### What does the change on this branch bring to main?

Derek's rule *never pass a body inline to `git` or `gh`* now states **why no quoting form saves you**,
instead of hedging that the failure happens "on some shells" even inside a here-string. The hedge was the
defect: it reads as a maybe about somebody else's environment, so it leaves the reader an axis to reason
along — *this form is literal, therefore I am safe* — and that reasoning is what breaks the rule.

**The occasion was the rule being broken by a session that could quote it.** It was already written in the
portable body *and* in this repo's lens with a dated measurement, and a commit message carrying
`"names a migration"` still went out as `git commit -m @'…'@` — a single-quoted here-string, chosen
precisely because single-quoting is literal. `git` answered `pathspec 'a' did not match any file(s)`.

**So the mechanism was measured rather than asserted**, and the numbers live in the lens where this repo's
evidence belongs. One argument carrying that phrase was handed to a native command three ways, with the
child printing its own `argv`: the single-quoted here-string and a plain single-quoted string produced
**three** arguments, character-for-character identical to each other, with `argv[2]` literally `a` — which
is the pathspec git named. The same text with the double quotes removed produced **one**. The split
therefore happens where the argument is serialised for the executable, downstream of however the string was
built, so nothing done on the PowerShell side reaches it.

Two smaller things follow from that and are written down with it: the literal here-string is named as *the*
trap rather than as one case, because literal-ness is real and irrelevant — it governs what the string
contains, not how it is handed over; and the file is stated as the **default** rather than the fallback for
hard cases, since there is no message short enough to be worth deciding about.

**Nothing was added about the newline half**, which was already exact, and no gate was built: the failure is
loud, and a checker that recognises "an inline body" in a shell command is the mention-not-use matcher this
project keeps paying for.

### Significance

#### Tier 0

The rule was here, dated and twice-stated, and was broken anyway — so what was missing was not a rule but
the reason it cannot be reasoned around. That is the difference between a note and something that holds at
the moment of typing.

**Score:** 3

#### Tier 1

A documented rule that a reader who knows it still breaks is a documentation defect rather than a discipline
one, and worth treating as such. The recurrence is recorded as a recurrence, which is what makes the second
instance say more than the first.

**Score:** 3

#### Tier 2

Derek's portable body travels to every consuming repo, so the sharpened rule arrives with the next plugin
update in every repo whose specialists make commits or write PR bodies. The mechanism sentence is the part
that saves them the same afternoon; the measurement stays here, because the trap is the shell's and the
numbers are ours.

**Score:** 3

### Pull Request
