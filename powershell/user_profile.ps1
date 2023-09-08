# PSReadLine
Set-PSReadLineOption -EditMode Vi
function OnViModeChange {
    if ($args[0] -eq 'Command') {
        # Set the cursor to a blinking block.
        Write-Host -NoNewLine "`e[1 q"
    } else {
        # Set the cursor to a blinking line.
        Write-Host -NoNewLine "`e[5 q"
    }
}
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $Function:OnViModeChange
# Set-PSReadLineOption -BellStyle None
# Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Chord 'Ctrl-n' -Function NextSuggestion
Set-PSReadLineKeyHandler -Chord 'Ctrl-p' -Function PreviousSuggestion
Set-PSReadLineKeyHandler -Chord Tab -Function Complete

# Icons
# Import-Module -Name Terminal-Icons

# Default Prompt
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\tokyonight_storm.omp.json" | Invoke-Expression
# Prompt
oh-my-posh init pwsh --config "C:/Users/shiya/.config/powershell/bubbles.omp.json" | Invoke-Expression

# Fzf
# Import-Module PSFzf
# Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Alias
Set-Alias vim nvim
Set-Alias ll ls
Set-Alias grep findstr
Set-Alias cl clear
Set-Alias tig 'C:\Program Files\Git\usr\bin\tig.exe'
Set-Alias less 'C:\Program Files\Git\usr\bin\less.exe'
function notes {
    nvim -c 'cd C:\Users\shiya\OneDrive\notes' C:\Users\shiya\OneDrive\notes
}

# Alias - Git
Set-Alias lg lazygit
Set-Alias g git
function gst {
	git status $args
}
function ga {
    git add $args
}
function gaa {
    git add --all $args
}
function gc {
    git commit -m $args
}
function gca {
    git commit -am $args
}
function gcm {
    git commit -m $args
}
function gba {
    git branch --all $args
}
function gco {
    git checkout $args
}
function glola {
    git log --graph --decorate --oneline --all $args
}

Import-Module posh-git

# Utilities
function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
