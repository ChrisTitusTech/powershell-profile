oh-my-posh init pwsh --config (Join-Path (Split-Path $Profile) 'cobalt2.omp.json') | Invoke-Expression

Write-Host "$($PSStyle.Foreground.Yellow)Use 'Show-Help' to display help$($PSStyle.Reset)"

#----------
# History
#----------

$psReadLineOptions = @{
    EditMode                      = 'Windows'
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    BellStyle                     = 'None'
    PredictionSource              = 'History'
    PredictionViewStyle           = 'ListView'
    MaximumHistoryCount           = 10000

    Colors = @{
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

    AddToHistoryHandler = {
        param($line)
        $line -notmatch 'password|secret|token|apikey|connectionstring'
    }
}

Set-PSReadLineOption @psReadLineOptions

$bindings = @{
    UpArrow          = 'HistorySearchBackward'
    DownArrow        = 'HistorySearchForward'
    Tab              = 'MenuComplete'
    'Ctrl+d'         = 'DeleteChar'
    'Ctrl+w'         = 'BackwardDeleteWord'
    'Alt+d'          = 'DeleteWord'
    'Ctrl+LeftArrow' = 'BackwardWord'
    'Ctrl+RightArrow'= 'ForwardWord'
    'Ctrl+z'         = 'Undo'
    'Ctrl+y'         = 'Redo'
}

$bindings.GetEnumerator() | ForEach-Object {
    Set-PSReadLineKeyHandler -Key $_.Key -Function $_.Value
}

#----------
# Functions
#----------

function Update-Profile {
    Invoke-WebRequest -Uri https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $Profile
    Write-Host "Updated PowerShell Profile" -ForegroundColor Green
}

function touch ($File) {
    if (Test-Path $File) {
        (Get-Item $File).LastWriteTime = Get-Date
    } else {
        New-Item $File -ItemType File | Out-Null
    }
}

function ff ($name) {
    (Get-ChildItem -Filter "$name" -Recurse).FullName
}

function winutil {
    Invoke-Expression (Invoke-RestMethod https://christitus.com/win)
}

function winutildev {
    Invoke-Expression (Invoke-RestMethod https://christitus.com/windev)
}

function uptime {
    (Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime | Select-Object Days, Hours, Minutes, Seconds
}

function unzip ($file) {
    Expand-Archive -Path $file
}

function grep ($Pattern, $Path) {
    Select-String -Pattern $Pattern -Path $Path
}

function sed ($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which ($name) {
    (Get-Command $name).Definition
}

function head ($Path) {
    Get-Content $Path -Head 10
}

function mkcd ($dir) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
    Set-Location -Path $dir
}

function trash ($Path) {
    $shell = New-Object -ComObject Shell.Application

    $full = (Resolve-Path $Path).Path
    $folder = Split-Path $full
    $name = Split-Path $full -Leaf

    $item = $shell.Namespace($folder).ParseName($name)
    $item.InvokeVerb("delete")

    Write-Host "Moved to Recycle Bin: $full"
}

function docs {
    Set-Location -Path $Home\Documents
}

function la {
    Get-ChildItem | Format-Table -AutoSize
}

function ll {
    Get-ChildItem -Force | Format-Table -AutoSize
}

function gs { git status }
function ga { git add . }
function gc { param($m) git commit -m "$m" }
function gpush { git push }
function gpull { git pull }
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

function Show-Help {
    $helpText = @"
    $($PSStyle.Foreground.Cyan)PowerShell Profile Help$($PSStyle.Reset)
    $($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
    $($PSStyle.Foreground.Green)Update-Profile$($PSStyle.Reset) - Checks for profile updates from a remote repository and updates if necessary.

    $($PSStyle.Foreground.Cyan)Git Shortcuts$($PSStyle.Reset)
    $($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
    $($PSStyle.Foreground.Green)g$($PSStyle.Reset) - Changes to the GitHub directory.
    $($PSStyle.Foreground.Green)ga$($PSStyle.Reset) - Shortcut for 'git add .'.
    $($PSStyle.Foreground.Green)gc$($PSStyle.Reset) <message> - Shortcut for 'git commit -m'.
    $($PSStyle.Foreground.Green)gcl$($PSStyle.Reset) <repo> - Shortcut for 'git clone'.
    $($PSStyle.Foreground.Green)gcom$($PSStyle.Reset) <message> - Adds all changes and commits with the specified message.
    $($PSStyle.Foreground.Green)gp$($PSStyle.Reset) - Shortcut for 'git push'.
    $($PSStyle.Foreground.Green)gpull$($PSStyle.Reset) - Shortcut for 'git pull'.
    $($PSStyle.Foreground.Green)gpush$($PSStyle.Reset) - Shortcut for 'git push'.
    $($PSStyle.Foreground.Green)gs$($PSStyle.Reset) - Shortcut for 'git status'.
    $($PSStyle.Foreground.Green)lazyg$($PSStyle.Reset) <message> - Adds all changes, commits with the specified message, and pushes to the remote repository.

    $($PSStyle.Foreground.Cyan)Shortcuts$($PSStyle.Reset)
    $($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
    $($PSStyle.Foreground.Green)docs$($PSStyle.Reset) - Changes the current directory to the user's Documents folder.
    $($PSStyle.Foreground.Green)export$($PSStyle.Reset) <name> <value> - Sets an environment variable.
    $($PSStyle.Foreground.Green)ff$($PSStyle.Reset) <name> - Finds files recursively with the specified name.
    $($PSStyle.Foreground.Green)grep$($PSStyle.Reset) <regex> [dir] - Searches for a regex pattern in files within the specified directory or from the pipeline input.
    $($PSStyle.Foreground.Green)head$($PSStyle.Reset) <path> [n] - Displays the first n lines of a file (default 10).
    $($PSStyle.Foreground.Green)la$($PSStyle.Reset) - Lists all files in the current directory with detailed formatting.
    $($PSStyle.Foreground.Green)ll$($PSStyle.Reset) - Lists all files, including hidden, in the current directory with detailed formatting.
    $($PSStyle.Foreground.Green)mkcd$($PSStyle.Reset) <dir> - Creates and changes to a new directory.
    $($PSStyle.Foreground.Green)sed$($PSStyle.Reset) <file> <find> <replace> - Replaces text in a file.
    $($PSStyle.Foreground.Green)touch$($PSStyle.Reset) <file> - Creates a new empty file.
    $($PSStyle.Foreground.Green)unzip$($PSStyle.Reset) <file> - Extracts a zip file to the current directory.
    $($PSStyle.Foreground.Green)uptime$($PSStyle.Reset) - Displays the system uptime.
    $($PSStyle.Foreground.Green)which$($PSStyle.Reset) <name> - Shows the path of the command.
    $($PSStyle.Foreground.Green)winutil$($PSStyle.Reset) - Runs the latest WinUtil full-release script from Chris Titus Tech.
    $($PSStyle.Foreground.Green)winutildev$($PSStyle.Reset) - Runs the latest WinUtil pre-release script from Chris Titus Tech.
    $($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
"@

    Write-Host $helpText
}
