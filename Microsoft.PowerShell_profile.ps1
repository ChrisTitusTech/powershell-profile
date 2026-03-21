### PowerShell Profile Refactor
### Version 1.04 - Refactored

$debug = $false

#################################################################################################################################
############                                                                                                         ############
############                                          !!!   WARNING:   !!!                                           ############
############                                                                                                         ############
############                DO NOT MODIFY THIS FILE. THIS FILE IS HASHED AND UPDATED AUTOMATICALLY.                  ############
############                    ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN BY COMMITS TO                      ############
############                       https://github.com/thomaskrol/powershell-profile.git.                         ############
############                                                                                                         ############
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
############                                                                                                         ############
############                      TO ADD YOUR OWN CODE OR IF YOU WANT TO OVERRIDE ANY OF THESE VARIABLES             ############
############                      OR FUNCTIONS. USE THE Edit-Profile FUNCTION TO CREATE YOUR OWN profile.ps1 FILE.   ############
############                      TO OVERRIDE IN YOUR NEW profile.ps1 FILE, REWRITE THE VARIABLE                     ############
############                      OR FUNCTION, ADDING "_Override" TO THE NAME.                                       ############
############                                                                                                         ############
############                      THE FOLLOWING VARIABLES RESPECT _Override:                                         ############
############                      $EDITOR_Override                                                                   ############
############                      $debug_Override                                                                    ############
############                      $repo_root_Override  [To point to a fork, for example]                             ############
############                      $timeFilePath_Override                                                             ############
############                      $updateInterval_Override                                                           ############
############                                                                                                         ############
############                      THE FOLLOWING FUNCTIONS RESPECT _Override:                                         ############
############                      Debug-Message_Override                                                             ############
############                      Update-Profile_Override                                                            ############
############                      Update-PowerShell_Override                                                         ############
############                      Clear-Cache_Override                                                               ############
############                      Get-Theme_Override                                                                 ############
############                      WinUtilDev_Override [To call a fork, for example]                                  ############
############                      Set-PredictionSource                                                               ############
#################################################################################################################################

if ($debug_Override){
    # If variable debug_Override is defined in profile.ps1 file
    # then use it instead
    $debug = $debug_Override
} else {
    $debug = $false
}

# Define the path to the file that stores the last execution time
if ($repo_root_Override){
    # If variable $repo_root_Override is defined in profile.ps1 file
    # then use it instead
    $repo_root = $repo_root_Override
} else {
    $repo_root = "https://raw.githubusercontent.com/thomaskrol"
}

# Helper function for cross-edition compatibility
function Get-ProfileDir {
    if ($PSVersionTable.PSEdition -eq "Core") {
        return [Environment]::GetFolderPath("MyDocuments") + "\PowerShell"
    } elseif ($PSVersionTable.PSEdition -eq "Desktop") {
        return [Environment]::GetFolderPath("MyDocuments") + "\WindowsPowerShell"
    } else {
        Write-Error "Unsupported PowerShell edition: $($PSVersionTable.PSEdition)"
        return $null
    }
}

# Define the path to the file that stores the last execution time
if ($timeFilePath_Override){
    # If variable $timeFilePath_Override is defined in profile.ps1 file
    # then use it instead
    $timeFilePath = $timeFilePath_Override
} else {
    $profileDir = Get-ProfileDir
    $timeFilePath = "$profileDir\LastExecutionTime.txt"
}

# Define the update interval in days, set to -1 to always check
if ($updateInterval_Override){
    # If variable $updateInterval_Override is defined in profile.ps1 file
    # then use it instead
    $updateInterval = $updateInterval_Override
} else {
    $updateInterval = 7
}

