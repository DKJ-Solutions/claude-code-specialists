### UNINSTALL step order: the document and the audit survive until the end · Docs · 2026-08-01

Test round v10 (#340) was the **first time anyone followed `UNINSTALL.md` end to end** — it had travelled
since PR #321 and had never been walked. It broke on itself twice, in the same pattern it warns about one
step earlier for something else.

- **Step 3 deleted the document you were reading** (#328). `UNINSTALL.md` is not part of the plugin
  payload: it ships only in the cached marketplace clone, and `claude plugin marketplace remove` deletes
  that clone (measured: 2.9 MB, gone). After that step the manual existed **nowhere on the machine**, with
  no error and nothing to search for. `marketplace remove` is therefore now **Step 5**, after the
  verification — the last thing removed is the last thing needed — and *Before you start* says to keep a
  copy, pointing at the durable one on GitHub. The page already made exactly this argument for
  `specialists-teardown` shipping inside the plugin; it simply never turned it on itself.
- **Step 4's audit tool went with Step 2** (#328, second half). Step 4 said the teardown's audit *"says
  `[FREE]`"* and offered a re-run *"if you still have the plugin installed"* — which its own Step 2
  guarantees you do not. Reordering cannot fix this half, because the audit lives in the payload the
  uninstall removes. So Step 1 now says to **keep that output** (it is the last point at which it can be
  produced) and Step 4 reads it back instead of asking for a fresh run, naming the honest alternative for a
  reader who did not keep it.
- **#339's open question is answered, and the answer became a rule.** The page used to admit it did not
  know whether `marketplace remove` also deletes the clone and the unpacked cache, and told the reader to
  go look. The looking has been done on a virgin profile — the one environment where an earlier install
  could not obscure it: **the clone goes, the unpacked cache stays** (2,930,310 → gone; 939,860 → still
  there). Stated as the rule rather than the two measurements: **the unpacked cache belongs to the
  marketplace, not to the install** — `marketplace add` creates it (absent → 939,768 bytes, install record
  still `{}`), `marketplace remove` does not remove it, and no `plugin install`/`uninstall` is involved
  either way. Step 5 carries the manual delete.
- **What a torn-down profile actually looks like**, replacing "clean" with something checkable: three files
  exist that were absent before adoption — `installed_plugins.json` (35 bytes), `known_marketplaces.json`
  (288 bytes, no longer naming this marketplace) and `~/.claude/settings.json` (22 bytes) — none holding
  anything of this family's. Plus a per-location table saying which step closes which, including the one
  entry **no step closes for you**.

**Sweep, as PR #341 established for this class:** no count claim in the page was invalidated by adding a
fifth step (the "two removals" framing is repo-vs-machine and unaffected), and the three pages that link
here — the QUICKSTART, the family README twice — describe the order without numbering it, so none needed a
matching edit. Both new anchors follow the existing `#step-N--<slug>` pattern.
