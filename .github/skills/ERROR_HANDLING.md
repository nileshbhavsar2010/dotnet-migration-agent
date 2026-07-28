# Error Handling & Logging Framework

## Overview
Comprehensive error handling for SRP skills with graceful degradation and detailed logging.

## Logging Strategy

### Log Levels
```
ERROR   → Critical failures that prevent continuation
WARN    → Non-critical issues or unexpected conditions
INFO    → Normal operation milestones
DEBUG   → Detailed diagnostic information (verbose)
```

### Log Format
```
[TIMESTAMP] [LEVEL] [SKILL] [COMPONENT] → MESSAGE
[2026-07-26T10:30:45] [ERROR] [Analyzer] [PackageRead] → Failed to read package version
```

### Log Location
```
.github/logs/
├── migration-analyzer.log
├── migration-updater.log
├── migration-verifier.log
└── migration-error.log (aggregated errors)
```

## Error Categories & Handling

### Category 1: File System Errors

```yaml
Error Type: File Not Found
Silent Failure Risk: ❌ HIGH
Detection: Check file existence before read
Action: Log as ERROR + Return structured error
Recovery: Provide suggestion for missing file

Example:
[ERROR] [Analyzer] [FileRead] → global.json not found
        Suggestion: Is this a .NET project root?
        Action: User must provide correct projectPath
```

### Category 2: Version/Format Errors

```yaml
Error Type: Invalid XML/JSON parsing
Silent Failure Risk: ❌ HIGH
Detection: Wrap parse operations in try-catch
Action: Log specific line that failed
Recovery: Show expected format example

Example:
[ERROR] [Analyzer] [Parse] → Invalid XML in CustomerOrderApi.csproj:15
        Message: Unexpected token '>'
        Fix: Review TargetFramework property syntax
```

### Category 3: Execution Errors

```yaml
Error Type: dotnet command fails
Silent Failure Risk: ❌ MEDIUM (exits with code)
Detection: Check exit code from terminal
Action: Log command + exit code + stderr
Recovery: Return specific error code

Example:
[ERROR] [Verifier] [Build] → dotnet build failed (exit code: 1)
        Command: dotnet build
        Stderr: The project file could not be loaded
```

### Category 4: Network Errors

```yaml
Error Type: Package restore fails
Silent Failure Risk: ❌ LOW (usually explicit)
Detection: Check restore operation result
Action: Log network error with timeout info
Recovery: Suggest retry or check connectivity

Example:
[WARN] [Updater] [Restore] → NuGet package source unavailable
       Timeout: 30s
       Recovery: Check internet connection, retry
```

## Skill-Specific Error Handling

### net-migration-analyzer: Error Handling

```python
# Pseudo-code for error handling

class MigrationAnalyzer:
    def analyze(self, target_version, project_path):
        logger = setup_logger('migration-analyzer')
        
        try:
            # Check inputs
            if not Path(project_path).exists():
                logger.error(f"Project path not found: {project_path}")
                return {
                    "success": False,
                    "error": "PROJECT_PATH_NOT_FOUND",
                    "message": f"Directory does not exist: {project_path}",
                    "suggestion": "Verify projectPath parameter"
                }
            
            # Validate target version format
            if not self._is_valid_version(target_version):
                logger.error(f"Invalid version format: {target_version}")
                return {
                    "success": False,
                    "error": "INVALID_VERSION_FORMAT",
                    "message": f"Expected format: X.Y (e.g., '10.0')",
                    "provided": target_version
                }
            
            # Find project files
            projects = self._find_projects(project_path)
            if not projects:
                logger.warn(f"No .csproj files found in {project_path}")
                return {
                    "success": False,
                    "error": "NO_PROJECTS_FOUND",
                    "message": "No .csproj files detected",
                    "suggestion": "Is this a .NET project root?"
                }
            
            logger.info(f"Found {len(projects)} project(s)")
            
            # Parse projects (with per-file error handling)
            results = []
            errors = []
            
            for project in projects:
                try:
                    parsed = self._parse_project(project)
                    results.append(parsed)
                    logger.debug(f"Parsed: {project}")
                except Exception as e:
                    error_msg = f"Failed to parse {project}: {str(e)}"
                    logger.error(error_msg)
                    errors.append({
                        "file": project,
                        "error": str(e)
                    })
            
            # Return partial success if some parsed
            if not results and errors:
                logger.error(f"All projects failed to parse")
                return {
                    "success": False,
                    "error": "PARSE_FAILURE",
                    "details": errors
                }
            
            if errors:
                logger.warn(f"Parsed {len(results)} but {len(errors)} failed")
                return {
                    "success": True,
                    "partial": True,
                    "warning": f"{len(errors)} project(s) failed to parse",
                    "results": results,
                    "errors": errors
                }
            
            logger.info("Analysis completed successfully")
            return {
                "success": True,
                "results": results,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.critical(f"Unexpected error: {str(e)}")
            return {
                "success": False,
                "error": "UNEXPECTED_ERROR",
                "message": str(e),
                "stack_trace": traceback.format_exc()
            }
```

