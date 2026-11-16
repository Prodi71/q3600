#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
cd "$OWRT_DIR"
make -j"$JOBS" download || make -j1 download V=s || { err "download failed"; exit 1; }
ok "Исходники загружены"