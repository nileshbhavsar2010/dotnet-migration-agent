param(
    [string]$ProjectRoot = ".",
    [string]$IntegrationProjectName = "CustomerOrderApi.Integration",
    [string]$TargetFramework = "net10.0",
    [switch]$Auto
)

function ExitWithError($msg) {
    Write-Error $msg
    exit 1
}

Write-Output "Integration test creator: checking workspace under '$ProjectRoot'..."

# Find candidate application project under src/
$appProj = Get-ChildItem -Path (Join-Path $ProjectRoot "src") -Recurse -Filter "*.csproj" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $appProj) {
    # fallback: find first non-test csproj
    $appProj = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.csproj" | Where-Object { $_.FullName -notmatch "\\tests\\" } | Select-Object -First 1
}

if (-not $appProj) { ExitWithError "Cannot find application project to reference. Ensure a project exists under 'src/'." }

$testsFolder = Join-Path $ProjectRoot "tests"
$integrationFolder = Join-Path $testsFolder $IntegrationProjectName
$integrationProjPath = Join-Path $integrationFolder "$IntegrationProjectName.csproj"

if (Test-Path $integrationProjPath) {
    Write-Output "Found existing integration project: $integrationProjPath"
    Write-Output "Updating TargetFramework and adding required packages if missing..."
    if ($Auto) {
        dotnet add $integrationProjPath package Microsoft.AspNetCore.Mvc.Testing
        # ensure target framework updated
        (Get-Content $integrationProjPath) -replace '<TargetFramework>.*<', "<TargetFramework>$TargetFramework<" | Set-Content $integrationProjPath
    } else {
        Write-Output "Suggested commands:"
        Write-Output "  dotnet add \"$integrationProjPath\" package Microsoft.AspNetCore.Mvc.Testing"
        Write-Output "  (manually update TargetFramework to $TargetFramework in $integrationProjPath)"
    }
} else {
    Write-Output "No integration project found. Scaffolding new integration test project at: $integrationFolder"
    if ($Auto) {
        New-Item -ItemType Directory -Path $integrationFolder -Force | Out-Null
        dotnet new xunit -n $IntegrationProjectName -o $integrationFolder --framework $TargetFramework
        # add reference to application project
        dotnet add $integrationProjPath reference $appProj.FullName
        dotnet add $integrationProjPath package Microsoft.AspNetCore.Mvc.Testing

        # create sample test file
        $sample = @"
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace $IntegrationProjectName
{
    public class CustomerOrderApiIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly WebApplicationFactory<Program> _factory;

        public CustomerOrderApiIntegrationTests(WebApplicationFactory<Program> factory)
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
        $samplePath = Join-Path $integrationFolder "CustomerOrderApiIntegrationTests.cs"
        $sample | Out-File -FilePath $samplePath -Encoding utf8
    } else {
        Write-Output "Suggested commands to scaffold integration test project:"
        Write-Output "  mkdir \"$integrationFolder\""
        Write-Output "  dotnet new xunit -n $IntegrationProjectName -o \"$integrationFolder\" --framework $TargetFramework"
        Write-Output "  dotnet add \"$integrationProjPath\" reference \"$($appProj.FullName)\""
        Write-Output "  dotnet add \"$integrationProjPath\" package Microsoft.AspNetCore.Mvc.Testing"
        Write-Output "  (create a sample test file similar to CustomerOrderApiIntegrationTests.cs)"
    }
}

Write-Output "Integration test creator finished."
