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
- Detect whether the application project is an ASP.NET Web host
  (`Sdk="Microsoft.NET.Sdk.Web"`) or a plain class library
  (`Sdk="Microsoft.NET.Sdk"`), and generate the sample test accordingly:
  - **Web host** → adds `Microsoft.AspNetCore.Mvc.Testing`, sample test uses
    `WebApplicationFactory<Program>` to hit an endpoint.
  - **Class library** → no ASP.NET packages added, sample test references
    the library directly with a placeholder `Assert` the agent should
    replace with a real call into the library's public API.

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

## Notes
- The script is idempotent and will update existing integration projects
  rather than overwriting them.
- If more than one candidate `.csproj` is found under `src/`, the script
  picks the first and reports this — if that's the wrong project for a
  multi-project repo, re-run with an explicit `-IntegrationProjectName` and
  reference the intended project instead.
- After scaffolding, replace the placeholder assertion in the generated test
  with a real call into the application project's public API before treating
  this step as complete.
