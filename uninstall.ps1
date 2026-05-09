if ($PSVersionTable.PSVersion.Major -ne 7) {
    Write-Error "PowerShell 7 (pwsh) is required."
    return
}

if (Test-Path ($Profile + ".bak")) {
    Move-Item -Path ($Profile + ".bak") -Destination $Profile
}

Remove-Item -Path (Join-Path (Split-Path $Profile) cobalt2.omp.json))

winget remove JanDeDobbeleer.OhMyPosh ajeetdsouza.zoxide --source winget --silent
Write-Host "Uninstallation Complete!" -ForegroundColor Green
