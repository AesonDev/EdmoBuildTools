param (
    [bool]$BuildFromServer = $false
)

Write-Output "Executing Run.ps1"
Invoke-PSake build.psake.ps1 -parameters @{"BuildFromServer" = $BuildFromServer}