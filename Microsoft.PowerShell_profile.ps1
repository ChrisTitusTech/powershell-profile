# Chris Titus Tech's PowerShell profile
# Uses oh-my-posh and has custom history + custom build-in functions

Invoke-Expression (oh-my-posh init pwsh --config (Join-Path (Split-Path $Profile)\cobalt2.omp.json))
Write-Host "Use 'Show-Help' to list all available functions" -ForegroundColor Yellow

# History & Colors & Tab Completion
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
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

# Functions
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

function ff ($Name) {
    (Get-ChildItem -Filter "$Name" -Recurse).FullName
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

function unzip ($File) {
    Expand-Archive -Path $file
}

function grep ($Pattern, $Path) {
    if ($Path) {
        Select-String $Pattern $Path
    } else {
        $input | Select-String $Pattern
    }
}

function sed ($File, $Find, $Replace) {
    (Get-Content $File).replace("$Find", $Replace) | Set-Content $file
}

function which ($Name) {
    (Get-Command $Name).Definition
}

function head ($Path) {
    Get-Content $Path -Head 10
}

function mkcd ($Path) {
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    Set-Location -Path $Path
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

function ll {
    Get-ChildItem -Force | Format-Table -AutoSize
}

function gs { git status }
function ga { git add . }
function gc ($m) { git commit -m "$m" }
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
  ${command}gc <message>${reset}       ${accent}→${reset} ${desc}git commit -m${reset}
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
  ${command}head <file> [n]${reset}    ${accent}→${reset} ${desc}First lines${reset}
  ${command}la / ll${reset}            ${accent}→${reset} ${desc}List files${reset}
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
