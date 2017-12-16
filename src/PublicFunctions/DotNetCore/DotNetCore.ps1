
function Get-LocalDotNetCoreVersion {
    $exe = (Get-Command dotnet)
    $version = $exe.Version
    return  $version
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
        Write-Output "Building $Project"
        Push-Location $path
        $args = ""
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
        [string]$Configuration       
    )

    $dotnetExe = (get-command dotnet).Source

    $TestProjects = Get-ChildItem -Path $Location -Filter "*.csproj"
    foreach ($Project in $TestProjects) {
        $path = $Project.Directory
        Write-Output "Testing $Project"
        Push-Location $path   
        $args = ""
        if ($Configuration) {
            $args += " -c $Configuration"
        }   
    
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

