param(
    [string]$RepoRoot = ".",
    [string]$BranchName,
    [string]$Title = "chore: Automated migration changes",
    [string]$Body = "This pull request was created by the migration agent automation.",
    [switch]$Force,
    [switch]$Auto,
    [switch]$CreateIntegration,
    [switch]$NonInteractive,
    [switch]$SimpleConfirm,
    [string]$TargetFramework = "net10.0",
    [string]$SdkVersion = "10.0.0"
)

function ExitWithError($msg) {
    Write-Error $msg
    exit 1
}

try {
    $RepoRoot = (Resolve-Path $RepoRoot).ProviderPath
} catch {
    ExitWithError "Repo root path '$RepoRoot' not found."
}

Push-Location $RepoRoot

function Update-GlobalJson($sdkVersion) {
    $globalJsonPath = Join-Path $RepoRoot "global.json"
    if (Test-Path $globalJsonPath) {
        Write-Output "Updating global.json to SDK $sdkVersion"
        Copy-Item $globalJsonPath "$globalJsonPath.backup" -Force
        try {
            $json = Get-Content $globalJsonPath | Out-String | ConvertFrom-Json
            if ($null -eq $json.sdk) { $json | Add-Member -MemberType NoteProperty -Name sdk -Value @{version=$sdkVersion} -Force }
            else { $json.sdk.version = $sdkVersion }
            $json | ConvertTo-Json -Depth 10 | Set-Content $globalJsonPath -Encoding utf8
            Write-Output "global.json updated (backup saved as global.json.backup)"
        } catch {
            Write-Output "Failed to update global.json: $_"
        }
    } else {
        Write-Output "No global.json found; creating one with SDK $sdkVersion"
        $obj = @{ sdk = @{ version = $sdkVersion; rollForward = "latestMinor" } }
        $obj | ConvertTo-Json -Depth 10 | Set-Content $globalJsonPath -Encoding utf8
        Write-Output "global.json created"
    }
}

function Update-CsprojTargetFrameworks($targetFramework) {
    Write-Output "Updating .csproj TargetFramework(s) to $targetFramework"
    $csprojFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter "*.csproj" | Where-Object { $_.FullName -notmatch "\\bin\\|\\obj\\" }
    foreach ($file in $csprojFiles) {
        $path = $file.FullName
        Write-Output "Processing $path"
        Copy-Item $path "$path.backup" -Force
        $content = Get-Content $path -Raw
        $new = $content -replace '<TargetFrameworks>(.*?)</TargetFrameworks>', { param($m) "<TargetFrameworks>$((($m.Groups[1].Value -split ';') -replace 'net\d+\.\d+', $targetFramework -join ';'))</TargetFrameworks>" }
        $new = $new -replace '<TargetFramework>.*?</TargetFramework>', "<TargetFramework>$targetFramework</TargetFramework>"
        Set-Content -Path $path -Value $new -Encoding utf8
    }
}

function Update-NuGetPackages() {
    Write-Output "Checking for outdated NuGet packages..."
    $csprojFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter "*.csproj" | Where-Object { $_.FullName -notmatch "\\bin\\|\\obj\\" }
    foreach ($proj in $csprojFiles) {
        Write-Output "Inspecting packages for $($proj.FullName)"
        try {
            $out = dotnet list `"$($proj.FullName)`" package --outdated 2>&1
        } catch {
            Write-Output ("Failed to list packages for {0}: {1}" -f $proj.FullName, $_)
            continue
        }
        foreach ($line in $out) {
            if ($line -match '^\s*>\s*(\S+)\s+\S+\s+\S+\s+(\S+)$') {
                $pkg = $matches[1]
                $latest = $matches[2]
                Write-Output "Updating $pkg to $latest in $($proj.FullName)"
                try {
                    dotnet add `"$($proj.FullName)`" package $pkg -v $latest
                } catch {
                    Write-Output ("Failed to update {0}: {1}" -f $pkg, $_)
                }
            }
        }
    }
}

function Apply-CodeFixes() {
    Write-Output "Attempting to run 'dotnet format' for code fixes (if available)..."
    try {
        dotnet format
    } catch {
        Write-Output "dotnet format failed or not available: $($_)"
    }
}

Write-Output "Migration agent automation: creating branch/PR if needed..."

# Check for git
try { git --version > $null } catch { ExitWithError "git not found in PATH." }

# Resolve origin remote
$remote = git remote get-url origin 2>$null
if (-not $remote) { ExitWithError "No 'origin' remote found. Add a remote and retry." }

# Determine branch name if not provided
if (-not $BranchName) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $BranchName = "chore/migration-$timestamp"
}

# If branch already exists locally, checkout it, otherwise create new
$exists = & git rev-parse --verify --quiet "refs/heads/$BranchName"
if ($LASTEXITCODE -eq 0) {
    Write-Output "Branch '$BranchName' already exists locally — checking it out."
    git checkout $BranchName
} else {
    git checkout -b $BranchName
}

