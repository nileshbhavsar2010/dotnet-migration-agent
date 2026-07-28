# Logging Setup & Configuration

## Quick Setup

```python
# logging_setup.py
import logging
import json
from pathlib import Path
from datetime import datetime

class LoggerFactory:
    """Centralized logging configuration for SRP skills"""
    
    LOG_DIR = Path(".github/logs")
    LOG_FORMAT = "[{timestamp}] [{level:8}] [{skill:20}] {message}"
    
    @staticmethod
    def setup_logger(skill_name: str):
        """Setup logger for a skill with file and console handlers"""
        
        # Create log directory
        LoggerFactory.LOG_DIR.mkdir(parents=True, exist_ok=True)
        
        # Create logger
        logger = logging.getLogger(skill_name)
        logger.setLevel(logging.DEBUG)
        
        # File handler (DEBUG level - verbose)
        fh = logging.FileHandler(LoggerFactory.LOG_DIR / f"{skill_name}.log")
        fh.setLevel(logging.DEBUG)
        
        # Console handler (INFO level - clean output)
        ch = logging.StreamHandler()
        ch.setLevel(logging.INFO)
        
        # Formatter
        formatter = logging.Formatter(
            LoggerFactory.LOG_FORMAT,
            defaults={"timestamp": datetime.now().isoformat(), "skill": skill_name}
        )
        
        fh.setFormatter(formatter)
        ch.setFormatter(formatter)
        
        logger.addHandler(fh)
        logger.addHandler(ch)
        
        return logger
    
    @staticmethod
    def log_error_to_aggregate(skill_name, error_code, message, details=None):
        """Log critical errors to aggregate error log"""
        
        error_log_path = LoggerFactory.LOG_DIR / "migration-error.log"
        
        error_entry = {
            "timestamp": datetime.now().isoformat(),
            "skill": skill_name,
            "error_code": error_code,
            "message": message,
            "details": details or {}
        }
        
        with open(error_log_path, "a") as f:
            json.dump(error_entry, f)
            f.write("\n")
```

## Usage Examples

### Example 1: Analyzer with Logging

```python
from logging_setup import LoggerFactory

class MigrationAnalyzer:
    def __init__(self):
        self.logger = LoggerFactory.setup_logger("net-migration-analyzer")
    
    def analyze(self, target_version, project_path):
        self.logger.info(f"Starting analysis for {target_version}")
        
        try:
            # Check path
            if not Path(project_path).exists():
                self.logger.error(f"Project path not found: {project_path}")
                LoggerFactory.log_error_to_aggregate(
                    "net-migration-analyzer",
                    "PROJECT_PATH_NOT_FOUND",
                    f"Directory does not exist: {project_path}"
                )
                return {"success": False, "error": "PROJECT_PATH_NOT_FOUND"}
            
            self.logger.debug(f"Project path verified: {project_path}")
            
            # Process analysis
            self.logger.info("Finding project files...")
            projects = self._find_projects(project_path)
            
            self.logger.info(f"Found {len(projects)} project(s)")
            self.logger.debug(f"Projects: {projects}")
            
            # ... rest of analysis
            
            self.logger.info("Analysis completed successfully")
            return {"success": True, "projects": projects}
            
        except Exception as e:
            self.logger.exception(f"Unexpected error: {str(e)}")
            LoggerFactory.log_error_to_aggregate(
                "net-migration-analyzer",
                "UNEXPECTED_ERROR",
                str(e),
                details={"stack_trace": traceback.format_exc()}
            )
            return {"success": False, "error": "UNEXPECTED_ERROR"}
```

### Example 2: Updater with Rollback Logging

```python
class MigrationUpdater:
    def __init__(self):
        self.logger = LoggerFactory.setup_logger("net-migration-updater")
    
    def update(self, update_spec, project_path):
        self.logger.info("Starting updates...")
        backups = {}
        
        for file_path, changes in update_spec.items():
            try:
                self.logger.debug(f"Backing up: {file_path}")
                backup_path = self._backup_file(file_path)
                backups[file_path] = backup_path
                
                self.logger.debug(f"Applying {len(changes)} changes to {file_path}")
                self._apply_changes(file_path, changes)
                
                self.logger.info(f"Updated: {file_path}")
                
            except Exception as e:
                self.logger.error(f"Failed to update {file_path}: {str(e)}")
                
                # Attempt rollback
                if file_path in backups:
                    try:
                        self._restore_from_backup(file_path, backups[file_path])
                        self.logger.info(f"Rolled back: {file_path}")
                    except Exception as rollback_e:
                        self.logger.critical(
                            f"Rollback failed for {file_path}: {str(rollback_e)}"
                        )
                        LoggerFactory.log_error_to_aggregate(
                            "net-migration-updater",
                            "ROLLBACK_FAILED",
                            f"Could not rollback {file_path}",
                            details={
                                "backup_path": backups[file_path],
                                "error": str(rollback_e)
                            }
                        )
```

### Example 3: Verifier with Process Logging

