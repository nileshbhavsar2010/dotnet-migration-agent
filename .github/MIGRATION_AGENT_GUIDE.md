# 🚀 .NET Migration Agent - Complete Guide

**Status:** ✅ Production Ready  
**Type:** End-to-End Multi-Skill Orchestrator  
**Version:** 2.0  
**Date:** 2026-07-26

---

## 📖 Table of Contents

1. [Quick Start](#quick-start)
2. [Step-by-Step Process](#step-by-step-process)
3. [Verification Checklist](#verification-checklist)
4. [Error Handling & Recovery](#error-handling--recovery)
5. [Commands Reference](#commands-reference)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Quick Start

### Command to Start Migration:

```bash
# Option 1: PowerShell (Recommended)
.\.github\scripts\net-migration-agent.ps1

# Option 2: Command Prompt
migrate.cmd

# Option 3: Specify version
.\.github\scripts\net-migration-agent.ps1 -TargetVersion "10.0"
```

**Then follow the interactive prompts.**

If you prefer to run the migration fully automatically (no prompts), use the wrapper which runs in non-interactive mode by default:

```powershell
migrate.cmd
```

To run a dry-run (no automatic git/push/PR or scaffolding), pass `--dry`:

```powershell
migrate.cmd --dry
```

---

## 📋 Step-by-Step Process

### ✅ STEP 1: SELECT TARGET VERSION

**Action:** Agent asks user to select target .NET version

**Display:**
```
Available .NET versions:
1. .NET 6.0
2. .NET 7.0
3. .NET 8.0
4. .NET 9.0
5. .NET 10.0

Select version (1-5): _
```

**Decision Point:** 
- Enter number corresponding to desired version
- Agent stores selection for next steps

**Expected Outcome:**
```
✅ Selected: .NET 10.0
```

---

### ✅ STEP 2: VALIDATE .NET SDK

**Action:** Check if target SDK is installed on system

**Command:**
```powershell
dotnet --list-sdks
```

**Display:**
```
Installed .NET SDKs:
6.0.421 [C:\Program Files\dotnet\sdk]
10.0.104 [C:\Program Files\dotnet\sdk]

✅ .NET 10.0 SDK is installed
```

**Decision Points:**
- **If SDK found:** Continue ✅
- **If SDK NOT found:** 
  - Show: `⚠️ .NET 10.0 SDK is NOT installed`
  - Ask: `Continue anyway? (y/n)`
  - Option to install: `winget install Microsoft.DotNet.SDK.10.0`

**Expected Outcome:**
```
✅ .NET 10.0 SDK validated
```

---

### ✅ STEP 3: DISCOVER & ANALYZE PROJECTS

**Action:** Find all .csproj files in workspace

**Command:**
```powershell
Get-ChildItem -Path . -Filter "*.csproj" -Recurse
```

**Display:**
```
Found projects:
• CustomerOrderApi.csproj (src/CustomerOrderApi)
• CustomerOrderApi.Tests.csproj (tests/CustomerOrderApi.Tests)

✅ Projects found: 2
```

**Validations:**
- ✅ At least one .csproj file exists
- ✅ Files are valid XML
- ✅ TargetFramework property present

**Expected Outcome:**
```
✅ 2 projects discovered successfully
```

---

### ✅ STEP 4: CAPTURE TEST BASELINE

**Action:** Run tests BEFORE migration to establish baseline

**Command:**
```powershell
dotnet test --no-build --verbosity quiet
```

**Display:**
```
Running: dotnet test

Test Run Successful.

Total tests: 5
Passed: 5
Failed: 0
Skipped: 0

✅ Baseline captured
```

**Why This Matters:**
- Ensures tests work with current version
- Provides comparison point after migration
- Helps identify migration-related issues

**Expected Outcome:**
```
✅ Baseline tests captured (5/5 passed)
```

---

### ✅ STEP 5: CREATE OR UPDATE INTEGRATION TEST CASES

**Action:** Ensure integration tests exist and are updated for the migrated .NET target.

**What This Means:**
- Detect whether an integration test project is already present
- If not, scaffold a minimal integration test project and add a sample test case
- If present, update project references and packages for .NET 10.0
- Ensure the tests target the migrated application behavior

**Commands:**
```powershell
# Example project creation
mkdir tests\CustomerOrderApi.Integration
cd tests\CustomerOrderApi.Integration
dotnet new xunit --framework net10.0
dotnet add reference ..\..\src\CustomerOrderApi\CustomerOrderApi.csproj
```

**Sample Test:**
- Create a `CustomerOrderApiIntegrationTests.cs` file
- Use `WebApplicationFactory<TEntryPoint>` or equivalent test host
- Include at least one end-to-end request/response validation

**Display:**
```
🧪 Checking integration tests...
  ✓ Found existing integration test project
  ✓ Updated project references for .NET 10.0
  ✓ Created sample integration test case
```

**Why This Matters:**
- Integration tests validate end-to-end behavior, not just unit logic
- They catch issues with service wiring, middleware, and configuration
- They are essential after a project version migration

**Expected Outcome:**
```
✅ Integration tests created or updated successfully
```

---

### ✅ STEP 6: CHECK NUGET PACKAGES & COMPATIBILITY

**Action:** Scan all NuGet packages and check version compatibility

**Analysis:**
```
📦 CustomerOrderApi.csproj:
• Microsoft.EntityFrameworkCore v6.0.21
• Microsoft.EntityFrameworkCore.Sqlite v6.0.21
• Swashbuckle.AspNetCore v6.4.0
• Serilog.AspNetCore v6.1.0

📦 CustomerOrderApi.Tests.csproj:
• Microsoft.NET.Test.Sdk v17.5.0
• xunit v2.4.2
• xunit.runner.visualstudio v2.4.5
• Moq v4.18.4
• FluentAssertions v6.10.0
• coverlet.collector v3.2.0

✅ 12 packages analyzed
```

**Compatibility Check:**
- 🔴 Microsoft.EntityFrameworkCore 6.0.21 → ⚠️ INCOMPATIBLE with .NET 10.0
- 🔴 Microsoft.EntityFrameworkCore.Sqlite 6.0.21 → ⚠️ INCOMPATIBLE with .NET 10.0
- 🟡 Other packages → ✅ Compatible or updatable

**Package Updates Planned:**
```
Microsoft.EntityFrameworkCore: 6.0.21 → 8.0.7
Microsoft.EntityFrameworkCore.Sqlite: 6.0.21 → 8.0.7
Swashbuckle.AspNetCore: 6.4.0 → 6.5.0
Serilog.AspNetCore: 6.1.0 → 8.1.0
... and 8 more
```

**Expected Outcome:**
```
✅ All packages have .NET 10.0 compatible versions
```

---

### ✅ STEP 6: GET USER APPROVAL

**Action:** Display all planned changes and request explicit approval

**Display:**
```
⚠️ This will modify your project files:
  • global.json (SDK version: 6.0.421 → 10.0.0)
  • CustomerOrderApi.csproj (Framework: net6.0 → net10.0)
  • CustomerOrderApi.Tests.csproj (Framework: net6.0 → net10.0)
  • 12 NuGet package versions updated

✅ Backups will be created automatically:
  • global.json.backup
  • CustomerOrderApi.csproj.backup
  • CustomerOrderApi.Tests.csproj.backup
```

**User Decision:**
```
Proceed with migration? (type "yes" or "no"): yes
```

**Validations:**
- ✅ Must type exactly "yes" (case-insensitive)
- ✅ Prevents accidental migrations

**Expected Outcome:**
```
✅ User approved migration
```

> Automation note: The migration agent supports a non-interactive mode. When the script is invoked with `-NonInteractive` or `-Auto`, the agent will assume approval and proceed without asking the user for confirmation. Use this when you want to run the full migration unattended.

---

### ✅ STEP 7: UPDATE global.json

**Action:** Update SDK version in global.json

**File:** `global.json`

**Before:**
```json
{"sdk":{"version":"6.0.421","rollForward":"latestMinor"}}
```

**After:**
```json
{"sdk":{"version":"10.0.0","rollForward":"latestMinor"}}
```

**Process:**
1. ✅ Create backup: `global.json.backup`
2. ✅ Parse JSON
3. ✅ Update `sdk.version` to "10.0.0"
4. ✅ Save file

**Display:**
```
📝 Updating global.json...
  ✓ Backed up to: global.json.backup
  ✓ SDK version: 6.0.421 → 10.0.0
```

**Expected Outcome:**
```
✅ global.json updated
```

---

### ✅ STEP 8: UPDATE .csproj FILES - FRAMEWORK

**Action:** Update TargetFramework in .csproj files

**File 1:** `src/CustomerOrderApi/CustomerOrderApi.csproj`

**Before:**
```xml
<TargetFramework>net6.0</TargetFramework>
```

**After:**
```xml
<TargetFramework>net10.0</TargetFramework>
```

**File 2:** `tests/CustomerOrderApi.Tests/CustomerOrderApi.Tests.csproj`

**Before:**
```xml
<TargetFramework>net6.0</TargetFramework>
```

**After:**
```xml
<TargetFramework>net10.0</TargetFramework>
```

**Process Per File:**
1. ✅ Create backup: `*.csproj.backup`
2. ✅ Parse XML
3. ✅ Update TargetFramework element
4. ✅ Save file

**Display:**
```
📝 Updating CustomerOrderApi.csproj...
  ✓ Backed up to: CustomerOrderApi.csproj.backup
  ✓ TargetFramework: net6.0 → net10.0

📝 Updating CustomerOrderApi.Tests.csproj...
  ✓ Backed up to: CustomerOrderApi.Tests.csproj.backup
  ✓ TargetFramework: net6.0 → net10.0
```

**Expected Outcome:**
```
✅ Both .csproj files updated with net10.0
```

---

### ✅ STEP 9: UPDATE NUGET PACKAGE VERSIONS

**Action:** Update PackageReference versions in .csproj files

**Package Updates Table:**

| Package Name | Old Version | New Version | Reason |
|-------------|-------------|-------------|--------|
| Microsoft.EntityFrameworkCore | 6.0.21 | 8.0.7 | Required for .NET 10.0 |
| Microsoft.EntityFrameworkCore.Sqlite | 6.0.21 | 8.0.7 | Required for .NET 10.0 |
| Swashbuckle.AspNetCore | 6.4.0 | 6.5.0 | .NET 10.0 compatible |
| Serilog.AspNetCore | 6.1.0 | 8.1.0 | .NET 10.0 compatible |
| Microsoft.NET.Test.Sdk | 17.5.0 | 17.9.0 | Latest for .NET 10.0 |
| xunit | 2.4.2 | 2.6.6 | Latest stable |
| xunit.runner.visualstudio | 2.4.5 | 2.5.6 | Latest stable |
| Moq | 4.18.4 | 4.20.70 | Latest stable |
| FluentAssertions | 6.10.0 | 6.12.0 | Latest stable |
| coverlet.collector | 3.2.0 | 6.0.0 | Latest stable |

**Process Per Package:**
1. ✅ Find `<PackageReference Include="PackageName" Version="X.X.X" />`
2. ✅ Update Version attribute
3. ✅ Save file

**Display:**
```
📝 Updating CustomerOrderApi.csproj packages:
  ✓ Microsoft.EntityFrameworkCore: 6.0.21 → 8.0.7
  ✓ Microsoft.EntityFrameworkCore.Sqlite: 6.0.21 → 8.0.7
  ✓ Swashbuckle.AspNetCore: 6.4.0 → 6.5.0
  ✓ Serilog.AspNetCore: 6.1.0 → 8.1.0

📝 Updating CustomerOrderApi.Tests.csproj packages:
  ✓ Microsoft.NET.Test.Sdk: 17.5.0 → 17.9.0
  ✓ xunit: 2.4.2 → 2.6.6
  ✓ xunit.runner.visualstudio: 2.4.5 → 2.5.6
  ✓ Moq: 4.18.4 → 4.20.70
  ✓ FluentAssertions: 6.10.0 → 6.12.0
  ✓ coverlet.collector: 3.2.0 → 6.0.0
```

**Expected Outcome:**
```
✅ All 12 packages updated to .NET 10.0 compatible versions
```

---

### ✅ STEP 10: RESTORE NUGET PACKAGES

**Action:** Download all NuGet packages for new versions

**Command:**
```powershell
dotnet restore
```

**What Happens:**
1. Reads updated .csproj files
2. Contacts NuGet.org for package versions
3. Downloads packages locally
4. Generates project.assets.json

**Display:**
```
📦 Running: dotnet restore

Determining projects to restore...
  Restored g:\CodeGit\CustomerOrderApi\src\CustomerOrderApi\CustomerOrderApi.csproj (590 ms)
  Restored g:\CodeGit\CustomerOrderApi\tests\CustomerOrderApi.Tests\CustomerOrderApi.Tests.csproj (624 ms)

✅ Restore successful
```

**Possible Issues & Resolution:**
| Issue | Cause | Resolution |
|-------|-------|-----------|
| Network timeout | No internet | Check connectivity, retry |
| Package not found | Typo in version | Check package exists on NuGet.org |
| Access denied | File locked | Close VS Code, retry |

**Expected Outcome:**
```
✅ All packages restored for .NET 10.0
```

---

### ✅ STEP 11: BUILD & COMPILE

**Action:** Compile code to verify no breaking changes

**Command:**
```powershell
dotnet build
```

**What Happens:**
1. Reads .csproj and restored packages
2. Compiles C# code
3. Generates output assemblies
4. Checks for compiler errors

**Display:**
```
🔨 Running: dotnet build

Build started...

Microsoft.NET.Sdk.Web 10.0.0 integrated into toolchain.
  Determining projects to restore...
  Restored g:\CodeGit\CustomerOrderApi\src\CustomerOrderApi\CustomerOrderApi.csproj
  Restored g:\CodeGit\CustomerOrderApi\tests\CustomerOrderApi.Tests\CustomerOrderApi.Tests.csproj
  
Building projects...
  Building 'CustomerOrderApi'...
  Building 'CustomerOrderApi.Tests'...

Build succeeded. 0 warnings
Time Elapsed 00:00:12.34

✅ Build successful
```

**Possible Issues & Resolution:**
| Issue | Cause | Resolution |
|-------|-------|-----------|
| CS0246: Type not found | API removed in new version | Update code to use new API |
| CS1061: Member doesn't exist | Package API changed | Check package release notes |
| Cannot find assembly | Package not restored | Run `dotnet restore` again |

**Expected Outcome:**
```
✅ Code compiles successfully with .NET 10.0
```

---

### ✅ STEP 12: RUN UNIT TESTS

**Action:** Execute all unit tests to verify functionality

**Command:**
```powershell
dotnet test
```

**What Happens:**
1. Compiles test projects
2. Discovers test methods
3. Executes each test
4. Reports results

**Display:**
```
🧪 Running: dotnet test

Starting test execution, please wait...
  Discovering: CustomerOrderApi.Tests
  Discovered: CustomerOrderApi.Tests with 5 test(s)

Executing test(s)...

  OrderServiceTests.PlaceAsync_SetsStatusToPending (PASSED) [100ms]
  OrderServiceTests.ConfirmAsync_ValidOrder_ReturnsTrue (PASSED) [45ms]
  OrderServiceTests.CancelAsync_PendingOrder_ReturnsTrue (PASSED) [52ms]
  OrderServiceTests.ConfirmAsync_InvalidOrder_ReturnsFalse (PASSED) [38ms]
  OrderServiceTests.CancelAsync_ConfirmedOrder_ReturnsConflict (PASSED) [41ms]

Test Run Successful.
Total tests: 5
Passed: 5
Failed: 0
Skipped: 0
Time: 0.276 seconds

✅ All tests passed
```

**Comparison with Baseline:**
```
Before Migration:  5/5 passed ✅
After Migration:   5/5 passed ✅
Regression:        None ✅
```

**Possible Issues & Resolution:**
| Issue | Cause | Resolution |
|-------|-------|-----------|
| Tests fail | API breaking change | Update test code or use compatibility shim |
| Tests hang | Async issue | Check async/await patterns |
| Tests timeout | Performance regression | Optimize code or increase timeout |

**Expected Outcome:**
```
✅ All tests pass with .NET 10.0
```

---

### ✅ STEP 13: CODE COVERAGE ANALYSIS

**Action:** Analyze test coverage to ensure quality maintained

**Command:**
```powershell
dotnet test /p:CollectCoverageMetrics=true
```

**Display:**
```
📊 Running: Code Coverage Analysis

Collecting coverage data...

Coverage Summary:
  Line coverage: 92.5%
  Branch coverage: 87.3%
  Method coverage: 100%

Coverage by project:
  CustomerOrderApi: 89.2%
  CustomerOrderApi.Tests: 100%

✅ Code coverage maintained
```

**Acceptance Criteria:**
- ✅ Line coverage > 80%
- ✅ No regression from baseline
- ✅ All critical paths covered

**Expected Outcome:**
```
✅ Code coverage acceptable (92.5% > 80% threshold)
```

---

### ✅ STEP 14: GENERATE MIGRATION REPORT

**Action:** Create comprehensive report of all changes

**Report Location:** `.github/migration-reports/migration-report-yyyyMMdd-HHmmss.md`

**Report Contents:**

```markdown
# .NET Migration Report

**Date:** 2026-07-26 14:35:22
**Target Version:** .NET 10.0
**Status:** ✅ SUCCESSFUL

## Summary
Successfully migrated CustomerOrderApi project from .NET 6.0 to .NET 10.0.

## Changes Applied
### Configuration Files
- global.json: SDK version 6.0.421 → 10.0.0
- CustomerOrderApi.csproj: Framework net6.0 → net10.0
- CustomerOrderApi.Tests.csproj: Framework net6.0 → net10.0

### NuGet Package Updates (12 total)
[See step 9 table above]

## Validation Results
- Restore: ✅ Passed
- Build: ✅ Passed (0 warnings)
- Tests: ✅ Passed (5/5)
- Code Coverage: ✅ 92.5% (maintained)

## Logs
- Main Log: .github/logs/migration-yyyyMMdd-HHmmss.log
- Error Log: .github/logs/migration-errors-yyyyMMdd-HHmmss.log

## Next Steps
1. git add .
2. git commit -m "chore: Migrate to .NET 10.0"
3. git push origin chore/net6-to-net10-migration
4. Create Pull Request

## Rollback Instructions
If issues arise:
```bash
cp global.json.backup global.json
cp src/CustomerOrderApi/CustomerOrderApi.csproj.backup src/CustomerOrderApi/CustomerOrderApi.csproj
cp tests/CustomerOrderApi.Tests/CustomerOrderApi.Tests.csproj.backup tests/CustomerOrderApi.Tests/CustomerOrderApi.Tests.csproj
git checkout -- .
```
```

**Display:**
```
📄 Report saved to: .github/migration-reports/migration-report-20260726-143522.md
```

**Expected Outcome:**
```
✅ Migration report generated successfully
```

---

## ✅ Verification Checklist

Use this checklist to verify migration success:

```
BEFORE MIGRATION:
☐ Current version: .NET 6.0
☐ All tests passing: 5/5
☐ Build succeeding: 0 errors, 0 warnings
☐ Code coverage: 92%+

DURING MIGRATION:
☐ Step 1: Version selected
☐ Step 2: SDK validated
☐ Step 3: Projects discovered (2 found)
☐ Step 4: Baseline captured
☐ Step 5: Packages analyzed (12 found)
☐ Step 6: User approved
☐ Step 7: global.json updated
☐ Step 8: .csproj files updated (2 files)
☐ Step 9: Packages updated (12 packages)
☐ Step 10: dotnet restore succeeded
☐ Step 11: dotnet build succeeded
☐ Step 12: dotnet test succeeded (5/5)
☐ Step 13: Code coverage maintained (92%+)
☐ Step 14: Report generated

AFTER MIGRATION:
☐ New version: .NET 10.0
☐ All tests passing: 5/5 ✅
☐ Build succeeding: 0 errors, 0 warnings ✅
☐ Code coverage: 92%+ ✅
☐ No breaking changes detected ✅
☐ All backups created ✅
☐ Report generated ✅
```

---

## 🚨 Error Handling & Recovery

### What Happens If Something Fails?

**At ANY step, if error occurs:**

1. **Error Detected** → Logged to `.github/logs/migration-errors-*.log`
2. **Automatic Rollback Initiated** → All changes reverted
3. **Backups Restored** → Files returned to original state
4. **Report Generated** → Error details documented
5. **User Notified** → Clear error message displayed

### Error Recovery Example

**Scenario:** dotnet build fails at Step 11

```
🔨 Running: dotnet build
...
error CS1061: 'OrderService' does not contain a definition for 'OldMethod'

❌ BUILD FAILED

🔄 ERROR RECOVERY ACTIVATED

Rolling back changes:
  ✓ Restored global.json from global.json.backup
  ✓ Restored CustomerOrderApi.csproj from backup
  ✓ Restored CustomerOrderApi.Tests.csproj from backup

Files returned to .NET 6.0 state.

📄 Error Report: .github/logs/migration-errors-20260726-143522.log

🎯 NEXT STEPS:
1. Review error message above
2. Update code to use new API
3. Run migration agent again
```

### Manual Recovery Steps

If automatic recovery doesn't work:

```powershell
# Step 1: Restore from backups
cp global.json.backup global.json
cp src/CustomerOrderApi/CustomerOrderApi.csproj.backup src/CustomerOrderApi/CustomerOrderApi.csproj
cp tests/CustomerOrderApi.Tests/CustomerOrderApi.Tests.csproj.backup tests/CustomerOrderApi.Tests/CustomerOrderApi.Tests.csproj

# Step 2: Clean build artifacts
dotnet clean

# Step 3: Verify restoration
dotnet build
dotnet test

# Step 4: Start migration again
.\.github\scripts\net-migration-agent.ps1
```

---

## 📚 Commands Reference

### Pre-Migration

| Command | Purpose |
|---------|---------|
| `dotnet --version` | Check current .NET version |
| `dotnet --list-sdks` | List installed SDKs |
| `git status` | Check uncommitted changes |
| `git branch` | List local branches |

### Migration Execution

| Command | Purpose |
|---------|---------|
| `.\.github\scripts\net-migration-agent.ps1` | Start migration (PowerShell) |
| `migrate.cmd` | Start migration (Command Prompt) |
| `dotnet restore` | Download NuGet packages |
| `dotnet build` | Compile code |
| `dotnet test` | Run unit tests |

### Post-Migration

| Command | Purpose |
|---------|---------|
| `git add .` | Stage all changes |
| `git commit -m "chore: Migrate to .NET 10.0"` | Commit changes |
| `git push origin chore/net6-to-net10-migration` | Push to remote |
| `git diff master` | View all changes |

### Verification

| Command | Purpose |
|---------|---------|
| `cat .github/logs/migration-*.log` | View migration log |
| `cat .github/logs/migration-errors-*.log` | View errors only |
| `cat .github/migration-reports/migration-report-*.md` | View report |

---

## 🔧 Troubleshooting

### Problem: SDK Not Found

**Error:**
```
⚠️ .NET 10.0 SDK is NOT installed
```

**Solution:**
```powershell
# Install the SDK
winget install Microsoft.DotNet.SDK.10.0

# Verify installation
dotnet --list-sdks
```

### Problem: NuGet Package Not Found

**Error:**
```
error NU1101: Unable to find package Microsoft.EntityFrameworkCore version 8.0.7
```

**Solution:**
```powershell
# Clear NuGet cache
dotnet nuget locals all --clear

# Restore again
dotnet restore
```

### Problem: Build Fails with CS1061

**Error:**
```
error CS1061: 'OrderService' does not contain a definition for 'PlaceOrderAsync'
```

**Solution:**
1. Check package release notes for API changes
2. Update code to use new API
3. Or, use compatibility shim if available

**Example Fix:**
```csharp
// Old API (EF Core 6.0)
var order = await _service.PlaceOrderAsync(dto);

// New API (EF Core 8.0)
var order = await _service.PlaceAsync(dto);
```

### Problem: Tests Fail After Migration

**Error:**
```
Test failed: Test method threw exception: System.NotImplementedException
```

**Solution:**
1. Run tests individually: `dotnet test --filter "TestName"`
2. Review test output for specific error
3. Update test code to work with new APIs
4. Re-run migration

### Problem: File Locked Error

**Error:**
```
System.IO.IOException: The file is locked
```

**Solution:**
```powershell
# Close all VS Code instances
# Or restart Visual Studio

# Then retry migration
.\.github\scripts\net-migration-agent.ps1
```

---

## 📊 Summary

| Item | Count | Status |
|------|-------|--------|
| Projects | 2 | ✅ Migrated |
| Steps | 14 | ✅ Automated |
| Tests | 5 | ✅ Passing |
| Packages | 12 | ✅ Updated |
| Backups | 5 | ✅ Created |

---

## 🎯 Next Steps After Migration

1. **Review Changes**
   ```bash
   git diff master
   ```

2. **Create Branch**
   ```bash
   git checkout -b chore/net6-to-net10-migration
   ```

3. **Commit**
   ```bash
   git add .
   git commit -m "chore: Migrate from .NET 6.0 to .NET 10.0"
   ```

4. **Push**
   ```bash
   git push origin chore/net6-to-net10-migration
   ```

5. **Create PR on GitHub**
   - Title: "chore: Migrate to .NET 10.0"
   - Description: Reference this guide
   - Wait for CI/CD to validate

6. **Merge After Approval**
   - Get code review approval
   - Ensure CI passes
   - Merge to master

---

**Status:** ✅ Complete End-to-End Guide  
**Validation:** All 14 steps documented with expected outcomes  
**Recovery:** Automatic rollback mechanism included  
**Reporting:** Comprehensive reporting at each step