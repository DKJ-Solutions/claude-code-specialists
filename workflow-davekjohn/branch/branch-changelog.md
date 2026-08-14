## `feat/adoption-is-its-own-page` changelog

### Branch title

adoption becomes its own page, and the install plumbing stops travelling with it

### Branch ID

20260814-212823

### Branch type

feat

### What does the change on this branch bring to main?

The structural half of inbound
[#664](https://github.com/DaveKJohn/claude-code-specialists/issues/664), whose live half shipped
separately in [#676](https://github.com/DaveKJohn/claude-code-specialists/pull/676). `INSTALL.md` and
`UNINSTALL.md` were 1,747 lines written for a GitHub developer who registers a marketplace and installs
plugins — and they travelled in full to a business marketplace whose readers install nothing and must
not try. **`plugins/ADOPTION.md` now carries the half that is everybody's**: run the bootstrap, verify
the orchestrator took the floor, write the roster and fill the lenses. The two plumbing pages moved to
the repo root.

**The seam is the audience, and it does not sit where #664 assumed.** The report proposed splitting the
adoption *section*, but two of the five steering lines it identified sit **inside** that section — its
Step 1 is enabling and installing. So the split runs between Step 1 and Step 2, not at a section
boundary, and the adoption page's step count went from four to three: the one it lost is the one that
has already happened for a reader whose organisation published to them.

**The publish set is now enforced by the folder boundary rather than by a list.** #664 proposed removing
an entry from `$PublishedPaths` in `publish-to-business.ps1`; there was no entry to remove, because that
list names **`plugins`** and publishes it whole. Moving the two pages to the root puts them outside every
published path without anything having to remember them. An exclusion list was the alternative and was
declined for the reason this repo already applied to `connectors/`: a list is silent about the third
plumbing page somebody adds later, while a folder boundary refuses it by construction.

**Two gates caught what the move broke, and one of them had written its own warning years' worth of
commits earlier.** The `$consumerDocs` list feeding checks 15 and 16 carries a comment saying that when
the adoption page was last renamed, *"the page renamed out from under `QUICKSTART.md` carries every
captured sample and measured figure these two checks exist for"* — and it happened again: the bootstrap's
closing line, the 4+15+2 counts and the verification snippet all travelled with the adoption half.
`ADOPTION.md` is in the list, and the fixture that exercises those checks was writing to a path nothing
reads any more.

**And one test turned out to be asserting about the wrong list.**
`cut-release-guardrail.tests.ps1` parsed the `$reservedRootMd` **literal** out of `cut-release.ps1` — but
that literal is the *fallback*, and this repo answers the `Get-ReservedRootMd` seam, so the value it was
checking is precisely the one that does not protect this repo's release. It failed here naming two files
that were correctly covered. The repair is not to add them to the literal: that default is the portable
one, and a consumer's root has neither file. It reads the seam now, and asserts that it did.

### Significance

#### Tier 0

A maintainer gets a shorter install page, an adoption page that stands on its own, and a release
guardrail that checks the list actually in force rather than the one that would be in force somewhere
else. The `$reservedRootMd` repair is the piece with a future: it would have kept passing while
silently guarding nothing.

**Score:** 3

#### Tier 2

A colleague on an organisation's own marketplace stops receiving 1,747 lines of install plumbing they
cannot act on, and receives instead a page written for exactly what they do have to do. Every public
consumer's bookmarks to `plugins/INSTALL.md` move — every link in this repo was repointed, but a
bookmark held elsewhere is theirs — which is the cost of the change and the reason it is worth stating
rather than burying.

**Score:** 4

### Pull Request

