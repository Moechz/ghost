# ghost-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Ghost](https://github.com/TryGhost/Ghost) 6.79.0.

## What this is

A four-file TOS Docker application archive (`ghostdocker.tar.gz`) that installs
Ghost on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `ghostdocker`)
- `ghostdocker.lang` — 23-language superset (TOS requires 14)
- `ghostdocker.svg` — application icon (the Ghost mark, 2 SVG elements)
- `docker-compose.yml` — one service, image `ghost:6.79.0-alpine`

## Repository layout

```text
.
├── tosapp.json                 # build spec: version, image, ports, translations, notes
├── src/
│   ├── config.ini              # TOS metadata (help -> PRIVACY.md)
│   ├── ghostdocker.lang        # generated from tosapp.json "translations"
│   ├── ghostdocker.svg         # icon
│   ├── docker-compose.yml      # service definition (entrypoint embedded at build)
│   └── entrypoint.sh           # wrapper: SQLite, permissions, site address
├── scripts/
│   ├── build.sh                # one architecture -> out/ghostdocker.tar.gz + .sha256
│   └── build-dual.sh           # x86_64 + aarch64, official -c check on both
├── tools/verify.py             # review-standards self-check (hard gate)
├── test/install-and-verify.sh  # on-device E2E (needs root; not used in review)
├── PRIVACY.md                  # what is stored, what leaves the NAS (C3–C8)
├── NOTICE.md                   # licences, image digest, trademarks (C2)
├── CHANGELOG.md                # per-version, per-review-code notes
└── LICENSE                     # MIT (packaging)
```

## How it works

| | |
|---|---|
| Container image | `ghost:6.79.0-alpine` (Docker Hub official image, unmodified) |
| Image digest | index `sha256:3a052ac4…b98702`, amd64 `fe638cd9…d648e7`, arm64 `f1b9eccf…41c203` |
| Open | `http://<NAS-IP>:8003/` (container port 2368) |
| Runs as | non-root, `user: "1000:1000"`, `cap_drop: ALL`, `no-new-privileges` |
| Persistent data | `/var/lib/ghost/content` → `/Volume1/DockerAppData/ghostdocker/content` |
| Logs | `docker logs ghostdocker`, plus rotated files in `content/logs/` |

Everything the blog owns is inside the application data folder:
`/Volume1/DockerAppData/ghostdocker/content` — the SQLite database in
`data/ghost.db` (posts, members and their e-mail addresses, subscriptions,
Mailgun key, API keys), uploaded media in `images/`, `media/` and `files/`,
themes in `themes/`, generated assets in `public/` and rotated logs in `logs/`.
TOS Docker applications do not take part in the shared-folder mechanism, so that
folder is reached with SSH/SFTP or the file station, not from the App Center.

## Install and first start

1. Install from the App Center (DockerEngine is pulled in as a dependency).
2. Open the app. The first time, the wrapper learns the address your browser used
   and starts Ghost with it (about 20 seconds, one page reload). This is why the
   blog's links, feeds and e-mails point at your NAS instead of `localhost`.
3. Create the owner account in Ghost's setup wizard. **The package has no default
   account and no default password** — the first account is the owner.
4. If you prefer a fixed address (a domain behind a reverse proxy, for example),
   put it in `content/public-url.txt` and restart the app. A commented sample is
   seeded there on the first start; the file is never overwritten.
5. Optional services are configured in the admin UI: Mailgun under
   **Settings → Email**, Stripe under **Settings → Members → Paid subscriptions**,
   Unsplash under **Settings → Advanced → Integrations**.

## Privacy

