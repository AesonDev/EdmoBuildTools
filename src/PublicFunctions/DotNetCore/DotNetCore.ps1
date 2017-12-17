
function Get-LocalDotNetCoreVersion {
    $exe = (Get-Command dotnet)
    $version = $exe.Version
    return  $version
}
function Get-NextVersion {
    param(
        [string]$VersionSpecLocation
    )

    Push-Location $VersionSpecLocation
    if (Test-Path .\VersionSpec.json) {
        
        #Get the current version from VersionSpec
        $currentVersion = Get-Content .\VersionSpec.json | ConvertFrom-Json       
         Write-Host "Current version = $currentVersion"
        if ($newVersion.Branche -ne "Master") {
           #If the build does not comes from the Master Branche then add the branche name with the build version
           #Every branche has his own incrementation
           $newVersion = $currentVersion
           $newVersion.Build = $currentVersion.Build + 1           
           $strBuild = ""
           $strBuild += $newVersion.Branche
           $strBuild += "-Build"
           $strBuild += $newVersion.Build 
           $strNewVersion = "{0}.{1}.{2}.{3}" -f $newVersion.Major, $newVersion.Minor, $newVersion.Patch, $strBuild 
           $newVersion | Convertto-Json |  Out-File .\VersionSpec.json
            
        }else{
           #If the build comes from the Master branche then only Major,Minor and Patch are in the version
           #Build version are never incremented in the Master Branche. Master Branche = Release Branche
           #Chenge to the verion (Major, Minor or Patch are made manually depending if the work done. 
           $strNewVersion = "{0}.{1}.{2}" -f $currentVersion.Major, $currentVersion.Minor, $currentVersion.Patch
        }   
        Pop-Location
        return $strNewVersion
    }
    else {
        Write-Host "No VersionSpec found in $VersionSpecLocation"
        Pop-Location
        return
    }
  
}

function New-DotNetCoreBuild {
    param (
        [string]$Location,
        [string]$Configuration,
        [bool]$IncludeDependentProjects = $true,
        [bool]$RestorePackages = $true
    )
   
    $dotnetExe = (get-command dotnet).Source
   
    $Projects = Get-ChildItem -Path $Location -Recurse -Filter "*.csproj" -Exclude "*test*"
    foreach ($Project in $Projects) {
        $path = $Project.Directory
        $newVersion = Get-NextVersion -VersionSpecLocation $path
        Write-Output "New version $newVersion"
        Write-Output "Building $Project in $path"

        Push-Location $path -Verbose
        #TODO https://blogs.msdn.microsoft.com/sonam_rastogi_blogs/2014/05/14/update-xml-file-using-powershell/
        $args = ""
       # if ($newVersion) {
            #Version is passed as MsBuild parameter and will be set in the .csproj and on the assembly by the .Net Core Cli
           
        #}
        if ($Configuration) {
            $args += " -c $Configuration"
        }
        if ($IncludeDependentProjects -eq $false) {
            $args += " --no-dependencies "
        }
        if ($RestorePackages -eq $false) {
            $args += " --no-restore "
        }
        $args += " --force "
       
        Write-Output "dotnet build $args"
    
        exec {
            & dotnet.exe build /p:BuildNumber='188' "$args"
        }

        Pop-Location
    }
    
   
  
}

function Start-UnitTests {
    param (
        [string]$Location,
        [string]$Configuration,
        [bool]$Build = $false,
        [bool]$Restore = $false       
    )

    $dotnetExe = (get-command dotnet).Source

    $TestProjects = Get-ChildItem -Path $Location -Recurse -Filter "*.csproj"

    if ($TestProjects.Count -eq 0) {
        Write-Output " NO TEST FOUND !!!!!!!"
    }

    foreach ($Project in $TestProjects) {
        $path = $Project.Directory
        Write-Output "Testing $Project"
        Push-Location $path   
        $args = ""
        if ($Configuration) {
            $args += " -c $Configuration"
        }
        if ($Build -eq $false) {
            $args += " --no-build "
        } 
        if ($Restore -eq $false) {
            $args += " --no-restore "
        }  

        $args += "--verbosity detailed"
    
        Write-Output "dotnet test  $args"    
        exec {
            & $dotnetExe test "$args"
        }
        Pop-Location
    }

   
}

function Test-DotNetCoreFunctionsAreLoaded {
    return "ok"
}

