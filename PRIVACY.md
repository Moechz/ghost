# Privacy Policy — Ghost for TerraMaster TOS (`ghostdocker`)

**Last updated:** 25 November 2026
**Package:** `ghostdocker` 6.79.0-1 (upstream Ghost 6.79.0, official Docker Hub image)
**Contact / publisher:** Moechz — moechz@163.com

This policy covers the TOS application `ghostdocker` (the “app”) and its packaging.
It was rewritten for the 6.79.0-1 submission so that every statement matches what
Ghost 6.79.0 actually stores, requests and sends.

## 1. Summary

- The app runs **on your NAS**. The developer of this package does not receive,
  collect or have access to any data the app processes, and operates no server in
  the app's request path.
- There is **no developer telemetry, no analytics SDK and no developer account**.
- Ghost itself, however, is not silent: the upstream application contacts a small
  number of **Ghost Foundation endpoints** during normal operation (an update
  check and the optional “Ghost Explore” listing) and, if you configure them, the
  services you choose (Mailgun for e-mail, Stripe for payments, Unsplash for
  stock images). **All of them are listed in §6 with the exact data sent.**
- The owner account, Mailgun key, Stripe keys and all API keys are supplied by
  **you** at runtime. The package ships no credentials.

## 2. What data is stored

Everything is stored inside the application data folder on your NAS:

`/Volume1/DockerAppData/ghostdocker/content`

| Data | Where | Notes |
|---|---|---|
| Posts, pages, tags, authors, theme settings, site settings | `data/ghost.db` (SQLite) | the content you publish |
| **Member records: e-mail address, name, labels, notes, subscription status, Stripe customer and subscription ids, tiers** | `data/ghost.db` | collected by Ghost when someone signs up or pays |
| Newsletter recipients and delivery/error records | `data/ghost.db` | per-recipient rows |
| **E-mail open and click events** (default **on**, see §6) | `data/ghost.db` | recorded per member when a newsletter is opened or a link is clicked |
| Comments, likes, member sessions and magic-link tokens | `data/ghost.db` | if comments/members are enabled |
| Staff accounts: name, e-mail, password hash, 2FA secret, session records | `data/ghost.db` | your own admin users |
| Integration and API keys, webhook secrets, **Mailgun key**, Stripe keys | `data/ghost.db` | entered in the admin UI, never in the package |
| Uploaded images, media and files | `images/`, `media/`, `files/` | the media you upload |
| Themes and generated assets | `themes/`, `public/` | |
| Rotated log files | `logs/` | Ghost's own logs (see §4) |
| Remembered site address | `.tos-site-url` (0600) and `public-url.txt` | no personal data, only a URL |

The database contains personal data of your members, so the package restricts it:
see §5.

## 3. What the app does not do

- No data is sent to the developer, and the developer holds no copy of anything.
- No third-party analytics (no Google Analytics, no Plausible, no Sentry) is
  enabled: Ghost's error reporting is only active if **you** configure a Sentry
  DSN, and analytics scripts are only added if you edit the theme.
- No data is sold or shared with advertisers.
- Nothing is uploaded anywhere unless it is listed in §6.

## 4. Retention

- **Application data:** kept until **you** delete it. There is no automatic expiry.
  Uninstalling the app from the App Center keeps the folder (see §8).
- **Logs:** Ghost writes rotated log files under `content/logs/`; rotation is
  enabled, so old files are removed automatically. Safe to delete at any time
  while the container is stopped.
- **E-mail events and member records:** kept in the database until you delete the
  member or the database.
- **Sessions / magic links:** expire on their own (Ghost defaults).
- **Website/server logs of moechz.com:** short-lived operational logs of the
  developer's website (not of the app), not used for profiling.

## 5. Security measures

- The container runs as **uid 1000**, never root; all Linux capabilities are
  dropped (`cap_drop: ALL`) and `no-new-privileges` is set. No `privileged`, no
  host network, no Docker socket, no `cap_add`.
- The wrapper sets **`umask 077`**; the database, its WAL and the logs are created
  `0600` and the data/log directories `0700`, so other local users on the NAS
  cannot read member e-mail addresses or the Mailgun key.
- Only one port is published (8003 → 2368) and it is meant for the LAN. Put the
  app behind a TLS reverse proxy before exposing it; Ghost serves plain HTTP.
- The image tag is pinned and the immutable OCI index digest is recorded in
  `docker-compose.yml` and `NOTICE.md`, so the same version cannot silently change.
- Back up `content/` and protect the backup: it contains the member database and
  the Mailgun key.

## 6. Third-party services and API disclosure (C8)

The developer operates no endpoint in this path. Below is **every** outbound
request the application can make, what it sends and where it goes. “Default”
means it happens without you configuring anything.

