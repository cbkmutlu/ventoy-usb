# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting access"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

. "$PSScriptRoot\..\ventoy\functions.ps1"

Write-Host "InitializeUserContext"
InitializeUserContext
Write-Host "SetTimeFormat"
SetTimeFormat -HKCU
Write-Host "SetP2PUpdateLocal"
SetP2PUpdateLocal -HKCU
Write-Host "SetW11RightClick"
SetW11RightClick
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
Write-Host "ShowItemsOnDesktop"
ShowItemsOnDesktop
Write-Host "ClearTaskbar"
ClearTaskbar
Write-Host "ClearStartMenu"
ClearStartMenu
Write-Host "DisableNewsAndInterests"
DisableNewsAndInterests -HKCU
Write-Host "DisableSmartScreen"
DisableSmartScreen
Write-Host "DisableCopilot"
DisableCopilot
Write-Host "DisableCortana"
DisableCortana
Write-Host "DisableWebSearch"
DisableWebSearch
Write-Host "DisableAppSuggestions"
DisableAppSuggestions
Write-Host "DisableWidgets"
DisableWidgets -HKCU
Write-Host "DisableAdvertisingID"
DisableAdvertisingID
Write-Host "DisableFeedback"
DisableFeedback
Write-Host "DisableRecommended"
DisableRecommended
Write-Host "DisableScreenSaver"
DisableScreenSaver
Write-Host "RemovePrinters"
RemovePrinters
Write-Host "RemoveEdgeLnk"
RemoveEdgeLnk

Write-Host -ForegroundColor Yellow "Reboot system [ENTER] or any other key to Exit"
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

if ($key.VirtualKeyCode -eq 13) {
    shutdown -r -t 3
}
else {
    exit 1
}