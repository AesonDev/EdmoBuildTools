
function Get-Test {
   
    return "ok"
}

# DotSource all Private .ps1 file
# DotSource all Private .ps1 file
$PublicFunctions = Join-Path -Path $PSScriptRoot -ChildPath 'PrivateFunctions' -Resolve
Get-ChildItem -Recurse -Path $PublicFunctions -Filter '*.ps1' | ForEach-Object { . $_.FullName | Out-Null }

# DotSource all Private .ps1 file
$PublicFunctions = Join-Path -Path $PSScriptRoot -ChildPath 'PublicFunctions' -Resolve
Get-ChildItem -Recurse -Path $PublicFunctions -Filter '*.ps1' | ForEach-Object { . $_.FullName | Out-Null }

#Export Module member from the .psd1 file (these are the functions exposed by the PSModule)
$module = Test-ModuleManifest -Path (Join-Path -Path $PSScriptRoot -ChildPath 'EdmoBuildTools.psd1' -Resolve)
Export-ModuleMember -Alias '*' -Function ([string[]]$module.ExportedFunctions.Keys)

