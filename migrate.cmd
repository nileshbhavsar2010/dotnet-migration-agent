@echo off
REM Wrapper to run the migration agent PowerShell script in non-interactive automatic mode by default.
REM Pass --dry to run in dry-run mode (no automatic git/PR/actions).

SETLOCAL
set "ARGS=%*"
if /I "%ARGS%"=="--dry" (
	powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0\.github\scripts\net-migration-agent.ps1" %*
) else (
	powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0\.github\scripts\net-migration-agent.ps1" -NonInteractive -CreateIntegration -Auto %*
)
ENDLOCAL
EXIT /B %ERRORLEVEL%