This application runs on your NAS. **The developer does not collect, receive or
have access to any data processed by the application**; there is no developer
telemetry and no account. Ghost itself talks to a few endpoints: an update check,
the optional Ghost Explore ping (on by default, editable in
**Settings → Ghost Explore**), and — only if you configure them — Mailgun, Stripe,
Unsplash, Gravatar, oEmbed providers and search-engine pings. Every endpoint, the
exact data sent and the region are listed in
[PRIVACY.md](PRIVACY.md#6-third-party-services-and-api-disclosure-c8) §6.

| Topic | Detail |
|---|---|
| Data processed | Posts, pages, themes, settings, uploaded media, logs, **member records (e-mail, name, subscription, Stripe ids) and newsletter open/click events** |
| Where it is stored | `/Volume1/DockerAppData/ghostdocker/content` on your NAS; nothing is uploaded to the developer |
| Retention | Until **you** delete it; logs are rotated by Ghost |
| Your rights | Export via admin **Settings → Advanced → Export**, correct in the UI, delete members in the UI, delete everything by removing the folder |
| Deletion channel | See “Data and uninstall” below, or e-mail **moechz@163.com** (answer within 30 days) |
| Security measures | uid 1000, `cap_drop: ALL`, `no-new-privileges`, no Docker socket, one published port, `umask 077` (database and logs 0600, data dir 0700), image digest pinned |

Full policy: [PRIVACY.md](PRIVACY.md) —
<https://github.com/Moechz/ghost/blob/main/PRIVACY.md> — website version at
<https://www.moechz.com/privacy.html>.

## Data and uninstall (F11)

Docker applications in TOS have **no uninstall hook**. Uninstalling from the App
Center removes the container and the app record, but **not** the data folder.
That is deliberate (an accidental uninstall must not destroy a blog), so deleting
data is an explicit step:

```bash
# remove the container, keep the posts
docker compose -p ghostdocker down

# delete everything the app ever wrote
sudo rm -rf /Volume1/DockerAppData/ghostdocker
```

Back up first — the folder is the whole site, including the member database:

```bash
docker compose -p ghostdocker stop
sudo cp -a /Volume1/DockerAppData/ghostdocker/content /path/to/backup/
```

Nothing is written outside `/Volume1/DockerAppData/ghostdocker/` except the
container's ephemeral `/tmp`.

## Third-party services (API disclosure)

The developer operates no server in this path. Summary of what Ghost 6.79 may
contact (full table with payloads and regions in PRIVACY.md §6):

| Service | Endpoint | Data sent | Destination / region | Default |
|---|---|---|---|---|
| Ghost update check | `updates.ghost.org` | Ghost version string | Ghost Foundation, US | on |
| Ghost Explore | `explore.ghost.org/api/update` | version, site uuid/url, theme, social handles, post counts (+members/MRR only if growth sharing is on) | Ghost Foundation, US | on (toggle in Settings) |
| Unsplash | `api.unsplash.com` | search term (from your browser) | Unsplash, US | on while the picker is used |
| Mailgun | `api.mailgun.net` | recipient addresses, newsletter content | Mailgun, US/EU | off |
| Stripe | `api.stripe.com` | member e-mail, payment/subscription data | Stripe, US/EU | off |
| Gravatar | `www.gravatar.com` | MD5 hash of an e-mail address | Automattic, US | on |
| oEmbed providers | YouTube/X/Vimeo/… | the URL you paste | the provider | on demand |
| IndexNow | `api.indexnow.org` | published post URLs | IndexNow partners | off |
| Ghost static CDN | `static.ghost.org` | anonymous GET of the default cover image (for `og:image` dimensions) | Ghost Foundation/Fastly, US | on until you set your own cover |
| Docker Hub | `registry-1.docker.io` / mirror | anonymous pull | Docker Hub, US / mirror | install time |

## Notices and licences

- **Ghost** — MIT, © Ghost Foundation, used unmodified inside the image.
- **Container image** — `ghost:6.79.0-alpine`, official Docker Hub image built from
  `TryGhost/docker-library-ghost`, OCI index digest recorded and pinned.
- **This packaging** — **MIT** (see `LICENSE`). The earlier “GPL-3.0” statement in
  `NOTICE.md`/`README.md` was inconsistent with `LICENSE` and is corrected.
- **Icon** — the Ghost logo mark, used to identify the upstream application.
- “Ghost”, “TerraMaster”, “TOS” are trademarks of their owners; this is an
  independent community package and is not affiliated with or endorsed by them.

Full attribution, per-architecture digests and the component licence list:
[NOTICE.md](NOTICE.md).

## Design highlights

- **Non-root, least privilege.** `user: "1000:1000"`, `cap_drop: ALL`,
  `security_opt: [no-new-privileges:true]`; verified on real hardware (uid 1000).
- **Minimal file permissions (S11).** `umask 077` in the wrapper: the SQLite
  database (member e-mail addresses, Mailgun key), its WAL and the logs are
  `0600`; `data/` and `logs/` are `0700`.
- **Entrypoint wrapper** (not a privilege shim): the image starts unprivileged once
  the database is configured, so `src/entrypoint.sh` only seeds the SQLite
  configuration, tightens permissions and resolves the site address, then hands
  over to the upstream `docker-entrypoint.sh`.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no
  `network_mode: host`, no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 2368.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip
  without a timestamp, plus the review-standards self-check.
- **SQLite, single container.** The upstream image defaults to a MySQL server on
  localhost; the wrapper sets `database__client=sqlite3` so the whole blog runs in
  one container. The database is `content/data/ghost.db`.
- **Correct links from the first visit** (see “Install and first start”).
- **23-language store metadata** covering both documented TOS language sets; no
  ASCII semicolon in any `descript`/`important` value (the store parser treats it
  as an INI comment and truncates the text).
- **SQLite safety.** Keep the container stopped while copying `content/` for a
  consistent backup.

## Runtime file manifest

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `content/public-url.txt` | optional pinned site address | first start by the wrapper | static | never overwritten; edit to pin |
| `content/.tos-site-url` | address learned from the first visit (0600) | first start, on the first external request | static | replaced when a new address is captured |
| `content/data/ghost.db` | posts, pages, members, subscriptions, settings, keys | first start by Ghost | grows with content and members | backup target; never overwritten |
| `content/data/ghost.db-wal` | SQLite write-ahead log | first write | bounded by checkpoints | transient |
| `content/images`, `content/media`, `content/files` | uploaded media | first start | grows with uploads | managed by Ghost |
| `content/themes` | Casper, Source and your themes | first start | user controlled | managed by Ghost |
| `content/public` | generated theme assets | first start / theme change | rebuilt on demand | safe to delete when stopped |
| `content/settings` | `routes.yaml` | first start | static | managed by Ghost |
| `content/logs` | rotated Ghost logs | first start | rotation enabled | safe to delete |

## Build

```bash
scripts/build-dual.sh 6.79.0-1     # both architectures + official -c on each
scripts/build.sh 6.79.0-1 x86_64   # one architecture (out/ghostdocker.tar.gz)
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`),
normalises CRLF/BOM/AppleDouble, then runs `tools/verify.py`, a review-standards
self-check: archive layout, JSON validity, required fields, 14+ language coverage,
version consistency, Docker-Hub-only images, fixed tag, reserved/recommended host
ports, non-root user, per-service healthcheck/TZ/restart, data path below the
application data root, never the `/Volume*` wildcard, comment-free sequence
blocks, `x-app-meta` position, no literal secrets, no ASCII semicolon in
descriptions, no cross-app text, and the SVG size/element limits.

