# Project Patterns
<!-- CC10X MEMORY CONTRACT: Do not rename headings. Used as Edit anchors. -->

## Architecture Patterns
- Personal scripts collection organized in flat directory structure

## Code Conventions
- Bash scripts with shebang `#!/usr/bin/env bash`
- Description comment: `# Description: ...` for scripts.list integration
- Executable permissions required

## File Structure
- Scripts in root directory
- Design docs in `docs/plans/`
- All scripts follow pattern: `category.action` naming

## Testing Patterns
- Manual testing via direct execution

## Common Gotchas
- None yet

## API Patterns
- None

## Error Handling
- Scripts use `set -euo pipefail` for safety

## Dependencies
- Required: fzf (interactive selection), jq (JSON processing)
- Optional: bat (syntax highlighting), awscli, saml2aws, kubectl, restish, go
- All installable via Homebrew
