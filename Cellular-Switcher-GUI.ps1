# Cellular-Switcher-GUI.ps1 — simple WinForms GUI for the cellular technology switcher
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
. "$PSScriptRoot\MbnInterop.ps1"

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Cellular Technology Switcher'
$form.Size = New-Object System.Drawing.Size(580, 430)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$statusBtn = New-Object System.Windows.Forms.Button
$statusBtn.Text = 'Status'
$statusBtn.Location = New-Object System.Drawing.Point(20, 20)
$statusBtn.Size = New-Object System.Drawing.Size(160, 35)

$btn3g = New-Object System.Windows.Forms.Button
$btn3g.Text = 'Switch to 3G+ (HSPA+)'
$btn3g.Location = New-Object System.Drawing.Point(200, 20)
$btn3g.Size = New-Object System.Drawing.Size(180, 35)

$btnLte = New-Object System.Windows.Forms.Button
$btnLte.Text = 'Back to LTE / 4G'
$btnLte.Location = New-Object System.Drawing.Point(380, 20)
$btnLte.Size = New-Object System.Drawing.Size(160, 35)

$out = New-Object System.Windows.Forms.TextBox
$out.Multiline = $true
$out.ReadOnly = $true
$out.ScrollBars = 'Vertical'
$out.Font = New-Object System.Drawing.Font('Consolas', 9)
$out.Location = New-Object System.Drawing.Point(20, 70)
$out.Size = New-Object System.Drawing.Size(520, 300)

function Set-Busy($busy) {
    $statusBtn.Enabled = -not $busy
    $btn3g.Enabled = -not $busy
    $btnLte.Enabled = -not $busy
}

$statusBtn.Add_Click({
    try { $out.Text = [MbnApi.MbnTool]::Status() }
    catch { $out.Text = "ERROR: $($_.Exception.Message)" }
})

$btn3g.Add_Click({
    $out.AppendText("Switching to 3G+ ... internet will blip for about 20 seconds.`r`n")
    Set-Busy $true
    [MbnApi.MbnTool]::BeginSwitch($true)
    $script:pending = $true
})

$btnLte.Add_Click({
    $out.AppendText("Switching back to LTE/4G ... internet will blip for about 20 seconds.`r`n")
    Set-Busy $true
    [MbnApi.MbnTool]::BeginSwitch($false)
    $script:pending = $true
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500
$timer.Add_Tick({
    if ($script:pending) {
        $r = [MbnApi.MbnTool]::PollSwitchResult()
        if ($null -ne $r) {
            $out.AppendText($r + "`r`n")
            Set-Busy $false
            $script:pending = $false
        }
    }
})
$timer.Start()

$form.Controls.AddRange(@($statusBtn, $btn3g, $btnLte, $out))
[void]$form.ShowDialog()