function Debug-Message{
    # If function "Debug-Message_Override" is defined in profile.ps1 file
    # then call it instead.
    if (Get-Command -Name "Debug-Message_Override" -ErrorAction SilentlyContinue) {
        Debug-Message_Override
    } else {
        Write-Host "#######################################" -ForegroundColor Red
        Write-Host "#           Debug mode enabled        #" -ForegroundColor Red
        Write-Host "#          ONLY FOR DEVELOPMENT       #" -ForegroundColor Red
        Write-Host "#                                     #" -ForegroundColor Red
        Write-Host "#       IF YOU ARE NOT DEVELOPING     #" -ForegroundColor Red
        Write-Host "#       JUST RUN \`Update-Profile\`     #" -ForegroundColor Red
        Write-Host "#        to discard all changes       #" -ForegroundColor Red
        Write-Host "#   and update to the latest profile  #" -ForegroundColor Red
        Write-Host "#               version               #" -ForegroundColor Red
        Write-Host "#######################################" -ForegroundColor Red
    }
}

if ($debug) {
    Debug-Message
}


# Opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Initial GitHub.com connectivity check
function Test-GitHubConnection {
    if ($PSVersionTable.PSEdition -eq "Core") {
        # If PowerShell Core, use a 1 second timeout
        return Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1
    } else {
        # For PowerShell Desktop, use .NET Ping class with timeout
        $ping = New-Object System.Net.NetworkInformation.Ping
        $result = $ping.Send("github.com", 1000)  # 1 second timeout
        return ($result.Status -eq "Success")
    }
}
$global:canConnectToGitHub = Test-GitHubConnection

# Import Modules and External Profiles
# Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# Safely read and parse the last execution date once to avoid exceptions when the file is missing or empty
$lastExecRaw = if (Test-Path $timeFilePath) { (Get-Content -Path $timeFilePath -Raw).Trim() } else { $null }
[Nullable[datetime]]$lastExec = $null
if (-not [string]::IsNullOrWhiteSpace($lastExecRaw)) {
    [datetime]$parsed = [datetime]::MinValue
    if ([datetime]::TryParseExact($lastExecRaw, 'yyyy-MM-dd', $null, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)) {
        $lastExec = $parsed
    }
}

# Check for Profile Updates
function Update-Profile {
    # If function "Update-Profile_Override" is defined in profile.ps1 file
    # then call it instead.
    if (Get-Command -Name "Update-Profile_Override" -ErrorAction SilentlyContinue) {
        Update-Profile_Override
    } else {
        try {
            $url = "$repo_root/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
            $oldhash = Get-FileHash $PROFILE
            Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
            $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
            if ($newhash.Hash -ne $oldhash.Hash) {
                Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
                Write-Host "Profile has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
            } else {
                Write-Host "Profile is up to date." -ForegroundColor Green
            }
        } catch {
            Write-Error "Unable to check for `$profile updates: $_"
        } finally {
            Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
        }
    }
}

# Check if not in debug mode AND (updateInterval is -1 OR file doesn't exist OR time difference is greater than the update interval)
if (-not $debug -and `
    ($updateInterval -eq -1 -or `
            -not (Test-Path $timeFilePath) -or `
            $null -eq $lastExec -or `
        ((Get-Date) - $lastExec).TotalDays -gt $updateInterval)) {

    Update-Profile
    $currentTime = Get-Date -Format 'yyyy-MM-dd'
    $currentTime | Out-File -FilePath $timeFilePath

} elseif ($debug) {
    Write-Warning "Skipping profile update check in debug mode"
}

function Update-PowerShell {
    # If function "Update-PowerShell_Override" is defined in profile.ps1 file
    # then call it instead.
    if (Get-Command -Name "Update-PowerShell_Override" -ErrorAction SilentlyContinue) {
        Update-PowerShell_Override
    } else {
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
                Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
                Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
            } else {
                Write-Host "Your PowerShell is up to date." -ForegroundColor Green
            }
        } catch {
            Write-Error "Failed to update PowerShell. Error: $_"
        }
    }
}

