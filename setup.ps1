if (-not ($Env:WT_SESSION)) {
    Write-Error "Windows Terminal (wt) is required."
    return
}

if ($PSVersionTable.PSVersion.Major -ne 7) {
    Write-Error "PowerShell 7 (pwsh) is required."
    return
}

if (Test-Path $Profile) {
    Move-Item -Path $Profile -Destination ($Profile + ".bak")
} else {
    New-Item -Path $Profile -Force | Out-Null
}

# Disable telemetry for funziezs
[Environment]::SetEnvironmentVariable("POWERSHELL_TELEMETRY_OPTOUT", "1", "Machine")

Invoke-WebRequest -Uri https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $Profile
Invoke-WebRequest -Uri https://github.com/JanDeDobbeleer/oh-my-posh/raw/main/themes/cobalt2.omp.json -OutFile (Split-Path $Profile)

winget install JanDeDobbeleer.OhMyPosh ajeetdsouza.zoxide --source winget --silent
Write-Host "Successfully Installed CTT PowerShell Profile." -ForegroundColor Green
