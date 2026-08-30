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
[`contributing-davekjohn/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## [Unreleased]

### DEPLOY: `fix/prune-merged-no-checkout-borrow-v1` · 20260830-152559

`prune-merged` no longer takes the checkout. Step 2 used to `git checkout <trunk>`, `git pull --ff-only`, and
hand the checkout back -- and a borrow returned within the second is still a tree that moves under whatever
else is running in the same checkout. That is the cause measured in
[#1145](https://github.com/DaveKJohn/claude-code-specialists/issues/1145): a file present on the branch and
absent on the trunk vanished and reappeared under a running test suite, turning a green gate red. It now
advances the trunk with `git fetch <remote> <trunk>:<trunk>`, which writes a local ref that `HEAD` is not on
and moves no working tree at all; the fast-forward guarantee is git's own, since it refuses a non-ff into
`refs/heads/` unless the refspec carries a leading `+`. A run already standing on the trunk keeps
`git pull --ff-only`, because git will not fetch into the checked-out ref.

**One move survives, and it cannot collide.** `git branch -d` can never delete the branch `HEAD` is on, so a
start branch that is *provably merged* is stepped off first -- announced where it happens, and the run then
ends on the trunk naming the sha it left. A branch under a running gate is unmerged by definition, so it
never reaches that line: what is left moves the tree only on work that is already finished.

**And the [#1069](https://github.com/DaveKJohn/claude-code-specialists/issues/1069) refusal went with it.**
A second worktree holding the trunk used to make the checkout impossible clone-wide, so this script refused
outright -- unavailable in exactly the situation that produces stray branches. git will not write a
checked-out ref either, but now that costs only the fast-forward: the run continues against the older trunk,
which errs towards *keeping* branches, and the warning still names the lane and how to release it. #1145's
detection stays untouched, because it is the right repair for the class and every other tree-mover in the
clone is still there.

**Score:** 3

#### What makes this deploy extra special

The workflow tells a consumer's session to run `prune-merged` mid-assignment and to background `ship-pr` so
the session can get on with something else -- two instructions that quietly collided in the shared checkout.
One of them stops colliding here, so a consumer gets fewer false reds from their own tooling without changing
anything they do. Their `prune-merged` also works in a state where it used to refuse: with a lane standing on
the trunk, it now reports instead of stopping.

**Score:** 3

#### Pull Request

prune-merged fast-forwards the trunk without borrowing the checkout

Plugins: contributing-davekjohn

[PR #1149](https://github.com/DaveKJohn/claude-code-specialists/pull/1149)

---

