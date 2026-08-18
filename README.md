# .NET Migration Agent

An agent-based framework for automating .NET version migrations across existing solutions and projects. The repository is organized around a staged skill pipeline defined under `.github/`, where each stage has a specific responsibility and a clear failure boundary.

## What this repo does

This project helps migrate .NET applications and libraries from one SDK/framework version to another, while keeping the process safe and verifiable. It is designed to:

- analyze project state before changes are made
- detect or scaffold integration tests for migrated projects
- apply framework and package updates with backup/rollback protections
- validate the result with restore/build/test steps
- open a PR only after verification succeeds

## Migration workflow

The migration process is intentionally split into a sequence of skills, in this order:

1. `net-migration-analyzer`  
   Scans the repo, identifies migration targets, and produces an update specification without modifying files.

2. `net-migration-integration`  
   Ensures integration tests exist or are updated for the migrated project surface.

3. `net-migration-updater`  
   Applies the update specification to `global.json`, project files, and NuGet package references while preserving rollback safety.

4. `net-migration-verifier`  
   Restores dependencies, builds the solution, and runs tests. If this step fails, the workflow stops.

5. `net-migration-pr`  
   Creates a migration branch, commits the changes, pushes them, and opens a pull request only after successful verification.

The full orchestration prompt is defined in `.github/prompts/migrate.prompt.md`.

## Safety rules

The repo guidance is explicit about safe execution:

- do not modify `global.json`, `.csproj` files, or NuGet packages outside the migration skill chain
- do not proceed to PR creation if the verification step fails
- treat any non-zero exit code or failed step result as an actual failure, even if some files were partially updated
- prefer explicit error reporting over inferred success

## Quick start

Use the migration workflow from the prompt or the repo script:

```powershell
# Run the full migration workflow
./.github/scripts/net-migration-agent.ps1
```

You can also trigger the guided flow via the prompt:

```text
/migrate
```

The prompt will step through the same sequence described above.

## Repository layout

```text
.github/
├── copilot-instructions.md
├── MIGRATION_AGENT_GUIDE.md
├── prompts/
│   └── migrate.prompt.md
├── scripts/
├── skills/
│   ├── README.md
│   ├── net-migration-analyzer/
│   ├── net-migration-integration/
│   ├── net-migration-pr/
│   ├── net-migration-updater/
│   └── net-migration-verifier/
└── workflows/

microservices/
├── AuditLogApi/
├── BackgroundJobWorker/
├── CacheManagementWorker/
├── ...
└── UserAuthApi/

results/
```

## Documentation

The `.github` folder contains the operational guidance for the migration process, including:

- `.github/copilot-instructions.md` — repo-level workflow instructions
- `.github/MIGRATION_AGENT_GUIDE.md` — end-to-end migration guide
- `.github/skills/README.md` — skill index and execution overview
- `.github/prompts/migrate.prompt.md` — automated migration prompt

## Typical use case

This repo is intended for working through multiple .NET projects in a monorepo or microservice workspace, updating them to a target SDK and compatibility baseline while validating that all dependent projects still build and test successfully.

## Status

This repository is set up as a structured migration automation framework, with the migration logic and safety controls defined in the `.github` folder rather than embedded in a single monolithic script.
