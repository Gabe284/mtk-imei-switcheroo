#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOD="$ROOT/kernelsu/mtk-imei-switcheroo"
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }
for f in "$MOD/action.sh" "$MOD/customize.sh" "$MOD/uninstall.sh" "$MOD/tools/record_check.sh"; do
  bash -n "$f" || fail "shell syntax: ${f#$ROOT/}"
done
pass "module shell syntax"
grep -Fq 'does not invoke them' "$MOD/action.sh" || fail "action must not execute bundled Python parsers"
grep -Fq 'read-only shell diagnostics do not require Python' "$MOD/action.sh" || fail "Python-free diagnostic status"
pass "diagnostic action does not require Python"
CHECK="$MOD/tools/record_check.sh"
grep -Fq 'for cmd in wc od tr' "$CHECK" || fail "required Android command preflight missing: wc/od/tr"
grep -Fq '/mnt/vendor/nvdata/md/NVRAM/NVD_IMEI/LD0B_001' "$CHECK" || fail "MTK IMEI record path missing"
grep -Fq '/mnt/vendor/nvdata/APCFG/APRDEB/BT_Addr' "$CHECK" || fail "MTK Bluetooth record path missing"
grep -Fq '/mnt/vendor/nvdata/APCFG/APRDEB/WIFI' "$CHECK" || fail "MTK Wi-Fi record path missing"
pass "Android command and Kansas record-path preflight"
grep -Fq 'No files are changed' "$CHECK" || fail "read-only declaration missing"
grep -Fq 'UNSUPPORTED SIZE' "$CHECK" || fail "unsupported sizes must fail closed"
grep -Fq 'UNSUPPORTED HEADER' "$CHECK" || fail "unknown WIFI header must fail closed"
grep -Fq 'refusing to infer a layout' "$CHECK" || fail "unknown formats must not be inferred"
grep -Fq 'No NVRAM writes are implemented or enabled' "$CHECK" || fail "write gate warning missing"
pass "unknown formats remain fail-closed"
if grep -Eiq '(^|[[:space:]])(dd[[:space:]]+if=|nvram[[:space:]]+write|setprop[[:space:]]+|flash[[:space:]]+)' "$MOD/action.sh" "$CHECK" "$MOD/customize.sh"; then fail "unexpected write-like command in diagnostic/installer scripts"; fi
pass "no obvious write operations in diagnostic/installer scripts"
grep -q '^id=mtk_imei_switcheroo$' "$MOD/module.prop" || fail "module id missing"
[ ! -e "$MOD/service.sh" ] || fail "unexpected boot-time service hook"
[ ! -e "$MOD/boot-completed.sh" ] || fail "unexpected boot-time hook"
pass "module metadata and no boot-time hook"
