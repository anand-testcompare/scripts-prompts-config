# shell-extras.zsh — Source from ~/.zshrc on macOS machines.
# Adds Codex feature banner and Claude Code env overrides.

# Claude Code: always use max effort
export CLAUDE_CODE_EFFORT_LEVEL=max

# Codex: print feature flags that differ from defaults before each launch
export CODEX_FEATURE_MODE=nondefault
if [[ -f "$HOME/scripts-prompts-config/universal/codex-shell-tools.sh" ]]; then
  source "$HOME/scripts-prompts-config/universal/codex-shell-tools.sh"
fi
