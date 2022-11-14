#If the file does not exist, create it.
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        # Detect Version of Powershell & Create Profile directories if they do not exist.
        if ($PSVersionTable.PSEdition -eq "Core" ) { 
            if (!(Test-Path -Path ($env:userprofile + "\Documents\Powershell"))) {
                New-Item -Path ($env:userprofile + "\Documents\Powershell") -ItemType "directory"
            }
        }
        elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            if (!(Test-Path -Path ($env:userprofile + "\Documents\WindowsPowerShell"))) {
                New-Item -Path ($env:userprofile + "\Documents\WindowsPowerShell") -ItemType "directory"
            }
        }

        Invoke-RestMethod https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -o $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created."
    }
    catch {
        throw $_.Exception.Message
    }
}
# If the file already exists, show the message and do nothing.
 else {
		 Get-Item -Path $PROFILE | Move-Item -Destination oldprofile.ps1
		 Invoke-RestMethod https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -o $PROFILE
		 Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
 }
& $profile

# OMP Install
#
winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh

# Font Install
# You will have to extract and Install this font manually, alternatively use the oh my posh font installer (Must be run as admin)
# oh-my-posh font install
# You will also need to set your Nerd Font of choice in your window defaults or in the Windows Terminal Settings.
Invoke-RestMethod https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip?WT.mc_id=-blog-scottha -o cove.zip

# Choco install
#
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Terminal Icons Install
#
Install-Module -Name Terminal-Icons -Repository PSGallery
