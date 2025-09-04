FROM openthread/otbr:latest
# Openthread provides two images: otbr, and border-router. Both include the
# "otbr-agent", but only otbr has the "otbr-web".

ARG S6_OVERLAY_VERSION=3.2.1.0

RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install --no-install-recommends -y socat xz-utils curl ca-certificates lsof vim strace \
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

ENV OTBR_LOG_LEVEL_INT="6"

ENV RCP_USE_TCP="1"
ENV RCP_PORT="6638"
ENV SOCAT_STARTUP_GRACE_PERIOD="2"
ENV RCP_TTY="/tmp/ttyOTBR"
ENV RCP_BAUDRATE="460800"
ENV SOCAT_SOURCE_PARAMETERS=",raw,echo=0,wait-slave,ignoreeof"
ENV SOCAT_DESTINATION_PARAMETERS=",nodelay,keepalive,forever,interval=5"

ENV OTBR_REST_LISTEN_ADRESS="0.0.0.0"
ENV OTBR_REST_LISTEN_PORT="8081"
ENV OTBR_THREAD_IF="wpan0"
ENV OTBR_BACKBONE_IF="eth0"
ENV OTBR_RCP_ADDITIONAL_ARGS=&uart-flow-control


ENV OTBR_BACKUP_INTERVAL="600"

ENV OTBR_WEB_ENABLE="0"
ENV OTBR_WEB_PORT="8080"
ENV OTBR_WEB_LISTEN_ADDRESS="0.0.0.0"

ENTRYPOINT ["/init"]
