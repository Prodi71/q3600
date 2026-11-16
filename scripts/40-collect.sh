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