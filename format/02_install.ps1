# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting access"
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

. "$PSScriptRoot\..\ventoy\functions.ps1"

InitializeUserContext

# Applications list
$apps = @(
    [PSCustomObject]@{ name = "Adobe Reader"; func = "AcrobatReader" },
    [PSCustomObject]@{ name = "Google Chrome"; func = "GoogleChrome" },
    [PSCustomObject]@{ name = "MPC-BE Codec"; func = "MPCBE" },
    [PSCustomObject]@{ name = "WinRAR"; func = "WinRAR" },
    [PSCustomObject]@{ name = "7Zip"; func = "7Zip" }
)

# Create form
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.Text = "Application Installer"
$form.Size = New-Object System.Drawing.Size(400, 365)
$form.StartPosition = "CenterScreen"

# Checkbox list (all selected)
$checkedListBox = New-Object System.Windows.Forms.CheckedListBox
$checkedListBox.Location = New-Object System.Drawing.Point(15, 40)
$checkedListBox.Size = New-Object System.Drawing.Size(355, 255)
$checkedListBox.CheckOnClick = $true

foreach ($app in $apps) {
    $item = [PSCustomObject]@{
        name = $app.name
        func = $app.func
    }

    $item | Add-Member -MemberType ScriptMethod -Name "ToString" -Value { return $this.name } -Force
    $state = [System.Windows.Forms.CheckState]::Unchecked
    $checkedListBox.Items.Add($item, $state) | Out-Null
}
$form.Controls.Add($checkedListBox)

# Install button
$btnOK = New-Object System.Windows.Forms.Button
$btnOK.Text = "Install Selected Applications"
$btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
$btnOK.Location = New-Object System.Drawing.Point(15, 290)
$btnOK.Size = New-Object System.Drawing.Size(355, 25)
$form.AcceptButton = $btnOK
$form.Controls.Add($btnOK)

# Select/Unselect button
$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Select/Unselect All"
$btnSelectAll.Size = New-Object System.Drawing.Size(355, 25)
$btnSelectAll.Location = New-Object System.Drawing.Point(15, 10)
$form.Controls.Add($btnSelectAll)

$global:allChecked = $true
$btnSelectAll.Add_Click({
        # Check toggle
        $newStatus = if ($global:allChecked) { $false } else { $true }
        for ($i = 0; $i -lt $checkedListBox.Items.Count; $i++) {
            $checkedListBox.SetItemChecked($i, $newStatus)
        }
        $global:allChecked = -not $global:allChecked
    })

# Close form
$global:close = $false
$form.Add_FormClosing({
        param($s, $e)

        if ($e.CloseReason -eq "UserClosing") {
            if ($result -eq "No") {
                $e.Cancel = $true
                $global:close = $false
            }
            else {
                $global:close = $true
            }
        }
    })

# Show form
if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $apps = $checkedListBox.CheckedItems

    if ($apps.Count -eq 0) {
        pause
        exit 1
    }

    foreach ($app in $apps) {
        if (-not (Get-Command $app.func -ErrorAction SilentlyContinue)) {
            continue
        }

        $maxAttempts = 3
        $success = $false

        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            try {
                # Call application install function from app.func
                Write-Host "Installing $($app.name)"
                & $app.func -Path $PSScriptRoot | Out-Null
                Start-Sleep -Seconds 2
                $success = $true
                break
            }
            catch {
                Write-Host "Attempt ($attempt/$maxAttempts) failed: $($_.Exception.Message)"
                if ($attempt -lt $maxAttempts) {
                    Start-Sleep -Seconds 5
                }
            }
        }

        if (-not $success) {
            Write-Host "$($app.name) installation failed after $maxAttempts attempts."
        }
    }
}

if ($global:close -eq $false) {
    Write-Host -ForegroundColor Yellow "Reboot system [ENTER] or any other key to Exit"
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    if ($key.VirtualKeyCode -eq 13) {
        shutdown -r -t 3
    }
    else {
        exit 1
    }
}