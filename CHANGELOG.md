# Changelog

All notable user-visible changes to the Ghost TOS application package.

## 6.65.0-1 — 2026-09-27

### Added
- First release. Ghost (`ghost:6.65.0-alpine`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8003 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/ghostdocker/`.
