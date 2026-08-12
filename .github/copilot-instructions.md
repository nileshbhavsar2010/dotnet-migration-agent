# .NET Migration Agent

This repo migrates .NET projects using a chain of Agent Skills under
`.github/skills/`, run in this order:

1. `net-migration-analyzer` — scans and produces an update spec (read-only)
2. `net-migration-integration` — scaffolds/updates integration tests
3. `net-migration-updater` — applies the update spec (with backup/rollback)
4. `net-migration-verifier` — restores, builds, and runs tests
5. `net-migration-pr` — branch, commit, push, and open a PR (only if step 4 passed)

To run the full chain, use the `/migrate` prompt (`.github/prompts/migrate.prompt.md`).
Each skill has full documentation in its own `SKILL.md`.

Do not update `global.json`, `.csproj` files, or NuGet packages outside of
this skill chain. Do not proceed to `net-migration-pr` if
`net-migration-verifier` reports failure.