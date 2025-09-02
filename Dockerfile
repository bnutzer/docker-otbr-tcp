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

ENTRYPOINT ["/init"]

ENV PATH=${PATH}:/command

# COPY services.d /etc/services.d
ADD otbr-dataset.sh /usr/local/bin/otbr-dataset.sh
COPY etc-s6-overlay /etc/s6-overlay
