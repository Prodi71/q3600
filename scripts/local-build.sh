#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
S="$(cd "$(dirname "$0")" && pwd)"
log "OpenWrt $OWRT_VER · $TGT/$SUB · $DEV · jobs=$JOBS"
for s in 00-official 05-clone 10-config 15-download 20-build-kernel 25-vermagic 30-build-packages 35-verify 40-collect; do
  bash "$S/$s.sh"
done
ok "Готово: $OUT_DIR"
cat "$GITHUB_STEP_SUMMARY"