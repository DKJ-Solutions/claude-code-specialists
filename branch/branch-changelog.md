## `feat/release-note-root-seam` changelog

### Branch title

The release note's root directory becomes a seam, and reaches both its readers

### Branch ID

20260812-095228

### Branch type

feat

### What does the change on this branch bring to main?

`Get-ReleaseConsumerBumps` says *whether* the hand-written release note is written. Nothing said
*where*: `cut-release.ps1` built that path from the literal `releases/notes`, while every neighbouring
path in the same file was already answered per repo — the folder component by
`Get-ReleaseNotesGrouping`, the release list by `Get-ReleaseHistoryPath`. The file already accepted that
the folder *inside* this path varies while its root did not.

That left the knob above it **unanswerable** for a repo whose hand-written notes live elsewhere: naming
the bumps would point the cut at a directory that does not exist there and leave the one that does out
of the release, so the only safe value was `@()` — the tier switched off, which is not an answer to the
question the knob asks. `Get-ReleaseNoteRoot` is that answer, defaulting to today's value, so nothing
changes for anyone who does not set it. `Get-ReleaseHistoryPath` is the precedent and carries the same
sentence: a location convention rather than a fact about the repo.

**The seam reaches both of its readers, which is the half that could have failed in silence.**
`session-status.ps1` looks for the newest note; had it kept the default, a repo that repointed the root
would have its note written to one place and looked for in the other, and the miss prints as *"no
release note was found"* — which reads like a repo that has not cut one yet. It reads the seam the way
it already reads the wording beside it: `repo-config.ps1` directly, inside the try that degrades to the
default, because that script deliberately dot-sources no library. Its scan now starts *at* the notes
root instead of walking `releases/` behind a `[\\/]notes[\\/]` filter — a filter that could not have
honoured a seam whose whole subject is the segment it matched on, and that already matched every file
in the tree whenever the checkout itself sat under a folder of that name.

The same report's smaller finding, in the same neighbourhood: of the three messages about the release
list, the two that fire on success used `$historyRelPath` and the one that fires when the file is
**missing** used the literal — so the seam failed exactly where the reader is about to go looking for
the path it names.

`releases/development/` is deliberately given no equivalent knob. The reporter could show a repo that
genuinely differs on the note root and none that differs on that one, and a seam nobody can be shown to
need is a knob every reader has to read past.

Reported from a consumer as inbound
[#616](https://github.com/DaveKJohn/claude-code-specialists/issues/616), verified against `main` before
the repair. The proposed name `Get-ReleaseConsumerNotesRoot` was not taken: since the two hand-written
documents merged there is one release note with a named section per reader, so the consumer is a
*section* of that document rather than its title, and the name follows the file's own vocabulary
(`Get-ReleaseNoteWording`, twenty lines below it).

### Significance

#### Tier 0

This repo sits on the default, so the seam itself changes nothing here. What does change is the
`releases/` scan, which stopped keying on a path segment that any checkout could carry in its own
directory name, and the missing-file warning, which stopped being the one message of three that
disagreed with the other two.

**Score:** 2

Is there a tier above this one?

#### Tier 1

The consumer tier stops being half-configurable: the knob that decides whether the document exists and
the knob that decides where it goes are answerable together now, and a test pins the writer and the
reader to the same seam — the pairing nothing else in the tree compares.

**Score:** 3

Is there a tier above this one?

#### Tier 2

A consumer could not turn the tier on at all, and wrote the reasoning for the workaround into their own
`repo-config.ps1`; that workaround is an answer now. Deliberately not scored 5, though band 5 names a
long-standing blocker that is gone: this one blocked the subset of repos that already keep their notes
somewhere else, and nobody outside that subset has anything to do.

**Score:** 4

### Pull Request
