#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
cd "$OWRT_DIR"
OVR=""; [ -s "$OFFICIAL_DIR/mk-override.txt" ] && OVR="$(cat "$OFFICIAL_DIR/mk-override.txt")"
IGN=""; [ "$IGN_ERR" = "true" ] && IGN="IGNORE_ERRORS=m"
log "Фаза 2: все пакеты (-j$JOBS) ${OVR:+[$OVR]} ${IGN:+[$IGN]}"
# shellcheck disable=SC2086
make -j"$JOBS" $OVR $IGN package/compile || make -j1 $OVR $IGN package/compile V=s \
  || { err "Сборка пакетов упала (logs/)"; exit 1; }
# shellcheck disable=SC2086
make -j"$JOBS" $OVR package/index
# shellcheck disable=SC2086
make -j1 $OVR package/install target/install || make -j1 $OVR package/install target/install V=s \
  || { err "Сборка образа упала (logs/)"; exit 1; }
ok "Пакеты и образ собраны"