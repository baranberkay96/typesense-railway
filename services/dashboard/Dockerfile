# syntax=docker/dockerfile:1
#
# Typesense Dashboard 2.5.0 (bfritscher/typesense-dashboard, GPL-3.0) behind
# a Caddy login for Railway.
#
# Base: ghcr.io/bfritscher/typesense-dashboard:2.5.0 (static web build
# served by Caddy 2 on Alpine), multi-arch index digest checked 2026-11-24.
# The image is used unmodified; only the start script and Caddyfile are ours.
FROM ghcr.io/bfritscher/typesense-dashboard:2.5.0@sha256:934356f6eb2a080e6e6741aee799fbf71e64486915a5cb82db3577528b17c182

COPY --chmod=0644 Caddyfile /etc/railway/Caddyfile
COPY --chmod=0755 railway-dashboard.sh /usr/local/bin/railway-dashboard

ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/railway-dashboard"]
