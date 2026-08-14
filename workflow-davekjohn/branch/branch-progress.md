## `fix/resolves-gate-assert-width` progress

### Steps

- [x] Reproduce the failure and establish it is not this-branch-caused: same commit, 2x red at width
      152, 2x green at width 80, no script differing from `main`
- [x] Measure the actual mechanism rather than infer it: rebuild the parent's render at the real
      95-character source path and show `#332` arriving as `#33` + decoration + `2`
- [x] Hoist `Test-OutputContains` and `Invoke-CapturedScript` out of the pre-flight `try` block to
      script scope, so every scenario can see them
- [x] Switch scenario C1 and C5 to `Invoke-CapturedScript`, and rewrite the comment that argued past
      the failure mode it had named
- [x] Add a capture probe that asserts on the ABSENCE of `NativeCommandError`, so the guard is about
      the capture and not about one phrase
- [x] Verify the probe in both directions: the old `2>&1` form does produce that string
- [x] Suite green at width 152 and at width 80 (318 asserts)
- [x] Lint gate green
- [x] All test suites green

### Where I left off

Done. `fix/agent-content-boundaries` is parked on origin and is next: once this merges it needs `main`
merged in and can then go through its own gate cleanly.
