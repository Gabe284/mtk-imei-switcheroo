# Read-only device preflight

Run this before choosing an NVRAM tool:

```sh
sh tools/nvram/device_preflight.sh
```

The script requires an authorized ADB device and attempts read-only property and file-size checks through `adb shell su -c`. It prints device properties, whether root access is available, and the sizes of the repository's expected IMEI, Bluetooth and Wi-Fi records.

## Important limitations

- This is a **read-only diagnostic**, not a KernelSU/Magisk module and not a patcher.
- File size is only a preliminary check. A matching size does not validate a record header, signature, checksum, offsets, or chipset-specific semantics.
- A detected MT6835 is explicitly reported as not hardware-validated by this repository. The existing tools' format assumptions must not be relaxed just to make a preflight pass.
- The script does not pull record contents, print IMEI/MAC values, stage files, remount partitions, write NVRAM, or reboot.
- A device property match is not proof that an NVRAM layout is compatible. Do not run live patch scripts until the target layout is independently validated and a safe backup/restore plan exists.
