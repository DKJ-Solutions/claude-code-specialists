## `docs/cut-release-docstring` progress

### Steps

- [x] Verify the reported defect before repairing it: 3b/3c really are gone from the code
- [x] Measure every other claim in the header against the code instead of stopping at the report
- [x] List the seam functions the script actually reads, and diff that against the list it advertises
- [x] Cross-check that list against the script contract's registry, as an independent second source
- [x] Rewrite the four affected blocks: synopsis, seam list, tier model, steps 3 / 3b-3c / 3d
- [x] Re-measure the rewrite itself — caught one new false claim about tier-0 ranking
- [x] Regenerate the plugin mirror so the two copies stay byte-identical
- [x] Lint gate and script-contract check green

### Where I left off

Done. The header now says what the code does, and the two places where the file already contradicted
itself agree with it. Nothing about the script's behaviour changed on this branch — only its description.
