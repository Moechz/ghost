# NOTICE — third-party components, licences and attributions

This package (`ghostdocker`, TOS 7 Docker application) is an independent packaging
by Moechz of the upstream **Ghost** project. It contains no upstream source code:
it installs the official Docker Hub image unmodified.

## 1. Upstream application — Ghost

- Project: <https://github.com/TryGhost/Ghost>
- Copyright: **Ghost Foundation** — `Copyright (c) 2013-2026 Ghost Foundation`
- Licence: **MIT** — verified against the upstream `LICENSE` file and
  `package.json` (`"license": "MIT"`) at tag `v6.79.0`, not copied from older
  metadata.
- Relationship: the upstream application is used **unmodified**, inside the
  container image. Nothing from the Ghost source tree is redistributed in this
  package or this repository.

The MIT text that governs Ghost:

> Permission is hereby granted, free of charge, to any person obtaining a copy of
> this software and associated documentation files (the “Software”), to deal in
> the Software without restriction, including without limitation the rights to
> use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
> the Software, and to permit persons to whom the Software is furnished to do so,
> subject to the following conditions: The above copyright notice and this
> permission notice shall be included in all copies or substantial portions of the
> Software.

## 2. Container image — `ghost:6.79.0-alpine`

| Item | Value |
|---|---|
| Registry | Docker Hub, official image (`docker.io/library/ghost`) |
| Tag | `ghost:6.79.0-alpine` |
| **OCI index digest** | `sha256:3a052ac4c0a74566700ec30283f7f702b81e65ae179e46ce18cca159c8b98702` |
| `linux/amd64` manifest | `sha256:fe638cd95b616444f59e5ff506584b512cdb4bb3022df43422a60ea2bcd648e7` |
| `linux/arm64/v8` manifest | `sha256:f1b9eccfd57d4a3659bba9a55b291fc50f74940d163aff6c12eb7722bc41c203` |
| Extra index entries | one SLSA/in-toto attestation manifest per architecture |
| Published / built | 2026-11-24 (`org.opencontainers.image.created` 21:17:45Z amd64, 21:22:55Z arm64) |
| Image version label | `org.opencontainers.image.version=6.79.0-alpine3.23` |
| Upstream image source | <https://github.com/TryGhost/docker-library-ghost> (`revision f53a7baf…`) |
| Base image | `node:22-alpine3.23` — Alpine **3.23.8**, Node.js **22.23.5** |
| Bundled CLI | Ghost CLI 1.34.1 (`GHOST_CLI_VERSION`) |

The digest was read from the registry (`Docker-Content-Digest` of the OCI index)
and cross-checked with the local pull. Because the index digest is immutable, the
bytes behind this version cannot change; the package records it so a rebuild can be
verified against the exact same image (T2 supply-chain pinning). The tag is what
the installer pulls, so the image is not redistributed here.

## 3. Components inside the image

| Component | Licence | Note |
|---|---|---|
| Ghost 6.79.0 (core, admin, portal, comments-ui, koenig, themes Casper and Source) | MIT | built from tag `v6.79.0` |
| Node.js 22.23.5 | MIT (with the OpenSSL/ICU notices Node ships) | runtime |
| Alpine Linux 3.23.8 base packages | mixed: MIT, BSD-2/3-Clause, Apache-2.0, ISC, GPL-2.0, LGPL-2.1, MPL-2.0 | musl libc (MIT), BusyBox (GPL-2.0), OpenSSL (Apache-2.0), ca-certificates (MPL-2.0), zlib (Zlib) |
| `gosu` 1.19 | Apache-2.0 | used by the upstream entrypoint |
| Ghost CLI 1.34.1 | MIT | installed in the image |
| npm dependencies of Ghost | mostly MIT, some Apache-2.0/BSD/ISC | licences are listed in each package's `package.json` inside the image |

Those components are shipped **inside the image only**. They are not redistributed
as separate files by this package, and their licence texts travel with the image.
If you need the full text of a specific licence, it is available inside the
container at `/var/lib/ghost/versions/6.79.0/node_modules/<package>/LICENSE` or from
the upstream repositories linked above.

## 4. This packaging

The files authored for this package — `docker-compose.yml`, `config.ini`,
`ghostdocker.lang`, `ghostdocker.svg` (icon artwork excepted, see §6),
`src/entrypoint.sh`, `scripts/`, `tools/verify.py`, `test/` and this documentation
— are released under the **MIT licence** (see `LICENSE`, `Copyright (c) 2026
Moechz`). This matches the licence of the upstream project and the text in
`LICENSE`; earlier revisions of `NOTICE.md` and `README.md` said “GPL-3.0”, which
was wrong and is corrected here.

## 5. Trademarks

“Ghost”, “Ghost Explore”, the Ghost logo, “TerraMaster” and “TOS” are trademarks or
registered trademarks of their respective owners (Ghost Foundation; TerraMaster).
Their use in this package is **descriptive and nominative only** — to identify the
upstream application and the platform it runs on. This package is **not
affiliated with, sponsored or endorsed by** Ghost Foundation or TerraMaster.

## 6. Icon

`src/ghostdocker.svg` reproduces the **Ghost logo mark** (the round Ghost glyph) on
a dark tile so that the application is recognisable in the App Center. The artwork
is the upstream project's logo; copyright in the logo belongs to Ghost Foundation
and the mark is used only to identify the Ghost application this package installs.
It is not a mark of this packaging, and no endorsement is implied. If the upstream
project asks for its removal, the icon will be replaced with a neutral one.

## 7. Platform tooling

`TOSAppSelfTestingTool` is supplied by TerraMaster for package self-testing. It is
not part of the submitted archive and is not redistributed inside it. The release
assets are the package and its SHA-256 file only.

## 8. Credentials

The package contains **no credentials**: no password, API key, token or private key
is baked into the archive or the compose file. The owner account is created by the
user in Ghost's setup wizard; the Mailgun key, Stripe keys, integration keys and
webhook secrets are entered in the admin UI at runtime and stored inside the data
volume (`content/data/ghost.db`, mode 0600). Ghost's own `indexnow_api_key` and
`site_uuid` are generated at runtime, never shipped.

## 9. Contact

Moechz — moechz@163.com — <https://www.moechz.com/>
