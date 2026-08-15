param(
    [string]$ProjectRoot = ".",
    [string]$IntegrationProjectName,
    [string]$TargetFramework = "net10.0",
    [switch]$Auto
)

# Make PowerShell-level errors (bad XML, missing files, etc.) terminate immediately
# instead of continuing silently past them.
$ErrorActionPreference = "Stop"

function ExitWithError($msg) {
    Write-Error $msg
    exit 1
}

# dotnet.exe does NOT throw a PowerShell exception on failure -- it just sets
# $LASTEXITCODE and returns. Without this wrapper, a failed restore, a bad
# reference, or a network hiccup during `dotnet add package` gets silently
# skipped and the script (and any agent driving it) reports success anyway.
function Invoke-DotNet {
    param(
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$Description
    )
    Write-Output "Running: dotnet $($ArgumentList -join ' ')"
    & dotnet @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "FAILED [$Description]: 'dotnet $($ArgumentList -join ' ')' exited with code $LASTEXITCODE. See dotnet output above for details."
    }
}

# Everything below runs inside try/catch so ANY failure -- a thrown PowerShell
# error, a failed dotnet command, bad project XML, etc. -- is caught, reported
# with a clear FAILED message, and exits non-zero. Nothing fails silently.
try {

$ProjectRoot = (Resolve-Path $ProjectRoot).ProviderPath
Write-Output "Integration test creator: checking workspace under '$ProjectRoot'..."

# --- Discover the application project ---
# Prefer src/, but don't assume a single csproj lives there.
$srcPath = Join-Path $ProjectRoot "src"
$candidates = @()
if (Test-Path $srcPath) {
    $candidates = Get-ChildItem -Path $srcPath -Recurse -Filter "*.csproj" -ErrorAction SilentlyContinue
}
if (-not $candidates -or $candidates.Count -eq 0) {
    $candidates = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.csproj" |
        Where-Object { $_.FullName -notmatch "\\tests\\|\\bin\\|\\obj\\" }
}
if (-not $candidates -or $candidates.Count -eq 0) {
    ExitWithError "Cannot find an application project to reference. Ensure a project exists under 'src/'."
}
if ($candidates.Count -gt 1) {
    Write-Output "Multiple candidate projects found under src/; using the first: $($candidates[0].FullName)"
    Write-Output "If this is wrong, re-run with an explicit -IntegrationProjectName and adjust manually."
}
$appProj = $candidates[0]
$appProjName = [System.IO.Path]::GetFileNameWithoutExtension($appProj.Name)

# --- Determine project type: Web host vs. plain library ---
try {
    [xml]$appProjXml = Get-Content $appProj.FullName
} catch {
    throw "FAILED: could not parse '$($appProj.FullName)' as XML -- is it a valid .csproj? Underlying error: $($_.Exception.Message)"
}
$sdkAttr = $appProjXml.Project.Sdk
$isWebHost = $sdkAttr -match "Microsoft\.NET\.Sdk\.Web"
Write-Output "Detected app project: $appProjName (Sdk=$sdkAttr, WebHost=$isWebHost)"

# --- Derive integration project name if not supplied ---
if (-not $IntegrationProjectName) {
    $IntegrationProjectName = "$appProjName.Integration"
}

$testsFolder = Join-Path $ProjectRoot "tests"
$integrationFolder = Join-Path $testsFolder $IntegrationProjectName
$integrationProjPath = Join-Path $integrationFolder "$IntegrationProjectName.csproj"

# --- Locate a solution file so the project actually loads in Visual Studio / VS Code ---
# dotnet new/add only touch disk + the referenced .csproj; the .sln (what VS/VS Code use
# to discover projects and populate Test Explorer) is never updated unless we do it here.
$slnCandidates = Get-ChildItem -Path $ProjectRoot -Filter "*.sln" -File -ErrorAction SilentlyContinue
if (-not $slnCandidates -or $slnCandidates.Count -eq 0) {
    $slnCandidates = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.sln" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\bin\\|\\obj\\" }
}
$slnPath = $null
if ($slnCandidates -and $slnCandidates.Count -gt 0) {
    $slnPath = $slnCandidates[0].FullName
    if ($slnCandidates.Count -gt 1) {
        Write-Output "Multiple .sln files found under '$ProjectRoot'; using the first: $slnPath"
        Write-Output "If this is wrong, re-run from the folder containing the intended solution."
    }
    Write-Output "Solution file: $slnPath"
} else {
    Write-Output "WARNING: no .sln found under '$ProjectRoot'. The integration test project will be created on disk but NOT added to any solution."
    Write-Output "Visual Studio / VS Code will not load it or show its tests until you either add a .sln at the repo root or run:"
    Write-Output "  dotnet sln <YourSolution.sln> add `"$integrationProjPath`""
}

function Add-ProjectToSolution {
    param([string]$CsprojPath)
    if ($slnPath) {
        Write-Output "Registering '$CsprojPath' with solution '$slnPath' (safe to re-run; no-op if already added)..."
        Invoke-DotNet -ArgumentList @("sln", $slnPath, "add", $CsprojPath) -Description "add project to solution"
    }
}

if (Test-Path $integrationProjPath) {
    Write-Output "Found existing integration project: $integrationProjPath"
    Write-Output "Updating TargetFramework and packages if missing..."
    if ($Auto) {
        if ($isWebHost) {
            # No version pinned -> dotnet add package resolves the latest stable release,
            # so this also covers "package needs updating for the new TargetFramework".
            Invoke-DotNet -ArgumentList @("add", $integrationProjPath, "package", "Microsoft.AspNetCore.Mvc.Testing") -Description "update Microsoft.AspNetCore.Mvc.Testing"
        }
        Invoke-DotNet -ArgumentList @("add", $integrationProjPath, "package", "Microsoft.NET.Test.Sdk") -Description "update Microsoft.NET.Test.Sdk"
        Invoke-DotNet -ArgumentList @("add", $integrationProjPath, "package", "xunit") -Description "update xunit"
        Invoke-DotNet -ArgumentList @("add", $integrationProjPath, "package", "xunit.runner.visualstudio") -Description "update xunit.runner.visualstudio"
        (Get-Content $integrationProjPath) -replace '<TargetFramework>.*<', "<TargetFramework>$TargetFramework<" |
            Set-Content $integrationProjPath
        Add-ProjectToSolution -CsprojPath $integrationProjPath
    } else {
        Write-Output "Suggested commands:"
        if ($isWebHost) {
            Write-Output "  dotnet add `"$integrationProjPath`" package Microsoft.AspNetCore.Mvc.Testing"
        }
        Write-Output "  dotnet add `"$integrationProjPath`" package Microsoft.NET.Test.Sdk"
        Write-Output "  dotnet add `"$integrationProjPath`" package xunit"
        Write-Output "  dotnet add `"$integrationProjPath`" package xunit.runner.visualstudio"
        Write-Output "  (manually update TargetFramework to $TargetFramework in $integrationProjPath)"
        if ($slnPath) {
            Write-Output "  dotnet sln `"$slnPath`" add `"$integrationProjPath`""
        }
    }
    Write-Output "Integration test creator finished."
    exit 0
}

