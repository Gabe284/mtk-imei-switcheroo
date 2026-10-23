#!/system/bin/sh

ui_print "*******************************"
ui_print " MTK IMEI Switcheroo"
ui_print " KernelSU preflight package"
ui_print "*******************************"

SOC="$(getprop ro.soc.model 2>/dev/null)"
DEVICE="$(getprop ro.product.device 2>/dev/null)"
SDK="$(getprop ro.build.version.sdk 2>/dev/null)"

ui_print "Device: ${DEVICE:-unknown}"
ui_print "SoC: ${SOC:-unknown}"
ui_print "Android SDK: ${SDK:-unknown}"
ui_print "No NVRAM data will be changed during install."

case "$SOC" in
  *MT6835*) ui_print "MT6835 detected. Record format validation remains mandatory." ;;
  *) ui_print "WARNING: SoC is not confirmed as MT6835; diagnostics only." ;;
esac

# Intentionally no boot scripts, service hooks, property changes, mounts,
# identifier writes, permission changes to vendor data, or automatic reboot.
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/tools/record_check.sh" 0 0 0755
set_perm "$MODPATH/module.prop" 0 0 0644
set_perm "$MODPATH/README.md" 0 0 0644
set_perm "$MODPATH/tools/nvram/imei_tool.py" 0 0 0644
set_perm "$MODPATH/tools/nvram/mac_tool.py" 0 0 0644
set_perm "$MODPATH/tools/nvram/README.md" 0 0 0644

ui_print "Installed diagnostic tools."
ui_print "Use the module action button for a read-only format audit."
ui_print "No write operation is enabled for unverified record layouts."
