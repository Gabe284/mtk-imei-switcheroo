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

prefix_hex() {
  od -An -tx1 -N8 "$1" 2>/dev/null | tr -s ' ' | sed 's/^ //;s/ $//'
}

check_one() {
  label="$1" path="$2" expected_size="$3" legacy_prefix="$4" prefix_len="$5"
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
  prefix="$(prefix_hex "$path")"
  got="$(printf '%s\n' "$prefix" | cut -c1-$prefix_len)"
  if [ "$got" = "$legacy_prefix" ]; then
    printf 'legacy signature prefix matches; full structural/checksum validation still required\n'
  else
    printf 'UNSUPPORTED SIGNATURE (not the recognized legacy prefix; refusing to infer a layout)\n'
  fi
}

printf 'Read-only NVRAM record format audit\n'
printf 'No record contents or identifiers are printed. No files are changed.\n\n'

check_one "LD0B_001" "$IMEI" 384 "4c444900" 8
check_one "BT_Addr" "$BT" 440 "000000000000" 12

if [ ! -f "$WIFI" ]; then
  printf 'WIFI: MISSING (not readable or not present)\n'
else
  size="$(size_of "$WIFI")"
  printf 'WIFI: %s bytes; ' "$size"
  if [ "$size" != "2050" ]; then
    printf 'UNSUPPORTED SIZE (legacy reference: 2050 bytes; size alone is not corruption evidence)\n'
  else
    header="$(od -An -tx1 -N4 "$WIFI" 2>/dev/null | tr -d ' \n')"
    case "$header" in
      01000800|01000900) printf 'legacy header matches; full structural/checksum validation still required\n' ;;
      *) printf 'UNSUPPORTED HEADER (got %s; refusing to infer a layout)\n' "${header:-unreadable}" ;;
    esac
  fi
fi

printf '\n'
printf 'Note: a matching size or prefix is not sufficient authorization to write a record.\n'
