#!/usr/bin/env bash
# Description: Update kubeconfig for an EKS cluster with interactive selection
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  aws.eks.update [--profile PROFILE] [--region REGION] [--name CLUSTER]

Examples:
  aws.eks.update                                    # fully interactive
  aws.eks.update --profile cloud-staging            # interactive region/cluster
  aws.eks.update --profile cloud-staging --region us-east-1 --name lakefs-cloud

Notes:
  - Interactively selects AWS profile, region, and EKS cluster
  - After selecting profile and region, queries available clusters
  - Requires fzf for interactive selection
EOF
}

# Check for fzf
if ! command -v fzf >/dev/null 2>&1; then
  echo "error: fzf is required. Install with: brew install fzf" >&2
  exit 127
fi

# Parse arguments
PROFILE=""
REGION=""
CLUSTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --name)
      CLUSTER="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Select profile if not provided
if [[ -z "$PROFILE" ]]; then
  profiles=$(aws configure list-profiles 2>/dev/null) || {
    echo "error: failed to list AWS profiles" >&2
    exit 1
  }

  if [[ -z "$profiles" ]]; then
    echo "error: no AWS profiles configured" >&2
    exit 1
  fi

  PROFILE=$(echo "$profiles" | fzf --prompt="Select AWS profile: " --height=~50% --reverse) || {
    echo "error: no profile selected" >&2
    exit 1
  }
fi
echo "Using profile: $PROFILE" >&2

# Select region if not provided
if [[ -z "$REGION" ]]; then
  regions="us-east-1
us-east-2
us-west-1
us-west-2
eu-west-1
eu-west-2
eu-central-1
ap-southeast-1
ap-southeast-2
ap-northeast-1"

  REGION=$(echo "$regions" | fzf --prompt="Select region: " --height=~50% --reverse) || {
    echo "error: no region selected" >&2
    exit 1
  }
fi
echo "Using region: $REGION" >&2

# Select cluster if not provided
if [[ -z "$CLUSTER" ]]; then
  echo "Fetching EKS clusters..." >&2
  clusters=$(aws eks list-clusters --profile "$PROFILE" --region "$REGION" --query 'clusters[]' --output text 2>/dev/null | tr '\t' '\n') || {
    echo "error: failed to list EKS clusters. Are you logged in?" >&2
    exit 1
  }

  if [[ -z "$clusters" ]]; then
    echo "error: no EKS clusters found in $REGION" >&2
    exit 1
  fi

  CLUSTER=$(echo "$clusters" | fzf --prompt="Select EKS cluster: " --height=~50% --reverse) || {
    echo "error: no cluster selected" >&2
    exit 1
  }
fi
echo "Using cluster: $CLUSTER" >&2

# Update kubeconfig
echo "Updating kubeconfig..." >&2
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER" --profile "$PROFILE"
