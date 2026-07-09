### Chris Titus Tech's PowerShell profile

$script:ProfileRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $PROFILE.CurrentUserCurrentHost -Parent }
$script:CustomProfile = Join-Path -Path $script:ProfileRoot -ChildPath 'CTTcustom.ps1'

if (Test-Path -Path $script:CustomProfile -PathType Leaf) {
    . $script:CustomProfile
}

function Test-InteractiveShell {
    try {
        return $Host.Name -eq 'ConsoleHost' -and
            -not [Console]::IsInputRedirected -and
            -not [Console]::IsOutputRedirected
    } catch {
        return $false
    }
}

function Get-ProfileDir {
    switch ($PSVersionTable.PSEdition) {
        'Core' { Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell'; break }
        'Desktop' { Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell'; break }
        default {
            Write-Error "Unsupported PowerShell edition: $($PSVersionTable.PSEdition)"
            $null
        }
    }
}

function Test-Command {
    param([Parameter(Mandatory)][string]$Name)
    $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

$isInteractiveShell = Test-InteractiveShell
$debug = if ($null -ne $debug_Override) { [bool]$debug_Override } else { $false }
$repo_root = if ($repo_root_Override) { $repo_root_Override } else { 'https://raw.githubusercontent.com/ChrisTitusTech' }
$profileDir = Get-ProfileDir
$timeFilePath = if ($timeFilePath_Override) { $timeFilePath_Override } else { Join-Path $profileDir 'LastExecutionTime.txt' }
$updateInterval = if ($null -ne $updateInterval_Override) { [int]$updateInterval_Override } else { 7 }
$showHelpOnLaunch = if ($null -ne $show_help_Override) { [bool]$show_help_Override } else { $false }

function Debug-Message {
    if (Get-Command -Name 'Debug-Message_Override' -ErrorAction SilentlyContinue) {
        Debug-Message_Override
        return
    }

    Write-Host '#######################################' -ForegroundColor Red
    Write-Host '#           Debug mode enabled        #' -ForegroundColor Red
    Write-Host '#          ONLY FOR DEVELOPMENT       #' -ForegroundColor Red
    Write-Host '#       Run Update-Profile to reset   #' -ForegroundColor Red
    Write-Host '#######################################' -ForegroundColor Red
}

if ($debug) {
    Debug-Message
}

function Test-ProfileUpdateDue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][int]$IntervalDays
    )

    if ($IntervalDays -lt 0 -or -not (Test-Path -Path $Path -PathType Leaf)) {
        return $true
    }

    $rawDate = (Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue).Trim()
    if ([string]::IsNullOrWhiteSpace($rawDate)) {
        return $true
    }

    $lastRun = [datetime]::MinValue
    if (-not [datetime]::TryParseExact(
            $rawDate,
            'yyyy-MM-dd',
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::None,
            [ref]$lastRun
        )) {
        return $true
    }

    return ((Get-Date).Date - $lastRun.Date).TotalDays -ge $IntervalDays
}

function Test-ProfileIsSymlink {
    $profileItem = Get-Item -LiteralPath $PROFILE.CurrentUserCurrentHost -Force -ErrorAction SilentlyContinue
    return $profileItem -and $profileItem.LinkType -eq 'SymbolicLink'
}

function Update-Profile {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param([switch]$Force)

    if (Get-Command -Name 'Update-Profile_Override' -ErrorAction SilentlyContinue) {
        Update-Profile_Override @PSBoundParameters
        return $true
    }

    $url = "$repo_root/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
    $target = $PROFILE.CurrentUserCurrentHost
    $tempFile = Join-Path $env:TEMP 'Microsoft.PowerShell_profile.ps1'

    try {
        Invoke-RestMethod -Uri $url -OutFile $tempFile -ErrorAction Stop

        $targetExists = Test-Path -Path $target -PathType Leaf
        $oldHash = if ($targetExists) { (Get-FileHash -Path $target).Hash } else { $null }
        $newHash = (Get-FileHash -Path $tempFile).Hash

        if (-not $Force -and $targetExists -and $oldHash -eq $newHash) {
            if ($isInteractiveShell) {
                Write-Host 'Profile is up to date.' -ForegroundColor Green
            }
            return $true
        }

        if ($PSCmdlet.ShouldProcess($target, 'Update PowerShell profile')) {
            $targetDir = Split-Path -Path $target -Parent
            if (-not (Test-Path -Path $targetDir)) {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            }

            Copy-Item -Path $tempFile -Destination $target -Force
            Write-Host 'Profile has been updated. Restart your shell to use the new version.' -ForegroundColor Magenta
        }

        return $true
    } catch {
        Write-Warning "Unable to check for profile updates: $_"
        return $false
    } finally {
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    }
}

