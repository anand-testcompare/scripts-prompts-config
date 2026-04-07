export PATH=$HOME/.local/bin:$PATH
if [[ -d "$HOME/.cargo/bin" ]] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

. "$HOME/.local/share/../bin/env"
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# fzf integration (Ctrl+R for history, Ctrl+T for files, Alt+C for cd)
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# Treat multi-line pastes as a single block in ZLE (no auto-accept on newline)
if [[ $- == *i* ]]; then
  autoload -Uz bracketed-paste-magic
  zle -N bracketed-paste bracketed-paste-magic
  bindkey -M emacs '^[[200~' bracketed-paste
  bindkey -M viins '^[[200~' bracketed-paste
fi

# zoxide replaces cd (learns your frequently used directories)
eval "$(zoxide init zsh --cmd cd)"

# zsh-history-substring-search keybindings (UP/DOWN arrow to search history)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
eval "$(starship init zsh)"

eval "$(mise activate zsh)"
export PATH="/home/anandpant/.cache/.bun/bin:$PATH"

export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

export CODEX_FEATURE_MODE=nondefault
if [[ -f "$HOME/scripts-prompts-config/universal/codex-shell-tools.sh" ]]; then
  source "$HOME/scripts-prompts-config/universal/codex-shell-tools.sh"
fi

alias pbcopy='wl-copy'
alias pbpaste='wl-paste'

# File system (from omarchy)
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias tree='eza --tree --icons --group-directories-first --git-ignore --level=1'
alias lta='lt -a'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
# Use bat for cat, but mask secrets in env-like files
cat() {
  if [[ $# -eq 0 ]]; then
    command bat
    return
  fi

  local file="$1"
  local basename="${file:t}"

  case "$basename" in
    .env|.env.*|*.env|*.env.*|.envrc|*.local|.staging|*.staging|*.staging.*)
      command bat --style=plain "$file" \
        | sed -E \
          -e 's/^([[:space:]]*(export[[:space:]]+)?[^#=]*(KEY|TOKEN|SECRET|PASSWORD|PASS|PWD|PRIVATE|JWT|COOKIE|SESSION|API|CREDENTIAL|AUTH)[^=]*=).+/\1********/I' \
          -e 's|(://[^/:]*:)[^@]+(@)|\1********\2|g' \
        | command bat --style=plain -l env --paging=never
      ;;
    *)
      command bat "$@"
      ;;
  esac
}

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tools
alias d='docker'
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }
open() { xdg-open "$@" >/dev/null 2>&1 & }

# Media helpers
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress="tar -xzf"
transcode-video-1080p() { ffmpeg -i $1 -vf scale=1920:1080 -c:v libx264 -preset fast -crf 23 -c:a copy ${1%.*}-1080p.mp4; }
transcode-video-4K() { ffmpeg -i $1 -c:v libx265 -preset slow -crf 24 -c:a aac -b:a 192k ${1%.*}-optimized.mp4; }
img2jpg() { img="$1"; shift; magick "$img" $@ -quality 95 -strip ${img%.*}-optimized.jpg; }
img2jpg-small() { img="$1"; shift; magick "$img" $@ -resize 1080x\> -quality 95 -strip ${img%.*}-optimized.jpg; }
img2png() { img="$1"; shift; magick "$img" $@ -strip -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all "${img%.*}-optimized.png"; }

# secrets (API keys, credentials) - stored separately
if [[ -f ~/.shell_secrets ]]; then
  source ~/.shell_secrets
  export SHELL_SECRETS_SOURCED=1
fi

fpath+=~/.zfunc; autoload -Uz compinit; compinit
[ -f /usr/share/zsh/plugins/fzf-tab-source/fzf-tab.plugin.zsh ] && source /usr/share/zsh/plugins/fzf-tab-source/fzf-tab.plugin.zsh

zstyle ':completion:*' menu select
# Smarter tab completion: case-insensitive + fuzzy separators
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=** r:|=**' 'l:|=* r:|=*'
# fzf-tab: fuzzy, case-insensitive matching
zstyle ':fzf-tab:*' fzf-flags --ansi --height=60% --layout=reverse --border --ignore-case

# opencode
export PATH=/home/anandpant/.opencode/bin:$PATH

# Drop broken Nix profile path if user profile isn't set up.
# (Some tools scan PATH and error on non-existent directories.)
if [[ ! -d "$HOME/.nix-profile/bin" ]]; then
  path=(${path:#$HOME/.nix-profile/bin})
fi

# bun completions
[ -s "/home/anandpant/.bun/_bun" ] && source "/home/anandpant/.bun/_bun"




# >>> meshix-cli install >>>
export PATH="/home/anandpant/.local/bin:$PATH"
if [ -f "/home/anandpant/.meshix/install/completions/meshix-cli.zsh" ]; then
  autoload -Uz compinit 2>/dev/null || true
  if ! command -v compdef >/dev/null 2>&1; then
    compinit -i >/dev/null 2>&1 || true
  fi
  source "/home/anandpant/.meshix/install/completions/meshix-cli.zsh"
fi
# <<< meshix-cli install <<<


# sentry
fpath=("/home/anandpant/.local/share/zsh/site-functions" $fpath)

# Claude Code – max effort on supported models (overrides effortLevel in settings.json)
export CLAUDE_CODE_EFFORT_LEVEL=max

# Launch Claude Code with oh-my-claudecode: `omc` enables OMC for the
# session, plain `claude` runs vanilla (the default in settings.json).
omc() {
  local settings="$HOME/.claude/settings.json"
  local vanilla_sl="bash $HOME/scripts-prompts-config/universal/claude-statusline.sh"
  local omc_sl='node $HOME/.claude/hud/omc-hud.mjs'

  # flip to OMC
  local tmp=$(mktemp)
  jq '
    .enabledPlugins["oh-my-claudecode@omc"] = true |
    .statusLine.command = "'"$omc_sl"'"
  ' "$settings" > "$tmp" && mv "$tmp" "$settings"

  # run claude, then restore vanilla on exit
  claude "$@"
  local rc=$?

  tmp=$(mktemp)
  jq '
    .enabledPlugins["oh-my-claudecode@omc"] = false |
    .statusLine.command = "'"$vanilla_sl"'"
  ' "$settings" > "$tmp" && mv "$tmp" "$settings"

  return $rc
}

# Turso
export PATH="$PATH:/home/anandpant/.turso"

# Depot CLI
export DEPOT_INSTALL_DIR="/home/anandpant/.depot/bin"
export PATH="$DEPOT_INSTALL_DIR:$PATH"
