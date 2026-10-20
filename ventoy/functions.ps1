function EnsurePath {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    return $Path
}

# Initialize user context
function InitializeUserContext {
    $script:basePath = $PSScriptRoot
    $script:userExplorer = Get-Process explorer -IncludeUserName | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1 -ExpandProperty UserName
    $script:userId = ([System.Security.Principal.NTAccount]$userExplorer).Translate([System.Security.Principal.SecurityIdentifier]).Value
    $script:userProfile = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$userId").ProfileImagePath
    $script:userDesktop = Join-Path $userProfile "Desktop"
    $script:userAppData = Join-Path $userProfile "AppData\Local"
    $script:userName = Split-Path $userProfile -Leaf
}

# Creates a shortcut to Internet Explorer on the desktop.
function CreateIE {
    $path = "C:\ie.vbs"
    $content = @'
Set ie = CreateObject("InternetExplorer.Application")
ie.Visible = True

If WScript.Arguments.Count > 0 Then
    ie.Navigate WScript.Arguments(0)
Else
    ie.Navigate "about:blank"
End If
'@

    $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBomEncoding)
}

# Set24HourTimeFormat
function SetTimeFormat {
    param([switch]$HKCU)

    if (-not $HKCU) {
        $path = EnsurePath -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Locale"
        Set-ItemProperty -Path $path -Name "sTimeFormat" -Value "HH:mm:ss" -ErrorAction SilentlyContinue
    }
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Control Panel\International"
    Set-ItemProperty -Path $path -Name "sTimeFormat" -Value "HH:mm:ss" -ErrorAction SilentlyContinue
}

# Sets the power configuration to Ultimate.
function SetPowerConfig {
    $ultimateTemplate = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    $ultimateGuid = "7a8b9c10-1234-4567-8901-abcdef123456"

    $exists = powercfg /list | Select-String $ultimateGuid
    if (-not $exists) {
        powercfg /duplicatescheme $ultimateTemplate $ultimateGuid | Out-Null
        Start-Sleep -Seconds 2
    }

    powercfg /setactive $ultimateGuid
    Start-Sleep -Seconds 2

    powercfg /change monitor-timeout-dc 60
    powercfg /change monitor-timeout-ac 120
    powercfg /change standby-timeout-dc 180
    powercfg /change standby-timeout-ac 240
}

# UAC Level
function SetUACLow {
    $path = EnsurePath -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
    Set-ItemProperty -Path $path -Name "ConsentPromptBehaviorAdmin" -Type DWord -Value 5
    Set-ItemProperty -Path $path -Name "PromptOnSecureDesktop" -Type DWord -Value 0
}

# Disables P2P updates (Delivery Optimization).
function SetP2PUpdateLocal {
    param([switch]$HKCU)

    if (-not $HKCU) {
        $path = EnsurePath -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"
        Set-ItemProperty -Path $path -Name "DODownloadMode" -Type DWord -Value 1
    }

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization"
    Set-ItemProperty -Path $path -Name "SystemSettingsDownloadMode" -Type DWord -Value 3
}

# Adds "Copy to " and "Move to " options to the context menu.
function SetW11RightClick {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    Set-ItemProperty -Path $path -Name "(Default)" -Value "" -Force | Out-Null
}

# Disables automatic updates.
function SetUpdateTarget {
    $build = [System.Environment]::OSVersion.Version.Build
    if ($build -lt 22000) {
        $path = EnsurePath -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"
        Set-ItemProperty -Path $path -Name "DisableWUfBSafeguards" -Type DWord -Value 1
        Set-ItemProperty -Path $path -Name "TargetReleaseVersion" -Type DWord -Value 1
        Set-ItemProperty -Path $path -Name "ProductVersion" -Type String -Value "Windows 10"
        Set-ItemProperty -Path $path -Name "TargetReleaseVersionInfo" -Type String -Value "22H2"
    }
}

# Disables the "Always combine" option for taskbar buttons.
function SetAutoTray {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer"
    Set-ItemProperty -Path $path -Name "EnableAutoTray" -Type DWord -Value 0
}

