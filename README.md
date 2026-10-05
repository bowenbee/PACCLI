# PACCLI

PowerShell scripts that use the [Power Platform CLI](https://aka.ms/PowerPlatformCLI) (`pac`) to export Power Platform solutions from a development environment and import them into another environment.

| Script | Purpose |
|--------|---------|
| `PAC_Exportv2.ps1` | Export a solution (unmanaged + managed), create its deployment settings file, and unpack it to source |
| `PAC_Import.ps1` | Import a solution zip into a target environment, optionally with a deployment settings file |
| `PAC_ConnectAppUser.ps1` | Helper used by the export script to sign in to `pac` as an application user |

## Prerequisites

1. **Power Platform CLI** installed. It comes with the Power Platform Tools extension for VS Code, or can be installed standalone. Check with `pac help`.
2. **An Entra ID app registration** with a client secret.
3. That app registration **added as an application user** in every environment you export from or import to, with the **System Customizer** or **System Administrator** security role (Power Platform admin center → Environment → Settings → Users + permissions → Application users).
4. **PowerShell 7** is recommended.

## One-time setup: store the client secret

The scripts read the app registration's client secret from an encrypted credential file in this folder, so the secret is never written in a script.

```powershell
Get-Credential | Export-Clixml .\MSPP-Automation-App-Account1.txt
```

When prompted, enter anything for the user name (the application ID is a good choice) and the **client secret** as the password.

- The file is encrypted with Windows DPAPI, so it only works for **your user account on this machine**. Re-create it on any other machine.
- It's listed in `.gitignore`. **Never commit it.** If the secret ever is committed, rotate it in Entra ID.

> Run both scripts **from inside this folder**. They find the helper script and the credential file using `.\` paths.

## Exporting a solution: `PAC_Exportv2.ps1`

### Configure

Edit the values near the top of the script:

| Variable | Meaning |
|----------|---------|
| `ApplicationID`, `TenantID` | Your app registration and tenant |
| `ConnectionName` | Name for the `pac` sign-in profile, e.g. `PowerFxHelpDev` |
| `EnvironmentURL` | Source (development) environment URL, e.g. `https://orgXXXX.crm.dynamics.com/` |
| `$SolutionName` | The solution's **unique name**, not its display name |
| `$ExportPath` | Folder to export into, usually the solution's own git repo |

### Run

```powershell
cd <path to PACCLI>
.\PAC_Exportv2.ps1
```

### What it does

1. Signs in to `pac` as the application user.
2. Looks up the solution in the source environment. **It stops** if the solution isn't found or the list can't be retrieved.
3. Exports both versions, with the solution version in the file name:
   - `<SolutionName>_<version>.zip` (unmanaged), e.g. `EisenhowerMatrix_1_0_0_1.zip`
   - `<SolutionName>_<version>_managed.zip`

   **It stops** if either export fails, so the later steps never run against an old zip.
4. Creates the deployment settings file `<SolutionName>_settings.json` from the managed zip. If the file already exists, it asks whether to overwrite it. Answer **N** to keep values you've already filled in.
5. Unpacks the unmanaged zip into `<ExportPath>\solution`, replacing what's there, so changes can be reviewed and committed in git.

### Notes

- Bump the solution version in the maker portal before exporting a new release. Otherwise the new zips overwrite the previous ones with the same version number.
- Each new version leaves the previous pair of zips in the folder. Delete the old ones if you don't want them committed.

## Deployment settings file

The settings file holds the values that differ per environment:

- **Environment variables**, such as a SharePoint site URL or list ID
- **Connection references**: the ID of a connection that already exists in the target environment

The export creates it with **blank values**. Before importing, fill in the values for the target environment:

```json
"EnvironmentVariables": [
  { "SchemaName": "prefix_SiteUrl", "Value": "https://contoso.sharepoint.com/sites/Prod" }
],
"ConnectionReferences": [
  { "LogicalName": "prefix_SharePointConnection", "ConnectionId": "<connection id in the target>" }
]
```

To find a connection ID, open the connection in the target environment's maker portal (Connections). The ID is in the page URL.

> A filled-in settings file contains environment-specific details. Keep it out of public repositories, and use a separate file per target environment (test, stage, prod).

## Importing a solution: `PAC_Import.ps1`

### Configure

Edit `$Params` at the bottom of the script:

| Parameter | Meaning |
|-----------|---------|
| `ApplicationID`, `TenantID`, `ClientSecret` | App registration sign-in. The secret is read from the credential file. |
| `SolutionPath` | Full path to the zip to import. Use the **managed** zip for test, stage and production. |
| `SettingsFilePath` | Full path to the filled-in deployment settings file for the target environment |
| `ConnectionName` | Name for the `pac` sign-in profile for the target, e.g. `Prod` |
| `EnvironmentURL` | Target environment URL |

### Run

```powershell
cd <path to PACCLI>
.\PAC_Import.ps1
```

The script signs in to the target environment and imports the solution, applying the settings file when one is given.

### After importing

1. Check that the solution's cloud flows are **turned on** (Solutions → your solution → Cloud flows).
2. Open the app and confirm it loads data from the target environment's data sources.
3. Share the app with its users in the target environment.

### Known limitations

- `pac` errors don't stop the import script. If signing in to the target fails, the import can run against whichever `pac` profile was active before. Check the output, or run `pac auth list` to confirm which profile is active (`*`).
- Each run creates a new `pac` sign-in profile. Clean up old ones with `pac auth delete --index <n>`.
- A **managed** import fails if an **unmanaged** copy of the same solution already exists in the target environment.