# skip in debug mode
# Check if not in debug mode AND (updateInterval is -1 OR file doesn't exist OR time difference is greater than the update interval)
if (-not $debug -and `
    ($updateInterval -eq -1 -or `
            -not (Test-Path $timeFilePath) -or `
            $null -eq $lastExec -or `
        ((Get-Date).Date - $lastExec.Date).TotalDays -gt $updateInterval)) {

    Update-PowerShell
    $currentTime = Get-Date -Format 'yyyy-MM-dd'
    $currentTime | Out-File -FilePath $timeFilePath
} elseif ($debug) {
    Write-Warning "Skipping PowerShell update in debug mode"
}

function Clear-Cache {
    # If function "Clear-Cache_Override" is defined in profile.ps1 file
    # then call it instead.
    # -----------------------------------------------------------------
    # If you do override this function, you should should probably duplicate
    # the following calls in your override function, just don't call this
    # function from your override function, otherwise you'll be in an infinate loop.
    if (Get-Command -Name "Clear-Cache_Override" -ErrorAction SilentlyContinue) {
        Clear-Cache_Override
    } else {
        # add clear cache logic here
        Write-Host "Clearing cache..." -ForegroundColor Cyan

        # Clear Windows Prefetch
        Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
        Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

        # Clear Windows Temp
        Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
        Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

        # Clear User Temp
        Write-Host "Clearing User Temp..." -ForegroundColor Yellow
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

        # Clear Internet Explorer Cache
        Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Cache clearing completed." -ForegroundColor Green
    }
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

# Editor Configuration
if ($EDITOR_Override){
    $EDITOR = $EDITOR_Override
} else {
    $EDITOR = if (Test-CommandExists nvim) { 'nvim' }
    elseif (Test-CommandExists pvim) { 'pvim' }
    elseif (Test-CommandExists vim) { 'vim' }
    elseif (Test-CommandExists vi) { 'vi' }
    elseif (Test-CommandExists code) { 'code' }
    elseif (Test-CommandExists codium) { 'codium' }
    elseif (Test-CommandExists notepad++) { 'notepad++' }
    elseif (Test-CommandExists sublime_text) { 'sublime_text' }
    else { 'notepad' }
    Set-Alias -Name vim -Value $EDITOR
}
# Quick Access to Editing the Profile
function Edit-Profile {
    vim $PROFILE.CurrentUserAllHosts
}
Set-Alias -Name ep -Value Edit-Profile

function Invoke-Profile {
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        Write-Host "Note: Some Oh My Posh/PSReadLine errors are expected in PowerShell 5. The profile still works fine." -ForegroundColor Yellow
    }
    & $PROFILE
}

