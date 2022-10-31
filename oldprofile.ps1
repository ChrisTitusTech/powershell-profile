### PowerShell template profile 
### Version 1.03 - Tim Sneath <tim@sneath.org>
### From https://gist.github.com/timsneath/19867b12eee7fd5af2ba
###
### This file should be stored in $PROFILE.CurrentUserAllHosts
### If $PROFILE.CurrentUserAllHosts doesn't exist, you can make one with the following:
###    PS> New-Item $PROFILE.CurrentUserAllHosts -ItemType File -Force
### This will create the file and the containing subdirectory if it doesn't already 
###
### As a reminder, to enable unsigned script execution of local scripts on client Windows, 
### you need to run this line (or similar) from an elevated PowerShell prompt:
###   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
### This is the default policy on Windows Server 2012 R2 and above for server Windows. For 
### more information about execution policies, run Get-Help about_Execution_Policies.

# Find out if the current user identity is elevated (has admin rights)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If so and the current host is a command line, then change to red color 
# as warning to user that they are operating in an elevated context
# Useful shortcuts for traversing directories
function cd...  { cd ..\.. }
function cd.... { cd ..\..\.. }

# Compute file hashes - useful for checking successful downloads 
function md5    { Get-FileHash -Algorithm MD5 $args }
function sha1   { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }

# Quick shortcut to start notepad
function n      { notepad $args }

# Drive shortcuts
function HKLM:  { Set-Location HKLM: }
function HKCU:  { Set-Location HKCU: }
function Env:   { Set-Location Env: }

# Creates drive shortcut for Work Folders, if current user account is using it
if (Test-Path "$env:USERPROFILE\Work Folders")
{
    New-PSDrive -Name Work -PSProvider FileSystem -Root "$env:USERPROFILE\Work Folders" -Description "Work Folders"
    function Work: { Set-Location Work: }
}

# Set up command prompt and window title. Use UNIX-style convention for identifying 
# whether user is elevated (root) or not. Window title shows current version of PowerShell
# and appends [ADMIN] if appropriate for easy taskbar identification
function prompt 
{ 
    if ($isAdmin) 
    {
        "[" + (Get-Location) + "] # " 
    }
    else 
    {
        "[" + (Get-Location) + "] $ "
    }
}

$Host.UI.RawUI.WindowTitle = "PowerShell {0}" -f $PSVersionTable.PSVersion.ToString()
if ($isAdmin)
{
    $Host.UI.RawUI.WindowTitle += " [ADMIN]"
}

# Does the the rough equivalent of dir /s /b. For example, dirs *.png is dir /s /b *.png
function dirs
{
    if ($args.Count -gt 0)
    {
        Get-ChildItem -Recurse -Include "$args" | Foreach-Object FullName
    }
    else
    {
        Get-ChildItem -Recurse | Foreach-Object FullName
    }
}

# Simple function to start a new elevated process. If arguments are supplied then 
# a single command is started with admin rights; if not then a new admin instance
# of PowerShell is started.
function admin
{
    if ($args.Count -gt 0)
    {   
       $argList = "& '" + $args + "'"
       Start-Process "$psHome\powershell.exe" -Verb runAs -ArgumentList $argList
    }
    else
    {
       Start-Process "$psHome\powershell.exe" -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command
# with elevated rights. 
Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin


# Make it easy to edit this profile once it's installed
function Edit-Profile
{
    if ($host.Name -match "ise")
    {
        $psISE.CurrentPowerShellTab.Files.Add($profile.CurrentUserAllHosts)
    }
    else
    {
        notepad $profile.CurrentUserAllHosts
    }
}

# We don't need these any more; they were just temporary variables to get to $isAdmin. 
# Delete them to prevent cluttering up the user profile. 
Remove-Variable identity
Remove-Variable principal
#
# Aliases
#
New-Alias vim nvim
function ll { Get-ChildItem -Path $pwd -File }
function g { cd $HOME\Documents\Github }
function gcom
{
	git add .
	git commit -m "$args"
}
function lazyg
{
	git add .
	git commit -m "$args"
	git push
}
Function Get-PubIP {
 (Invoke-WebRequest http://ifconfig.me/ip ).Content
}
function uptime {
        Get-WmiObject win32_operatingsystem | select csname, @{LABEL='LastBootUpTime';
        EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
}
function reload-profile {
        & $profile
}
function find-file($name) {
        ls -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | foreach {
                $place_path = $_.directory
                echo "${place_path}\${_}"
        }
}
function unzip ($file) {
        echo("Extracting", $file, "to", $pwd)
	$fullFile = Get-ChildItem -Path $pwd -Filter .\cove.zip | ForEach-Object{$_.FullName}
        Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function grep($regex, $dir) {
        if ( $dir ) {
                ls $dir | select-string $regex
                return
        }
        $input | select-string $regex
}
function touch($file) {
        "" | Out-File $file -Encoding ASCII
}
function df {
        get-volume
}
function sed($file, $find, $replace){
        (Get-Content $file).replace("$find", $replace) | Set-Content $file
}
function which($name) {
        Get-Command $name | Select-Object -ExpandProperty Definition
}
function export($name, $value) {
        set-item -force -path "env:$name" -value $value;
}
function pkill($name) {
        ps $name -ErrorAction SilentlyContinue | kill
}
function pgrep($name) {
        ps $name
}


## Final Line to set prompt
oh-my-posh --init --shell pwsh --config ~/jandedobbeleer.omp.json | Invoke-Expression
