<#

.SYNOPSIS

Use Script to bulk export a list of Solutions using PAC ClI for backup purposes

#>

$SolutionsList = Import-Csv (Join-Path $PSScriptRoot "Inputs\SolutionNames.csv")
$total = $SolutionsList.Count
$i = 0

. (Join-Path $PSScriptRoot "PAC_Export.ps1")

# Each solution is exported into its own subfolder under this path
$ExportPath = "D:\Documents\Projects\MSPP-Solutions"

Foreach ($Solution in $SolutionsList){

    $i++

    $SolutionName  = $Solution.SolutionName

        Write-Progress `
            -Activity "Processing Items" `
            -Status "Processing $($SolutionName) $i of $total" `
            -PercentComplete (($i / $total) * 100)

    $Params = @{
        ExportPath = $(Join-Path $ExportPath -ChildPath $SolutionName)
        SolutionName = $SolutionName
        ConnectionName = "PowerFxHelpDev"
        EnvironmentURL =  "https://org403dacb8.crm.dynamics.com/"
        UseSettingsFile = $true
    }

    Export-PowerPlatformSolution @Params


}