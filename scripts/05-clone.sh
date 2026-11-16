#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
if [ -d "$OWRT_DIR/.git" ]; then log "Дерево уже есть: $OWRT_DIR"
else
  git clone --depth 1 --branch "v$OWRT_VER" https://github.com/openwrt/openwrt.git "$OWRT_DIR" \
  || git clone --depth 1 --branch "v$OWRT_VER" https://git.openwrt.org/openwrt/openwrt.git "$OWRT_DIR" \
  || { err "Тег v$OWRT_VER не найден"; exit 1; }
fi
cd "$OWRT_DIR"
[ -f "$OFFICIAL_DIR/feeds.buildinfo" ] && cp "$OFFICIAL_DIR/feeds.buildinfo" feeds.conf.default
./scripts/feeds update -a
./scripts/feeds install -a
ok "Фиды установлены"