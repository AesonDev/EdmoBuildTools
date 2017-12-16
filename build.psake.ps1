
Properties {
    [bool]$BuildFromServer
}


#Generate work variable
$Script:rootPath = split-path -parent $MyInvocation.MyCommand.Definition
$Script:ModuleName = "EdmoBuildTools"
$manifestPath = "$Script:rootPath\src\$Script:ModuleName.psd1"


Task default -Depends Publish

Task RunTests -ErrorAction Stop {
    
    Import-Module Pester
   
    #Get all test files
    $testFolderPath = "$Script:rootPath\tests\"
    $testsFiles = Get-ChildItem -Path $testFolderPath -Filter "*.pester.ps1"

     
    # Run the Pester Test
    foreach ($testsFile in $testsFiles) {
        $testFileName = $testsFile.FullName
        $testResults = Invoke-Pester $testFileName -PassThru -Verbose
        if ($testResults.FailedCount -gt 0) {
            $testResults | Format-List
            Write-Error -Message "$testFileName tests failed. Build cannot continue !"
        }  
    }
    
    
}

Task IncrementVersion -depends RunTests -ErrorAction Stop {
    #Get current version and build number
    [version]$currentVersion = (Test-ModuleManifest $manifestPath).Version
    Write-Output "Current version is $currentVersion"
    $currentBuild = $currentVersion.Build
    
    #DotSource the versionSpec to get th version from the versionSpecValue object
    . "$rootPath\VersionSpec.ps1"

    #Increment version and update module manifest
    $newBuild = $currentBuild += 1 
    $newVersion = [version]::new($versionSpecValue.Major, $versionSpecValue.Minor, $newBuild)
    Update-ModuleManifest -ModuleVersion $newVersion -Path $manifestPath 
   
    #Show updated version
    [version]$script:latestVersion = (Test-ModuleManifest $manifestPath).Version
    Write-Output "New version is $script:latestVersion"
   
}

Task CleanOldPsModule -depends IncrementVersion -ErrorAction Stop {
    $modulePath = "C:\Program Files\WindowsPowerShell\Modules\$Script:ModuleName\"
    Remove-Item $modulePath   -Force -Recurse
}

Task Publish -depends CleanOldPsModule -ErrorAction Stop {

    if ($BuildFromServer) {
        Write-Output "Building from build server"
        $apiKey = '4d7779f0-8c1b-4df3-a863-1e755654888f'
        Register-PSRepository -Name Proget -PublishLocation http://proget/nuget/Powershell-DVL/ -SourceLocation http://proget/nuget/Powershell-DVL/ -InstallationPolicy Trusted  -ErrorAction Ignore
      
        # Import-Module  "$rootPath\src\EdmoBuildTools.psd1"
        ## TODO bug in Nuget Provider ? BadRequest when publishing to Proget (Linux Version)
        Publish-Module -Path "C:\Users\gaetan.AESONDEV\Projects\Edmo\EdmoBuildTools\EdmoBuildTools\"  -NuGetApiKey $apiKey -Repository Proget -Verbose -Confirm:$false
   
    }
    else {
        Write-Output "Publishing to local Dev Workstation"
        $version = $script:latestVersion.ToString()

        #Create the local folder where to put the PSModule
        $modulePath = "C:\Program Files\WindowsPowerShell\Modules\$Script:ModuleName\$version"
        New-Item -ItemType Directory -Path $modulePath -Force
        
        #Copy the module files
        $moduleFiles = Get-ChildItem  -Path "$Script:rootPath\src"
        foreach ($file in $moduleFiles) {
            Copy-Item -Path $file.FullName -Destination $modulePath -Recurse
        }

        #Show latest installed version
        Get-Module EdmoBuildTools -ListAvailable | Select-Object Version

    }

}





