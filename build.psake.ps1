
Properties {
    [bool]$BuildFromServer
}


#Generate work variable
$Script:rootPath = split-path -parent $MyInvocation.MyCommand.Definition
$Script:ModuleName = "EdmoBuildTools"
$manifestPath = "$Script:rootPath\src\$Script:ModuleName.psd1"


Task default -Depends CleanOldPsModule

Task RunTests -ErrorAction Stop {
    
    Import-Module Pester
   
    # Run the Pester Test
    $testResults = Invoke-Pester "$Script:rootPath\tests\main.pester.ps1" -PassThru
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
    [version]$script:latestVersion = (Test-ModuleManifest $manifestPath).Version
    Write-Output "New version is $script:latestVersion"
   
}

Task Publish -depends IncrementVersion -ErrorAction Stop {

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
        $moduleFiles = Get-ChildItem -Path "$Script:rootPath\src"
        foreach ($file in $moduleFiles) {
            Copy-Item -Path $file.FullName -Destination $modulePath
        }

        #Show latest installed version
        Get-Module EdmoBuildTools -ListAvailable | Select-Object Version

    }

}

Task CleanOldPsModule -depends Publish -ErrorAction Stop {
    $modulePath = "C:\Program Files\WindowsPowerShell\Modules\$Script:ModuleName\"
    $modules = (Get-ChildItem $modulePath | Sort-Object CreationTime -Descending)
   
    # Only keep last 5 version
    for($i = 5; $i -lt $modules.Count; $i++) {
      Remove-Item -Recurse  $modules[$i].FullName
    }

   
}



