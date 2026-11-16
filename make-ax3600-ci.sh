#!/usr/bin/env bash
# Генератор проекта OpenWrt CI для Xiaomi AX3600 + упаковка в zip
set -euo pipefail
P="openwrt-ax3600-ci"
mkdir -p "$P"/{.github/workflows,scripts,docs}
cd "$P"

# ================================================================== .config
cat > ax3600.config <<'__SEED__'
# Xiaomi Mi AIoT Router AX3600 · OpenWrt qualcommax/ipq807x
# Seed для .config — накладывается ПОВЕРХ официального config.buildinfo.
# ВАЖНО: не добавлять CONFIG_KERNEL_* / CONFIG_LINUX_* — меняется vermagic (ABI kmod).

CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq807x=y
# CONFIG_TARGET_MULTI_PROFILE is not set
# CONFIG_TARGET_ALL_PROFILES is not set
CONFIG_TARGET_qualcommax_ipq807x_DEVICE_xiaomi_ax3600=y

# собрать ВСЕ kernel-модули как пакеты (=m)
CONFIG_DEVEL=y
CONFIG_ALL_KMODS=y
CONFIG_ALL_NONSHARED=y

CONFIG_BUILD_LOG=y
CONFIG_CCACHE=y
# CONFIG_AUTOREMOVE=y      # раскомментировать, если мало диска

CONFIG_TARGET_ROOTFS_SQUASHFS=y
# CONFIG_TARGET_ROOTFS_INITRAMFS is not set

# ---- снятие конфликтующих вариантов ----
# CONFIG_PACKAGE_dnsmasq is not set
CONFIG_PACKAGE_dnsmasq-full=y
# CONFIG_PACKAGE_wpad-basic-mbedtls is not set
# CONFIG_PACKAGE_wpad-basic-openssl is not set
# CONFIG_PACKAGE_wpad-mini is not set
CONFIG_PACKAGE_wpad-openssl=y
# CONFIG_PACKAGE_libustream-mbedtls is not set
CONFIG_PACKAGE_libustream-openssl=y
# CONFIG_PACKAGE_libuhttpd-mbedtls is not set
CONFIG_PACKAGE_libuhttpd-openssl=y
# CONFIG_PACKAGE_nftables-nojson is not set
CONFIG_PACKAGE_nftables-json=y
# CONFIG_PACKAGE_ip-tiny is not set
CONFIG_PACKAGE_ip-full=y
__SEED__

# ========================================================== список пакетов
cat > packages.config_obrez.txt <<'__PKGS__'
# Xiaomi AX3600 · OpenWrt 25.12.x
# Одно имя на строку -> CONFIG_PACKAGE_<имя>=y. '#' — комментарий, дубли удаляются.
# Все kmod-* дополнительно собираются целиком (CONFIG_ALL_KMODS=y) и попадут в packages/.

# ---- база ----
base-files
busybox
ca-bundle
ca-certificates
cgi-io
dropbear
firewall4
fstools
fwtool
getrandom
jshn
jsonfilter
logd
losetup
mtd
netifd
odhcp6c
odhcpd-ipv6only
procd
procd-seccomp
procd-ujail
terminfo
ubi-utils
ubox
ubus
ubusd
uci
uclient-fetch
urandom-seed
urngd
e2fsprogs
htop

# ---- ucode / rpcd ----
ucode
ucode-mod-fs
ucode-mod-html
ucode-mod-lua
ucode-mod-math
ucode-mod-nl80211
ucode-mod-rtnl
ucode-mod-ubus
ucode-mod-uci
ucode-mod-uloop
rpcd
rpcd-mod-file
rpcd-mod-iwinfo
rpcd-mod-luci
rpcd-mod-rrdns
rpcd-mod-ucode

# ---- TLS: варианты OpenSSL ----
libustream-openssl
libuhttpd-openssl
openssl-util
wget-ssl
curl

# ---- Wi-Fi: IPQ8074 + QCA9887 (AIoT) ----
ipq-wifi-xiaomi_ax3600
ath11k-firmware-ipq8074
ath10k-board-qca9887
ath10k-firmware-qca9887
hostapd-common
wpad-openssl
wireless-regdb
iw
iwinfo
kmod-ath
kmod-ath11k
kmod-ath11k-ahb
kmod-ath10k-ct-smallbuffers
kmod-cfg80211
kmod-mac80211

