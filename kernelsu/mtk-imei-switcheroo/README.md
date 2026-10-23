# MTK IMEI Switcheroo — KernelSU package

This directory is packaged by GitHub Actions as an installable KernelSU ZIP.
The package contains the repository's legacy Python parsers plus an on-device
read-only format audit.

## Current status

**Preflight build, not yet a verified MT6835 identifier-switching build.**

Observed Moto G 2025 (kansas, MT6835) record sizes are:

| Record | Observed size | Legacy parser reference | Current interpretation |
| --- | ---: | ---: | --- |
| LD0B_001 | 832 bytes | 384 bytes | Unsupported size |
| BT_Addr | 2416 bytes | 440 bytes | Unsupported size |
| WIFI | 2050 bytes | 2050 bytes | Size matches, but observed header did not match known legacy headers |

These observations do not establish a record format. No offsets, encryption, checksums,
or replacement layout are inferred from the size alone.

## Install and inspect

1. Download the mtk-imei-switcheroo-kernelsu artifact from the GitHub Actions run.
2. Install the ZIP in KernelSU Next and reboot only if KernelSU requests it.
3. Open the module action button to run the read-only audit.

The installer adds no boot-time service and does not modify properties, mounts,
NVRAM, Wi-Fi configuration, or identifiers. The action script reports only file
sizes and recognized signature status; it does not print identifier bytes.

## Bundled tools and dependencies

GitHub Actions copies tools/nvram/imei_tool.py and mac_tool.py into the
module ZIP. They preserve the upstream parser's verified legacy format checks.
They are not automatically run by the action menu. The IMEI tool needs Python
3 and PyCryptodome; the MAC tool needs Python 3. The Android KernelSU action
environment does not guarantee either dependency.

The upstream live-patch scripts are intentionally not bundled as live actions:
they assume host-side ADB and the known legacy layouts, which are not suitable
as an on-device module workflow for the observed MT6835 records.

## Write gate

No live NVRAM write path is enabled in this preflight build. Enabling one requires
independent format validation for the exact MT6835 records and tests that establish
preservation of all unrelated bytes. A successful KernelSU install is not proof
of format compatibility.
