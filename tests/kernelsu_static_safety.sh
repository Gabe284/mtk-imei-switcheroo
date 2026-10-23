#!/usr/bin/env bash
# Static safety/regression checks for the installable read-only KernelSU package.
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

grep -Fq 'No files are changed' "$MOD/tools/record_check.sh" || fail "read-only declaration missing"
grep -Fq 'UNSUPPORTED SIZE' "$MOD/tools/record_check.sh" || fail "unsupported sizes must fail closed"
grep -Fq 'UNSUPPORTED HEADER' "$MOD/tools/record_check.sh" || fail "unknown WIFI header must fail closed"
grep -Fq 'refusing to infer a layout' "$MOD/tools/record_check.sh" || fail "unknown formats must not be inferred"
grep -Fq 'not sufficient authorization to write' "$MOD/tools/record_check.sh" || fail "write gate warning missing"
pass "unknown formats remain fail-closed"

if grep -Eiq '(^|[[:space:]])(dd[[:space:]]+if=|nvram[[:space:]]+write|setprop[[:space:]]+|flash[[:space:]]+)' "$MOD/action.sh" "$MOD/tools/record_check.sh" "$MOD/customize.sh"; then
  fail "unexpected write-like command in diagnostic/installer scripts"
fi
pass "no obvious write operations in diagnostic/installer scripts"

grep -q '^id=mtk_imei_switcheroo$' "$MOD/module.prop" || fail "module id missing"
[ ! -e "$MOD/service.sh" ] || fail "unexpected boot-time service hook"
[ ! -e "$MOD/boot-completed.sh" ] || fail "unexpected boot-time hook"
pass "module metadata and no boot-time hook"
