## `fix/new-branch-stacked-idempotency` progress

### Steps

- [x] Verify #615 against the tree: the two tests, the comment above them, and whether the proposed
      `Get-BranchFileDeclaredBranch` really reads the entry heading as well as the step list's
- [x] Replace both tests with one owner comparison against the current branch
- [x] Decide overwrite-versus-refuse for a foreign owner, and guard the unrecoverable half
- [x] Name the previous owner in every outcome — kept, replaced or written
- [x] Add the two regression scenarios and measure them against the pre-fix script
- [x] Sync the plugin mirror
- [x] Review the diff and repair what it found: the git call missed `-C $repoRoot` and the
      `EAP=Continue` wrapper that every other git call in this script carries (the #107 pitfall)

### Where I left off
