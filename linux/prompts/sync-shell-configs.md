# Shell Configuration Sync Prompt

## Purpose
Keep bash and zsh configurations synchronized to ensure consistent development environment across both shells.

## Main Prompt

Analyze my `.bashrc` and `.zshrc` files and identify any development tools, environment variables, PATH modifications, or configurations that exist in one shell but not the other. 

Please check and sync:

### 1. Development Tools
- NVM/Node.js configuration
- Bun, Deno, or other JS runtimes
- Python tools (pyenv, pipx, poetry, conda)
- Ruby tools (rbenv, rvm)
- Rust/Cargo configuration
- Go environment variables
- Java/SDKMAN configuration
- Any other language version managers

### 2. PATH Modifications
- ~/.local/bin
- Tool-specific bin directories
- Custom script directories

### 3. Environment Variables
- API keys and tokens (note them but don't auto-sync for security)
- Tool-specific environment variables
- Development environment settings

### 4. Shell Features
- Aliases that would work in both shells
- Common functions (if compatible)
- Completion configurations
- History settings

### 5. Third-party Tools
- FZF configuration
- Docker/Podman settings
- Cloud CLI tools (AWS, GCP, Azure)
- Database client configurations

## Instructions

For each difference found:
- Explain what's missing where
- Add missing configs to the appropriate file
- Maintain each file's existing style and organization
- Flag any shell-specific configs that can't be directly ported

After syncing, test both shells to ensure the critical tools work correctly.

## Quick Test Commands

After running the sync, verify with:

```bash
# In bash
source ~/.bashrc
echo $SHELL
node --version
bun --version
echo $PATH

# In zsh  
source ~/.zshrc
echo $SHELL
node --version
bun --version
echo $PATH
```

## Usage

Run this prompt:
- After installing new development tools
- When switching between terminals and noticing missing commands
- As part of regular system maintenance
- After updating either .bashrc or .zshrc manually

## Notes

- Some configurations are shell-specific and cannot be directly ported
- Security-sensitive environment variables should be reviewed manually
- Shell-specific syntax differences should be respected (e.g., array handling)
- Test thoroughly after syncing to ensure nothing breaks