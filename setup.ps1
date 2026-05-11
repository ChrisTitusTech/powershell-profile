#requires -RunAsAdministrator
#requires -Version 7.0

if (-not ($Env:WT_SESSION)) {
    Throw "Windows Terminal (wt) is required."
}

if (Test-Path $Profile) {
    Move-Item -Path $Profile -Destination ($Profile + ".bak")
} else {
    New-Item -Path $Profile -Force | Out-Null
}

Invoke-WebRequest -Uri https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $Profile
Invoke-WebRequest -Uri https://github.com/JanDeDobbeleer/oh-my-posh/raw/main/themes/cobalt2.omp.json -OutFile (Split-Path $Profile)

Install-Module -Name Terminal-Icons -Force

winget install JanDeDobbeleer.OhMyPosh ajeetdsouza.zoxide DEVCOM.JetBrainsMonoNerdFont --source winget --silent
Write-Host "Successfully Installed CTT PowerShell Profile." -ForegroundColor Green
