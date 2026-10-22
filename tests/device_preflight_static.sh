#!/bin/sh
set -u
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SCRIPT="$ROOT/tools/nvram/device_preflight.sh"

[ -f "$SCRIPT" ] || { echo "FAIL: preflight script missing"; exit 1; }
sh -n "$SCRIPT" || exit 1

# Static safety guard: this script must remain read-only with respect to the
# device. These tokens are intentionally prohibited from its source.
if grep -En 'adb[[:space:]]+(push|reboot)|mount[[:space:]]+-o[[:space:]]+remount|(^|[[:space:]])(dd|flash|fastboot)[[:space:]]|chmod[[:space:]]|chown[[:space:]]|rm[[:space:]]|cp[[:space:]]' "$SCRIPT"; then
    echo "FAIL: potentially mutating command found in preflight script"
    exit 1
fi

grep -q 'MT6835 detected' "$SCRIPT" || { echo "FAIL: MT6835 branch missing"; exit 1; }
grep -q 'format still unverified' "$SCRIPT" || { echo "FAIL: size check overstates compatibility"; exit 1; }
grep -q 'No device files were modified' "$SCRIPT" || { echo "FAIL: read-only completion message missing"; exit 1; }
echo "PASS: device preflight syntax and static read-only checks"
