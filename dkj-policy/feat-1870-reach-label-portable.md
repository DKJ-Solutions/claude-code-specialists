## feat/1870-reach-label-portable

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

#### What Dave asked for

Dave, September 11, 2026: *"smartwatchbanden gebruikt een minor label. Aangezien dat een consumer is van
deze plugin, verwacht ik juist dat hier ook een minor label is. Deze minor label krijgt elke consumer van
de dkj-policy plugin."* and, on the axis: *"een changelog entry is een tier-0 (patch) of tier-1, tier-2
(minor). hetzelfde idee pas ik nu alleen ook toe op issues."*

#### What was true before this branch

The reach label existed only in `dkj-policy-bwj`, whose two call sites refuse outside a BWJ store repo,
and its default name was `tier-1`. `dkj-policy` prescribed no issue label at all -- `CONTRIBUTING-portable.md`
said the opposite in as many words: *"your labels are your tracker's -- nothing in this plugin reads
either"*.

#### Why this is not #1686 half 2 reversed -- corrected after the red-team

The first draft of this branch argued: *#1686 kept the prio axis repo-local because nothing in the
workflow reads a priority, and that does not transfer because the reach scale IS read.* **That argument
does not survive and was withdrawn.** Held against the LABEL -- which is what goes portable here -- no
gate, no script and no runner reads `minor` either; two skills consult it, which is the same enforcement
class as zero scripts consulting `prio-`. This branch's own contract comment says so in as many words,
one paragraph below where the claim sat.

**The difference that does hold is one level up, and it is about the AXIS rather than the label.** A
priority axis exists nowhere in this workflow, so making it portable would have handed a consumer a scale
they had never been asked about. The reach axis is already theirs: every changelog entry they write scores
it, and `cut-release.ps1` refuses a minor no tier-1-or-higher entry earned. The label adds no axis -- it
reads one the consumer already answers, one step earlier. #1540's lesson is met separately, by the
seam's default: an unanswered consumer is correct, not gapped.

#### The one consumer this is NOT free for, and it is filed

`BWJ-ecommerce/xoxowildhearts` carries `tier-1` and answers no seam, so once this reaches it through a
release, `report-issue` types a label it does not have -- and `gh issue create` refuses the whole call
atomically, producing no issue at all rather than one without a label. That is stronger than #1540's
"correct repo reports a gap": it is a correct repo whose filing path stops. It cannot be repaired from
this branch (another repo's tracker, and #1686 is explicit that a session does not rename labels on live
trackers on its own), so it is filed rather than absorbed, and both ways out are written into
`adopt-dkj-policy` Part 4 and the BWJ adopt step.

### CREATE

- [x] `minor` created on this repo's tracker, `fbca04`, with the tier-2 wording this repo's
      `Get-ReleaseAudienceTier = 2` calls for
- [x] `RELEASES-portable.md` -- the tier model gains its issue projection, beside the scale it projects
- [x] `CONTRIBUTING-portable.md` -- the one exception to "your labels are your tracker's"
- [x] `Get-ReachLabel` registered in the script contract: Optional, `copy`, default `minor`
- [x] shared-script mirror and `config-blueprint.json` regenerated
- [x] `adopt-dkj-policy` Part 4 -- the label on the tracker, with a wording per audience tier
- [x] `dkj-policy-bwj` stops defining the axis and points at it; every `tier-1` DEFAULT claim corrected
- [x] this repo's lenses: the reach axis beside the prio axis (`01-01` always-on, `05-05` in detail)

### TEST

- [x] `scripts/tests/reach-label.tests.ps1` -- new suite, 24 asserts: the definition, the exception,
      Part 4's two wordings, the contract record's shape, and no portable page still calling the
      default `tier-1`
- [x] `dkj-policy-bwj.tests.ps1` -- the proposed-seam assert re-aimed: `tier-1` is now the answer a
      store that has NOT renamed its label owes, not the default
- [x] `check-plugin-integrity.ps1` -- 0 errors

### DEPLOY: feat/1870-reach-label-portable

The reach label becomes part of `dkj-policy` rather than of its BWJ chapter, and its name becomes
`minor`. It is the tier model -- which this workflow already reads on every changelog entry, and which
already decides patch versus minor -- read one step earlier, on the issue instead of on the entry. An
issue whose landing will be written at tier 1 or 2 carries the label; tier 0 carries none, and doubt
resolves there. `Get-ReachLabel` states the string a tracker stores, defaulting to `minor`, so a repo
that spells the axis otherwise answers one function instead of being renamed.

**Score:** 4

#### What makes this deploy extra special

This is the first issue label this workflow has ever prescribed, and it arrives with the sentence that
used to forbid it rewritten rather than quietly contradicted: your other labels are still your
tracker's business. A consumer gets a worklist -- `is:open label:minor` is every open issue whose
landing will be visible past their own developers -- for the price of one `gh label create`, which
`adopt-dkj-policy` Part 4 now hands them. A consumer already running the axis as `tier-1` is not
renamed by this: they either rename the label themselves, which GitHub does without dropping it from a
single issue, or answer `Get-ReachLabel` with the word they have.

**Score:** 3

#### Pull Request

The reach label goes portable: every consumer carries 'minor'
