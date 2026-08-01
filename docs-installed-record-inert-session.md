### The state that reads as healthy from every angle · Docs · 2026-08-01

The last of test round v10's findings (#327), and the part of it that was still open. Its first half — the
bold claim *"Those keys do not install anything, though"* — was already false-by-measurement and was
corrected in [PR #341](https://github.com/DaveKJohn/davekjohns-workshop/pull/341), in the same paragraph that
PR was rewriting. What remained was the half the issue itself called the largest of the round: **the state
deserves naming, because it reads as healthy from every angle.**

**What was measured.** On a virgin profile, a **single session start** — no command run, no file changed —
wrote a full `project`-scoped install record with the correct version and sha, byte-for-byte the size of the
one the documented command produces. And **that same session loaded nothing**: no `specialists-*` skills, no
subagents, no session-hook output, no sender header, while the entire payload sat in the cache. The record is
written *after* the load phase, so only the next session gets the plugin.

That combination is why it is worth a name rather than a footnote. Every angle a reader would normally trust
agrees: the record says installed, project scope, correct sha; every check that reads that record sees a
healthy repo; and the session is inert. The verification query in Step 1 **cannot** catch it, because the
query reads the record. So the QUICKSTART now says to verify by the **surface** instead — is the skill in the
slash list, did the hooks print, does Chris open the turn — and ties it to the discipline `UNINSTALL.md`
already states from the other direction: *"a session that loads no plugin has no hooks to complain."* Absence
of complaint is not evidence when the thing that would complain is the thing that did not load.

**A second, independent reason `[NOT-INSTALLED-HERE]` never fires at a session start**, now recorded in the
design note next to the "heals itself" correction from
[PR #345](https://github.com/DaveKJohn/davekjohns-workshop/pull/345). That note explains the marker is
unreachable because the record is written away before a hook can look. v10 measured the other half: there is
**no hook running at all** in that session, because the hooks ship in the plugin it did not load. Both halves
must hold for the marker to be reachable from a session, and neither does — which is exactly why it is
documented as reachable only by a deliberate run, and why `check-connectors`, speaking about a consumer from
outside, remains the only thing that can report the total case.

**What this entry deliberately does NOT settle.** #327 raises the possibility that the two `claude plugin`
commands in Step 1 are redundant: a session start registers the marketplace (#329) and a later session start
writes the record (this issue). **That chain has never been run end to end.** The two halves were measured
separately, and the second ran via a manual `marketplace add` rather than via a session start. It is a
measurement, not a documentation choice, and it cannot be made in this repo — so it is written down with its
exact recipe rather than guessed at or quietly dropped: *write the two keys, restart, restart, then read the
six locations and the skill list without running a single `claude plugin` command.* Until that has been done
the page tells the reader to run the commands, because that is the route it can vouch for.

Split out as [#350](https://github.com/DaveKJohn/davekjohns-workshop/issues/350) rather than left inside a
closing dossier, with the recipe and what each of the three outcomes would mean. A question that only exists
in a closed issue is a question nobody will run.

Plugins: specialists
