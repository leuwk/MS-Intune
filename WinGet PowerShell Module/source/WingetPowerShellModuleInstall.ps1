<#
.SYNOPSIS
 Installs PowerShell 7 and WinGet PowerShell Module
.DESCRIPTION
 Installs PowerShell 7 and WinGet PowerShell Module
#>

try {
    # Force TLS 1.2 for GitHub/PSGallery
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Install NuGet Provider
    $provider = Get-PackageProvider NuGet -ListAvailable -ErrorAction Ignore
    if (-not $provider) {
        Install-PackageProvider -Name NuGet -Force -Scope AllUsers
    }

    # Ensure PSGallery is trusted
    if (-not (Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue)) {
        Register-PSRepository -Default
    }

    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

    # Install Microsoft.WinGet.Client for Windows PowerShell 5.1 for AllUsers
    if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
        Install-Module Microsoft.WinGet.Client -Force -AllowClobber -Confirm:$false -Scope AllUsers
    }

    # GitHub API endpoint for PowerShell releases
    $githubApiUrl = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'

    # Fetch the latest release details
    $release = Invoke-RestMethod -Uri $githubApiUrl

    # Find asset with .msi in the name
    $asset = $release.assets | Where-Object { $_.name -like "*msi*" -and $_.name -like "*x64*" } | Select-Object -First 1

    # Get the download URL and filename
    $downloadUrl = $asset.browser_download_url
    $filename    = $asset.name
    $downloadPath = Join-Path $env:TEMP $filename

    # Download the latest release
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath

    # Install PowerShell 7 silently
    Start-Process msiexec.exe -Wait -ArgumentList "/I `"$downloadPath`" /qn"

    # Locate pwsh.exe
    $pwshExecutable = "C:\Program Files\PowerShell\7\pwsh.exe"

    # Run a script block in PowerShell 7
    & $pwshExecutable -Command {
        $provider = Get-PackageProvider NuGet -ErrorAction Ignore
        if (-not $provider) {
            Install-PackageProvider -Name NuGet -Force -Scope AllUsers
        }

        if (-not (Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue)) {
            Register-PSRepository -Default
        }

        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

        Install-Module Microsoft.WinGet.Client -Force -AllowClobber -Confirm:$false -Scope AllUsers
        Import-Module Microsoft.WinGet.Client

        if (Get-Command Repair-WinGetPackageManager -ErrorAction SilentlyContinue) {
            Repair-WinGetPackageManager
        }
    }

    Write-Output "Installation completed successfully."
    exit 0
}
catch {
    Write-Error "Installation failed: $_"
    exit 1
}
