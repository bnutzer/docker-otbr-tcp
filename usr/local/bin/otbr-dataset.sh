#!/bin/sh
# otbr-dataset.sh — persists and restores the thread dataset in a file
# Usage:
#   otbr-dataset.sh restore   # Loads dataset.hex (if available) and starts Thread
#   otbr-dataset.sh backup    # Exports the current dataset to dataset.hex (if changed)

# Script suggested by chatgpt

set -eu

STATE_DIR="${OTBR_STATE_DIR:-/var/lib/otbr}"
DATASET_FILE="$STATE_DIR/dataset.hex"
TMP_FILE="$DATASET_FILE.tmp"
OTBR_THREAD_IF=${OTBR_THREAD_IF:-wpan0}

log() {
	printf '%s %s\n' "[$(date +%F\ %T)]" "$*"
}

wait_otctl() {
	i=0
	while ! ot-ctl -I ${OTBR_THREAD_IF} state >/dev/null 2>&1 ; do
		i=$((i+1))
		if [ "$i" -ge 60 ] ; then
			log "ot-ctl not ready"
			exit 1
		fi
		sleep 1
	done
}

ensure_dir() {
	mkdir -p "$STATE_DIR";
}

restore() {
	ensure_dir
	wait_otctl

	if [ -s "$DATASET_FILE" ]; then
		log "restoring dataset from $DATASET_FILE"

		HEX="$(head -n 1 "${DATASET_FILE}" | tr -d ' \r\n')"
		case "$HEX" in
			(*[!0-9A-Fa-f]*)
				echo "[restore] invalid hex in $DATASET_FILE" >&2
				exit 1
				;;
			(*)
				ot-ctl -I ${OTBR_THREAD_IF} dataset set active "$HEX"
				;;
		esac

		ot-ctl -I ${OTBR_THREAD_IF} dataset commit active
	else
		if ot-ctl -I ${OTBR_THREAD_IF} dataset active >/dev/null 2>&1; then
			log "no persisted dataset, backing up currently active dataset"
			ot-ctl -I ${OTBR_THREAD_IF} dataset active -x > "$TMP_FILE"
			mv -f "$TMP_FILE" "$DATASET_FILE"
		else
			log "no active dataset present -> initializing new dataset"
			ot-ctl -I ${OTBR_THREAD_IF} dataset init new
			ot-ctl -I ${OTBR_THREAD_IF} dataset commit active
			ot-ctl -I ${OTBR_THREAD_IF} dataset active -x > "$TMP_FILE"
			mv -f "$TMP_FILE" "$DATASET_FILE"
		fi
	fi

	# Activate interface/Thread (idempotent)
	ot-ctl -I ${OTBR_THREAD_IF} ifconfig up
	ot-ctl -I ${OTBR_THREAD_IF} thread start

	# YMMV :)
	ot-ctl -I ${OTBR_THREAD_IF} nat64 disable || true

	log "restore done"
}

backup() {
	ensure_dir
	wait_otctl
	if ! ot-ctl -I ${OTBR_THREAD_IF} dataset active >/dev/null 2>&1; then
		log "no active dataset (disabled?) — skipping backup"
		exit 0
	fi
	ot-ctl -I ${OTBR_THREAD_IF} dataset active -x > "$TMP_FILE"
	if grep -q "^Error" $TMP_FILE ; then
		log "ot-ctl active responded with error. Skipping backup."
		exit 0
	fi
	if [ ! -s "$DATASET_FILE" ] || ! cmp -s "$TMP_FILE" "$DATASET_FILE"; then
		mv -f "$TMP_FILE" "$DATASET_FILE"
		log "dataset updated -> $DATASET_FILE"
	else
		rm -f "$TMP_FILE"
		log "dataset unchanged"
	fi
}

case "${1:-}" in
	restore) restore ;;
	backup)  backup  ;;
	*) echo "Usage: $0 {restore|backup}" >&2; exit 2 ;;
esac