function Invoke-ScheduledProfileUpdate {
    if ($debug -or
        -not $isInteractiveShell -or
        (Test-ProfileIsSymlink) -or
        -not (Test-ProfileUpdateDue -Path $timeFilePath -IntervalDays $updateInterval)) {
        return
    }

    if (Update-Profile) {
        $timeDir = Split-Path -Path $timeFilePath -Parent
        if (-not (Test-Path -Path $timeDir)) {
            New-Item -Path $timeDir -ItemType Directory -Force | Out-Null
        }
        Get-Date -Format 'yyyy-MM-dd' | Set-Content -Path $timeFilePath
    }
}

function Update-PowerShell {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (Get-Command -Name 'Update-PowerShell_Override' -ErrorAction SilentlyContinue) {
        Update-PowerShell_Override @PSBoundParameters
        return
    }

    if (-not (Test-Command winget)) {
        Write-Warning 'winget is required to update PowerShell automatically.'
        return
    }

    try {
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest' -ErrorAction Stop
        $currentVersion = [version]$PSVersionTable.PSVersion
        $latestVersion = [version]($release.tag_name -replace '^v', '')

        if ($currentVersion -ge $latestVersion) {
            Write-Host "PowerShell $currentVersion is up to date." -ForegroundColor Green
            return
        }

        if ($PSCmdlet.ShouldProcess("PowerShell $currentVersion", "Upgrade to $latestVersion")) {
            winget upgrade --id Microsoft.PowerShell --exact --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -ne 0) {
                Write-Error "winget failed to update PowerShell. Exit code: $LASTEXITCODE"
                return
            }
            Write-Host 'PowerShell has been updated. Restart your shell to use the new version.' -ForegroundColor Magenta
        }
    } catch {
        Write-Error "Failed to update PowerShell. Error: $_"
    }
}

