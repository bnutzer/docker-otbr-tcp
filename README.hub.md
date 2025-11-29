# Docker OpenThread Border Router with TCP Radio Support

A dockerized OpenThread Border Router (OTBR) that connects to network-attached Thread radio devices via TCP, such as SMLIGHT SLZB-06M and similar models.

This extends the standard OpenThread OTBR to support remote radio communication through socat tunneling, making it perfect for setups where your Thread radio is connected to the network rather than directly via USB. The image is based on the original/upstream image by OpenThread. OpenThread does not publish versioned images, so neither do we.

## 🔗 Source Repository

**GitHub:** [bnutzer/docker-otbr-tcp](https://github.com/bnutzer/docker-otbr-tcp)

For complete documentation, configuration details, and source code, visit the GitHub repository.

## 📦 Image Tags

- **`latest`** - Latest release. Stability depends on upstream image.
- **`YYYYMMDD`** - Date-based releases (e.g., `20250905`)

All images support both `linux/amd64` and `linux/arm64` architectures.

## 🚀 Quick Start

### Minimal Example
```bash
docker run -d \
  --name otbr \
  --network host \
  --privileged \
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
    privileged: true
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
**Base Image:** [OpenThread OTBR](https://hub.docker.com/r/openthread/otbr)
