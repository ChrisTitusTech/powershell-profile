if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -SkipPublisherCheck
}
Invoke-ScriptAnalyzer -Path .\Microsoft.PowerShell_profile.ps1 | Where-Object { $_.Severity -ne 0 -and $_.Severity -ne 1}