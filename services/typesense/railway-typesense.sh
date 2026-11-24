#!/bin/sh
# Start Typesense on Railway.
#
# Deploy-form values are checked first; a bad value never stops the deploy
# (STANDARD 8.29). Typesense parses numbers with std::stoi and exits on
# garbage, so invalid numbers fall back to the default with a warning. An
# empty or short API key would stop Typesense (empty) or leave it weakly
# protected, so the API is locked with a random key and the log says how
# to fix it.
set -eu

log() { echo "railway-typesense: $*" >&2; }

# Port used by the public domain and Railway's healthcheck.
case "${PORT:-}" in
  ''|*[!0-9]*) log "PORT='${PORT:-}' is not a number, using 8108"; PORT=8108 ;;
esac
if [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ] || [ "$PORT" = 8107 ]; then
  log "PORT=$PORT is not usable (8107 is the peering port), using 8108"; PORT=8108
fi
export TYPESENSE_API_PORT="$PORT"
# "::" is dual-stack in Typesense >= 30 (IPV6_V6ONLY=0): IPv4 healthcheck
# and the IPv6/IPv4 private network both reach it.
export TYPESENSE_API_ADDRESS="::"

export TYPESENSE_DATA_DIR="${RAILWAY_VOLUME_MOUNT_PATH:-/data}"
mkdir -p "$TYPESENSE_DATA_DIR"

# Admin API key: at least 16 characters.
key_len=$(printf '%s' "${TYPESENSE_API_KEY:-}" | wc -c | tr -d ' ')
if [ "$key_len" -lt 16 ]; then
  log "WARNING: TYPESENSE_API_KEY is missing or shorter than 16 characters ($key_len)."
  log "WARNING: the API is LOCKED with a random key nobody knows. Set TYPESENSE_API_KEY"
  log "WARNING: to at least 16 characters in the service variables and redeploy."
  TYPESENSE_API_KEY=$(head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 40)
  export TYPESENSE_API_KEY
fi
# A bootstrap search-only key is deprecated upstream; create scoped keys via /keys.
unset TYPESENSE_SEARCH_ONLY_API_KEY || true

# CPU: Typesense sizes its pools from the host's core count (96 on Railway
# hosts -> 768 threads). Use the container's CPU quota instead (STANDARD 8.15).
cores=""
if [ -r /sys/fs/cgroup/cpu.max ]; then
  read -r quota period < /sys/fs/cgroup/cpu.max || true
  if [ "${quota:-max}" != max ] && [ -n "${period:-}" ] && [ "$period" -gt 0 ] 2>/dev/null; then
    cores=$(( (quota + period - 1) / period ))
  fi
fi
[ -n "$cores" ] || cores=$(nproc 2>/dev/null || echo 2)
[ "$cores" -ge 1 ] || cores=1
[ "$cores" -le 32 ] || cores=32

clamp() { # value min max
  v=$1; [ "$v" -lt "$2" ] && v=$2; [ "$v" -gt "$3" ] && v=$3; echo "$v"
}
number() { # name default
  eval "v=\${$1:-}"
  case "$v" in
    '') eval "export $1=$2" ;;
    *[!0-9]*) log "$1='$v' is not a whole number, using $2"; eval "export $1=$2" ;;
    *) eval "export $1=$v" ;;
  esac
}
number TYPESENSE_THREAD_POOL_SIZE "$(clamp $((cores * 8)) 16 128)"
number TYPESENSE_NUM_COLLECTIONS_PARALLEL_LOAD "$(clamp $((cores * 4)) 4 32)"
number TYPESENSE_CACHE_NUM_ENTRIES 1000
number TYPESENSE_SNAPSHOT_INTERVAL_SECONDS 3600

# Booleans Typesense compares with the literal "TRUE".
upper_bool() { # name default
  eval "v=\${$1:-}"
  v=$(printf '%s' "$v" | tr '[:lower:]' '[:upper:]')
  case "$v" in
    TRUE|FALSE) eval "export $1=$v" ;;
    '') eval "export $1=$2" ;;
    *) log "$1 is not true/false, using $2"; eval "export $1=$2" ;;
  esac
}
upper_bool TYPESENSE_ENABLE_CORS TRUE
# Single node whose IP changes on every redeploy: let Raft reset its peer list.
upper_bool TYPESENSE_RESET_PEERS_ON_ERROR TRUE
upper_bool TYPESENSE_ENABLE_SEARCH_ANALYTICS FALSE

[ -n "${TYPESENSE_CORS_DOMAINS:-}" ] || unset TYPESENSE_CORS_DOMAINS

log "starting Typesense on [::]:$TYPESENSE_API_PORT, data in $TYPESENSE_DATA_DIR, $cores CPU(s), thread pool $TYPESENSE_THREAD_POOL_SIZE"
exec /opt/typesense-server
