## feat/1881-converge-bwj-floor

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Write down the ownership ruling (BWJ plugin by default, Dave, September 11 2026) and ship the first increment under it: the shared test harness both stores carry their own drifted copy of.

#### The ruling this branch implements

**Anything the two stores share goes to `dkj-policy-bwj`, unless it is obviously universal** (Dave,
September 11, 2026). #1881 named two candidate homes and said the split was the whole of the issue;
this is the answer, and the branch writes it down where a store reads it before shipping the first
thing under it.

### CREATE

- [x] The ruling, in
      [`plugins/dkj-policy/dkj-policy-bwj/README.md`](../plugins/dkj-policy/dkj-policy-bwj/README.md) --
      what it owns, the price it accepts, the two homes it does NOT touch (`dkj-subagents-shopify` for
      the theme mechanisms, and each store's own `repo-config.ps1` for the data), and what ships under
      it today.
- [x] **The second question**, in the same place: a store's own rule asks *"does the plugin provide
      this?"*, which is a one-repo question, so it is joined by *"is there a second store that needs this
      too?"*. #1881's own closing point, and the half that makes any of this stick.
- [x] The plugin's `policy, never mechanism` line widened rather than quietly broken -- the distinction
      that survives is copy-vs-dot-source, not prose-vs-code.
- [x] The first increment:
      [`scripts/tests/test-lib.ps1`](../plugins/dkj-policy/dkj-policy-bwj/scripts/tests/test-lib.ps1),
      the superset of the two stores' drifted copies, in English.
- [x] The repo-side reasoning in [Sylvester's lens](../.claude/specialists/lenses/05-15-extension.md).

### TEST

- [x] `scripts/tests/bwj-test-lib.tests.ps1` -- 39 passed, 0 failed. It holds the three ways this
      convergence comes undone: the superset (a later edit dropping one store's half is the divergence
      returning *inside* the plugin, where no consumer-to-consumer check can see it), the behaviour of
      the two mechanisms born from a false green, and the language.
- [x] It runs the lib in a **child process**, which is load-bearing: the lib defines `Assert-True` and
      `$script:Pass`/`$script:Fail` in its dot-sourcer's scope, PowerShell names are case-insensitive,
      and a suite that dot-sourced it would be asserting with the code under test.
- [x] `check-plugin-integrity.ps1` -- 0 errors. The new file is held to the ASCII rule and the parse by
      the same checks as every other `.ps1`.
- [x] The live sibling check re-read for the numbers quoted in the README (69 `ONLY-IN`, 19 `DRIFTED`,
      5 `ALIASED`).

#### What this branch deliberately does not do

The other four candidates are filed as
[#1886](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1886), each with its verdict under the
ruling, because each is a decision of its own size: `lint-brain.ps1` is a translation as well as a merge,
`plugin-scripts.ps1` is the one likely to earn the *obviously universal* exception, and the theme-archive
rules are really a `dkj-policy-bwj`-against-`dkj-subagents-shopify` question. And the class found while
reading for the ruling -- a consumer carrying its own copy of something a plugin **already** ships, which
no check here can report -- is [#1885](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1885).

### DEPLOY: feat/1881-converge-bwj-floor

`dkj-policy-bwj` now states which mechanisms it owns, and ships the first one: the test harness the two
BWJ stores were each maintaining their own drifted copy of.

The sibling check landed a day earlier and reported 93 findings without being able to act on any of
them, because acting needed one decision nobody had made -- which plugin owns a mechanism two stores
both need. The answer is BWJ by default, and the price is stated rather than hidden: `dkj-policy` stays
thinner than it could be, and the two stores get a BWJ-only copy of things that are arguably universal.

The harness was chosen as the first increment because it is the case where merging is a decision rather
than a diff. Each store's copy was ahead of the other -- one had the two mechanisms born from a false
GREEN in the very gate these suites are read by, the other the three-legged plugin-loaded check, and it
was still in the language the first had been translated out of a month earlier.

Beside the ruling sits the question that makes it stick: a store's own rule asks *"does the plugin
provide this?"*, which with a structural N of two answers "no duplication" right up until somebody opens
the other repo.

**Score:** 4

#### What makes this deploy extra special

For the two BWJ stores this is the first mechanism they stop maintaining twice, and the README tells
them how to adopt it -- one forwarder, no suite changes. For every other consumer of this marketplace
the answer is N/A by design: the ruling exists precisely so that a mechanism two stores need does not
arrive in the plugin everybody runs.

**Score:** 3

#### Pull Request

Converge the BWJ store floor: dkj-policy-bwj owns what the two stores share

