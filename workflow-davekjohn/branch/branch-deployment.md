## `fix/sync-content-provenance` deployment

### What does the change on this branch deploy to main?

The Shopify pre-task sync stops deciding who wins a file by **when** the trunk last touched it and starts
deciding by **whose content live is holding**. Reported as inbound
[#807](https://github.com/DaveKJohn/claude-code-specialists/issues/807); the report's urgent half
(`--no-merges` on the floor lookup) was already repaired on `main` by
[#801](https://github.com/DaveKJohn/claude-code-specialists/issues/801) and this is the second half it
named as the next release.

The old rule was the **wrong measurement** rather than a buggy one, and that is why repairing the floor
could not have been enough. Nothing pushes the trunk *to* live except the per-file release step, and a
deletion cannot be pushed that way at all -- so the trunk's changes are permanently invisible to live and
sink below the floor as soon as one more sync commit lands. From that moment on, every future sync tries to
overwrite them again, forever.

What replaced it:

> Has this path ever held live's content in the trunk's history? Then the trunk wins. Otherwise live wins
> -- and if the trunk also changed it, nobody wins and a human looks.

`scripts/lib/sync-rules.ps1` gains five functions for that (`Get-GitRawBlobId`, `Get-CrStrippedBytes`,
`Get-GitStoredBlobId`, `Test-LiveContentIsOurs`, `Get-SyncFileVerdict`) and `scripts/task/sync-main.ps1` is
rewritten around them. **The floor survives, demoted:** its only remaining job is to notice that live's
content is foreign *and* the trunk changed the same path recently -- both sides moved -- and refuse. A
wrong floor now costs an extra conflict report instead of silent data loss.

Three structural changes make the script unable to destroy work rather than merely unlikely to:

- **Live is pulled into a mirror outside the repo**, and the working tree is written only for the paths
  whose verdict is `take-live`. The wholesale version pulled over the tree and then restored what it should
  not have taken, so every bug in the rule was a bug that had *already* overwritten the file.
- **It never deletes.** A path the trunk has and live does not is reported, not acted on.
- **The branch name is decided before the pull**, so a collision stops the run while the tree is clean.

`-DryRun` is new and is the first thing to run: every verdict, nothing written, and allowed on a dirty tree
because that is exactly when somebody wants to ask what the sync would do to it. `-MirrorPath` and
`-KeepMirror` come with it. **`-SkipPull` is retired** -- it meant "run the rule over the working tree",
which cannot mean anything now -- and is still accepted so the refusal can name what replaced it.

**Two mechanisms in the reference implementation were verified against git rather than adopted on trust,
and one of them was broken.** `git check-ignore --stdin <paths>` answers `fatal: cannot specify pathnames
with --stdin` and exits 128, which the quiet wrapper swallows -- so that filter silently reported nothing
ignored, and a repo ignoring `config/settings_data.json` would have captured live's copy as foreign drift
on every run. Feeding real stdin is not available either: Windows PowerShell 5.1 does not connect a
pipeline to a native executable's stdin here and has no `<` redirect. The batched argument form is what
ships, with a test that proves it. `git ls-tree --format` was the second: it needs git 2.36, and the
default output carries the same fields behind a tab, so this reads the default.

**A third came out of writing the comparison rather than out of the report**, and it fails in the losing
direction: git quotes any path holding a byte above `0x7F`, so an accented theme filename arrives from
`ls-tree` as `"assets/caf\303\251.js"` and matches nothing the mirror walk produces. The trunk's copy would
read as a path live does not have while live's *identical* file read as content the trunk has never held --
foreign, taken, trunk overwritten. `core.quotePath=false` on both path queries fixes it, and the assert
that pins it was checked the only way worth checking: with the flag removed again, where it fails.

The two suites grew from 24 to **78 asserts** together. The headline case is `ours/buried`, which is the
whole change in one fixture: the trunk fixed a file, a later sync commit buried the fix below the floor,
and live still holds the trunk's old copy. It asserts both halves -- that the content rule holds the file
back, *and* that the time rule has already lost it -- so the fixture cannot rot into agreeing with itself.

**Score:** 4

#### What makes this change extra special

For a consumer running `sync-main.ps1`, this is the difference between a sync that protects merged work and
one that reverts it on every run until somebody notices. And "merged but not live yet" is not an edge case
there: it is a **designed** state, which is what a pending `CHANGELOG.md` entry means -- so adopting this
marketplace's changelog model is what made the naive sync strictly more dangerous in the first place.

It was measured both ways in `xoxowildhearts` before it was built, and the false-negative half is the one
that matters, because a rule that is safe by capturing nothing is useless. Against live on 2026-08-21: 31
differing files, all 31 content that repo has held, so the new rule captures **zero** -- correctly, since
there was no third-party drift, only the trunk having moved forward. The old rule captured all 31 and was
about to revert three merged PRs. Replayed over every past "from live" commit: **10 of 11** real drift
files come back foreign and are captured; the 11th reverted a single trailing blank line.

Two Shopify consumers load `team-shopify`, and only one of them has a local repair plus the temporary
`PreToolUse` hook that routes its sessions away from the shipped skill. The other runs the shipped copy as
it stands. That hook is marked temporary in its own header with its removal condition stated -- an
installed `team-shopify` that ships the repaired rule -- which is this.

**Score:** 5

### Pull Request

The Shopify pre-task sync decides by content provenance instead of a time window
