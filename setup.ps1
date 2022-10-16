#If the file does not exist, create it.
if (-not(Test-Path -Path $PROFILE -PathType Leaf)) {
     try {
         $null = Invoke-RestMethod https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -o $PROFILE
         Write-Host "The profile @ [$PROFILE] has been created."
     }
     catch {
         throw $_.Exception.Message
     }
 }
# If the file already exists, show the message and do nothing.
 else {
     Write-Host "Cannot create profile, one already exists @ $PROFILE"
 }
& $profile

# OMP Install
#
$app = "JanDeDobbeleer.OhMyPosh"
if ((exit [int] (winget list --name posh | Select-String -Pattern 'found')-eq 1)) {
	winget install $app
} 
else {
    Write-Host "OhMyPosh Already Installed!"
}


# Font Install
$Destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
$null = Invoke-RestMethod https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip?WT.mc_id=-blog-scottha -o cove.zip
Get-ChildItem -Path $Source -Include '*.ttf','*.ttc','*.otf' -Recurse | ForEach {
	$Font = "$($_.Name)"
	If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
		# Copy font to local temporary folder
        	Copy-Item $($_.FullName) -Destination $TempFolder
        
	        # Install font
        	$Destination.CopyHere($Font,0x10)
	}
	else {
		Write-Host "Font Already Installed"
	}
        # Delete temporary copy of font
        Remove-Item $Font -Force
}

