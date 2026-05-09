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
Write-Host "Installed PowerShell Profile" -ForegroundColor Green

Invoke-WebRequest -Uri https://github.com/JanDeDobbeleer/oh-my-posh/raw/main/themes/cobalt2.omp.json -OutFile $Home\cobalt2.omp.json
attrib +h $Home\cobalt2.omp.json # Hide the file
Write-Host "Installed oh-my-posh theme" -ForegroundColor Green

Write-Host "Installing dependencies..."

# If you dont have winget then fuck you
winget install JanDeDobbeleer.OhMyPosh --source winget --silent
winget install ajeetdsouza.zoxide --source winget --silent

Write-Host "Installtion Complete!" -ForegroundColor Green
