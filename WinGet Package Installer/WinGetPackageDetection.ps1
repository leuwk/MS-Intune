# App ID to detect: Change to required AppID
$AppID = "9WZDNCRFJ3PZ"

# Marker file path
$markerFile = "C:\ProgramData\IntuneWinGet\InstalledApps\$AppID.installed"

# Log file path
$logFile = "C:\ProgramData\IntuneWinGet\AppDetection.log"

# Ensure log file exists (but don't write to STDOUT)
if (-not (Test-Path $logFile)) {
    New-Item -ItemType File -Path $logFile -Force | Out-Null
}

# Log function
function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logFile -Value "[$timestamp] $Message"
}

# Detection logic
if (Test-Path $markerFile) {
    Write-Log "Marker file found: $markerFile. $AppID is installed."
    Write-Output "$AppID is isntalled."   # <-- Intune sees this as DETECTED
    exit 0
}
else {
    Write-Log "Marker file not found: $markerFile. $AppID not installed."
    # No output -> Intune treats as NOT DETECTED
    exit 0
}