| # | Service | Endpoint | Data sent | Destination / region | When / default |
|---|---|---|---|---|---|
| 1 | Ghost update check | `https://updates.ghost.org` (`GET ?ghost_version=…`) | the Ghost version string only (`6.79.0`) | Ghost Foundation, US | at most once a day at startup — **default on** |
| 2 | Ghost Explore ping | `https://explore.ghost.org/api/update` (`POST`, JSON) | `ghost` version, `site_uuid`, site **URL**, active theme name, Facebook and X/Twitter handles, total published posts, first and last post dates. If you enable “Share growth data” it also sends **total member count** and **MRR by currency** | Ghost Foundation, US | once per container start — **default on**; switch off in **Admin → Settings → Ghost Explore** (toggle “Ghost Explore”); growth data has its own toggle, off by default |
| 3 | Unsplash image search | `https://api.unsplash.com` (from your browser) | the search term and page you type in the editor's Unsplash picker, plus your browser's IP | Unsplash, US | only when you use the picker — enabled in **Settings → Advanced → Integrations → Unsplash** (can be switched off) |
| 4 | Mailgun (e-mail delivery) | `https://api.mailgun.net/v3/<domain>/…` | recipient e-mail addresses, newsletter content, open/click events | Mailgun (US or EU region, whichever you configure) | only if you configure Mailgun in **Settings → Email** — **default off** (Ghost falls back to a generated from-address; no mail leaves the NAS) |
| 5 | Stripe (payments) | `https://api.stripe.com` | member e-mail, name, payment method token, subscription and invoice data | Stripe, US/EU | only if you enable paid memberships and connect Stripe — **default off** |
| 6 | Gravatar (avatars) | `https://www.gravatar.com/avatar/<md5(email)>` | the **MD5 hash of a member or staff e-mail address** | Automattic/Gravatar, US | whenever an avatar is rendered for a member or staff user — **default on**; switch off by adding `privacy__useGravatar: "false"` to the container environment |
| 7 | oEmbed / link previews | the provider named by the embedded URL (YouTube, X/Twitter, Vimeo, …) | the URL you paste into the editor | the provider you paste | only when you paste a supported URL in the editor |
| 8 | Remote media (content import, media inliner) | the URL of the image/file being imported | an HTTP GET for that URL (no credentials) | wherever the media is hosted | only when you import content or paste a remote image and Ghost fetches it |
| 9 | IndexNow (search-engine ping) | `https://api.indexnow.org/indexnow` | the public URLs of posts you publish | IndexNow (Bing/Yandex and partners) | only after an IndexNow key is generated/enabled — **default off** (no key = no ping) |
| 10 | S3-compatible storage (optional) | the endpoint you configure | images/media you upload | your storage provider | only if you configure external storage — **default off** |
| 11 | ActivityPub / Webmention federation (optional) | the remote instance you interact with | your post URL and public post content | the remote fediverse instance | only if you enable federation/webmentions |
| 12 | Slack integration (optional) | your Slack webhook | notification text you choose | Slack, US | only if you configure a webhook |
| 13 | Docker Hub (image pull) | `registry-1.docker.io` (or the registry mirror configured in DockerEngine) | anonymous pull request | Docker Hub, US / your mirror | at install time and when the image is updated |
| 14 | Ghost static CDN (default cover image) | `https://static.ghost.org/v5.0.0/images/publication-cover.jpg` | an anonymous `GET` for the image, so Ghost can add its width/height to the `og:image` meta tags | Ghost Foundation CDN (Fastly), US | every homepage render **until you replace the default cover image** in **Settings → General** (the URL is a Ghost default, no personal data is sent) |

No other endpoints are contacted. If a row says “default off”, the app makes no
request to it until you configure it.

**Your control over the two Ghost Foundation calls that are on by default:**

- **Explore ping** — switch it off with the “Ghost Explore” toggle in
  **Admin → Settings → Ghost Explore**. The site then stops being listed in the
  Ghost Explore directory and no further ping is sent.
- **Update check** — sends only the version string and has no admin toggle in
  Ghost 6.79. To stop it, set `updateCheck__url` to an unused address in the
  container environment (for example `http://127.0.0.1:9/`), or block
  `updates.ghost.org` in the NAS firewall. Ghost logs a warning when the check
  cannot complete and keeps working; the version string carries no personal data.
- **Gravatar** and **email open/click tracking** can be switched off as described
  in the table and in **Settings → Email**.

## 7. Your rights and the deletion channel (C7)

| Right | How |
|---|---|
| Access / export | Ghost admin → **Settings → Advanced → Export** exports posts, members and settings as JSON. The complete state is the folder `/Volume1/DockerAppData/ghostdocker/content/` — copy it while the container is stopped. |
| Correct | Edit the member, post or setting in the app's admin UI. |
| Delete a member | Ghost admin → **Members** → delete. Their e-mail address, events and subscription rows are removed from the database. |
| Delete everything | Stop the app, then remove `/Volume1/DockerAppData/ghostdocker/` (see §8). |
| Portability | The export in JSON plus the `content/` folder is a complete, readable copy. |
| Assistance | E-mail **moechz@163.com** with the subject “Ghost data request”; a reply follows within 30 days. The developer holds no copy of your data, so deletion is normally completed on your own NAS; the address exists for questions and for the developer's website. |

## 8. Deleting the app and its data (F11)

Docker applications in TOS have **no uninstall hook**. Uninstalling from the App
Center removes the container (and the app record), but **not** the data folder:

```bash
# stop and remove the container (keeps the data)
docker compose -p ghostdocker down

# remove the container AND everything the app ever wrote
sudo rm -rf /Volume1/DockerAppData/ghostdocker
```

The second command is the only way to delete the posts, the member database, the
uploaded media and the remembered site address. Back the folder up first if you
may want the site back. Nothing is written outside that folder except the
container's own ephemeral `/tmp`.

## 9. Children

The app is a self-hosted publishing tool and is not directed at children. The
site owner decides what is published.

## 10. Changes

Material changes are published in this file and in `CHANGELOG.md`, and the
“Last updated” date above is bumped.

## 11. Contact

Moechz — **moechz@163.com** — <https://www.moechz.com/privacy.html>
