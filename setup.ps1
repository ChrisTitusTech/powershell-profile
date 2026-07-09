$profileSourceUri = 'https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1'
$themeSourceUri = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Command {
    param([Parameter(Mandatory)][string]$Name)
    $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function Save-UriToFile {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string]$OutFile
    )

    $client = New-Object System.Net.WebClient
    try {
        $client.DownloadFile($Uri, $OutFile)
    } finally {
        $client.Dispose()
    }
}

function Get-ProfileDir {
    switch ($PSVersionTable.PSEdition) {
        'Core' { Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell'; break }
        'Desktop' { Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell'; break }
        default { throw "Unsupported PowerShell edition: $($PSVersionTable.PSEdition)" }
    }
}

function Test-InternetConnection {
    $response = $null
    try {
        $request = [System.Net.WebRequest]::Create('https://github.com')
        $request.Method = 'HEAD'
        $request.Timeout = 10000
        $response = $request.GetResponse()
        return $true
    } catch {
        Write-Warning 'Internet connection is required but GitHub is not reachable.'
        return $false
    } finally {
        if ($response) {
            $response.Close()
        }
    }
}

function Save-ProfileBackup {
    param([Parameter(Mandatory)][string]$ProfilePath)

    if (-not (Test-Path -Path $ProfilePath -PathType Leaf)) {
        return $null
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupPath = Join-Path (Split-Path -Path $ProfilePath -Parent) "oldprofile-$timestamp.ps1"
    Copy-Item -Path $ProfilePath -Destination $backupPath -Force
    return $backupPath
}

function Install-Profile {
    param(
        [Parameter(Mandatory)][string]$SourceUri,
        [Parameter(Mandatory)][string]$ProfilePath
    )

    $profileDir = Split-Path -Path $ProfilePath -Parent
    if (-not (Test-Path -Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }

    $tempProfile = Join-Path $env:TEMP 'Microsoft.PowerShell_profile.ps1'
    try {
        Save-UriToFile -Uri $SourceUri -OutFile $tempProfile
        $backupPath = Save-ProfileBackup -ProfilePath $ProfilePath
        Copy-Item -Path $tempProfile -Destination $ProfilePath -Force

        Write-Host "PowerShell profile installed to [$ProfilePath]."
        if ($backupPath) {
            Write-Host "Previous profile backed up to [$backupPath]."
        }
    } finally {
        Remove-Item -Path $tempProfile -ErrorAction SilentlyContinue
    }
}

function Install-WinGetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name
    )

    if (-not (Test-Command winget)) {
        Write-Warning "winget was not found. Skipping $Name."
        return $false
    }

    try {
        winget install --id $Id --exact --source winget --accept-source-agreements --accept-package-agreements --silent
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "winget failed to install $Name. Exit code: $LASTEXITCODE"
            return $false
        }
        return $true
    } catch {
        Write-Warning "Failed to install $Name. Error: $_"
        return $false
    }
}

function Install-OhMyPoshTheme {
    param(
        [string]$ThemeName = 'cobalt2',
        [string]$ThemeUri = $themeSourceUri
    )

    $profileDir = Get-ProfileDir
    if (-not (Test-Path -Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }

    $themePath = Join-Path $profileDir "$ThemeName.omp.json"
    try {
        Save-UriToFile -Uri $ThemeUri -OutFile $themePath
        Write-Host "Oh My Posh theme installed to [$themePath]."
        return $themePath
    } catch {
        Write-Warning "Failed to download Oh My Posh theme. Error: $_"
        return $null
    }
}

function Get-InstalledFontName {
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        return (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
    } catch {
        Write-Warning "Unable to inspect installed fonts. Error: $_"
        return @()
    }
}

function Install-NerdFont {
    param(
        [string]$FontName = 'CascadiaCode',
        [string]$FontDisplayName = 'CaskaydiaCove NF',
        [string]$Version = '3.2.1'
    )

    if ((Get-InstalledFontName) -contains $FontDisplayName) {
        Write-Host "Font [$FontDisplayName] is already installed."
        return $true
    }

    $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v$Version/$FontName.zip"
    $zipFilePath = Join-Path $env:TEMP "$FontName.zip"
    $extractPath = Join-Path $env:TEMP $FontName

    try {
        Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        Save-UriToFile -Uri $fontZipUrl -OutFile $zipFilePath
        Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force

        $fontShellFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path $extractPath -Recurse -Filter '*.ttf' | ForEach-Object {
            if (-not (Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                $fontShellFolder.CopyHere($_.FullName, 0x10)
            }
        }

        Write-Host "Font [$FontDisplayName] installed."
        return $true
    } catch {
        Write-Warning "Failed to install $FontDisplayName. Error: $_"
        return $false
    } finally {
        Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $zipFilePath -Force -ErrorAction SilentlyContinue
    }
}

function Install-TerminalIconsModule {
    try {
        Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force -SkipPublisherCheck
        Write-Host 'Terminal-Icons module installed.'
        return $true
    } catch {
        Write-Warning "Failed to install Terminal-Icons. Error: $_"
        return $false
    }
}

if (-not (Test-IsAdministrator)) {
    Write-Warning 'Please run this script as an Administrator.'
    return
}

if (-not (Test-InternetConnection)) {
    return
}

try {
    [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', [EnvironmentVariableTarget]::Machine)
} catch {
    Write-Warning "Unable to set PowerShell telemetry opt-out. Error: $_"
}

$profilePath = $PROFILE.CurrentUserCurrentHost
Install-Profile -SourceUri $profileSourceUri -ProfilePath $profilePath
Install-WinGetPackage -Id 'JanDeDobbeleer.OhMyPosh' -Name 'Oh My Posh' | Out-Null
Install-WinGetPackage -Id 'ajeetdsouza.zoxide' -Name 'zoxide' | Out-Null
Install-OhMyPoshTheme | Out-Null
Install-NerdFont | Out-Null
Install-TerminalIconsModule | Out-Null

Write-Host 'Setup completed. Restart PowerShell to load the profile.'
