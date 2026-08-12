---
name: net-migration-integration
description: >-
  Scaffolds, updates, and validates integration test projects during a .NET
  migration — detects existing integration test projects under tests/,
  creates a new xunit project targeting the migration's TargetFramework when
  none exists, wires up WebApplicationFactory-based sample tests, and adds
  Microsoft.AspNetCore.Mvc.Testing where needed. Use when integration test
  coverage needs to be created or verified as part of a .NET version
  migration, typically after net-migration-analyzer and before or alongside
  net-migration-updater.
---
# Net Migration Integration Test Creator
 
Purpose: Scaffold, update, and validate integration test projects during migration.
 
Responsibilities:
- Detect existing integration test projects under `tests/`.
- If missing, scaffold an `xunit` integration test project targeting the migration `TargetFramework`.
- Add references to the migrated application project and add `Microsoft.AspNetCore.Mvc.Testing` when needed.
- Create a minimal sample integration test using `WebApplicationFactory<TEntryPoint>`.
Usage:
- This skill is intended to be invoked by the migration agent script. It can also be run directly:
  ```powershell
  powershell -File .github/scripts/create-integration-test.ps1 -ProjectRoot . -IntegrationProjectName CustomerOrderApi.Integration -TargetFramework net10.0
  ```
 
Notes:
- The script is idempotent and will update existing projects rather than overwriting them.
- By default the migration agent will only suggest commands; use `-Auto` to execute actions.
 