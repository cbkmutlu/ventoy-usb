# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting access"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

. "$PSScriptRoot\ventoy\functions.ps1"

Write-Host "InitializeUserContext"
InitializeUserContext
Write-Host "CreateIE"
CreateIE
Write-Host "SetTimeFormat"
SetTimeFormat
Write-Host "SetPowerConfig"
SetPowerConfig
Write-Host "SetUACLow"
SetUACLow
Write-Host "SetP2PUpdateLocal"
SetP2PUpdateLocal
Write-Host "SetW11RightClick"
SetW11RightClick
Write-Host "SetUpdateTarget"
SetUpdateTarget
Write-Host "SetAutoTray"
SetAutoTray
Write-Host "SetSearchBoxAsIcon"
SetSearchBoxAsIcon
Write-Host "SetTheme"
SetTheme
Write-Host "SetAppearance"
SetAppearance
Write-Host "HideRecentShortcuts"
HideRecentShortcuts
Write-Host "HideItemsFromThisPC"
HideItemsFromThisPC
Write-Host "ShowItemsOnDesktop"
ShowItemsOnDesktop
Write-Host "ClearTaskbar"
ClearTaskbar
Write-Host "ClearStartMenu"
ClearStartMenu
Write-Host "DisableStartMenuPrograms"
DisableStartMenuPrograms
Write-Host "DisableStartMenuNotifications"
DisableStartMenuNotifications
Write-Host "DisableStartMenuFolders"
DisableStartMenuFolders
Write-Host "DisableWindowsInk"
DisableWindowsInk
Write-Host "DisableNewsAndInterests"
DisableNewsAndInterests
Write-Host "DisableAutoLogger"
DisableAutoLogger
Write-Host "DisableTelemetry"
DisableTelemetry
Write-Host "DisableSmartScreen"
DisableSmartScreen
Write-Host "DisableCopilot"
DisableCopilot
Write-Host "DisableCortana"
DisableCortana
Write-Host "DisableCortanaSearch"
DisableCortanaSearch
Write-Host "DisableWebSearch"
DisableWebSearch
Write-Host "DisableAppSuggestions"
DisableAppSuggestions
Write-Host "DisableWidgets"
DisableWidgets
Write-Host "DisableLocationTracking"
DisableLocationTracking
Write-Host "DisableWiFiSense"
DisableWiFiSense
Write-Host "DisableAdvertisingID"
DisableAdvertisingID
Write-Host "DisableFeedback"
DisableFeedback
Write-Host "DisableErrorReporting"
DisableErrorReporting
Write-Host "DisableScheduledTasks"
DisableScheduledTasks
Write-Host "DisableDiagTrack"
DisableDiagTrack
Write-Host "DisablePrefetcher"
DisablePrefetcher
Write-Host "DisableRecommended"
DisableRecommended
Write-Host "DisableScreenSaver"
DisableScreenSaver
Write-Host "DisableNetworkDevice"
DisableNetworkDevice
Write-Host "RemovePrinters"
RemovePrinters
Write-Host "RemoveOptionalFeatures"
RemoveOptionalFeatures
Write-Host "RemoveEdgeLnk"
RemoveEdgeLnk
Write-Host "RemovePackages"
RemovePackages
Write-Host "RemoveOneDrive"
RemoveOneDrive

Write-Host -ForegroundColor Yellow "Reboot system [ENTER] or any other key to Exit"
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

if ($key.VirtualKeyCode -eq 13) {
    shutdown -r -t 3
}
else {
    exit 1
}