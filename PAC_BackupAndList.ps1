$CurDate = Get-Date
$BackupLabel = "PAC_CLI_$($CurDate.ToString("MM-dd-yyyy-hhmmss"))"

. .\PAC_ConnectAppUser.ps1

# Connect PAC CLI

$CredFilePath = Resolve-Path .\MSPP-Automation-App-Account1.txt

$Params = [ordered]@{
    ApplicationID ="af89894e-e9ac-495b-b120-476fc370e7cf"
    TenantID = "b5976420-83ee-4ae8-b567-aa3d16095d7a"
    ClientSecret = $(Import-Clixml -Path $CredFilePath).GetNetworkcredential().password
    ConnectionName = "PowerFxHelpDev"
    EnvironmentURL =  "https://org403dacb8.crm.dynamics.com/"
}

Connect-PACCLIAppUser @Params

# Take Backup

pac admin backup --environment $params.EnvironmentURL --label $BackupLabel

# List Backups

pac admin list-backups --environment $params.EnvironmentURL