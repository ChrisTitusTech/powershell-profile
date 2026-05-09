if (-Not ($Env:WT_SESSION)) {
    Write-Host "You must use Windows Terminal to install ChrisTitusTech's PowerShell profile" -ForegroundColor Red
    return
}

if ($PSVersionTable.PSVersion.Major -ne 7) {
    Write-Host "You must use PowerShell 7 to install ChrisTitusTech's PowerShell profile" -ForegroundColor Red
    return
}

if (Test-Path $Profile) {
    Move-Item -Path $Profile -Destination ($Profile + ".bak")
} else {
    New-Item -Path $Profile -Force | Out-Null
}

Invoke-WebRequest -Uri https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $Profile
Invoke-WebRequest -Uri https://github.com/JanDeDobbeleer/oh-my-posh/raw/main/themes/cobalt2.omp.json -OutFile (Split-Path $Profile)

winget install JanDeDobbeleer.OhMyPosh ajeetdsouza.zoxide --source winget --silent
Write-Host "Installtion Complete!" -ForegroundColor Green