function Clear-Cache {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (Get-Command -Name 'Clear-Cache_Override' -ErrorAction SilentlyContinue) {
        Clear-Cache_Override @PSBoundParameters
        return
    }

    $paths = @(
        "$env:SystemRoot\Prefetch\*",
        "$env:SystemRoot\Temp\*",
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*"
    )

    foreach ($path in $paths) {
        if ($PSCmdlet.ShouldProcess($path, 'Remove cached files')) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Initialize-OptionalModule {
    if (-not $isInteractiveShell) {
        return
    }

    if (Get-Module -ListAvailable -Name Terminal-Icons) {
        Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
    } elseif ($isInteractiveShell) {
        Write-Warning 'Terminal-Icons module is not installed. Run setup.ps1 to install dependencies.'
    }

    $chocolateyProfile = if ($env:ChocolateyInstall) {
        Join-Path $env:ChocolateyInstall 'helpers\chocolateyProfile.psm1'
    } else {
        $null
    }

    if ($chocolateyProfile -and (Test-Path -Path $chocolateyProfile -PathType Leaf)) {
        Import-Module $chocolateyProfile -ErrorAction SilentlyContinue
    }
}

function Resolve-Editor {
    if ($EDITOR_Override) {
        return $EDITOR_Override
    }

    foreach ($candidate in 'nvim', 'pvim', 'vim', 'vi', 'code', 'codium', 'notepad++', 'sublime_text') {
        if (Test-Command $candidate) {
            return $candidate
        }
    }

    return 'notepad'
}

Initialize-OptionalModule

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$EDITOR = Resolve-Editor
Set-Alias -Name vim -Value $EDITOR -Force

if ($isInteractiveShell) {
    try {
        $adminSuffix = if ($isAdmin) { ' [ADMIN]' } else { '' }
        $Host.UI.RawUI.WindowTitle = "PowerShell $($PSVersionTable.PSVersion)$adminSuffix"
    } catch {
        Write-Verbose "Unable to set console title: $_"
    }
}

function prompt {
    $marker = if ($isAdmin) { '#' } else { '$' }
    "[$(Get-Location)] $marker "
}

function Edit-Profile {
    & $EDITOR $PROFILE.CurrentUserAllHosts
}
Set-Alias -Name ep -Value Edit-Profile -Force

function Invoke-Profile {
    . $PROFILE.CurrentUserCurrentHost
}

function touch {
    param([Parameter(Mandatory)][string]$File)

    if (Test-Path -Path $File) {
        (Get-Item -Path $File).LastWriteTime = Get-Date
    } else {
        New-Item -Path $File -ItemType File -Force | Out-Null
    }
}

function mkcd {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    Set-Location -Path $Path
}

function ff {
    param([Parameter(Mandatory)][string]$Name)
    Get-ChildItem -Recurse -Filter "*$Name*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}

function pubip {
    (Invoke-WebRequest -Uri 'https://ifconfig.me/ip' -UseBasicParsing).Content
}

function winutil {
    & ([ScriptBlock]::Create((Invoke-RestMethod -Uri 'https://christitus.com/win'))) @args
}

function winutildev {
    if (Get-Command -Name 'WinUtilDev_Override' -ErrorAction SilentlyContinue) {
        WinUtilDev_Override @args
        return
    }

    & ([ScriptBlock]::Create((Invoke-RestMethod -Uri 'https://christitus.com/windev'))) @args
}

function admin {
    $cwd = (Get-Location).ProviderPath
    if ($args.Count -gt 0) {
        Start-Process wt -Verb RunAs -ArgumentList @('-d', $cwd, 'pwsh.exe', '-NoExit', '-Command', ($args -join ' '))
    } else {
        Start-Process wt -Verb RunAs -ArgumentList @('-d', $cwd, 'pwsh.exe', '-NoExit')
    }
}
Set-Alias -Name su -Value admin -Force

function uptime {
    $boot = if (Get-Command Get-Uptime -ErrorAction SilentlyContinue) {
        Get-Uptime -Since
    } else {
        (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    }

    (Get-Date) - $boot | Select-Object Days, Hours, Minutes, Seconds
}

function unzip {
    param([Parameter(Mandatory)][string]$File)

    if (-not (Test-Path -Path $File -PathType Leaf)) {
        Write-Error "File not found: $File"
        return
    }

    Expand-Archive -Path $File -DestinationPath (Get-Location) -Force
}

function hb {
    param([Parameter(Mandatory)][string]$FilePath)

    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "File not found: $FilePath"
        return
    }

    try {
        $content = Get-Content -Path $FilePath -Raw
        $response = Invoke-RestMethod -Uri 'http://bin.christitus.com/documents' -Method Post -Body $content -ErrorAction Stop
        $url = "http://bin.christitus.com/$($response.key)"
        Set-Clipboard $url
        Write-Output "$url copied to clipboard."
    } catch {
        Write-Error "Failed to upload the document. Error: $_"
    }
}

function grep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Pattern,
        [Parameter(Position = 1)][string]$Path,
        [Parameter(ValueFromPipeline)][object]$InputObject
    )

    begin {
        $pipelineInput = [System.Collections.Generic.List[object]]::new()
    }

    process {
        if ($PSBoundParameters.ContainsKey('InputObject')) {
            $pipelineInput.Add($InputObject)
        }
    }

    end {
        if ($Path) {
            Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Select-String -Pattern $Pattern
        } elseif ($pipelineInput.Count -gt 0) {
            $pipelineInput | Select-String -Pattern $Pattern
        } else {
            Write-Error 'Usage: grep <pattern> [path] or pipe input to grep'
        }
    }
}

function df { Get-Volume }

function sed {
    param(
        [Parameter(Mandatory)][string]$File,
        [Parameter(Mandatory)][string]$Find,
        [Parameter(Mandatory)][string]$Replace
    )

    (Get-Content -Path $File).Replace($Find, $Replace) | Set-Content -Path $File
}

function which {
    param([Parameter(Mandatory)][string]$Name)
    Get-Command -Name $Name | Select-Object -ExpandProperty Definition
}

function export {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )
    Set-Item -Path "env:$Name" -Value $Value -Force
}

function pkill {
    param([Parameter(Mandatory)][string]$Name)
    Get-Process -Name $Name -ErrorAction SilentlyContinue | Stop-Process -Force
}

