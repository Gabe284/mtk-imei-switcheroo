#!/bin/sh
# Read-only ADB device and NVRAM preflight. Never writes to the device.
set -u

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

command -v adb >/dev/null 2>&1 || die "adb not found in PATH"
command -v awk >/dev/null 2>&1 || die "awk not found in PATH"

device_state=$(adb devices 2>/dev/null | awk 'NR > 1 && NF { print $2; exit }')
[ "$device_state" = "device" ] || die "Expected one authorized ADB device in state 'device'; got '${device_state:-none}'"

printf '%s\n' "========== READ-ONLY DEVICE PREFLIGHT =========="
getprop_value() {
    adb shell getprop "$1" 2>/dev/null | tr -d '\r'
}

model=$(getprop_value ro.product.model)
product=$(getprop_value ro.product.name)
soc=$(getprop_value ro.soc.model)
hardware=$(getprop_value ro.boot.hardware)
android=$(getprop_value ro.build.version.release)
sdk=$(getprop_value ro.build.version.sdk)

printf 'ro.product.model=%s\n' "${model:-unknown}"
printf 'ro.product.name=%s\n' "${product:-unknown}"
printf 'ro.soc.model=%s\n' "${soc:-unknown}"
printf 'ro.boot.hardware=%s\n' "${hardware:-unknown}"
printf 'Android=%s (SDK %s)\n' "${android:-unknown}" "${sdk:-unknown}"

root_id=$(adb shell su -c id 2>/dev/null | tr -d '\r')
case "$root_id" in
    *"uid=0"*) printf '%s\n' "Root access: available via adb shell su -c" ;;
    *) printf '%s\n' "Root access: unavailable via adb shell su -c (file checks may be denied)" ;;
esac

check_size() {
    label=$1
    path=$2
    expected=$3
    result=$(adb shell su -c "if [ -r '$path' ]; then wc -c < '$path'; else echo MISSING; fi" 2>/dev/null | tr -d '\r' | tr -d ' ')
    case "$result" in
        ''|*[!0-9]*)
            printf '%s: unable to read size (%s)\n' "$label" "${result:-no response}"
            ;;
        *)
            if [ "$result" -eq "$expected" ]; then
                printf '%s: %s bytes (expected size matches; format still unverified)\n' "$label" "$result"
            else
                printf '%s: %s bytes (tool expects %s; incompatible with current size checks)\n' "$label" "$result" "$expected"
            fi
            ;;
    esac
}

printf '\n%s\n' "========== NVRAM RECORD SIZE CHECKS (READ ONLY) =========="
check_size "IMEI LD0B_001" "/mnt/vendor/nvdata/md/NVRAM/NVD_IMEI/LD0B_001" 384
check_size "Bluetooth BT_Addr" "/mnt/vendor/nvdata/APCFG/APRDEB/BT_Addr" 440
check_size "Wi-Fi WIFI" "/mnt/vendor/nvdata/APCFG/APRDEB/WIFI" 2050

case "$soc $hardware" in
    *MT6835*|*mt6835*)
        printf '\n%s\n' "Compatibility: MT6835 detected."
        printf '%s\n' "No MT6835 hardware-validated record profile is present in this repository."
        printf '%s\n' "A matching file size alone does not establish record-format compatibility."
        printf '%s\n' "Do not run the live patch scripts on this device until its record layouts are independently validated."
        ;;
    *)
        printf '\n%s\n' "Compatibility: no repository-supported hardware profile was inferred from the detected properties."
        printf '%s\n' "Detection is informational only; it does not authorize live patching."
        ;;
esac

printf '\n%s\n' "Preflight complete. No device files were modified; no identifiers were read or printed."
