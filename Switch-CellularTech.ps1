# Switch-CellularTech.ps1 — network technology switcher (CLI)
# Usage:
#   .\Switch-CellularTech.ps1 status   - show current technology (read-only)
#   .\Switch-CellularTech.ps1 3g       - prefer HSPA+/3G (disables LTE)   [brief disconnect]
#   .\Switch-CellularTech.ps1 lte      - prefer LTE/4G (restores default) [brief disconnect]
#   .\Switch-CellularTech.ps1 watch    - watchdog: auto-bounce radio when service is lost (e.g. load shedding)
param(
    [Parameter(Position=0)]
    [ValidateSet('status','3g','lte','watch')]
    [string]$Mode = 'status'
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\MbnInterop.ps1"

switch ($Mode) {
    'status' { [MbnApi.MbnTool]::Status() }
    '3g'     { [MbnApi.MbnTool]::Switch($true) }
    'lte'    { [MbnApi.MbnTool]::Switch($false) }
    'watch'  {
        Write-Output ("Watchdog started {0} - checking registration every 60s. Ctrl+C to stop." -f (Get-Date -Format 'HH:mm:ss'))
        while ($true) {
            try {
                $o = [MbnApi.MbnSession]::Open()
                $r = [MbnApi.IMbnRegistration]$o[1]
                [uint32]$regState = 0
                [void]$r.GetRegisterState([ref]$regState)
                $ok = ($regState -eq 3 -or $regState -eq 4 -or $regState -eq 5)  # HOME / ROAMING / PARTNER
                if ($ok) {
                    Write-Output ("{0}  OK  (registered)" -f (Get-Date -Format 'HH:mm:ss'))
                } else {
                    Write-Output ("{0}  NO SERVICE (regState={1}) - bouncing radio..." -f (Get-Date -Format 'HH:mm:ss'), $regState)
                    netsh mbn set powerstate interface="Cellular" state=off | Out-Null
                    Start-Sleep -Seconds 6
                    netsh mbn set powerstate interface="Cellular" state=on | Out-Null
                    Start-Sleep -Seconds 25   # give the modem time to re-camp
                    $o2 = [MbnApi.MbnSession]::Open()
                    $r2 = [MbnApi.IMbnRegistration]$o2[1]
                    [uint32]$after = 0
                    [void]$r2.GetRegisterState([ref]$after)
                    if ($after -eq 3 -or $after -eq 4 -or $after -eq 5) {
                        Write-Output ("{0}  SERVICE RESTORED" -f (Get-Date -Format 'HH:mm:ss'))
                    } else {
                        Write-Output ("{0}  still no service (will retry)" -f (Get-Date -Format 'HH:mm:ss'))
                    }
                }
            } catch {
                Write-Output ("{0}  check failed: {1}" -f (Get-Date -Format 'HH:mm:ss'), $_.Exception.Message)
            }
            Start-Sleep -Seconds 60
        }
    }
}

