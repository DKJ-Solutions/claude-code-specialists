### the install path never names the marketplace refresh · Fix · 2026-07-31

Inbound [#284](https://github.com/DaveKJohn/davekjohns-workshop/issues/284), test round v5. The #282
fix — the marketplace cache is a second update gate — landed completely on the **update** side and on
exactly one of the places that describe a first **install**: `specialists-init/SKILL.md` step 0b. The
QUICKSTART's Step 1 and the family README's Step 0 still printed an install with no
`claude plugin marketplace update` in it.

**The sharp part is where the evidence sits.** The measurement the QUICKSTART itself cites is a fresh
`install`, not an `update`: minutes after `v3.0.2` was tagged, `claude plugin install … --scope project`
produced **3.0.1** and said `✔ Successfully installed`. That sentence lives under *Staying up to date* —
a section headed "Updates reach you via **releases**", which is not where the install reader goes. So a
new consumer following the three steps literally skipped the refresh and walked into the exact fault the
page had already measured, with nothing in the output to betray it: a green install, a plausible version
number, and a session quietly missing whatever the release added.

That weighs more than a forgotten cross-reference, for a reason the two documents state about
themselves. The QUICKSTART is, per the root README, *the* canonical enable-a-plugin walkthrough and is
explicitly aimed at someone who did not build the system — the reader with no experience to fill a gap
with. And Step 0 of the family README says of itself: *"This documentation path is the only thing a new
consumer has, because until the plugin loads, the skill that would say otherwise does not exist."* Which
is precisely why the correct version in `specialists-init/SKILL.md` cannot cover for either of them.

Four places now name it:

- **QUICKSTART Step 1** — two numbered lines, refresh first, with one paragraph on why an install-time
  reader is the one who needs it, pointing at *Staying up to date* for the full mechanics rather than
  restating the measurement.
- **Family README Step 0** — "three acts in order" is now **four**. The acts being counted is what made
  a missing one expensive here, so it is an act rather than a parenthesis, plus a blockquote naming both
  the behaviour (#282) and the omission (#284).
- **`connectors/README.md`** — the version-gate line named the scope flag but not the refresh; it now
  names both. The weakest of the three, and the same asymmetry.
- **The root README's Consumption paragraph** — which #284 did not list. It printed
  `claude plugin install … --scope project` with the flag and no refresh. Found by running #284's own
  suggested verification (grep every place that prints a lifecycle command, and check what travels with
  it) instead of only the three addresses the finding named.

**Deliberately not claimed: this is a doc finding, not a second measurement of #282.** The stale-cache
state could not be produced naturally in this round — the cache on that machine had been refreshed on
July 30 when `v3.0.3` was released — and following QUICKSTART Step 1 literally, *without* the refresh,
simply produced 3.0.3. What was measured is that the step was missing in the places above.

Plugins: specialists
