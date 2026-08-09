## `docs/cut-release-docstring` changelog

### Branch title

The cut-release docstring describes the script that exists

### Branch ID

20260809-205550

### Branch type

docs

### What does the change on this branch bring to main?

`cut-release.ps1`'s header described a script that stopped existing over three separate decisions in
August. Measured against the code in the same file rather than proofread, **twelve** claims were wrong,
and the file already contradicted itself in two places: an in-line comment at the retirement point
records that steps 3b/3c are gone, and a seam comment further down records that `Get-ReleaseLiveMarker`
is retired — while the header above both still presented them as live.

**The half with teeth is the seam list, because that list is an interface.** A consumer configures this
shared script by defining optional functions in their own `repo-config.ps1`, and this header is where
they read which ones exist. It named seven; the script reads seven; **they were not the same seven**:

| named, but retired | read, but unnamed |
|---|---|
| `Get-ReleaseLiveMarker` — described the retired release block in `CHANGELOG.md` | `Get-LintScript` — which script the lint gate runs |
| `Get-ReleaseCategoryTitles` — labelled the retired category headings | `Get-ReleaseHistoryPath` — where the release overview table lives |

Both directions cost a consumer something, and the second more than the first. Defining a retired
function does nothing and *looks configured*, which is worse than an error. And `Get-ReleaseHistoryPath`
is the one this repo just paid for: cutting `v4.0.0` refused outright until a `#### 4.x` section was
opened by hand in the very page that function points at — a refusal a consumer would meet with no
documented way to know which file was meant. The list is now the seven the script actually reads, taken
from the script rather than from the previous list, and cross-checked against the script contract's own
registry, which independently names the same seven.

**The other ten are the tier-model drift, one layer below where the `v4.0.0` release just repaired it.**
The header still said `CHANGELOG.md` holds one section per tier, that the notes group by branch type
inside each tier, that a cut writes a reference under `## Releases` and empties "every tier section", and
that the model switches off in "a repo that declares a single section" — the exact test this repo has
recorded as a landmine, since a flat changelog gives an unadopted repo and an adopting one one group
each. Each of those is now what the code does, with the reasoning kept where it changes behaviour rather
than merely dated. Step 3d gained the condition it had always been missing: the highlights need a
**tier-2 entry** as well as a matching bump type, which is the whole of what keeps a tier-1-only minor
from handing an outsider a document about work they cannot see.

**One claim was corrected twice, which is the argument for measuring instead of reading.** The first
rewrite of step 3 said the entries are ranked within each tier by significance. The suites say otherwise
in as many words — *ranked from tier 1 up, and deliberately not at tier 0* — because the development note
is the record and keeps the order the folds left. A plausible sentence, written while repairing eleven
implausible ones, and it would have shipped as the twelfth.

**The retired step numbers 3b/3c are kept as headings that say they are retired**, rather than
renumbered. Consumers' own release notes refer to "step 3b", and a reader on an older copy of this
script should land on the answer instead of on a step that has quietly come to mean something else.

**The mirror was regenerated rather than hand-edited**, so the root copy and the one in
`workflow-davekjohn` stay byte-identical, which is what the shared-scripts drift lint enforces.

### Significance

#### Tier 0

This is the header a maintainer reads before touching the release cut, and it disagreed with the code
directly beneath it in two places. The next person to change this script would have been reasoning from
a description of the version before last.

**Score:** 3

#### Tier 1

The class is the one this project keeps paying for: a decision changes the mechanism and leaves the
sentence describing it. Three separate August decisions each left their traces here, in the one file
where the correction is a docstring rather than a document somebody has to remember exists.

**Score:** 3

#### Tier 2

The seam list is how a consumer learns what they may configure in a shared script they run but do not
own. It advertised two knobs that do nothing and hid one that a release cut refuses without — including
the refusal this repo hit today, which names no file.

**Score:** 4

### Pull Request

