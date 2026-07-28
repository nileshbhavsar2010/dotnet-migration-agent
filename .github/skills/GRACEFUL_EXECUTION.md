# Error Handling & Graceful Execution Guide

## Overview
Comprehensive guide to preventing silent failures and handling errors gracefully in SRP skills.

## Quick Answer to "Will This Fail Silently?"

### ❌ NO - Here's Why

```
Every operation has:
1. ✅ Input validation (fail fast)
2. ✅ File existence checks (before modification)
3. ✅ Error logging (to file + console)
4. ✅ Explicit error responses (never silent)
5. ✅ Recovery mechanisms (rollback, retry)
6. ✅ Status tracking (success/partial/failed)
```

## Error Handling Architecture

### Layer 1: Prevention (Input Validation)

```python
# Before any file operation:
def safe_operation(project_path, config):
    
    # Validate inputs
    if not project_path:
        return error("PROJECT_PATH_MISSING")
    
    if not Path(project_path).exists():
        return error("PROJECT_PATH_NOT_FOUND")
    
    if not Path(project_path).is_dir():
        return error("PROJECT_PATH_NOT_DIRECTORY")
    
    # Only proceed if all validations pass
    return execute_operation(project_path, config)
```

### Layer 2: Logging (Every Operation)

```python
# Every operation is logged:
logger.info(f"Starting operation: {operation_name}")
try:
    result = perform_operation()
    logger.info(f"Operation succeeded: {result}")
except Exception as e:
    logger.error(f"Operation failed: {str(e)}")
    logger.exception(e)  # Stack trace
    return error_response()
```

### Layer 3: Recovery (Automatic Rollback)

```python
# For file modifications:
def update_file_safely(file_path, changes):
    
    # Step 1: Backup
    backup = backup_file(file_path)
    logger.debug(f"Backed up: {file_path} → {backup}")
    
    try:
        # Step 2: Modify
        apply_changes(file_path, changes)
        logger.info(f"Updated: {file_path}")
        return success()
        
    except Exception as e:
        # Step 3: Rollback on failure
        logger.error(f"Update failed: {str(e)}")
        try:
            restore_file(file_path, backup)
            logger.info(f"Rolled back: {file_path}")
            return error("UPDATE_FAILED_ROLLED_BACK")
        except Exception as rollback_e:
            # Step 4: Log if rollback fails
            logger.critical(f"Rollback failed: {str(rollback_e)}")
            return error("ROLLBACK_FAILED", severity="CRITICAL")
```

### Layer 4: Response (Explicit Status)

```json
// Success
{
  "success": true,
  "results": {...}
}

// Partial (some succeeded, some failed)
{
  "success": true,
  "partial": true,
  "succeeded": [...],
  "failed": [...],
  "log_file": ".github/logs/..."
}

// Failure
{
  "success": false,
  "error": "ERROR_CODE",
  "message": "Human-readable error",
  "suggestion": "How to fix",
  "log_file": ".github/logs/..."
}
```

## Execution Flow with Error Handling

### Scenario 1: Happy Path
```
START
  ↓
[Analyzer] Reads files successfully
  ↓ (success=true, generates spec)
[Updater] Backs up & modifies files
  ↓ (success=true, all files updated)
[Verifier] Build succeeds
  ↓ (success=true, all tests pass)
SUCCESS ✅
  ↓
Logs: All INFO entries, clean execution
```

### Scenario 2: Partial Failure (File Permission)
```
START
  ↓
[Updater] 
  ├─ File 1: ✅ Updated
  ├─ File 2: ❌ Permission denied → Backed up, rolled back
  ├─ File 3: ✅ Updated
  ↓ (success=true, partial=true)
PARTIAL SUCCESS ⚠️
  ↓
Response: Lists succeeded + failed files
Log: ERROR entry for failed file
```

### Scenario 3: Recovery (Build Fails)
```
START
  ↓
[Verifier]
  ├─ Restore: ✅ OK
  ├─ Build: ❌ Compilation error
  ↓
FAILURE ❌
  ↓
Response: BUILD_FAILED + compiler errors
Log: ERROR entry with stderr output
Recovery: Suggestion to fix compilation
```

### Scenario 4: Catastrophic (Rollback Fails)
```
START
  ↓
[Updater]
  ├─ Update file: ❌ Failed
  ├─ Rollback attempt: ❌ Also failed
  ↓
CRITICAL FAILURE 🚨
  ↓
Response: ROLLBACK_FAILED + manual recovery instructions
Log: CRITICAL entry + recovery instructions
Action: Manual file restoration required
```

## Logging in Action

### Console Output (What User Sees)
```
[2026-07-26T10:30:45] [INFO    ] [net-migration-analyzer] Starting analysis for 10.0
[2026-07-26T10:30:46] [INFO    ] [net-migration-analyzer] Found 2 projects
[2026-07-26T10:30:46] [INFO    ] [net-migration-analyzer] Analysis completed successfully

[2026-07-26T10:30:47] [INFO    ] [net-migration-updater] Starting updates...
[2026-07-26T10:30:47] [INFO    ] [net-migration-updater] Updated: global.json
[2026-07-26T10:30:48] [INFO    ] [net-migration-updater] Updated: CustomerOrderApi.csproj
✅ Migration complete
```