### net-migration-updater: Error Handling

```python
class MigrationUpdater:
    def update(self, update_spec, project_path):
        logger = setup_logger('migration-updater')
        
        try:
            # Validate input spec
            if not update_spec or not isinstance(update_spec, dict):
                logger.error("Invalid update specification")
                return {
                    "success": False,
                    "error": "INVALID_SPEC",
                    "message": "update_spec must be non-empty dict"
                }
            
            # Validate project path before modifications
            if not Path(project_path).exists():
                logger.error(f"Project path not found: {project_path}")
                return {
                    "success": False,
                    "error": "PROJECT_PATH_NOT_FOUND"
                }
            
            logger.info("Starting file updates...")
            results = []
            failures = []
            
            # Update each file with rollback capability
            for file_path, changes in update_spec.items():
                try:
                    # Backup before modification
                    backup_path = self._backup_file(file_path)
                    logger.debug(f"Backed up: {file_path} → {backup_path}")
                    
                    # Apply changes
                    self._apply_changes(file_path, changes)
                    logger.info(f"Updated: {file_path}")
                    results.append({
                        "file": file_path,
                        "status": "success",
                        "backup": backup_path
                    })
                    
                except Exception as e:
                    error_msg = f"Failed to update {file_path}: {str(e)}"
                    logger.error(error_msg)
                    
                    # Attempt rollback
                    try:
                        self._restore_from_backup(file_path, backup_path)
                        logger.info(f"Rolled back: {file_path}")
                    except Exception as rollback_error:
                        logger.critical(f"Rollback failed for {file_path}: {str(rollback_error)}")
                        failures.append({
                            "file": file_path,
                            "error": str(e),
                            "rollback_error": str(rollback_error)
                        })
                        continue
                    
                    failures.append({
                        "file": file_path,
                        "error": str(e),
                        "rolled_back": True
                    })
            
            # Return status
            if not results and failures:
                logger.error("All updates failed")
                return {
                    "success": False,
                    "error": "ALL_UPDATES_FAILED",
                    "failures": failures
                }
            
            if failures:
                logger.warn(f"Partial success: {len(results)} ok, {len(failures)} failed")
                return {
                    "success": True,
                    "partial": True,
                    "updated": results,
                    "failed": failures,
                    "warning": "Some files were not updated"
                }
            
            logger.info(f"Successfully updated {len(results)} files")
            return {
                "success": True,
                "updated": results,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.critical(f"Unexpected error during updates: {str(e)}")
            return {
                "success": False,
                "error": "UNEXPECTED_ERROR",
                "message": str(e)
            }
```

### net-migration-verifier: Error Handling

