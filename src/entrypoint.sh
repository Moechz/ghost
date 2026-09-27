#!/bin/sh
# ===========================================================================
# Ghost entrypoint wrapper for TerraMaster TOS 7
# ===========================================================================
# The upstream image is built to start Ghost as root and expects a MySQL
# server. TOS forbids root containers, so this wrapper:
#
#   1. makes Ghost use an embedded SQLite database inside the mounted data
#      volume (the compose file already exports database__client and
#      database__connection__filename) - one container, no database server;
#   2. resolves the address of the blog. Ghost builds every link (navigation,
#      canonical URLs, feeds, member e-mails) from its `url` setting and
#      otherwise falls back to http://localhost:2368, which no other device
#      can reach. On the first start this wrapper listens on the published
#      port, remembers the address of the first request that does not come
#      from inside the container, and then starts Ghost with it;
#   3. hands over to the upstream docker-entrypoint.sh, which seeds the
#      content directory on the first start and drops to the `node` user.
#
# The detected address is stored in content/.tos-site-url. A user-written
# content/public-url.txt always wins over it. Both files live in the mounted
# data volume, so they survive container updates and reinstalls.
#
# MAINTAINERS: this file is embedded into docker-compose.yml by
# scripts/build.sh, which indents it and escapes every dollar sign as two
# dollar signs (docker compose would otherwise interpolate them). Edit THIS
# file only, and never write a doubled dollar sign here.
# ===========================================================================
set -u

CONTENT=/var/lib/ghost/content
MANUAL="$CONTENT/public-url.txt"
STATE="$CONTENT/.tos-site-url"
CAPTURE=/tmp/tos-ghost-capture.js
FALLBACK="http://localhost:2368"

log() { printf '[ghost] %s\n' "$*"; }

mkdir -p "$CONTENT" 2>/dev/null || true

# Seed the optional override once; never touch an existing file.
if [ ! -e "$MANUAL" ]; then
  cat > "$MANUAL" 2>/dev/null <<'SAMPLE'
# The address you use to reach this blog (optional).
#
# Ghost is normally configured automatically: the first time you open the app
# it remembers the address your browser used, and the blog keeps working from
# that address. Fill this file in only to pin a different one - for example a
# domain name behind a reverse proxy running on this NAS.
#
# Everything after '#' is ignored; the first http:// or https:// line wins.
# Restart the app to apply it. The file is never overwritten by the package.
#
#http://192.168.1.10:8003
SAMPLE
fi

# First usable http(s) line of a file, whitespace stripped.
pick_url() {
  [ -s "$1" ] || return 0
  sed -e 's/#.*$//' -e 's/[[:space:]]//g' "$1" 2>/dev/null \
    | grep -m1 -E '^https?://[^/]+' \
    | sed -e 's:/*$::' || true
}

url="$(pick_url "$MANUAL")"
if [ -n "$url" ]; then
  log "site address from public-url.txt: $url"
else
  url="$(pick_url "$STATE")"
  [ -n "$url" ] && log "site address remembered from the first visit: $url"
fi

# Nothing remembered yet: learn the address from the first real request.
if [ -z "$url" ]; then
  log "first start: waiting for the first request to learn the blog address"
  cat > "$CAPTURE" <<'TOSJS'
'use strict';
// First-run address capture for the Ghost TOS package. Listens on the
// published port before Ghost does. The first request whose Host header does
// not point at the container itself (a browser on the LAN, or a reverse
// proxy) is remembered as the blog address; loopback probes - the compose
// healthcheck - only get a short "starting" page. After the timeout the
// wrapper falls back to localhost, so the app can never stay stuck here.
const http = require('http');
const fs = require('fs');
const os = require('os');

const PORT = 2368;
const STATE = '/var/lib/ghost/content/.tos-site-url';
const TIMEOUT_MS = 600000;

const own = [];
const ifaces = os.networkInterfaces();
Object.keys(ifaces).forEach(function (name) {
  (ifaces[name] || []).forEach(function (addr) {
    own.push(String(addr.address).toLowerCase());
  });
});

