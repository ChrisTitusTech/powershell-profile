### Chris Titus Tech's PowerShell profile

oh-my-posh init pwsh --config $Home\Documents\PowerShell\cobalt2.omp.json | Invoke-Expression
Write-Host "Use 'Show-Help' to list all available functions" -ForegroundColor Yellow

# History & Colors
Set-PSReadLineOption -PredictionViewStyle ListView -Colors @{
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

#KeyBinds
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

# Functions
function Update-Profile {
    Invoke-WebRequest -Uri https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $Profile
    Write-Host "Updated PowerShell Profile" -ForegroundColor Green
}

# File / Directory Utilities
function touch ($File) {
    if (Test-Path $File) {
        (Get-Item $File).LastWriteTime = Get-Date
    } else {
        New-Item $File -ItemType File | Out-Null
    }
}

function mkcd ($Path) {
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    Set-Location -Path $Path
}

function trash ($Path) {
    if (Test-Path $Path -PathType Container) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($Path,'OnlyErrorDialogs','SendToRecycleBin')
    } else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($Path,'OnlyErrorDialogs','SendToRecycleBin')
    }
}

function ff ($Name) {
    Get-ChildItem -Recurse -Filter $Name -File | Select-Object -ExpandProperty FullName
}

function head ($Path) {
    Get-Content $Path -Head 10
}

function sed ($File, $Find, $Replace) {
    (Get-Content $File).replace("$Find", $Replace) | Set-Content $file
}

function which ($Name) {
    (Get-Command $Name).Source
}

# System Utilities
function uptime {
    (Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime | Select-Object Days, Hours, Minutes, Seconds
}

function winutil {
    Invoke-RestMethod https://christitus.com/win | Invoke-Expression
}

function winutildev {
    Invoke-RestMethod https://christitus.com/windev | Invoke-Expression
}

# Git Shortcuts
function gs { git status }
function ga { git add . }
function gp { git push }
function gpush { git push }
function gpull { git pull }
function gcl { git clone $args }

function gcom {
    git add .
    git commit -m "$args"
}

function lazyg {
    git add .
    git commit -m "$args"
    git push
}

function g { __zoxide_z github }

# Listing / Viewing
function la {
    Get-ChildItem | Format-Table -AutoSize
}

function ll {
    Get-ChildItem -Force | Format-Table -AutoSize
}

# Aliases
Set-Alias -Name unzip -Value Expand-Archive
Set-Alias -Name grep -Value Select-String

# Help Function
function Show-Help {
    $title    = $PSStyle.Foreground.BrightMagenta
    $section  = $PSStyle.Foreground.BrightBlue
    $command  = $PSStyle.Foreground.BrightGreen
    $desc     = $PSStyle.Foreground.BrightWhite
    $accent   = $PSStyle.Foreground.BrightYellow
    $dim      = $PSStyle.Foreground.BrightBlack
    $reset    = $PSStyle.Reset

    Write-Host @"
${title}󰘳 PowerShell Profile Help${reset}
${dim}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}

${section}󰊢 Update${reset}
  ${command}Update-Profile${reset}  ${accent}→${reset} ${desc}Updates the profile from a remote repository.${reset}

${section}󰊢 Git Shortcuts${reset}
${dim}────────────────────────────────────────────────────${reset}
  ${command}g${reset}                  ${accent}→${reset} ${desc}Changes to the GitHub directory${reset}
  ${command}ga${reset}                 ${accent}→${reset} ${desc}git add .${reset}
  ${command}gcl <repo>${reset}         ${accent}→${reset} ${desc}git clone${reset}
  ${command}gcom <message>${reset}     ${accent}→${reset} ${desc}add + commit${reset}
  ${command}gp / gpush${reset}         ${accent}→${reset} ${desc}git push${reset}
  ${command}gpull${reset}              ${accent}→${reset} ${desc}git pull${reset}
  ${command}gs${reset}                 ${accent}→${reset} ${desc}git status${reset}
  ${command}lazyg <message>${reset}    ${accent}→${reset} ${desc}add + commit + push${reset}

${section}󰘴 System Shortcuts${reset}
${dim}────────────────────────────────────────────────────${reset}
  ${command}docs${reset}               ${accent}→${reset} ${desc}Documents folder${reset}
  ${command}ff <name>${reset}          ${accent}→${reset} ${desc}Search files${reset}
  ${command}grep <regex> [dir]${reset} ${accent}→${reset} ${desc}Search text${reset}
  ${command}head <file>${reset}        ${accent}→${reset} ${desc}First lines${reset}
  ${command}ll${reset}                 ${accent}→${reset} ${desc}List files${reset}
  ${command}mkcd <dir>${reset}         ${accent}→${reset} ${desc}Create + enter dir${reset}
  ${command}sed <file> <find> <replace>${reset} ${accent}→${reset} ${desc}Replace text${reset}
  ${command}touch <file>${reset}       ${accent}→${reset} ${desc}Create file${reset}
  ${command}unzip <file>${reset}       ${accent}→${reset} ${desc}Extract zip${reset}
  ${command}uptime${reset}             ${accent}→${reset} ${desc}System uptime${reset}
  ${command}which <name>${reset}       ${accent}→${reset} ${desc}Locate command${reset}
  ${command}winutil${reset}            ${accent}→${reset} ${desc}Run WinUtil${reset}
  ${command}winutildev${reset}         ${accent}→${reset} ${desc}Run WinUtil Dev${reset}

${dim}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}
"@
}
