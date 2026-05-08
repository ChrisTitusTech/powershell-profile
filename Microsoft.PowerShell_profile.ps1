oh-my-posh init pwsh --config $Home\cobalt2.omp.json | Invoke-Expression

Write-Host "$($PSStyle.Foreground.Yellow)Use 'Show-Help' to list all available functions$($PSStyle.Reset)"

#----------
# History
#----------

Set-PSReadLineOption `
    -EditMode Windows `
    -HistoryNoDuplicates `
    -HistorySearchCursorMovesToEnd `
    -BellStyle None `
    -PredictionSource History `
    -PredictionViewStyle ListView `
    -MaximumHistoryCount 10000 `
    -Colors @{
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
    } `
    -AddToHistoryHandler {
        $args[0] -notmatch 'password|secret|token|apikey|connectionstring'
    }

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

foreach ($b in $bindings.Keys) {
    Set-PSReadLineKeyHandler -Key $b -Function $bindings[$b]
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
    Write-Host @"
$($PSStyle.Foreground.Cyan)PowerShell Profile Help$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)Update-Profile$($PSStyle.Reset) - Checks for profile updates from a remote repository and updates if necessary.

$($PSStyle.Foreground.Cyan)Git Shortcuts$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)g$($PSStyle.Reset) - Changes to the GitHub directory.
$($PSStyle.Foreground.Green)ga$($PSStyle.Reset) - git add .
$($PSStyle.Foreground.Green)gc <message>$($PSStyle.Reset) - git commit -m
$($PSStyle.Foreground.Green)gcl <repo>$($PSStyle.Reset) - git clone
$($PSStyle.Foreground.Green)gcom <message>$($PSStyle.Reset) - add + commit
$($PSStyle.Foreground.Green)gp / gpush$($PSStyle.Reset) - git push
$($PSStyle.Foreground.Green)gpull$($PSStyle.Reset) - git pull
$($PSStyle.Foreground.Green)gs$($PSStyle.Reset) - git status
$($PSStyle.Foreground.Green)lazyg <message>$($PSStyle.Reset) - add + commit + push

$($PSStyle.Foreground.Cyan)Shortcuts$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)docs$($PSStyle.Reset) - Documents folder
$($PSStyle.Foreground.Green)ff <name>$($PSStyle.Reset) - search files
$($PSStyle.Foreground.Green)grep <regex> [dir]$($PSStyle.Reset) - search text
$($PSStyle.Foreground.Green)head <file> [n]$($PSStyle.Reset) - first lines
$($PSStyle.Foreground.Green)la / ll$($PSStyle.Reset) - list files
$($PSStyle.Foreground.Green)mkcd <dir>$($PSStyle.Reset) - create + enter dir
$($PSStyle.Foreground.Green)sed <file> <find> <replace>$($PSStyle.Reset) - replace text
$($PSStyle.Foreground.Green)touch <file>$($PSStyle.Reset) - create file
$($PSStyle.Foreground.Green)unzip <file>$($PSStyle.Reset) - extract zip
$($PSStyle.Foreground.Green)uptime$($PSStyle.Reset) - system uptime
$($PSStyle.Foreground.Green)which <name>$($PSStyle.Reset) - locate command
$($PSStyle.Foreground.Green)winutil / winutildev$($PSStyle.Reset) - run WinUtil
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
"@
}
