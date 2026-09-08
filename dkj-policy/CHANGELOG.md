# Changelog

Everything merged since the last release sits under **`## [Unreleased]`**, **newest first**: **one `###` per
change**, and under it two named `####` sections. The `###` heading is the change's own —
`` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `#### What makes this deploy extra special` for the second audience, and `#### Pull Request`.
Every level here moved one deeper on August 26, 2026, when the pending section above them was introduced and
the development cycle beside them shifted to match; entries written before that day carry the whole set one
level shallower and are read exactly as they always were.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
[`releases/history.md`](releases/history.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`dkj-policy/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

**The line directly under `## [Unreleased]` is a tally, and nobody types it.** It reads
`**4 / 9 minor entries**`: how many of the pending entries reach the audience this repo publishes to, out of
how many are waiting for the next release, and which bump that work has earned. The two numbers answer
different questions and may differ — the fraction counts tier 2 and above, the bump follows tier 1 and
above — so `**0 / 8 minor entries**` says nothing reaches a subscriber while the version still owes a minor
for what reaches management. It is
**derived from the entries below it every time it is written**, by the fold that adds one and the cut that
removes them all, so it holds no state of its own and a hand-edited count is simply corrected on the next
fold. It ends with an HTML comment that marks it as machine-written; that marker is what the next run
replaces, so anything else written in this space is left alone.

---

## [Unreleased]

**0 / 1 patch entry** <!-- pending-tally -->

### DEPLOY: fix/1562-origin-remote-redirect · 20260907-211130

The repo-citation section of `CLAUDE.md` now covers the layer it could not reach: a checkout's own
`origin` remote. A checkout cloned before the September 2, 2026 transfer still pushes to
`DaveKJohn/claude-code-specialists.git` and succeeds only because GitHub answers `remote: This
repository moved` — every push of the `v4.32.0` cut did exactly that. The note names the
one-command repoint (`git remote set-url origin
https://github.com/DKJ-Solutions/claude-code-specialists.git`) and ties the fragility to the same
condition the prose rule already carries: the redirect holds only while nothing is created at the
old path.

**Score:** 1

The failure this prevents has not happened: pushes from un-repointed checkouts still work today. It
bites the day anything is created at `DaveKJohn/claude-code-specialists` — every such checkout's
pushes then fail with no redirect to catch them, and nothing in the tree points at the cause.

#### What makes this deploy extra special

N/A — an internal documentation note. A subscriber of the service never sees a repo remote URL.

**Score:** N/A

#### Pull Request

Note the origin remote fix for checkouts still on DaveKJohn/

[PR #1563](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1563)

---

