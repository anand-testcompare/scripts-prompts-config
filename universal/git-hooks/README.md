# Universal Git Hooks

## commit-msg Hook

This hook prevents commits containing Claude/Anthropic branding text and is OS-agnostic.

### Installation

**Option 1: Global Git Template (Recommended)**

Set up git to use these hooks for all new repositories:

```bash
# Create git template directory if it doesn't exist
mkdir -p ~/.git-templates/hooks

# Copy the hook
cp commit-msg ~/.git-templates/hooks/

# Make it executable
chmod +x ~/.git-templates/hooks/commit-msg

# Configure git to use this template
git config --global init.templateDir ~/.git-templates
```

After this setup, all new repositories created with `git init` will automatically include this hook.

For existing repositories, run:
```bash
git init
```

**Option 2: Per-Repository Installation**

For a specific repository:

```bash
# Navigate to your repository
cd /path/to/your/repo

# Copy the hook
cp /path/to/this/commit-msg .git/hooks/

# Make it executable
chmod +x .git/hooks/commit-msg
```

### What It Does

The hook checks commit messages for:
- References to "claude" (case-insensitive)
- References to "anthropic" (case-insensitive)

If found, it blocks the commit and displays an error message.

### Testing

Try to commit with a message containing "Claude":
```bash
git commit -m "Added feature with Claude"
# Should fail with error message
```

Normal commits work fine:
```bash
git commit -m "Added new feature"
# Should succeed
```
