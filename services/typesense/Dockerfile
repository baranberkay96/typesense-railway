# syntax=docker/dockerfile:1
#
# Typesense 30.2 (GPL-3.0) for Railway.
#
# Base: the official typesense/typesense image, multi-arch index digest
# checked 2026-11-24. To upgrade, change tag and digest together after
# reading the release notes (take a snapshot first, see README).
FROM typesense/typesense:30.2@sha256:610f2d34b1f93d00762869da2c67736775e5798d19a2c8b91b014b8a0cc1e110

COPY --chmod=0755 railway-typesense.sh /usr/local/bin/railway-typesense

ENV PORT=8108
EXPOSE 8108
STOPSIGNAL SIGINT

ENTRYPOINT ["/usr/local/bin/railway-typesense"]
