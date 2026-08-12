---
description: "Run the full .NET migration pipeline: analyze, scaffold tests, apply updates, verify, and open a PR."
---
Migrate this project to .NET ${input:targetVersion:10.0}.

Run these steps in order, using the matching skill for each, and stop and
report clearly if any step fails or is skipped:

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

After each step, briefly report what happened before moving to the next one.
