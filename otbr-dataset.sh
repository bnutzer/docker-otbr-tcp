#!/bin/sh
# Script suggested by chatgpt
#  https://chatgpt.com/c/68b5e509-9288-8322-87e1-24f1ed92866f
# otbr-dataset.sh — persistiert das Thread-Dataset in eine Datei und stellt es wieder her.
# Nutzung:
#   otbr-dataset.sh restore   # lädt dataset.hex (falls vorhanden) und startet Thread
#   otbr-dataset.sh backup    # exportiert das aktuelle Dataset nach dataset.hex (nur bei Änderung)

set -eu

STATE_DIR="${OTBR_STATE_DIR:-/var/lib/otbr}"
DATASET_FILE="$STATE_DIR/dataset.hex"
TMP_FILE="$DATASET_FILE.tmp"

log(){ printf '%s %s\n' "[$(date +%F\ %T)]" "$*" ; }

wait_otctl() {
  i=0
  while ! ot-ctl state >/dev/null 2>&1; do
    i=$((i+1))
    [ "$i" -ge 60 ] && { log "ot-ctl not ready"; exit 1; }
    sleep 1
  done
}

ensure_dir() { mkdir -p "$STATE_DIR"; }

restore() {
  ensure_dir
  wait_otctl

  if [ -s "$DATASET_FILE" ]; then
    log "restoring dataset from $DATASET_FILE"
    # Dataset setzen und dauerhaft machen


    if [ -s "$DATASET_FILE" ]; then

      HEX="$(head -n 1 "${DATASET_FILE}" | tr -d ' \r\n')"
      case "$HEX" in
        (*[!0-9A-Fa-f]*) echo "[restore] invalid hex in $DATASET_FILE" >&2 ;;
        (*) ot-ctl dataset set active "$HEX" ;;
      esac
    fi

    ot-ctl dataset commit active || true
  else
    # Falls nichts persistiert ist: existierendes Dataset sichern oder neues erzeugen
    if ot-ctl dataset active >/dev/null 2>&1; then
      log "no persisted dataset, backing up currently active dataset"
      ot-ctl dataset active -x > "$TMP_FILE"
      mv -f "$TMP_FILE" "$DATASET_FILE"
    else
      log "no active dataset present -> initializing new dataset"
      ot-ctl dataset init new
      ot-ctl dataset commit active
      ot-ctl dataset active -x > "$TMP_FILE"
      mv -f "$TMP_FILE" "$DATASET_FILE"
    fi
  fi

  # Interface/Thread hochfahren (idempotent)
  ot-ctl ifconfig up || true
  ot-ctl thread start || true

  # Optional: NAT64 deaktivieren (falls unerwünscht)
  ot-ctl nat64 disable >/dev/null 2>&1 || true

  log "restore done"
}

backup() {
  ensure_dir
  wait_otctl
  if ! ot-ctl dataset active >/dev/null 2>&1; then
    log "no active dataset (disabled?) — skipping backup"
    exit 0
  fi
  ot-ctl dataset active -x > "$TMP_FILE"
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
