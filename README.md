# PowerShell Profile

A modern Windows PowerShell profile with quality-of-life aliases, Oh My Posh support, Terminal-Icons, zoxide navigation, and helper functions for common shell tasks.

## Install

Run the installer from an elevated PowerShell session:

```powershell
irm "https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1" | iex
```

The installer:

- Backs up an existing profile with a timestamped `oldprofile-*.ps1` file.
- Installs this repository's `Microsoft.PowerShell_profile.ps1`.
- Installs Oh My Posh, zoxide, Terminal-Icons, and the CaskaydiaCove Nerd Font.
- Downloads the `cobalt2.omp.json` theme into your PowerShell profile directory.

The profile itself does not install packages, download themes, or upgrade PowerShell during shell startup. Missing optional tools are skipped with a warning.

## Customize

Do not edit `Microsoft.PowerShell_profile.ps1` directly; it is updated from this repository.

Put personal customizations in your all-hosts profile:

```powershell
Edit-Profile
```

You can also place `CTTcustom.ps1` beside `Microsoft.PowerShell_profile.ps1`. It is loaded before this profile reads override variables and functions.

## Supported Overrides

Variables:

```powershell
$EDITOR_Override
$debug_Override
$repo_root_Override
$show_help_Override
$timeFilePath_Override
$updateInterval_Override
```

Functions:

```powershell
Debug-Message_Override
Update-Profile_Override
Update-PowerShell_Override
Clear-Cache_Override
Get-Theme_Override
WinUtilDev_Override
Set-PredictionSource_Override
```

Avoid calling the original function from its override, otherwise the override will recurse.
