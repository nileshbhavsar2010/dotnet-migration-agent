---
description: "Run the full .NET migration pipeline: analyze, scaffold tests, apply updates, verify, and open a PR."
---
Migrate this project to .NET ${input:targetVersion:10.0}.

Run these steps in order, using the matching skill for each.

1. Analyze the current project state and produce an update specification
   (net-migration-analyzer). Do not modify any files in this step.
2. Detect or scaffold integration test coverage for the affected projects
   (net-migration-integration).
3. Apply the update specification from step 1 to global.json, .csproj files,
   and NuGet packages, with backup/rollback on failure (net-migration-updater).
4. Restore, build, and run tests to verify the migration
   (net-migration-verifier). If this step fails, stop here — do not proceed
   to step 5 — and report the failure with enough detail to fix it.
5. Only if step 4 succeeded: create a migration branch, commit the changes,
   push it, and open a pull request (net-migration-pr).

## Failure handling — no silent failures
After each step, check its actual result — the process/script exit code or
equivalent success signal for that step's tool — rather than inferring
success from the absence of visible errors or from the step's own narration.

- A non-zero exit code, a thrown error, or a `FAILED:`-prefixed message from
  a step's script means that step **failed**, even if some files were
  created or partially updated along the way.
- If a step fails: stop the pipeline immediately, do not proceed to later
  steps, and report the failure to the user with the exact error text
  produced by that step (not a paraphrase or summary that could hide the
  actual cause).
- If a step produces a non-fatal warning (e.g. no solution file found for a
  scaffolded test project), pass that warning through to the user as well,
  even though the pipeline continues — the user needs to know the created
  artifact may need manual follow-up.
- Briefly report what happened after each step before moving to the next
  one — this report must reflect the actual checked result, not an assumed
  or narrated outcome.
