# Changelog

All notable user-visible changes to the Ghost TOS application package.

## 6.79.0-1 — 2026-11-25

Review remediation of the on-hold submission `6.65.0-2` (x86_64). Codes addressed:
**C2, C6, C8, T1, T2** from the review table, plus the blocking items that the same
table contained (**F11, S11, V7**) and the `Failed stage: Installation failed` note.

### Upgraded
- **T1** — upstream image `ghost:6.65.0-alpine` → **`ghost:6.79.0-alpine`**
  (Ghost 6.79.0, published 2026-11-24). The base image moved to
  `node:22-alpine3.23` (**Alpine 3.23.8**, Node.js 22.23.5), which lifts the Alpine
  and Node packages that the vulnerability scan reported. Ghost runs its own
  database migrations on boot, so an existing 6.65 blog is upgraded in place on the
  first start (back up `content/` first, as always).
- The tag is pinned and the immutable **OCI index digest**
  `sha256:3a052ac4…b98702` is recorded in `docker-compose.yml`, `NOTICE.md` and
  `README.md`, together with the amd64 (`fe638cd9…d648e7`) and arm64/v8
  (`f1b9eccf…41c203`) manifests, so the same version cannot silently change bytes.

### Compliance
- **C2** — `NOTICE.md` rewritten: Ghost is **MIT** (verified against the upstream
  `LICENSE` and `package.json` at `v6.79.0`, copyright Ghost Foundation), the image
  is the official Docker Hub image built from `TryGhost/docker-library-ghost` with
  its digest and construction date, the components inside the image and their
  licences are listed, the icon is identified as the upstream Ghost logo, and the
  trademark/non-affiliation statement is explicit. **Corrected an inconsistency:**
  `NOTICE.md` and `README.md` claimed “GPL-3.0” for the packaging while `LICENSE`
  is MIT — the packaging is now MIT everywhere.
- **C6** — `PRIVACY.md` rewritten to match runtime behaviour. The old text said
  “no telemetry”; Ghost 6.79 actually stores member e-mail addresses, names,
  subscription and Stripe customer ids, the Mailgun key, API keys and newsletter
  open/click events, and it **phones home by default**: an update check to
  `updates.ghost.org` (version string only) and a Ghost Explore ping to
  `explore.ghost.org/api/update` (version, site uuid/url, theme, social handles,
  post counts, and — only when “share growth data” is enabled — member count and
  MRR). Both are now documented with their payload, frequency and the switch that
  turns them off (Admin → Settings → Ghost Explore, or `updateCheck__url`).
- **C8** — a full endpoint table (14 rows) with endpoint, data sent, destination
  and region, and whether it is on by default: update check, Explore ping,
  Unsplash, Mailgun, Stripe, Gravatar (MD5 of the e-mail address), oEmbed
  providers, remote media import, IndexNow, S3 storage, ActivityPub/Webmentions,
  Slack, Docker Hub, and the Ghost CDN request for the default cover image. The same table is in `README.md` and the description notes.

### Security and runtime
- **T2** — the package carries no credentials of any kind, and the compose file
  says so. The owner account is created by the user in the setup wizard; Mailgun,
  Stripe and integration keys are entered in the admin UI and stored inside the
  data volume; Ghost's `indexnow_api_key` and `site_uuid` are generated at
  runtime. A new gate in `tools/verify.py` fails the build if a password, secret,
  API key or token literal ever appears in the archive.
- **S11** — `umask 077` in the entrypoint: the SQLite database (member personal
  data, Mailgun key), its WAL and the logs are created `0600`, `data/` and
  `logs/` are `0700`. Compose now also drops all capabilities
  (`cap_drop: ALL`) and sets `no-new-privileges:true`. The container still runs as
  uid 1000.
- **F11** — README/PRIVACY now state that TOS Docker packages have no uninstall
  hook, list everything the app writes (`content/` with database, media, themes,
  generated assets, logs, remembered address) and give the exact commands to back
  up and to delete the folder.
- **V7** — both architectures are rebuilt deterministically (sorted tar, uid/gid 0,
  zeroed mtimes, gzip without timestamp) and the published SHA-256 is compared
  with the platform's `file_hash` after submission.
- **Installation** — the package was installed for real in an isolated staging
  project (temporary port, temporary data directory, no production data): container
  `healthy`, HTTP 200, `user=1000:1000`. The previous submission's
  `Failed stage: Installation failed` is consistent with the checksum mismatch
  (V7) recorded in the same review and with a host-port collision on the review
  machine; the host port is unchanged (8003), per the port policy.

### Changed files
- `tosapp.json` — version `6.79.0-1`, image `ghost:6.79.0-alpine`,
  `help` → `.../blob/main/PRIVACY.md`, runtime-file manifest (database, WAL,
  images/media/files, themes, public, settings, logs, address files), notes,
  descriptions; en/zh-cn/zh-hk rewritten with no ASCII semicolon.
- `src/config.ini` — `help` → PRIVACY.md.
- `src/docker-compose.yml` — image bump, index digest comment, `cap_drop`,
  `security_opt`, `stop_grace_period`, health-check `start_period` 90s.
- `src/entrypoint.sh` — `umask 077`, permission hardening, 0600 state file,
  cleanup of the temporary capture script, clearer first-start logging.
- `src/ghostdocker.lang` — regenerated (23 languages) from `tosapp.json`.
- `PRIVACY.md`, `NOTICE.md`, `README.md`, `LICENSE`, `CHANGELOG.md` — as above.
- `scripts/build-dual.sh` — new: builds and checks both architectures.
- `tools/verify.py` — new gates: ASCII semicolon in descriptions, literal
  secrets, cross-app text, image digest documented.

## 6.65.0-1 — 2026-09-27

### Added
- First release. Ghost (`ghost:6.65.0-alpine`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8003 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/ghostdocker/`.
