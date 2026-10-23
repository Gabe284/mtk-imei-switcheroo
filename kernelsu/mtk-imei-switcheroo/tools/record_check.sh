#!/system/bin/sh
# Read-only structural detection. Does not print identifier bytes or modify files.
IMEI="/mnt/vendor/nvdata/md/NVRAM/NVD_IMEI/LD0B_001"
BT="/mnt/vendor/nvdata/APCFG/APRDEB/BT_Addr"
WIFI="/mnt/vendor/nvdata/APCFG/APRDEB/WIFI"

size_of() {
  if [ ! -f "$1" ]; then
    printf 'missing'
    return
  fi
  wc -c < "$1" | tr -d '[:space:]'
}

hex_at() {
  od -An -tx1 -j "$2" -N "$3" "$1" 2>/dev/null | tr -d ' \n'
}

check_prefix_record() {
  label="$1" path="$2" expected_size="$3" offset="$4" bytes="$5" expected_hex="$6"
  size="$(size_of "$path")"
  if [ "$size" = "missing" ]; then
    printf '%s: MISSING (not readable or not present)\n' "$label"
    return
  fi
  printf '%s: %s bytes; ' "$label" "$size"
  if [ "$size" != "$expected_size" ]; then
    printf 'UNSUPPORTED SIZE (legacy reference: %s bytes; size alone is not corruption evidence)\n' "$expected_size"
    return
  fi
  got="$(hex_at "$path" "$offset" "$bytes")"
  if [ "$got" = "$expected_hex" ]; then
    printf 'legacy signature matches; full structural/checksum validation still required\n'
  else
    printf 'UNSUPPORTED SIGNATURE (got %s; refusing to infer a layout)\n' "${got:-unreadable}"
  fi
}

printf 'Read-only NVRAM record format audit\n'
printf 'No record contents or identifiers are printed. No files are changed.\n\n'

# Exact legacy parser signatures: LD0B_001 has an 8-byte signature at offset 0;
# BT_Addr has a 16-byte signature at offset 6. MAC bytes at offset 0 are not a signature.
check_prefix_record "LD0B_001" "$IMEI" 384 0 8 "4c44490010ef0a00"
check_prefix_record "BT_Addr" "$BT" 440 6 16 "60002310000007000000050703040000"

if [ ! -f "$WIFI" ]; then
  printf 'WIFI: MISSING (not readable or not present)\n'
else
  size="$(size_of "$WIFI")"
  printf 'WIFI: %s bytes; ' "$size"
  if [ "$size" != "2050" ]; then
    printf 'UNSUPPORTED SIZE (legacy reference: 2050 bytes; size alone is not corruption evidence)\n'
  else
    header="$(hex_at "$WIFI" 0 4)"
    case "$header" in
      01000800|01000900) printf 'legacy header matches; full structural/checksum validation still required\n' ;;
      *) printf 'UNSUPPORTED HEADER (got %s; refusing to infer a layout)\n' "${header:-unreadable}" ;;
    esac
  fi
fi

printf '\n'
printf 'Note: a matching size or signature is not sufficient authorization to write a record.\n'
