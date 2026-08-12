param(
    [string]$ProjectRoot = ".",
    [string]$IntegrationProjectName,
    [string]$TargetFramework = "net10.0",
    [switch]$Auto
)

function ExitWithError($msg) {
    Write-Error $msg
    exit 1
}

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
[xml]$appProjXml = Get-Content $appProj.FullName
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

if (Test-Path $integrationProjPath) {
    Write-Output "Found existing integration project: $integrationProjPath"
    Write-Output "Updating TargetFramework and packages if missing..."
    if ($Auto) {
        if ($isWebHost) {
            dotnet add $integrationProjPath package Microsoft.AspNetCore.Mvc.Testing
        }
        (Get-Content $integrationProjPath) -replace '<TargetFramework>.*<', "<TargetFramework>$TargetFramework<" |
            Set-Content $integrationProjPath
    } else {
        Write-Output "Suggested commands:"
        if ($isWebHost) {
            Write-Output "  dotnet add `"$integrationProjPath`" package Microsoft.AspNetCore.Mvc.Testing"
        }
        Write-Output "  (manually update TargetFramework to $TargetFramework in $integrationProjPath)"
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
    Write-Output "Integration test creator finished."
    exit 0
}

New-Item -ItemType Directory -Path $integrationFolder -Force | Out-Null
dotnet new xunit -n $IntegrationProjectName -o $integrationFolder --framework $TargetFramework
dotnet add $integrationProjPath reference $appProj.FullName

if ($isWebHost) {
    # --- Web host template: spin up in-memory server, hit an endpoint ---
    dotnet add $integrationProjPath package Microsoft.AspNetCore.Mvc.Testing

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