# Ultra-Fast PowerShell Profile
# === STARTUP PERFORMANCE FIXES ===
# Disable module auto-loading (saves ~200-300ms)
$PSModuleAutoLoadingPreference = 'ModuleQualifiedOnly'

# Remove chocolatey profile if it auto-loaded (saves ~300ms)
Remove-Module chocolateyProfile -Force -ErrorAction SilentlyContinue

# === ALIASES ===
Set-Alias vim nvim
Set-Alias ll ls  
Set-Alias grep findstr
Set-Alias cl clear
Set-Alias tig 'C:\Program Files\Git\usr\bin\tig.exe'
Set-Alias less 'C:\Program Files\Git\usr\bin\less.exe'
Set-Alias lg lazygit
Set-Alias g git

# === GIT FUNCTIONS ===
function gst { git status $args }
function ga { git add $args }
function gaa { git add --all $args }
function gc { git commit -m $args }
function gca { git commit -am $args }
function gcm { git commit -m $args }
function gba { git branch --all $args }
function gco { git checkout $args }
function glola { git log --graph --decorate --oneline --all $args }
function which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

# === PSREADLINE CONFIGURATION ===
Set-PSReadLineOption -EditMode Vi -BellStyle None -PredictionSource History -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Chord 'Ctrl-n' -Function NextSuggestion
Set-PSReadLineKeyHandler -Chord 'Ctrl-p' -Function PreviousSuggestion  
Set-PSReadLineKeyHandler -Chord Tab -Function Complete

# Vi mode cursor indicator
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler {
    Write-Host -NoNewLine $(if ($args[0] -eq 'Command') { "`e[1 q" } else { "`e[5 q" })
}

# === STARSHIP PROMPT ===
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}

# === ON-DEMAND GIT INTEGRATION ===
function Enable-GitIntegration {
    if (-not $Global:PoshGitLoaded -and (git rev-parse --git-dir 2>$null)) {
        Import-Module posh-git -Global -Force:$false -ErrorAction SilentlyContinue
        $Global:PoshGitLoaded = $true
        Write-Host "✅ Git integration enabled" -ForegroundColor Green
    }
}

# Auto-enable git integration when navigating to git repos
function Set-Location {
    # Call the original Set-Location with all parameters
    Microsoft.PowerShell.Management\Set-Location @args
    
    # Check if we entered a git repo after changing directory
    if (-not $Global:PoshGitLoaded -and (git rev-parse --git-dir 2>$null)) {
        Enable-GitIntegration
    }
}

# === OPTIONAL UTILITIES ===
# Enable chocolatey when needed
function Enable-Chocolatey {
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -Force -Global -ErrorAction SilentlyContinue
    Write-Host "✅ Chocolatey enabled for this session" -ForegroundColor Green
}
