# shell-extras.zsh — Source from ~/.zshrc on macOS machines.
# Adds Codex feature banner and Claude Code env overrides.

# Claude Code: always use max effort
export CLAUDE_CODE_EFFORT_LEVEL=max

# Codex: print all feature flags before each launch; green means the value differs from the default baseline
export CODEX_FEATURE_MODE=all
if [[ -f "$HOME/scripts-prompts-config/universal/codex-shell-tools.sh" ]]; then
  source "$HOME/scripts-prompts-config/universal/codex-shell-tools.sh"
fi