function pgrep {
    param([Parameter(Mandatory)][string]$Name)
    Get-Process -Name $Name -ErrorAction SilentlyContinue
}

function head {
    param([Parameter(Mandatory)][string]$Path, [int]$n = 10)
    Get-Content -Path $Path -Head $n
}

function tail {
    param([Parameter(Mandatory)][string]$Path, [int]$n = 10, [switch]$f)
    Get-Content -Path $Path -Tail $n -Wait:$f
}

function nf {
    param([Parameter(Mandatory)][string]$Name)
    New-Item -ItemType File -Path . -Name $Name -Force | Out-Null
}

function trash {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -Path $Path)) {
        Write-Error "Item not found: $Path"
        return
    }

    $item = Get-Item -Path $Path
    $parentPath = if ($item.PSIsContainer) { $item.Parent.FullName } else { $item.DirectoryName }
    $shell = New-Object -ComObject 'Shell.Application'
    $shellItem = $shell.NameSpace($parentPath).ParseName($item.Name)

    if ($shellItem) {
        $shellItem.InvokeVerb('delete')
    } else {
        Write-Error "Could not move item to Recycle Bin: $Path"
    }
}

function docs {
    Set-Location -Path ([Environment]::GetFolderPath('MyDocuments'))
}

function dtop {
    Set-Location -Path ([Environment]::GetFolderPath('Desktop'))
}

function k9 { param([Parameter(Mandatory)][string]$Name) pkill $Name }
function la { Get-ChildItem | Format-Table -AutoSize }
function ll { Get-ChildItem -Force | Format-Table -AutoSize }
function gs { git status }
function ga { git add . }
function gc { git commit -m ($args -join ' ') }
function gpush { git push @args }
function gpull { git pull @args }
function gcl { git clone @args }

function g {
    if (Get-Command __zoxide_z -ErrorAction SilentlyContinue) {
        __zoxide_z github
    } elseif (Test-Path -Path "$HOME\github") {
        Set-Location "$HOME\github"
    }
}

function gcom {
    git add .
    git commit -m ($args -join ' ')
}

function lazyg {
    git add .
    git commit -m ($args -join ' ')
    git push
}

function sysinfo { Get-ComputerInfo }

function flushdns {
    Clear-DnsClientCache
    Write-Host 'DNS has been flushed'
}

function cpy { Set-Clipboard ($args -join ' ') }
function pst { Get-Clipboard }

function Set-PSReadLineOptionsCompat {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Options)

    $safeOptions = $Options.Clone()
    if ($PSVersionTable.PSEdition -ne 'Core') {
        $safeOptions.Remove('PredictionSource')
        $safeOptions.Remove('PredictionViewStyle')
    }

    if ($PSCmdlet.ShouldProcess('PSReadLine', 'Set PSReadLine options')) {
        Set-PSReadLineOption @safeOptions
    }
}

function Set-PredictionSource {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (Get-Command -Name 'Set-PredictionSource_Override' -ErrorAction SilentlyContinue) {
        Set-PredictionSource_Override
        return
    }

    if ($PSCmdlet.ShouldProcess('PSReadLine', 'Set prediction source')) {
        if ($PSVersionTable.PSEdition -eq 'Core') {
            Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        }

        Set-PSReadLineOption -MaximumHistoryCount 10000
    }
}

function Initialize-PSReadLine {
    if (-not $isInteractiveShell -or -not (Get-Module -ListAvailable -Name PSReadLine)) {
        return
    }

    $options = @{
        EditMode                    = 'Windows'
        HistoryNoDuplicates        = $true
        HistorySearchCursorMovesToEnd = $true
        PredictionSource           = 'History'
        PredictionViewStyle        = 'ListView'
        BellStyle                  = 'None'
        Colors                     = @{
            Command   = '#87CEEB'
            Parameter = '#98FB98'
            Operator  = '#FFB6C1'
            Variable  = '#DDA0DD'
            String    = '#FFDAB9'
            Number    = '#B0E0E6'
            Type      = '#F0E68C'
            Comment   = '#D3D3D3'
            Keyword   = '#8367c7'
            Error     = '#FF6347'
        }
    }

    Set-PSReadLineOptionsCompat -Options $options
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

    Set-PSReadLineOption -AddToHistoryHandler {
        param([string]$line)
        $line -notmatch '(?i)(password|secret|token|apikey|connectionstring)'
    }

    Set-PredictionSource
}

