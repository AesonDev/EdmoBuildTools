
function Get-LocalDotNetCoreVersion{
  $exe = (Get-Command dotnet)
  $version = $exe.Version
  return  $version
}

function Test-DotNetCoreFunctionsAreLoaded {
  return "ok"
}

