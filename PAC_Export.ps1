function Export-PowerPlatformSolution {
    [CmdletBinding()]
    param (
        [string]$ExportPath,
        [string]$SolutionName,
        [string]$ConnectionName,
        [string]$EnvironmentURL,
        [bool]$UseSettingsFile
    )

    begin {
        $ErrorActionPreference = "STOP"
    }

    process {

        $UnmangedPath = Join-Path -Path $ExportPath -ChildPath "$($SolutionName)_unmanaged.zip"
        $ManagedPath = Join-Path -Path $ExportPath -ChildPath "$($SolutionName)_managed.zip"

        $SettingsFileName = Join-Path -Path $ExportPath -ChildPath "$($SolutionName)_settings.json"

        $ExportPathExists = Test-Path $ExportPath
        $ExistingSettingsFile = Test-Path $SettingsFileName

        if (!$ExportPathExists) {
            New-Item -Type Directory -Path $ExportPath
        }

        if ($ExistingSettingsFile) {
            $userResponse = Read-Host "The settings file already exists for $($SolutionName). Do you want to override it? (Y/N)"
            if ($userResponse -eq 'Y' -or $userResponse -eq 'y') {
                $OverrideSettingFile = $true
            } else {
                $OverrideSettingFile = $false
            }
        }

        # Connection

       # pac auth create --name $ConnectionName --environment $EnvironmentURL

        # List Solutions

        $Solutions = pac solution list --json | ConvertFrom-Json

        $FilteredSolutions = $Solutions | Where-Object {$_.SolutionUniqueName -eq $SolutionName}

        $Version  = $FilteredSolutions.VersionNumber.Replace(".","_")

        If($FilteredSolutions){

        Write-Host "Found Solution $($SolutionName) in environment"

        # Export
        pac solution export --name $SolutionName --path $ManagedPath --managed --overwrite
        pac solution export --name $SolutionName --path $UnmangedPath --managed false --overwrite

        # Settings File (create when missing, or replace when the user agreed to override)
        if ($UseSettingsFile -and (!$ExistingSettingsFile -or $OverrideSettingFile)) {
            if ($ExistingSettingsFile) { Remove-Item $SettingsFileName }
            pac solution create-settings --solution-zip $ManagedPath --settings-file $SettingsFileName
        }

        # Rename files to append the version number onto them

        $Files = Get-ChildItem -Path $ExportPath -File -Filter "*.zip"

        $Files | ForEach-Object {

            $NewFileName = $_.BaseName + "_" + $Version + $_.Extension

          Rename-Item $_.FullName -NewName $NewFileName

        }

        } else {

            Write-Error "Solution Name $($SolutionName) not found"

        }


    }
}

$SolutionName = "EisenhowerMatrix"
$ExportPath = "D:\Documents\Projects\EisenhowerMatrix"
$SolutionUnpackExportPath = "$ExportPath\solution"
$UnmanagedZip = Join-Path $ExportPath "$($SolutionName).zip"
$ManagedZip   = Join-Path $ExportPath "$($SolutionName)_managed.zip"
$SettingsFile = Join-Path $ExportPath "$($SolutionName)_settings.json"

pac solution export --name $SolutionName --path $UnmanagedZip --overwrite
pac solution export --name $SolutionName --path $ManagedZip --managed --overwrite

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

 pac solution pack --zipfile "$ExportPath\EisenhowerMatrix.zip" --folder "$ExportPath"

 pac solution import --path "$ExportPath\EisenhowerMatrix.zip" --publish-changes

 pac solution pack --zipfile "$ExportPath\PokemonEncyclopedia.zip" --folder "$ExportPath"

 pac solution import --path "$ExportPath\PokemonEncyclopedia.zip" --publish-changes