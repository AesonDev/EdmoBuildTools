#Generate work variable
$currenttPath = split-path -parent $MyInvocation.MyCommand.Definition
$rootPath = Split-Path -Parent $currenttPath
$manifestPath = "$rootPath\src\EdmoBuildTools.psd1"

Import-Module .\src\EdmoBuildTools.psd1

Describe "Manifest" {
    It "Module manifest is valid" {        
        { Test-ModuleManifest $manifestPath } |  Should Not Throw
    }
}

Describe "Unit tests" {
    It "Get-Test result should be ok" {
        Get-Test | Should Be "ok"
    }
   
}
