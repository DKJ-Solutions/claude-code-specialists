### Four secondary findings from the life-hub round (inbound #271) · Fix · 2026-07-30

The four lower-severity findings from
[#271](https://github.com/DaveKJohn/davekjohns-workshop/issues/271), fixed together because all four sit
in the same install/uninstall path — and **three of them are defects in work shipped earlier the same day**,
which is the argument for a second pair of eyes outside this repo.

**1. The audit missed a Dutch possessive, which is a false negative in a scan built to over-report.**
`Dereks` takes no apostrophe in Dutch, so the trailing `\b` rejected it and a live reference in a
consumer's own tracked prose went unreported — in a scan whose skill documents itself as biased toward
over-reporting *precisely because a miss is the expensive failure*. The name group now accepts an optional
possessive (`Dereks`, `Derek's`, `Alex'`). **Applies to every non-English consumer, so not an edge case.**

Fixing it exposed a second, smaller lie in the same line: the hit was reported from the capture group, so a
match on `Dereks` printed `name 'Derek'` — sending a reader to search for a string that is not on that
line. It now reports the text **as it appears in the file**.

**2. The dry-run audit showed the wrong 40 lines.** The preview is explicitly the inventory a reader says
yes to, and it was filled entirely by the ~20 lens files the same run had just listed under `[remove]`:
every one mentions a specialist, they consumed the whole cap, and the hits that actually matter only became
visible after `-Apply`. Files on the removal list are now **excluded** rather than sorted last — a
reference inside a file that is going away is not a surviving reference, so listing it would be wrong and
not merely noisy. The exclusion is counted and stated, because a silent narrowing is the thing this audit
exists to prevent.

**3. `[keep]` on an occupied `repo-config.ps1` left a broken contract silently.** Keeping it is correct —
these addresses are inhabited in any repo that predates the plugin, since the scaffolds are the files that
were *extracted from* repos like these. But an existing one has no reason to define the plugin's own
contract functions, so `check-roster-sync` then calls `Get-RosterPath` on a file that does not have it and
the consumer gets `[ERROR]` lines at every session start with nothing connecting them to the bootstrap.
The `[keep]` line now names the missing functions — **only the missing ones**, since listing all four at a
repo that already has them is the noise that teaches people to skim.

**4. The per-item `[KEEP]` line claimed authorship the script cannot establish.** It printed *"filled
in"* while the summary block below it correctly hedges with *"not recognised as an unfilled scaffold"* —
the `smartwatchbanden` correction landed in the summary and not in the line above it, so one run asserted
and hedged about the same file. The line now says what the script actually knows.

**All four are asserted**, including the two that could only be caught by looking at real-world shapes: a
Dutch possessive in a consumer's prose, and an occupied scaffold that lacks the contract. The
possessive test also asserts that a line naming **no** specialist is still not a hit — a looser boundary
must not become a boundary that matches everything.
