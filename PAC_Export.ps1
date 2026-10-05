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
