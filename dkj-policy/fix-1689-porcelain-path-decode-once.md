## fix/1689-porcelain-path-decode-once

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
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

Move `Convert-GitQuotedPath` into `git-porcelain-lib.ps1`, have `sync-main` dot-source it, and let
`ConvertTo-GitPorcelainPath` return the decoded path.

#### The repair the issue proposed was refused by the file it named

#1689 (which this session filed while shipping #1682) said *"have `sync-rules.ps1` dot-source it"*.
Reading `sync-rules.ps1`'s own registry entry refuses that outright:

> **DEPENDENCY-FREE, and specifically NOT a reader of `repo-config.ps1`**: the live-theme guard
> dot-sources that file on every command inside a catch that returns no live theme id, so anything it
> pulls in is a way to silently disarm the guard.

So a dot-source added there is a way to disarm a guard over a revenue-serving Shopify theme, and even
a `Test-Path`-guarded one leaves `Convert-GitQuotedPath` undefined in the absent-file case — which puts
`sync-main` back at inbound #821's failure (foreign, taken, trunk overwritten), silently. It would also
be a **cross-plugin** dot-source, which `sync-main.ps1` already rules out by name for `merged-pr-lib`.

**What made the repair possible instead: `sync-rules.ps1` never CALLED the function it defined** — one
occurrence in the whole file, the `function` line. So it lost it outright and its dependency-free
property is *preserved* rather than traded. The corrected reasoning is a comment on #1689 as well, so
the issue and the branch do not disagree.

### CREATE

- [x] `Convert-GitQuotedPath` moved from `sync-rules.ps1` into `git-porcelain-lib.ps1`, verbatim, with
      a note left at the old site saying where it went and **why it must not be dot-sourced back in**.
- [x] `sync-main.ps1` dot-sources `git-porcelain-lib.ps1` directly and **unguarded** — the same shape,
      and the same stated reasons, as its existing `merged-pr-lib` and `native-capture-lib`
      dot-sources: a payload missing the file must fail at load, not mis-decode quietly.
- [x] A **second registry mirror**, `git-porcelain-lib-shopify` → `dkj-team-shopify`, on
      `native-capture-lib-shopify`'s and `merged-pr-lib-shopify`'s precedent. Both plugins are
      separately versioned and separately installed, so one file mirrored twice beats a cross-plugin
      path that a version mismatch breaks without a word.
- [x] `ConvertTo-GitPorcelainPath` now decodes a quoted path. The two arms stay **split**, not chained:
      the decode can legitimately return a real backslash (git escapes one as `\`), so running the
      separator normalisation afterwards would put #1682's lesson 4 straight back one layer along.
- [x] `Get-WorkingCopySnapshotFormat` bumped 1 → 2. The serialised *shape* is unchanged and the entry
      **keys** are not: a pre-change baseline holds `caf/303/251.txt` where a post-change one holds the
      real filename, so across the two the old key reads as vanished and the new one as growth — and
      growth is silent by design. That is exactly the false alarm the version exists to refuse.
- [x] `fanout-lib`'s **"THE RESIDUAL LIMIT"** paragraph retired rather than ignored. It stated the
      escaped form as a deliberate trade, and the trade was between *escaped* and *console-decoded* —
      the only two options inbound #821 had. A byte-level decode downstream of the wire is a third one,
      and it is not exposed to the code page the trade guards against.
- [x] The plugin README row for the lib rewritten: three callers now, and the second mirror named.

### TEST

- [x] The decoder's ten asserts **stay in `sync-rules.tests.ps1`**, which now dot-sources the porcelain
      lib. They stayed because the comment above them explains why they are unit asserts *in that
      suite*: the property they pin is one `sync-main.tests.ps1` cannot pin without mutating the shared
      console state, and moving them would separate that reasoning from the sibling suite whose console
      flip produced the original flakiness. A test script may depend on what `sync-rules.ps1` may not.
- [x] `git-porcelain-lib.tests.ps1` owns the other half instead of a second copy of those ten: the
      escape now decodes through `ConvertFrom-GitPorcelainLine`, both halves of a rename decode, the
      decoder is asserted to be defined by **this** lib, and a real backslash in a filename survives
      the decode without being normalised. 54 asserts.
- [x] `sync-main.tests.ps1` gains the mirror guard the file already had for `native-capture-lib` — the
      one thing `build-shared-scripts -Check` structurally cannot catch, since a missing entry is a
      pair it never looks at. Plus: the dot-source is present, it is **unguarded**, and
      `sync-rules.ps1` neither defines the function nor dot-sources the lib. 141 asserts.
- [x] Green: `git-porcelain-lib` 54, `sync-rules` 152, `sync-main` 141, `fanout-lib` 86,
      `park-cycle` 91, `shared-scripts` 636. Lint gate 0 errors.
- [x] No fixture needed the #1693 treatment this time, and that was checked rather than assumed:
      `sync-main.tests.ps1` runs the script **in place** from the repo root, so its dot-sources resolve
      against the real `scripts/lib/`. No suite copies `sync-main.ps1` or `sync-rules.ps1` into a
      fixture tree.
- [x] The lint gate and every suite, via `open-pr.ps1`.

### DEPLOY: fix/1689-porcelain-path-decode-once

Reading a git path now happens in one place. `Convert-GitQuotedPath` — which decodes git's C-quoted
form, escape by escape, into the real filename — has moved out of `sync-rules.ps1` and into
`git-porcelain-lib.ps1`, beside the `core.quotePath` flag that produces the form it decodes. So the
porcelain reading no longer stops one step short: `park-lib`, `fanout-lib` and `sync-main` all get the
readable path, and `fanout-lib` loses a limit it had written down as permanent.

**The move went in the opposite direction from the one #1689 proposed, and that is the substance of the
change.** `sync-rules.ps1` is dependency-free on purpose — the live-theme guard loads it on every
command inside a catch that returns no live theme id — so making it dot-source anything is a way to
disarm that guard silently. It never called the function it defined, so it could lose it instead, and
`sync-main.ps1` takes the lib directly, unguarded, exactly as it already takes two others.

**Score:** 3

#### What makes this deploy extra special

N/A — nothing a consumer of the plugins notices, provided the release carries both mirrors, which is
what the new `sync-main.tests.ps1` assert exists to prove. A consumer running `dkj-team-shopify`
without `dkj-policy` gets the lib from its own plugin's payload; the readable path in a sync report is
the only visible difference, and reports are not a published surface.

**Score:** N/A

#### Pull Request

Reading a git path lives once: the quoted-path decoder moves into git-porcelain-lib
