## `feat/release-github-folder` progress

### Steps

- [x] Measure whether anything LINKS to the three body paths before moving them — seven references, zero links
- [x] `git mv` the three existing bodies to `releases/github/4.x/<X.Y.Z>.md`
- [x] Repoint the body path in `cut-release.ps1`, and derive its directory from its own path
- [x] Copy the source over the plugin mirror rather than retyping the edits, so the two cannot diverge
- [x] Repoint the four live documents naming the old path: `releases/README.md`, Rendall's lens, the `cut-release` skill, `repo-config.ps1`'s artefact list
- [x] Leave the path named in `releases/development/4.x/4.3.0.md` — a published record describes what the file was called then
- [x] Guardrail asserts: the new root, the suffix gone from the assignment line, the directory derived from that path
- [x] Regenerate the config blueprint — the `repo-config.ps1` comment is guidance it ships, so the lint caught it stale
- [x] Lint gate green
- [x] All suites green — 31 of them, passed 31 / failed 0 (the docs still say "all 26"; flagged separately, not repaired here)
- [~] No seam for the new root — declined, per `Get-ReleaseNoteRoot`'s own contract record; the knob arrives the day a repo differs
- [~] A section in `releases/README.md` describing the three roots — deliberately left to the chunk that renames `notes/` to `audience/`, so the model is not half-described

### Where I left off

Chunk 1 of three (issue #620's design). The move itself is done and the lint is green; the suites are
running. Chunk 2 is the model — `Get-ReleaseAudienceTier` as a `decide` contract record with no silent
default, the scaffolder writing tier 0 plus the one enabled audience tier, and the cumulative-ladder check
collapsing. Chunk 3 is `notes/` → `audience/` plus the documents that describe the tier model, and closing
#620 with the evidence.

