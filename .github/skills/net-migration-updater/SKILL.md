# .NET Migration Updater Skill

**Single Responsibility:** Apply version updates to project files based on analyzer output.

## Purpose
Takes structured update specification from `.net-migration-analyzer` and applies all changes in a single batch operation.

## Input
- `updateSpec`: JSON from analyzer skill
- `projectPath`: Path to solution root

## Process
1. Extract all file paths and changes from spec
2. Create batch replacements using `multi_replace_string_in_file`
3. Return confirmation of applied changes

## Output
```
✅ Updated: global.json
✅ Updated: src/CustomerOrderApi/CustomerOrderApi.csproj
✅ Updated: tests/CustomerOrderApi.Tests/CustomerOrderApi.Tests.csproj
Total changes: 3 files, 12 package updates
```

## Error Handling

### Safety Mechanisms
✅ **Automatic Backup** - Backs up each file before modification
✅ **Rollback on Failure** - Restores from backup if update fails
✅ **Batch Validation** - Validates spec before applying
✅ **Per-File Recovery** - Continues processing if one file fails
✅ **Detailed Logging** - Every operation logged with context

### Error Scenarios
```
Scenario 1: File Not Writable
→ Logs error with permission info
→ Skips file, continues batch
→ Returns partial success

Scenario 2: Backup Fails
→ Logs critical error
→ Skips file (won't modify without backup)
→ Continues with other files

Scenario 3: Update Fails
→ Logs error detail
→ Automatically restores from backup
→ Continues with other files

Scenario 4: Rollback Fails
→ Logs CRITICAL error
→ Stops batch processing
→ Returns with suggestion to manually restore
```

### Error Responses
```json
{
  "success": true,
  "partial": true,
  "updated": [{"file": "global.json", "status": "success"}],
  "failed": [{"file": "file.csproj", "error": "Permission denied", "rolled_back": true}],
  "log_file": ".github/logs/net-migration-updater.log"
}
```

### Silent Failure Prevention
- ❌ NOT silently applying partial changes
- ✅ Explicit success/partial/failed status
- ✅ Lists which files succeeded/failed
- ✅ Backup paths stored for recovery
- ✅ Automatic rollback on failure
- ✅ Critical errors logged separately

## Logging
All operations logged to `.github/logs/net-migration-updater.log`
- INFO: File updates, rollbacks
- DEBUG: Backup locations, change details
- ERROR: Update failures with recovery status
- CRITICAL: Unrecoverable errors (rollback failed)

## Token Cost
~3,000 tokens per execution

## Use When
- After `.net-migration-analyzer` provides update specification
- Ready to commit changes to disk
