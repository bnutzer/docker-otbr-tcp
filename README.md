docker-otbr-tcp
===============

This repository provides tools to run a dockerized OpenThread Border Router that uses a network-attached radio "Thread stick", such as the SMLIGHT models
(https://smlight.tech/).

OpenThread Border Router (OTBR) requires a device file to be passed to its agent. The Home Assistant add-on introduced the ability to use "socat" to create a
local socket and connect it with a remote TCP socket. However, that add-on is only usable in Home Assistant OS. This Docker image uses the same concept for
standard Docker installations.

Despite its name, the image also supports local (USB-attached) thread sticks.

Using docker hub image
======================
The image is published to docker hub for arm64 and x86_64 architectures. You can find it
[on docker hub as bnutzer/otbr-tcp](https://hub.docker.com/r/bnutzer/otbr-tcp).

New images are built weekly. As the upstream image [openthread/otbr](https://hub.docker.com/r/openthread/otbr)
does not provide any meaningful versioning, this image is published as "latest" as well. I cannot guarantee
the latest tag to always provide a stable version.

Building the image
==================

Clone this repository and change to its working directory, then run the Docker build:
```
git clone https://github.com/bnutzer/docker-otbr-tcp.git
cd docker-otbr-tcp
docker build -t otbr-tcp .
```

Configuration
=============

OTBR in this image can be configured by setting environment variables (see below for usage). These variables are currently available:

| Component | Variable | Default | Description |
|-----------|----------|---------|-------------|
| global | OTBR_LOG_LEVEL_INT | 6 | Log level for OTBR (6 = info) |
| rcp | RCP_USE_TCP | 1 | This image can also use a local (USB) Thread stick by setting this variable to 0 (and setting the TTY to your USB device) |
| rcp | RCP_HOST | (n/a) | The hostname or IP of your radio device |
| rcp | RCP_PORT | 6638 | Port of your radio device. 6638 is the default for SMLIGHT devices |
| rcp | RCP_TTY | /tmp/ttyOTBR | For TCP mode, socat and agent use this as their shared socket. Point to your USB device for local radio |
| rcp | SOCAT_SOURCE_PARAMETERS | ,raw,echo=0,wait-slave,ignoreeof | Additional arguments to the local socket configuration for socat |
| rcp | SOCAT_DESTINATION_PARAMETERS | ,nodelay,keepalive,forever,interval=5 | Additional arguments to the remote socket configuration for socat |
| agent | RCP_BAUDRATE | 460800 | Communication baud rate for the radio. The default is the maximum; reduce by factors of 2 or 4 for increased stability |
| agent | SOCAT_STARTUP_GRACE_PERIOD | 2 | Additional wait time to allow socat to contact the radio |
| agent | OTBR_REST_LISTEN_ADDRESS | 0.0.0.0 | Local address for OTBR REST interface. 0.0.0.0 is public. IPv6 options not yet explored |
| agent | OTBR_REST_LISTEN_PORT | 8081 | Port of OTBR REST interface |
| agent, web | OTBR_THREAD_IF | wpan0 | TUN device created and used by OTBR. Set to a different device for running multiple instances |
| agent | OTBR_BACKBONE_IF | eth0 | Local network device |
| agent | OTBR_RCP_ADDITIONAL_ARGS | &uart-flow-control | RCP arguments to pass to OTBR. Default enables flow control |
| agent | OTBR_VENDOR_NAME | OpenThread Border Router | Vendor name reported by the OTBR agent |
| agent | OTBR_MODEL_NAME | docker-otbr-tcp | Model name reported by the OTBR agent |
| agent | OTBR_SERVICEBASENAME | | Set service base name of router. Defaults to "OpenThread BR (unspecified vendor)" and will be appended an identifier |
| web | OTBR_WEB_ENABLE | 0 | Enable OTBR web interface by setting this value to "1" |
| web | OTBR_WEB_PORT | 8080 | Port for web interface |
| web | OTBR_WEB_LISTEN_ADDRESS | 0.0.0.0 | Local listening address for web interface |

Running the image
=================

The only mandatory configuration variable is "RCP_HOST"; the defaults work fine for many cases.

## Using Docker

```bash
docker run -e RCP_HOST=SLZB-06M.local -v ./otbr-data:/var/lib/thread --rm otbr-tcp
```

## Using Docker Compose

OTBR might commonly be run on the same machine running Home Assistant. This is a sample docker-compose.yml:

```yaml
services:
  otbr:
    image: bnutzer/otbr-tcp
    network_mode: host
    restart: unless-stopped
    privileged: true
    cap_drop:
      - NET_ADMIN   # Should prevent iptables/ipset updates
      - NET_RAW     # No raw network access
    devices:
      - /dev/net/tun
    environment:
      - RCP_HOST=SLZB-06M.local
    volumes:
      - ./otbr-data:/var/lib/thread
```

Then run:
```bash
docker compose up -d otbr
```

Dataset management
==================

OpenThread Border Router maintains its state in files in `/var/lib/thread`. This state includes an identifier, and the dataset.
Using a persistent volume for these data will help your router to stay in its Thread mesh.

Security considerations
=======================

The upstream OpenThread Border Router is a reference implementation and not originally intended to be run on production installations
unchanged. However, the public community (we!) use it for that purpose.

The otbr API is not authenticated. If any device has access to your physical network, it may be able to re-configure your thread network and
gain access to your IoT devices, including ones that might pose security risks such as smart locks. It is strongly advisable to restrict access
to the container, e.g., by setting the listen address to 127.0.0.1, setting up firewalls, etc.

otbr-web
========

otbr-web is a very basic web app for interaction with the otbr REST API. It is even less fit for production setups, and yet, it's the best option
we have to get an overview of our installations.

Unfortunately, configuring otbr securely clashes with the expectations of otbr-web. The web interface normally expects the REST interface to be open
for access from the browser. For otbr-web to work, you need to have a `OTBR_REST_LISTEN_ADDRESS` that allows access from your browser. A non-default
`OTBR_REST_LISTEN_PORT` is handled automatically: the start script passes it to otbr-web via `-P`, so no source patching is required.

> **Caveat:** The web UI's JavaScript runs in *your browser* and queries the REST API directly. The REST address and port (`OTBR_REST_LISTEN_ADDRESS`
> / `OTBR_REST_LISTEN_PORT`) must therefore be reachable from the browser's network, not just from inside the container or the Docker host. A REST
> interface bound to a loopback or internal-only address will leave the web UI unable to load data, even though otbr-web itself starts fine.

ot-ctl wrapper
==============

otbr can be managed using the cli program `ot-ctl`. When using a non-default `OTBR_THREAD_IF`, that interface needs to be passed to ot-ctl.
For simplification, this image provides a wrapper `wrap-ot-ctl` that automatically uses the configured `OTBR_THREAD_IF` value, reducing the
risk of passing the wrong device, e.g., when multiple containers are running in parallel.

Example usage:
```bash
docker compose exec otbr wrap-ot-ctl state
docker compose exec otbr wrap-ot-ctl dataset active
```

License
=======

These Docker image build files are licensed under the MIT license. See the LICENSE file for details.
