## `fix/a-republished-copy-must-not-be-installed-from` changelog

### Branch title

a reader of a republished copy is told not to follow the install commands

### Branch ID

20260814-211501

### Branch type

fix

### What does the change on this branch bring to main?

The harm that inbound [#664](https://github.com/DaveKJohn/claude-code-specialists/issues/664) reports,
separated from the restructuring it proposes — because the harm is live in a published copy today and
the restructuring is a project.

`plugins/INSTALL.md`, `plugins/UNINSTALL.md` and `README.md` all steer a reader into registering the
**public** marketplace `DaveKJohn/claude-code-specialists`. That is correct for a reader who came to
this repo to install. It is wrong for a colleague holding a copy that was **republished into their own
organisation's marketplace**, where the registration and the install already happened centrally — and
following it adds a second channel pointing elsewhere, which is the one thing an org marketplace exists
to prevent. Neither page said which copy the reader was holding. All three now do, at the top, before
the first command.

**Verified against the tree before anything was written, and every number in the report holds exactly**:
`INSTALL.md` 1,220 lines, `UNINSTALL.md` 527, together the 1,747 the title claims; the five steering
lines are at `INSTALL.md:38`, `:678`, `:718` and `README.md:312`, `:320`, and each is what the report
says it is.

**Two of the report's own load-bearing claims did not survive the same pass, and both are about its
proposed fix rather than its finding.**

1. *"The published-set list in `publish-to-business.ps1` is where that choice is expressed, so the
   change is one entry plus the new page."* There is no entry to remove: `$PublishedPaths` names
   **`plugins`**, the whole directory, so both pages travel by being inside it. Excluding them needs
   either an exclusion mechanism that does not exist, or moving them out of `plugins/` — which is what
   this repo already did with `connectors/`, for the same reason, and is the cheaper of the two because
   a folder boundary cannot be forgotten the way a list can.
2. *"Split both pages along that seam."* The seam is not on a line boundary. Two of the five steering
   lines — `:678` and `:718` — sit **inside** the adoption section the report wants published, in
   *Connecting in four steps*. So the split is a rewrite, not a move, and it is a project rather than a
   branch.

**What is deliberately not built here:** `plugins/ADOPTION.md` and the publish-set change. Both are
real, both are wanted, and both need a decision about the resulting shape that this branch has no
business making on its own. The three notes added here hold under every shape that decision could take,
which is exactly why they could be separated out and shipped first.

### Significance

#### Tier 0

No behaviour here changes; the maintainer is the one reader who is never in the situation these notes
address. What it does carry forward is the measurement that #664's two proposed mechanisms do not hold,
so the next person picking it up starts from that rather than from the proposal.

**Score:** 1

#### Tier 2

The audience the note is for is the one that cannot yet read it — a colleague on an organisation's own
marketplace — and for them it is the difference between adopting correctly and quietly opening a second
channel outside the org's control. Every public consumer sees three added paragraphs that do not apply
to them and say so in their first sentence.

**Score:** 3

### Pull Request

