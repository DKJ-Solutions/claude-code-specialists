### the record names a commit, and the clone tracks main · Docs · 2026-08-01

Closes inbound [#313](https://github.com/DaveKJohn/davekjohns-workshop/issues/313), the heaviest of round
v8's three findings (overview: [#316](https://github.com/DaveKJohn/davekjohns-workshop/issues/316)).

**A consumer runs `main`, not the release, and every documented way of asking said `3.0.8`.** Round v8
measured a consumer that had moved `3.0.6 → 3.0.8` with no command run and landed three commits past the
`v3.0.8` tag. `plugin.json` reads `3.0.8` on both commits, so the version string cannot express the
difference — while the payload genuinely differed (the same `SKILL.md` hashed differently on the tag and in
the installed cache), and `3.0.7` was never cached at all, so that release's fixes were skipped over
entirely. `gitCommitSha` was the only field that could tell the two apart, and it appeared **nowhere** in
the payload.

**Both printed record queries now name the commit** — step 0c in `specialists-init/SKILL.md` and step 1 in
the QUICKSTART — with the reading a user needs beside them: `version` identifies the *release*,
`gitCommitSha` identifies the *code*, they can disagree, and when they do only the second is true. Step 0c
also carries the one-line `git rev-list` that settles which of the two you are on.

**And the mechanism is now recorded as measured rather than suspected, which is more than the issue could
establish.** The issue proposed saying "the clone tracks `main`"; that has since been verified directly —
the cached marketplace clone has `main` checked out, tracking `origin/main` — and the *documented*
two-command update procedure was run deliberately in this repo, producing the identical state
(`version 3.0.8`, sha on `main`). So this is not an artefact of an unknown scheduler: **the documented
update path cannot deliver a tagged release, because the source it reads is a branch.** Every commit merged
after a release ships to consumers immediately under the previous release's version number. The opening
line of *Staying up to date* said updates "reach you via releases" and now says what releases actually do
(announce) versus what lands (whatever `main` holds).

Two consequences spelled out for consumers, because both change how a reader should act: the family's own
discipline of *"pin source locations against the release tag"* does not hold inside a consumer, so pin
against the sha the record names; and a bug that will not reproduce against the tag may still be real,
because you were never on the tag. What stays open is deliberately marked open: that a refresh moves you to
`main` is settled, but what *triggers* an unasked refresh is not, and that half is CLI behaviour rather
than plugin code.
