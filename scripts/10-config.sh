#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
cd "$OWRT_DIR"
cp "$OFFICIAL_DIR/config.buildinfo" .config
cat "$ROOT/ax3600.config" >> .config
ok "база: официальный config.buildinfo + ax3600.config"

USER_CFG="$OFFICIAL_DIR/user.cfg"; WANT="$OFFICIAL_DIR/want.txt"
UNKNOWN="$OFFICIAL_DIR/unknown.txt"; AVAIL="$OFFICIAL_DIR/available-packages.txt"
: > "$USER_CFG"; : > "$WANT"; : > "$UNKNOWN"
SRC="$ROOT/packages.config_obrez.txt"
if [ -f "$SRC" ]; then
  awk '
    /^[[:space:]]*$/ {next}
    /^# CONFIG_[A-Za-z0-9_]+ is not set$/ {print; next}
    /^[[:space:]]*#/ {next}
    { l=$0; gsub(/\r/,"",l); gsub(/^[[:space:]]+|[[:space:]]+$/,"",l)
      if (l ~ /^CONFIG_/) print l
      else if (l ~ /^[A-Za-z0-9_.+-]+$/) print "CONFIG_PACKAGE_" l "=y" }
  ' "$SRC" | awk '!seen[$0]++' > "$USER_CFG"
  grep -E '^CONFIG_(KERNEL_|TARGET_|LINUX_|VERSION_)' "$USER_CFG" > "$OFFICIAL_DIR/stripped.cfg" || true
  if [ -s "$OFFICIAL_DIR/stripped.cfg" ]; then
    warn "Выкинуто из списка (влияет на ядро/цель):"; cat "$OFFICIAL_DIR/stripped.cfg"; fi
  grep -vE '^CONFIG_(KERNEL_|TARGET_|LINUX_|VERSION_)' "$USER_CFG" >> .config || true
  ok "список применён как =y"
else warn "packages.config_obrez.txt не найден"; fi

make defconfig

if [ -f tmp/.packageinfo ]; then
  awk '/^Package: /{print $2} /^Provides: /{for(i=2;i<=NF;i++) print $i}' tmp/.packageinfo \
    | tr -d ',' | sed '/^$/d' | sort -u > "$AVAIL"
  sed -nE 's/^CONFIG_PACKAGE_([A-Za-z0-9_.+-]+)=[ym]$/\1/p' "$USER_CFG" | sort -u > "$WANT"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    grep -qx "$p" "$AVAIL" || printf '%s\n' "$p" >> "$UNKNOWN"
  done < "$WANT"
  if [ -s "$UNKNOWN" ]; then
    warn "Нет таких пакетов в $OWRT_VER (удаляю из .config):"
    gh_sum "#### ⚠️ Пакеты, которых нет в $OWRT_VER (удалены)"; gh_sum ""
    gh_sum "| запрошено | похожие в дереве |"; gh_sum "|---|---|"
    while IFS= read -r p; do
      b=$(printf '%s' "$p" | sed -E 's/[0-9]+$//')
      s=$(grep -F "$b" "$AVAIL" | head -4 | tr '\n' ' ' || true)
      printf '   - %-32s -> %s\n' "$p" "${s:-—}"
      gh_sum "| \`$p\` | ${s:-—} |"
      awk -v pre="CONFIG_PACKAGE_${p}=" 'index($0,pre)!=1' .config > .config.tmp && mv .config.tmp .config
    done < "$UNKNOWN"
    gh_sum ""; make defconfig
  else ok "все имена пакетов валидны"; fi
else warn "tmp/.packageinfo нет — валидация пропущена"; fi

for p in base-files busybox procd netifd firewall4 dnsmasq-full luci kmod-mac80211 kmod-ath11k; do
  grep -q "^CONFIG_PACKAGE_$p=y" .config || warn "$p не =y — прошивка будет неполной"
done

./scripts/diffconfig.sh > "$OFFICIAL_DIR/ours.config.diff"
if diff <(grep -E '^(# )?CONFIG_KERNEL_' "$OFFICIAL_DIR/config.buildinfo" | sort) \
        <(grep -E '^(# )?CONFIG_KERNEL_' "$OFFICIAL_DIR/ours.config.diff" | sort) \
        > "$OFFICIAL_DIR/kernel-config.diff"; then
  ok "CONFIG_KERNEL_* идентичны официальным -> vermagic совпадёт"
else warn "Конфиг ядра разошёлся с релизным:"; cat "$OFFICIAL_DIR/kernel-config.diff" || true; fi
grep -E 'ALL_KMODS|ALL_NONSHARED|TARGET_qualcommax|USE_APK' .config || true
cp .config "$OFFICIAL_DIR/final.config"