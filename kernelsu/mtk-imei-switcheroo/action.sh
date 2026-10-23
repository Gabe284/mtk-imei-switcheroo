#!/system/bin/sh
MODDIR="${0%/*}"
CHECK="$MODDIR/tools/record_check.sh"

printf '\nMTK IMEI Switcheroo — READ-ONLY\n'
printf 'Device: %s (%s)\n' "$(getprop ro.product.model)" "$(getprop ro.product.device)"
printf 'SoC: %s\n' "$(getprop ro.soc.model)"
printf 'Android: %s / SDK %s\n' "$(getprop ro.build.version.release)" "$(getprop ro.build.version.sdk)"
printf '\n'
if [ -x "$CHECK" ]; then
  "$CHECK"
else
  printf 'ERROR: read-only record checker is missing or not executable: %s\n' "$CHECK"
fi
printf '\nLegacy parser status:\n'
printf 'Bundled Python parsers are reference tools only; this action does not invoke them.\n'
if command -v python3 >/dev/null 2>&1; then
  printf 'python3: available (%s); no parser was run\n' "$(command -v python3)"
else
  printf 'python3: unavailable; read-only shell diagnostics do not require Python\n'
fi
printf '\n'
printf 'STATUS: diagnostics only. This build does not write NVRAM.\n'
printf 'The device-specific IMEI/BT layouts are not validated, so write paths remain disabled.\n'
