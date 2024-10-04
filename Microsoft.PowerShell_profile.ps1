### PowerShell Profile Refactor
### Version 1.04 - Refactored

#################################################################################################################################
############                                                                                                         ############
############                                          !!!   WARNING:   !!!                                           ############
############                                                                                                         ############
############                DO NOT MODIFY THIS FILE. THIS FILE IS HASHED AND UPDATED AUTOMATICALLY.                  ############
############                    ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN BY COMMITS TO                      ############
############                       https://github.com/moeller-projects/powershell-profile.git.                       ############
############                                                                                                         ############
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
############                                                                                                         ############
############                      IF YOU WANT TO MAKE CHANGES, USE THE Edit-Profile FUNCTION                         ############
############                              AND SAVE YOUR CHANGES IN THE FILE CREATED.                                 ############
############                                                                                                         ############
#################################################################################################################################

#region Basic Setup

$global:commandDescriptions = @()
function Add-Command-Description {
    [CmdletBinding()]
    param (
        [string]$CommandName,
        [string]$Description,
        [string]$Category,
        [string[]]$Aliases = @()
    )
    if (-not $CommandName -or -not $Description) {
        Write-Error "Both CommandName and Description are required."
        return
    }
    $commandDescription = [PSCustomObject]@{
        CommandName = $CommandName
        Description = $Description
        Category    = $Category
        Aliases     = $Aliases -join ", "
    }
    $global:commandDescriptions += $commandDescription
}