function touch($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Network Utilities
function pubip { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# Open WinUtil full-release
function winutil {
    Invoke-Expression (Invoke-RestMethod https://christitus.com/win)
}

# Open WinUtil dev-release
function winutildev {
    # If function "WinUtilDev_Override" is defined in profile.ps1 file
    # then call it instead.
    if (Get-Command -Name "WinUtilDev_Override" -ErrorAction SilentlyContinue) {
        WinUtilDev_Override
    } else {
        Invoke-Expression (Invoke-RestMethod https://christitus.com/windev)
    }
}

# System Utilities
function admin {
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
Set-Alias -Name su -Value admin

function uptime {
    try {
        # find date/time format
        $dateFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.ShortDatePattern
        $timeFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.LongTimePattern

        # check powershell version
        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $lastBoot = (Get-WmiObject win32_operatingsystem).LastBootUpTime
            $bootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($lastBoot)

            # reformat lastBoot
            $lastBoot = $bootTime.ToString("$dateFormat $timeFormat")
        } else {
            # the Get-Uptime cmdlet was introduced in PowerShell 6.0
            $lastBoot = (Get-Uptime -Since).ToString("$dateFormat $timeFormat")
            $bootTime = [System.DateTime]::ParseExact($lastBoot, "$dateFormat $timeFormat", [System.Globalization.CultureInfo]::InvariantCulture)
        }

        # Format the start time
        $formattedBootTime = $bootTime.ToString("dddd, MMMM dd, yyyy HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture) + " [$lastBoot]"
        Write-Host "System started on: $formattedBootTime" -ForegroundColor DarkGray

        # calculate uptime
        $uptime = (Get-Date) - $bootTime

        # Uptime in days, hours, minutes, and seconds
        $days = $uptime.Days
        $hours = $uptime.Hours
        $minutes = $uptime.Minutes
        $seconds = $uptime.Seconds

        # Uptime output
        Write-Host ("Uptime: {0} days, {1} hours, {2} minutes, {3} seconds" -f $days, $hours, $minutes, $seconds) -ForegroundColor Blue

    } catch {
        Write-Error "An error occurred while retrieving system uptime."
    }
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

    $uri = "http://bin.christitus.com/documents"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $Content -ErrorAction Stop
        $hasteKey = $response.key
        $url = "http://bin.christitus.com/$hasteKey"
        Set-Clipboard $url
        Write-Output "$url copied to clipboard."
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

function trash($path) {
    $fullPath = (Resolve-Path -Path $path).Path

    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath

        if ($item.PSIsContainer) {
            # Handle directory
            $parentPath = $item.Parent.FullName
        } else {
            # Handle file
            $parentPath = $item.DirectoryName
        }

        $shell = New-Object -ComObject 'Shell.Application'
        $shellItem = $shell.NameSpace($parentPath).ParseName($item.Name)

        if ($item) {
            $shellItem.InvokeVerb('delete')
            Write-Host "Item '$fullPath' has been moved to the Recycle Bin."
        } else {
            Write-Host "Error: Could not find the item '$fullPath' to trash."
        }
    } else {
        Write-Host "Error: Item '$fullPath' does not exist."
    }
}

### Quality of Life Aliases

# Navigation Shortcuts
function docs {
    $docs = if(([Environment]::GetFolderPath("MyDocuments"))) {([Environment]::GetFolderPath("MyDocuments"))} else {$HOME + "\Documents"}
    Set-Location -Path $docs
}

function dtop {
    $dtop = if ([Environment]::GetFolderPath("Desktop")) {[Environment]::GetFolderPath("Desktop")} else {$HOME + "\Documents"}
    Set-Location -Path $dtop
}

# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing
function la { Get-ChildItem | Format-Table -AutoSize }
function ll { Get-ChildItem -Force | Format-Table -AutoSize }

# Git Shortcuts
function gs { git status }

function ga { git add . }

function gc { git commit }

function gcm { param($m) git commit -m "$m" }

function gcp { param($m) git commit -p -m "$m" }

function gcam {
    git add .
    git commit -m "$args"
}
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

function gd { git diff }

function gb { git branch "$args" }

function gbr { git branch -r "$args" }

function gco { git checkout "$args"

function glg { git log --oneline --graph } }

function gpsh { git push }

function gpll { git pull }

function g { __zoxide_z github }

function gcl { git clone "$args" }

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

# Set-PSReadLineOption Compatibility for PowerShell Desktop
function Set-PSReadLineOptionsCompat {
    param([hashtable]$Options)
    if ($PSVersionTable.PSEdition -eq "Core") {
        Set-PSReadLineOption @Options
    } else {
        # Remove unsupported keys for Desktop and silence errors
        $SafeOptions = $Options.Clone()
        $SafeOptions.Remove('PredictionSource')
        $SafeOptions.Remove('PredictionViewStyle')
        Set-PSReadLineOption @SafeOptions
    }
}

# Enhanced PowerShell Experience
# Enhanced PSReadLine Configuration
$PSReadLineOptions = @{
    EditMode = 'Windows'
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    Colors = @{
        Command = '#87CEEB'  # SkyBlue (pastel)
        Parameter = '#98FB98'  # PaleGreen (pastel)
        Operator = '#FFB6C1'  # LightPink (pastel)
        Variable = '#DDA0DD'  # Plum (pastel)
        String = '#FFDAB9'  # PeachPuff (pastel)
        Number = '#B0E0E6'  # PowderBlue (pastel)
        Type = '#F0E68C'  # Khaki (pastel)
        Comment = '#D3D3D3'  # LightGray (pastel)
        Keyword = '#8367c7'  # Violet (pastel)
        Error = '#FF6347'  # Tomato (keeping it close to red for visibility)
    }
    PredictionSource = 'History'
    PredictionViewStyle = 'ListView'
    BellStyle = 'None'
}
Set-PSReadLineOptionsCompat -Options $PSReadLineOptions

# Custom key handlers
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

# Custom functions for PSReadLine
Set-PSReadLineOption -AddToHistoryHandler {
    param($line)
    $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
    $hasSensitive = $sensitive | Where-Object { $line -match $_ }
    return ($null -eq $hasSensitive)
}

# Fix Set-PredictionSource for Desktop
function Set-PredictionSource {
    # If "Set-PredictionSource_Override" is defined in profile.ps1 file
    # then call it instead.
    if (Get-Command -Name "Set-PredictionSource_Override" -ErrorAction SilentlyContinue) {
        Set-PredictionSource_Override
    } elseif ($PSVersionTable.PSEdition -eq "Core") {
        # Improved prediction settings
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -MaximumHistoryCount 10000
    } else {
        # Desktop version - use History only
        Set-PSReadLineOption -MaximumHistoryCount 10000
    }
}
Set-PredictionSource

# Custom completion for common commands
$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    $customCompletions = @{
        'git' = @('status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout')
        'bun' = @('install', 'start', 'run', 'test', 'build', 'add')
        'npm' = @('install', 'start', 'run', 'test', 'build')
        'deno' = @('run', 'compile', 'bundle', 'test', 'lint', 'fmt', 'cache', 'info', 'doc', 'upgrade')
    }

    $command = $commandAst.CommandElements[0].Value
    if ($customCompletions.ContainsKey($command)) {
        $customCompletions[$command] | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}
Register-ArgumentCompleter -Native -CommandName git, bun, npm, deno -ScriptBlock $scriptblock

$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    dotnet complete --position $cursorPosition $commandAst.ToString() |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock

# If function "Get-Theme_Override" is defined in profile.ps1 file
# then call it instead.
if (Get-Command -Name "Get-Theme_Override" -ErrorAction SilentlyContinue) {
    Get-Theme_Override
} else {
    # Oh My Posh initialization with local theme fallback and auto-download
    $localThemePath = Join-Path (Get-ProfileDir) "posh-theme-thomaskrol.omp.json"
    $themeUrl = "https://gist.githubusercontent.com/thomaskrol/b5339a5a72b095d69134e2591ba9f6ea/raw/0b3dd9cbe75438fcc69de13e8b9b79dcce20f390/posh-theme-thomaskrol.omp.json"
    if (-not (Test-Path $localThemePath)) {
        # Try to download the theme file to the detected local path
        try {
            Invoke-RestMethod -Uri $themeUrl -OutFile $localThemePath
            Write-Host "Downloaded missing Oh My Posh theme to $localThemePath"
        } catch {
            Write-Warning "Failed to download theme file. Falling back to remote theme. Error: $_"
        }
    }
    if (Test-Path $localThemePath) {
        oh-my-posh init pwsh --config $localThemePath | Invoke-Expression
    } else {
        # Fallback to remote theme if local file doesn't exist
        oh-my-posh init pwsh --config $themeUrl | Invoke-Expression
    }
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
} else {
    Write-Host "zoxide command not found. Attempting to install via winget..."
    try {
        winget install -e --id ajeetdsouza.zoxide
        Write-Host "zoxide installed successfully. Initializing..."
        Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
    } catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
}

# Help Function
function Show-Help {
    $helpText = @"
$($PSStyle.Foreground.Cyan)PowerShell Profile Help$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)

$($PSStyle.Foreground.Cyan)Profile Management$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)Edit-Profile$($PSStyle.Reset) / $($PSStyle.Foreground.Green)ep$($PSStyle.Reset) - Opens profile in editor

$($PSStyle.Foreground.Green)Update-Profile$($PSStyle.Reset) - Checks & downloads latest profile from repository

$($PSStyle.Foreground.Green)Update-PowerShell$($PSStyle.Reset) - Checks & updates to latest PowerShell release

$($PSStyle.Foreground.Green)Invoke-Profile$($PSStyle.Reset) - Reloads profile

$($PSStyle.Foreground.Green)Clear-Cache$($PSStyle.Reset) - Clears Windows/temp/browser cache files

$($PSStyle.Foreground.Cyan)Git Commands$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)g$($PSStyle.Reset) - Jump to github directory | i.e. zoxide jump github

$($PSStyle.Foreground.Green)gs$($PSStyle.Reset) - Show repo status | i.e. git status

$($PSStyle.Foreground.Green)ga$($PSStyle.Reset) - Stage all changes | i.e. git add .

$($PSStyle.Foreground.Green)gc$($PSStyle.Reset) <msg> - Commit (interactive) | i.e. git commit

$($PSStyle.Foreground.Green)gcm$($PSStyle.Reset) <msg> - Commit with message | i.e. git commit -m <msg>

$($PSStyle.Foreground.Green)gcp$($PSStyle.Reset) <msg> - Commit patches with message | i.e. git commit -p -m <msg>

$($PSStyle.Foreground.Green)gcam$($PSStyle.Reset) <msg> - Stage & commit all with message | i.e. git add . && git commit -m <msg>

$($PSStyle.Foreground.Green)gd$($PSStyle.Reset) - Show diff | i.e. git diff

$($PSStyle.Foreground.Green)gb$($PSStyle.Reset) [name] - List or create branch | i.e. git branch [name]

$($PSStyle.Foreground.Green)gbr$($PSStyle.Reset) [name] - List remote branches | i.e. git branch -r [name]

$($PSStyle.Foreground.Green)gco$($PSStyle.Reset) <branch> - Switch branch | i.e. git checkout <branch>

$($PSStyle.Foreground.Green)glg$($PSStyle.Reset) - Pretty log graph | i.e. git log --oneline --graph

$($PSStyle.Foreground.Green)gpsh$($PSStyle.Reset) - Push changes | i.e. git push

$($PSStyle.Foreground.Green)gpll$($PSStyle.Reset) - Pull changes | i.e. git pull

$($PSStyle.Foreground.Green)gcl$($PSStyle.Reset) <repo> - Clone repository | i.e. git clone <repo>

$($PSStyle.Foreground.Green)lazyg$($PSStyle.Reset) <msg> - Stage, commit & push all with message | i.e. git add . && git commit -m <msg> && git push

$($PSStyle.Foreground.Cyan)File & Directory Management$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)touch$($PSStyle.Reset) <file> - Create empty file | i.e. "" | Out-File <file>

$($PSStyle.Foreground.Green)nf$($PSStyle.Reset) <name> - Create new file | i.e. New-Item -ItemType file -Name <name>

$($PSStyle.Foreground.Green)ff$($PSStyle.Reset) <name> - Find files recursively | i.e. Get-ChildItem -Recurse -Filter *<name>*

$($PSStyle.Foreground.Green)mkcd$($PSStyle.Reset) <dir> - Create & enter directory | i.e. mkdir <dir> && cd <dir>

$($PSStyle.Foreground.Green)unzip$($PSStyle.Reset) <file> - Extract zip file | i.e. Expand-Archive <file> -DestinationPath .

$($PSStyle.Foreground.Green)trash$($PSStyle.Reset) <path> - Move to recycle bin | i.e. Shell.Application InvokeVerb delete

$($PSStyle.Foreground.Cyan)Navigation Shortcuts$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)docs$($PSStyle.Reset) - Go to Documents folder | i.e. cd [Environment]::GetFolderPath("MyDocuments")

$($PSStyle.Foreground.Green)dtop$($PSStyle.Reset) - Go to Desktop folder | i.e. cd [Environment]::GetFolderPath("Desktop")

$($PSStyle.Foreground.Cyan)System & Process Management$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)admin$($PSStyle.Reset) / $($PSStyle.Foreground.Green)su$($PSStyle.Reset) [cmd] - Elevate privileges | i.e. Start-Process -Verb runAs

