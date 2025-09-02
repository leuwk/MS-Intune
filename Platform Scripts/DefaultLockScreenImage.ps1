<#
.SYNOPSIS
    Enforces a corporate lock screen image during Autopilot provisioning.

.DESCRIPTION
    This script sets the systems lock screen image to a predefined file.
    It runs in HKLM (system context).
    Note: Changes may only apply after first reboot.

.NOTES
    Update $lockscreenPath to desired value.
    Deploy via Intune as a device-targeted Platform script.
#>

try {
    # --- Config ---
    $lockscreenUrl  = "https://wacestorage01.blob.core.windows.net/public/intune/customers/LUKE001/lockscreen.jpg"

    $lockscreenDir  = "C:\Windows\Web\Wallpaper\Default"
    $lockscreenPath = Join-Path $lockscreenDir "lockscreen.jpg"

    $lockscreenRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

    # --- Ensure folder exists ---
    if (-not (Test-Path $lockscreenDir)) {
        New-Item -ItemType Directory -Force -Path $lockscreenDir | Out-Null
        Write-Output "Created lock screen folder: $lockscreenDir"
    }

    # --- Download lock screen image ---
    Invoke-WebRequest -Uri $lockscreenUrl -OutFile $lockscreenPath -UseBasicParsing -ErrorAction Stop
    Write-Output "Downloaded lock screen image to $lockscreenPath"

    # --- Test PersonalizationCSP registry key exists, create if not ---    
    if (-not (Test-Path $lockscreenRegPath)) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -Name "PersonalizationCSP" -Force | Out-Null
        Write-Output "Created policy key: $lockscreenRegPath"
    }

    # --- Set registry keys for lock screen image application ---
    Set-ItemProperty -Path $lockscreenRegPath -Name "LockScreenImagePath" -Value $lockscreenPath -Type String -Force | Out-Null
    Set-ItemProperty -Path $lockscreenRegPath -Name "LockScreenImageUrl" -Value $lockscreenPath -Type String -Force | Out-Null
    Set-ItemProperty -Path $lockscreenRegPath -Name "LockScreenImageStatus" -Value 1 -Type Dword -Force | Out-Null

    Write-Output "Set system policy to configure default Lock Screen image. Exiting."
    exit 0
}
catch {
    Write-Output "Failed: $($_.Exception.Message)"
    exit 1
}
