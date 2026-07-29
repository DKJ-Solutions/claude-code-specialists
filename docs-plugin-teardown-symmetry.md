### Install and uninstall must be symmetric — the teardown gap, recorded · Docs · 2026-07-29

Dave set a requirement on July 29, 2026: a consumer must be able to **install and uninstall these
plugins at any moment**, and after an uninstall it must be able to stand fully free — no lingering
reference to a specialist, manual, persona, or roster anywhere in the repo. Adoption is reversible by
design, not a one-way door. `specialists-init` builds up; **nothing tears down.**

Measured against the `life-hub` consumer rather than estimated. The half that already works is worth
stating plainly: **everything the plugin owns disappears correctly** — agent defs, manuals, persona
bodies, skills, shared scripts, and the three `SessionStart` hooks, which are registered by the
plugin's own `hooks/hooks.json` and leave with it. The gap is entirely on the consumer side: 26
git-tracked lens files referencing nothing, 101 specialist mentions across 492 lines of `CLAUDE.md`,
scripts that exist only for specialists, and — the sharpest one — an `@`-import that points into the
marketplace cache and therefore **actively breaks**, leaving a dead instruction file at every session
start rather than merely clutter.

**The diagnosis is not "too much lives in the consumer".** Consumer-side content is three things, and
only one is disposable: what the plugin owns (already correct), what the repo owner wrote but built on
plugin concepts (the lenses, roster, routing, chains), and what is genuinely independent (the branch
taxonomy, the changelog convention, "never directly on `main`"). A teardown that deletes
indiscriminately would destroy governance and repo knowledge the owner authored — worse than leaving
clutter. The real defect is that the middle category is **woven in rather than bolted on**: 101
mentions spread through one file cannot be removed cleanly, one import pointing at one directory can.
And the third category needs rewording, not removing — "Derek opens the PR" turns a still-valid rule
into a reference to a character that no longer exists.

Recorded in the [family README](claude-code-plugins/claude-specialists/README.md) under **Removal: the
teardown gap**, next to the bootstrap path it is the counterpart to, with the measurement table, the
three categories, and the target shape (one seam for the plugin-shaped content, plugin-neutral wording
for the independent rules, a `specialists-teardown` beside `specialists-init`, and lens files off the
plugin path).

**A false claim corrected in the same pass.** The bootstrap section justified itself with *"a plugin
injects no main-loop context and edits no `CLAUDE.md`"*. The second half is true; the first is not — a
plugin can activate one of its own agents as the main thread via a root `settings.json`. That was
already established in [#215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215) and filed
there as a token-saving idea. It is more than that: a plugin-delivered Chris removes the `@`-import,
which is the worst artifact an uninstall leaves. Same problem from the other side, so #215 is
re-weighted rather than left in the backlog as a nice-to-have.

Nothing is built here. This records the requirement and the measurement so the next change does not
weave more content onto the path that has to be untangled — the cost of the seam rises with every
addition.
