# discourse-railway

A thin wrapper around [`discourse/discourse`](https://hub.docker.com/r/discourse/discourse),
upstream's own prebuilt Discourse image, so a forum can be deployed on
[Railway](https://railway.com) from a template with no manual first-run steps.

The application is never rebuilt. This repo adds exactly three things:

1. **Real client IPs.** Discourse's bundled nginx config sends
   `X-Forwarded-For $remote_addr`, which behind Railway's edge is a `100.64.0.0/10`
   address rather than the visitor. Every visitor would then land in the same per-IP
   rate-limit bucket. `nginx/10-real-client-ip.conf` takes the leftmost entry of the
   incoming header instead, which Railway's edge overwrites and is therefore
   trustworthy.
2. **A listen port Railway can probe.** The image ships `listen 80;`; the entrypoint
   rewrites that outlet from `$PORT` so the health check and the served port agree.
3. **The first administrator.** Upstream creates it with the interactive
   `rake admin:create` or with a confirmation email. `bootstrap-admin.rb` does the same
   steps from `ADMIN_EMAIL` / `ADMIN_PASSWORD`, once, in the background, after the
   boot-time migration has finished. It does nothing at all if any administrator
   already exists, so a password changed later in the UI is never reverted.

## Required environment

| Variable | Notes |
|---|---|
| `DISCOURSE_HOSTNAME` | defaults to `RAILWAY_PUBLIC_DOMAIN` |
| `DISCOURSE_DB_HOST` / `_PORT` / `_NAME` / `_USERNAME` / `_PASSWORD` | PostgreSQL |
| `DISCOURSE_REDIS_HOST` / `_PORT` / `_PASSWORD` | Redis |
| `DISCOURSE_SMTP_ADDRESS` / `_PORT` | any SMTP host |
| `DISCOURSE_SECRET_KEY_BASE` | 128 hex characters; must stay stable |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | first administrator; `ADMIN_USERNAME` optional |

Every other `DISCOURSE_*` variable is written straight into
`config/discourse.conf` by the image's own `copy-env` boot script, so the whole of
`config/discourse_defaults.conf` and every site setting is reachable.

## Volume

Mount one volume at `/shared`. Uploads, backups and Rails logs live there; the image
recreates the directory tree on a fresh volume by itself.

## Licence

The wrapper files here are MIT. Discourse itself is GPL-2.0 and is not modified.
