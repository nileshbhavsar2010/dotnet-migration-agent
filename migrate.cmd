@echo off
REM Wrapper to run the migration agent PowerShell script in non-interactive automatic mode by default.
REM Usage:
REM   migrate.cmd [--dry] [--root <path>]
REM   migrate.cmd g:\path\to\repo

SETLOCAL
set "DRY=0"
set "ROOT=%CD%"
setlocal enabledelayedexpansion
:nextArg
if "%~1"=="" goto run
if /I "%~1"=="--dry" (
    set "DRY=1"
    shift
    goto nextArg
)
if /I "%~1"=="--root" (
    shift
    if "%~1"=="" (
        echo Missing path after --root
        exit /B 1
    )
    set "ROOT=%~1"
    shift
    goto nextArg
)
if "%~1"=="--help" (
    echo Usage: migrate.cmd [--dry] [--root ^<repoPath^>]
    echo Default: run against current folder with non-interactive auto mode.
    exit /B 0
)
REM If first argument is a path and not a known switch, treat it as root path.
if "%ROOT%"=="%CD%" (
    set "ROOT=%~1"
    shift
)
goto nextArg
:run
for %%I in ("%~f0") do set "SCRIPT_DIR=%%~dpI"
if not exist "%SCRIPT_DIR%\.github\scripts\net-migration-agent.ps1" (
    echo ERROR: Agent script not found at "%SCRIPT_DIR%\.github\scripts\net-migration-agent.ps1"
    echo Ensure migrate.cmd is run from the dotnet-migration-agent repo root or use the correct file path.
    exit /B 1
)
if "%DRY%"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\.github\scripts\net-migration-agent.ps1" -RepoRoot "%ROOT%" -CreateIntegration %*
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\.github\scripts\net-migration-agent.ps1" -RepoRoot "%ROOT%" -NonInteractive -CreateIntegration -Auto %*
)
ENDLOCAL
EXIT /B %ERRORLEVEL%
