# Docker OpenThread Border Router with TCP Radio Support

A dockerized OpenThread Border Router (OTBR) that connects to network-attached Thread radio devices via TCP, such as SMLIGHT SLZB-06M and similar models.

This extends the standard OpenThread OTBR to support remote radio communication through socat tunneling, making it perfect for setups where your Thread radio is connected to the network rather than directly via USB. The image is based on the upstream image [openthread/border-router](https://hub.docker.com/r/openthread/border-router). OpenThread does not publish versioned images, so the moving tags track upstream's `latest`.

## 🔗 Source Repository

**GitHub:** [bnutzer/docker-otbr-tcp](https://github.com/bnutzer/docker-otbr-tcp)

For complete documentation, configuration details, and source code, visit the GitHub repository.

## 📦 Image Tags

### v2 — current

- **`latest`**, **`v2`** - Most recent v2 build. Rebuilt weekly and on every change; stability depends on upstream.
- **`v2-YYYYMMDD`** - v2 build of that day (e.g., `v2-20260928`)
- **`YYYYMMDD`** - Alias of `v2-YYYYMMDD`, but only for dates from the v2 cutover onwards (see below)
- **`v2-sha-<sha>`**, **`sha-<sha>`** - v2 build of a specific git commit
- **`v2-build-<nr>`** - v2 build of a specific CI run

Pin `v2` rather than `latest` if you want a future major version to be an explicit opt-in.

### v1 — legacy, do not use for new installations

⚠️ **v1 is legacy.** It is based on the older [openthread/otbr](https://hub.docker.com/r/openthread/otbr) image, which upstream targets at test environments. It receives no new features and is **not rebuilt weekly** anymore.

- **`v1`** - Most recent v1 build
- **`v1-YYYYMMDD`**, **`v1-sha-<sha>`**, **`v1-build-<nr>`** - Pinned v1 builds
- Unprefixed **`YYYYMMDD`** tags up to and including `20260921` and **`build-<nr>`** up to `build-67` are v1 images from before the cutover.

**Upgrading from v1:** until the cutover, `latest` was v1 — if you pull `latest`, you now get v2. To stay on v1 for the time being, pin `bnutzer/otbr-tcp:v1`. Migration notes are in the [GitHub README](https://github.com/bnutzer/docker-otbr-tcp#migrating-from-v1).

All images support both `linux/amd64` and `linux/arm64` architectures.

## 🚀 Quick Start

### Minimal Example
```bash
docker run -d \
  --name otbr \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  --device /dev/net/tun \
  -e RCP_HOST=SLZB-06M.local \
  bnutzer/otbr-tcp
```

### Docker Compose (Recommended)
```yaml
services:
  otbr:
    image: bnutzer/otbr-tcp
    container_name: otbr
    network_mode: host
    restart: unless-stopped
    cap_add:
      - NET_ADMIN   # configure wpan0, routes, ip6tables
      - NET_RAW
    devices:
      - /dev/net/tun
    environment:
      - RCP_HOST=SLZB-06M.local  # Replace with your radio's hostname/IP
```

## ⚙️ Key Configuration

This image is configured using environment variables. The only mandatory variable is `RCP_HOST`.
See [the full configuration documentation in github](https://github.com/bnutzer/docker-otbr-tcp).

---

**License:** MIT  
**Maintainer:** [bnutzer](https://github.com/bnutzer)  
**Base Image:** [openthread/border-router](https://hub.docker.com/r/openthread/border-router)
