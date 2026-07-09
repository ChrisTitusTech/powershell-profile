# Pretty PowerShell

A clean PowerShell 7 profile for Windows Terminal with better colors, keybinds, Git shortcuts, file helpers, Terminal-Icons, oh-my-posh, and zoxide.

## Install

Run PowerShell as Administrator inside Windows Terminal:

```powershell
irm "https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1" | iex
```

The installer:

- Backs up an existing profile with a timestamped `oldprofile-*.ps1` file.
- Installs this repository's `Microsoft.PowerShell_profile.ps1`.
- Installs Oh My Posh, zoxide, Terminal-Icons, and the CaskaydiaCove Nerd Font.
- Downloads the `cobalt2.omp.json` theme into your PowerShell profile directory.

The profile itself does not install packages, download themes, or upgrade PowerShell during shell startup. Missing optional tools are skipped with a warning.

After installing, restart Windows Terminal and set your PowerShell font to `CaskaydiaCove NF`.

## What's Included

- PSReadLine colors, list-view suggestions, and shell-friendly keybinds.
- Optional `Terminal-Icons`, `oh-my-posh`, and `zoxide` startup.
- Git shortcuts: `gs`, `ga`, `gcom`, `gp`, `gpull`, `gcl`, `lazyg`.
- File helpers: `touch`, `mkcd`, `trash`, `ff`, `head`, `sed`, `which`.
- Process/system helpers: `pgrep`, `pkill`, `k9`, `uptime`, `winutil`, `winutildev`.
- Navigation/listing helpers: `g`, `docs`, `la`, `ll`.

Run `Show-Help` in PowerShell to see the full command list.

## Theme

By default, the profile uses:

```powershell
$Home\cobalt2.omp.json
```

Set `POSH_THEME` to use a different oh-my-posh theme path.

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

## Support

If this profile helps you, star the repo, share it, or sponsor development:
https://github.com/sponsors/ChrisTitusTech
