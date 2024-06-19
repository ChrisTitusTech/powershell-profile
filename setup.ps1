

# Ensure the script can run with elevated privileges
$isadmin =
if ($IsWindows) {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
elseif (Get-Command touch -ErrorAction Ignore) {
    touch /tmp *> $null
    Remove-Item /tmp -ErrorAction Ignore
    $LASTEXITCODE -eq 0
}
if (!$isadmin) {
    Write-Warning "Please run this script as an Administrator!"
    break
}
# Function to test internet connectivity
function Test-InternetConnection {
    try {
        $testConnection = Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Check for internet connectivity before proceeding
if (-not (Test-InternetConnection)) {
    break
}

# Profile creation or update
if (!(Test-Path -Path $PROFILE.CurrentUserCurrentHost -PathType Leaf)) {
    try {
        # Create Profile directories if they do not exist.
        $profilePath = $PROFILE.CurrentUserCurrentHost
        New-Item -ItemType File -Force -Name $PROFILE.CurrentUserCurrentHost

        Invoke-RestMethod https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$($PROFILE.CurrentUserCurrentHost)] has been created."
        Write-Host "If you want to add any persistent components, please do so at [$($PROFILE.CurrentUserAllHosts)] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to create or update the profile. Error: $_"
    }
}
else {
    try {
        Get-Item -Path $PROFILE.CurrentUserCurrentHost | Move-Item -Destination "oldprofile.ps1" -Force
        Invoke-RestMethod https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$($PROFILE.CurrentUserCurrentHost)] has been created and old profile moved to ./oldprofile.ps1 ."
        Write-Host "Please back up any persistent components of your old profile to [$($PROFILE.CurrentUserAllHosts)] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to backup and update the profile. Error: $_"
    }
}
#windows 
if($IsWindows) {
# OMP Install
try {
    winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
}
catch {
    Write-Error "Failed to install Oh My Posh. Error: $_"
}

# Font Install
try {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

    if ($fontFamilies -notcontains "CaskaydiaCove NF") {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFileAsync((New-Object System.Uri("https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip")), ".\CascadiaCode.zip")
        
        while ($webClient.IsBusy) {
            Start-Sleep -Seconds 2
        }

        Expand-Archive -Path ".\CascadiaCode.zip" -DestinationPath ".\CascadiaCode" -Force
        $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path ".\CascadiaCode" -Recurse -Filter "*.ttf" | ForEach-Object {
            If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {        
                $destination.CopyHere($_.FullName, 0x10)
            }
        }

        Remove-Item -Path ".\CascadiaCode" -Recurse -Force
        Remove-Item -Path ".\CascadiaCode.zip" -Force
    }
}
catch {
    Write-Error "Failed to download or install the Cascadia Code font. Error: $_"
}

# Final check and message to the user
if ((Test-Path -Path $PROFILE) -and (winget list --name "OhMyPosh" -e) -and ($fontFamilies -contains "CaskaydiaCove NF")) {
    Write-Host "Setup completed successfully. Please restart your PowerShell session to apply changes."
} else {
    Write-Warning "Setup completed with errors. Please check the error messages above."
}

# Choco install
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
catch {
    Write-Error "Failed to install Chocolatey. Error: $_"
}
# zoxide Install
try {
    winget install -e --id ajeetdsouza.zoxide
    Write-Host "zoxide installed successfully."
}
catch {
    Write-Error "Failed to install zoxide. Error: $_"
}
}elseif ($IsLinux) {
    # OMP Install
    & "curl -s https://ohmyposh.dev/install.sh | bash -s"
    # zoxide Install
    & "curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh"
    #font install
    mkdir ~/.local/share/fonts -Force
    Invoke-RestMethod -Uri "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip" -OutFile ".\CascadiaCode.zip"
    Expand-Archive -Path ".\CascadiaCode.zip" -DestinationPath ".\CascadiaCode"
    Copy-Item -Path ".\CascadiaCode\*" -Destination "~/.local/share/fonts" -Recurse -Force
    Remove-Item -Path ".\CascadiaCode\" ".\CascadiaCode.zip" -Force -Recurse
}elseif ($IsMacOS) {
    & "brew install jandedobbeleer/oh-my-posh/oh-my-posh zoxide"
    mkdir ~/.local/share/fonts -Force
    Invoke-RestMethod -Uri "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip" -OutFile ".\CascadiaCode.zip"
    Expand-Archive -Path ".\CascadiaCode.zip" -DestinationPath ".\CascadiaCode"
    Copy-Item -Path ".\CascadiaCode\*" -Destination "/Library/Fonts" -Recurse -Force
    Remove-Item -Path ".\CascadiaCode\" ".\CascadiaCode.zip" -Force -Recurse
}
# Terminal Icons Install
try {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
}
catch {
    Write-Error "Failed to install Terminal Icons module. Error: $_"
}
