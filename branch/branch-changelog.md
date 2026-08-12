## `docs/source-repo-script-path` changelog

### Branch title

Say which copy of a shared script to run when you are in the source repo

### Branch ID

20260812-193855

### Branch type

docs

### What does the change on this branch bring to main?

Every `workflow-davekjohn` skill page now states, beside the command it prints, that the source repo runs
its own copy under `scripts/` — and why. The pages print `${CLAUDE_PLUGIN_ROOT}/scripts/…`, which is the
only path that resolves for a consumer, and **the harness expands it to the reader's own plugin cache
before the page is read** — so a maintainer standing in this repo is handed an authoritative-looking
command pointing at the last *released* mirror, which lags this repo by however many merges have landed
since. Ten pages said nothing about that; one (`cut-release`) said the repo path "works as before", which
reads as a permission where it is a requirement.

**Measured on August 12, 2026 against mirror `4.5.0`, and both failures are silent.** `new-branch`
scaffolded the retired three-tier ladder instead of this repo's `Tier 0` + `Tier 2` and rewrote
`branch/templates/branch_template_changelog.md` back into the pre-audience shape; `session-status`
reported no release note under `releases/notes/` and therefore printed an empty "what the last release
left open" block. The cause is not configuration: the mirror contains **no `Get-ReleaseAudienceTier` and
no `Get-ReleaseNoteRoot` at all**, so each silently fell back to its pre-seam default. A third instance
was produced by the session that wrote this entry, on its own first command.

Two things were deliberately *not* done. The printed command is unchanged, because lint check 22 forbids
an absolute path in a shipped page's `-File` argument and the mirror path is the correct one for the
reader those pages are written for — the source-repo case is added beside it, never in place of it. And
re-syncing or bumping the mirror is not treated as the repair, because the lag is structural: the cache
holds a release, and the source is by definition ahead of it between releases. The measurement itself is
recorded once, in `scripts/README.md`, so the ten pages carry the rule rather than ten copies of the
evidence.

### Significance

#### Tier 0

It fires on the two commands that *start* a piece of work, so a wrong answer propagates into everything
downstream — and it had already produced a changelog entry in a retired shape and a status report with a
section quietly empty. A maintainer reads the corrected sentence the next time they open any of these
pages, which in this repo is daily.

**Score:** 4

#### Tier 2

For almost every consumer nothing changes: the command they run is untouched, and the added sentence
explicitly confirms that the line above it is theirs. What it buys them is the case where this system is
copied — a consumer who publishes plugins of their own inherits the identical trap, and it is one that
produces no error message. Small, and noticed only if pointed out.

**Score:** 2

### Pull Request

