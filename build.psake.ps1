
#Generate work variable
$rootPath = split-path -parent $MyInvocation.MyCommand.Definition
$manifestPath = "$rootPath\src\EdmoBuildTools.psd1"

Task default -Depends Publish

Task RunTests -ErrorAction Stop {

    Import-Module Pester
   
    # Run the Pester Test
    $testResults = Invoke-Pester "$rootPath\tests\main.pester.ps1" -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue !'
    }  
}

Task IncrementVersion -depends RunTests -ErrorAction Stop {
    #Get current version and build number
    [version]$currentVersion = (Test-ModuleManifest $manifestPath).Version
    Write-Output "Current version is $currentVersion"
    $currentBuild = $currentVersion.Build
   
    #Increment version and update module manifest
    $newBuild = $currentBuild += 1 
    $newVersion = [version]::new($currentVersion.Major, $currentVersion.Minor, $newBuild)
    Update-ModuleManifest -ModuleVersion $newVersion -Path $manifestPath 
   
    #Show updated version
    [version]$latestVersion = (Test-ModuleManifest $manifestPath).Version
    Write-Output "New version is $latestVersion"
   
}

Task Publish -depends IncrementVersion -ErrorAction Stop {
    $apiKey = '4d7779f0-8c1b-4df3-a863-1e755654888f'
    Register-PSRepository -Name Proget -PublishLocation http://proget/nuget/Powershell-DVL/ -SourceLocation http://proget/nuget/Powershell-DVL/ -InstallationPolicy Trusted  -ErrorAction Ignore
   
   # Import-Module  "$rootPath\src\EdmoBuildTools.psd1"

    Publish-Module -Name Pester  -NuGetApiKey $apiKey -Repository Proget -Verbose -Confirm:$false
}



