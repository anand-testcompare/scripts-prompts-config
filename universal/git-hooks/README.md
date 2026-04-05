# Universal Git Hooks

## commit-msg Hook

This hook prevents automated Claude/Anthropic attribution patterns in commits while still allowing normal mentions of Claude in regular commit text.

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
- `Generated with Claude...` attribution headers/footers
- attribution trailers such as `Co-Authored-By`, `Signed-off-by`, or `Authored-by` when they reference Claude/Anthropic identities
- git author/committer identities containing `claude`, `anthropic`, or `noreply@`

If these specific patterns are found, it blocks the commit and displays an error message.

Uses `-E` (extended regex) for portability across GNU grep (Linux) and BSD grep (macOS). The original `\|` basic-regex alternation silently fails on BSD grep, allowing commits through on macOS.

### Testing

Try to commit with a Claude attribution trailer:
```bash
git commit -m "Added feature

Co-authored-by: Claude <noreply@anthropic.com>"
# Should fail with error message
```

Normal commits and regular mentions of Claude work fine:
```bash
git commit -m "Integrate Claude API retries"
# Should succeed
```
