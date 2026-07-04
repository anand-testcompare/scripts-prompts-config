# shell-extras.zsh — Source from ~/.zshrc on macOS machines.
# Adds Codex feature banner and Claude Code shell helpers.

# Codex: print all feature flags before each launch; green means the value differs from the default baseline
export CODEX_FEATURE_MODE=all
if [[ -f "$HOME/scripts-prompts-config/universal/codex-shell-tools.sh" ]]; then
  source "$HOME/scripts-prompts-config/universal/codex-shell-tools.sh"
fi

# pnpm: standard package manager. Keep Corepack non-interactive and expose common shortcuts.
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
if [[ -d "$PNPM_HOME" && ":$PATH:" != *":$PNPM_HOME:"* ]]; then
  export PATH="$PNPM_HOME:$PATH"
fi

alias p='pnpm'
alias pi='pnpm install'
alias pa='pnpm add'
alias pad='pnpm add --save-dev'
alias px='pnpm dlx'
alias prun='pnpm run'
