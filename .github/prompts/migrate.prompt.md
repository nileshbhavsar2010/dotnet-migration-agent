---
description: "Run the full .NET migration pipeline: analyze, scaffold tests, apply updates, verify, and open a PR."
---
Migrate this project to .NET ${input:targetVersion:10.0}.

Before making any change, ask the user exactly what they want changed.
Do not assume the migration should include integration tests, package upgrades,
project-file edits, or a PR. Stop and ask the user to confirm the change scope
before running any file-modifying step.

When the user answers, follow only that scope.

1. Analyze the current project state and produce an update specification
   (net-migration-analyzer). Do not modify any files in this step.
2. Only if the user explicitly approved integration-test creation or broader
   migration work, detect or scaffold integration test coverage for the
   affected projects (net-migration-integration).
3. Apply only the user-approved changes from step 1 to global.json, .csproj
   files, and NuGet packages, with backup/rollback on failure
   (net-migration-updater).
4. Restore, build, and run tests to verify the migration
   (net-migration-verifier). If this step fails, stop here — do not proceed
   to step 5 — and report the failure with enough detail to fix it.
5. Only if step 4 succeeded and the user explicitly approved a PR: create a
   migration branch, commit the approved changes, push it, and open a pull
   request (net-migration-pr).

If the user does not specify a change set, ask them one of these questions:
- framework-only changes
- framework + package updates
- framework + package updates + integration tests
- full migration + PR
- no changes / stop

Never auto-create a PR or a test project from a copied .github folder without
explicit user approval.

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