function Register-CustomCompletion {
    if (-not $isInteractiveShell) {
        return
    }

    $completionMap = @{
        git  = @('status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout')
        npm  = @('install', 'start', 'run', 'test', 'build')
        deno = @('run', 'compile', 'bundle', 'test', 'lint', 'fmt', 'cache', 'info', 'doc', 'upgrade')
    }

    Register-ArgumentCompleter -Native -CommandName git, npm, deno -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $null = $cursorPosition
        $completionWord = $wordToComplete
        $map = $completionMap
        $command = $commandAst.CommandElements[0].Value
        if ($map.ContainsKey($command)) {
            $map[$command] |
                Where-Object { $_ -like "$completionWord*" } |
                ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
        }
    }.GetNewClosure()

    if (Test-Command dotnet) {
        Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
            param($wordToComplete, $commandAst, $cursorPosition)
            $null = $wordToComplete
            dotnet complete --position $cursorPosition $commandAst.ToString() |
                ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
        }
    }
}

function Resolve-OhMyPoshTheme {
    $candidates = @(
        $env:POSH_THEME,
        (Join-Path $profileDir 'cobalt2.omp.json'),
        (Join-Path $HOME 'cobalt2.omp.json')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($candidate in $candidates) {
        if (Test-Path -Path $candidate -PathType Leaf) {
            return $candidate
        }
    }

    return $null
}

function Initialize-PromptTool {
    if (-not $isInteractiveShell) {
        return
    }

    if (Get-Command -Name 'Get-Theme_Override' -ErrorAction SilentlyContinue) {
        Get-Theme_Override
    } elseif (Test-Command oh-my-posh) {
        $theme = Resolve-OhMyPoshTheme
        if ($theme) {
            oh-my-posh init pwsh --config $theme | Invoke-Expression
        } elseif ($isInteractiveShell) {
            Write-Warning 'Oh My Posh theme not found. Run setup.ps1 to install cobalt2.omp.json.'
        }
    } elseif ($isInteractiveShell) {
        Write-Warning 'oh-my-posh is not installed. Run setup.ps1 to install dependencies.'
    }

    if (Test-Command zoxide) {
        Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
    } elseif ($isInteractiveShell) {
        Write-Warning 'zoxide is not installed. Run setup.ps1 to install dependencies.'
    }
}

function Show-Help {
    @'
PowerShell Profile Help
=======================

Profile:
  Edit-Profile      Open the current user's all-hosts profile for editing.
  Invoke-Profile    Reload this profile in the current session.
  Update-Profile    Check for profile updates.
  Update-PowerShell Check for the latest PowerShell release and update with winget.

Git:
  g                 Go to the GitHub directory with zoxide fallback.
  ga                git add .
  gc <message>      git commit -m <message>
  gcl <repo>        git clone <repo>
  gcom <message>    git add .; git commit -m <message>
  gp/gpush          git push
  gpull             git pull
  gs                git status
  lazyg <message>   git add .; git commit -m <message>; git push

Shortcuts:
  cpy <text>        Copy text to the clipboard.
  df                Show volume information.
  docs/dtop         Go to Documents/Desktop.
  ff <name>         Find files recursively by name.
  flushdns          Clear the DNS cache.
  grep <regex> [p]  Search files or piped input.
  hb <file>         Upload file content to bin.christitus.com.
  head/tail         Show the first or last lines of a file.
  k9/pkill <name>   Kill processes by name.
  la/ll             List visible/all files.
  mkcd <dir>        Create and enter a directory.
  nf/touch <file>   Create a file.
  pgrep <name>      Find processes by name.
  pst               Paste clipboard text.
  sed <f> <a> <b>   Replace text in a file.
  sysinfo           Show system information.
  unzip <file>      Extract a zip file here.
  uptime            Show system uptime.
  which <name>      Show command path.
  winutil           Run the latest WinUtil release script.
  winutildev        Run the latest WinUtil prerelease script.
'@ | Write-Host
}

Set-Alias -Name gp -Value gpush -Force

Initialize-PSReadLine
Register-CustomCompletion
Initialize-PromptTool
Invoke-ScheduledProfileUpdate

if ($showHelpOnLaunch) {
    Show-Help
} elseif ($isInteractiveShell) {
    Write-Host "Use 'Show-Help' to display help" -ForegroundColor Yellow
}