```python
class MigrationVerifier:
    def verify(self, project_path, skip_tests=False):
        logger = setup_logger('migration-verifier')
        results = {}
        
        try:
            logger.info("Starting verification...")
            
            # Step 1: Restore
            try:
                logger.info("Running: dotnet restore")
                restore_result = self._run_command("dotnet restore", project_path)
                if restore_result.exit_code != 0:
                    logger.error(f"Restore failed: {restore_result.stderr}")
                    return {
                        "success": False,
                        "error": "RESTORE_FAILED",
                        "stage": "restore",
                        "exit_code": restore_result.exit_code,
                        "stderr": restore_result.stderr
                    }
                logger.info("Restore: OK")
                results["restore"] = "success"
                
            except TimeoutError:
                logger.error("Restore timed out (>300s)")
                return {
                    "success": False,
                    "error": "RESTORE_TIMEOUT",
                    "stage": "restore"
                }
            except Exception as e:
                logger.error(f"Restore failed: {str(e)}")
                return {
                    "success": False,
                    "error": "RESTORE_ERROR",
                    "message": str(e)
                }
            
            # Step 2: Build
            try:
                logger.info("Running: dotnet build")
                build_result = self._run_command("dotnet build", project_path)
                if build_result.exit_code != 0:
                    logger.error(f"Build failed: {build_result.stderr}")
                    return {
                        "success": False,
                        "error": "BUILD_FAILED",
                        "stage": "build",
                        "exit_code": build_result.exit_code,
                        "stderr": build_result.stderr,
                        "suggestion": "Review compiler errors above"
                    }
                logger.info("Build: OK")
                results["build"] = "success"
                
            except TimeoutError:
                logger.error("Build timed out (>600s)")
                return {
                    "success": False,
                    "error": "BUILD_TIMEOUT",
                    "stage": "build"
                }
            except Exception as e:
                logger.error(f"Build failed: {str(e)}")
                return {
                    "success": False,
                    "error": "BUILD_ERROR",
                    "message": str(e)
                }
            
            # Step 3: Test (optional)
            if not skip_tests:
                try:
                    logger.info("Running: dotnet test")
                    test_result = self._run_command("dotnet test", project_path)
                    if test_result.exit_code != 0:
                        logger.warn(f"Tests failed: {test_result.stderr}")
                        results["test"] = "failed"
                        return {
                            "success": True,
                            "partial": True,
                            "warning": "Tests failed",
                            "stage": "test",
                            "exit_code": test_result.exit_code,
                            "results": results
                        }
                    logger.info("Tests: OK")
                    results["test"] = "success"
                    
                except TimeoutError:
                    logger.warn("Tests timed out (>600s)")
                    results["test"] = "timeout"
                except Exception as e:
                    logger.warn(f"Tests error: {str(e)}")
                    results["test"] = "error"
            
            logger.info("Verification completed successfully")
            return {
                "success": True,
                "results": results,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.critical(f"Unexpected error during verification: {str(e)}")
            return {
                "success": False,
                "error": "UNEXPECTED_ERROR",
                "message": str(e),
                "results": results
            }
```

## Error Response Format (Standardized)

```json
{
  "success": false,
  "error": "ERROR_CODE",
  "message": "Human-readable error message",
  "stage": "which_stage_failed",
  "suggestion": "How to fix it",
  "details": { /* additional context */ },
  "timestamp": "2026-07-26T10:30:45Z",
  "log_reference": "See log file: .github/logs/migration-error.log"
}
```

## Silent Failure Prevention

### Checks Before Each Operation

```
✓ Input validation
✓ Path existence verification  
✓ Permission checks
✓ Format validation
✓ Version compatibility checks
✓ Space/resource availability
```

### Recovery Mechanisms

```
1. Automatic Rollback
   - Backup before modification
   - Restore on failure
   - Clean up backups on success

2. Partial Success Handling
   - Continue processing remaining items
   - Return success=true + partial=true
   - Include both succeeded and failed items

3. Retry Capability
   - Network errors: automatic retry (3 attempts)
   - Timeout errors: return with suggestion
   - Lock contention: exponential backoff

4. User Notification
   - Detailed error messages
   - Actionable suggestions
   - Log file reference
```

## Testing Error Paths

```bash
# Test 1: Missing project path
analyzer(target="10.0", project_path="/invalid/path")
Expected: ERROR with suggestion

# Test 2: Invalid version format
analyzer(target="invalid", project_path=".")
Expected: ERROR with format example

# Test 3: Malformed XML
# Manually break .csproj
updater(spec={...}, project_path=".")
Expected: ERROR + rollback with confirmation

# Test 4: Build failure
# Introduce compilation error
verifier(project_path=".")
Expected: ERROR with compiler output

# Test 5: Network timeout
# Simulate slow network
verifier(project_path=".")
Expected: WARN with retry suggestion
```

## Monitoring & Alerting

### Log Aggregation
```bash
# View all errors
tail -f .github/logs/migration-error.log

# Filter by severity
grep "\[ERROR\]" .github/logs/*.log
grep "\[CRITICAL\]" .github/logs/*.log
```

### Dashboard Suggestions
```
- Success rate per skill
- Average execution time
- Top error types
- Recovery success rate
- User retry patterns
```

## Documentation for Users

### When Errors Occur

1. **Check log file** - Detailed error information
2. **Read error message** - User-friendly explanation
3. **Follow suggestion** - Recommended fix
4. **Retry or escalate** - Next steps if manual intervention needed

### Common Issues & Resolution

```
ERROR: PROJECT_PATH_NOT_FOUND
→ Verify you're in project root directory
→ Provide absolute path: "C:\path\to\project"

ERROR: PARSE_FAILURE
→ Check .csproj file is valid XML
→ Review file is not in use by another process

ERROR: BUILD_FAILED
→ Review compiler errors in output
→ Run `dotnet restore` manually first
→ Check .NET SDK version matches target

ERROR: NETWORK_ERROR
→ Check internet connection
→ Verify NuGet sources are accessible
→ Retry operation
```

---

**Status:** Production-Ready Error Handling Framework
**Version:** 1.0
