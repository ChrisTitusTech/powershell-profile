#requires -RunAsAdministrator
#requires -Version 7.0

if (-not ($Env:WT_SESSION)) {
    Throw "Windows Terminal (wt) is required."
}

if (Test-Path $Profile) {
    Move-Item -Path $Profile -Destination ($Profile + ".bak") -Force
} else {
    New-Item -Path $Profile -Force | Out-Null
}

# Disable pwsh telemetry for funnzies :)
[System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT','1','Machine')

Invoke-WebRequest -Uri https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $Profile
Invoke-WebRequest -Uri https://github.com/JanDeDobbeleer/oh-my-posh/raw/main/themes/cobalt2.omp.json -OutFile $Home\cobalt2.omp.json
attrib +h $Home\cobalt2.omp.json

Install-Module -Name Terminal-Icons -Force -Repository PSGallery

winget install JanDeDobbeleer.OhMyPosh ajeetdsouza.zoxide DEVCOM.JetBrainsMonoNerdFont --source winget --silent
Write-Host "Successfully Installed CTT PowerShell Profile." -ForegroundColor Green
