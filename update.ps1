# Check winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "Winget is not found"
    pause
    exit 1
}

# Set path
$folder = "format"
$basePath = Join-Path $PSScriptRoot ${folder}
$jsonPath = Join-Path $PSScriptRoot "ventoy\${folder}.json"

# Check JSON
if (-not (Test-Path $jsonPath)) {
    Write-Host -ForegroundColor Red "${jsonPath} not found"
    pause
    exit 1
}

# Get data
$data = Get-Content $jsonPath -Raw | ConvertFrom-Json

# Check data
if ($null -eq $data -or $data.Count -eq 0) {
    Write-Host -ForegroundColor Red "No packages found in JSON"
    pause
    exit 1
}

# Loop data
foreach ($app in $data) {
    $id = $app.id
    $version = $app.version
    $name = $app.name
    $locale = $app.locale
    $file = $app.file
    Write-Host "Checking $name"

    if (-not $id) {
        Write-Host -ForegroundColor Red "Id not found for $name"
        continue
    }

    try {
        # Get latest version from GitHub
        $downloadUrl = (Invoke-RestMethod $id).assets.browser_download_url | Where-Object { $_.EndsWith($app.source) }
    }
    catch {
        # If the link is not found, catch the error (silently)
        $downloadUrl = $null
    }

    # Check GitHub link
    if ($downloadUrl) {
        # Check file extension
        if ($app.source) {
            $latestVersion = (Invoke-RestMethod $id).tag_name
        }
        else {
            Write-Host -ForegroundColor Red "Source: EndsWith Error (e.g. .exe)"
        }
    }
    else {
        # Check language option (e.g., WinRAR is listed with language option)
        if ($locale) {
            $info = winget show --id $id --exact --accept-source-agreements --locale $locale
        }
        else {
            $info = winget show --id $id --exact --accept-source-agreements
        }

        try {
            $latestVersion = (($info | Where-Object { $_ -match "^Version:" } | Select-Object -First 1) -replace "^Version:\s*", "").Trim()
            $downloadUrl = (($info | Where-Object { $_ -match "Installer Url:" }) -replace "Installer Url:\s*", "").Trim()
        }
        catch {
            if ($locale) {
                Write-Host -ForegroundColor Yellow "Update found, but locale ($locale) not found for $name"
            }
            else {
                Write-Host -ForegroundColor Red "Update failed for $name"
            }
            continue
        }
    }

    # Check if latest version is found
    if (-not $latestVersion) {
        Write-Host -ForegroundColor Red "Version not found for $name"
        continue
    }

    # Check package version
    if ($latestVersion -ne $version) {
        if (-not $downloadUrl) {
            Write-Host -ForegroundColor Red "URL not found for ${name}"
            continue
        }

        # Find file extension
        if ($downloadUrl -match "\.(exe|msix|msi|zip|7z|nupkg)") {
            $extension = $matches[0]
        }

        # Set file path
        $destination = Join-Path $basePath "${file}${extension}"

        # Download package
        Start-BitsTransfer -Source $downloadUrl -Destination $destination

        # Update data
        $app.version = $latestVersion
        $app.url = $downloadUrl

        Write-Host -ForegroundColor Green "Updated $name"
    }
}

# Write to package file
$data | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8
pause
exit 0