# Connect PAC CLI

. .\PAC_ConnectAppUser.ps1

$CredFilePath = Resolve-Path .\MSPP-Automation-App-Account1.txt

$Params = [ordered]@{
    ApplicationID ="af89894e-e9ac-495b-b120-476fc370e7cf"
    TenantID = "b5976420-83ee-4ae8-b567-aa3d16095d7a"
    ClientSecret = $(Import-Clixml -Path $CredFilePath).GetNetworkcredential().password
    ConnectionName = "PowerFxHelpDev"
    EnvironmentURL =  "https://org403dacb8.crm.dynamics.com/"
}

Connect-PACCLIAppUser @Params

# Change Solution Name and Export Paths as needed

$SolutionName = "EisenhowerMatrix"
$ExportPath = "D:\Documents\Projects\EisenhowerMatrix"
$SolutionUnpackExportPath = "$ExportPath\solution"

$SettingsFile = Join-Path $ExportPath "$($SolutionName)_settings.json"

# Find the solution in the connected environment
$Solutions = pac solution list --json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw "Could not list solutions in the connected environment" }

$FilteredSolutions = $Solutions | Where-Object { $_.SolutionUniqueName -eq $SolutionName } | Select-Object -First 1

if (-not $FilteredSolutions) {
    throw "Solution $($SolutionName) not found in the connected environment"
}

Write-Host "Found Solution $($SolutionName) version $($FilteredSolutions.VersionNumber) in environment"

# Zip names include the version, e.g. EisenhowerMatrix_1_0_0_1.zip / EisenhowerMatrix_1_0_0_1_managed.zip
$Version      = $FilteredSolutions.VersionNumber.Replace(".", "_")
$UnmanagedZip = Join-Path $ExportPath "$($SolutionName)_$($Version).zip"
$ManagedZip   = Join-Path $ExportPath "$($SolutionName)_$($Version)_managed.zip"

pac solution export --name $SolutionName --path $UnmanagedZip --overwrite
if ($LASTEXITCODE -ne 0) { throw "Unmanaged export of $($SolutionName) failed" }

pac solution export --name $SolutionName --path $ManagedZip --managed --overwrite
if ($LASTEXITCODE -ne 0) { throw "Managed export of $($SolutionName) failed" }

# Deployment settings (environment variables + connection references) from the managed zip
$CreateSettingsFile = $true
if (Test-Path $SettingsFile) {
    $userResponse = Read-Host "The settings file already exists for $($SolutionName). Do you want to override it? (Y/N)"
    $CreateSettingsFile = $userResponse -eq 'Y' -or $userResponse -eq 'y'
}

if ($CreateSettingsFile) {
    if (Test-Path $SettingsFile) { Remove-Item $SettingsFile }
    pac solution create-settings --solution-zip $ManagedZip --settings-file $SettingsFile
} else {
    Write-Host "Keeping existing settings file: $SettingsFile"
}

# Unpack the unmanaged zip into .\solution
#   --allowDelete removes files from .\solution that are no longer in the solution
#   --processCanvasApps expands the .msapp into source files so app changes show as diffs in git
pac solution unpack --zipfile $UnmanagedZip --folder $SolutionUnpackExportPath --packagetype Unmanaged --allowWrite true --allowDelete true --processCanvasApps true