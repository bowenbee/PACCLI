
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

# List Connections

#pac auth create --name "Testing" --environment $Params.EnvironmentURL
$ConnectionString  = pac connection list

$lines = $ConnectionString -split "`n"
# Skip the first line and heading
$lines = $lines[2..$($lines.Length - 1)]

$objects = @()

foreach ($line in $lines) {

    if ($line -match '^(\S+)\s+(.+?)\s+(/providers/.+)\s+(.*)$') {
       
        $obj = [PSCustomObject]@{
            Id       = $matches[1]
            Name     = $matches[2]
            APIId    = $matches[3]
            Status   = $matches[4]
        }

        $objects += $obj
    }
    
}

$objects | Out-GridView