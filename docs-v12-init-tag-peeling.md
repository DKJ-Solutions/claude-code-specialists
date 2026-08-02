### The cached clone does carry tags, and annotated ones invert the answer · Docs · 2026-08-02

Test round v12's [#372](https://github.com/DaveKJohn/davekjohns-workshop/issues/372), against the #322
block in the `specialists-init` skill. Two things, and the second is the one that matters.

**The "no tags" clause was false, and it survived a round after being reported.** The bullet read the
fetch refspec `+refs/heads/main:refs/remotes/origin/main` as proof that the cached clone carries no tags.
The refspec governs later *fetches*; the initial `git clone` still brings along every tag pointing at
history it fetched. Both clones measured this round had them — a fresh one carrying `v3.1.1`, an older one
carrying 66. The block already contradicted itself on this point, since the very next bullet says the tag
set *"is frozen at whatever came along when the clone was created"*, which only makes sense if tags come
along at all. The clause is gone, and the other place that leaned on it (*"a shallow, tag-less clone"*) is
corrected with it.

**The substantive half of #322 was genuinely fixed, and the repair has a hole the original never
considered.** The block names two outcomes for resolving a tag locally: it matches, or you get
`fatal: ambiguous argument`. There is a third. This family's release tags are **annotated**, so
`git rev-parse v3.1.1` returns the *tag object* (`12b2d1b`) rather than the commit (`4b1a74d`). On a clone
sitting exactly on the release commit, the comparison therefore **succeeds** — no error, no missing tag —
and hands back a sha that does not equal `HEAD`.

That is the same inversion #322 was filed about, reached from the opposite side. The old failure mode was
*the tag is absent, so the failure reads as "not the release"*; this one is *the tag is present, peels, and
the mismatch reads as "not the release"* — while the reader is standing on it. And the false "no tags"
clause actively fed it, by telling the reader the comparison was impossible on a machine where it will
quietly run and lie. Both facts were verified against this repo before writing rather than taken from the
report: `git cat-file -t v3.1.1` returns `tag`, and `v3.1.1^{}` peels to the commit `HEAD` was on.

The third outcome is now named, with the measured triple, and the instruction is explicit: if you resolve
a tag locally at all, peel it with `^{}`. The `gh api …/tags` route is noted as immune — its `.commit.sha`
is the commit already.
