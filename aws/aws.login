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
  - TOTP MFA token is generated automatically via generate.mfa.token (if available).
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

STATE_FILE="$HOME/.config/aws-login/last"

# fzf with last selection sorted to the top of the list
fzf_with_last() {
  local last="$1" prompt="$2"
  local items
  items=$(cat)
  if [[ -n "$last" ]]; then
    local matched rest
    matched=$(echo "$items" | grep -xF "$last" | head -1) || true
    if [[ -n "$matched" ]]; then
      rest=$(echo "$items" | grep -vxF "$matched")
      items="${matched}"$'\n'"${rest}"
    fi
  fi
  echo "$items" | fzf --exact --prompt="$prompt" --height=~50% --reverse
}

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

  # Only show profiles that have a saml2aws account configured
  profiles=$(grep '^\[' ~/.saml2aws 2>/dev/null | tr -d '[]') || {
    echo "error: failed to list AWS profiles from ~/.saml2aws" >&2
    exit 1
  }

  if [[ -z "$profiles" ]]; then
    echo "error: no AWS profiles configured" >&2
    exit 1
  fi

  PROFILE_COUNT=$(echo "$profiles" | wc -l | tr -d ' ')
  if [[ "$PROFILE_COUNT" -eq 1 ]]; then
    profile="$profiles"
  else
    LAST_PROFILE=""
    [[ -f "$STATE_FILE" ]] && LAST_PROFILE=$(cat "$STATE_FILE")
    profile=$(echo "$profiles" | fzf_with_last "$LAST_PROFILE" "Select AWS profile: ") || {
      echo "error: no profile selected" >&2
      exit 1
    }
  fi
fi

# Save selection
mkdir -p "$(dirname "$STATE_FILE")"
echo "$profile" > "$STATE_FILE"

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

# Generate TOTP token automatically if possible
mfa_token=""
if command -v generate.mfa.token >/dev/null 2>&1; then
  mfa_token=$(generate.mfa.token 2>/dev/null) || true
fi

cmd=(saml2aws -a "$profile")
if [[ -n "$region" ]]; then
  cmd+=(--region "$region")
fi
if [[ -n "$mfa_token" ]]; then
  cmd+=(--mfa-token "$mfa_token")
fi
cmd+=(login --force --profile "$profile")

# Keep stdout clean (so command substitution / eval only sees exports).
# Try with auto-generated token first; if it fails, retry without it (manual prompt)
if ! "${cmd[@]}" 1>&2; then
  if [[ -n "$mfa_token" ]]; then
    echo "Auto MFA failed, retrying with manual prompt..." >&2
    cmd=(saml2aws -a "$profile")
    if [[ -n "$region" ]]; then
      cmd+=(--region "$region")
    fi
    cmd+=(login --force --profile "$profile")
    "${cmd[@]}" 1>&2
  else
    exit 1
  fi
fi

printf 'export AWS_PROFILE=%q\n' "$profile"
printf 'export AWS_DEFAULT_PROFILE=%q\n' "$profile"

# Resolve region: explicit flag > credentials file > aws config
if [[ -z "$region" ]]; then
  region=$(aws configure get region --profile "$profile" 2>/dev/null) || true
fi

if [[ -n "$region" ]]; then
  printf 'export AWS_REGION=%q\n' "$region"
  printf 'export AWS_DEFAULT_REGION=%q\n' "$region"
fi

if [[ -t 1 ]]; then
  echo >&2
  echo "To apply to your current shell:" >&2
  echo "  eval \"\$(${0} ${profile}${region:+ --region ${region}})\"" >&2
fi