# ---- сеть / netfilter ----
ip-full
nftables-json
mtr-json
kmod-libphy
kmod-phy-aquantia
kmod-qca-nss-dp
kmod-qca-ssdk
kmod-qrtr
kmod-qrtr-smd
kmod-nfnetlink
kmod-nf-conntrack
kmod-nf-conntrack6
kmod-nf-conntrack-netlink
kmod-nf-flow
kmod-nf-log
kmod-nf-log6
kmod-nf-nat
kmod-nf-reject
kmod-nf-reject6
kmod-nf-tproxy
kmod-nft-core
kmod-nft-fib
kmod-nft-nat
kmod-nft-offload
kmod-nft-tproxy

# ---- crypto ----
kmod-crypto-aead
kmod-crypto-ccm
kmod-crypto-cmac
kmod-crypto-crc32c
kmod-crypto-ctr
kmod-crypto-gcm
kmod-crypto-gf128
kmod-crypto-ghash
kmod-crypto-hash
kmod-crypto-hmac
kmod-crypto-kpp
kmod-crypto-lib-chacha20
kmod-crypto-lib-chacha20poly1305
kmod-crypto-lib-curve25519
kmod-crypto-lib-poly1305
kmod-crypto-manager
kmod-crypto-michael-mic
kmod-crypto-null
kmod-crypto-rng
kmod-crypto-seqiv
kmod-crypto-sha512
kmod-lib-crc-ccitt
kmod-lib-crc16
kmod-lib-crc32c
kmod-nls-base

# ---- PPP / USB / железо ----
ppp
ppp-mod-pppoe
kmod-ppp
kmod-pppoe
kmod-pppox
kmod-slhc
kmod-fs-ext4
kmod-gpio-button-hotplug
kmod-leds-gpio
kmod-hwmon-core
kmod-thermal
kmod-usb-core
kmod-usb3
kmod-usb-xhci-hcd
kmod-usb-dwc3
kmod-usb-dwc3-qcom

# ---- VPN ----
openvpn-openssl
wireguard-tools
kmod-wireguard
kmod-tun
kmod-udptunnel4
kmod-udptunnel6

# ---- LuCI ----
luci
luci-base
luci-compat
luci-lua-runtime
luci-mod-admin-full
luci-mod-network
luci-mod-status
luci-mod-system
luci-app-firewall
luci-app-openvpn
luci-app-package-manager
luci-proto-ipv6
luci-proto-ppp
luci-proto-wireguard
luci-theme-bootstrap
luci-theme-material
uhttpd
uhttpd-mod-ubus
__PKGS__

