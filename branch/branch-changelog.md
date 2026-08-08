## `feat/one-changelog-for-the-product` changelog

### Branch title

One changelog for the whole product

### Branch ID

20260808-161512

### Branch type

feat

### What does the change on this branch bring to main?

The per-plugin `CHANGELOG.md` and `RELEASE.md` card are gone — ten files, **11,684 lines** — together
with the three functions that generated them, the two lint checks that policed them, and the tests
that covered both. The repo has become the product, so it has **one** changelog. Decision by Dave,
August 8, 2026.

**The premise was measured before anything was deleted, because the whole case turns on it.** Those
files existed on the reasoning that the plugin cache is all a consumer has, so a history had to travel
*inside* it. That is not how a consumer receives this repo: the marketplace source is a **git clone of
the whole repository**, so `CHANGELOG.md` and the complete `releases/` tree already sit in every
consumer's `~/.claude/plugins/marketplaces/claude-code-specialists/`. The ten files were a second copy
of a record the reader always held — and, being a copy, free to disagree with it. Checks 9 and 17
existed for exactly that disagreement: one guarded that a plugin's version was stated identically in
two places, the other that a write-once intro had not drifted from its generator.

**Both checks were correct, and both dissolved rather than being weakened.** That is the shape worth
keeping from this change: *a check that compares two statements of one fact is made unnecessary by
deleting one of them, and that is a better outcome than a better check.* The measured history backs it
— check 17 was built in August 2026 after all four intros were found still naming a marketplace that a
rename had swept out of 59 files, and the card had to be corrected the week before that because it
claimed *"You are on this release"*, which a document written at cut time cannot know.

**What deliberately survives.** The **lockstep version bump** is untouched: `plugin.json` is still the
one place a plugin's version lives and still moves for all five together, because a consumer running
group 1 alongside group 3 needs matching versions. `Get-ReleasePluginTier` therefore still returns
`$true` — "the cards are gone" is not "the plugin tier is gone". The `Plugins:` line the fold derives
also stays: the release notes read it, so it was never only for the removed files.

**And the answer a consumer needs is now stated where it is actually true.** "Which release am I on?"
is answered by the `version` in the cached `<plugin>/.claude-plugin/plugin.json`; "what changed?" by
the root `CHANGELOG.md` and `releases/`, in the clone they already have. Both README sections,
`INSTALL.md`'s *Staying up to date*, and `releases/README.md`'s cut description were pointing readers
at the retired files and now point at these.

Lint gate 0 errors; all 27 suites green in 127s.

Plugins: specialists, specialists-lifehub, specialists-shopify, specialists-ecomm, specialists-workflow-davekjohn

### Significance

#### Tier 0

Two lint checks, three generator functions, one link rewriter, two fixture helpers and roughly 12,000
lines of generated document leave the tree, and the release cut loses a whole step. A maintainer
touching `release-lib.ps1` or the lint gate meets a materially smaller surface. Against that, nothing
they do daily changes: the fold, the entry format and the bump are as they were.

**Score:** 3

#### Tier 1

The generalisable lesson is about check design rather than about these files: when a gate exists to
keep two copies of one fact agreeing, ask whether the second copy has to exist at all. Both retired
checks were sound, well-tested and born from real measured defects — and all of that was downstream of
a duplication nobody had questioned. Recorded in Sylvester #15 so the next such gate is weighed before
it is built.

**Score:** 3

#### Tier 2

A consumer loses two files from every plugin folder in their cache, one of which — `RELEASE.md` — was
the thing the docs told them to open after an update. Nothing breaks and no action is required: the
history they were reading is one directory up in the same clone, and their version is in
`plugin.json`. But anyone who bookmarked the card notices the moment they next look for it, which is
what puts this in the middle of the band rather than at the bottom.

**Score:** 3

### Pull Request
