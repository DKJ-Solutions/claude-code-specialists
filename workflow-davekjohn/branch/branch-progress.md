## `docs/v4-11-0-release-note` progress

### Steps

#### PLAN

- [x] Read the cut's draft, the development notes' tier-2 reasons, and v4.10.0's note for register
- [x] Decide the selection and the order: migration first (test 3), then the one new capability

#### CREATE

- [x] Rewrite the consumer section against the seven tests -- second person, action at the top
- [x] Verify every mechanism the document names against the tree before printing it (`/prompt`,
      `adopt-workflow-folder`, `workflow-davekjohn/prompts/`) -- the #566 rule
- [x] Author *What it is worth* -- time, risk, reduced dependence; the 87% and the 19% belong here
- [x] Author *What was still open* -- as a snapshot, past tense, five items
- [x] Write step 0a's first pass into the document: the 5m 25s head and what blocked a person

#### TEST

- [x] Lint + suites via `open-pr.ps1` (check 25 holds the consumer document's links to its own tier)

### Where I left off

Document written and the branch is ready for its PR. The second timing pass -- the end-to-end total --
is deliberately not in this branch: it cannot exist until this PR has merged and the Release is
published, and it lands in its own small edit afterwards.
