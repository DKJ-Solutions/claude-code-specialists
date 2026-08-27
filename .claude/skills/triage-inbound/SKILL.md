---
name: triage-inbound
description: The measured evidence behind this repo's inbound-item verification — the six ways a filed report fails on pickup (already repaired, reasoning expired, proposed repair names something that does not exist, subject does not exist, size mis-measured, the symptom is in the reporter's own tree), each with the issue that produced it. Use when an inbound issue is being picked up here, when a report's symptom, reason, repair, size, subject or repo is being checked against the tree, or when deciding whether a standing report is still routable.
---

# Triaging an inbound item — the evidence

> The **rule** lives where it is always loaded: the portable half in Chris's persona body
> (`plugins/teams/team-alpha/personas/01-01-persona.md`) and this repo's one-sentence form in
> [his lens](../../specialists/lenses/01-01-extension.md#the-dave-rules). This skill carries the
> **measurements** behind it — which is what the repo's own convention asks of a skill: *"personas
> and manuals carry no repo-specific detail at all while skills carry the evidence behind a
> procedure"* ([`CLAUDE.md`](../../../CLAUDE.md#claude-code-specialistss-safety-implementation)).

Six things are checked before an inbound item is routed, and each one fails independently: the
**symptom** may already be repaired, the **reasoning** may have expired, the **repair** it proposes
may name a mechanism that does not exist, the **subject** may not exist at all, the **size** it
reports is almost never the size of the subject, and the **repo** it names may not be the one the
symptom is in. Below is the instance that produced each, because a pattern without its measurement is
just advice.

## The six patterns, as measured here

- **Where the inbound verification was measured.** The portable rule — an inbound item is verified as
  still standing before it is routed — was written after
  [#469](https://github.com/DaveKJohn/claude-code-specialists/issues/469) on August 5, 2026. It was
  filed at 08:04 reporting that the fold kept the entry-creation date, repaired on `main` by
  [#472](https://github.com/DaveKJohn/claude-code-specialists/pull/472) at 09:24, and picked up as open
  work after that. Because this repo is the source, it receives every consumer's inbound issues *and*
  does the repairing, so filing and fixing can and did cross inside the same morning — which is why the
  check belongs at the front of intake here rather than being a theoretical nicety. Two details of that
  close are the reason the portable rule says more than "check first": the repair had gone **further**
  than the issue proposed (the date left the heading altogether instead of being restamped in it), so
  the documentation fix the reporting repo had planned needed different wording; and the audit the issue
  suggested in passing was worth actually running — **7 of 326** dated headings in `CHANGELOG.md` and
  `releases/` disagreed with the real merge date, all by one or two days, deliberately left as they are
  because they sit in published records that already travelled to consumers.
- **The second failure pattern: it still stands, but its reasoning has expired.** #469 is the easy case —
  the item was repaired, so verifying it closes it.
  [#456](https://github.com/DaveKJohn/claude-code-specialists/issues/456) is the case that looks like it
  survives verification: re-measured on August 8, 2026, everything it *asks for* was still open, while
  **three of its own load-bearing facts had expired** in the four days since filing — the seam whose
  history-wiping danger carried its central argument was retired, along with two others it counted. So a
  standing item is not automatically a routable one: check the **reasoning** as well as the symptom, and
  where the argument is gone say so and have it re-established rather than inherited. Same discipline as
  the repo's rule that a report's *reason* is verified before its symptom is repaired — this is that rule
  applied to the report's own age.
- **The third failure pattern: symptom and reason both stand, and the proposed repair names something that
  does not exist.** [#566](https://github.com/DaveKJohn/claude-code-specialists/issues/566), measured on
  pickup, August 10, 2026. It reported that `CONTRIBUTING.md` could not be adopted by a consumer because it
  hardcoded this repo's answers where the seam already has a function, and it was right on both counts —
  five of the six seam functions it named exist under exactly those names, and the four false statements it
  listed were in the file. Its **proposal** was the part that failed: it gave
  `Resolve-PluginScript -RelativePath 'scripts\task\new-branch.ps1'` as the form a consumer invokes a
  shared script with, and no such function exists anywhere in the tree. The real form is
  `${CLAUDE_PLUGIN_ROOT}`, which is what the repair ended up documenting.
  **Why this one is the most expensive of the three to get wrong here:** the deliverable was a document
  written to be *copied*, so adopting the proposal verbatim would have shipped every consumer an
  instruction to call a function that has never existed — a defect that reads as authoritative and travels
  by plugin update. A reporter infers mechanisms from the outside; grep each named function, flag or file
  before building on it, keep the observation and replace the remedy. The same pass found the reverse, too:
  the trap the issue reported around `Get-ReservedRootMd` was already written up in the contract table as
  `Adopt = 'decide'`, so that half needed surfacing rather than building.
- **The fourth failure pattern: symptom, reason and repair are all beside the point, because the subject
  does not exist.** [#660](https://github.com/DaveKJohn/claude-code-specialists/issues/660), closed
  August 15, 2026. It asked for a GitHub Projects board for *"pair-cli issues, tickets and project work"*,
  and everything downstream of that name was sound: two pickups answered the four design points, measured
  two real blockers, and designed an owner-level board carrying draft items because the repo did not exist
  yet. Coherent throughout, and about nothing. Asked directly, **Dave did not recognise the name** — and
  the search that followed found `pair-cli` in exactly one place in the visible world: the issue itself. No
  file in the tree, no other issue or PR under either owner, no repository of his anywhere on GitHub.
  **What made it invisible is worth naming, because it will look the same next time.** The issue was
  written by a session on Dave's spoken word — its own text says so (*"filed so it is not forgotten"*) —
  in a batch of three dictated within 45 minutes that morning, the other two of which were real and closed
  the same day. So the name arrived under his name, in the house style, flanked by siblings that checked
  out. The first pickup did search for the repo, found nothing, and recorded it as **"not visible from
  here"** rather than as *"not there"* — that single reading is the whole defect, and it cost a second
  pickup plus an auth-scope refresh requested from Dave for a board that was never going to be built.
  **Ask the requester before designing**, and treat a name occurring nowhere but in its own report as
  naming nothing.
  The same close settled the wish underneath the name, so nobody re-opens it on instinct: measured over
  every issue ever filed here, **179 total, 178 closed, 170 of them within 24 hours, median lifetime 3.4
  hours, none older than seven days, and exactly one open** — the issue asking for the board. A board keeps
  waiting work visible; nothing here waits.
- **The fifth pattern, measured on this repo's own reports rather than a consumer's: the finding is
  real and its SIZE is wrong.** Written August 15, 2026, after a team-wide review filed 22 issues and
  **three of them turned out to be mis-measured on pickup** — all three mine, all three found only
  because the repair began with a recount. **A fourth followed the next day**, from the same review and
  the same team, and it is added below rather than folded into the count so the growth stays visible:
  - **[#697](https://github.com/DaveKJohn/claude-code-specialists/issues/697)** counted **32** uses of
    the retired name "the workshop repo". The subject — the word *workshop* as a live term — is
    **342**. Repairing to the report was still right, but the remaining 310 are a separate decision,
    filed as [#720](https://github.com/DaveKJohn/claude-code-specialists/issues/720) with its
    measurement rather than swept along on my own authority.
  - **[#700](https://github.com/DaveKJohn/claude-code-specialists/issues/700)** claimed one identical
    sentence in **20** agent defs. Exactly **3** are identical; the other 17 carry role-specific tails.
    The proposed shared block would have put those 17 tails inside a generated region for the next
    generator run to delete — the same trap that had to be worked around eight times in
    [#699](https://github.com/DaveKJohn/claude-code-specialists/issues/699).
  - **[#701](https://github.com/DaveKJohn/claude-code-specialists/issues/701)** reported a claim
    falsified by **5** dated references in 3 portable files. The claim names four categories and
    *dates are not among them*: the real count is **2** person names. Repairing to the report would
    have stripped two correct measurements out of Nolan's manual.
  - **[#714](https://github.com/DaveKJohn/claude-code-specialists/issues/714)**, picked up the next day,
    August 16, 2026, makes it four — and it is the one where the recount changed the *verdict* rather than
    the size. It reported the local test gate at **322.5s**, "+40%", growth "diffuse, not one offender".
    Re-measured five times, four of them in the gate's own pool: **196–235s**, around the baseline it was
    said to have left, with the whole wall clock being **one suite** to a tenth of a second. Its second
    count was wrong in the same direction as the three above — "234 asserts" is what that one suite prints
    for itself, against **4,206** across all forty. The measurement and the corrected direction are in
    [Nolan #25](../../specialists/lenses/06-25-extension.md#the-gates-wall-clock-is-one-suite--re-measured-n5-august-16-2026).
  **What generalises:** a count in a report is whatever the search matched, and the search is chosen by
  whoever noticed the symptom. Here the reporter and the repairer were the same team an hour apart, and
  it still went wrong **four times out of 22** — which is the argument for recounting even when the report
  is your own, and especially then. **And a timing is a count too**: #714's headline was a stopwatch
  reading taken while the machine ran a team-wide review, which is why the re-measure states the machine
  state and the n beside every figure.
- **The sixth pattern: the symptom is real, it is live right now, and it is in the REPORTER's tree.**
  [#954](https://github.com/DaveKJohn/claude-code-specialists/issues/954), closed August 27, 2026. It
  reported two dead GitHub blob URLs — `plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md`,
  404 against the `contributing-davekjohn/` form's 200 — in `releases/README.md`, above its horizontal
  rule. Every one of those facts was verified and true, and the dead links exist. **In djcylow-react.**
  Here, `grep -rn "plugins/workflows/workflow-davekjohn" .` over the whole tree returns **zero** live
  hits: the seven survivors are inside archived release notes as visible prose whose link targets already
  point at the new path, which is the published-record rule working. And the page the report names has no
  mirrored section for them to be in — `grep -c '^---' releases/README.md` returns **0**, no horizontal
  rule at all. Two commits emptied it, and the first is the point: `94476de6` (August 13, 2026, inbound
  [#646](https://github.com/DaveKJohn/claude-code-specialists/issues/646)) moved the mirrored process half
  **out of that file** and into `RELEASES-portable.md`, taking both URLs with it; `8797f7a5` (August 26,
  #886) then corrected the path in its new home.
  **What made it invisible is the report's own justification, which is the part to distrust.** It argued
  *"the content above the rule is a verbatim mirror of the source's page, so a local fix would just
  restart drift"* — sound reasoning from an identity the two trees had **stopped sharing thirteen days
  earlier**, by the very change that ended the mirroring. A mirror is the one construct where "which
  repo's tree is this path in?" cannot be answered by reading the content, because being identical is the
  whole design. So resolve the path in **your** tree before accepting the attribution, and where it
  resolves nowhere, go and read the reporter's copy. Theirs was at
  `contributing-davekjohn/releases/README.md` — a *different path* than the report names, whose own
  `releases/README.md` returns 404, so the named file existed on neither side. **The tell for a stale
  mirror is datable from inside it**: line 482 of their copy still describes `RELEASES-portable.md` as a
  proposal ("source for a **`RELEASES-portable.md`** in the plugin"), which pins the mirror to before #646
  landed, while the two dead links sat at 196 and 289 above the rule at 336.
  **And the proposed repair fails a fourth way**, on the tree that does have the defect: repointing two
  URLs preserves a ~4,000-word hand-maintained mirror of a process half that no longer exists upstream —
  the exact cost #646 was filed to end — and it would drift again at the next rename. The remedy is to
  replace everything above the rule with a pointer to the plugin's page, which is what
  `adopt-workflow-folder` scaffolds. **What separates this from the first pattern:** #469 was repaired
  here, so verifying it *closed* it. Here nothing was repaired away — the defect is live, it is simply
  not ours, and the closure's whole value is telling the reporter which file to open and what to do that
  is not what they asked for.
