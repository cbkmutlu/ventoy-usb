# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting access"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

. "$PSScriptRoot\ventoy\functions.ps1"

InitializeUserContext
Write-Host "InitializeUserContext"
CreateIE
Write-Host "CreateIE"
SetTimeFormat
Write-Host "SetTimeFormat"
SetPowerConfig
Write-Host "SetPowerConfig"
SetUACLow
Write-Host "SetUACLow"
SetP2PUpdateLocal
Write-Host "SetP2PUpdateLocal"
SetW11RightClick
Write-Host "SetW11RightClick"
SetUpdateTarget
Write-Host "SetUpdateTarget"
SetAutoTray
Write-Host "SetAutoTray"
SetSearchBoxAsIcon
Write-Host "SetSearchBoxAsIcon"
SetTheme
Write-Host "SetTheme"
SetAppearance
Write-Host "SetAppearance"
HideRecentShortcuts
Write-Host "HideRecentShortcuts"
HideItemsFromThisPC
Write-Host "HideItemsFromThisPC"
ShowItemsOnDesktop
Write-Host "ShowItemsOnDesktop"
ClearTaskbar
Write-Host "ClearTaskbar"
ClearStartMenu
Write-Host "ClearStartMenu"
DisableStartMenuPrograms
Write-Host "DisableStartMenuPrograms"
DisableStartMenuNotifications
Write-Host "DisableStartMenuNotifications"
DisableStartMenuFolders
Write-Host "DisableStartMenuFolders"
DisableWindowsInk
Write-Host "DisableWindowsInk"
DisableNewsAndInterests
Write-Host "DisableNewsAndInterests"
DisableAutoLogger
Write-Host "DisableAutoLogger"
DisableTelemetry
Write-Host "DisableTelemetry"
DisableSmartScreen
Write-Host "DisableSmartScreen"
DisableCopilot
Write-Host "DisableCopilot"
DisableCortana
Write-Host "DisableCortana"
DisableCortanaSearch
Write-Host "DisableCortanaSearch"
DisableWebSearch
Write-Host "DisableWebSearch"
DisableAppSuggestions
Write-Host "DisableAppSuggestions"
DisableWidgets
Write-Host "DisableWidgets"
DisableLocationTracking
Write-Host "DisableLocationTracking"
DisableWiFiSense
Write-Host "DisableWiFiSense"
DisableAdvertisingID
Write-Host "DisableAdvertisingID"
DisableFeedback
Write-Host "DisableFeedback"
DisableErrorReporting
Write-Host "DisableErrorReporting"
DisableScheduledTasks
Write-Host "DisableScheduledTasks"
DisableDiagTrack
Write-Host "DisableDiagTrack"
DisablePrefetcher
Write-Host "DisablePrefetcher"
DisableRecommended
Write-Host "DisableRecommended"
DisableScreenSaver
Write-Host "DisableScreenSaver"
DisableNetworkDevice
Write-Host "DisableNetworkDevice"
RemovePrinters
Write-Host "RemovePrinters"
RemoveOptionalFeatures
Write-Host "RemoveOptionalFeatures"
RemoveEdgeLnk
Write-Host "RemoveEdgeLnk"
RemovePackages
Write-Host "RemovePackages"
RemoveOneDrive
Write-Host "RemoveOneDrive"