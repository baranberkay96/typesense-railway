# NOTICE: Typesense template

This is a community template. It is not made, endorsed or supported by Typesense, Inc., the Typesense Dashboard author or Railway.

## Components

| Component | Source | License | How it is used |
|---|---|---|---|
| Typesense 30.2 (`typesense/typesense:30.2@sha256:610f2d34b1f93d00762869da2c67736775e5798d19a2c8b91b014b8a0cc1e110`) | https://github.com/typesense/typesense | GPL-3.0 | Official image, unmodified, as the base image |
| Typesense Dashboard 2.5.0 (`ghcr.io/bfritscher/typesense-dashboard:2.5.0@sha256:934356f6eb2a080e6e6741aee799fbf71e64486915a5cb82db3577528b17c182`), includes Caddy 2 (Apache-2.0) on Alpine | https://github.com/bfritscher/typesense-dashboard | GPL-3.0 (Copyright Boris Fritscher) | Published image, unmodified, as the base image; our Caddyfile and start script are added |

Source code for both GPL-3.0 components is available at the repositories above at the tags `v30.2` and `v2.5.0`.

## Files written for this template

`services/typesense/Dockerfile`, `services/typesense/railway-typesense.sh`, `services/dashboard/Dockerfile`, `services/dashboard/Caddyfile`, `services/dashboard/railway-dashboard.sh` and the documentation were written for this template and are offered under the MIT License.

## Upstream files checked

- typesense v30.2: `src/tsconfig.cpp` and `include/tsconfig.h` (environment variable names, `"TRUE"` booleans, `std::stoi` number parsing), `src/http_server.cpp` (`::` binds dual-stack with `IPV6_V6ONLY=0`), `src/typesense_server_utils.cpp` (thread pool = 8 x `hardware_concurrency()`), `docker/deployment.Dockerfile`.
- typesense-dashboard v2.5.0: `Dockerfile`, `entrypoint.sh`, `README.md` (`config.json` autologin, `SAME` host mode with a path).

## Market templates

The Typesense templates on the Railway marketplace (`railwayapp-templates/typesense`, `copperline-ai/typesense-railway` with Typelens, `Shinyduo/typesense-railway`) were reviewed for features only. No files or text were copied.
