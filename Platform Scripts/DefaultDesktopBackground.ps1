<#
.SYNOPSIS
    Enforces a corporate wallpaper for each user at logon.

.DESCRIPTION
    This script sets the default user’s desktop wallpaper to a predefined file.
    Note: Changes may only apply after first reboot.

.NOTES
    Update $wallpaperUrl and $themeUrl to desired values.
    Update $wallpaperPath to desired value.
    Deploy via Intune as a device-targeted Platform script.
#>

try {
    # --- Config ---
    $wallpaperUrl  = "https://url.to/wallpaper.jpg"
    $themeUrl      = "https://url.to/default.theme"

    $wallpaperDir  = "C:\Windows\Web\Wallpaper\Default"
    $wallpaperPath = Join-Path $wallpaperDir "wallpaper.jpg"

    $themeDir      = "$env:SystemRoot\Resources\Themes"
    $themePath     = Join-Path $themeDir "default.theme"

    $defaultHive   = "C:\Users\Default\NTUSER.DAT"
    $tempHiveName  = "TempDefault"

    # --- Ensure folders exist ---
    New-Item -ItemType Directory -Force -Path $wallpaperDir | Out-Null
    New-Item -ItemType Directory -Force -Path $themeDir | Out-Null

    # --- Download wallpaper ---
    Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath -UseBasicParsing -ErrorAction Stop
    Write-Output "Downloaded wallpaper to $wallpaperPath"

    # --- Download theme ---
    Invoke-WebRequest -Uri $themeUrl -OutFile $themePath -UseBasicParsing -ErrorAction Stop
    Write-Output "Downloaded theme to $themePath"

    # --- Verify Default User hive exists ---
    if (-not (Test-Path $defaultHive)) {
        throw "Default user hive not found at $defaultHive"
    }

    # --- Load Default User hive as HKEY_USERS\TempDefault ---
    # If hive is already loaded, remove it first (defensive)
    if (Test-Path "Registry::HKEY_USERS\$tempHiveName") {
        Write-Output "Temp hive already present; unloading first..."
        reg unload "HKU\$tempHiveName" | Out-Null
    }

    $loadResult = & reg load "HKU\$tempHiveName" $defaultHive 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to load default hive: $loadResult"
    }
    Write-Output "Loaded default hive as HKU\$tempHiveName"

    try {
        # --- Registry paths inside the loaded hive ---
        $themeRegPath = "Registry::HKEY_USERS\$tempHiveName\Software\Microsoft\Windows\CurrentVersion\Themes"
        $wallpaperRegPath = "Registry::HKEY_USERS\$tempHiveName\Control Panel\Desktop"

        # Ensure Themes key exists in the default hive
        if (-not (Test-Path $themeRegPath)) {
            New-Item -Path "Registry::HKEY_USERS\$tempHiveName\Software\Microsoft\Windows\CurrentVersion" -Name "Themes" -Force | Out-Null
            Write-Output "Created Themes key in default hive"
        }

        # Point Default User to the downloaded theme
        Set-ItemProperty -Path $themeRegPath -Name "CurrentTheme" -Value $themePath -Force
        Write-Output "Set CurrentTheme to $themePath in default hive"

        # Point Default Wallpaper to the downloaded image
        Set-ItemProperty -Path $wallpaperRegPath -Name "WallPaper" -Value $wallpaperPath -Force
        Write-Output "Set WallPaper to $wallpaperPath in default hive"

        Write-Output "Theme & wallpaper registered successfully for Default User."
    }
    finally {
        # Unload hive (ensure we clean up)
        $unloadResult = & reg unload "HKU\$tempHiveName" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Output "Warning: failed to unload hive HKU\${tempHiveName}: $unloadResult"
        } else {
            Write-Output "Unloaded hive HKU\$tempHiveName"
        }
    }

    # --- SAFELY disable Windows Spotlight via machine-wide policy (HKLM) ---
    # These are the policy keys Microsoft honours for turning off Spotlight features.
    $cloudContentPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"

    if (-not (Test-Path $cloudContentPolicyPath)) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "CloudContent" -Force | Out-Null
        Write-Output "Created policy key: $cloudContentPolicyPath"
    }

    # Disable Windows Spotlight features generally
    New-ItemProperty -Path $cloudContentPolicyPath -Name "DisableWindowsSpotlightFeatures" -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $cloudContentPolicyPath -Name "DisableSpotlightCollectionOnDesktop" -PropertyType DWord -Value 1 -Force | Out-Null

    Write-Output "Set machine policy to disable Windows Spotlight (HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent)"

    # (Optional) If you also want to disable tailored experiences (advertising-type content):
    # New-ItemProperty -Path $cloudContentPolicyPath -Name "DisableTailoredExperiencesWithDiagnosticData" -PropertyType DWord -Value 1 -Force | Out-Null

    exit 0
}
catch {
    Write-Output "Failed: $($_.Exception.Message)"
    exit 1
}
