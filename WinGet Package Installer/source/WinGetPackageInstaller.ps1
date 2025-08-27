# Initialise parameters
param(
    [Parameter(Mandatory = $true)]
    [string]$AppID,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Install","Uninstall")]
    [string]$Action
)

# Initialise variables
$logDir = "C:\ProgramData\IntuneWinGet"
$logFile = Join-Path $logDir "PackageInstallation.log"
$markerPath = Join-Path $logDir "InstalledApps"
$markerFile = Join-Path $markerPath "$AppID.installed"

# Ensure log directory exists
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

# Initialize log file (force create if missing)
if (-not (Test-Path $logFile)) {
    New-Item -Path $logFile -ItemType File -Force | Out-Null
}

# Log function
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry
    if ($Level -eq "ERROR") {
        Write-Error $Message
    } else {
        Write-Output $Message
    }
}

# Initial logging
Write-Log "==== Script started ===="
Write-Log "AppID = $AppID"
Write-Log "Action = $Action"

# Run script action
try {
    Write-Log "Importing Microsoft.WinGet.Client Module"
    Import-Module Microsoft.WinGet.Client -ErrorAction Stop
    Write-Log "Imported Microsoft.WinGet.Client successfully"

    switch ($Action) {
        # Attempt WinGet package install
        "Install" {
            Write-Log "Starting installation for $AppID"
            $installed = Get-WinGetPackage -Id $AppID -ErrorAction SilentlyContinue
            if ($installed) {
                Write-Log "$AppID already installed."
                exit 0
            }

            Install-WinGetPackage -Id $AppID -Mode Silent -Scope System -Force -ErrorAction Stop
            Write-Log "Successfully installed $AppID"

            if (-not (Test-Path $markerPath)) {
                New-Item -Path $markerPath -ItemType Directory -Force | Out-Null
                Write-Log "Created marker directory: $markerPath"
            }

            New-Item -Path $markerFile -ItemType File -Force | Out-Null
            Write-Log "Created marker file: $markerFile"
        }

        # Attempt WinGet package uninstall
        "Uninstall" {
            Write-Log "Starting uninstall for $AppID"
            $installed = Get-WinGetPackage -Id $AppID -ErrorAction SilentlyContinue
            if (-not $installed) {
                Write-Log "$AppID not installed."
                exit 0
            }

            Uninstall-WinGetPackage -Id $AppID -Mode Silent -Force -ErrorAction Stop
            Write-Log "Successfully uninstalled $AppID"

            if (Test-Path $markerFile) {
                Remove-Item -Path $markerFile -Force
                Write-Log "Deleted marker file: $markerFile"
            }
        }
    }

    Write-Log "==== Script finished successfully ===="
    exit 0
}

catch {
    Write-Log "ERROR: $($_.Exception.Message)" "ERROR"
    exit 1
}
