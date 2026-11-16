#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
cd "$OWRT_DIR"
VM="$(cat "$OFFICIAL_DIR/vermagic.txt")"
KVER_OFF="$(cat "$OFFICIAL_DIR/kver.txt" 2>/dev/null || true)"
OURS=$(find bin -type f \( -name '*.ipk' -o -name '*.apk' \) -name 'kernel[-_]*' | head -n1 || true)
[ -n "$OURS" ] || { err "Не найден собранный kernel-пакет"; exit 1; }
log "Наш kernel-пакет: $(basename "$OURS")"
OURVM=$(hex32 "$(basename "$OURS")"); OURKVER=$(kver "$(basename "$OURS")")
gh_sum "#### Проверка ABI"; gh_sum ""
gh_sum "| | kernel | vermagic |"; gh_sum "|---|---|---|"
gh_sum "| official | \`${KVER_OFF:-?}\` | \`$VM\` |"
gh_sum "| built | \`${OURKVER:-?}\` | \`${OURVM:-?}\` |"; gh_sum ""
PKGIDX=$(find bin -name 'Packages' -type f | head -n1 || true)
if [ -n "$PKGIDX" ]; then
  DEP=$(grep -A12 '^Package: kmod-' "$PKGIDX" | grep -m1 '^Depends:.*kernel' || true)
  [ -n "$DEP" ] && log "Пример зависимости kmod: $DEP"
fi
if [ -n "$KVER_OFF" ] && [ "$OURKVER" != "$KVER_OFF" ]; then
  err "Версия ядра отличается ($OURKVER != $KVER_OFF) — модули несовместимы физически"; exit 1; fi
if [ "$OURVM" != "$VM" ]; then
  err "vermagic не совпал: $OURVM != $VM (см. official/kernel-config.diff)"; exit 1; fi
ok "vermagic совпадает с официальным $OWRT_VER"
gh_sum "✅ vermagic совпадает с официальным $OWRT_VER"; gh_sum ""