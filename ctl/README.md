# scriptctl

A simple CLI tool to manage and run your custom scripts, inspired by lakectl.

## Features

- Discover and run scripts from `~/scripts` directory
- Infer script extensions automatically (.sh, .py, .rb, .js, .ts)
- Pass arguments directly to scripts
- List all available scripts

## Installation

```bash
cd ~/scripts/ctl
make install
```

This will build the binary and copy it to `~/.local/bin/scriptctl` (make sure `~/.local/bin` is in your PATH).

## Usage

### List available scripts

```bash
scriptctl list
```

### Run a script

```bash
# Run hello.sh
scriptctl hello

# Run with arguments
scriptctl hello arg1 arg2
```

The tool will automatically find `hello.sh`, `hello.py`, etc. in your `~/scripts` directory.

### Custom scripts directory

```bash
scriptctl --scripts-dir /path/to/scripts list
scriptctl --scripts-dir /path/to/scripts myscript
```

## Adding Scripts

1. Create an executable script in `~/scripts`:

```bash
echo '#!/bin/bash
echo "Hello from my script!"
echo "Args: $@"' > ~/scripts/myscript.sh

chmod +x ~/scripts/myscript.sh
```

2. Run it with scriptctl:

```bash
scriptctl myscript arg1 arg2
```

## Supported Script Extensions

- `.sh` - Shell scripts
- `.py` - Python scripts
- `.rb` - Ruby scripts
- `.js` - JavaScript scripts
- `.ts` - TypeScript scripts

## Project Structure

```
~/scripts/ctl/
├── cmd/scriptctl/
│   ├── main.go           # Entry point
│   └── cmd/
│       ├── root.go       # Root command and script execution
│       └── list.go       # List command
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

## Development

```bash
# Build
make build

# Install locally
make install

# Clean
make clean
```

## How it works

scriptctl is built using:
- [cobra](https://github.com/spf13/cobra) for CLI framework
- [go-homedir](https://github.com/mitchellh/go-homedir) for home directory resolution

When you run `scriptctl <script-name>`:
1. It checks if `<script-name>` is a built-in command (like `list`)
2. If not, it looks for a script in `~/scripts` with any supported extension
3. It executes the script with the provided arguments

Similar to how lakectl handles plugins, scriptctl treats unknown commands as potential scripts to execute.