### File Output (Full Debug Trail)
```
[2026-07-26T10:30:45.001] [DEBUG   ] [net-migration-analyzer] Reading: g:\project\global.json
[2026-07-26T10:30:45.002] [DEBUG   ] [net-migration-analyzer] Found version: 6.0.421
[2026-07-26T10:30:45.003] [DEBUG   ] [net-migration-analyzer] Reading: g:\project\src\*.csproj
[2026-07-26T10:30:45.124] [INFO    ] [net-migration-analyzer] Found 2 project(s)
[2026-07-26T10:30:45.125] [DEBUG   ] [net-migration-analyzer] Project 1: CustomerOrderApi.csproj
[2026-07-26T10:30:45.126] [DEBUG   ] [net-migration-analyzer] Project 2: CustomerOrderApi.Tests.csproj
[2026-07-26T10:30:45.345] [INFO    ] [net-migration-analyzer] Analysis completed successfully
```

### Error Log (Aggregated Failures)
```json
{"timestamp":"2026-07-26T10:35:22Z","skill":"net-migration-updater","error_code":"FILE_NOT_WRITABLE","message":"Permission denied: file.csproj","details":{"file":"file.csproj","errno":13,"rolled_back":true}}
```

## Check for Silent Failures

### Test Case 1: Invalid Project Path
```bash
Analyst(project_path="/invalid/path", target="10.0")
Expected: ERROR response with "PROJECT_PATH_NOT_FOUND"
Log entry: ERROR [Analyzer] [Validate] → Project path not found: /invalid/path
Result: ✅ Not silent - error explicitly returned
```

### Test Case 2: Malformed XML
```bash
Updater(spec={...}, project_path=".")
# Manually corrupt .csproj XML
Expected: ERROR response with parse error details
Log entry: ERROR [Updater] [Parse] → XML parsing failed at line 5
Rollback: Automatic restoration from backup
Result: ✅ Not silent - error logged + recovered
```

### Test Case 3: Build Compilation Error
```bash
Verifier(project_path=".")
# Introduce compilation error in code
Expected: ERROR response with compiler messages
Log entry: ERROR [Verifier] [Build] → dotnet build failed (exit code: 1)
Suggestion: "Review compiler errors"
Result: ✅ Not silent - error explicit + actionable
```

### Test Case 4: Permission Denied During Update
```bash
Updater(spec={...}, project_path=".")
# Remove write permissions on a file
Expected: PARTIAL SUCCESS response
Log entry: ERROR [Updater] [Write] → Permission denied
Rollback: ✅ Successfully rolled back
Files: Lists which succeeded, which failed
Result: ✅ Not silent - partial status explicit
```

## Recovery Procedures

### If Updater Fails During File Write

**Automatic:**
1. Logs error with file path
2. Attempts rollback from backup
3. Returns success/partial/failed status

**Manual (if rollback fails):**
```bash
# Recovery instructions in log file
Log: See backup file at: .github/temp/backup_global.json_20260726
Manual restore: cp .github/temp/backup_global.json_20260726 global.json
```

### If Build Verification Fails

**No recovery needed (verify only)**
- Build output shown in log
- Compiler errors provided in response
- Suggestion for next steps

**Next steps (user action):**
1. Review compiler errors
2. Fix issues in code
3. Re-run verifier

### If Analyzer Detects Unsupported Version

**No modifications made**
- Analysis returns error code
- Suggestion to manually upgrade
- No risk to existing code

## Monitoring & Alerting

### Watch for Errors
```bash
# Real-time error monitoring
tail -f .github/logs/migration-error.log | jq .

# Count errors by type
cat .github/logs/migration-error.log | jq -s 'group_by(.error_code) | map({code: .[0].error_code, count: length})'

# Find CRITICAL errors
grep CRITICAL .github/logs/*.log
```

### GitHub Actions Integration
```yaml
- name: Check for Migration Errors
  run: |
    if grep -q "CRITICAL" .github/logs/migration-error.log; then
      echo "::error::Critical error detected in migration"
      exit 1
    fi
```

## Documentation Summary

| Document | Purpose |
|----------|---------|
| ERROR_HANDLING.md | Comprehensive error framework |
| LOGGING_SETUP.md | Logging implementation |
| Individual SKILL.md | Error handling per skill |
| GRACEFUL_EXECUTION.md | This file - practical guide |

## Key Takeaways

```
✅ YES - All errors are explicit
✅ YES - All operations are logged
✅ YES - Failures have recovery mechanisms
✅ YES - Status is always clear (success/partial/failed)
✅ YES - Error messages are actionable
❌ NO - Nothing fails silently
❌ NO - Partial changes without notification
❌ NO - Lost error information
```

---

**Status:** Production Ready
**Version:** 1.0
**Recommendation:** Review before running in production
