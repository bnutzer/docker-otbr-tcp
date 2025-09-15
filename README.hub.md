# Docker OpenThread Border Router with TCP Radio Support

A dockerized OpenThread Border Router (OTBR) that connects to network-attached Thread radio devices via TCP, such as SMLIGHT SLZB-06M and similar models.

This extends the standard OpenThread OTBR to support remote radio communication through socat tunneling, making it perfect for setups where your Thread radio is connected to the network rather than directly via USB.

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
  -e RCP_HOST=your-thread-radio.local \
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
      - OTBR_WEB_ENABLE=1        # Optional: Enable web interface
```

## ⚙️ Key Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `RCP_HOST` | **Yes** | - | Hostname or IP of your Thread radio device |
| `RCP_PORT` | No | 6638 | Radio device port (6638 for SMLIGHT devices) |
| `OTBR_WEB_ENABLE` | No | 0 | Set to `1` to enable the web interface on port 8080 |
| `OTBR_THREAD_IF` | No | wpan0 | Thread interface name |

## 🌟 Features

- **Multi-architecture support** - Works on both x64 and ARM64 systems
- **TCP radio support** - Connect to network-attached Thread radios
- **Automatic dataset persistence** - Maintains Thread network configuration across restarts
- **Web interface** - Optional OTBR web UI for management
- **REST API** - Full OpenThread REST API support
- **Docker optimized** - Based on official OpenThread OTBR image

## 📖 Full Documentation

For detailed configuration options, troubleshooting, and advanced usage, see the complete documentation in the [GitHub repository](https://github.com/bnutzer/docker-otbr-tcp).

## 🏠 Common Use Cases

- **Home Assistant integration** - Run alongside Home Assistant for Thread device management
- **Network-attached radios** - Use SMLIGHT or similar TCP-enabled Thread coordinators
- **Multi-architecture deployments** - Deploy on Raspberry Pi, x86 servers, or ARM-based systems
- **Development environments** - Test Thread applications with persistent network state

---

**License:** MIT  
**Maintainer:** [bnutzer](https://github.com/bnutzer)  
**Base Image:** [OpenThread OTBR](https://hub.docker.com/r/openthread/otbr)
