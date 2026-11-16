#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
cd "$OWRT_DIR"
log "Фаза 1: tools + toolchain + kernel (-j$JOBS)"
make -j"$JOBS" tools/install toolchain/install target/compile \
  || make -j1 tools/install toolchain/install target/compile V=s \
  || { err "Сборка ядра упала (logs/)"; exit 1; }
ok "Ядро собрано"
find build_dir -maxdepth 3 -name '.vermagic' -exec sh -c 'echo "  $1: $(cat "$1")"' _ {} \; || true