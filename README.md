# Personal Scripts Collection

A curated collection of utility scripts for AWS, Kubernetes, lakeFS, and other development tools.

## Features

- **Interactive Selection**: Most scripts use `fzf` for interactive selection menus
- **AWS Integration**: Profile management, EKS cluster access, and secrets retrieval
- **lakeFS Tools**: Configuration management and display utilities
- **Shell Utilities**: Alias management and script browsing

## Prerequisites

### Required Tools

| Tool | Purpose | Installation |
|------|---------|--------------|
| **bash** | Shell interpreter | Pre-installed on macOS |
| **zsh** | Shell interpreter (for add.alias) | Pre-installed on macOS |
| **fzf** | Interactive fuzzy finder | `brew install fzf` |
| **jq** | JSON processor | `brew install jq` |

### Optional Tools

| Tool | Required By | Purpose | Installation |
|------|-------------|---------|--------------|
| **bat** | lakectl.cat | Syntax highlighting | `brew install bat` |
| **AWS CLI** | aws.* scripts | AWS operations | `brew install awscli` |
| **saml2aws** | aws.login | AWS SAML authentication | `brew install saml2aws` |
| **kubectl** | generate.token, aws.eks.update | Kubernetes cluster access | `brew install kubectl` |
| **restish** | restish.prepare | REST API client | `brew install restish` |

### Language Requirements

| Language | Required By | Installation |
|----------|-------------|--------------|
| **Go 1.x+** | ctl/ (scriptctl) | `brew install go` |

## Installation

### Quick Start

Run the init script to automatically install all missing dependencies:

```bash
./init
```

The init script will:
1. Check for Homebrew (install if missing)
2. Check each required and optional dependency
3. Install missing dependencies via Homebrew
4. Report any tools that need manual installation

### Manual Installation

If you prefer to install dependencies manually:

```bash
# Required tools
brew install fzf jq

# Optional tools (install as needed)
brew install bat awscli saml2aws kubectl restish go
```

## Scripts Overview

### AWS Tools

- **aws.login** - Login to AWS profile and export credentials (requires saml2aws)
- **aws.eks.update** - Update kubeconfig for EKS cluster with interactive selection
- **aws.secret** - Retrieve AWS secrets with interactive profile selection

### lakeFS Tools

- **lakectl.set** - Set active lakectl configuration profile
- **lakectl.cat** - Display lakectl config with syntax highlighting

### Kubernetes Tools

- **generate.token** - Generate superadmin JWT token from lakeFS cloud control plane

### REST API Tools

- **restish.prepare** - Generate token and update restish config with bearer authorization

### Shell Utilities

- **add.alias** - Add a new alias to ~/.aliases and reload .zshrc
- **scripts.list** - Interactive script browser and launcher

### Development Tools

- **ctl/** - Go-based script control utility (requires Go for compilation)

## Usage Examples

### Interactive Script Browser

List all scripts with descriptions and run interactively:

```bash
./scripts.list
```

List scripts without running:

```bash
./scripts.list --list
```

### AWS Workflow

```bash
# Login to AWS
eval "$(./aws.login)"

# Update kubeconfig for EKS cluster
./aws.eks.update

# Retrieve a secret
./aws.secret my-app/database-password
```

### lakeFS Workflow

```bash
# Set active lakectl profile
./lakectl.set dev

# View current configuration
./lakectl.cat
```

### Adding Custom Aliases

```bash
./add.alias gs "git status"
./add.alias k "kubectl"
```

## Configuration

### AWS Configuration

Scripts expect AWS profiles configured in `~/.aws/config`:

```ini
[profile cloud-staging]
region = us-east-1
```

### lakeFS Configuration

The `lakectl.set` script expects YAML config files in:

```
~/code/treeverse/config/*.yaml
```

Example config structure:

```yaml
credentials:
  access_key_id: YOUR_KEY
  secret_access_key: YOUR_SECRET
server:
  endpoint_url: https://your-endpoint.com/api/v1
```

## Script Conventions

All scripts follow these conventions:

- **Shebang**: `#!/usr/bin/env bash` (or `#!/bin/zsh` for zsh-specific)
- **Error Handling**: `set -euo pipefail` for safety
- **Description**: `# Description: ...` comment for scripts.list integration
- **Usage Help**: `--help` or `-h` flag displays usage information
- **Interactive Mode**: Most scripts support both CLI arguments and interactive selection

## Development

### Building scriptctl

The `ctl/` directory contains a Go-based utility:

```bash
cd ctl
make build
```

### Adding New Scripts

1. Create script file in repository root
2. Add shebang: `#!/usr/bin/env bash`
3. Add description comment: `# Description: Your description`
4. Make executable: `chmod +x your-script`
5. Test with: `./scripts.list`

## Troubleshooting

### fzf Not Found

```bash
brew install fzf
```

### AWS CLI Errors

Ensure you're logged in:

```bash
eval "$(./aws.login)"
```

### kubectl Context Issues

Update your kubeconfig:

```bash
./aws.eks.update
```

### lakectl Config Not Found

Create config files in `~/code/treeverse/config/` or adjust `CONFIG_DIR` in `lakectl.set`.

## Directory Structure

```
.
├── README.md              # This file
├── init                   # Dependency installer
├── scripts.list           # Interactive script browser
├── add.alias              # Alias management
├── aws.login              # AWS authentication
├── aws.eks.update         # EKS kubeconfig management
├── aws.secret             # AWS secrets retrieval
├── lakectl.set            # lakeFS profile switcher
├── lakectl.cat            # lakeFS config viewer
├── generate.token         # Token generation
├── restish.prepare        # REST API setup
└── ctl/                   # Go-based utilities
    ├── Makefile
    ├── README.md
    ├── cmd/
    ├── go.mod
    └── scriptctl          # Compiled binary
