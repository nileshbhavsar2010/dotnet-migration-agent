---
name: net-migration-integration
description: >-
  Scaffolds, updates, and validates integration test projects during a .NET
  migration — detects existing integration test projects under tests/,
  creates a new xunit project targeting the migration's TargetFramework when
  none exists, and adapts the sample test to the app project's type (ASP.NET
  Web host vs. plain class library). Use when integration test coverage
  needs to be created or verified as part of a .NET version migration,
  typically after net-migration-analyzer and before or alongside
  net-migration-updater.
---
# Net Migration Integration Test Creator

Purpose: Scaffold, update, and validate integration test projects during migration.

Responsibilities:
- Detect existing integration test projects under `tests/`.
- If missing, scaffold an `xunit` integration test project targeting the migration `TargetFramework`.
- Add a project reference to the migrated application project.
- Register the integration test project with the repo's `.sln` so it actually
  loads in Visual Studio / VS Code and shows up in Test Explorer. Creating the
  `.csproj` on disk is not sufficient on its own — if it isn't in the
  solution, the IDE will never load or run it.
- Detect whether the application project is an ASP.NET Web host
  (`Sdk="Microsoft.NET.Sdk.Web"`) or a plain class library
  (`Sdk="Microsoft.NET.Sdk"`), and generate the sample test accordingly:
  - **Web host** → adds `Microsoft.AspNetCore.Mvc.Testing`, sample test uses
    `WebApplicationFactory<Program>` to hit an endpoint.
  - **Class library** → no ASP.NET packages added, sample test references
    the library directly with a placeholder `Assert` the agent should
    replace with a real call into the library's public API.
- When updating an existing integration project, refresh its test/package
  references (`Microsoft.NET.Test.Sdk`, `xunit`, `xunit.runner.visualstudio`,
  and `Microsoft.AspNetCore.Mvc.Testing` for web hosts) to the latest stable
  versions, not just add them if missing.

## Usage
This skill is intended to be invoked directly by the agent, without a
hardcoded project name — let the script derive it from the discovered app
project. **Always pass `-Auto`**; without it, the script only prints
suggested commands and creates nothing.

```powershell
powershell -ExecutionPolicy Bypass -File .github/scripts/create-integration-test.ps1 -ProjectRoot . -TargetFramework <target-framework> -Auto
```

Only omit `-Auto` if the user has explicitly asked to preview the planned
changes first without creating any files.

If `-IntegrationProjectName` is not supplied, the script derives one from
the discovered application project as `<AppProjectName>.Integration`.

## Error handling — do not fail silently
The script wraps every `dotnet` invocation in a checked call and the whole
script body in try/catch. On any failure (bad project XML, a failed
`dotnet` command, a missing project, etc.) it writes a message prefixed
`FAILED:` or `FAILED [step]:` via `Write-Error` and exits with a non-zero
exit code.

**The invoking agent must not treat this step as successful based on
narration alone.** After running the script:
- Check the actual process exit code (e.g. `$LASTEXITCODE` in PowerShell, or
  the equivalent for however the agent shells out).
- A non-zero exit code means the step **FAILED** — do not report success,
  do not proceed to the next pipeline step (`net-migration-updater`, etc.),
  and surface the script's `FAILED` / `Write-Error` output verbatim to the
  user rather than summarizing it as "done" or omitting it.
- If the script prints a `WARNING:` (e.g. no `.sln` found), pass that
  warning through to the user too — it's not fatal, but it means the
  created project may not be visible in the IDE until addressed.

## Notes
- The script is idempotent and will update existing integration projects
  rather than overwriting them.
- If more than one candidate `.csproj` is found under `src/`, the script
  picks the first and reports this — if that's the wrong project for a
  multi-project repo, re-run with an explicit `-IntegrationProjectName` and
  reference the intended project instead.
- If more than one `.sln` is found under `-ProjectRoot`, the script picks
  the first and reports this. For a multi-solution or multi-repo layout
  (e.g. one `.sln` per microservice), run this skill with `-ProjectRoot`
  pointed at each project's own folder rather than a shared superproject
  root, so the correct solution is targeted each time.
- After scaffolding, replace the placeholder assertion in the generated test
  with a real call into the application project's public API before treating
  this step as complete.
