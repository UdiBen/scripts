# Personal Scripts Collection

A curated collection of utility scripts for AWS, Kubernetes, lakeFS, and other development tools.

## Features

- **Categorized**: Scripts organized into `aws/`, `lakefs/`, and `common/` directories
- **Interactive Selection**: Most scripts use `fzf` for interactive selection menus
- **AWS Integration**: Profile management, EKS cluster access, and secrets retrieval
- **lakeFS Tools**: Configuration management, API tokens, and restish setup
- **Shell Utilities**: Alias management, MFA token generation, and script browsing

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
| **kubectl** | kube.connect, kube.logs, create.api.token | Kubernetes cluster access | `brew install kubectl` |
| **stern** | kube.logs | Multi-pod log tailing | `brew install stern` |
| **restish** | restish.prepare | REST API client | `brew install restish` |
| **authenticator** | generate.mfa.token | TOTP token generation | `brew install authenticator` |
| **make** | lakefs.run | Build lakeFS binary | `xcode-select --install` |
| **node/npm** | lakefs.run | WebUI hot reload | `brew install node` |

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
brew install bat awscli saml2aws kubectl restish authenticator
```

### PATH Setup

Add the following to your `~/.zshrc`:

```bash
export PATH="$HOME/scripts:$HOME/scripts/aws:$HOME/scripts/lakefs:$HOME/scripts/common:$PATH"
```

This makes all scripts callable by name from anywhere.

## Scripts Overview

### aws/

- **aws.login** - Login to AWS profile and export credentials (auto-generates MFA token)
- **aws.secret** - Retrieve AWS secrets with interactive profile selection
- **kube.connect** - Update kubeconfig for an EKS cluster with interactive selection
- **kube.logs** - Tail logs of Kubernetes pods/jobs using stern (interactive selection, follow or dump)

### lakefs/

- **create.api.token** - Create a JWT token for a dev control-plane namespace
- **mirrord.prepare** - Configure and prepare a local mirrord session against a remote control-plane dev environment
- **restish.prepare** - Set up restish for admin and giam APIs with tokens and port-forwarding
- **lakectl.set** - Set active lakectl configuration profile (static configs or K8s dev environment)
- **lakectl.cat** - Display lakectl config with syntax highlighting
- **lakefs.run** - Run lakeFS locally in various modes (quickstart, custom config, webui hot reload)

### common/

- **generate.mfa.token** - Generate a JumpCloud MFA token, copy to clipboard
- **add.alias** - Add a new alias to ~/.aliases and reload .zshrc
- **kill.process** - Kill a process interactively using fzf (optional grep filter)

### Root

- **init** - Install all missing dependencies for the scripts collection
- **scripts.list** - Interactive script browser and launcher (category-first navigation)

## Usage Examples

### Interactive Script Browser

Browse by category and run interactively:

```bash
scripts.list
```

List all scripts grouped by category:

```bash
scripts.list --list
```

### AWS Workflow

```bash
# Login to AWS (MFA token generated automatically)
eval "$(aws.login)"

# Connect to an EKS cluster
kube.connect

# Retrieve a secret
aws.secret my-app/database-password
```

### lakeFS Workflow

```bash
# Set up restish for admin and giam APIs
restish.prepare

# Query organizations
restish admin list-organizations-v2-public

# Query groups
restish giam list-groups
```

### lakeFS Configuration

```bash
# Set active lakectl profile
lakectl.set dev

# View current configuration
lakectl.cat
```

### Adding Custom Aliases

```bash
add.alias gs "git status"
add.alias k "kubectl"
```

## Configuration

### AWS Configuration

Scripts expect AWS profiles configured via saml2aws (`~/.saml2aws`) and AWS config (`~/.aws/config`).

### lakeFS Configuration

Configuration files are stored in subdirectories under `~/code/treeverse/config/`:

```
~/code/treeverse/config/lakectl/    # lakectl client configs (used by lakectl.set)
~/code/treeverse/config/lakefs/     # lakeFS server configs (used by lakefs.run)
```

### MFA Token

Store your JumpCloud TOTP secret in the macOS Keychain:

```bash
security add-generic-password -a "$USER" -s "TOTP_SECRET" -w "your-totp-secret"
```

## Script Conventions

All scripts follow these conventions:

- **Shebang**: `#!/usr/bin/env bash` (or `#!/bin/zsh` for zsh-specific)
- **Error Handling**: `set -euo pipefail` for safety
- **Description**: `# Description: ...` comment for scripts.list integration
- **Usage Help**: `--help` or `-h` flag displays usage information
- **Interactive Mode**: Most scripts support both CLI arguments and interactive selection
- **Naming**: Dot-separated names, no `.sh` extension

### Adding New Scripts

1. Create script file in the appropriate category directory (`aws/`, `lakefs/`, or `common/`)
2. Add shebang: `#!/usr/bin/env bash`
3. Add description comment: `# Description: Your description`
4. Make executable: `chmod +x your-script`
5. Test with: `scripts.list`

## Directory Structure

```
.
├── README.md              # This file
├── init                   # Dependency installer
├── scripts.list           # Interactive script browser
├── aws/
│   ├── aws.login          # AWS authentication
│   ├── aws.secret         # AWS secrets retrieval
│   ├── kube.connect       # EKS kubeconfig management
│   └── kube.logs          # Pod log viewer
├── lakefs/
│   ├── create.api.token   # JWT token generation
│   ├── mirrord.prepare    # mirrord session setup
│   ├── restish.prepare    # REST API setup
│   ├── lakectl.set        # lakeFS profile switcher (+ dev environment)
│   ├── lakectl.cat        # lakeFS config viewer
│   └── lakefs.run         # Local lakeFS runner
└── common/
    ├── generate.mfa.token # MFA token generation
    ├── add.alias          # Alias management
    └── kill.process       # Interactive process killer
```

## Troubleshooting

### fzf Not Found

```bash
brew install fzf
```

### AWS CLI Errors

Ensure you're logged in:

```bash
eval "$(aws.login)"
```

### kubectl Context Issues

Update your kubeconfig:

```bash
kube.connect
```

### lakectl Config Not Found

Create config files in `~/code/treeverse/config/lakectl/` or adjust `CONFIG_DIR` in `lakectl.set`.
