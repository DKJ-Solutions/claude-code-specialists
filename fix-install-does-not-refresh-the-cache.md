### install does not refresh the cache — measured, so stop calling it unmeasured · Fix · 2026-07-31

`v3.0.5` was cut to ship #292, and the stale-cache window it opened was used for the question #292 had
to leave open. **That window expires** — it lasts only until something refreshes the clone — so it was
measured the minute it existed instead of left for the next adoption round, which had already reported
it as an unreachable gap twice
([#287](https://github.com/DaveKJohn/davekjohns-workshop/issues/287) §5.1, and the round before it).

**The measurement, as a controlled pair.** Same machine, same minute, two fresh throwaway folders, with
the cached clone recorded beforehand as sitting on the `v3.0.4` commit and not containing the `v3.0.5`
one:

| | command | result | clone afterwards |
|---|---|---|---|
| A | a fresh project-scoped install, **no refresh** | **3.0.4** — the previous release | unchanged, still on `v3.0.4` |
| B | `claude plugin marketplace update` first, then the same install | **3.0.5** | advanced to `v3.0.5` |

So **`install` does not refresh the cache and `update` does.** The per-command distinction #292
introduced is no longer half-measured: the `install` half rests on two independent measurements on two
different releases (July 30 after `v3.0.2`, July 31 after `v3.0.5`), and the refresh is *load-bearing* in
front of an install where it is idempotent insurance in front of an update. Both keep it.

**One detail that is worse than the earlier account said.** The install's success line names the **scope
and no version at all**. Previous notes said "nothing in that output hints the version is stale", which
understates it: there is no version in the output to be suspicious of. The install record is the only
place it appears — exactly why the adoption path verifies against `installed_plugins.json` rather than
reading a success line.

**What this corrects.** [Rendall #06's lens](.claude/specialists/lenses/05-06-extension.md) said in as
many words that the `install` half was *"still unmeasured: that needs the next release's stale window"* —
true when written a few hours earlier, false now, and left alone it would be the same class of defect this
repo spent the day closing. Corrected there, in the QUICKSTART's *Staying up to date*, in
`specialists-init` step 0b, and in the root README's *Versioning*. Rendall's lens also gains the
operational lesson: **the stale window after `cut-release.ps1` pushes the tag is a measurement opportunity
that expires**, so an open cache question gets answered then or waits a whole release.

Not claimed: any mechanism. *Why* `update` refreshes and `install` does not was not established, and the
docs state the two measured behaviours rather than a theory about them.

Plugins: specialists