function bareHost(value) {
  if (!value) return '';
  const h = String(value).trim().toLowerCase();
  if (h.charAt(0) === '[') {
    const end = h.indexOf(']');
    if (end > 0) return h.slice(1, end);
  }
  const colon = h.indexOf(':');
  return colon >= 0 ? h.slice(0, colon) : h;
}

function isLocal(host) {
  if (!host) return true;
  if (host === 'localhost' || host === '::1' || host === '0.0.0.0') return true;
  if (host.slice(-10) === '.localhost') return true;
  if (host.slice(0, 4) === '127.') return true;
  return own.indexOf(host) >= 0;
}

function scheme(req) {
  const raw = String(req.headers['x-forwarded-proto'] || '')
    .split(',')[0].trim().toLowerCase();
  return raw === 'https' ? 'https' : 'http';
}

const PAGE = [
  '<!doctype html><html lang="en"><head><meta charset="utf-8">',
  '<meta name="viewport" content="width=device-width, initial-scale=1">',
  '<title>Ghost is starting</title><style>',
  'body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;',
  'background:#15171A;color:#fff;display:flex;min-height:100vh;margin:0;',
  'align-items:center;justify-content:center;text-align:center}',
  'main{padding:2rem;max-width:34rem}h1{font-size:1.5rem;margin:0 0 .75rem}',
  'p{margin:.35rem 0;color:#c5c8cc;line-height:1.5}</style></head><body>',
  '<main><h1>Ghost is starting</h1>',
  '<p>Preparing this blog for the address you just used.</p>',
  '<p>This page reloads by itself; it usually takes about 20 seconds.</p>',
  '</main><script>',
  '(function(){function t(){fetch(window.location.href,',
  '{cache:"no-store",redirect:"manual"}).then(function(r){',
  'if(r.headers.get("X-TOS-Starting")==="1"){setTimeout(t,2000);}',
  'else{window.location.reload();}}).catch(function(){setTimeout(t,2000);});}',
  'setTimeout(t,2000);})();',
  '</script></body></html>'
].join('');

function respond(res, after) {
  res.writeHead(200, {
    'Content-Type': 'text/html; charset=utf-8',
    'Cache-Control': 'no-store, must-revalidate',
    'X-TOS-Starting': '1'
  });
  res.end(PAGE, after || function () {});
}

function done(server, code) {
  setTimeout(function () {
    try { server.close(); } catch (err) { /* already closed */ }
    process.exit(code);
  }, 200);
}

const server = http.createServer(function (req, res) {
  const header = String(req.headers['x-forwarded-host'] || req.headers.host || '')
    .split(',')[0].trim();
  const host = bareHost(header);
  if (isLocal(host)) {
    respond(res);
    return;
  }
  const url = scheme(req) + '://' + header;
  try {
    fs.writeFileSync(STATE, url.replace(/\/+$/, '') + '\n');
    process.stdout.write('[ghost] captured site address: ' + url + '\n');
  } catch (err) {
    process.stdout.write('[ghost] could not store the site address: ' + err + '\n');
  }
  respond(res, function () { done(server, 0); });
});

server.on('error', function (err) {
  process.stdout.write('[ghost] capture listener failed: ' + err + '\n');
  process.exit(3);
});

server.listen(PORT, '0.0.0.0', function () {
  setTimeout(function () { done(server, 3); }, TIMEOUT_MS);
});
TOSJS
  node "$CAPTURE" &
  capture=$!
  trap 'kill "$capture" 2>/dev/null; exit 0' TERM INT
  wait "$capture" || true
  trap - TERM INT
  url="$(pick_url "$STATE")"
fi

if [ -n "$url" ]; then
  export url
  log "starting Ghost with url=$url"
else
  export url="$FALLBACK"
  log "no external address seen yet; starting with $url"
fi

exec docker-entrypoint.sh node current/index.js
