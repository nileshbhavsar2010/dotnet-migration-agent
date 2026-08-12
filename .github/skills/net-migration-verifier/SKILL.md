---
name: net-migration-verifier
description: >-
  Runs dotnet restore, build, and test to validate a .NET migration compiles
  and passes tests, with staged, per-step error reporting. Use after
  net-migration-updater has applied changes and before committing or opening
  a pull request; also reusable standalone for any general build validation.
---
# .NET Migration Verifier Skill
 
**Single Responsibility:** Validate migration by running build and tests.
 
## Purpose
Verifies that updated .NET version compiles and tests pass. This skill is optional and reusable for any build validation.
 
## Input
- `projectPath`: Path to solution root
- `skipTests`: Optional, default false
## Process
1. `dotnet restore`
2. `dotnet build`
3. `dotnet test` (unless skipped)
## Output
```
Build Status: ✅ SUCCESS
Tests Passed: 5/5
Ready for commit
```
 
Or detailed error report if failures detected.
 
## Error Handling
 
### Stage-by-Stage Validation
```
[Stage 1: Restore]
  → If fails: Return error with stderr output
  → If timeout: Return TIMEOUT error
  → If success: Continue to build
 
[Stage 2: Build]
  → If fails: Return BUILD_FAILED with compiler errors
  → If timeout: Return BUILD_TIMEOUT
  → If success: Continue to test (unless skip_tests=true)
 
[Stage 3: Test]
  → If fails: Return with partial=true (build OK, tests failed)
  → If timeout: Return with warning
  → If success: Return success=true
```
 
### Error Responses
```json
{
  "success": false,
  "error": "BUILD_FAILED",
  "stage": "build",
  "exit_code": 1,
  "stderr": "error NU1101: Unable to find package...",
  "suggestion": "Check NuGet sources and network connectivity",
  "log_file": ".github/logs/net-migration-verifier.log"
}
```
 
### Error Categories
- `RESTORE_FAILED` - Package restore error
- `RESTORE_TIMEOUT` - Restore took >300s
- `BUILD_FAILED` - Compilation error
- `BUILD_TIMEOUT` - Build took >600s
- `TEST_FAILED` - Test failures (not fatal)
- `UNEXPECTED_ERROR` - Unhandled exception
### Silent Failure Prevention
- ❌ NOT returning success if build failed
- ✅ Explicit error codes per stage
- ✅ Full stderr output in response
- ✅ Exit codes preserved
- ✅ Actionable suggestions provided
- ✅ All commands logged with output
## Logging
All operations logged to `.github/logs/net-migration-verifier.log`
- INFO: Stage start/completion
- DEBUG: Full command output
- ERROR: Stage failures with exit codes
- WARN: Tests failed but build succeeded
## Characteristics
- ✅ Single terminal execution
- ✅ No file modifications
- ✅ Reusable (not migration-specific)
- ✅ Optional execution (can skip if confident)
- ✅ Fast validation
## Token Cost
~2,000 tokens per execution (depending on build size)
 
## Use When
- After `.net-migration-updater` applies changes
- Before committing/creating PR
- Optional: Can skip for faster token usage if code review is sufficient
## Reusability
Can be used independently for any build validation task.
 