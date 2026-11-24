#!/bin/sh
# Start the Typesense Dashboard behind a Caddy login on Railway.
#
# The dashboard's config.json (with the Typesense admin key, for autologin)
# is only served after the basic-auth login. Bad deploy-form values never
# stop the deploy (STANDARD 8.29): a missing or short password locks the
# login with a random password and the log says how to fix it.
set -eu

log() { echo "railway-dashboard: $*" >&2; }

case "${PORT:-}" in
  ''|*[!0-9]*) log "PORT='${PORT:-}' is not a number, using 8080"; PORT=8080 ;;
esac
if [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then log "PORT=$PORT is out of range, using 8080"; PORT=8080; fi
export PORT

user="${DASHBOARD_USERNAME:-admin}"
if ! printf '%s' "$user" | grep -Eq '^[A-Za-z0-9._@-]{1,64}$'; then
  log "DASHBOARD_USERNAME may only use letters, digits and . _ @ - (1-64 chars), using 'admin'"
  user=admin
fi
export DASHBOARD_USERNAME="$user"

pass="${DASHBOARD_PASSWORD:-}"
pass_len=$(printf '%s' "$pass" | wc -c | tr -d ' ')
if [ "$pass_len" -lt 12 ] || [ "$pass_len" -gt 72 ]; then
  log "WARNING: DASHBOARD_PASSWORD must be 12-72 characters (got $pass_len)."
  log "WARNING: the dashboard login is LOCKED with a random password nobody knows."
  log "WARNING: set DASHBOARD_PASSWORD in the service variables and redeploy."
  pass=$(head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)
fi
DASHBOARD_PASSWORD_HASH=$(caddy hash-password --plaintext "$pass")
export DASHBOARD_PASSWORD_HASH
unset pass DASHBOARD_PASSWORD

host="${TYPESENSE_HOST:-}"
port="${TYPESENSE_PORT:-8108}"
case "$port" in ''|*[!0-9]*) log "TYPESENSE_PORT='$port' is not a number, using 8108"; port=8108 ;; esac
if [ -z "$host" ]; then
  log "WARNING: TYPESENSE_HOST is empty; the dashboard cannot reach Typesense until it is set."
  host=127.0.0.1
fi
case "$host" in *:*) host="[$host]" ;; esac
export TYPESENSE_UPSTREAM="http://$host:$port"

# Autologin config: the admin key goes to the browser only after the login.
key=$(printf '%s' "${TYPESENSE_API_KEY:-}" | sed 's/\\/\\\\/g; s/"/\\"/g')
umask 022
cat > /srv/config.json <<JSON
{
  "apiKey": "$key",
  "node": {
    "host": "SAME",
    "path": "/api"
  }
}
JSON
unset key TYPESENSE_API_KEY TYPESENSE_DASHBOARD_CONFIG

log "dashboard on :$PORT (login '$DASHBOARD_USERNAME'), Typesense API proxied at /api -> $TYPESENSE_UPSTREAM"
exec caddy run --config /etc/railway/Caddyfile --adapter caddyfile
