# Switch-CellularTech.ps1 — network technology switcher (CLI)
# Usage:
#   .\Switch-CellularTech.ps1 status   - show current technology (read-only)
#   .\Switch-CellularTech.ps1 3g       - prefer HSPA+/3G (disables LTE)   [brief disconnect]
#   .\Switch-CellularTech.ps1 lte      - prefer LTE/4G (restores default) [brief disconnect]
param(
    [Parameter(Position=0)]
    [ValidateSet('status','3g','lte')]
    [string]$Mode = 'status'
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\MbnInterop.ps1"

switch ($Mode) {
    'status' { [MbnApi.MbnTool]::Status() }
    '3g'     { [MbnApi.MbnTool]::Switch($true) }
    'lte'    { [MbnApi.MbnTool]::Switch($false) }
}