[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

#opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Initial GitHub.com connectivity check with 1 second timeout
$canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

# Import Modules and External Profiles
function Import-RequiredModules {    
    $modules = @('Terminal-Icons', 'PSMenu', 'InteractiveMenu', 'PSReadLine', 'CompletionPredictor', 'PSFzf')
    $missingModules = $modules | Where-Object { -not (Get-Module -ListAvailable -Name $_) }
    if ($missingModules) {
        Install-Module -Name $missingModules -Scope CurrentUser -Force -SkipPublisherCheck
    }
    Import-Module -Name $modules
}
Import-RequiredModules

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

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

class InfoAttribute : System.Attribute {
    [string]$Description
    [string]$Category

    InfoAttribute([string]$description, [string]$category) {
        $this.Description = $description
        $this.Category = $category
    }
}

class MenuOption {
    [String]$Name
    [String]$Value

    [String]ToString() {
        return "$($this.Name) ($($this.Value))"
    }
}

function New-MenuItem([String]$Name, [String]$Value) {
    $MenuItem = [MenuOption]::new()
    $MenuItem.Name = $Name
    $MenuItem.Value = $Value
    return $MenuItem
}

#endregion

#region System

Add-Command-Description("Update-Profile", "Checks for profile updates from a remote repository and updates if necessary", "System")
function Update-Profile {    
    if (-not $global:canConnectToGitHub) {
        Write-Information "Skipping profile update check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
        return
    }

    try {
        $url = "https://raw.githubusercontent.com/moeller-projects/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
        $oldhash = Get-FileHash $PROFILE
        Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
        $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
        if ($newhash.Hash -ne $oldhash.Hash) {
            Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
            Write-Information "Profile has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
        }
    } catch {
        Write-Error "Unable to check for `$profile updates"
    } finally {
        Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
    }
}
Update-Profile

Add-Command-Description("Update-PowerShell", "Checks for the latest PowerShell release and updates if a new version is available", "System")
function Update-PowerShell {
    if (-not $global:canConnectToGitHub) {
        Write-Information "Skipping PowerShell update check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
        return
    }

    try {
        Write-Information "Checking for PowerShell updates..." -ForegroundColor Cyan
        $updateNeeded = $false
        $currentVersion = $PSVersionTable.PSVersion.ToString()
        $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
        $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
        if ($currentVersion -lt $latestVersion) {
            $updateNeeded = $true
        }

        if ($updateNeeded) {
            Write-Information "Updating PowerShell..." -ForegroundColor Yellow
            winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements
            Write-Information "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
        } else {
            Write-Information "Your PowerShell is up to date." -ForegroundColor Green
        }
    } catch {
        Write-Error "Failed to update PowerShell. Error: $_"
    }
}
Update-PowerShell

Add-Command-Description("Edit-Profile", "Opens the current user's profile for editing using the configured editor", "System")
function Edit-Profile {
    nvim $PROFILE.CurrentUserAllHosts
}

Add-Command-Description("Reload-Profile", "Reloads the current user's PowerShell profile", "System")
function Reload-Profile {    
    & $profile
}

Add-Command-Description("Get-RecentHistory", "Gets recent PowerShell history", "Development")
function Get-RecentHistory {
    [CmdletBinding()]
    param (
        [Int32]$Last
    )

    $historyEntries = $(Get-Content $(Get-PSReadLineOption).HistorySavePath | Select-Object -Last $Last) -join "`n"
    Write-Output $historyEntries
    $historyEntries | clip
    Write-Information "Copied to Clipboard" -ForegroundColor Magenta
}

#endregion

#region File Management

Add-Command-Description("touch", "Creates a new empty file", "File Management")
function touch($file) {
    "" | Out-File $file -Encoding ASCII
}

Add-Command-Description("ff", "Finds files recursively with the specified name", "File Management")
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

#endregion

#region AI
Add-Command-Description("Configure-AI", "Configure the AI-Feature", "AI")
function global:Configure-AI {
    $provider = Read-Host "Enter AI Provider"
    $apiKey = Read-Host "Enter OpenAI API Key"
    $model = Read-Host "Enter OpenAI Model"
    
    [System.Environment]::SetEnvironmentVariable('AI_PROVIDER', $provider, [System.EnvironmentVariableTarget]::Machine)
    [System.Environment]::SetEnvironmentVariable('OPENAI_API_KEY', $apiKey, [System.EnvironmentVariableTarget]::Machine)
    [System.Environment]::SetEnvironmentVariable('OPENAI_MODEL ', $model, [System.EnvironmentVariableTarget]::Machine)
}

Add-Command-Description("Ask-ChatGpt", "Ask ChatGpt a Question", "AI", @("ask"))
function global:Ask-ChatGpt {
    [CmdletBinding()]
    [Alias("ask")]
    param (
        [string[]]$Args,
        [switch]$UseShell
    )

    if (-not $env:OPENAI_API_KEY) {
        Write-Error "Error: The OPENAI_API_KEY environment variable is not set."
        return
    }

    $argsString = $Args -join ' '
    $shellOption = if ($UseShell) { '-s' } else { '' }
    $command = "tgpt $shellOption `"$argsString`""
    Invoke-Expression $command
}
#endregion

#region Network Utilities

Add-Command-Description("Get-PubIP", "Retrieves the public IP address of the machine", "Network Utilities")
function Get-PubIP {    
    (Invoke-WebRequest https://ipv4.icanhazip.com).Content.Trim()
}

#endregion

# Open WinUtil
Add-Command-Description("winutil", "Runs the WinUtil script from Chris Titus Tech", "System Utilities")
function winutil {
	Invoke-WebRequest -useb https://christitus.com/win | Invoke-Expression
}

# System Utilities
Add-Command-Description("admin", "Runs a command as an administrator", "System Utilities", @("su"))
function admin {
    [CmdletBinding()]
    [Alias("su")]
    param ()
    
    if ($args.Count -gt 0) {
        $argList = "& '$args'"
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

Add-Command-Description("uptime", "Displays the system uptime", "System Utilities")
function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

Add-Command-Description("unzip", "Extracts a zip file to the current directory", "File Management")
function unzip ($file) {
    Write-Information("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}

Add-Command-Description("hb", "Uploads the specified file's content to a hastebin-like service and returns the URL", "File Management")
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

Add-Command-Description("grep", "Searches for a regex pattern in files within the specified directory or from the pipeline input", "File Management")
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

Add-Command-Description("df", "Displays information about volumes", "System Utilities")
function df {
    get-volume
}

Add-Command-Description("sed", "Replaces text in a file", "File Management")
function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

Add-Command-Description("which", "Shows the path of the command", "System Utilities")
function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

Add-Command-Description("export", "Sets an environment variable", "System Utilities")
function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

Add-Command-Description("pkill", "Kills processes by name", "System Utilities")
function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

Add-Command-Description("pgrep", "Lists processes by name", "System Utilities")
function pgrep($name) {
    Get-Process $name
}

Add-Command-Description("head", "Displays the first n lines of a file", "File Management")
function head {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

Add-Command-Description("tail", "Displays the last n lines of a file", "File Management")
function tail {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
Add-Command-Description("nf", "Creates a new file with the specified name", "File Management")
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
Add-Command-Description("mkcd", "Creates and changes to a new directory", "Directory Management")
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

#region Quality of Life Aliases
# Navigation Shortcuts
Add-Command-Description("docs", "Changes the current directory to the user's Documents folder", "Navigation Shortcuts")
function docs { Set-Location -Path $HOME\Documents }

Add-Command-Description("dtop", "Changes the current directory to the user's Desktop folder", "Navigation Shortcuts")
function dtop { Set-Location -Path $HOME\Desktop }

# Quick Access to Editing the Profile
Add-Command-Description("ep", "Opens the profile for editing", "Navigation Shortcuts")
function ep { nvim $PROFILE }

# Simplified Process Management
Add-Command-Description("k9", "Kills a process by name", "Simplified Process Management")
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing
Add-Command-Description("la", "Lists all files in the current directory with detailed formatting", "Enhanced Listing")
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
Add-Command-Description("ll", "Lists all files, including hidden, in the current directory with detailed formatting", "Enhanced Listing")
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }

# Git Shortcuts
Add-Command-Description("gs", "Shortcut for 'git status'", "Git Shortcuts")
function gs { git status }

Add-Command-Description("ga", "Shortcut for 'git add .'", "Git Shortcuts")
function ga { git add . }

Add-Command-Description("gc", "Shortcut for 'git commit -m'", "Git Shortcuts")
function gc { param($m) git commit -m "$m" }

Add-Command-Description("gp", "Shortcut for 'git push'", "Git Shortcuts")
function gp { git push }

Add-Command-Description("g", "Changes to the GitHub directory", "Git Shortcuts")
function g { __zoxide_z github }

Add-Command-Description("gcl", "Clones a git repository", "Git Shortcuts")
function gcl { git clone "$args" }

Add-Command-Description("gcom", "Adds all changes and commits with the specified message", "Git Shortcuts")
function gcom {
    git add .
    git commit -m "$args"
}
Add-Command-Description("lazyg", "Adds all changes, commits with the specified message, and pushes to the remote repository", "Git Shortcuts")
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

Add-Command-Description("lzg", "Runs lazygit", "Terminal Apps")
function lzg { lazygit }

Add-Command-Description("lzd", "Runs lazydocker", "Terminal Apps")
function lzd { lazydocker }

Set-Alias k kubectl
Set-Alias d docker
Set-Alias dc docker-compose

#endregion

# Quick Access to System Information
Add-Command-Description("sysinfo", "Displays detailed system information", "Quick Access to System Information")
function sysinfo { Get-ComputerInfo }

# Networking Utilities
Add-Command-Description("flushdns", "Clears the DNS cache", "Networking Utilities")
function flushdns {
	Clear-DnsClientCache
	Write-Information "DNS has been flushed"
}

# Clipboard Utilities
Add-Command-Description("cpy", "Copies the specified text to the clipboard", "Clipboard Utilities")
function cpy { Set-Clipboard $args[0] }

Add-Command-Description("pst", "Retrieves text from the clipboard", "Clipboard Utilities")
function pst { Get-Clipboard }

Add-Command-Description("Switch-Azure-Subscription", "Select and login to Azure Subscription", "Development", @("sas"))
function Switch-Azure-Subscription {
    [CmdletBinding()]
    [Alias("sas")]
    param ()
    
    # Fetch the list of Azure subscriptions
    $AZ_SUBSCRIPTIONS = az account list --output json | ConvertFrom-Json
    if ($AZ_SUBSCRIPTIONS.Count -eq 0) {
        Write-Error "No Azure Subscriptions found."
        return
    }

    # Populate the options array
    $Options = $AZ_SUBSCRIPTIONS | ForEach-Object { New-MenuItem -Name $_.name -Value $_.id }

    # Display the menu and get the selected subscription
    $selectedAZSub = Show-Menu -MenuItems $Options

    # Set the selected Azure subscription
    & az account set -s $selectedAZSub.Value
}


# Login to Docker Registry
Add-Command-Description("Login-ACR", "Select and login to Azure Container Registry using Docker", "Development", @("lacr"))
function Login-ACR {
    [CmdletBinding()]
    [Alias("lacr")]
    param ()
    
    # Retrieve the list of Azure Container Registries
    $ACRs = az acr list --output json | ConvertFrom-Json

    # Check if $ACRs is empty
    if ($ACRs.Count -eq 0) {
        Write-Error "No Azure Container Registries found."
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

Add-Command-Description("Get-FileSize", "Gets the size of a file", "File Management")
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
Add-Command-Description("Share-File", "Uploads one or more files to share it using HiDrive", "Share")
function Share-File {
    [Info("Upload one or more Files to share it using HiDrive", "Share")]
    [CmdletBinding()]
    [Alias("sf")]
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
            Write-Information "[DONE] $($file.Name) - $(Get-FileSize -Path $Path)"
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

Add-Command-Description("Watch-File", "Watches a file for changes", "File Management", @("wf"))
function Watch-File {
	param (
        [string]$Path
    )
	Get-Content $Path -Wait -Tail 1
}
function wf { Watch-File -Path $args[0] }

Add-Command-Description("Select-KubeContext", "Selects a Kubernetes context", "Kubernetes Utilities", @("kubectx"))
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

Add-Command-Description("Select-KubeNamespace", "Selects a Kubernetes namespace", "Kubernetes Utilities", @("kubens"))
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

$Global:ProjectPaths = @(
	"D:\projects\aveato",
	"D:\projects\laekkerai",
	"D:\projects\private"
)
# Class to support auto-completion of project folders from multiple paths
Class MyProjects : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {        
        # Collect project names from all specified paths
        $ProjectNames = foreach ($ProjectPath in $Global:ProjectPaths) {
            if (Test-Path $ProjectPath) {
                (Get-ChildItem -Path $ProjectPath -Directory).BaseName
            }
        }

        # Return distinct project names
        return [string[]] $ProjectNames | Sort-Object -Unique
    }
}

Add-Command-Description("Enter-Projects", "Enters a predefined project folder", "Navigation", @("project"))
function Enter-Projects {
    [CmdletBinding()]
    [Alias("project")]
    param(
        # Enable tab completion with projects found in multiple paths
        [ValidateSet([MyProjects])]
        [ArgumentCompletions([MyProjects])]
        [string]
        $projects
    )

    # Find the first matching project folder in the specified paths
    foreach ($ProjectPath in $Global:ProjectPaths) {
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

#region Setup Command Completions

if (Test-CommandExists fnm) {
    fnm env --use-on-cd --shell power-shell | Out-String | Invoke-Expression
}

if (Test-CommandExists fnm) {
	volta completions powershell | Out-String | Invoke-Expression
}

#endregion

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
        oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/powerlevel10k_lean.omp.json" | Invoke-Expression
    }
}

## Final Line to set prompt
Get-Theme
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
} else {
    Write-Information "zoxide command not found. Attempting to install via winget..."
    try {
        winget install -e --id ajeetdsouza.zoxide
        Write-Information "zoxide installed successfully. Initializing..."
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

function global:Show-Help {
    # Create a hashtable to group functions by category
    $groupedByCategory = @{}

    foreach ($commandDescription in $commandDescriptions) {
            $category = $commandDescription.Category
            $description = $commandDescription.Description
            $functionName = $commandDescription.CommandName

            $aliasList = $commandDescription.aliases -join ", "
            if (-not $aliasList) {
                $aliasList = " "
            }
            if (-not $groupedByCategory.ContainsKey($category)) {
                $groupedByCategory[$category] = @()
            }

            $groupedByCategory[$category] += [pscustomobject]@{
                Name        = $functionName
                Description = $description
                Aliases     = $aliasList
            }
    }

    # Now print the functions, grouped by category
    foreach ($category in $groupedByCategory.Keys) {
        Write-Information "=> $category" -ForegroundColor Cyan
        $groupedByCategory[$category] | Format-Table -Property Name, Aliases, Description -AutoSize
        Write-Information ""
    }
}
Write-Information "Use 'Show-Help' to display help"