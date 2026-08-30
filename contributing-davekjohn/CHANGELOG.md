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

### DEPLOY: `fix/major-advice-inherits-its-condition-v1` · 20260830-163736

The new-major guardrail's closing sentence no longer counts an edit a repo may not have. The advice refuses
a `X.0.0` cut whose history section does not exist yet, prints the heading to add, and then says the pin in
a test has to be repointed too -- *IF* this repo pins the targeted major, capitalised, because the pin is
repo-owned. The sentence after it took that back: *"Both edits belong to this cut"* counts two, so a reader
who had correctly concluded the pin paragraph was not theirs was told one line later to make a second edit,
and went looking for it. It now reads *"The section edit belongs to this cut, and the pin with it if this
repo has one"* -- naming the edit rather than pointing back at one, and taking the plural with it -- and two
assertions hold it there from both sides: the count must not return, and the condition must not be dropped
in its place. **The `cut-release` skill page carried the same contradiction** around its own conditional
bullet, and it is repaired in the same movement.

This repo has the pin, so its own maintainers read the sentence that was true. The failure this prevents is
the one this repo cannot meet: it lands entirely on a consumer, which is why the fix is in the shared script
rather than in a lens.

**Score:** 1

#### What makes this deploy extra special

A consumer opening their first major meets this refusal at a milestone moment, having just been told the
step is manual because it is deliberate. Until now the message ended by contradicting its own conditional
one line earlier, sending a reader with no pin to hunt for a second edit that was never theirs. Measured on
the documented path in a fresh consumer: after adding the section alone -- one edit, no pin -- the re-run cut
`v1.0.0` cleanly, so the conditional reading was the correct one and the closing sentence was simply wrong
for them.

**Score:** 2

#### Pull Request

The new-major advice's closing sentence inherits the pin condition

Plugins: contributing-davekjohn

[PR #1155](https://github.com/DaveKJohn/claude-code-specialists/pull/1155)

---

### DEPLOY: `fix/major-refusal-names-the-seam-v1` · 20260830-161529

The release cut's major refusal now names the seam that lowers its threshold. It always answered two of the
three questions a reader arrives with -- what the threshold is, and how many minors this major line has had
-- and left the third with two routes: *"cut the minor this work earns instead"*, correct where the bump was
simply wrong, and `-SkipTierGate`, the bypass, named in full. `Get-ReleaseMajorMinMinors` was in neither, so
the repo the seam exists to serve met a hard refusal with no configuration-shaped answer on offer and the
bypass as the nearest thing to one -- the worse of the two outcomes, because it overrules a content
judgement that was correct where answering the seam produces a correct release. The refusal now carries a
third clause naming the function and `scripts/repo-config.ps1`, and two assertions pin it.

This repo's own threshold of `10` is measured against its own history -- the 1.x line ran to 1.18 and the
2.x line to 2.16 before each was recapped -- so its maintainers will not meet this refusal wrongly. The
failure it prevents here is one that has not happened yet: a maintainer reading the refusal on a slower line
and reaching for `-SkipTierGate` because it is the only knob the message offers.

**Score:** 1

#### What makes this deploy extra special

A consumer that cuts minors rarely is precisely who this threshold is not measured for, and until now the
refusal it meets pointed only at the bypass. That consumer now reads, in the refusal itself, the one thing
that turns it into a correct release: set `Get-ReleaseMajorMinMinors` in their own `scripts/repo-config.ps1`.
The seam was always discoverable in `CONTRIBUTING-portable.md`, the `cut-release` skill page and the contract
registry -- and a person meeting a refusal reads the refusal. This is the only class of refusal in this
workflow whose remedy is a configuration value rather than an act on the branch, so it is the one that has to
carry the seam's name in the message.

**Score:** 3

#### Pull Request

The major refusal names the seam that lowers its threshold

Plugins: contributing-davekjohn

[PR #1154](https://github.com/DaveKJohn/claude-code-specialists/pull/1154)

---

### DEPLOY: `fix/fresh-adoption-note-root-agrees-v1` · 20260830-155244

`adopt-workflow-folder` no longer scaffolds a directory the release cut will not use. It resolves
`Get-ReleaseNoteRoot` through the seam -- the same treatment the changelog and history roots beside it
already got -- and **writes the answer into `scripts/repo-config.ps1`** where, and only where, all three
of these hold: the lib exists, it defines no answer, and no hand-written note sits at the shared
`releases/notes` fallback. That is the freshly scaffolded repo and nothing else; every other repo is
reported and left untouched. The `releases/audience/.gitkeep` is gone, its stated premise having turned
out to be false -- `cut-release.ps1` creates the note's parent directory itself -- and the scaffolded
pages now name whichever root the seam actually resolves to instead of asserting one flatly.

This is the first `decide` seam any command in this workflow answers on its own, and the three
conditions are the whole safety argument: `adopt-config` never places one because copying the source's
answer would assert something about a repo it merely *found*, whereas this run **creates** the folder.

**Score:** 3

#### What makes this deploy extra special

A consumer who adopts the folder and then cuts a release gets their release note inside the folder the
adoption just built, instead of at `releases/notes/` in the repo root with the history table linking back
out to reach it -- and without an empty committed directory promising a destination nothing wrote to.
Reported from a testrun that followed the documented path literally (#1150), where every individual step
behaved as documented and the two halves of one run still disagreed. Nothing changes for a consumer who
already answered the seam or already has notes on disk: their answer wins, and nothing is ever moved.

**Score:** 3

#### Pull Request

A fresh adoption's note root and its scaffolded folder now agree

Plugins: contributing-davekjohn

[PR #1153](https://github.com/DaveKJohn/claude-code-specialists/pull/1153)

---

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