```python
class MigrationVerifier:
    def __init__(self):
        self.logger = LoggerFactory.setup_logger("net-migration-verifier")
    
    def verify(self, project_path, skip_tests=False):
        self.logger.info(f"Starting verification in {project_path}")
        
        # Restore
        try:
            self.logger.info("Running: dotnet restore")
            result = subprocess.run(
                ["dotnet", "restore"],
                cwd=project_path,
                capture_output=True,
                timeout=300
            )
            
            if result.returncode != 0:
                self.logger.error(f"Restore failed (exit code: {result.returncode})")
                self.logger.debug(f"Stderr: {result.stderr.decode()}")
                LoggerFactory.log_error_to_aggregate(
                    "net-migration-verifier",
                    "RESTORE_FAILED",
                    f"dotnet restore exited with code {result.returncode}",
                    details={"stderr": result.stderr.decode()[:500]}
                )
                return {"success": False, "error": "RESTORE_FAILED"}
            
            self.logger.info("Restore: OK")
            
        except subprocess.TimeoutExpired:
            self.logger.error("Restore timed out (300s)")
            LoggerFactory.log_error_to_aggregate(
                "net-migration-verifier",
                "RESTORE_TIMEOUT",
                "dotnet restore timed out after 300 seconds"
            )
            return {"success": False, "error": "RESTORE_TIMEOUT"}
```

## Log Output Examples

### Console Output (INFO level)
```
[2026-07-26T10:30:45.123] [INFO    ] [net-migration-analyzer] Starting analysis for 10.0
[2026-07-26T10:30:45.234] [INFO    ] [net-migration-analyzer] Found 2 project(s)
[2026-07-26T10:30:45.345] [INFO    ] [net-migration-analyzer] Analysis completed successfully
```

### File Output (DEBUG level)
```
[2026-07-26T10:30:45.123] [INFO    ] [net-migration-analyzer] Starting analysis for 10.0
[2026-07-26T10:30:45.124] [DEBUG   ] [net-migration-analyzer] Project path verified: /path/to/project
[2026-07-26T10:30:45.125] [INFO    ] [net-migration-analyzer] Finding project files...
[2026-07-26T10:30:45.156] [DEBUG   ] [net-migration-analyzer] Projects: ['/path/to/project.csproj', ...]
[2026-07-26T10:30:45.234] [INFO    ] [net-migration-analyzer] Found 2 project(s)
[2026-07-26T10:30:45.345] [INFO    ] [net-migration-analyzer] Analysis completed successfully
```

### Error Log (.github/logs/migration-error.log)
```json
{"timestamp":"2026-07-26T10:30:45Z","skill":"net-migration-analyzer","error_code":"PROJECT_PATH_NOT_FOUND","message":"Directory does not exist: /invalid/path","details":{}}
{"timestamp":"2026-07-26T10:35:22Z","skill":"net-migration-updater","error_code":"ROLLBACK_FAILED","message":"Could not rollback file.csproj","details":{"backup_path":"/tmp/backup","error":"Permission denied"}}
```

## Log Monitoring Commands

```bash
# View all activity
tail -f .github/logs/net-migration-*.log

# View only errors
grep ERROR .github/logs/*.log

# View analyzer activity
tail -f .github/logs/net-migration-analyzer.log

# View critical errors
grep CRITICAL .github/logs/migration-error.log

# Count errors by type
cat .github/logs/migration-error.log | jq -s 'group_by(.error_code) | map({code: .[0].error_code, count: length})'

# Export for analysis
cat .github/logs/migration-error.log | jq . > error-analysis.json
```

## Log Retention Policy

```
Daily Rotation:
├── .github/logs/net-migration-analyzer.log (current day)
├── .github/logs/net-migration-analyzer.log.1 (previous day)
├── .github/logs/net-migration-analyzer.log.2 (2 days ago)
└── ... (keep 7 days)

Cleanup:
├── Logs older than 30 days: archived to .github/logs/archive/
├── Archive older than 90 days: deleted
├── migration-error.log: keep indefinitely (aggregate errors)
```

## Integration with CI/CD

### GitHub Actions: Capture Logs

```yaml
- name: Run Migration
  id: migrate
  run: |
    python scripts/migrate.py
    
- name: Upload logs on failure
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: migration-logs
    path: .github/logs/
    retention-days: 30
```

### CI/CD: Parse Error Log

```yaml
- name: Check for critical errors
  run: |
    if grep "CRITICAL" .github/logs/migration-error.log; then
      echo "::error::Critical migration error detected"
      exit 1
    fi
```

## Dashboard Integration

### Prometheus Metrics (Optional)

```python
from prometheus_client import Counter, Histogram

# Metrics
migration_errors = Counter(
    'migration_errors_total',
    'Total migration errors',
    ['skill', 'error_code']
)

migration_duration = Histogram(
    'migration_duration_seconds',
    'Migration execution time'
)

# Usage
migration_errors.labels(skill='analyzer', error_code='PARSE_FAILURE').inc()
```

---

**Status:** Production-Ready Logging System
**Version:** 1.0
**Recommendation:** Implement before running skills in production
