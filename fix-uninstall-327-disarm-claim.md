### the #327 disarm claim is conditional on which key stays behind · Fix · 2026-08-02

`UNINSTALL.md` Step 3 closed with *"Walk it through to the end of Step 5 and the mechanism is
disarmed, stray key or not."* Round v13 measured the opposite (inbound
[#382](https://github.com/DaveKJohn/davekjohns-workshop/issues/382)): after a by-the-book teardown
through Step 5 — record `{}`, `known_marketplaces.json` `{}`, clone and cache gone — with **both**
keys deliberately left behind, two session starts and no commands at all put the machine back on an
install record. Session 1 re-registered the marketplace and rebuilt the clone; session 2 wrote a
full `project` record.

The disarming does not hang on reaching Step 5 but on **Step 3 removing both keys**, and the two are
not equal: with only `enabledPlugins` left the machine does stay free (measured separately), so
`extraKnownMarketplaces` is the one that matters — it is the key that can put the marketplace back,
and everything else follows from that. The closing sentence now says so, and the key's bullet in
Step 3 is marked accordingly.

The three-state table gained a fourth row and lost one condition that was too strong. Its rows 1 and
2 read as a sequence rather than as alternatives — the state row 1 leaves behind *is* what row 2
fires on, which is what makes the whole thing possible unattended. And the record in row 2 does
**not** require the unpacked cache: v13's record pointed its `installPath` into a
`cache/davekjohns-workshop/…` directory that did not exist.

Folded in from the same round: a record written by a session start is recognisable by its **key
order** (inbound [#389](https://github.com/DaveKJohn/davekjohns-workshop/issues/389)) — a real
install puts `projectPath` second, a session start puts it last. A second signal next to
`installedAt` and independent of it, readable without the hand-edit that would wipe the evidence.
Written in as confirmation rather than proof, with its CLI-version caveat attached.
