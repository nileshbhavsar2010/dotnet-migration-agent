---
name: net-migration-analyzer
description: >-
  Scans .NET project files (.csproj, global.json) and produces a structured
  JSON specification of required target framework and NuGet package version
  changes, without modifying any files. Use first whenever a .NET version
  migration is requested, before any files are changed.
---
# .NET Migration Analyzer Skill
 
**Single Responsibility:** Analyze project structure and identify all required version changes.
 
## Purpose
Scans .NET project files and generates a structured specification of all required updates without making any modifications.
 
## Input
- `targetVersion`: Target .NET version (e.g., "10.0")
- `projectPath`: Path to solution root
## Output
Structured JSON with:
```json
{
  "globalJson": {"currentVersion": "6.0.421", "targetVersion": "10.0.0"},
  "projects": [
    {
      "path": "src/CustomerOrderApi/CustomerOrderApi.csproj",
      "currentTarget": "net6.0",
      "targetFramework": "net10.0",
      "packages": [
        {"name": "Microsoft.EntityFrameworkCore", "current": "6.0.21", "target": "8.0.7"},
        {"name": "Serilog.AspNetCore", "current": "6.1.0", "target": "8.1.0"}
      ]
    }
  ],
  "breakingChanges": [],
  "riskLevel": "low"
}
```
 
## No Side Effects
- ✅ Read-only operation
- ✅ No file modifications
- ✅ No terminal commands
- ✅ Structured output for next skill
## Error Handling
 
### Graceful Failure Prevention
✅ Validates all inputs before processing
✅ Checks file existence & readability
✅ Handles malformed XML gracefully
✅ Logs all operations with DEBUG detail
✅ No partial success (all-or-nothing per-file)
 
### Error Responses
```json
{
  "success": false,
  "error": "PROJECT_PATH_NOT_FOUND",
  "message": "Directory does not exist: /path",
  "suggestion": "Verify projectPath parameter",
  "log_file": ".github/logs/net-migration-analyzer.log"
}
```
 
### Common Errors
- `PROJECT_PATH_NOT_FOUND` - Invalid project path
- `PARSE_FAILURE` - Malformed .csproj XML
- `NO_PROJECTS_FOUND` - No .csproj files detected
- `INVALID_VERSION_FORMAT` - Wrong version format
### Silent Failure Prevention
- ❌ NOT silently returning empty results
- ✅ Explicitly logs and returns error codes
- ✅ Provides actionable suggestions in response
- ✅ Comprehensive logging to file
## Logging
All operations logged to `.github/logs/net-migration-analyzer.log`
- INFO: Major operations
- DEBUG: Detailed file processing
- ERROR: Failures with recovery suggestions
## Token Cost
~2,500 tokens per execution
 
## Use When
User requests `.NET version migration` → Run this skill first to get update spec.