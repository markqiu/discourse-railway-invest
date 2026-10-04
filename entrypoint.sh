#!/bin/bash
# Boot wrapper for Discourse on Railway. Everything here is either a value Railway
# knows and Discourse does not, or a step a template deployer would otherwise have to
# run by hand. It ends in `exec /sbin/boot`, the image's own CMD, so runit still owns
# nginx, unicorn and sidekiq.
set -euo pipefail

log() { echo "[railway] $*"; }

# --- hostname --------------------------------------------------------------------
# Discourse bakes this into every generated link and /etc/runit/1.d/install-ssl exits
# non-zero without it, which fails the whole boot. Railway hands us the domain it
# generated, so a template deploy needs no input.
if [ -z "${DISCOURSE_HOSTNAME:-}" ]; then
  if [ -z "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
    log "FATAL: set DISCOURSE_HOSTNAME, or give this service a public domain."
    exit 1
  fi
  export DISCOURSE_HOSTNAME="$RAILWAY_PUBLIC_DOMAIN"
fi
log "hostname: ${DISCOURSE_HOSTNAME}"

# --- listen port -----------------------------------------------------------------
# The image ships `listen 80;` in this outlet. Railway probes $PORT for the health
# check, so the two have to agree.
PORT="${PORT:-80}"
printf 'listen %s default_server;\nlisten [::]:%s default_server;\n' "$PORT" "$PORT" \
  > /etc/nginx/conf.d/outlets/server/10-http.conf
log "nginx will listen on ${PORT}"

# The published image sometimes still ships Debian's stock nginx site, which claims
# `listen 80 default_server` and `root /var/www/html` — it then wins every request and
# the whole forum reads as a "Welcome to nginx!" page with a healthy container behind
# it. Upstream's own web template deletes it; do the same, whichever variant we got.
if [ -e /etc/nginx/sites-enabled/default ]; then
  rm -f /etc/nginx/sites-enabled/default
  log "removed the stock nginx default site"
fi
log "nginx check: $(nginx -t 2>&1 | tail -1)"

# --- bundled-plugin sanity ---------------------------------------------------------
# The published image has shipped a discourse-workflows tree whose node definitions
# reference DiscourseWorkflows::Schema constants its own schema.rb does not define.
# Rails then aborts the entire boot with "** INCOMPATIBLE PLUGIN **" — a state nobody
# deploying this can fix from the outside, and upstream's own error text says to
# remove the plugin. Do exactly that, and only when the mismatch is really there.
WORKFLOWS=/var/www/discourse/plugins/discourse-workflows
if [ -d "$WORKFLOWS/lib/discourse_workflows/nodes" ]; then
  missing=""
  for const in $(grep -rhoE 'Schema::[A-Z][A-Z0-9_]+' "$WORKFLOWS/lib/discourse_workflows/nodes" \
                 | sed 's/^Schema:://' | sort -u); do
    grep -rq "$const" "$WORKFLOWS/lib/discourse_workflows/schema.rb" \
                      "$WORKFLOWS/lib/discourse_workflows/schema" 2>/dev/null \
      || missing="${missing} ${const}"
  done
  if [ -n "$missing" ]; then
    log "disabling discourse-workflows — its nodes reference undefined Schema constants:${missing}"
    rm -rf "$WORKFLOWS"
  fi
fi

# --- first administrator ----------------------------------------------------------
# Discourse's own first-run path is `rake admin:create`, which is interactive, or a
# confirmation email to an address in developer_emails. Neither works for a template,
# so create the account here instead — once, in the background, after unicorn has
# finished migrating and is answering. The marker lives on the volume and the script
# itself bails out if any admin already exists, so an operator's later password change
# is never reverted.
ADMIN_MARKER=/shared/.railway-admin-bootstrapped
if [ -n "${ADMIN_EMAIL:-}" ] && [ -n "${ADMIN_PASSWORD:-}" ] && [ ! -f "$ADMIN_MARKER" ]; then
  (
    for _ in $(seq 1 180); do
      if curl -fsS --max-time 5 "http://127.0.0.1:${PORT}/srv/status" >/dev/null 2>&1; then
        log "app is answering; bootstrapping the first administrator"
        if /usr/local/bin/rails runner /usr/local/bin/railway-bootstrap-admin.rb; then
          touch "$ADMIN_MARKER"
        else
          log "admin bootstrap failed — it will be retried on the next deploy"
        fi
        exit 0
      fi
      sleep 10
    done
    log "app never answered /srv/status; skipping the admin bootstrap"
  ) &
else
  log "admin bootstrap skipped (already done, or ADMIN_EMAIL/ADMIN_PASSWORD unset)"
fi

exec /sbin/boot
