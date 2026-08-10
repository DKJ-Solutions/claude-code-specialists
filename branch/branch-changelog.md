## `feat/the-trunk-warning-lead-is-seamable` changelog

### Branch title

The trunk warning's opening sentence is translatable like the rest of it

### Branch ID

20260810-093843

### Branch type

feat

### What does the change on this branch bring to main?

`TrunkWarningLead` joins `$script:BranchFileDefaults`, so the trunk warning in `branch/branch-changelog.md`
and `branch/branch-progress.md` is repo-owned prose from its first word rather than from its second sentence.
`Format-BranchFileHeader` built that opening sentence itself, which made it the one fragment of those two
documents a consumer could not reach through `Get-BranchFileWordingOverrides` — and a consumer who had
translated everything else got this (inbound
[#562](https://github.com/DaveKJohn/claude-code-specialists/issues/562)):

```markdown
# `main` changelog


> **You are on `main`.** Schrijf hier nog niet -- maak eerst een branch.
> Wat je hier op de hoofdbranch neerzet hoort bij geen enkele branch, wordt niet gevouwen, en staat
> de volgende die er wel een maakt in de weg.
```

The first sentence a reader of that document sees, in the wrong language, with no way out but forking
`new-branch.ps1` — the duplication [#410](https://github.com/DaveKJohn/claude-code-specialists/issues/410)
had just removed. It is also the exact case those knobs were built for: the trunk itself has been
configurable through `Get-TrunkBranchName` all along, so this lead was the only part of the warning that did
not move with the repo.

**`{0}` is replaced by the trunk name, by a plain string replace rather than `-f`.** A seam value is
hand-written, and `{` is an ordinary character in prose — a format string would throw at scaffold time on
somebody's translation. The placeholder is optional for the same reason it earns its place: a translation
usually needs the trunk name somewhere other than where English puts it, and a lead that omits it simply
does not repeat a name the heading directly above already carries.

**An empty override keeps the default, and that is this seam's existing fail-safe rather than a new rule.**
The first draft of this change claimed an empty lead was a legitimate way to drop the sentence; the test
written to prove that is what disproved it, since `Get-BranchFileWording` ignores any empty value so a blank
heading cannot leave a document with a gap where a sentence belongs. So the seam can replace this sentence,
not remove it — recorded in both the lib and the suite, because the wrong version of it was written down
first.

`new-branch`'s `SKILL.md` says so too: its promise that defining none of these knobs gives you "exactly the
English text above" was true of everything except this line, which is what made the defect worth reporting.

### Significance

#### Tier 0

Nothing changes here — this repo's branch files are in English, which is what the defaults say. What it
prevents is the request this would otherwise become next time: a consumer asking for one more string to be
seamable, one release later.

**Score:** 1

#### Tier 1

The knob family established by #410 is complete for these two documents, so "is the branch scaffold
translatable" stops being a question with a footnote. Small, and it settles rather than improves.

**Score:** 2

#### Tier 2

For a consumer whose repo is not in English this is the difference between a document that reads as theirs
and one that opens in a foreign language — and their only alternative was maintaining a private copy of the
script, which is the cost this whole seam exists to avoid. They can adopt it by adding one key; changing
nothing keeps the current text exactly.

**Score:** 3

### Pull Request
