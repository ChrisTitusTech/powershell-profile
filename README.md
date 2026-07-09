# Pretty PowerShell

A clean PowerShell 7 profile for Windows Terminal with better colors, keybinds, Git shortcuts, file helpers, Terminal-Icons, oh-my-posh, and zoxide.

## Install

Run PowerShell as Administrator inside Windows Terminal:

```powershell
irm https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1 | iex
```

The installer backs up your existing profile, downloads the profile and cobalt2 oh-my-posh theme, installs `Terminal-Icons`, and installs `oh-my-posh`, `zoxide`, and `JetBrainsMono Nerd Font` with `winget`.

After installing, restart Windows Terminal and set your PowerShell font to `JetBrainsMono Nerd Font`.

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

## Support

If this profile helps you, star the repo, share it, or sponsor development:
https://github.com/sponsors/ChrisTitusTech
