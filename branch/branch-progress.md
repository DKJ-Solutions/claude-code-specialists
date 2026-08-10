## `docs/the-quoting-trap-is-the-argument-boundary` progress

### Steps

- [x] Check whether the lesson was already recorded before writing anything -- it was, in Derek's portable
      body AND in this repo's lens, with a dated measurement
- [~] Add a new section for it -- dropped: there was nothing missing to add. What was wrong was one hedge
      inside the existing rule, so the repair is a replacement rather than an addition
- [x] Measure the mechanism instead of asserting it: hand one argument carrying `"` to a native command
      three ways and read the child's own `argv`
- [x] Portable body: replace "on some shells ... even inside a here-string" with why no quoting form
      reaches the failure, and state the file as the default rather than the fallback
- [x] Repo lens: record the recurrence as a recurrence, with the argv measurement and the `pathspec 'a'`
      error it explains
- [x] Confirm the layer split is respected -- mechanism portable, numbers and dates local
- [x] Lint gate + all suites green

### Where I left off

Done. Worth keeping in view: the useful finding here was not the shell behaviour but that a rule written in
two layers, with a measurement attached, still got broken -- by reasoning along an axis the text left open.
That is why the repair is a sentence about *why the axis is wrong* rather than a louder restatement of the
rule.
