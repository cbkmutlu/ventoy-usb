# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting access"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

. "$PSScriptRoot\..\ventoy\functions.ps1"

InitializeUserContext
Write-Host "InitializeUserContext"
SetTimeFormat -HKCU
Write-Host "SetTimeFormat"
SetP2PUpdateLocal -HKCU
Write-Host "SetP2PUpdateLocal"
SetW11RightClick
Write-Host "SetW11RightClick"
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
ShowItemsOnDesktop
Write-Host "ShowItemsOnDesktop"
ClearTaskbar
Write-Host "ClearTaskbar"
ClearStartMenu
Write-Host "ClearStartMenu"
DisableNewsAndInterests -HKCU
Write-Host "DisableNewsAndInterests"
DisableSmartScreen
Write-Host "DisableSmartScreen"
DisableCopilot
Write-Host "DisableCopilot"
DisableCortana
Write-Host "DisableCortana"
DisableWebSearch
Write-Host "DisableWebSearch"
DisableAppSuggestions
Write-Host "DisableAppSuggestions"
DisableWidgets -HKCU
Write-Host "DisableWidgets"
DisableAdvertisingID
Write-Host "DisableAdvertisingID"
DisableFeedback
Write-Host "DisableFeedback"
DisableRecommended
Write-Host "DisableRecommended"
DisableScreenSaver
Write-Host "DisableScreenSaver"
RemovePrinters
Write-Host "RemovePrinters"
RemoveEdgeLnk
Write-Host "RemoveEdgeLnk"

Write-Host -ForegroundColor Yellow "Reboot system [ENTER] or any other key to Exit"
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

if ($key.VirtualKeyCode -eq 13) {
    shutdown -r -t 3
}
else {
    exit 1
}