<#
.SYNOPSIS
    Enforces a corporate wallpaper for each user at logon.

.DESCRIPTION
    This script sets the user’s desktop wallpaper to a predefined file.
    It runs in HKCU (user context), overriding Spotlight after login.

.NOTES
    Deploy via Intune as a user-targeted Platform script.
#>

try {
    # --- Config ---
    $wallpaperPath = "C:\Windows\Web\Wallpaper\Default\wallpaper.jpg"
    $wallpaperRegPath = "HKCU:\Control Panel\Desktop"
    $cloudContentRegPath = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"

    # --- Test Wallpaper exists on system, exit failed if not ---
    if (-not (Test-Path $wallpaperPath)) {
        Write-Output "Wallpaper not found at $wallpaperPath. Exiting."
        exit 1
    }

    # --- Set wallpaper registry value ---
    Set-ItemProperty -Path $wallpaperRegPath -Name "WallPaper" -Value $wallpaperPath -Force
    Write-Output "Set HKCU wallpaper to $wallpaperPath"

    # --- Force Windows to refresh wallpaper ---
    RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
    Write-Output "Refreshed desktop wallpaper."

    # --- Test registry CloudContent registry key exists, create if not ---    
    if (-not (Test-Path $cloudContentPolicyPath)) {
        New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows" -Name "CloudContent" -Force | Out-Null
        Write-Output "Created policy key: $cloudContentPolicyPath"
    }

    # --- Disable Windows Spotlight features generally ---
    Set-ItemProperty -Path $cloudContentPolicyPath -Name "DisableWindowsSpotlightFeatures" -Value 1 -Force | Out-Null
    Set-ItemProperty -Path $cloudContentPolicyPath -Name "DisableSpotlightCollectionOnDesktop" -Value 1 -Force | Out-Null

    Write-Output "Set user policy to disable Windows Spotlight. Exiting."
    exit 0
}
catch {
    Write-Output "Failed: $($_.Exception.Message)"
    exit 1
}
