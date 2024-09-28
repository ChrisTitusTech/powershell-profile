### PowerShell Profile Refactor
### Version 1.04 - Refactored

#################################################################################################################################
############                                                                                                         ############
############                                          !!!   WARNING:   !!!                                           ############
############                                                                                                         ############
############                DO NOT MODIFY THIS FILE. THIS FILE IS HASHED AND UPDATED AUTOMATICALLY.                  ############
############                    ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN BY COMMITS TO                      ############
############                       https://github.com/moeller-projects/powershell-profile.git.                         ############
############                                                                                                         ############
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
############                                                                                                         ############
############                      IF YOU WANT TO MAKE CHANGES, USE THE Edit-Profile FUNCTION                         ############
############                              AND SAVE YOUR CHANGES IN THE FILE CREATED.                                 ############
############                                                                                                         ############
#################################################################################################################################

[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

#opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Initial GitHub.com connectivity check with 1 second timeout
$canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

# Import Modules and External Profiles
# Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons, PSMenu, InteractiveMenu, PSReadLine, CompletionPredictor, PSFzf -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons, PSMenu, InteractiveMenu, PSReadLine, CompletionPredictor, PSFzf
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# Check for Profile Updates
function Update-Profile {
    if (-not $global:canConnectToGitHub) {
        Write-Host "Skipping profile update check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
        return
    }

    try {
        $url = "https://raw.githubusercontent.com/moeller-projects/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
        $oldhash = Get-FileHash $PROFILE
        Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
        $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
        if ($newhash.Hash -ne $oldhash.Hash) {
            Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
            Write-Host "Profile has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
        }
    } catch {
        Write-Error "Unable to check for `$profile updates"
    } finally {
        Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
    }
}
Update-Profile

function Update-PowerShell {
    if (-not $global:canConnectToGitHub) {
        Write-Host "Skipping PowerShell update check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
        $updateNeeded = $false
        $currentVersion = $PSVersionTable.PSVersion.ToString()
        $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
        $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
        if ($currentVersion -lt $latestVersion) {
            $updateNeeded = $true
        }

        if ($updateNeeded) {
            Write-Host "Updating PowerShell..." -ForegroundColor Yellow
            winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements
            Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
        } else {
            Write-Host "Your PowerShell is up to date." -ForegroundColor Green
        }
    } catch {
        Write-Error "Failed to update PowerShell. Error: $_"
    }
}
Update-PowerShell


# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# Utility Functions
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Editor Configuration
$EDITOR = if (Test-CommandExists nvim) { 'nvim' }
          elseif (Test-CommandExists pvim) { 'pvim' }
          elseif (Test-CommandExists vim) { 'vim' }
          elseif (Test-CommandExists vi) { 'vi' }
          elseif (Test-CommandExists code) { 'code' }
          elseif (Test-CommandExists notepad++) { 'notepad++' }
          elseif (Test-CommandExists sublime_text) { 'sublime_text' }
          else { 'notepad' }
Set-Alias -Name vim -Value $EDITOR

function Edit-Profile {
    vim $PROFILE.CurrentUserAllHosts
}
function touch($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Ask ChatGPT
function Ask-ChatGpt {
    param (
        [string[]]$Args,
        [switch]$UseShell
    )

    if (-not $env:OPENAI_API_KEY) {
        Write-Host "Error: The OPENAI_API_KEY environment variable is not set."
        return
    }

    $argsString = $Args -join ' '
    $shellOption = if ($UseShell) { '-s ' } else { '' }
    $command = "tgpt --provider openai --key $env:OPENAI_API_KEY --model 'gpt-4o' $shellOption'$argsString'"
    Invoke-Expression $command
}
function ask {
    param (
        [string[]]$Args
    )
    Ask-ChatGpt -Args $Args
}

# Network Utilities
function Get-PubIP { (Invoke-WebRequest https://ipv4.icanhazip.com).Content.Trim() }

# Open WinUtil
function winutil {
	iwr -useb https://christitus.com/win | iex
}

# System Utilities
function admin {
    if ($args.Count -gt 0) {
        $argList = "& '$args'"
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
Set-Alias -Name su -Value admin

function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

function reload-profile {
    & $profile
}

function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function hb {
    if ($args.Length -eq 0) {
        Write-Error "No file path specified."
        return
    }
    
    $FilePath = $args[0]
    
    if (Test-Path $FilePath) {
        $Content = Get-Content $FilePath -Raw
    } else {
        Write-Error "File path does not exist."
        return
    }
    
    $uri = "https://hastebin.de/documents"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $Content -ErrorAction Stop
        $hasteKey = $response.key
        $url = "https://hastebin.de/$hasteKey"
        Write-Output $url
    } catch {
        Write-Error "Failed to upload the document. Error: $_"
    }
}
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function df {
    get-volume
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

function head {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

function tail {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

### Quality of Life Aliases

# Navigation Shortcuts
function docs { Set-Location -Path $HOME\Documents }

function dtop { Set-Location -Path $HOME\Desktop }

# Quick Access to Editing the Profile
function ep { vim $PROFILE }

# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }

# Git Shortcuts
function gs { git status }

function ga { git add . }

function gc { param($m) git commit -m "$m" }

function gp { git push }

function g { __zoxide_z github }

function gcl { git clone "$args" }

function gcom {
    git add .
    git commit -m "$args"
}
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

# Quick Access to System Information
function sysinfo { Get-ComputerInfo }

# Networking Utilities
function flushdns {
	Clear-DnsClientCache
	Write-Host "DNS has been flushed"
}

# Clipboard Utilities
function cpy { Set-Clipboard $args[0] }

function pst { Get-Clipboard }

# Define a class for menu options
class MenuOption {
    [String]$Name
    [String]$Value

    [String]ToString() {
        return "$($this.Name) ($($this.Value))"
    }
}

# Function to create a new menu item
function New-MenuItem([String]$Name, [String]$Value) {
    $MenuItem = [MenuOption]::new()
    $MenuItem.Name = $Name
    $MenuItem.Value = $Value
    return $MenuItem
}

# Switch Azure Subscription
function Switch-Azure-Subscription {
    # Fetch the list of Azure subscriptions
    $AZ_SUBSCRIPTIONS = az account list --output json | ConvertFrom-Json
    if ($AZ_SUBSCRIPTIONS.Count -eq 0) {
        Write-Host "No Azure Subscriptions found."
        return
    }

    # Populate the options array
    $Options = $AZ_SUBSCRIPTIONS | ForEach-Object { New-MenuItem -Name $_.name -Value $_.id }

    # Display the menu and get the selected subscription
    $selectedAZSub = Show-Menu -MenuItems $Options

    # Set the selected Azure subscription
    & az account set -s $selectedAZSub.Value
}
function sas { Switch-Azure-Subscription }


# Login to Docker Registry
function Login-Azure-Container-Registry {
    # Retrieve the list of Azure Container Registries
    $ACRs = az acr list --output json | ConvertFrom-Json

    # Check if $ACRs is empty
    if ($ACRs.Count -eq 0) {
        Write-Host "No Azure Container Registries found."
        return
    }

    # Create menu options from the ACR list
    $Options = $ACRs | ForEach-Object { New-MenuItem -Name $_.loginServer -Value $_.name }

    # Display the menu and get the selected ACR
    $selectedACR = Show-Menu -MenuItems $Options

    # Get the credentials for the selected ACR
    $credentials = az acr credential show --name $selectedACR.Value -o json | ConvertFrom-Json

    # Login to Docker registry using the credentials
    docker login $selectedACR.Name --username $credentials.username --password $credentials.passwords[0].value
}
function lacr { Login-Azure-Container-Registry }

function Get-FileSize {
    param(
        [string]$Path
    )
    
    $file = Get-Item -Path $Path
    $sizeInBytes = $file.Length

    $units = @("Bytes", "KB", "MB", "GB", "TB")
    $unitValues = 1, 1KB, 1MB, 1GB, 1TB

    for ($i = $units.Length - 1; $i -ge 0; $i--) {
        if ($sizeInBytes -ge $unitValues[$i]) {
            $size = [math]::round($sizeInBytes / $unitValues[$i], 2)
            Write-Output "$size $($units[$i])"
            return
        }
    }
}

# Share File via HiDrive Share
function Share-File {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Paths
    )
    
    # Base URLs
    $baseApiUrl = "https://share.hidrive.com/api"

    # Request credentials for file sharing
    try {
        $credentialsResponse = Invoke-WebRequest -Method POST -Uri "$baseApiUrl/new"
        $credentials = $credentialsResponse.Content | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to obtain credentials: $_"
        return
    }

    foreach ($Path in $Paths) {
        # Validate file path
        if (-not (Test-Path -Path $Path)) {
            Write-Error "The specified path '$Path' does not exist."
            continue
        }

        try {
            # Get the file item
            $file = Get-Item -Path $Path

            # Upload the file
            $uploadUri = "$baseApiUrl/$($credentials.id)/patch?dst=$($file.name)&offset=0"
            $uploadResponse = Invoke-WebRequest -Method POST -Uri $uploadUri -Form @{file = $file} -ContentType "multipart/form-data" -Headers @{"x-auth-token" = $credentials.token}
            Write-Output "[DONE] $($file.Name) - $(Get-FileSize -Path $Path)"
        }
        catch {
            Write-Error "An error occurred while processing '$Path': $_"
        }
    }

    # Finalize the upload
    $finalizeUri = "$baseApiUrl/$($credentials.id)/finalize"
    $finalizeResponse = Invoke-WebRequest -Method POST -Uri $finalizeUri -Headers @{"x-auth-token" = $credentials.token}

    # Collect the shareable link
    $share = "https://get.hidrive.com/$($credentials.id)"
    
    $share | clip
    Write-Output $share
}
function sf { Share-File }


# Terminal Apps
function lzg { lazygit }
function lzd { lazydocker }


# Init fnm (Fast Node.js Manager)
if (Test-CommandExists fnm) {
    fnm env --use-on-cd --shell power-shell | Out-String | Invoke-Expression
}

function Init-fnm {
	node --version > .node-version
}

function Watch-File {
	param (
        [string]$Path
    )
	Get-Content $Path -Wait -Tail 1
}

function wf { Watch-File -Path $args[0] }

Set-Alias k kubectl
Set-Alias d docker
Set-Alias dc docker-compose
function global:Select-KubeContext {
  [CmdletBinding()]
  [Alias('kubectx')]
  param (
    [parameter(Mandatory=$False,Position=0,ValueFromRemainingArguments=$True)]
    [Object[]] $Arguments
  )
  begin {
    if ($Arguments.Length -gt 0) {
      $ctx = & kubectl config get-contexts -o=name | fzf -q @Arguments
    } else {
      $ctx = & kubectl config get-contexts -o=name | fzf
    }
  }
  process {
    if ($ctx -ne '') {
      & kubectl config use-context $ctx
    }
  }
}

function global:Select-KubeNamespace {
  [CmdletBinding()]
  [Alias('kubens')]
  param (
    [parameter(Mandatory=$False,Position=0,ValueFromRemainingArguments=$True)]
    [Object[]] $Arguments
  )
  begin {
    if ($Arguments.Length -gt 0) {
      $ns = & kubectl get namespace -o=name | fzf -q @Arguments
    } else {
      $ns = & kubectl get namespace -o=name | fzf
    }
  }
  process {
    if ($ns -ne '') {
      $ns = $ns -replace '^namespace/'
      & kubectl config set-context --current --namespace=$ns
    }
  }
}

$ProjectPaths = @(
	"D:\projects\aveato",
	"D:\projects\laekkerai",
	"D:\projects\private"
)
# Class to support auto-completion of project folders from multiple paths
Class MyProjects : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {        
        # Collect project names from all specified paths
        $ProjectNames = foreach ($ProjectPath in $ProjectPaths) {
            if (Test-Path $ProjectPath) {
                (Get-ChildItem -Path $ProjectPath -Directory).BaseName
            }
        }

        # Return distinct project names
        return [string[]] $ProjectNames | Sort-Object -Unique
    }
}

# Command Definition
function Enter-Projects {
    [CmdletBinding()]
    param(
        # Enable tab completion with projects found in multiple paths
        [ValidateSet([MyProjects])]
        [ArgumentCompletions([MyProjects])]
        [string]
        $projects
    )

    # Find the first matching project folder in the specified paths
    foreach ($ProjectPath in $ProjectPaths) {
        $FullProjectPath = Join-Path -Path $ProjectPath -ChildPath $projects
        if (Test-Path $FullProjectPath) {
            Set-Location -Path $FullProjectPath
            Get-ChildItem
            return
        }
    }

    # If no match found, throw an error
    Write-Error "Project '$projects' not found in the specified paths."
}
New-Alias -Name "project" Enter-Projects


# Customize syntax highlighting
Set-PSReadLineOption -Colors @{
    Command = "Cyan"
    Keyword = "Green"
    String = "Magenta"
    Operator = "Yellow"
    Variable = "White"
    Comment = "DarkGray"
}

# Increase history size
Set-PSReadLineOption -MaximumHistoryCount 4096
# Enable predictive IntelliSense
Set-PSReadLineOption -PredictionSource History
# Case insensitive history search with cursor at the end
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
# Disable bell
Set-PSReadLineOption -BellStyle None
# Set custom key bindings
Set-PSReadLineKeyHandler -Key Ctrl+l -Function ClearScreen
Set-PSReadLineKeyHandler -Chord Enter -Function ValidateAndAcceptLine
Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord Alt+v -Function SwitchPredictionView
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Save command history to file
Set-PSReadLineOption -HistorySavePath "$env:APPDATA\PSReadLine\CommandHistory.txt"

$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    dotnet complete --position $cursorPosition $commandAst.ToString() |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock

Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    $completion_file = New-TemporaryFile
    $env:ARGCOMPLETE_USE_TEMPFILES = 1
    $env:_ARGCOMPLETE_STDOUT_FILENAME = $completion_file
    $env:COMP_LINE = $wordToComplete
    $env:COMP_POINT = $cursorPosition
    $env:_ARGCOMPLETE = 1
    $env:_ARGCOMPLETE_SUPPRESS_SPACE = 0
    $env:_ARGCOMPLETE_IFS = "`n"
    $env:_ARGCOMPLETE_SHELL = 'powershell'
    az 2>&1 | Out-Null
    Get-Content $completion_file | Sort-Object | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
    }
    Remove-Item $completion_file, Env:\_ARGCOMPLETE_STDOUT_FILENAME, Env:\ARGCOMPLETE_USE_TEMPFILES, Env:\COMP_LINE, Env:\COMP_POINT, Env:\_ARGCOMPLETE, Env:\_ARGCOMPLETE_SUPPRESS_SPACE, Env:\_ARGCOMPLETE_IFS, Env:\_ARGCOMPLETE_SHELL
}


# Get theme from profile.ps1 or use a default theme
function Get-Theme {
    if (Test-Path -Path $PROFILE.CurrentUserAllHosts -PathType leaf) {
        $existingTheme = Select-String -Raw -Path $PROFILE.CurrentUserAllHosts -Pattern "oh-my-posh init pwsh --config"
        if ($null -ne $existingTheme) {
            Invoke-Expression $existingTheme
            return
        }
    } else {
        oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/material.omp.json" | Invoke-Expression
    }
}

## Final Line to set prompt
Get-Theme
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
} else {
    Write-Host "zoxide command not found. Attempting to install via winget..."
    try {
        winget install -e --id ajeetdsouza.zoxide
        Write-Host "zoxide installed successfully. Initializing..."
        Invoke-Expression (& { (zoxide init powershell | Out-String) })
    } catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
}

Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force

# Set-PSReadLineOption -PredictionSource History
# Set-PSReadLineOption -PredictionViewStyle ListView
# Set-PSReadLineOption -EditMode Windows

# Help Function
function Show-Help {
    @"
PowerShell Profile Help
=======================

Update-Profile - Checks for profile updates from a remote repository and updates if necessary.

Update-PowerShell - Checks for the latest PowerShell release and updates if a new version is available.

Edit-Profile - Opens the current user's profile for editing using the configured editor.

touch <file> - Creates a new empty file.

ff <name> - Finds files recursively with the specified name.

Get-PubIP - Retrieves the public IP address of the machine.

winutil - Runs the WinUtil script from Chris Titus Tech.

uptime - Displays the system uptime.

reload-profile - Reloads the current user's PowerShell profile.

unzip <file> - Extracts a zip file to the current directory.

hb <file> - Uploads the specified file's content to a hastebin-like service and returns the URL.

grep <regex> [dir] - Searches for a regex pattern in files within the specified directory or from the pipeline input.

df - Displays information about volumes.

sed <file> <find> <replace> - Replaces text in a file.

which <name> - Shows the path of the command.

export <name> <value> - Sets an environment variable.

pkill <name> - Kills processes by name.

pgrep <name> - Lists processes by name.

head <path> [n] - Displays the first n lines of a file (default 10).

tail <path> [n] - Displays the last n lines of a file (default 10).

nf <name> - Creates a new file with the specified name.

mkcd <dir> - Creates and changes to a new directory.

docs - Changes the current directory to the user's Documents folder.

dtop - Changes the current directory to the user's Desktop folder.

ep - Opens the profile for editing.

k9 <name> - Kills a process by name.

la - Lists all files in the current directory with detailed formatting.

ll - Lists all files, including hidden, in the current directory with detailed formatting.

gs - Shortcut for 'git status'.

ga - Shortcut for 'git add .'.

gc <message> - Shortcut for 'git commit -m'.

gp - Shortcut for 'git push'.

g - Changes to the GitHub directory.

gcom <message> - Adds all changes and commits with the specified message.

lazyg <message> - Adds all changes, commits with the specified message, and pushes to the remote repository.

sysinfo - Displays detailed system information.

flushdns - Clears the DNS cache.

cpy <text> - Copies the specified text to the clipboard.

pst - Retrieves text from the clipboard.

sas - Switch current selected Azure Subscription.

lacr - Login to Azure Container Registry.

ask - Ask ChatGPT.

Use 'Show-Help' to display this help message.
"@
}
Write-Host "Use 'Show-Help' to display help"