# ================================================================== lib.sh
cat > scripts/lib.sh <<'__LIB__'
#!/usr/bin/env bash
set -euo pipefail
: "${OWRT_VER:=25.12.6}"
: "${TGT:=qualcommax}"
: "${SUB:=ipq807x}"
: "${DEV:=xiaomi_ax3600}"
: "${DL:=https://downloads.openwrt.org/releases}"
: "${FORCE_VM:=true}"
: "${IGN_ERR:=true}"
: "${VM_INPUT:=}"
: "${JOBS:=$(nproc)}"
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ROOT:=$(cd "$_LIB_DIR/.." && pwd)}"
: "${OWRT_DIR:=$ROOT/openwrt}"
: "${OUT_DIR:=$ROOT/out}"
: "${OFFICIAL_DIR:=$ROOT/official}"
mkdir -p "$OFFICIAL_DIR" "$OUT_DIR"
: "${GITHUB_OUTPUT:=$OFFICIAL_DIR/gh-output.env}"
: "${GITHUB_STEP_SUMMARY:=$OFFICIAL_DIR/summary.md}"
touch "$GITHUB_OUTPUT" "$GITHUB_STEP_SUMMARY"
log(){ printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok(){  printf '\033[1;32m OK\033[0m %s\n' "$*"; }
warn(){ printf '::warning::%s\n' "$*"; }
err(){ printf '::error::%s\n' "$*"; }
gh_out(){ printf '%s=%s\n' "$1" "$2" >> "$GITHUB_OUTPUT"; }
gh_sum(){ printf '%s\n' "$*" >> "$GITHUB_STEP_SUMMARY"; }
hex32(){ grep -oE '[0-9a-f]{32}' <<<"$1" | head -n1 || true; }
kver(){ grep -oE '[0-9]+\.[0-9]+\.[0-9]+' <<<"$1" | head -n1 || true; }
__LIB__

# ========================================================== 00-official.sh
cat > scripts/00-official.sh <<'__S00__'
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
__S00__

# ============================================================= 05-clone.sh
cat > scripts/05-clone.sh <<'__S05__'
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
__S05__

# ============================================================ 10-config.sh
cat > scripts/10-config.sh <<'__S10__'
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
__S10__

# ========================================================== 15-download.sh
cat > scripts/15-download.sh <<'__S15__'
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
cd "$OWRT_DIR"
make -j"$JOBS" download || make -j1 download V=s || { err "download failed"; exit 1; }
ok "Исходники загружены"
__S15__

# ======================================================= 20-build-kernel.sh
cat > scripts/20-build-kernel.sh <<'__S20__'
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
cd "$OWRT_DIR"
log "Фаза 1: tools + toolchain + kernel (-j$JOBS)"
make -j"$JOBS" tools/install toolchain/install target/compile \
  || make -j1 tools/install toolchain/install target/compile V=s \
  || { err "Сборка ядра упала (logs/)"; exit 1; }
ok "Ядро собрано"
find build_dir -maxdepth 3 -name '.vermagic' -exec sh -c 'echo "  $1: $(cat "$1")"' _ {} \; || true
__S20__

# =========================================================== 25-vermagic.sh
cat > scripts/25-vermagic.sh <<'__S25__'
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
__S25__

# ===================================================== 30-build-packages.sh
cat > scripts/30-build-packages.sh <<'__S30__'
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
__S30__

# ============================================================= 35-verify.sh
cat > scripts/35-verify.sh <<'__S35__'
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
__S35__

# ============================================================ 40-collect.sh
cat > scripts/40-collect.sh <<'__S40__'
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
cd "$OWRT_DIR"
mkdir -p "$OUT_DIR"/{packages,kmods,firmware,meta,repo}
mapfile -t SRCS < <(for d in "$OWRT_DIR/bin/packages" "$OWRT_DIR/bin/targets"; do [ -d "$d" ] && echo "$d"; done)
[ "${#SRCS[@]}" -gt 0 ] || { err "Нет bin/packages и bin/targets"; exit 1; }
log "Собираем пакеты в out/packages"
find "${SRCS[@]}" -type f \( -name '*.ipk' -o -name '*.apk' \) -print0 \
 | while IFS= read -r -d '' f; do cp -ln "$f" "$OUT_DIR/packages/" 2>/dev/null || cp -n "$f" "$OUT_DIR/packages/"; done
find "$OUT_DIR/packages" -maxdepth 1 -type f -name 'kmod-*' -print0 \
 | while IFS= read -r -d '' f; do cp -ln "$f" "$OUT_DIR/kmods/" 2>/dev/null || cp -n "$f" "$OUT_DIR/kmods/"; done
TDIR="$OWRT_DIR/bin/targets/$TGT/$SUB"
if [ -d "$TDIR" ]; then
  find "$TDIR" -maxdepth 1 -type f -name "*$DEV*" -exec cp -n {} "$OUT_DIR/firmware/" \; 2>/dev/null || true
  find "$TDIR" -maxdepth 1 -type f -name '*.manifest' -exec cp -n {} "$OUT_DIR/firmware/" \; 2>/dev/null || true
  for f in config.buildinfo feeds.buildinfo sha256sums profiles.json; do
    [ -f "$TDIR/$f" ] && cp -n "$TDIR/$f" "$OUT_DIR/firmware/" || true; done
fi
find bin -type f \( -name 'Packages*' -o -name 'packages.adb' -o -name '*.manifest' \) \
  -exec cp -n {} "$OUT_DIR/meta/" \; 2>/dev/null || true
[ -d "$OWRT_DIR/bin/packages" ] && cp -al "$OWRT_DIR/bin/packages/." "$OUT_DIR/repo/" 2>/dev/null || true
if [ -d "$TDIR/packages" ]; then
  mkdir -p "$OUT_DIR/repo/targets/$TGT/$SUB"
  cp -al "$TDIR/packages/." "$OUT_DIR/repo/targets/$TGT/$SUB/" 2>/dev/null || true
fi
cp "$OFFICIAL_DIR/final.config"     "$OUT_DIR/firmware/build.config"      2>/dev/null || true
cp "$OFFICIAL_DIR/ours.config.diff" "$OUT_DIR/firmware/build.config.diff" 2>/dev/null || true
cp "$OFFICIAL_DIR/vermagic.txt"     "$OUT_DIR/firmware/vermagic.txt"      2>/dev/null || true
[ -s "$OFFICIAL_DIR/unknown.txt" ] && cp "$OFFICIAL_DIR/unknown.txt" "$OUT_DIR/meta/unknown-packages.txt" || true
( cd "$OUT_DIR/packages" && sha256sum ./* > "$OUT_DIR/SHA256SUMS-packages.txt" ) 2>/dev/null || true
N_ALL=$(find "$OUT_DIR/packages" -maxdepth 1 -type f | wc -l)
N_KMOD=$(find "$OUT_DIR/kmods" -maxdepth 1 -type f | wc -l)
log "пакетов: $N_ALL, из них kmod: $N_KMOD"
gh_sum "#### Результат"; gh_sum ""
gh_sum "- пакетов в \`packages/\`: **$N_ALL**"
gh_sum "- из них \`kmod-*\`: **$N_KMOD**"; gh_sum ""
du -sh "$OUT_DIR"/* || true
__S40__

# ========================================================== local-build.sh
cat > scripts/local-build.sh <<'__SLB__'
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
S="$(cd "$(dirname "$0")" && pwd)"
log "OpenWrt $OWRT_VER · $TGT/$SUB · $DEV · jobs=$JOBS"
for s in 00-official 05-clone 10-config 15-download 20-build-kernel 25-vermagic 30-build-packages 35-verify 40-collect; do
  bash "$S/$s.sh"
done
ok "Готово: $OUT_DIR"
cat "$GITHUB_STEP_SUMMARY"
__SLB__

# ================================================================ workflow
cat > .github/workflows/ax3600.yml <<'__WF__'
name: AX3600 · OpenWrt · all kmods

on:
  workflow_dispatch:
    inputs:
      owrt_version:
        description: 'Версия релиза OpenWrt (тег v<version>)'
        type: string
        required: true
        default: '25.12.6'
      vermagic:
        description: 'ABI-хэш вручную, 32 hex (пусто = авто)'
        type: string
        default: ''
      force_vermagic:
        description: 'Подставлять официальный vermagic'
        type: boolean
        default: true
      ignore_package_errors:
        description: 'IGNORE_ERRORS=m (битый пакет не валит сборку)'
        type: boolean
        default: true
      artifact_scope:
        description: 'Что выложить артефактом'
        type: choice
        options: [all, kmods]
        default: all
  push:
    paths:
      - 'packages.config_obrez.txt'
      - 'ax3600.config'
      - 'scripts/**'
      - '.github/workflows/ax3600.yml'

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

env:
  OWRT_VER: ${{ inputs.owrt_version || '25.12.6' }}
  FORCE_VM: ${{ inputs.force_vermagic }}
  IGN_ERR:  ${{ inputs.ignore_package_errors }}
  VM_INPUT: ${{ inputs.vermagic }}
  TGT: qualcommax
  SUB: ipq807x
  DEV: xiaomi_ax3600

jobs:
  build:
    runs-on: ubuntu-24.04
    timeout-minutes: 350
    steps:
      - uses: actions/checkout@v4

      - name: Free disk space
        run: |
          sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc \
                      /opt/hostedtoolcache/CodeQL /usr/share/swift /usr/local/.ghcup \
                      /usr/local/share/powershell /usr/share/miniconda
          sudo docker image prune -af || true
          sudo apt-get clean
          df -h /

      - name: Install build dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y --no-install-recommends \
            build-essential clang flex bison g++ gawk gettext git \
            libncurses-dev libssl-dev libelf-dev python3 python3-dev \
            python3-setuptools python3-pyelftools rsync swig unzip zlib1g-dev \
            file wget curl zstd time jq ccache xsltproc device-tree-compiler

      - name: Official vermagic / config.buildinfo / feeds.buildinfo
        id: official
        run: bash scripts/00-official.sh

      - name: Clone OpenWrt v${{ env.OWRT_VER }} + feeds
        run: bash scripts/05-clone.sh

      - name: Cache dl + ccache
        uses: actions/cache@v4
        with:
          path: |
            openwrt/dl
            openwrt/.ccache
          key: owrt-${{ env.OWRT_VER }}-${{ hashFiles('official/feeds.buildinfo') }}
          restore-keys: |
            owrt-${{ env.OWRT_VER }}-

      - name: Generate .config (+ validate package names)
        run: bash scripts/10-config.sh

      - name: Download sources
        run: bash scripts/15-download.sh

      - name: Phase 1 — toolchain + kernel
        run: bash scripts/20-build-kernel.sh

      - name: Apply official vermagic
        run: bash scripts/25-vermagic.sh

      - name: Phase 2 — all packages (all kmods) + image
        run: bash scripts/30-build-packages.sh

      - name: Verify vermagic
        run: bash scripts/35-verify.sh

      - name: Collect packages / firmware
        if: always()
        run: bash scripts/40-collect.sh

      - name: Upload packages
        if: ${{ always() && inputs.artifact_scope != 'kmods' }}
        uses: actions/upload-artifact@v4
        with:
          name: packages-${{ env.OWRT_VER }}-${{ env.DEV }}
          path: out/packages
          compression-level: 6
          if-no-files-found: warn

      - name: Upload kmods only
        if: ${{ always() && inputs.artifact_scope == 'kmods' }}
        uses: actions/upload-artifact@v4
        with:
          name: kmods-${{ env.OWRT_VER }}-${{ env.DEV }}
          path: out/kmods
          compression-level: 6
          if-no-files-found: warn

      - name: Upload firmware + metadata
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: firmware-${{ env.OWRT_VER }}-${{ env.DEV }}
          path: |
            out/firmware
            out/meta
            out/SHA256SUMS-packages.txt
            official/summary.md
            official/kernel-config.diff
          if-no-files-found: warn

      - name: Build logs on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: build-logs
          path: |
            openwrt/logs
            official
          if-no-files-found: ignore
__WF__

# ================================================================== README
cat > README.md <<'__RD__'
# OpenWrt 25.12.6 · Xiaomi AX3600 · все kmod + vermagic

Сборка прошивки `qualcommax/ipq807x`, **всех** kernel-модулей пакетами и их
совместимость со **стоковой** прошивкой того же релиза.

## Запуск
1. Содержимое этой папки — в корень репозитория (`.github/` должен быть в корне).
2. Actions → «AX3600 · OpenWrt · all kmods» → Run workflow.
3. Артефакты: `packages-*` (все .apk/.ipk, включая все kmod), `firmware-*` (образы,
   манифест, итоговый .config, vermagic).

Локально: `OWRT_VER=25.12.6 bash scripts/local-build.sh` (~25–40 ГБ диска).

## Про vermagic
Это не «25.12.6», а 32-hex ABI-хэш kernel-пакета (`kernel_6.12.x-r1-<hash>_...`).
Каждый kmod зависит от `kernel (= <ver>-<hash>)`. Пайплайн:
1. воспроизводит официальный конфиг (`config.buildinfo` + `feeds.buildinfo` + тот же тег);
2. форсирует хэш (`.vermagic`, литерал в `include/*.mk`, `LINUX_VERMAGIC=` в make);
3. сверяет результат и **падает** при расхождении.

Форс — косметика метаданных; реальную совместимость даёт только идентичный конфиг ядра.

## Ключевые решения
* Список пакетов применяется как **`=y`** (это манифест рабочей системы).
  `=m` для `base-files`/`netifd`/`luci` дал бы роутер без сети и LuCI.
* «Все kmod в packages» обеспечивает `CONFIG_ALL_KMODS=y` — они собираются `=m`
  и в образ не вшиваются.
* Конфликты вариантов сняты в `ax3600.config` (dnsmasq, wpad, ustream/uhttpd, ip, nftables).
* Шаг `10-config.sh` валидирует имена по `tmp/.packageinfo`, печатает таблицу
  «запрошено → что есть в дереве» и сам удаляет несуществующие.

## Установка на роутер
```sh
apk add --allow-untrusted ./kmod-xxx-*.apk    # 25.12
opkg install ./kmod-xxx_*.ipk                 # 24.10 и старше