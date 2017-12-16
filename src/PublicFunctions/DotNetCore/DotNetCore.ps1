
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
         
        if ($newVersion.Branche -ne "Master") {
           #If the build does not comes from the Master Branche then add the branche name with the build version
           #Every branche has his own incrementation
           $newVersion.build = $currentVersion.build + 1
           $strBuild = ""
           $strBuild += $newVersion.Branche
           $strBuild += "-Build"
           $strBuild += $newVersion.Build 
           $strNewVersion = "{0}.{1}.{2}.{3}" -f $newVersion.Major, $newVersion.Minor, $newVersion.Patch, $strBuild 
            
        }else{
           #If the build comes from the Master branche then only Major,Minor and Patch are in the version
           #Build version are never incremented in the Master Branche. Master Branche = Release Branche
           #Chenge to the verion (Major, Minor or Patch are made manually depending if the work done. 
           $strNewVersion = "{0}.{1}.{2}" -f $currentVersion.Major, $currentVersion.Minor, $currentVersion.Patch
        }   
        Pop-Location
        return $version
    }
    else {
        Pop-Location
        Throw "VersionSpec.json not found"
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
   
    $TestProjects = Get-ChildItem -Path $Location -Recurse -Filter "*.csproj"
    foreach ($Project in $TestProjects) {
        $path = $Project.Directory
        $newVersion = Get-NextVersion -VersionSpecLocation $path
        Write-Output "Building $Project"
        Push-Location $path
        #Version is passed as MsBuild parameter and will be set in the .csproj and on the assembly by the .Net Core Cli
        $args = " /p:SemVer=$newVersion "
        if ($Configuration) {
            $args += " -c $Configuration"
        }
        if ($IncludeDependentProjects -eq $false) {
            $args += " --no-dependencies "
        }
        if ($RestorePackages -eq $false) {
            $args += " --no-restore "
        }

        Write-Output "dotnet build $args"
    
        exec {
            & $dotnetExe build "$args"
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

