---
name: net-migration-pr
description: >-
  Creates a migration branch, commits all changes made by
  net-migration-updater, pushes the branch, and opens a pull request
  (via GitHub CLI if available, otherwise prints a compare URL). Use
  only after net-migration-verifier has confirmed the build and tests
  pass — this is the final step of a migration run and should not run
  if verification failed or was skipped.
---
# Net Migration PR Creator
 
**Single Responsibility:** Package a completed, verified migration into a branch, commit, and pull request.
 
## Purpose
Takes a working tree that has already been updated by `net-migration-updater`
and confirmed by `net-migration-verifier`, and turns it into a reviewable PR.
This skill does not modify project/package files itself — it only handles
git/GitHub operations.
 
## Preconditions
- `net-migration-verifier` has run and reported `success: true` (or the user
  has explicitly said to skip verification).
- There are uncommitted changes in the working tree (`git status --porcelain`
  is non-empty).
If either precondition isn't met, stop and report why instead of proceeding.
 
## Input
- `branchName`: optional. Defaults to `chore/migration-<yyyyMMdd-HHmmss>`.
- `title`: optional PR title. Defaults to `chore: Automated migration changes`.
- `body`: optional PR body. Defaults to a short summary of what changed
  (target framework, package updates, test project changes) pulled from the
  analyzer/updater/verifier outputs earlier in the conversation.
## Process
1. Confirm `git` is available and an `origin` remote exists.
2. Create (or check out, if it already exists) the target branch.
3. Stage and commit all changes with the given title.
4. Push the branch to `origin` with `-u`.
5. If the `gh` CLI is available, run `gh pr create --title <title> --body <body>`.
6. If `gh` is not available, determine the repo's default branch and print a
   compare URL in the form:
   `https://github.com/<owner>/<repo>/compare/<default-branch>...<branchName>?expand=1`
## No Side Effects Beyond Git
- ✅ Does not modify `.csproj`, `global.json`, or package files
- ✅ Only touches git state (branch/commit/push) and optionally opens a PR
- ❌ Does not run `dotnet build`/`dotnet test` — that's `net-migration-verifier`'s job
## Error Handling
 
### Error Responses
```json
{
  "success": false,
  "error": "NO_ORIGIN_REMOTE",
  "message": "No 'origin' remote configured for this repository.",
  "suggestion": "Add a remote with 'git remote add origin <url>' and retry.",
  "log_file": ".github/logs/net-migration-pr.log"
}
```
 
### Common Errors
- `NO_ORIGIN_REMOTE` - No `origin` remote configured
- `NOTHING_TO_COMMIT` - Working tree is clean; nothing to package into a PR
- `PUSH_FAILED` - Branch push rejected (permissions, protected branch, etc.)
- `PR_CREATE_FAILED` - `gh pr create` failed even though push succeeded; falls back to printing a compare URL
### Silent Failure Prevention
- ❌ NOT silently skipping the commit if there's nothing staged
- ✅ Explicitly reports whether a PR was created or only a compare URL was printed
- ✅ Logs branch name, commit hash, and PR URL (or compare URL) on success
## Logging
All operations logged to `.github/logs/net-migration-pr.log`
- INFO: Branch created, commit hash, push result, PR URL
- ERROR: Any step failure with suggested recovery
## Token Cost
~1,500 tokens per execution
 
## Use When
- After `net-migration-verifier` reports success
- User asks to "open a PR", "create a pull request", "commit and push the migration", or similar
 