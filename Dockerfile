# OpenThread Border Router with TCP-based RCP support (via socat)
# Based on bnutzer/docker-otbr-tcp (MIT License)
# Upstream: https://github.com/bnutzer/docker-otbr-tcp

# Pin base image digest for reproducible builds
# To update: docker pull openthread/otbr:latest && docker inspect --format='{{index .RepoDigests 0}}' openthread/otbr:latest
FROM openthread/otbr@sha256:331fffa741e504901f7818e991952cc34ff45edb675ed6cb42a9f43a2b5d5be6

LABEL org.opencontainers.image.title="OTBR TCP"
LABEL org.opencontainers.image.description="OpenThread Border Router with remote TCP RCP support"
LABEL org.opencontainers.image.source="https://github.com/bnutzer/docker-otbr-tcp"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.base.name="openthread/otbr"

ARG S6_OVERLAY_VERSION=3.2.1.0

RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install --no-install-recommends -y socat xz-utils curl ca-certificates lsof \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN set -eux; \
	if [ -z "${TARGETARCH:-}" ]; then \
		if command -v dpkg >/dev/null 2>&1; then \
			TARGETARCH="$(dpkg --print-architecture)"; \
		else \
			TARGETARCH="$(uname -m)"; \
		fi; \
	fi; \
	case "${TARGETARCH}" in \
		amd64)  S6_ARCH=x86_64 ;; \
		arm64)  S6_ARCH=aarch64 ;; \
		*) echo "Unsupported TARGETARCH=${TARGETARCH}"; exit 1 ;; \
	esac; \
	curl -fsSL -o /tmp/s6-noarch.tar.xz  "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz"; \
	curl -fsSL -o /tmp/s6-arch.tar.xz    "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz"; \
	tar -C / -Jxpf /tmp/s6-noarch.tar.xz; \
	tar -C / -Jxpf /tmp/s6-arch.tar.xz; \
	rm -f /tmp/s6-*.tar.xz

ENV PATH=${PATH}:/command

COPY etc /etc
COPY usr /usr

# --- Logging ---
ENV OTBR_LOG_LEVEL_INT="6"

# --- RCP (Radio Co-Processor) via TCP/socat ---
ENV RCP_USE_TCP="1"
ENV RCP_PORT="6638"
ENV RCP_TTY="/tmp/ttyOTBR"
ENV RCP_BAUDRATE="460800"
ENV SOCAT_STARTUP_GRACE_PERIOD="2"
ENV SOCAT_SOURCE_PARAMETERS=",raw,echo=0,wait-slave,ignoreeof"
ENV SOCAT_DESTINATION_PARAMETERS=",nodelay,keepalive,forever,interval=5"

# --- OTBR REST API ---
ENV OTBR_REST_LISTEN_ADDRESS="0.0.0.0"
# Keep legacy typo for backwards compatibility with existing deployments
ENV OTBR_REST_LISTEN_ADRESS="0.0.0.0"
ENV OTBR_REST_LISTEN_PORT="8081"

# --- OTBR Network ---
ENV OTBR_THREAD_IF="wpan0"
ENV OTBR_BACKBONE_IF="eth0"
ENV OTBR_RCP_ADDITIONAL_ARGS="&uart-flow-control"

# --- OTBR Web UI (disabled by default) ---
ENV OTBR_WEB_ENABLE="0"
ENV OTBR_WEB_PORT="8080"
ENV OTBR_WEB_LISTEN_ADDRESS="0.0.0.0"
ENV OTBR_WEB_PATCH_REST_PORT="0"

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -sf http://localhost:${OTBR_REST_LISTEN_PORT:-8081}/node/state || exit 1

ENTRYPOINT ["/init"]
