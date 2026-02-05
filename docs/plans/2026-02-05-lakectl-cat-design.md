# lakectl.cat Script Design

**Date:** 2026-02-05
**Status:** Implemented

## Purpose

Display the contents of `~/.lakectl.yaml` configuration file with syntax highlighting when available.

## Requirements

- Show lakectl configuration in a readable format
- Use syntax highlighting if `bat` is installed
- Fallback to plain `cat` if `bat` is not available
- No error handling for missing file (fail naturally)
- Follow existing scripts collection pattern

## Implementation

### Script Location
`/Users/udi/scripts/lakectl.cat`

### Approach
1. Check if `bat` command is available using `command -v`
2. If available: use `bat --language=yaml --style=numbers,grid`
3. If not available: use plain `cat`
4. Use `exec` to replace the shell process with the chosen command

### Features
- Zero configuration required
- Graceful degradation (bat → cat)
- Consistent with other scripts in the collection
- Includes description comment for `scripts.list` integration
- Simple and maintainable (~15 lines)

## Testing

Script successfully displays `~/.lakectl.yaml` with appropriate formatting based on available tools.

## Dependencies

**Optional:**
- `bat` - for syntax highlighting (gracefully degrades without it)

**Required:**
- bash
- cat (standard Unix utility)
