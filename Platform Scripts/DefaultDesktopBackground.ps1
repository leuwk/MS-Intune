try {
    # --- Config ---
    $wallpaperUrl  = "https://wacestorage01.blob.core.windows.net/public/intune/customers/LUKE001/wallpaper.jpg"
    $themeUrl      = "https://wacestorage01.blob.core.windows.net/public/intune/customers/LUKE001/default.theme"

    $wallpaperDir  = "C:\Windows\Web\Wallpaper\Default"
    $wallpaperPath = Join-Path $wallpaperDir "wallpaper.jpg"

    $themeDir      = "$env:SystemRoot\Resources\Themes"
    $themePath     = Join-Path $themeDir "default.theme"

    $defaultHive   = "C:\Users\Default\NTUSER.DAT"

    # --- Ensure folders exist ---
    New-Item -ItemType Directory -Force -Path $wallpaperDir | Out-Null
    New-Item -ItemType Directory -Force -Path $themeDir | Out-Null

    # --- Download wallpaper ---
    Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath -UseBasicParsing

    # --- Download theme ---
    Invoke-WebRequest -Uri $themeUrl -OutFile $themePath -UseBasicParsing

    # --- Verify Default User hive exists ---
    if (-not (Test-Path $defaultHive)) {
        throw "Default user hive not found at $defaultHive"
    }

    # --- Load Default User hive as HKEY_USERS\TempDefault ---
    reg load HKU\TempDefault $defaultHive | Out-Null

    try {
        # --- Registry path inside the loaded hive ---
        $themeRegPath = "Registry::HKEY_USERS\TempDefault\Software\Microsoft\Windows\CurrentVersion\Themes"
        $wallpaperRegPath = "Registry::HKEY_USERS\TempDefault\Control Panel\Desktop"

        # Ensure Themes key exists
        if (-not (Test-Path $themeRegPath)) {
            New-Item -Path "Registry::HKEY_USERS\TempDefault\Software\Microsoft\Windows\CurrentVersion" -Name "Themes" -Force | Out-Null
        }

        # Point Default User to the downloaded theme
        Set-ItemProperty -Path $themeRegPath -Name "CurrentTheme" -Value $themePath -Force

        # Point Default Wallpaper to the downloaded image
        Set-ItemProperty -Path $wallpaperRegPath -Name "WallPaper" -Value $wallpaperPath -Force

        Write-Output "Theme registered successfully for Default User."
    }
    finally {
        # Unload hive
        reg unload HKU\TempDefault | Out-Null
    }

    exit 0
}
catch {
    Write-Output "Failed: $($_.Exception.Message)"
    exit 1
}
