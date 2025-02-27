
function Connect-PACCLIAppUser {

    <# 
        Connect to an Environment Using PAC CLI and an Application User Account
    #>

    param (
        [string]$ConnectionName,
        [string]$EnvironmentURL,
        [string]$ApplicationID,
        [string]$TenantID,
        [string]$ClientSecret
    )

    pac auth create `
     --name $ConnectionName `
      --environment $EnvironmentURL `
       --applicationid $ApplicationID `
        --tenant $TenantID `
        --clientsecret $ClientSecret
    
}