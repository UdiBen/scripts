# Project: Personal Scripts Collection

## Script Conventions

All scripts follow these patterns strictly:

- **Header**: `#!/usr/bin/env bash` + `# Description: ...` on line 2 + `set -euo pipefail`
- **Naming**: Dot-separated, no `.sh` extension (e.g., `kube.logs`, `aws.secret`)
- **Location**: Place in category subdirectory (`aws/`, `lakefs/`, `common/`)
- **Help**: `usage()` function using heredoc to stderr (`cat >&2 <<'EOF'`), triggered by `-h`/`--help`
- **Arguments**: Support both CLI flags and interactive selection via fzf
- **fzf**: Always check availability, use `--exact --height=~50% --reverse --prompt="..."`
- **fzf selection**: Use `fzf_with_last` for interactive selections (sorts previous choice to top). If only a single value exists, select it automatically without showing fzf.
- **Output**: Diagnostic/progress messages to stderr, data to stdout
- **Errors**: stderr with `echo "error: ..." >&2`, exit codes: 1 (general), 2 (bad args), 3 (external failure), 127 (missing dependency)
- **Dependency checks**: `command -v <tool> >/dev/null 2>&1` with helpful install instructions on failure

## Required Housekeeping

When adding, modifying, or deleting scripts:
- **README.md**: Update the Scripts Overview section, the directory tree, and the Optional Tools table if applicable
- **init script**: If a new external dependency is introduced, add a `check_tool` entry to `init`
- **Commit and push**: Once the user approves the change, commit and push to the remote
