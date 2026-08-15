## `docs/source-repo-naming` progress

### Steps

#### PLAN

- [x] Measure the real size before editing: 32 occurrences of "workshop repo" across 20 files, against
      340 occurrences of "workshop" as a generic role word across 66 — the second set is deliberately
      out of scope here and reported back instead

#### CREATE

- [x] `#697` — replace all 32 "workshop repo" with "the source repo"
- [x] Reword the one sentence where the substitution reads badly ("The source of this script lives in
      the source repo" → "This script is maintained in the source repo")
- [x] Leave the three `davekjohns-workshop` references alone — they are correct past tense
- [x] `#710` — translate the four Dutch section comments in `.gitignore`
- [x] Record `.gitignore` in the language rule's layer list and its `paths:`, so the gap is closed
      rather than only patched
- [~] Sweep the remaining 308 generic uses of "workshop" — deliberately not done here: it is a
      prose-sensitive edit across 66 files of shipped plugin content, materially larger than the issue
      described, and its size is Dave's call rather than mine to assume

#### TEST

- [x] `check-plugin-integrity.ps1` green — including the shared-script check over all 30 mirrored
      pairs, which is what proves both sides of every mirror were edited identically
- [x] full test suite green

### Where I left off

