# Oh My Posh configuration
eval "$(/home/anandpant/.local/bin/oh-my-posh init zsh --config ~/.config/ohmyposh/theme.json)"

# Path additions
export PATH=$PATH:~/.local/bin

# Zsh plugins
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# Add completions path
fpath=(~/.zsh/zsh-completions/src $fpath)

# Initialize completions
autoload -U compinit && compinit

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# Autosuggestion configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666,underline"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# FZF configuration (using fdfind on Ubuntu/Debian)
export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Aliases for better development workflow (adjusted for Linux)
# Check if exa/eza is installed
if command -v exa &> /dev/null; then
    alias ll='exa -la --icons --git'
    alias ls='exa --icons'
elif command -v eza &> /dev/null; then
    alias ll='eza -la --icons --git'
    alias ls='eza --icons'
else
    alias ll='ls -la --color=auto'
    alias ls='ls --color=auto'
fi

# Use batcat on Ubuntu/Debian (it's installed as batcat to avoid conflicts)
if command -v batcat &> /dev/null; then
    alias cat='batcat'
elif command -v bat &> /dev/null; then
    alias cat='bat'
fi

# Use fdfind on Ubuntu/Debian
if command -v fdfind &> /dev/null; then
    alias fd='fdfind'
fi

# Ripgrep alias
if command -v rg &> /dev/null; then
    alias grep='rg'
fi

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# Development aliases
alias serve='python3 -m http.server'
alias myip='curl -s https://ipinfo.io/ip'
alias ports='ss -tuln'  # ss is more modern than netstat on Linux
alias update='sudo apt update && sudo apt upgrade'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Quick directory access
alias dl='cd ~/Downloads'
alias docs='cd ~/Documents'
alias dev='cd ~/Development'

# Enable color support
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Productivity
alias h='history'
alias j='jobs -l'
alias c='clear'

# System info aliases for Linux
alias meminfo='free -h'
alias cpuinfo='lscpu'
alias diskinfo='df -h'
alias processinfo='htop'

# Clipboard aliases (Linux)
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

# Key bindings
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^P' up-line-or-search
bindkey '^N' down-line-or-search

# Auto-rehash commands
zstyle ':completion:*' rehash true

# Better completion
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Load local configurations if they exist
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Bun Configuration
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Load sensitive environment variables from secure file
if [ -f ~/.shell_secrets ]; then
    source ~/.shell_secrets
fi

# Source FZF if installed via package manager
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh