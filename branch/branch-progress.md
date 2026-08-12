## `docs/migration-before-layouts` progress

### Steps

- [x] Verify #612 against the tree: `git ls-tree -r 6ae038f` confirms `plugins/specialists/` is what
      `3.2.0` shipped, and both tables document only the older layout
- [x] Measure the layout per tag rather than accepting the report's version framing — which corrected
      it: the old ids ran to `v3.9.0`, not `v3.2.0`
- [x] Rewrite the repair as a shape test, with both real before-forms and their version ranges under it
- [x] Say what to do when neither literal matches — the wrong conclusion is the whole failure mode
- [x] Drop the folder-table row for a workflow before-path that never existed, and say when that plugin
      first shipped
- [x] Copy edit and lint: restore the sample block's binding statement, and point at the page's existing
      install-record query instead of adding a second, weaker one

### Where I left off
