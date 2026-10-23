#!/system/bin/sh
MODDIR="${0%/*}"
CHECK="$MODDIR/tools/record_check.sh"

IMEI_DEFAULT="/mnt/vendor/nvdata/md/NVRAM/NVD_IMEI/LD0B_001"
BT_DEFAULT="/mnt/vendor/nvdata/APCFG/APRDEB/BT_Addr"
WIFI_DEFAULT="/mnt/vendor/nvdata/APCFG/APRDEB/WIFI"
IMEI_PATH="$IMEI_DEFAULT"
BT_PATH="$BT_DEFAULT"
WIFI_PATH="$WIFI_DEFAULT"

show_device() {
  printf '\nDevice: %s (%s)\n' "$(getprop ro.product.model)" "$(getprop ro.product.device)"
  printf 'SoC: %s\n' "$(getprop ro.soc.model)"
  printf 'Android: %s / SDK %s\n' "$(getprop ro.build.version.release)" "$(getprop ro.build.version.sdk)"
}
show_paths() {
  printf '\nRead-only diagnostic paths\n'
  printf '1. IMEI record: %s\n' "$IMEI_PATH"
  printf '2. Bluetooth record: %s\n' "$BT_PATH"
  printf '3. Wi-Fi record: %s\n' "$WIFI_PATH"
  printf 'Path scope: /mnt/vendor/nvdata/ only\n'
}
valid_path() {
  case "$1" in
    /mnt/vendor/nvdata/*) return 0 ;;
    *) return 1 ;;
  esac
}
read_path() {
  prompt="$1" current="$2"
  printf '%s\nCurrent: %s' "$prompt" "$current"
  printf 'New absolute path (blank keeps current): '
  IFS= read -r entered
  [ -n "$entered" ] || entered="$current"
  if ! valid_path "$entered"; then
    printf 'Rejected: paths must be inside /mnt/vendor/nvdata/.\n'
    return 1
  fi
  printf '%s' "$entered"
}
configure_paths() {
  printf '\nConfigure paths for this run only. No files or records are modified.\n'
  printf 'Only absolute paths under /mnt/vendor/nvdata/ are accepted.\n\n'
  value="$(read_path 'IMEI record path' "$IMEI_PATH")" || return
  IMEI_PATH="$value"
  value="$(read_path 'Bluetooth record path' "$BT_PATH")" || return
  BT_PATH="$value"
  value="$(read_path 'Wi-Fi record path' "$WIFI_PATH")" || return
  WIFI_PATH="$value"
  printf '\nPaths updated for this action session.\n'
}
run_audit() {
  if [ ! -x "$CHECK" ]; then
    printf 'ERROR: checker missing or not executable: %s\n' "$CHECK"
    return 1
  fi
  IMEI_PATH="$IMEI_PATH" BT_PATH="$BT_PATH" WIFI_PATH="$WIFI_PATH" "$CHECK"
}
show_device
printf '\nMTK IMEI Switcheroo — READ-ONLY diagnostic console\n'
printf 'No identifier writes are available in this build.\n'

while :; do
  printf '\nMain menu\n'
  printf '  1) Run read-only record audit\n'
  printf '  2) Configure diagnostic paths\n'
  printf '  3) Show configured paths\n'
  printf '  4) Exit\n'
  printf 'Select [1-4]: '
  IFS= read -r choice
  case "$choice" in
    1) run_audit ;;
    2) configure_paths ;;
    3) show_paths ;;
    4|q|Q) printf 'Exiting. No NVRAM records were changed.\n'; break ;;
    *) printf 'Invalid choice. Enter 1, 2, 3, or 4.\n' ;;
  esac
done

printf '\nLegacy parser status:\n'
printf 'Bundled Python parsers are reference tools only; this action does not invoke them.\n'
if command -v python3 >/dev/null 2>&1; then
  printf 'python3: available (%s); no parser was run\n' "$(command -v python3)"
else
  printf 'python3: unavailable; read-only shell diagnostics do not require Python\n'
fi
printf '\nSTATUS: diagnostics only. This build does not write NVRAM.\n'
