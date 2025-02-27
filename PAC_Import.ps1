function Import-PowerPlatformSolution {
    [CmdletBinding()]
    param (
        [string]$SolutionPath,
        [string]$ApplicationID,
        [string]$TenantID,
        [string]$ClientSecret,
        [string]$SettingsFilePath,
        [string]$ConnectionName,
        [string]$EnvironmentURL
    )

    $ErrorActionPreference = "STOP"
    
    $SolutionPathFound = Test-Path $SolutionPath
    $SettingsFileFound = Test-Path $SettingsFilePath
    $SettingsFileResult = If ($SettingsFilePath -and $SettingsFileFound -eq $true) {
        $true
    }
    elseif ($SettingsFileFound -eq $false) {
        Write-Error "$SettingsFilePath not found"
    }
    else {
        $false
    }
    
    if ($SolutionPathFound) {
        pac auth create --name $ConnectionName --environment $EnvironmentURL --applicationid $ApplicationID --tenant $TenantID --clientsecret $ClientSecret

        if ($SettingsFileResult) {
            pac solution import --path $SolutionPath --settings-file $SettingsFilePath --publish-changes
        }
        else {
            pac solution import --path $SolutionPath --publish-changes
        }
    }
    else {
        Write-Error "Couldn't find solution file at $SolutionPath"
        return
    }
}



$ApplicationAccountCreds = Import-Clixml $(Resolve-Path .\MSPP-Automation-App-Account1.txt)

$Params = @{
    ApplicationID ="af89894e-e9ac-495b-b120-476fc370e7cf"
    TenantID = "b5976420-83ee-4ae8-b567-aa3d16095d7a"
    ClientSecret = $ApplicationAccountCreds.getnetworkcredential().password
    SolutionPath      = "C:\Users\Brendan\Desktop\Projects\Date Generator\DateGenerator\DateGenerator_managed.zip"
    SettingsFilePath  = "C:\Users\Brendan\Desktop\Projects\Date Generator\DateGenerator\DateGenerator_settings_TestEnv.json"
    ConnectionName    = "PowerFxHelpTest"
    EnvironmentURL    = "https://orge5f6a53a.crm.dynamics.com//"
}

Import-PowerPlatformSolution @Params
