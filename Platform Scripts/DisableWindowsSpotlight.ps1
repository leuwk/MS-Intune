<#
.SYNOPSIS
    Enforces a corporate wallpaper for each user at logon.

.DESCRIPTION
    This script sets the user’s desktop wallpaper to a predefined file.
    It runs in HKCU (user context), overriding Spotlight after login.
    Note: Changes may only apply after first reboot.

.NOTES
    Update $wallpaperPath to desired value.
    Deploy via Intune as a user-targeted Platform script.
#>

try {
    # --- Config ---
    $wallpaperPath = "C:\Windows\Web\Wallpaper\Default\wallpaper.jpg"
    $wallpaperRegPath = "HKCU:\Control Panel\Desktop"
    $cloudContentRegPath = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"
    $windowsSpotlightRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\DesktopSpotlight\Settings"

    # --- Test CloudContent registry key exists, create if not ---    
    if (-not (Test-Path $cloudContentRegPath)) {
        New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows" -Name "CloudContent" -Force | Out-Null
        Write-Output "Created policy key: $cloudContentRegPath"
    }

    # --- Disable Windows Spotlight features generally ---
    Set-ItemProperty -Path $cloudContentRegPath -Name "DisableWindowsSpotlightFeatures" -Value 1 -Force | Out-Null
    Set-ItemProperty -Path $cloudContentRegPath -Name "DisableSpotlightCollectionOnDesktop" -Value 1 -Force | Out-Null

    # --- Test Spotlight Settings registry key exists, create if not ---    
    if (-not (Test-Path $windowsSpotlightRegPath)) {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\DesktopSpotlight" -Name "Settings" -Force | Out-Null
        Write-Output "Created policy key: $windowsSpotlightRegPath"
    }

    # --- Disable Windows Spotlight EnabledState ---
    Set-ItemProperty -Path $windowsSpotlightRegPath -Name "EnabledState" -Value 0 -Force | Out-Null
    Set-ItemProperty -Path $windowsSpotlightRegPath -Name "OneTimeUpgrade" -Value 1 -Force | Out-Null

    # --- Test Wallpaper exists on system, exit failed if not ---
    if (-not (Test-Path $wallpaperPath)) {
        Write-Output "Wallpaper not found at $wallpaperPath. Exiting."
        exit 1
    }

    # --- Set wallpaper registry value ---
    Set-ItemProperty -Path $wallpaperRegPath -Name "WallPaper" -Value $wallpaperPath -Force
    Write-Output "Set HKCU wallpaper to $wallpaperPath"

    # -- Kill Shell Experience Host process (Controls Spotlight) ---
    Stop-Process -Name ShellExperienceHost -Force -ErrorAction SilentlyContinue

    # --- Force Windows to refresh wallpaper ---
    RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
    Write-Output "Refreshed desktop wallpaper."

    Write-Output "Set user policy to disable Windows Spotlight. Exiting."
    exit 0
}
catch {
    Write-Output "Failed: $($_.Exception.Message)"
    exit 1
}
