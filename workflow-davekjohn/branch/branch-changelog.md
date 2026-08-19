## Branch `docs/handover-transcription` changelog - 20260819-125347

### What does the change on this branch bring to main?

#### Tier 0

`/handover`'s verify step gains a fifth question: **is the cause the lock states actually the cause?**
The four it already asked all test whether the lock is *out of date* — done, overtaken, reasoning
expired, names something gone. None of them catches a lock that is current and simply wrong about a
mechanism, which is what happened on the pickup of
[#747](https://github.com/DaveKJohn/claude-code-specialists/issues/747) an hour earlier.

**The measured instance.** A lock written **six minutes** before it was read named its subject correctly —
an open, still-standing inbound issue — and stated the cause as `-RankByTier 2` filtering a tier-1 repo's
entries out. That parameter only **sorts**; it drops nothing. The real hardcode was a `Tier -eq 2`
selection in `cut-release.ps1`, one file earlier than the renderer the lock routed the fix to. **The report
it summarised had named the right line.** So this is neither truncation nor staleness, the two modes Chris's
lens already carried, but **transcription**: a correct source summarised into something false.

**Two properties make it the hardest of the five to catch, and both are now written down.** The lock was
*fresh*, so every staleness instinct argued for trusting it — and it carried its own certificate,
*"Confirmed at the code level before locking, not taken from the report"*, which is precisely the sentence
that would otherwise have prompted a re-read. Nothing was lost only because the repair began by opening the
function; without that it would have landed in the wrong file, left the defect standing, and shipped a code
comment citing a mechanism nobody has — a defect that reads as authoritative.

**Written into the payload rather than the lens, per the standing rule that a way of working goes portable
first.** Every repo that uses `/lock` has this failure available to it, so the rule and its measurement sit
in the shipped skill page; the lens keeps a pointer plus the one genuinely repo-specific note — that here the
report and the pickup were the same team an hour apart, the same shape as the fifth inbound pattern already
recorded there.

**Score:** 3

#### Higher than tier 0?

It is a **shipped skill page**, so every consumer using `/handover` receives the sharper verify step
with the next release -- and the failure it guards against is one their own locks can produce, since
`/lock` writes a summary in exactly the same way. The measurement travels with the rule rather than
staying in this repo, which is what makes it usable by a reader who was not here for it.

**Score:** 2

### Pull Request

a handover's summary of a report is verified against the report, not inherited