# Optionally create or update integration tests
if ($CreateIntegration) {
    $createScript = Join-Path $PSScriptRoot "create-integration-test.ps1"
    if (Test-Path $createScript) {
        if ($Auto -or $SimpleConfirm) {
            Write-Output "Running integration test scaffolding (Auto/SimpleConfirm mode)..."
            & $createScript -ProjectRoot $RepoRoot -Auto -IntegrationProjectName "$(Split-Path $RepoRoot -Leaf).Integration" -TargetFramework $TargetFramework
        } else {
            Write-Output "DRY RUN: Integration creation requested but neither -Auto nor -SimpleConfirm provided."
            Write-Output "Suggested command:"
            Write-Output "  powershell -ExecutionPolicy Bypass -File .github/scripts/create-integration-test.ps1 -ProjectRoot $RepoRoot -IntegrationProjectName '<Name>' -TargetFramework $TargetFramework -Auto"
        }
    } else {
        Write-Output "Integration creation script not found at: $createScript"
    }
}

# If NonInteractive requested, treat as Auto and suppress interactive prompts
if ($NonInteractive) { $Auto = $true }

# If SimpleConfirm provided in interactive mode, prompt once and proceed if user says yes
if (-not $Auto -and $SimpleConfirm) {
    $resp = Read-Host "Proceed with migration steps (update files, scaffold integration tests, build and test)? (yes/no)"
    if ($resp.ToLower() -ne 'yes') {
        Write-Output "User declined. Exiting without changes."
        exit 0
    }
}

# If Auto, run restore/build/test automatically (non-interactive)
if ($Auto -or $SimpleConfirm) {
    Write-Output "Auto mode enabled: performing migration steps non-interactively..."
    # Update global.json and csproj target frameworks
    Update-GlobalJson $SdkVersion
    Update-CsprojTargetFrameworks $TargetFramework

    # Update NuGet packages
    Update-NuGetPackages

    # Apply code fixes (dotnet format)
    Apply-CodeFixes

    # Now restore, build, test
    try {
        Write-Output "Running: dotnet restore"
        dotnet restore
    } catch {
        Write-Output "dotnet restore failed: $_"
    }

    try {
        Write-Output "Running: dotnet build --no-restore"
        dotnet build --no-restore
    } catch {
        Write-Output "dotnet build failed: $_"
    }

    try {
        Write-Output "Running: dotnet test --no-build"
        dotnet test --no-build
    } catch {
        Write-Output "dotnet test failed: $_"
    }
} else {
    Write-Output "Note: Auto mode not enabled. Build/test and update steps were skipped."
}

# Stage and commit any changes (only execute if -Auto is provided)
$status = git status --porcelain
if ($Auto) {
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        git add -A
        try {
            git commit -m $Title
        } catch {
            Write-Output "Nothing to commit or commit failed: $_"
        }
        git push -u origin $BranchName
    } else {
        Write-Output "No changes detected to commit. Ensuring branch is pushed."
        # push branch if missing remotely
        git ls-remote --exit-code --heads origin $BranchName 2>$null
        if ($LASTEXITCODE -ne 0) { git push -u origin $BranchName }
    }
} else {
    Write-Output "DRY RUN: -Auto not provided, no git/remote commands will be executed."
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        Write-Output "Suggested commands to run manually:"
        Write-Output "  git add -A"
        Write-Output "  git commit -m '$Title'"
        Write-Output "  git push -u origin $BranchName"
    } else {
        Write-Output "Suggested commands to run manually (push branch if needed):"
        Write-Output "  git push -u origin $BranchName"
    }
}

# Try to create PR using GitHub CLI if available
$hasGh = $false
try { gh --version > $null; $hasGh = $true } catch {}

if ($Auto) {
    if ($hasGh) {
        Write-Output "Creating PR using GitHub CLI..."
        gh pr create --title "$Title" --body "$Body"
        if ($LASTEXITCODE -ne 0) { Write-Output "gh pr create failed (exit $LASTEXITCODE)." }
    } else {
        Write-Output "GitHub CLI (gh) not found — printing PR compare URL to open in browser."
        # Determine default branch (best-effort)
        $defaultBranch = "main"
        try {
            $info = git remote show origin 2>$null
            if ($info -match "HEAD branch: (\S+)") { $defaultBranch = $matches[1] }
        } catch {}

        # Normalize remote to owner/repo
        $repo = $remote -replace '^.*[:/]', ''
        $repo = $repo -replace '\\.git$',''
        $compareUrl = "https://github.com/$repo/compare/$defaultBranch...$BranchName?expand=1"
        Write-Output $compareUrl
    }
} else {
    Write-Output "DRY RUN: -Auto not provided, PR creation skipped."
    if ($hasGh) {
        Write-Output "Suggested command to create PR with gh:"
        Write-Output "  gh pr create --title \"$Title\" --body \"$Body\""
    } else {
        # Determine default branch (best-effort)
        $defaultBranch = "main"
        try {
            $info = git remote show origin 2>$null
            if ($info -match "HEAD branch: (\S+)") { $defaultBranch = $matches[1] }
        } catch {}
        $repo = $remote -replace '^.*[:/]', '' -replace '\.git$',''
        $compareUrl = "https://github.com/$repo/compare/$defaultBranch...$BranchName?expand=1"
        Write-Output "Suggested PR URL: $compareUrl"
    }
}

Write-Output "Done. Branch: $BranchName"
