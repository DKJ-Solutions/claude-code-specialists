### A quoted output sample must say what it is bound to · Feat · 2026-08-02

The class behind four of test round v11's nine findings, closed as a rule rather than as four
documentation fixes. `#358` quoted a bootstrap line captured in a repo that already had the script
scaffolds; `#359` quoted a CLI error the current CLI no longer emits; `#360` gave a byte baseline that
was the LF figure on a platform where every round measures the CRLF one; `#361` told the reader to look
for a sender header no bootstrapped repo produces. Each was accurate when captured, which is what makes
the shape nasty: nothing reads as wrong, the reader is simply told to expect something that cannot
happen on their machine.

**Check 15 (`[expected-output]`) holds the consumer-facing docs to it.** A fenced block carrying a
language is a command to run; a block with no language, or `text`, is a sample the reader compares
against — and only the second kind can go stale under them. That distinction was already in the markup,
which is why this is a gate and not a heuristic: measured before building, the two consumer documents
hold 34 fenced blocks of which exactly 5 are samples. A check with a five-item haystack can afford to
be strict. Each sample must have a version, a date, or a hedge (`varies`, `illustrative`, `depends on`,
…) in the prose around it — not inside it, which was the first bug the tests caught, where a block
containing the words "already present" vouched for itself.

**It found a live instance immediately**: the marketplace-refresh failure quoted in Step 1 of
`QUICKSTART.md` named no CLI version — the same defect as `#359`, one section earlier, which the round
did not catch. Now bound, with the invariant stated separately from the wording.

**Two exclusions, both stated rather than silent**, because an exclusion nobody can see is how a gate
quietly stops covering what it claims: language-tagged blocks (commands), and blocks containing box
drawing (diagrams are drawn, not captured — the family README's seam diagram was the check's first false
positive). The escape hatch `<!-- unbound-sample: <reason> -->` must name a reason; a bare marker does
not silence the check, and that is asserted, so the hatch stays a way to record an exception rather than
a way to switch the gate off.

The rule itself is recorded with [Tessa #16](.claude/specialists/lenses/06-16-extension.md), who holds
it everywhere the gate does not reach: prefer stating the invariant over quoting the string.
