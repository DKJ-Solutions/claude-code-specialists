### The v3.5.0 release documents: the internal note and the edited highlights · Docs · 2026-08-05

Tier: 0

The two documents `cut-release.ps1` deliberately does not write, for the release cut earlier today. Both
land here rather than on the release commit because that commit is already tagged, and neither is one of
the two named direct-on-`main` exceptions.

**The internal note (tier 1) is written from scratch, as it must be** -- the generated skeleton supplies
the metadata and the entry titles as bullets, and the one section carrying the tier's whole point, *what
it is worth*, is the one nothing can generate. Written in time, risk and reduced dependence on a
developer: the version number stopped being a matter of taste, three audiences stopped sharing one
document, and a gate we believed was running turned out not to be.

**The highlights (tier 2) went from 300 lines to 60, and that is the edit rather than a side effect of
it.** The generated draft is now the right *selection* -- the four tier-2 entries, chosen by their own
authors instead of guessed from branch prefixes -- but it is still their words, written for a reviewer.
The reader of this document decides whether to update, so the rewrite drops every file name, function
name and assert count, and keeps the four things that reader can act on: the changelog gains tiers and
the bump has to be earned, the shared release script stops assuming it runs in its home repo, two
workflow scripts resume instead of failing, and nothing changes for a repo that has adopted none of it.

**One line was deliberately not written into the internal note**, and its absence is the lesson from
v3.4.0's note holding. That tier warns that it is a *snapshot* and goes stale in hours where it is also
the published release body -- measured once by a line stating the previous release had no public page,
which its own author then published. So the open-points section names what sits with whom, and says
nothing about what has or has not been published as of the hour it was written.
