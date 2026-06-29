FROM openthread/border-router:latest
# Older versions of this project were based on openthread/otbr. However, that
# image is targeted towards test environments.
# Starting ~ 2026-05-20, this image will be based on openthread/border-router,
# the production image: Ubuntu 24.04, slim, built with OTBR_DBUS=OFF.

LABEL org.opencontainers.image.title="OTBR TCP"
LABEL org.opencontainers.image.description="OpenThread Border Router with remote TCP RCP support"
LABEL org.opencontainers.image.source="https://github.com/bnutzer/docker-otbr-tcp"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.base.name="openthread/border-router"

RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install --no-install-recommends -y socat lsof vim strace \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Wipe upstream's s6-rc service tree wholesale so our COPY below is the only
# authoritative source. Our tree provides the user/user2 bundle markers that
# s6-overlay's top bundle requires.
RUN rm -rf /etc/s6-overlay/s6-rc.d

COPY etc /etc
COPY usr /usr

ENV OTBR_VENDOR_NAME="OpenThread Border Router"
ENV OTBR_MODEL_NAME="docker-otbr-tcp"

ENV OTBR_LOG_LEVEL_INT="6"

ENV RCP_USE_TCP="1"
ENV RCP_PORT="6638"
ENV RCP_TTY="/tmp/ttyOTBR"
ENV RCP_BAUDRATE="460800"
ENV SOCAT_STARTUP_GRACE_PERIOD="2"
ENV SOCAT_SOURCE_PARAMETERS=",raw,echo=0,wait-slave,ignoreeof"
ENV SOCAT_DESTINATION_PARAMETERS=",nodelay,keepalive,forever,interval=5"

# OTBR_REST_LISTEN_ADDRESS defaults to 0.0.0.0 in the otbr-agent run script.
# No ENV default here so the script can detect explicit user overrides and
# fall back to the legacy misspelled OTBR_REST_LISTEN_ADRESS if set.
ENV OTBR_REST_LISTEN_PORT="8081"
ENV OTBR_THREAD_IF="wpan0"
ENV OTBR_BACKBONE_IF="eth0"
ENV OTBR_RCP_ADDITIONAL_ARGS=&uart-flow-control

ENV OTBR_WEB_ENABLE="0"
ENV OTBR_WEB_PORT="8080"
ENV OTBR_WEB_LISTEN_ADDRESS="0.0.0.0"

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
	CMD wrap-ot-ctl state >/dev/null 2>&1

ENTRYPOINT ["/init"]