## Local verification

```bash
./TOSAppSelfTestingTool -c out/ghostdocker_x86_64.tar.gz    # official spec check
python3 ../stage.py .                                       # isolated runtime check
bash test/install-and-verify.sh                             # on-device E2E (root)
```

`stage.py` rewrites the compose file to a temporary port and a temporary data
directory, runs `docker compose up`, and asserts: container healthy, HTTP answer,
`user=1000:1000`, then removes everything again. It never touches
`/Volume1/DockerAppData`.

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v6.79.0-1`**, assets `ghostdocker_x86_64.tar.gz`,
   `ghostdocker_aarch64.tar.gz` and their `.sha256` files.
3. Developer platform → Add Application: ID `ghostdocker`, package type Docker,
   repository URL, architecture `x86_64` and `aarch64`.
4. Version Management → Add Version `6.79.0-1` → automated validation → review.
5. After upload, compare the platform's `file_hash` with the local
   `sha256sum` of each archive (V7).

## Limitations

- Mail is not configured out of the box: Ghost falls back to a generated
  from-address, so member sign-up, newsletter and password-reset e-mails need
  Mailgun or SMTP settings before they reach real inboxes.
- The blog is served over plain HTTP on the LAN. Do not publish the port to the
  internet; put it behind a TLS reverse proxy or a tunnel.
- Docker applications cannot be updated through the App Center: install the newer
  version over the same app (the data folder is kept), or back the data up and
  reinstall.
- On a NAS without internet access, Ghost logs `IMAGE_SIZE_URL` errors while it tries to measure the default cover image from `static.ghost.org`. The page still renders; upload your own cover image (Settings → General) to stop it.
- Host port 8003 is shared with other applications in the store. Port collisions
  are a user decision (install one of the two), not a package defect.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.

## Support

- Issues and questions: <https://github.com/Moechz/ghost/issues>
- E-mail: moechz@163.com
- Privacy: [PRIVACY.md](PRIVACY.md) · Licence: [NOTICE.md](NOTICE.md)