$($PSStyle.Foreground.Green)uptime$($PSStyle.Reset) - Show system uptime since boot

$($PSStyle.Foreground.Green)k9$($PSStyle.Reset) <process> - Kill process by name | i.e. Stop-Process -Name <process>

$($PSStyle.Foreground.Green)pkill$($PSStyle.Reset) <pattern> - Stop processes by name | i.e. Get-Process <pattern> | Stop-Process

$($PSStyle.Foreground.Green)pgrep$($PSStyle.Reset) <pattern> - List processes by name | i.e. Get-Process <pattern>

$($PSStyle.Foreground.Cyan)File & Text Operations$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)grep$($PSStyle.Reset) <regex> [dir] - Search files for pattern | i.e. select-string <regex>

$($PSStyle.Foreground.Green)sed$($PSStyle.Reset) <file> <find> <replace> - Replace text in file | i.e. (Get-Content).replace() | Set-Content

$($PSStyle.Foreground.Green)head$($PSStyle.Reset) <path> [n] - Show first n lines (def: 10) | i.e. Get-Content -Head

$($PSStyle.Foreground.Green)tail$($PSStyle.Reset) <path> [n] - Show last n lines (def: 10) | i.e. Get-Content -Tail

$($PSStyle.Foreground.Green)which$($PSStyle.Reset) <name> - Show command path | i.e. Get-Command -ExpandProperty Definition

