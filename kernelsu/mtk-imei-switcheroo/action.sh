#!/system/bin/sh
MODDIR="${0%/*}"
CHECK="$MODDIR/tools/record_check.sh"

printf '\nMTK IMEI Switcheroo — READ-ONLY\n'
printf 'Device: %s (%s)\n' "$(getprop ro.product.model)" "$(getprop ro.product.device)"
printf 'SoC: %s\n' "$(getprop ro.soc.model)"
printf 'Android: %s / SDK %s\n' "$(getprop ro.build.version.release)" "$(getprop ro.build.version.sdk)"
printf '\n'
"$CHECK"
printf '\nBundled legacy parser availability:\n'
if command -v python3 >/dev/null 2>&1; then
  printf 'python3: %s\n' "$(command -v python3)"
  if python3 -c 'from Crypto.Cipher import AES' >/dev/null 2>&1; then
    printf 'PyCryptodome: available\n'
  elif python3 -c 'from Cryptodome.Cipher import AES' >/dev/null 2>&1; then
    printf 'pycryptodomex: available\n'
  else
    printf 'AES dependency: unavailable; IMEI parser cannot run\n'
  fi
else
  printf 'python3: unavailable in KernelSU action environment\n'
fi
printf '\n'
printf 'STATUS: diagnostics only. This build does not write NVRAM.\n'
printf 'The device-specific IMEI/BT layouts are not validated, so write paths remain disabled.\n'
