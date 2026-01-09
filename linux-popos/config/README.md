# Linux Configuration Directory

This directory is the target location for Linux backups created by `backup-configs.sh`. In this repository, only templates and documentation are committed by default; actual configs are created locally when you run a backup.

## Directory Contents

### Shell Configurations (created locally by backups)

- `.bashrc` - Bash shell configuration with development tools and aliases
- `.bashrc_dev` - Additional development-specific bash configuration
- `.zshrc` - Zsh configuration with Oh My Posh, plugins, and modern tools
- `.shell_secrets.template` - Template for API keys and sensitive environment variables

### Git Configuration

- `.gitconfig` - Git user settings, aliases, and preferences
- `.gitignore_global` - Global gitignore patterns

### Application Configurations (created locally by backups)

- `.claude/CLAUDE.md` - Personal Claude instructions and preferences
- `.config/kitty/` - Kitty terminal emulator configuration
- `.config/ohmyposh/` - Oh My Posh prompt themes and configurations

### Backup Manifest (created locally by backups)

- `BACKUP_MANIFEST.txt` - Auto-generated list of files in the last backup with timestamp and host information

## Security Status

Committed files in this directory are verified to be free of:

- API keys or tokens
- Passwords or credentials
- Private SSH keys
- Any other sensitive data

Sensitive information should only be stored in `.shell_secrets` (not tracked) using the provided template as a guide.
Review any locally generated backups for secrets before committing them.

### Intentionally Excluded

The backup/restore scripts skip these files because they can contain tokens or history:

- `~/.mcp.json`
- `~/.claude.json`

## Usage

These files are automatically managed by the backup and restore scripts:

### To update configs in this directory

```bash
cd ../
./backup-configs.sh
```

### To restore configs from this directory

```bash
cd ../
./restore-configs.sh
```

## File Permissions

The restore script automatically sets appropriate permissions:

- `.shell_secrets`: 600 (user read/write only)
- Regular configs: Standard user permissions
- Executable scripts: Preserved from backup

## Customization

Before restoring on a new system, you may want to review and customize:

1. `.gitconfig` - Update user name and email
2. `.shell_secrets.template` - Prepare your API keys
3. Terminal configs - Adjust for your display/preferences

## Shell Feature Matrix

| Feature             | Bash (.bashrc) | Zsh (.zshrc) |
| ------------------- | -------------- | ------------ |
| NVM                 | ✅             | ✅           |
| Bun                 | ✅             | ✅           |
| Git aliases         | ✅             | ✅           |
| Safety aliases      | ✅             | ✅           |
| Dev tools           | ✅             | ✅           |
| Oh My Posh          | ❌             | ✅           |
| Syntax highlighting | ❌             | ✅           |
| Auto-suggestions    | ❌             | ✅           |
| FZF integration     | ✅             | ✅           |
| Modern CLI tools    | ✅             | ✅           |
| Secret masking      | ❌             | ✅           |

## Secret Masking

The `cat` function (powered by bat) automatically masks sensitive values when viewing env-like files:

```bash
cat .env
# Output:
# DATABASE_URL=postgres://user:********@localhost/mydb
# API_KEY=********
# JWT_SECRET=********
```

**Masked patterns**:
- Keys containing: KEY, TOKEN, SECRET, PASSWORD, PASS, PWD, PRIVATE, JWT, COOKIE, SESSION, API, CREDENTIAL, AUTH
- Inline URL credentials: `://user:password@` → `://user:********@`

**Affected files**: `.env`, `.env.*`, `*.env`, `.envrc`, `*.local`, `.staging`, `*.staging`

**Scan all env files in a directory** (uses the shell function, so secrets are masked):

```bash
find ~/Development -maxdepth 4 -name '.env*' -type f | while read -r f; do echo "=== $f ==="; cat "$f"; echo; done
```

Note: Don't use `find -exec cat` as it bypasses the shell function and shows secrets in plain text.

## Sync Maintenance

To keep bash and zsh synchronized, use the prompt in:

```
../prompts/sync-shell-configs.md
```

This ensures both shells have access to the same development tools and environment settings.
