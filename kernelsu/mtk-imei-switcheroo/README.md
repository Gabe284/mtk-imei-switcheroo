# MTK IMEI Switcheroo — KernelSU Next diagnostic package

This package targets the Moto G 2025 (kansas), MediaTek MT6835, Android 16 / SDK 36.

## Device command set

The action uses Android's /system/bin/sh and getprop for device identity. The record audit uses Android Toybox applets wc, od, and tr. It does not require Python, Bash, ADB, or a host-side Linux environment on the phone.

Audited paths observed on this device:
- /mnt/vendor/nvdata/md/NVRAM/NVD_IMEI/LD0B_001
- /mnt/vendor/nvdata/APCFG/APRDEB/BT_Addr
- /mnt/vendor/nvdata/APCFG/APRDEB/WIFI

The checker verifies required commands before inspecting records. If a command is missing, or a path is missing/unreadable, it reports an incomplete audit and fails closed. It does not search arbitrary partitions or print raw record bytes, IMEIs, Bluetooth addresses, or Wi-Fi addresses.

## Current format findings

| Record | Observed size | Legacy reference | Result |
| --- | ---: | ---: | --- |
| LD0B_001 | 832 bytes | 384 bytes | Unsupported size |
| BT_Addr | 2,416 bytes | 440 bytes | Unsupported size |
| WIFI | 2,050 bytes | 2,050 bytes | Header unsupported |

These findings do not prove corruption or identify the actual record layout. No offsets, encryption, checksums, or replacement layout are inferred.

## Build and install

GitHub Actions packages this directory as mtk-imei-switcheroo-kernelsu.zip. Download the artifact from the workflow run and install it through KernelSU Next. The module has no boot-time service hook and performs no NVRAM or identifier writes. Bundled legacy Python parsers are reference tools only and are not invoked by the on-device action.

A matching size or signature is not sufficient to authorize a write. This build is diagnostic-only; it is not an IMEI or MAC switching implementation.
