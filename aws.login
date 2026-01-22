#!/usr/bin/env bash
# Description: Login to AWS profile and export credentials
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  awslogin [profile] [--region <region>]

Examples:
  eval "$(awslogin)"                              # interactive profile selection
  eval "$(awslogin cloud-staging)"
  eval "$(awslogin cloud-staging --region us-east-1)"

Notes:
  - This command prints shell export statements on stdout.
  - Use it with eval (or a shell function wrapper) to set the active profile in your current shell.
  - If no profile is provided, an interactive selector will be shown (requires fzf).
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

# If first arg looks like a profile (not a flag), use it; otherwise do interactive selection
if [[ $# -ge 1 && ! "$1" =~ ^- ]]; then
  profile="$1"
  shift
else
  # Interactive profile selection with fzf
  if ! command -v fzf >/dev/null 2>&1; then
    echo "error: fzf is required for interactive selection. Install with: brew install fzf" >&2
    exit 127
  fi

  profiles=$(aws configure list-profiles 2>/dev/null) || {
    echo "error: failed to list AWS profiles" >&2
    exit 1
  }

  if [[ -z "$profiles" ]]; then
    echo "error: no AWS profiles configured" >&2
    exit 1
  fi

  profile=$(echo "$profiles" | fzf --prompt="Select AWS profile: " --height=~50% --reverse) || {
    echo "error: no profile selected" >&2
    exit 1
  }
fi

region=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --region|-r)
      if [[ $# -lt 2 ]]; then
        echo "error: --region requires a value" >&2
        exit 2
      fi
      region="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if ! command -v saml2aws >/dev/null 2>&1; then
  echo "error: saml2aws not found in PATH" >&2
  exit 127
fi

cmd=(saml2aws -a "$profile")
if [[ -n "$region" ]]; then
  cmd+=(--region "$region")
fi
cmd+=(login --profile "$profile")

# Keep stdout clean (so command substitution / eval only sees exports).
"${cmd[@]}" 1>&2

printf 'export AWS_PROFILE=%q\n' "$profile"
printf 'export AWS_DEFAULT_PROFILE=%q\n' "$profile"

if [[ -n "$region" ]]; then
  printf 'export AWS_REGION=%q\n' "$region"
  printf 'export AWS_DEFAULT_REGION=%q\n' "$region"
fi

if [[ -t 1 ]]; then
  echo >&2
  echo "To apply to your current shell:" >&2
  echo "  eval \"\$(${0} ${profile}${region:+ --region ${region}})\"" >&2
fi
