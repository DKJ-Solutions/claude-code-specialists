## `feat/prompt-inbox` progress

### Steps

#### PLAN

- [x] Put the three design questions to Dave (one file vs a queue, how it is picked up, what happens
      afterwards) -- all three answered with the recommendation: one `prompt.md`, skill + session-start
      announcement, archive and reset.
- [x] Read how `branch/` and `/lock` already work, so the inbox follows the shape the repo has rather
      than inventing a fourth one.

#### CREATE

- [x] `scripts/lib/prompt-inbox-lib.ps1` -- the one source: where the file is, its reset state, and the
      structural test for whether an assignment is waiting.
- [x] `scripts/task/prompt-inbox.ps1` -- place, read, `-Archive`.
- [x] `plugins/workflows/workflow-davekjohn/hooks/prompt-sessioncheck.ps1` + its `hooks.json` entry --
      announces a waiting prompt, first line only.
- [x] `plugins/workflows/workflow-davekjohn/skills/prompt/SKILL.md` -- the portable procedure.
- [x] Register both files in `shared-scripts-lib.ps1` and generate the plugin mirrors.
- [x] `adopt-workflow-folder.ps1` scaffolds the folder for a consumer, from the same formatters.
- [x] The folder docs: `workflow-davekjohn/prompts/README.md`, plus the `README.md` and `CLAUDE.md`
      rows one level up.
- [~] A `PROMPTS-portable.md` beside the other three portable pages -- dropped: those pages exist
      because a convention has a local half each repo answers, and this one has none. The skill is the
      portable half, and a page would restate it under another name.

#### TEST

- [x] `scripts/tests/prompt-inbox.tests.ps1` -- 47 asserts over the formatters, the readers and the
      place -> read -> archive -> reset cycle end to end.
- [x] The lint gate and every suite green.

### Where I left off

Built and green. The session-start announcement only starts working in this repo after the merge and
push: the hook runs from the plugin cache, which holds the last pushed version. `/prompt` itself works
now, from `scripts/task/prompt-inbox.ps1`.