Write-Output "No integration project found. Scaffolding new integration test project at: $integrationFolder"

if (-not $Auto) {
    Write-Output "DRY RUN (pass -Auto to actually create files). Suggested commands:"
    Write-Output "  mkdir `"$integrationFolder`""
    Write-Output "  dotnet new xunit -n $IntegrationProjectName -o `"$integrationFolder`" --framework $TargetFramework"
    Write-Output "  dotnet add `"$integrationProjPath`" reference `"$($appProj.FullName)`""
    if ($isWebHost) {
        Write-Output "  dotnet add `"$integrationProjPath`" package Microsoft.AspNetCore.Mvc.Testing"
    }
    if ($slnPath) {
        Write-Output "  dotnet sln `"$slnPath`" add `"$integrationProjPath`""
    } else {
        Write-Output "  (no .sln found under '$ProjectRoot' -- point -ProjectRoot at the folder containing your solution, or add the project to it manually)"
    }
    Write-Output "Integration test creator finished."
    exit 0
}

New-Item -ItemType Directory -Path $integrationFolder -Force | Out-Null
Invoke-DotNet -ArgumentList @("new", "xunit", "-n", $IntegrationProjectName, "-o", $integrationFolder, "--framework", $TargetFramework) -Description "scaffold xunit project"
Invoke-DotNet -ArgumentList @("add", $integrationProjPath, "reference", $appProj.FullName) -Description "add project reference"
Add-ProjectToSolution -CsprojPath $integrationProjPath

if ($isWebHost) {
    # --- Web host template: spin up in-memory server, hit an endpoint ---
    Invoke-DotNet -ArgumentList @("add", $integrationProjPath, "package", "Microsoft.AspNetCore.Mvc.Testing") -Description "add Microsoft.AspNetCore.Mvc.Testing"

    $sample = @"
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace $IntegrationProjectName
{
    public class ${appProjName}IntegrationTests : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly WebApplicationFactory<Program> _factory;

        public ${appProjName}IntegrationTests(WebApplicationFactory<Program> factory)
        {
            _factory = factory;
        }

        [Fact]
        public async Task Get_Home_ReturnsSuccess()
        {
            var client = _factory.CreateClient();
            var response = await client.GetAsync("/");
            response.EnsureSuccessStatusCode();
        }
    }
}
"@
} else {
    # --- Library template: call the library directly, no web host involved ---
    $sample = @"
using Xunit;

namespace $IntegrationProjectName
{
    // Integration-style tests for ${appProjName}: exercise the library's
    // public surface directly (no web host -- this is a class library).
    // Replace this sample with real calls into $appProjName as needed.
    public class ${appProjName}IntegrationTests
    {
        [Fact]
        public void Placeholder_ReplaceWithRealIntegrationScenario()
        {
            // TODO: call into $appProjName here, e.g.:
            // var result = SomeType.SomeMethod(...);
            // Assert.True(result.IsValid);
            Assert.True(true);
        }
    }
}
"@
}

$samplePath = Join-Path $integrationFolder "${appProjName}IntegrationTests.cs"
$sample | Out-File -FilePath $samplePath -Encoding utf8

Write-Output "Integration test creator finished."

} catch {
    # Single, unmissable failure point. $_.Exception.Message covers both
    # PowerShell-level errors and the throw'n messages from Invoke-DotNet above.
    Write-Error "Integration test creator FAILED: $($_.Exception.Message)"
    if ($_.ScriptStackTrace) {
        Write-Output "--- Stack trace (for debugging) ---"
        Write-Output $_.ScriptStackTrace
    }
    exit 1
}
