#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
VM="$(cat "$OFFICIAL_DIR/vermagic.txt")"
: > "$OFFICIAL_DIR/mk-override.txt"
if [ "$FORCE_VM" != "true" ]; then log "FORCE_VM=false — пропускаем"; exit 0; fi
cd "$OWRT_DIR"
log "Подставляем официальный vermagic: $VM"
find build_dir -maxdepth 3 -name '.vermagic' -exec sh -c 'echo "  было $1: $(cat "$1")"' _ {} \; || true
FOUND=0
for d in build_dir/target-*/linux-*/linux-*/; do
  [ -d "$d" ] || continue
  printf '%s' "$VM" > "$d/.vermagic"; FOUND=1
done
[ "$FOUND" = "1" ] || warn "Каталоги сборки ядра не найдены"
mkdir -p "$OFFICIAL_DIR/mk-backup"
for f in include/*.mk; do
  if grep -qE '^[[:space:]]*LINUX_VERMAGIC[[:space:]]*[:?+]?=' "$f"; then
    cp "$f" "$OFFICIAL_DIR/mk-backup/"
    sed -i -E "s/^([[:space:]]*)LINUX_VERMAGIC[[:space:]]*[:?+]?=.*/\1LINUX_VERMAGIC:=$VM/" "$f"
    ok "пропатчен $f"
  fi
done
printf 'LINUX_VERMAGIC=%s' "$VM" > "$OFFICIAL_DIR/mk-override.txt"
find build_dir -maxdepth 3 -name '.vermagic' -exec sh -c 'echo "  стало $1: $(cat "$1")"' _ {} \; || true