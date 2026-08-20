# `docs/shopify-line-endings` cycle · 20260820-160658

## PLAN

- [x] Verify #788 at HEAD: `grep -rniE "crlf|line ending|autocrlf" plugins/teams/team-shopify/` -> 0 hits
- [x] Verify the three measurements in the reporting consumer's own tree rather than copying them from
      the report. All three are written into that repo's `.gitattributes` and hold: 37 CRLF files against
      a pure-LF index, `text=auto` alone does not clear them, `git add` does
- [x] Recount: the report says "over 712 tracked files"; the tree now says 740. The figure that carries
      the argument -- 37 files, zero changed lines -- is the one that holds, so the text uses that and
      drops the total
- [x] Decide where it goes. The report proposed Sandra's and Steven's manuals; the CLI fact is Steven's
      (he owns the CLI reference), the reading instruction is Sandra's (she reads the pull), and the
      README gets it too because a consumer meets this before opening either manual

## CREATE

- [x] Steven #22: a section under the CLI reference -- the two writers, the measurement, the reading
      instruction, the `eol=lf` trap, and what `.gitattributes` should carry
- [x] Sandra #21: the reading instruction in her hard rules, covering the pre-task sync and both
      verification pulls of the live push, pointing at Steven's measurement
- [x] `team-shopify/README.md`: a section before the adoption sections, since the first pull comes before
      the first read of a manual
- [x] The `sync-main` skill page's step 5 and `adopt-shopify-floor`'s closing output both point at it --
      the two places a consumer is standing when it bites
- [~] `.gitattributes` is NOT scaffolded by the floor. The measurement says the procedure is where this
      is handled, and `* text=auto` in a repo whose index already holds CRLF renormalises the whole tree
      on the next `add`. Stated as a decision in the manual rather than left silent

## TEST

- [x] `check-plugin-integrity.ps1`: 0 errors, 286 links scanned
- [x] The three anchors checked by hand against the heading they target, since a fragment is the part a
      link scan cannot prove
- [x] `adopt-shopify-floor` (36), `check-plugin-integrity-docs` (75), `shared-scripts` (378),
      `agent-shared` (27): 0 fail
- [~] No new test. The change is prose plus two lines of script output; the mirror pair is already held
      byte-identical by the drift lint

## DEPLOY

- [x] Branch check ran BEFORE the first edit this time, which is the correction to the slip recorded on
      the previous branch

## Where I left off

After the merge and the fold: close #788 with the evidence, including the 712-to-740 recount and why the
floor does not place `.gitattributes`. Then the last one, #789 -- the shipped entry gate.
