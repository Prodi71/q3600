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