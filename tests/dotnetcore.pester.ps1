
Import-Module .\src\EdmoBuildTools.psd1


Describe "DotNet Core exec" {
    It "Get installed version should not throw" {
         { Get-LocalDotNetCoreVersion } | Should Not Throw         
    }
    It "Get installed version should return the good version" {
        $exe = (Get-Command dotnet)
        $version = $exe.Version
        Write-Host "installed dotnet.exe version is $version"
        Get-LocalDotNetCoreVersion | Should Be $version 
    }
}
