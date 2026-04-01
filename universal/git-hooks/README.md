# Universal Git Hooks

## commit-msg Hook

This hook prevents commits with automated Claude/Anthropic branding or attribution patterns while allowing legitimate mentions in other contexts.

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
- References to "noreply@" (catches AI-tool co-author trailers by email)

If these specific patterns are found, it blocks the commit and provides a tip on how to disable the attribution in your tool settings.

Uses `-E` (extended regex) for portability across GNU grep (Linux) and BSD grep (macOS). The original `\|` basic-regex alternation silently fails on BSD grep, allowing commits through on macOS.

### Testing

Try to commit with a message containing an automated attribution:
```bash
git commit -m "Added feature

Co-authored-by: Claude <noreply@anthropic.com>"
# Should fail with error message
```

Normal commits and mentions of "Claude" in regular sentences work fine:
```bash
git commit -m "Integrated Claude API into the backend"
# Should succeed
```
