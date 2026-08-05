## A shared parser's change is probed against a consumer's document, not only this repo's

### What does this change do?

One hard rule added to [Sylvester #15's portable manual](plugins/specialists/manuals/05-15-manual.md):
**when a shared script changes what it recognises, probe it against a consumer's document.** A shared
script reaches a consumer through a plugin update rather than by their choosing, so a parser that has
learned a new shape meets their *old* one first — and the source repo is the worst possible place to
notice that, because it is the one repo that has already migrated. Its own files are the new shape by the
time the change is finished, and every test written alongside the change uses the new shape too.

**The rule names the failure mode, which is silence rather than an error.** A parser handed a shape it was
not written for produces a confident, well-formed, wrong answer, and the gates that might have caught it
are often reading that same answer.

**The measured instance is [#476](https://github.com/DaveKJohn/claude-code-specialists/pull/476),** where
`CHANGELOG.md` became one flat list of `##` entries. Probed against a consumer still on the pre-flat shape,
their `## Pull Requests` heading parsed as ONE entry swallowing every real entry and `## Releases` as a
second — so their whole release history would have been published into the release notes and the
per-plugin CHANGELOGs as a "change", and then deleted from `CHANGELOG.md`, because the cut keeps only the
intro. **And nothing refused:** blocks like that declare no impact, so the bump gate read the repo as never
having adopted the tier model and reported itself *inactive* — correct by its own rule, and the reason the
release would have proceeded. Found by building a synthetic consumer while scoring that branch's own entry,
not by a failing suite. The guard that now refuses it shipped in the same PR.

**And it states what makes the repair safe**, which is the half easiest to get wrong: a refusal that will
fire in repos you cannot see needs an *exact* discriminator, not "looks wrong". Name the shapes that are
legitimate, check that each declares something the old shape cannot, refuse the rest before writing
anything, and name both the offending part and the migration. A refusal that can fire on a legitimate
document is worse than the defect, because it arrives in someone else's repo.

**It goes to the portable manual rather than to this repo's lens**, per the August 4, 2026 rule: the source
is the default destination and the lens is the exception that needs a reason. Nothing about this rule is
specific to this repo — any repo maintaining scripts that travel to consumers meets it — and a portable
rule filed in a lens is not wrong anywhere, it simply never arrives.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 1 | 3 | a colleague changing a shared script now has the check written down instead of rediscovering it the way this one was rediscovered -- noticed the moment they touch that part |

### Type of change

Docs