# Hides the search box and shows it as an icon.
function SetSearchBoxAsIcon {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Search"
    Set-ItemProperty -Path $path -Name "SearchboxTaskbarMode" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "SearchboxTaskbarModePrevious" -Type DWord -Value 1
}

# Sets the theme to dark mode.
function SetTheme {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-ItemProperty -Path $path -Name "SystemUsesLightTheme" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AppsUseLightTheme" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "EnableTransparency" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "ColorPrevalence" -Type DWord -Value 0
}

# Sets the appearance of the system.
function SetAppearance {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Control Panel\Keyboard"
    Set-ItemProperty -Path $path -Name "KeyboardDelay" -Type DWord -Value 0

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Control Panel\Desktop"
    Set-ItemProperty -Path $path -Name "DragFullWindows" -Type String -Value 0
    Set-ItemProperty -Path $path -Name "MenuShowDelay" -Type String -Value 0
    Set-ItemProperty -Path $path -Name "FontSmoothing" -Type String -Value 2
    Set-ItemProperty -Path $path -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](0x90, 0x32, 0x07, 0x80, 0x10, 0x00, 0x00, 0x00))

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Control Panel\Desktop\WindowMetrics"
    Set-ItemProperty -Path $path -Name "MinAnimate" -Type String -Value 0
    Set-ItemProperty -Path $path -Name "IconSpacing" -Type String -Value "-1245"
    Set-ItemProperty -Path $path -Name "IconVerticalSpacing" -Type String -Value "-1125"

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\DWM"
    Set-ItemProperty -Path $path -Name "EnableAeroPeek" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AlwaysHibernateThumbnails" -Type DWord -Value 0

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    Set-ItemProperty -Path $path -Name "VisualFXSetting" -Type DWord -Value 3

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $path -Name "ListviewAlphaSelect" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "ListviewShadow" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "TaskbarAnimations" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "IconsOnly" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AutoCheckSelect" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "DisableThumbnailCache" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "DisableThumbsDBOnNetworkFolders" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "LaunchTo" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "ShowTaskViewButton" -Type DWord -Value 0

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
    Set-ItemProperty -Path $path -Name "ScoobeSystemSettingEnabled" -Type DWord -Value 0

    # Disables the "Always combine" option for taskbar buttons.
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Policies\Microsoft\Windows\Explorer"
    Set-ItemProperty -Path $path -Name "HideRecentlyAddedApps" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "ForceStartSize" -Type DWord -Value 1
}

# Disables the "Recent items" feature.
function HideRecentShortcuts {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer"
    Set-ItemProperty -Path $path -Name "ShowFrequent" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "ShowRecent" -Type DWord -Value 0
}

# Hides items from "This PC".
function HideItemsFromThisPC {
    # 3DObjects
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    # Desktop
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    # Documents
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    # Downloads
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    # Music
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    # Pictures
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    # Videos
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null;
}

# Shows items on the desktop.
function ShowItemsOnDesktop {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu"
    Set-ItemProperty -Path $path -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Type DWord -Value 0
    # Set-ItemProperty -Path $path -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Type DWord -Value 0

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
    Set-ItemProperty -Path $path -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Type DWord -Value 0
    # Set-ItemProperty -Path $path -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Type DWord -Value 0

    # $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
    # Set-ItemProperty -Path $path -Name "(Default)" -Value "Bilgisayar"
    # $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}"
    # Set-ItemProperty -Path $path -Name "(Default)" -Value "Çöp"
}

# Clears the Taskbar.
function ClearTaskbar {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
    Set-ItemProperty -Path $path -Name "Favorites" -Type Binary -Value ([byte[]](255))
    Remove-ItemProperty -Path $path -Name "FavoritesResolve" -ErrorAction SilentlyContinue
}

