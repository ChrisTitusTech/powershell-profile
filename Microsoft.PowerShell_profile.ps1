### PowerShell Profile Refactor
### Version 1.03 - Refactored

#################################################################################################################################
############                                                                                                         ############
############                                          !!!   WARNING:   !!!                                           ############
############                                                                                                         ############
############                DO NOT MODIFY THIS FILE. THIS FILE IS HASHED AND UPDATED AUTOMATICALLY.                  ############
############                    ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN BY COMMITS TO                      ############
############                       https://github.com/the-sudipta/powershell-profile.git                             ############
############                                                                                                         ############
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
############                                                                                                         ############
############                      IF YOU WANT TO MAKE CHANGES, USE THE Edit-Profile FUNCTION                         ############
############                              AND SAVE YOUR CHANGES IN THE FILE CREATED.                                 ############
############                                                                                                         ############
#################################################################################################################################

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/stelbent-compact.minimal.omp.json" | Invoke-Expression

Import-Module -Name Terminal-Icons

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# Define the animation characters
$animationChars = @('|', '/', '-', '\')

# Set the duration for the animation
$duration = 2  # Total time to run the animation (in seconds)
$endTime = (Get-Date).AddSeconds($duration)

# Hide the cursor
[Console]::CursorVisible = $false

# Loop until the duration is reached
while ((Get-Date) -lt $endTime) {
    foreach ($char in $animationChars) {
        # Clear the line and write the current animation character
        Write-Host -NoNewline "`r$char"

        # Pause for a short duration to control the speed of the animation
        Start-Sleep -Milliseconds 100

        # Check if the time is up to break out of the loop
        if ((Get-Date) -ge $endTime) {
            break
        }
    }
}

# Show the cursor again after the animation ends
[Console]::CursorVisible = $true

# Clear the last character after the animation
clear


# ###################################### Linux Customization

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

# Network Utilities
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

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


function grep($regex, $dir) {
    if ($dir) {
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

# Enhanced PowerShell Experience
# Set color options for PSReadLine
Set-PSReadLineOption -Colors @{
    Command = 'Yellow'
    Parameter = 'Green'
    String = 'DarkCyan'
    Keyword = 'Magenta'
    Operator = 'Cyan'
}

# Set continuation prompt
Set-PSReadLineOption -ContinuationPrompt '  '

# Set key handlers for navigation
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Enter' -Function ValidateAndAcceptLine

# Argument completer for dotnet
$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    dotnet complete --position $cursorPosition $commandAst.ToString() |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock

# Help Function
function Show-Help {
    Write-Host "Available Commands:" -ForegroundColor Cyan
    Write-Host "----------------------------"

    # Display each function with a brief description of its purpose, using different colors
    Write-Host -NoNewline "prompt               " -ForegroundColor Yellow
    Write-Host "- Customizes command prompt based on admin status" -ForegroundColor Gray
    Write-Host -NoNewline "Test-CommandExists   " -ForegroundColor Yellow
    Write-Host "- Checks if a command is available" -ForegroundColor Gray
    Write-Host -NoNewline "Edit-Profile         " -ForegroundColor Yellow
    Write-Host "- Opens the PowerShell profile for editing" -ForegroundColor Gray
    Write-Host -NoNewline "touch                " -ForegroundColor Yellow
    Write-Host "- Creates an empty file" -ForegroundColor Gray
    Write-Host -NoNewline "ff                   " -ForegroundColor Yellow
    Write-Host "- Finds files recursively by name" -ForegroundColor Gray
    Write-Host -NoNewline "Get-PubIP            " -ForegroundColor Yellow
    Write-Host "- Retrieves public IP address" -ForegroundColor Gray
    Write-Host -NoNewline "winutil              " -ForegroundColor Yellow
    Write-Host "- Runs Windows utilities script from Christ Titus" -ForegroundColor Gray
    Write-Host -NoNewline "admin                " -ForegroundColor Yellow
    Write-Host "- Runs a command with elevated rights" -ForegroundColor Gray
    Write-Host -NoNewline "uptime               " -ForegroundColor Yellow
    Write-Host "- Shows system uptime" -ForegroundColor Gray
    Write-Host -NoNewline "reload-profile       " -ForegroundColor Yellow
    Write-Host "- Reloads PowerShell profile" -ForegroundColor Gray
    Write-Host -NoNewline "unzip                " -ForegroundColor Yellow
    Write-Host "- Extracts a zip file" -ForegroundColor Gray
    Write-Host -NoNewline "grep                 " -ForegroundColor Yellow
    Write-Host "- Searches for text matching a regex" -ForegroundColor Gray
    Write-Host -NoNewline "df                   " -ForegroundColor Yellow
    Write-Host "- Displays free disk space" -ForegroundColor Gray
    Write-Host -NoNewline "sed                  " -ForegroundColor Yellow
    Write-Host "- Replaces text in a file" -ForegroundColor Gray
    Write-Host -NoNewline "which                " -ForegroundColor Yellow
    Write-Host "- Finds location of a command" -ForegroundColor Gray
    Write-Host -NoNewline "export               " -ForegroundColor Yellow
    Write-Host "- Sets environment variable" -ForegroundColor Gray
    Write-Host -NoNewline "pkill                " -ForegroundColor Yellow
    Write-Host "- Kills processes by name" -ForegroundColor Gray
    Write-Host -NoNewline "pgrep                " -ForegroundColor Yellow
    Write-Host "- Searches for processes by name" -ForegroundColor Gray
    Write-Host -NoNewline "head                 " -ForegroundColor Yellow
    Write-Host "- Shows the first lines of a file" -ForegroundColor Gray
    Write-Host -NoNewline "tail                 " -ForegroundColor Yellow
    Write-Host "- Shows the last lines of a file" -ForegroundColor Gray
    Write-Host -NoNewline "nf                   " -ForegroundColor Yellow
    Write-Host "- Creates a new file" -ForegroundColor Gray
    Write-Host -NoNewline "mkcd                 " -ForegroundColor Yellow
    Write-Host "- Creates and navigates to a directory" -ForegroundColor Gray
    Write-Host -NoNewline "docs                 " -ForegroundColor Yellow
    Write-Host "- Navigates to the Documents folder" -ForegroundColor Gray
    Write-Host -NoNewline "dtop                 " -ForegroundColor Yellow
    Write-Host "- Navigates to the Desktop folder" -ForegroundColor Gray
    Write-Host -NoNewline "ep                   " -ForegroundColor Yellow
    Write-Host "- Edits PowerShell profile" -ForegroundColor Gray
    Write-Host -NoNewline "k9                   " -ForegroundColor Yellow
    Write-Host "- Kills a process by name" -ForegroundColor Gray
    Write-Host -NoNewline "la                   " -ForegroundColor Yellow
    Write-Host "- Lists all files in current directory" -ForegroundColor Gray
    Write-Host -NoNewline "ll                   " -ForegroundColor Yellow
    Write-Host "- Lists all files with hidden ones" -ForegroundColor Gray
    Write-Host -NoNewline "gs                   " -ForegroundColor Yellow
    Write-Host "- Git status" -ForegroundColor Gray
    Write-Host -NoNewline "ga                   " -ForegroundColor Yellow
    Write-Host "- Git add all changes" -ForegroundColor Gray
    Write-Host -NoNewline "gc                   " -ForegroundColor Yellow
    Write-Host "- Git commit with message" -ForegroundColor Gray
    Write-Host -NoNewline "gp                   " -ForegroundColor Yellow
    Write-Host "- Git push" -ForegroundColor Gray
    Write-Host -NoNewline "g                    " -ForegroundColor Yellow
    Write-Host "- Navigates to GitHub directory" -ForegroundColor Gray
    Write-Host -NoNewline "gcl                  " -ForegroundColor Yellow
    Write-Host "- Git clone repository" -ForegroundColor Gray
    Write-Host -NoNewline "gcom                 " -ForegroundColor Yellow
    Write-Host "- Git command placeholder" -ForegroundColor Gray
    Write-Host -NoNewline "lazyg                " -ForegroundColor Yellow
    Write-Host "- Lazygit shortcut" -ForegroundColor Gray
    Write-Host -NoNewline "sysinfo              " -ForegroundColor Yellow
    Write-Host "- Shows computer information" -ForegroundColor Gray
    Write-Host -NoNewline "flushdns             " -ForegroundColor Yellow
    Write-Host "- Flushes DNS cache" -ForegroundColor Gray
    Write-Host -NoNewline "cpy                  " -ForegroundColor Yellow
    Write-Host "- Copies text to clipboard" -ForegroundColor Gray
    Write-Host -NoNewline "pst                  " -ForegroundColor Yellow
    Write-Host "- Pastes text from clipboard" -ForegroundColor Gray
    Write-Host -NoNewline "add                  " -ForegroundColor Yellow
    Write-Host "- Placeholder function for adding items" -ForegroundColor Gray
    Write-Host -NoNewline "del                  " -ForegroundColor Yellow
    Write-Host "- Placeholder function for deleting items" -ForegroundColor Gray
    Write-Host -NoNewline "move                 " -ForegroundColor Yellow
    Write-Host "- Placeholder function for moving items" -ForegroundColor Gray
    Write-Host -NoNewline "ls-hidden            " -ForegroundColor Yellow
    Write-Host "- Lists hidden files in current directory" -ForegroundColor Gray
    Write-Host -NoNewline "hide                 " -ForegroundColor Yellow
    Write-Host "- Hides files" -ForegroundColor Gray
    Write-Host -NoNewline "unhide               " -ForegroundColor Yellow
    Write-Host "- Unhides files" -ForegroundColor Gray
    Write-Host -NoNewline "gh-sugg              " -ForegroundColor Yellow
    Write-Host "- GitHub suggestion command" -ForegroundColor Gray
    Write-Host -NoNewline "gh-expl              " -ForegroundColor Yellow
    Write-Host "- GitHub exploration command" -ForegroundColor Gray
    Write-Host -NoNewline "gh-conf              " -ForegroundColor Yellow
    Write-Host "- GitHub configuration command" -ForegroundColor Gray
    Write-Host -NoNewline "gh-alias             " -ForegroundColor Yellow
    Write-Host "- GitHub alias command" -ForegroundColor Gray
    Write-Host -NoNewline "Get-Installed        " -ForegroundColor Yellow
    Write-Host "- Lists installed programs" -ForegroundColor Gray
    Write-Host -NoNewline "Export-Installed     " -ForegroundColor Yellow
    Write-Host "- Exports list of installed programs" -ForegroundColor Gray
    Write-Host -NoNewline "Show-Processes       " -ForegroundColor Yellow
    Write-Host "- Lists active processes" -ForegroundColor Gray
    Write-Host -NoNewline "Kill-ID              " -ForegroundColor Yellow
    Write-Host "- Kills process by ID" -ForegroundColor Gray
    Write-Host -NoNewline "Search-Processes     " -ForegroundColor Yellow
    Write-Host "- Searches for processes by name" -ForegroundColor Gray
    Write-Host -NoNewline "Show-Tree     " -ForegroundColor Yellow
    Write-Host "- Display the folder and file structure from the current directory" -ForegroundColor Gray

    Write-Host "----------------------------"
    Write-Host "Use 'FunctionName -help' for more details on each command."
}


# Function to add a file or folder in the current directory
function add {
    param($Name)

    # Check if the name contains an extension
    if ($Name -like "*.*") {
        # Create a file
        New-Item -ItemType File -Path (Join-Path -Path (Get-Location) -ChildPath $Name) -Force
    } else {
        # Create a folder
        New-Item -ItemType Directory -Path (Join-Path -Path (Get-Location) -ChildPath $Name) -Force
    }
}

# Function to delete a file or folder in the current directory
function del {
    param($Name)

    # Combine path with current directory
    $Path = Join-Path -Path (Get-Location) -ChildPath $Name

    # Remove the item if it exists
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
    } else {
        Write-Host "Item '$Name' not found in the current directory."
    }
}

# Function to move a file or folder to a destination
function move {
    param(
        [string]$Name,
        [string]$Destination
    )

    # Combine path with current directory
    $Path = Join-Path -Path (Get-Location) -ChildPath $Name

    # Move the item if it exists
    if (Test-Path $Path) {
        Move-Item -Path $Path -Destination $Destination -Force
    } else {
        Write-Host "Item '$Name' not found in the current directory."
    }
}


# Fucntion to show show hidden folders and files like .git
function ls-hidden {
    Get-ChildItem -Force | Where-Object { $_.Attributes -match 'Hidden' }
}


# Function to hide specific files or folders or all items in the current directory
function hide {
    param (
        [string]$name = ""
    )

    if (-not [string]::IsNullOrEmpty($name)) {
        # Hide specific file or folder
        $itemPath = Join-Path -Path (Get-Location) -ChildPath $name
        $item = Get-Item -Path $itemPath -ErrorAction SilentlyContinue
        if ($item) {
            # Apply attributes to hide
            attrib +h +s +r +x $item.FullName
            Write-Host "Hidden: $name"
        } else {
            Write-Host "Item not found: $name"
        }
    } else {
        # Hide all files and folders in the current directory
        Get-ChildItem -Force | ForEach-Object {
            attrib +h +s +r +x $_.FullName
        }
        Write-Host "All items in the current directory are now hidden."
    }
}

# Function to unhide specific files or folders or all items in the current directory
function unhide {
    param (
        [string]$name = ""
    )

    if (-not [string]::IsNullOrEmpty($name)) {
        # Unhide specific file or folder by searching for hidden items
        $itemPath = Join-Path -Path (Get-Location) -ChildPath $name
        $item = Get-ChildItem -Path (Get-Location) -Filter $name -Force -ErrorAction SilentlyContinue
        if ($item) {
            # Remove attributes to unhide
            foreach ($i in $item) {
                attrib -h -s -r -x $i.FullName
                Write-Host "Unhidden: $($i.Name)"
            }
        } else {
            Write-Host "Item not found: $name"
        }
    } else {
        # Unhide all files and folders in the current directory
        Get-ChildItem -Force | ForEach-Object {
            attrib -h -s -r -x $_.FullName
        }
        Write-Host "All items in the current directory are now unhidden."
    }
}

# Function to suggest a Git command using GitHub Copilot
function gh-sugg {
    param(
        [string]$command
    )
    gh copilot suggest $command
}

# Function to explain a Git command using GitHub Copilot
function gh-expl {
    param(
        [string]$command
    )
    gh copilot explain $command
}

# Function to configure GitHub Copilot options
function gh-conf {
    param(
        [string]$option,
        [string]$value
    )
    gh copilot config $option $value
}

# Function to generate aliases for GitHub Copilot
function gh-alias {
    gh copilot alias
}


# Function to View all the softwares installed in the machine
function Get-Installed {
    # Lists all installed items using Winget and displays them on the console
    winget list
}

# Function to Export all the softwares installed in the machine
function Export-Installed {
    # Lists all installed items using Winget
    $installedItems = winget list

    # Prompts user for file name and extension
    $fileName = Read-Host "Enter the file name with extension (e.g., All Intstalled Items.txt)"
    
    # Writes the list to the file
    $installedItems | Out-File -FilePath $fileName
    
    # Display the file location
    Write-Host "The list has been saved to $fileName"
}


# Function to display all processes as a numbered list
function Show-Processes {
    $global:processList = Get-Process | Select-Object -Property Id, ProcessName
    $i = 1
    $processList | ForEach-Object {
        Write-Output "$i. ProcessName: $($_.ProcessName), Id: $($_.Id)"
        $i++
    }
}


# Function to kill all processes with the same name by selecting its number from the numbered list
function Kill-ID {
    param (
        [int]$processNumber
    )

    # Check if running as Administrator
    $isAdmin = ([System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Output "Please run the Terminal as Administrator to use this command."
        return
    }

    # Validate the process number
    if ($processNumber -le 0 -or $processNumber -gt $processList.Count) {
        Write-Output "Invalid process number."
        return
    }

    # Get the process name from the selected item in the list
    $processName = $processList[$processNumber - 1].ProcessName
    $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue

    # Attempt to terminate all processes with that name
    if ($processes) {
        foreach ($proc in $processes) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                Write-Output "Process with ID $($proc.Id) and Name $processName has been killed."
            } catch {
                Write-Output "Failed to kill process with ID $($proc.Id). Reason: $($_.Exception.Message)"
            }
        }

        # Final check to confirm all processes are terminated
        Start-Sleep -Seconds 1
        if (Get-Process -Name $processName -ErrorAction SilentlyContinue) {
            Write-Output "Some processes with the name $processName are still running. They might be restarting automatically or protected by the system."
        } else {
            Write-Output "All processes with the name $processName have been successfully terminated."
        }
    } else {
        Write-Output "No processes found with the name $processName."
    }
}


# Function to search and list all processes by name (case-insensitive)
function Search-Processes {
    param (
        [string]$processName
    )

    # Ensure the process name parameter is provided
    if (-not $processName) {
        Write-Output "Please specify a process name to search for."
        return
    }

    # Get all processes that match the provided name, case-insensitively
    $matchingProcesses = Get-Process | Where-Object { $_.ProcessName -like "$processName" -or $_.ProcessName -match "^$processName$" -and $_.ProcessName -match "$processName" }

    # Check if any matching processes were found
    if ($matchingProcesses) {
        Write-Output "Processes matching '$processName':"
        $matchingProcesses | ForEach-Object { 
            Write-Output "Process Name: $($_.ProcessName), Process ID: $($_.Id)" 
        }
    } else {
        Write-Output "No processes found with the name '$processName'."
    }
}

function Show-Tree {
    param (
        [string]$Path = (Get-Location),
        [int]$Depth = 2,  # Default depth to avoid excessive output
        [string]$Indent = ""
    )

    # Get directories and files
    $items = Get-ChildItem -Path $Path | Sort-Object PSIsContainer -Descending

    foreach ($item in $items) {
        $prefix = ""
        if ($item.PSIsContainer) {
            $prefix = [char]::ConvertFromUtf32(0x1F4C1)  # 📁 Folder
        } else {
            $prefix = [char]::ConvertFromUtf32(0x1F4C4)  # 📄 File
        }

        Write-Host "$Indent|-- $prefix $($item.Name)" -ForegroundColor Cyan

        if ($item.PSIsContainer -and $Depth -gt 0) {
            Show-Tree -Path $item.FullName -Depth ($Depth - 1) -Indent ("$Indent|   ")
        }
    }
}

function write-file {
    param(
        [string]$FileName
    )
    
    # Resolve full path of the file
    $FullPath = Resolve-Path -Path $FileName -ErrorAction SilentlyContinue
    
    if ($FullPath) {
        # Path to Sublime Text executable
        $SublimePath = "E:\Yaarian\Download_Software_Installation_Folder\Sublime Text 3\Sublime Text\sublime_text.exe"
        
        # Open the file in Sublime Text
        Start-Process -FilePath $SublimePath -ArgumentList $FullPath
    } else {
        Write-Host "File not found: $FileName" -ForegroundColor Red
    }
}



# Load the profile once
# Show-Help

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/stelbent-compact.minimal.omp.json" | Invoke-Expression


