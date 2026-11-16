#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
BASE_URL="$DL/$OWRT_VER/targets/$TGT/$SUB"
log "Официальный репозиторий: $BASE_URL"
if ! curl -fsSL "$BASE_URL/" -o "$OFFICIAL_DIR/index.html"; then
  err "Релиз $OWRT_VER для $TGT/$SUB не найден на downloads.openwrt.org"; exit 1; fi
if ! curl -fsSL "$BASE_URL/config.buildinfo" -o "$OFFICIAL_DIR/config.buildinfo"; then
  err "Нет config.buildinfo — не воспроизвести конфиг ядра (vermagic)"; exit 1; fi
ok "config.buildinfo получен"
if curl -fsSL "$BASE_URL/feeds.buildinfo" -o "$OFFICIAL_DIR/feeds.buildinfo"; then
  ok "feeds.buildinfo получен"
else warn "feeds.buildinfo недоступен — используем дефолтные фиды"; fi

VM=""; KVER=""
if curl -fsSL "$BASE_URL/packages/" -o "$OFFICIAL_DIR/packages-index.html" 2>/dev/null; then
  KFN=$(grep -oE 'kernel[-_][0-9][^"<>[:space:]]*\.(ipk|apk)' "$OFFICIAL_DIR/packages-index.html" | head -n1 || true)
  if [ -n "${KFN:-}" ]; then VM=$(hex32 "$KFN"); KVER=$(kver "$KFN"); log "kernel официалов: $KFN"; fi
fi
if [ -z "$VM" ]; then
  MAN=$(grep -oE '[^"<>[:space:]]+\.manifest' "$OFFICIAL_DIR/index.html" | head -n1 || true)
  if [ -n "$MAN" ]; then
    curl -fsSL "$BASE_URL/$MAN" -o "$OFFICIAL_DIR/official.manifest" || true
    LINE=$(awk '$1=="kernel"{print $NF; exit}' "$OFFICIAL_DIR/official.manifest" 2>/dev/null || true)
    VM=$(hex32 "$LINE"); KVER=$(kver "$LINE")
  fi
fi
[ -n "$VM_INPUT" ] && VM="$VM_INPUT"
if ! [[ "$VM" =~ ^[0-9a-f]{32}$ ]]; then
  err "Не определён официальный vermagic (получено: '${VM:-пусто}'). Задайте input 'vermagic'."; exit 1; fi
printf '%s' "$VM" > "$OFFICIAL_DIR/vermagic.txt"
printf '%s' "$KVER" > "$OFFICIAL_DIR/kver.txt"
gh_out vm "$VM"; gh_out kver "$KVER"
ok "Официальное ядро: ${KVER:-?}  vermagic: $VM"
gh_sum "### OpenWrt $OWRT_VER · $TGT/$SUB · $DEV"; gh_sum ""
gh_sum "Официальный kernel: \`${KVER:-?}\` · vermagic: \`$VM\`"; gh_sum ""