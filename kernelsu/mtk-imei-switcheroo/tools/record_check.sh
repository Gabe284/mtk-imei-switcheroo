#!/system/bin/sh
# Read-only MT6835 record-format diagnostics. Never write or print record contents.
IMEI="/mnt/vendor/nvdata/md/NVRAM/NVD_IMEI/LD0B_001"
BT="/mnt/vendor/nvdata/APCFG/APRDEB/BT_Addr"
WIFI="/mnt/vendor/nvdata/APCFG/APRDEB/WIFI"

# Android Toybox/POSIX applets expected on the stock Android 16 image.
for cmd in wc od tr; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'ERROR: required Android command unavailable: %s\n' "$cmd"
    printf 'STATUS: diagnostics incomplete; no records were changed.\n'
    exit 1
  fi
done

size_of() {
  if [ ! -f "$1" ] || [ ! -r "$1" ]; then printf 'missing/unreadable'; return; fi
  wc -c < "$1" | tr -d '[:space:]'
}
hex_at() { od -An -tx1 -j "$2" -N "$3" "$1" 2>/dev/null | tr -d ' \n'; }
check_prefix_record() {
  label="$1" path="$2" expected_size="$3" offset="$4" bytes="$5" expected_hex="$6"
  size="$(size_of "$path")"
  case "$size" in
    missing/unreadable|'') printf '%s: MISSING/UNREADABLE (expected location not accessible)\n' "$label"; return ;;
    *[!0-9]*) printf '%s: SIZE CHECK FAILED; refusing to infer a layout\n' "$label"; return ;;
  esac
  printf '%s: %s bytes; ' "$label" "$size"
  if [ "$size" != "$expected_size" ]; then printf 'UNSUPPORTED SIZE (legacy reference: %s bytes; size alone is not corruption evidence)\n' "$expected_size"; return; fi
  got="$(hex_at "$path" "$offset" "$bytes")"
  if [ "$got" = "$expected_hex" ]; then printf 'legacy signature matches; full structural/checksum validation still required\n'
  else printf 'UNSUPPORTED SIGNATURE (signature bytes withheld; refusing to infer a layout)\n'; fi
}

printf 'Read-only NVRAM record format audit\n'
printf 'No record contents or identifiers are printed. No files are changed.\n'
printf 'Commands: Android shell + wc, od, tr (no Python dependency).\n\n'
check_prefix_record "LD0B_001" "$IMEI" 384 0 8 "4c44490010ef0a00"
check_prefix_record "BT_Addr" "$BT" 440 6 16 "60002310000007000000050703040000"

size="$(size_of "$WIFI")"
case "$size" in
  missing/unreadable|'') printf 'WIFI: MISSING/UNREADABLE (expected location not accessible)\n' ;;
  *[!0-9]*) printf 'WIFI: SIZE CHECK FAILED; refusing to infer a layout\n' ;;
  2050)
    printf 'WIFI: %s bytes; ' "$size"
    header="$(hex_at "$WIFI" 0 4)"
    case "$header" in 01000800|01000900) printf 'legacy header matches; full structural/checksum validation still required\n' ;; *) printf 'UNSUPPORTED HEADER (header bytes withheld; refusing to infer a layout)\n' ;; esac
    ;;
  *) printf 'WIFI: %s bytes; UNSUPPORTED SIZE (legacy reference: 2050 bytes; size alone is not corruption evidence)\n' "$size" ;;
esac
printf '\nNote: matching size or signature is not sufficient authorization to write a record.\n'
printf 'STATUS: diagnostics only. No NVRAM writes are implemented or enabled.\n'
