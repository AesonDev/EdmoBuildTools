Enum BuildType {
    XunitTest   
}

function Get-Test {
    param(
        [BuildType]$BuildType
    )   
    return "ok"
}



Export-ModuleMember Get-Test

