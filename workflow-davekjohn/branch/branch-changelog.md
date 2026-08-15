## `feat/prompt-inbox` changelog

### Branch title

a prompt inbox in workflow-davekjohn

### Branch ID

20260815-145029

### Branch type

feat

### What does the change on this branch bring to main?

An assignment no longer has to be typed into a terminal. It is written into
`workflow-davekjohn/prompts/prompt.md` in an editor, `/prompt` reads it and takes it through the ordinary
intake, and `-Archive` files it under the date and resets the inbox once the work is under way. A
SessionStart hook announces a waiting prompt — its **first line only**, never the body, so the requester
keeps the moment to say "not yet". Dave, August 15, 2026, on the plain complaint that communicating
through the terminal is unpleasant: no wrapping, no editing, no saving something half-finished.

**It is the mirror of `/lock`, and the direction is the whole design.** That one is Claude writing a
note for the next Claude; this one is the requester writing for the next session — which is why the two
keep separate files and separate commands rather than one store with a direction field.

**"Is something waiting" is a structural test, not a string match**, and that is what this mechanism
does differently from the changelog entry's scaffold gate. The reset file is an HTML comment block and
nothing else, so the body is everything outside the comments and an empty body means nothing waits. No
placeholder wording to recognise, therefore no shared source for those strings and no translation seam:
a consumer may rewrite every word of the comment block and the test is unaffected, because comments are
comments in every language. It also closes the failure that wording-matching would have had here — the
scaffold's own instructions being handed to a session as if the requester had written them.

**The inbox is deliberately untracked, and the folder ships its own `.gitignore` saying so.** It is one
person's working input on one machine, changing between saves; a tracked copy would dirty the tree
continuously, which is exactly what a release cut refuses to run on — the failure a tracked PowerShell
cache already caused here twice. Shipping the rule *inside* the folder rather than as lines for the root
`.gitignore` means a consumer adopts the mechanism with one command and no edit to a file they already
own. The generated template reference is tracked *because* the inbox is not: without it a fresh clone
would carry no trace that the mechanism exists.

**No `PROMPTS-portable.md` beside the other three portable pages, deliberately.** Those exist because a
convention has a portable half and a local half each repo answers — branch prefixes, release tiers, who
approves what. This one has no local half: one file, one command, and nothing anyone configures. The
`prompt` skill is the portable half, and a page would restate it under another name.

One failure was measured rather than predicted and is repaired in the shape it actually appears in:
Windows PowerShell 5.1 raises a `DirectoryNotFoundException` past 260 characters, **naming a directory
that demonstrably exists**, and the archive path adds about ninety characters of its own. Hit with the
tree under a 147-character root. The archive write is wrapped so the message names path length as the
likely cause, and the inbox is reset only *after* the archive copy has landed — an inbox must never be
emptied when its record did not.

### Significance

#### Tier 0

It changes how an assignment arrives, which is the first minute of every piece of work. Noticed the same
day, and by every specialist rather than one — but it adds no obligation: the terminal keeps working
exactly as it did, so nothing breaks for anyone who never opens the file.

**Score:** 4

#### Tier 2

A new `/prompt` skill, a new session-start check and a folder their scaffold now places. It is opt-in in
the strongest sense — the hook stays silent in a repo that has no inbox at all — so a consumer who wants
none of it sees no change whatsoever, while one who does gets it without configuring a single value.

**Score:** 3

### Pull Request
