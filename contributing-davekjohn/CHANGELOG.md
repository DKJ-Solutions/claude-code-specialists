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

### DEPLOY: `fix/new-branch-remote-resume-v1` · 20260830-135427

`new-branch` now resolves *resume or cut* by reading **both** ref namespaces before it acts, so a branch
that exists only on `origin` is resumed at the remote tip with tracking instead of being forked at the
current base. That branch is this workflow's own cross-device handoff -- `new-branch` pushes by default
and `cycle-autopark` keeps it current on the remote -- so the script documented as idempotent, the one you
are told to re-run to resume, was the one that could not see the branches the flow produces. Nothing on
screen said so: the run reads clean because idempotence promises a clean run, and the scaffold written
into the fork is byte-identical to the one on the parked branch because the same script wrote both. What
was missing was the branch's work. `worktree-lane.ps1` inherited the whole failure through its
delegation and reported `Lane open` as on a genuine new branch.

The run now names which of the three things it did, and says the name is taken and to type `-v2` if a new
branch was meant -- a resume is adopted, never adopted silently. In the same movement the #1046 base
warning moved behind that question: its count is `HEAD..origin/<trunk>` measured before the checkout, so
on a resume it was handing over the trunk's gap under the resumed branch's name. A cut is still warned,
with the count, twice.

**Score:** 4

#### What makes this deploy extra special

`new-branch.ps1` is mirrored into every consumer's plugin cache, and the parked branch is their
cross-device handoff too -- so this is the fix arriving where the failure was silent and the work simply
was not there. The skill page that told them the script is idempotent now states all three shapes it
actually has.

**Score:** 3

#### Pull Request

new-branch resumes a branch that exists only on origin

Plugins: contributing-davekjohn

[PR #1141](https://github.com/DaveKJohn/claude-code-specialists/pull/1141)

---

