# ghost-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Ghost](https://github.com/TryGhost/Ghost).

## What this is

A four-file TOS Docker application archive (`ghostdocker.tar.gz`) that installs
Ghost on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `ghostdocker`)
- `ghostdocker.lang` — 23-language superset (TOS requires 14)
- `ghostdocker.svg` — application icon (488 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `ghost:6.65.0-alpine`

## How it works

| | |
|---|---|
| Container image | `ghost:6.65.0-alpine` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8003/` (container port 2368) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/var/lib/ghost/content` → `/Volume1/DockerAppData/ghostdocker/content` |
| Logs | `docker logs ghostdocker` (stdout/stderr) |

Everything the blog owns is inside the application data folder: `/Volume1/DockerAppData/ghostdocker/content` — the SQLite database in `data/ghost.db`, uploaded images in `images/`, themes in `themes/`. TOS Docker applications do not take part in the shared-folder mechanism, so that folder is reached with SSH/SFTP or the file station, not from the App Center. Copy `content/` to back the site up.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper** (not a privilege shim): the image runs unprivileged already once the database is configured, so `src/entrypoint.sh` only seeds the SQLite configuration and resolves the site address, then hands over to the upstream `docker-entrypoint.sh`.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 2368.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **SQLite, single container.** The upstream image defaults to a MySQL server on localhost; the wrapper sets `database__client=sqlite3` so the whole blog runs in one container with no database service to administer. The database file is `content/data/ghost.db`.
- **Correct links from the first visit.** Ghost writes absolute URLs from its `url` setting and falls back to `http://localhost:2368`, which no other device can reach. The wrapper captures the `Host` header of the first request that does not come from the NAS itself and restarts the blog with that address (about 20 seconds, once). A commented sample of `content/public-url.txt` is seeded on the first start as a manual override.
- **23-language store metadata** covering both documented TOS language sets.
- **SQLite safety.** Ghost keeps a write-ahead log next to the database; keep the container stopped while copying `content/` for a consistent backup.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `content/public-url.txt` | the site address Ghost builds its links from (optional override) | first start by the entrypoint wrapper | static | never overwritten; edit it to pin the address |
| `content/data/ghost.db` | the entire site database (posts, pages, members, settings) in SQLite | first start by Ghost | grows with posts, images and members | never overwritten; this is the backup target |
| `content/images` | images you upload to posts and settings | first start | grows with uploaded media | managed by Ghost |
| `content/themes` | themes (the bundled Source theme plus anything you add) | first start | user controlled | managed by Ghost |
| `/Volume1/DockerAppData/ghostdocker/content` | Ghost application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/ghostdocker.tar.gz + .sha256
scripts/build.sh 6.65.0-2   # packaging iteration bump
scripts/build.sh 6.65.0-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/ghostdocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v6.65.0-1`**, assets `ghostdocker.tar.gz` +
   `ghostdocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `ghostdocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `6.65.0-1` → automated validation → review.

## License / branding

Ghost is distributed by its upstream authors under **MIT**. The container image is the official image from Docker Hub (`ghost:6.65.0-alpine`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

Mail is not configured out of the box: Ghost falls back to a generated from-address, so member sign-up, newsletter and password-reset emails need SMTP settings before they reach real inboxes (Admin -> Settings -> Email).
The blog is served over plain HTTP on the LAN. Do not publish the port to the internet; put it behind a TLS reverse proxy or a tunnel if you need remote access.
Docker applications cannot be updated through the App Center: install the newer version over the same app (the data folder is kept), or back the data up and reinstall.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