# Clears the Start Menu.
function ClearStartMenu {
    $build = [System.Environment]::OSVersion.Version.Build
    # Windows 10 Creators Update (1703) and earlier
    if ($build -ge 15063 -and $build -le 16299) {
        Get-ChildItem -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" -Include "*.group" -Recurse | ForEach-Object {
            $data = (Get-ItemProperty -Path "$($_.PsPath)\Current" -Name "Data").Data -Join ","
            $data = $data.Substring(0, $data.IndexOf(",0,202,30") + 9) + ",0,202,80,0,0"
            Set-ItemProperty -Path "$($_.PsPath)\Current" -Name "Data" -Type Binary -Value $data.Split(",")
        }
    }
    # Windows 10 Redstone 3 (17134) and later
    elseif ($build -ge 17134 -and $build -lt 22000) {
        $key = Get-ItemProperty -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\*start.tilegrid`$windows.data.curatedtilecollection.tilecollection\Current"
        $data = $key.Data[0..25] + ([byte[]](202, 50, 0, 226, 44, 1, 1, 0, 0))
        Set-ItemProperty -Path $key.PSPath -Name "Data" -Type Binary -Value $data
        Stop-Process -Name "ShellExperienceHost" -Force -ErrorAction SilentlyContinue
    }
}

# Disables the "More programs" option in the Start Menu.
function DisableStartMenuPrograms {
    $path = EnsurePath -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    Set-ItemProperty -Path $path -Name "NoChangeStartMenu" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "NoStartMenuMorePrograms" -Type DWord -Value 0 #2
    Set-ItemProperty -Path $path -Name "NoStartMenuMFUprogramsList" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "NoRecentDocsHistory" -Type DWord -Value 1
}

# Disables Start Menu folders.
function DisableStartMenuFolders {
    $path = EnsurePath -Path "HKLM:\Software\Microsoft\PolicyManager\current\device\Start"
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderDocuments" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderDocuments_ProviderSet" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderDownloads" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderDownloads_ProviderSet" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderFileExplorer" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderFileExplorer_ProviderSet" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderMusic" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderMusic_ProviderSet" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderNetwork" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderNetwork_ProviderSet" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderPersonalFolder" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderPersonalFolder_ProviderSet" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderPictures" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderPictures_ProviderSet" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderSettings" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderSettings_ProviderSet" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderVideos" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AllowPinnedFolderVideos_ProviderSet" -Type DWord -Value 1
}

# Disables Start Menu notifications.
function DisableStartMenuNotifications {
    $path = EnsurePath -Path "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
    Set-ItemProperty -Path $path -Name "NoTileApplicationNotification" -Type DWord -Value 1
}

# Disables the "Windows Ink Workspace" feature.
function DisableWindowsInk {
    $path = EnsurePath -Path "HKLM:\Software\Policies\Microsoft\WindowsInkWorkspace"
    Set-ItemProperty -Path $path -Name "AllowSuggestedAppsInWindowsInkWorkspace" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AllowWindowsInkWorkspace" -Type DWord -Value 0
}

# Disables "News and Interests" feature.
function DisableNewsAndInterests {
    param([switch]$HKCU)

    if (-not $HKCU) {
        $path = EnsurePath -Path "HKLM:\Software\Policies\Microsoft\Windows\Windows Feeds"
        Set-ItemProperty -Path $path -Name "EnableFeeds" -Type DWord -Value 0
    }

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Feeds"
    Set-ItemProperty -Path $path -Name "ShellFeedTaskbarSuggestionsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "EnShellFeedsTaskbarViewMode" -Type DWord -Value BB36E869 -ErrorAction SilentlyContinue
}

# Disables automatic logging.
function DisableAutoLogger {
    $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
    Remove-Item -Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl" -ErrorAction SilentlyContinue | Out-Null
    icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null
}

# Disables telemetry.
function DisableTelemetry {
    $path = EnsurePath -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    Set-ItemProperty -Path $path -Name "AllowTelemetry" -Type DWord -Value 0

    $path = EnsurePath -Path "HKLM:\Software\Policies\Microsoft\Windows\DataCollection"
    Set-ItemProperty -Path $path -Name "AllowTelemetry" -Type DWord -Value 0

    $path = EnsurePath -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    Set-ItemProperty -Path $path -Name "AllowTelemetry" -Type DWord -Value 0

    Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\ProgramDataUpdater" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Autochk\Proxy" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" -ErrorAction SilentlyContinue | Out-Null
}

# Disables SmartScreen.
function DisableSmartScreen {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer"
    Set-ItemProperty -Path $path -Name "SmartScreenEnabled" -Type String -Value "Off"

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\AppHost"
    Set-ItemProperty -Path $path -Name "EnableWebContentEvaluation" -Type DWord -Value 0
}

# Disables Copilot.
function DisableCopilot {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Policies\Microsoft\Windows\WindowsCopilot"
    Set-ItemProperty -Path $path -Name "TurnOffWindowsCopilot" -Type DWord -Value 1

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $path -Name "ShowCopilotButton" -Type DWord -Value 0
}

# Disables Cortana.
function DisableCortana {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Personalization\Settings"
    Set-ItemProperty -Path $path -Name "AcceptedPrivacyPolicy" -Type DWord -Value 0

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\InputPersonalization"
    Set-ItemProperty -Path $path -Name "RestrictImplicitTextCollection" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "RestrictImplicitInkCollection" -Type DWord -Value 1

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Policies\Microsoft\InputPersonalization"
    Set-ItemProperty -Path $path -Name "AllowInputPersonalization" -Type DWord -Value 0

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\InputPersonalization\TrainedDataStore"
    Set-ItemProperty -Path $path -Name "HarvestContacts" -Type DWord -Value 0

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $path -Name "ShowCortanaButton" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "ShowCopilotButton" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "TaskbarMn" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "TaskbarAl" -Type DWord -Value 0
}

# Disables Cortana search.
function DisableCortanaSearch {
    $path = EnsurePath -Path "HKLM:\Software\Policies\Microsoft\Windows\Windows Search"
    Set-ItemProperty -Path $path -Name "AllowCortana" -Type DWord -Value 0
}

# Disables web search.
function DisableWebSearch {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Search"
    Set-ItemProperty -Path $path -Name "BingSearchEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "CortanaConsent" -Type DWord -Value 0

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Policies\Microsoft\Windows\Windows Search"
    Set-ItemProperty -Path $path -Name "DisableWebSearch" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "ConnectedSearchUseWebOverMeteredConnections" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "ConnectedSearchUseWeb" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AllowSearchToUseLocation" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "AlwaysUseAutoLangDetection" -Type DWord -Value 0
}

# Disables app suggestions.
function DisableAppSuggestions {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-ItemProperty -Path $path -Name "ContentDeliveryAllowed" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "OemPreInstalledAppsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "PreInstalledAppsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "PreInstalledAppsEverEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SilentInstalledAppsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SystemPaneSuggestionsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SubscribedContent-310093Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SubscribedContent-314559Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SubscribedContent-338387Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SubscribedContent-338389Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SubscribedContent-338393Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SubscribedContent-353694Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SubscribedContent-353696Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SubscribedContent-353698Enabled" -Type DWord -Value 0
}

# Disables Widgets.
function DisableWidgets {
    param([switch]$HKCU)

    if (-not $HKCU) {
        $path = EnsurePath -Path "HKLM:\Software\Policies\Microsoft\Windows\CloudContent"
        Set-ItemProperty -Path $path -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 1
    }

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $path -Name "TaskbarMn" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "TaskbarAl" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "TaskbarDa" -Type DWord -Value 0
}

# Disables location tracking.
function DisableLocationTracking {
    $path = EnsurePath -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
    Set-ItemProperty -Path $path -Name "SensorPermissionState" -Type DWord -Value 0

    $path = EnsurePath -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
    Set-ItemProperty -Path $path -Name "Status" -Type DWord -Value 0
}

# Disables WiFi Sense.
function DisableWiFiSense {
    $path = EnsurePath -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
    Set-ItemProperty -Path $path -Name "Value" -Type DWord -Value 0

    $path = EnsurePath -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
    Set-ItemProperty -Path $path -Name "Value" -Type DWord -Value 0

    $path = EnsurePath -Path "HKLM:\Software\Microsoft\WcmSvc\wifinetworkmanager\config"
    Set-ItemProperty -Path $path -Name "AutoConnectAllowedOEM" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "WiFISenseAllowed" -Type DWord -Value 0
}

# Disables advertising ID.
function DisableAdvertisingID {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    Set-ItemProperty -Path $path -Name "Enabled" -Type DWord -Value 0

    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Windows\CurrentVersion\Privacy"
    Set-ItemProperty -Path $path -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Type DWord -Value 0
}

# Disables feedback.
function DisableFeedback {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Microsoft\Siuf\Rules"
    Set-ItemProperty -Path $path -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "RunDiagnostics" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "SubmitType" -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name "PeriodInNanoSeconds" -Type DWord -Value 0
}

# Disables error reporting.
function DisableErrorReporting {
    $path = EnsurePath -Path "HKLM:\Software\Microsoft\Windows\Windows Error Reporting\Consent"
    Set-ItemProperty -Path $path -Name "ForceConsent" -Type DWord -Value 0

    $path = EnsurePath -Path "HKLM:\Software\Microsoft\Windows\Windows Error Reporting\Recovery"
    Set-ItemProperty -Path $path -Name "CeipEnable" -Type DWord -Value 0

    $path = EnsurePath -Path "HKLM:\Software\Microsoft\Windows\Windows Error Reporting"
    Set-ItemProperty -Path $path -Name "Disabled" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "DontSendAdditionalData" -Type DWord -Value 1
}

# Disables scheduled tasks.
function DisableScheduledTasks {
    Disable-ScheduledTask -TaskName "XblGameSaveTask" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Consolidator" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "UsbCeip" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "DmClient" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "DmClientOnScenarioDownload" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClient" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Windows Error Reporting\QueueReporting" | Out-Null
}

# Disables DiagTrack.
function DisableDiagTrack {
    Stop-Service "DiagTrack" -WarningAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Disabled
}

# Disables prefetcher.
function DisablePrefetcher {
    $path = EnsurePath -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
    Set-ItemProperty -Path $path -Name "EnablePrefetcher" -Type DWord -Value 0
}

# Disables recommended items in Start Menu.
function DisableRecommended {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Policies\Microsoft\Windows\WindowsExplorer"
    Set-ItemProperty -Path $path -Name "HideRecommendedSection" -Type DWord -Value 1
}

# Disables screen saver.
function DisableScreenSaver {
    $path = EnsurePath -Path "Registry::HKEY_USERS\$userId\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
    Set-ItemProperty -Path $path -Name "ScreenSaveActive" -Type String -Value 0
}

# Disables network device auto-setup.
function DisableNetworkDevice {
    Stop-Service "NcdAutoSetup" -ErrorAction SilentlyContinue
    Set-Service "NcdAutoSetup" -StartupType Disabled
    $path = EnsurePath -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private"
    Set-ItemProperty -Path $path -Name "AutoSetup" -Type DWord -Value 0
}

# Removes printers.
function RemovePrinters {
    Remove-Printer -Name "*XPS*" -ErrorAction SilentlyContinue
    Remove-Printer -Name "*Fax*" -ErrorAction SilentlyContinue
    Remove-Printer -Name "*OneNote*" -ErrorAction SilentlyContinue
}

# Removes optional features.
function RemoveOptionalFeatures {
    Get-WindowsCapability -Online | Where-Object { $_.Name -like "*App.StepsRecorder*" } | Remove-WindowsCapability -Online | Out-Null
    Get-WindowsCapability -Online | Where-Object { $_.Name -like "*Print.Fax.Scan*" } | Remove-WindowsCapability -Online | Out-Null
    Get-WindowsCapability -Online | Where-Object { $_.Name -like "*XPS.Viewer*" } | Remove-WindowsCapability -Online | Out-Null
    Get-WindowsCapability -Online | Where-Object { $_.Name -like "*Microsoft.Windows.WordPad*" } | Remove-WindowsCapability -Online | Out-Null
}

# Removes Edge shortcuts.
function RemoveEdgeLnk {
    Remove-Item -Path "$env:PUBLIC\Desktop\Microsoft Edge.lnk" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$userDesktop\Microsoft Edge.lnk" -Force -Recurse -ErrorAction SilentlyContinue
}

# Removes packages.
function RemovePackages {
    $packages = @(
        # Xbox
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.Xbox.TCUI",

        # Cortana
        "Microsoft.549981C3F5F10",

        # Custom
        "Microsoft.Copilot",
        "Microsoft.Windows.AIHub",
        "Clipchamp.Clipchamp",
        "Microsoft.OneDrive",
        "Microsoft.PCManager",
        "Microsoft.MicrosoftJournal",
        "Microsoft.NetworkSpeedTest",
        "Microsoft.Office.OneNote",
        "Microsoft.Office.Lens",
        "Microsoft.Office.Sway",

        # BuiltIn
        "Microsoft.3DBuilder",
        "Microsoft.ScreenSketch",
        "Microsoft.AppConnector",
        "Microsoft.BingFinance",
        "Microsoft.BingFoodAndDrink",
        "Microsoft.BingHealthAndFitness",
        "Microsoft.BingMaps",
        "Microsoft.BingNews",
        "Microsoft.News",
        "Microsoft.PPIProjection",
        "Microsoft.BingSports",
        "Microsoft.BingTranslator",
        "Microsoft.BingTravel",
        "Microsoft.BingWeather",
        "Microsoft.CommsPhone",
        "Microsoft.ConnectivityStore",
        "Microsoft.FreshPaint",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.HelpAndTips",
        "Microsoft.Media.PlayReadyClient.2",
        "Microsoft.Messaging",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftPowerBIForWindows",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftStickyNotes",
        "Microsoft.MinecraftUWP",
        "Microsoft.MixedReality.Portal",
        "Microsoft.MoCamera",
        "Microsoft.MSPaint",
        "Microsoft.NetworkSpeedTest",
        "Microsoft.OfficeLens",
        "Microsoft.Office.Sway",
        "Microsoft.Office.Todo.List",
        "Microsoft.OneConnect",
        "Microsoft.People",
        "Microsoft.Print3D",
        "Microsoft.Reader",
        "Microsoft.RemoteDesktop",
        "Microsoft.SkypeApp",
        "Microsoft.Todos",
        "Microsoft.Wallet",
        "Microsoft.WebMediaExtensions",
        "Microsoft.Whiteboard",
        "Microsoft.WindowsAlarms",
        "Microsoft.windowscommunicationsapps",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsReadingList",
        "Microsoft.WindowsScan",
        # "Microsoft.Windows.Photos",
        # "Microsoft.WindowsSoundRecorder",
        # "Microsoft.WindowsCamera",
        # "Microsoft.WindowsMaps",
        "Microsoft.WindowsPhone",
        "Microsoft.WinJS.1.0",
        "Microsoft.WinJS.2.0",
        "Microsoft.YourPhone",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "Microsoft.Advertising.Xaml",
        "*Disney*",
        "*Tiktok*",
        "2414FC7A.Viber",
        "41038Axilesoft.ACGMediaPlayer",
        "46928bounde.EclipseManager",
        "4DF9E0F8.Netflix",
        "64885BlueEdge.OneCalendar",
        "7EE7776C.LinkedInforWindows",
        "828B5831.HiddenCityMysteryofShadows",
        "89006A2E.AutodeskSketchBook",
        "9E2F88E3.Twitter",
        "A278AB0D.DisneyMagicKingdoms",
        "A278AB0D.DragonManiaLegends",
        "A278AB0D.MarchofEmpires",
        "ActiproSoftwareLLC.562882FEEB491",
        "AD2F1837.GettingStartedwithWindows8",
        "AD2F1837.HPJumpStart",
        "AD2F1837.HPRegistration",
        "AdobeSystemsIncorporated.AdobePhotoshopExpress",
        "Amazon.com.Amazon",
        "AmazonVideo.PrimeVideo",
        "C27EB4BA.DropboxOEM",
        "CAF9E577.Plex",
        "CyberLinkCorp.hs.PowerMediaPlayer14forHPConsumerPC",
        "D52A8D61.FarmVille2CountryEscape",
        "D5EA27B7.Duolingo-LearnLanguagesforFree",
        "DB6EA5DB.CyberLinkMediaSuiteEssentials",
        "DolbyLaboratories.DolbyAccess",
        "Drawboard.DrawboardPDF",
        "*Facebook*",
        "*LinkedIn*",
        "*Instagram*",
        "*MarchofEmpires*",
        "Fitbit.FitbitCoach",
        "flaregamesGmbH.RoyalRevolt2",
        "GAMELOFTSA.Asphalt8Airborne",
        "KeeperSecurityInc.Keeper",

        # BubbleWitch3Saga, CandyCrushFriends, CandyCrushSaga, CandyCrushSodaSaga, FarmHeroesSaga
        "*king.com*",
        "Nordcurrent.CookingFever",
        "PandoraMediaInc.29680B314EFC2",
        "PricelinePartnerNetwork.Booking.comBigsavingsonhot",
        "SpotifyAB.SpotifyMusic",
        "ThumbmunkeysLtd.PhototasticCollage",
        "WinZipComputing.WinZipUniversal",
        "XINGAG.XING"
    )
    foreach ($pkg in $packages) {
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $pkg } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
        Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $pkg } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Out-Null
    }
}

# Removes OneDrive.
function RemoveOneDrive {
    taskkill.exe /F /IM "OneDrive.exe" 2>&1 | Out-Null
    taskkill.exe /F /IM "explorer.exe" 2>&1 | Out-Null
    Start-Sleep -Seconds 2

    $setup = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
    if (!(Test-Path $setup)) {
        $setup = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    }
    if (Test-Path $setup) {
        Start-Process $setup "/uninstall" -Wait -NoNewWindow
    }

    $paths = @(
        "$userProfile\OneDrive",
        "$userAppData\Microsoft\OneDrive",
        "$env:PROGRAMDATA\Microsoft OneDrive",
        "$env:SYSTEMDRIVE\OneDriveTemp"
    )

    foreach ($p in $paths) {
        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
    }

    Remove-Item -Path "$userProfile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -ErrorAction SilentlyContinue | Out-Null

    $path = EnsurePath("Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder");
    Set-ItemProperty -Path $path -Name Attributes -Value 0 -Type DWord -ErrorAction SilentlyContinue
    $path = EnsurePath("Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder");
    Set-ItemProperty -Path $path -Name Attributes -Value 0 -Type DWord -ErrorAction SilentlyContinue

    Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like "*OneDrive*" } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    Start-Process "explorer.exe"
}

# Adobe Acrobat Reader
function AcrobatReader {
    param([string]$Path)

    $process = Start-Process -FilePath "$Path\adobereader.exe" -ArgumentList "/sAll /rs /msi EULA_ACCEPT=YES DISABLEDESKTOPSHORTCUT=1 IW_DEFAULT_VERB=Read LEAVE_PDFOWNERSHIP=NO" -PassThru -Wait

    if (Test-Path "$basePath\pdf-adobereader.msp") {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/update", "$basePath\pdf-adobereader.msp", "/qn /norestart" -PassThru -Wait
    }

    AcrobatReaderRegistry

    # Remove Desktop Shortcut
    Remove-Item -Path "$env:PUBLIC\Desktop\Acrobat Reader 2020.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$userDesktop\Acrobat Reader 2020.lnk" -Force -ErrorAction SilentlyContinue

    # PDF-XChange Editor PDF Previewer Handler
    # https://www.pdf-xchange.com/EditorV10.x64.msi
    if (Test-Path "$basePath\pdf-xchange.msi") {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "$basePath\pdf-xchange.msi", "/qn", "/norestart", "ADDLOCAL=F_ShellExt", "SET_AS_DEFAULT=0" -PassThru -Wait
    }

    return ($process.ExitCode -in @(0, 3010, 1641))
}

function AcrobatReaderRegistry {
    $path = EnsurePath -Path "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Acrobat Reader\2020\FeatureLockDown"
    # Remove Sign In / Sign Out
    Set-ItemProperty -Path $path -Name "bSuppressSignOut" -Type DWord -Value 1
    # Remove Upgrade / Pro purchasing ads
    Set-ItemProperty -Path $path -Name "bAcroSuppressUpsell" -Type DWord -Value 1
    # Remove first opening tips
    Set-ItemProperty -Path $path -Name "bToggleFTE" -Type DWord -Value 1

    $path = EnsurePath -Path "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Acrobat Reader\2020\FeatureLockDown\cServices"
    # Disable Adobe online services
    Set-ItemProperty -Path $path -Name "bUpdater" -Type DWord -Value 0
    # Adobe Document Cloud
    Set-ItemProperty -Path $path -Name "bToggleAdobeDocumentServices" -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name "bToggleDocumentCloud" -Type DWord -Value 1
    # Box, Dropbox, Google Drive, OneDrive
    Set-ItemProperty -Path $path -Name "bToggleWebConnectors" -Type DWord -Value 1

    $path = EnsurePath -Path "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Acrobat Reader\2020\FeatureLockDown\cSharePoint"
    # SharePoint
    Set-ItemProperty -Path $path -Name "bDisableSharePointFeatures" -Type DWord -Value 1
}

# Google Chrome
function GoogleChrome {
    param([string]$Path)

    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "$Path\chrome.msi", "/quiet /norestart" -PassThru -Wait

    # Policies
    $path = EnsurePath("Registry::HKEY_USERS\$userId\SOFTWARE\Policies\Google\Chrome");
    New-ItemProperty -Path $path -Name "MemorySaverModeSavings" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $path -Name "TranslateEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $path -Name "BackgroundModeEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $path -Name "BookmarkBarEnabled" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $path -Name "SearchSuggestEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $path -Name "DefaultNotificationsSetting" -Value 2 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $path -Name "MetricsReportingEnabled" -Value 2 -PropertyType DWord -Force | Out-Null

    # Adguard Extension
    # https://chromewebstore.google.com/detail/adguard-adblocker/bgnkhhnnamicmpeenaelnjfhikgbkllg
    $path = EnsurePath("HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist");
    New-ItemProperty -Path $path -Name "1" -Value "bgnkhhnnamicmpeenaelnjfhikgbkllg;https://clients2.google.com/service/update2/crx" -PropertyType String -Force | Out-Null

    # Create First Run
    New-Item -Path "C:\Users\$userName\AppData\Local\Google\Chrome\User Data" -Name "First Run" -Force | Out-Null

    return ($process.ExitCode -in @(0, 3010, 1641))
}

# MPC-BE Codec
function MPCBE {
    param([string]$Path)

    $process = Start-Process -FilePath "$Path\mpc-be.exe" -ArgumentList '/verysilent /suppressmsgboxes /norestart /sp- /mergetasks="!desktopicon"' -PassThru -Wait
    Start-Process "$env:ProgramFiles\MPC-BE\mpc-be64.exe" -ArgumentList "/regvid" -Wait

    return ($process.ExitCode -in @(0, 3010, 1641))
}

# WinRAR
function WinRAR {
    param([string]$Path)

    $process = Start-Process -FilePath "$Path\winrar.exe" -ArgumentList "/S" -PassThru -Wait

    return ($process.ExitCode -in @(0, 3010, 1641))
}

# 7zip
function 7zip {
    param([string]$Path)

    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "$Path\7zip.msi", "/qn /norestart" -PassThru -Wait

    return ($process.ExitCode -in @(0, 3010, 1641))
}