$($PSStyle.Foreground.Cyan)Directory & File Listing$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)la$($PSStyle.Reset) - List files formatted | i.e. Get-ChildItem | Format-Table

$($PSStyle.Foreground.Green)ll$($PSStyle.Reset) - List all files incl. hidden | i.e. Get-ChildItem -Force | Format-Table

$($PSStyle.Foreground.Cyan)System Information$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)sysinfo$($PSStyle.Reset) - System info details | i.e. Get-ComputerInfo

$($PSStyle.Foreground.Green)df$($PSStyle.Reset) - Volume information | i.e. Get-Volume

$($PSStyle.Foreground.Cyan)Network & Utilities$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)pubip$($PSStyle.Reset) - Get public IP | i.e. Invoke-WebRequest http://ifconfig.me/ip

$($PSStyle.Foreground.Green)flushdns$($PSStyle.Reset) - Clear DNS cache | i.e. Clear-DnsClientCache

$($PSStyle.Foreground.Green)cpy$($PSStyle.Reset) <text> - Copy to clipboard | i.e. Set-Clipboard <text>

$($PSStyle.Foreground.Green)pst$($PSStyle.Reset) - Get clipboard text | i.e. Get-Clipboard

$($PSStyle.Foreground.Cyan)Advanced Utilities$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)hb$($PSStyle.Reset) <file> - Upload file to hastebin service

$($PSStyle.Foreground.Green)export$($PSStyle.Reset) <name> <value> - Set env variable | i.e. \$env <name> = <value>

$($PSStyle.Foreground.Cyan)External Tools$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)winutil$($PSStyle.Reset) - Launch Chris Titus WinUtil (full release)

$($PSStyle.Foreground.Green)winutildev$($PSStyle.Reset) - Launch Chris Titus WinUtil (dev/pre-release)

$($PSStyle.Foreground.Cyan)Aliases$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)vim$($PSStyle.Reset) - Configured editor | i.e. \$EDITOR (nvim/vim/code/etc)

$($PSStyle.Foreground.Green)su$($PSStyle.Reset) - Admin privilege escalation | i.e. admin

$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
Type '$($PSStyle.Foreground.Magenta)Show-Help$($PSStyle.Reset)' anytime to display this help.
"@
    Write-Host $helpText
}

if (Test-Path "$PSScriptRoot\CTTcustom.ps1") {
    Invoke-Expression -Command "& `"$PSScriptRoot\CTTcustom.ps1`""
}

Write-Host "$($PSStyle.Foreground.Yellow)Use 'Show-Help' to display help$($PSStyle.Reset)"
