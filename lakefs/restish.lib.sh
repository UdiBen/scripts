#!/usr/bin/env bash
# restish.lib.sh — shared helpers for control-plane restish tooling.
#
# Source this file; do not execute it. The caller owns its own `set`
# options. Requires: kubectl, jq, fzf, curl, and the create.api.token script.

RESTISH_CONFIG="${RESTISH_CONFIG:-$HOME/Library/Application Support/restish/apis.json}"
CP_API_DIR="${CP_API_DIR:-$HOME/code/treeverse/cloud-controlplane/service/api}"

# fzf with the last selection sorted to the top.
#   echo "$items" | fzf_with_last <last_value> <prompt> [exact|prefix]
fzf_with_last() {
  local last="$1" prompt="$2" match_mode="${3:-exact}"
  local items
  items=$(cat)
  if [[ -n "$last" ]]; then
    local matched rest
    if [[ "$match_mode" == "prefix" ]]; then
      matched=$(echo "$items" | grep "^${last}" | head -1) || true
    else
      matched=$(echo "$items" | grep -xF "$last" | head -1) || true
    fi
    if [[ -n "$matched" ]]; then
      rest=$(echo "$items" | grep -vxF "$matched")
      items="${matched}"$'\n'"${rest}"
    fi
  fi
  echo "$items" | fzf --exact --prompt="$prompt" --height=~50% --reverse
}

# Echo the control-plane namespace for the current kubectl context.
# Honors $CONTROLPLANE_NAMESPACE. Prompts (fzf) when several exist.
#   cp_detect_namespace [last_namespace]
cp_detect_namespace() {
  local last="${1:-}"
  if [[ -n "${CONTROLPLANE_NAMESPACE:-}" ]]; then
    echo "$CONTROLPLANE_NAMESPACE"
    return 0
  fi
  if ! kubectl config current-context >/dev/null 2>&1; then
    echo "error: no kubectl context set. Run: aws.login && kube.connect" >&2
    return 2
  fi
  local all cp count
  all=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null) || {
    echo "error: cannot reach the cluster (AWS credentials may be expired). Run: aws.login && kube.connect" >&2
    return 2
  }
  cp=$(echo "$all" | tr ' ' '\n' | grep control-plane) || true
  if [[ -z "$cp" ]]; then
    echo "error: no control-plane namespace found in current kubectl context" >&2
    return 2
  fi
  count=$(echo "$cp" | wc -l | tr -d ' ')
  if [[ "$count" -eq 1 ]]; then
    echo "$cp"
  else
    echo "$cp" | fzf_with_last "$last" "Select namespace: "
  fi
}

# Port-forward a control-plane service to localhost, replacing any
# process already bound to the port.
#   cp_start_port_forward <service> <local_port> <namespace>
cp_start_port_forward() {
  local svc="$1" port="$2" ns="$3"
  if lsof -ti :"$port" >/dev/null 2>&1; then
    kill "$(lsof -ti :"$port")" 2>/dev/null || true
    sleep 0.5
  fi
  kubectl port-forward "svc/$svc" "$port:80" -n "$ns" >/dev/null 2>&1 &
  echo "  $svc -> localhost:$port (pid $!)" >&2
}

# Poll a service's /_health until ready.
#   cp_wait_health <local_port> [tries]
cp_wait_health() {
  local port="$1" tries="${2:-15}" i
  for ((i = 1; i <= tries; i++)); do
    curl -sf "http://localhost:${port}/_health" >/dev/null 2>&1 && return 0
    sleep 1
  done
  echo "error: service on :$port not ready after ${tries}s" >&2
  return 3
}

# Merge a single API entry into the restish config, preserving others.
#   cp_restish_set_api <name> <base_url> <token> <spec_file>
cp_restish_set_api() {
  local name="$1" base="$2" token="$3" spec="$4" entry
  entry=$(jq -n --arg name "$name" --arg base "$base" --arg spec "$spec" --arg tok "Bearer $token" \
    '{($name): {base: $base, spec_files: [$spec],
                profiles: {default: {headers: {authorization: $tok}, auth: {name: ""}}}}}')
  mkdir -p "$(dirname "$RESTISH_CONFIG")"
  if [[ -f "$RESTISH_CONFIG" ]]; then
    jq --argjson new "$entry" '. * $new' "$RESTISH_CONFIG" >"$RESTISH_CONFIG.tmp" && mv "$RESTISH_CONFIG.tmp" "$RESTISH_CONFIG"
  else
    jq -n --argjson new "$entry" '{"$schema": "https://rest.sh/schemas/apis.json"} * $new' >"$RESTISH_CONFIG"
  fi
}

# Ensure the restish `admin` API is usable: if the port-forward is up and
# the admin entry exists, no-op; otherwise detect namespace, port-forward,
# mint a superadmin token, and write the admin config. Idempotent.
cp_ensure_admin() {
  local port=8087 svc=control-plane-admin-service ns token
  if curl -sf "http://localhost:${port}/_health" >/dev/null 2>&1 &&
    [[ -f "$RESTISH_CONFIG" ]] && jq -e '.admin.base' >/dev/null 2>&1 <"$RESTISH_CONFIG"; then
    return 0
  fi
  echo "Setting up admin API access..." >&2
  ns=$(cp_detect_namespace "") || return $?
  echo "  namespace: $ns" >&2
  cp_start_port_forward "$svc" "$port" "$ns"
  cp_wait_health "$port" 15 || return 3
  echo "  minting superadmin token..." >&2
  token=$(CONTROLPLANE_NAMESPACE="$ns" create.api.token superadmin) || {
    echo "error: failed to generate admin token" >&2
    return 2
  }
  cp_restish_set_api admin "http://localhost:${port}/api/v1" "$token" "$CP_API_DIR/admin.yml"
  rm -rf "$HOME/Library/Caches/restish/"* 2>/dev/null || true
}
